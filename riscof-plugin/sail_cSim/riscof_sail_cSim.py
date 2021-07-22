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
	# Check if the config.ini node has a sail_cSim node. Else error out.
        if config is None:
            logger.error("Config node for sail_cSim missing.")
            raise SystemExit

        # capture the number of parallel jobs that can be used for running tests
        # on sail_cSim either from the config.ini or default to 1
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)

	# capture tha path of the plugin from the config.ini node.
        self.pluginpath = os.path.abspath(config['pluginpath'])

	# since sail_csim has different binaries for 32 and 64. Here we have
	# created a small dictionary which maps XLEN to the respective binary paths. 
	# We first check for the PATH variable in the config.ini, else we default to 
	# riscv_sim_RV32/RV64. The element selection happens in the build phase, when we 
	# access to the ISA yaml (coming from DUT).
        self.sail_exe = { '32' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_RV32"),
                '64' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_RV64")}
	
	# This is usually not required unless you are running sail_cSim as a DUT.
	# This variable is used to set path of the riscv-config isa spec if specified in the
	# config.ini file. Else default to an empty string.
        self.isa_spec = os.path.abspath(config['ispec']) if 'ispec' in config else ''

	# This is usually not required unless you are running sail_cSim as a DUT.
	# This variable is used to set path of the riscv-config platform spec if specified in the
	# config.ini file. Else default to an empty string.
        self.platform_spec = os.path.abspath(config['pspec']) if 'ispec' in config else ''

	# capture the make command from the config.ini which could
        # default to using "make". Options for this command could be "pmake" as
        # well.
        self.make = config['make'] if 'make' in config else 'make'

        # logger statements to print on the terminal during the run
        logger.debug("SAIL CSim plugin initialised using the following configuration.")
        for entry in config:
            logger.debug(entry+' : '+config[entry])
        return sclass

    def initialise(self, suite, work_dir, archtest_env):

	# capture the suite directory
        self.suite = suite
	
	# capture the working directory.
        self.work_dir = work_dir

	# set the compile and objdump commands here. Note the march is not hardwired here, 
	# because it will change for each test.
        self.objdump_cmd = 'riscv{1}-unknown-elf-objdump -D {0} > {2};'
        self.compile_cmd = 'riscv{1}-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env

    def build(self, isa_yaml, platform_yaml):

        # The checked isa and platform yamls are provided by the riscof tool to
        # this function. The following loads the yaml as a python dictionary.
        ispec = utils.load_yaml(isa_yaml)['hart0']

        # we capture the max xlen value from the isa yaml.
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        
        #TODO: The following assumes you are using the riscv-gcc toolchain. If
        #      not please change appropriately and sets the mabi argument for
        #      compilation
        self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else 'ilp32 ')

        # the following variable is used capture the value of the --isa argument
        # needed for spike.
        self.isa = 'rv' + self.xlen
        if "I" in ispec["ISA"]:
            self.isa += 'i'
        if "M" in ispec["ISA"]:
            self.isa += 'm'
        if "C" in ispec["ISA"]:
            self.isa += 'c'
        if "F" in ispec["ISA"]:
            self.isa += 'f'
        if "D" in ispec["ISA"]:
            self.isa += 'd'

        # the Folloing piece of code checks if the toolchain, spike and make
        # commands exist on the command line. If not, then an error is thrown.
        objdump = "riscv{0}-unknown-elf-objdump".format(self.xlen)
        if shutil.which(objdump) is None:
            logger.error(objdump+": executable not found. Please check environment setup.")
            raise SystemExit
        compiler = "riscv{0}-unknown-elf-gcc".format(self.xlen)
        if shutil.which(compiler) is None:
            logger.error(compiler+": executable not found. Please check environment setup.")
            raise SystemExit
        if shutil.which(self.sail_exe[self.xlen]) is None:
            logger.error(self.sail_exe[self.xlen]+ ": executable not found. Please check environment setup.")
            raise SystemExit
        if shutil.which(self.make) is None:
            logger.error(self.make+": executable not found. Please check environment setup.")
            raise SystemExit


    def runTests(self, testList,cgf_file=None):

        # Here we use the makefile utility offered by riscof to quickly create a
        # Makefile where each target of the makefile corresponds to a single
        # test compilation and run.
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))

        # set the jobs that can be used by the make command.
        make.makeCommand = self.make + ' -j' + self.num_jobs

        # we will now parse through each test selected by the framework and
        # create makefile targets.
        for file in testList:

            # capture the testentry from the test-list dictionary
            testentry = testList[file]

            # capture the path of the assembly test
            test = testentry['test_path']

            # capture the directory where artifacts of the compilation of the
            # test should be generated.
            test_dir = testentry['work_dir']
            test_name = test.rsplit('/',1)[1][:-2]

	    # Name of the elf of the compiled test
            elf = 'ref.elf'

            # We now start building the execution command for the test. First
            # lets change directories to the work_dir specified by the test.
            execute = "@cd "+testentry['work_dir']+";"

            # Set the march value, test name and elf name to the compile command. 
            # NOTE: here we are going to use riscv32- toolchain for RV32 systems
            # and riscv64- toolchain for RV64 systems. If you do not want this
            # distinction, you can replace "self.xlen" in the below line with a
            # hardcoded number under quotes: "64"
            cmd = self.compile_cmd.format(testentry['isa'].lower(), self.xlen) + ' ' + test + ' -o ' + elf

            #TODO: we are using -D to enable compile time macros. If your
            # toolchain is not riscv-gcc you may want to change the below code
            # The compile macros are available within the test-entry. 
            # Users can further append their own compile macros that may be
            # required for custom vendor specific-code or for assertions.
            compile_cmd = cmd + ' -D' + " -D".join(testentry['macros'])

            # append compile command to the makefile execution command.
            execute+=compile_cmd+";"

	    # append the objdump command to the makefile execution command.
            execute += self.objdump_cmd.format(elf, self.xlen, 'ref.disass')

            # set name and path of the signature file. All dut signatures must
            # be named "Ref-<ref-name>.signature". This is what the RISCOF
            # framework will look for when matching signatures.
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")

	    # Append the command to running the test on the simulator and dumping 
	    # the signature file.
            execute += self.sail_exe[self.xlen] + ' --test-signature={0} {1} > {2}.log 2>&1;'.format(sig_file, elf, test_name)

            cov_str = ' '
            for label in testentry['coverage_labels']:
                cov_str+=' -l '+label

            # under coverage mode, we also append the isac commands for
            # collecting coverage from the test.
            if cgf_file is not None:
                coverage_cmd = 'riscv_isac --verbose info coverage -d \
                        -t {0}.log --parser-name c_sail -o coverage.rpt  \
                        --sig-label begin_signature  end_signature \
                        --test-label rvtest_code_begin rvtest_code_end \
                        -e ref.elf -c {1} -x{2} {3};'.format(\
                        test_name, ' -c '.join(cgf_file), self.xlen, cov_str)
            else:
                coverage_cmd = ''
            execute+=coverage_cmd

            # create a makefile target for the current test.
            make.add_target(execute)

        # run all the targets in parallel    
        make.execute_all(self.work_dir)
