# Riscof Plugin for RISC-V SAIL C-Emulator

This directory provides all the files and artifacts required for running SAIL RISC-V as a Reference model on the 
[RISCOF](https://github.com/riscv/riscof) framework.

## Getting SAIL RISC-V

The model repository should be cloned from [here](https://github.com/rems-project/sail-riscv).

## Building SAIL RISC-V C-Emulator

The [README.md](../../README.md) at the top level of the sail-riscv repository gives details on 
building C based executable of the model. You can build both the RV32 and RV64 variants.
Once built, please add `$SAIL_RISCV/c_emulator` and `$SAIL_RISCV/ocaml_emulator` to your $PATH, 
where $SAIL_RISCV is the path to the cloned repository.

## Plugin Files

Description of all files present in this plugin:

``` 
  env                 # contains the model_test.h and the link.ld files currently found in 
                      # the riscv-arch-test/riscv-target/sail-riscv-c directory  of the
                      # the riscv-arch-test repository.
  riscof_sail_cSim.py # plugin file for spike. MUST be prefixed with "riscof_"
  sail_isa.yaml       # ISA YAML configuration file - new file. Only required if using sail as DUT
  sail_platform.yaml  # PLATFORM YAML configuration file - new file. Only required if using sail as DUT
  __init__.py         # used expose the plugin path. - new file
  README.md           # This file
```

## Using SAIL RISC-V as a reference model in RISCOF

RISCOF requires a `config.ini` file to detect various parameters of the run like - name and path 
of the dut and reference plugins, the isa spec files, etc. A template of this this file can be generated
automatically using the `riscof setup` command . Please see the
[Config.ini Syntax](https://riscof.readthedocs.io/en/stable/inputs.html#config-ini-syntax))
guide for mode details on the syntax of this file and how to modify/build custom plugins.

You will need to edit the reference plugin sections of the `config.ini` file with the following 


```
# Name of the Plugin. All entries are case sensitive. Including the name.
[sail_cSim]

#path to the directory where the plugin is present. (required)
pluginpath=/clone-path/sail-riscv/riscof-plugin/sail_cSim

#path where the `riscv_sim_RV*` binaries are available. (optional)
#if this value is absent, it is assumed that the binaries are available in the $PATH by default
PATH=<path-to-binaries>

#number of jobs to spawn in parallel while running tests on sail_cSim (optional)
jobs=1

#the make command to use while executing the make file. Any of bmake,cmake,pmake,make etc. (optional)
#Default is make
make=make
```

- Export command
```
pwd=pwd;export PYTHONPATH=$pwd:$PYTHONPATH;
```

## About the Plugin

The sail_cSim plugin (`riscof_sail_cSim.py` file) present here has the following four functions:

- \_\_init\_\_: This is the base initialization function. This function will check if the config.ini
  section corresponding to `sail_cSim` for the following variables and set variables accordingly:

  - PATH: if set in the config.ini file, then the plugin will use this as the sail_cSim executable, else
    will assume it's available by default in the $PATH
  - make: if set in config.ini then the plugin uses that command to execute the make file, else
    default to using the `make` command
  - jobs: if set in config.ini then the makefile is run with so many jobs in parallel, else defaults
    to 1

- initialize: This function basically sets up the compiler command for compiling tests. Currently
  the plugin defaults to using `riscv[64/32]-unknown-elf-gcc` compiler. If you are using an
  alternate toolchain or executable, you will need to edit this function.

- build: This function will simply generate the values of the a few compile arguments and check if the
  required tooling is available on the system.

- runTests: This function will first create a Makefile, where each target of the Makefile
  corresponds to compiling a specific test and then running it on the sail C-emulator. If this plugin is being
  used to collect coverage of a test via isac, then this function will also append the isac commands
  for each test in the corresponding Makefile target.

  Note, that the march values for the compiler for each test can be different and are generated from
  the test-list provided to this function.

  Once the Makefile is created, this function will execute the makefile targets in parallel
  depending on the `jobs` value selected in the \_\_init\_\_ function.

This plugin also supports coverage collection using ISAC. 

