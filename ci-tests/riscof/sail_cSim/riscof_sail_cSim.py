import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate
import riscof.constants as constants
from riscv_isac.isac import isac

logger = logging.getLogger()

class sail_cSim(pluginTemplate):
    __model__ = "sail_c_simulator"
    __version__ = "0.5.0"

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)

        config = kwargs.get('config')
        if config is None:
            logger.error("Config node for sail_cSim missing.")
            raise SystemExit(1)
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)
        self.pluginpath = os.path.abspath(config['pluginpath'])
        self.sail_exe = { '32' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_RV32"),
                '64' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_RV64")}
        self.isa_spec = os.path.abspath(config['ispec']) if 'ispec' in config else ''
        self.platform_spec = os.path.abspath(config['pspec']) if 'ispec' in config else ''
        self.make = config['make'] if 'make' in config else 'make'
        logger.debug("SAIL CSim plugin initialised using the following configuration.")
        for entry in config:
            logger.debug(entry+' : '+config[entry])
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        self.suite = suite
        self.work_dir = work_dir
        self.objdump_cmd = 'riscv64-unknown-elf-objdump -D {0} > {1};'
        # self.archtest_env = archtest_env.replace("riscv-arch-test", "../my-repo/riscv-arch-test")
        self.compile_cmd = 'riscv64-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env

        # workaround to avoid clang format error in sail-riscv CI.
        # *clang suggest style that is syntactically incorrect*
        # Insert the following macro at run-time.
        modelTest_path = 'sail_cSim/env/model_test.h'
        macro = """
#define RVMODEL_DATA_SECTION .pushsection                                      \\
  .tohost, "aw", @progbits;                                                    \\
  .align 8;                                                                    \\
  .global tohost;                                                              \\
  tohost:                                                                      \\
  .dword 0;                                                                    \\
  .align 8;                                                                    \\
  .global fromhost;                                                            \\
  fromhost:                                                                    \\
  .dword 0;                                                                    \\
  .popsection;                                                                 \\
  .align 8;                                                                    \\
  .global begin_regstate;                                                      \\
  begin_regstate:                                                              \\
  .word 128;                                                                   \\
  .align 8;                                                                    \\
  .global end_regstate;                                                        \\
  end_regstate:                                                                \\
  .word 4;
"""
        with open(modelTest_path, 'r') as file:
            modelTest = file.readlines()
        modelTest.insert(2, macro)
        with open(modelTest_path, 'w') as file:
            file.writelines(modelTest)

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)['hart0']
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        self.isa = ' '  # 'rv' + self.xlen
        ilp32 = 'ilp32e ' if "E" in ispec["ISA"] else 'ilp32 '
        self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else ilp32)
        # if "I" in ispec["ISA"]:
        #     self.isa += 'i'
        # if "M" in ispec["ISA"]:
        #     self.isa += 'm'
        # if "C" in ispec["ISA"]:
        #     self.isa += 'c'
        # if "F" in ispec["ISA"]:
        #     self.isa += 'f'
        # if "D" in ispec["ISA"]:
        #     self.isa += 'd'

        # flag for sail-riscv to enable zcb extension.
        # sail model does not yet offer flags for other extensions, supported extensions are enabled by default
        if "Zcb" in ispec["ISA"]:
            self.isa += ' --enable-zcb'

        objdump = "riscv64-unknown-elf-objdump"
        if shutil.which(objdump) is None:
            logger.error(objdump+": executable not found. Please check environment setup.")
            raise SystemExit(1)
        compiler = "riscv64-unknown-elf-gcc"
        if shutil.which(compiler) is None:
            logger.error(compiler+": executable not found. Please check environment setup.")
            raise SystemExit(1)
        if shutil.which(self.sail_exe[self.xlen]) is None:
            logger.error(self.sail_exe[self.xlen]+ ": executable not found. Please check environment setup.")
            raise SystemExit(1)
        if shutil.which(self.make) is None:
            logger.error(self.make+": executable not found. Please check environment setup.")
            raise SystemExit(1)

    def runTests(self, testList, cgf_file=None):
        if os.path.exists(self.work_dir+ "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir+ "/Makefile." + self.name[:-1])
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = self.make + ' -j' + self.num_jobs
        for file in testList:
            testentry = testList[file]
            test = testentry['test_path']
            test_dir = testentry['work_dir']
            test_name = test.rsplit('/',1)[1][:-2]

            elf = 'ref.elf'

            execute = "@cd "+testentry['work_dir']+";"

            cmd = self.compile_cmd.format(testentry['isa'].lower(), self.xlen) + ' ' + test + ' -o ' + elf
            compile_cmd = cmd + ' -D' + " -D".join(testentry['macros'])
            execute+=compile_cmd+";"

            # execute += self.objdump_cmd.format(elf, 'ref.disass')
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

            # execute += self.sail_exe[self.xlen] + ' --test-signature={0} {1} > {2}.log 2>&1;'.format(sig_file, elf, test_name)
            execute += self.sail_exe[self.xlen] + ' {0} --no-trace --test-signature={1} {2} > /dev/null;'.format(self.isa, sig_file, elf)

            make.add_target(execute)
        make.execute_all(self.work_dir)
