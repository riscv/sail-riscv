import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template
import sys

import riscof.utils as utils
import riscof.constants as constants
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class spike(pluginTemplate):
    __model__ = "spike"

    __version__ = "XXX"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get('config')

        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        self.dut_exe = os.path.join(config['PATH'] if 'PATH' in config else "","spike")

        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)

        self.pluginpath=os.path.abspath(config['pluginpath'])
        self.isa_spec = os.path.abspath(config['ispec'])
        self.platform_spec = os.path.abspath(config['pspec'])

        if 'target_run' in config and config['target_run']=='0':
            self.target_run = False
        else:
            self.target_run = True

    def initialise(self, suite, work_dir, archtest_env):

       self.work_dir = work_dir

       # capture the architectural test-suite directory.
       self.suite_dir = suite

       self.compile_cmd = 'riscv64-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env + ' {1} -o {2} {3}'

       # workaround to avoid clang format error in sail-riscv CI.
       # *clang suggest style that is syntactically incorrect*
       # Insert the following macro at run-time.
       modelTest_path = 'spike/env/model_test.h'
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

      # load the isa yaml as a dictionary in python.
      ispec = utils.load_yaml(isa_yaml)['hart0']

      self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')

      # incorporate rv32e along with rv32i and rv64i
      ilp32 = 'ilp32e ' if "E" in ispec["ISA"] else 'ilp32 '
      self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else ilp32)
      # for spike start building the '--isa' argument.
      self.isa = 'rv' + self.xlen
      if "I" in ispec["ISA"]:
          self.isa += 'i'
      if "E" in ispec["ISA"]:
          self.isa += 'e'
      if "M" in ispec["ISA"]:
          self.isa += 'm'
      if "A" in ispec["ISA"]:
          self.isa += 'a'
      if "F" in ispec["ISA"]:
          self.isa += 'f'
      if "D" in ispec["ISA"]:
          self.isa += 'd'
      if "C" in ispec["ISA"]:
          self.isa += 'c'
      if "Zca" in ispec["ISA"]:
          self.isa += '_zca'
      if "Zcb" in ispec["ISA"]:
          self.isa += '_zcb'
      if "Zba" in ispec["ISA"]:
          self.isa += '_zba'
      if "Zbb" in ispec["ISA"]:
          self.isa += '_zbb'
      if "Zbc" in ispec["ISA"]:
          self.isa += '_zbc'
      if "Zbs" in ispec["ISA"]:
          self.isa += '_zbs'
      if "Zicond" in ispec["ISA"]:
          self.isa += '_zicond'
      if "Zicboz" in ispec["ISA"]:
          self.isa += '_zicboz'
      if "Zfa" in ispec["ISA"]:
          self.isa += '_zfa'
      if "Zfa" in ispec["ISA"]:
          self.isa += '_zfh'
      if "Zfinx" in ispec["ISA"]:
          self.isa += '_zfinx'

    def runTests(self, testList):

      # Delete Makefile if it already exists.
      if os.path.exists(self.work_dir+ "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir+ "/Makefile." + self.name[:-1])
      # create an instance the makeUtil class that we will use to create targets.
      make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))

      make.makeCommand = 'make -k -j' + self.num_jobs

      for testname in testList:

          # for each testname we get all its fields (as described by the testList format)
          testentry = testList[testname]

          test = testentry['test_path']

          test_dir = testentry['work_dir']

          elf = 'dut.elf'

          sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

          compile_macros= ' -D' + " -D".join(testentry['macros'])

          cmd = self.compile_cmd.format(testentry['isa'].lower(), test, elf, compile_macros)

          if self.target_run:
            # set up the simulation command. Template is for spike. Please change.
            simcmd = self.dut_exe + ' --isa={0} +signature={1} +signature-granularity=4 {2}'.format(self.isa, sig_file, elf)
          else:
            simcmd = 'echo "NO RUN"'

          # concatenate all commands that need to be executed within a make-target.
          execute = '@cd {0}; {1}; {2};'.format(testentry['work_dir'], cmd, simcmd)

          make.add_target(execute)

      make.execute_all(self.work_dir)

      if not self.target_run:
          raise SystemExit(0)
