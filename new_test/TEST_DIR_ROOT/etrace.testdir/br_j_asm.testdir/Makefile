# vim: set tabstop=4 shiftwidth=4 noexpandtab
# ====================================================================================================================
# Filename:		Makefile
#
# Description:	Makefile for building and running 
#
# Author(s):	Bill McSpadden (bill@riscv.org)
#
# Revision:		See git log
#
# ====================================================================================================================
#
# SHELL is set to /bin/sh as default for make
#	On Ubuntu,  /bin/sh is a symlink to /bin/dash
#	/bin/dash does not behave much like bash.
#	I want bash to be the shell we use in this environment,
#	not dash.
SHELL := /bin/bash
$(info SHELL: ${SHELL})

# TEST_DIR_PATH_KEYDIR is the directory name under which the
#	test directory exists.  This directory contains the items
#	needed to build and run RISC-V tests.  This keyword is needed
#	in order that this makefile and all 'included' makefiles can
#	find the consistent set of tools for building and running
#	tests.
TEST_DIR_PATH_KEYDIR := TEST_DIR_ROOT

# TEST_DIR_PATH is the full directory path to the current test
#	directory.  This is an important variable for running in this 
#	particular enviornment.
TEST_DIR_PATH	:= $(shell 														\
	sandbox_root=$$PWD ;														\
	if [[ "$$sandbox_root" =~ /${TEST_DIR_PATH_KEYDIR}/ ]] ; 					\
		then 																	\
		while [ ! `basename $$sandbox_root` == ${TEST_DIR_PATH_KEYDIR} ] ;		\
			do																	\
			sandbox_root=`dirname $$sandbox_root`; 								\
			if [[ $sandbox_root == "/" ]] ;										\
                then															\
		        echo "NULL" ;													\
                break ;															\
                fi;																\
			done ;																\
		echo "$$sandbox_root" ;													\
	else																		\
		echo "NULL" ;															\
		fi;																		\
	)

$(info TEST_DIR_PATH: ${TEST_DIR_PATH})
$(info TEST_DIR_PATH realpath: $(realpath ${TEST_DIR_PATH}))
$(info TEST_DIR_PATH abspath:  $(abspath ${TEST_DIR_PATH}))

# Use the GNU Make Standard Library.  It provides a Make API
#	for useful data structures and functions.
include ${TEST_DIR_PATH}/lib/gmsl.git/gmsl

#=========================================================
# List of source files that are the source for a test
C_SRC		:= $(wildcard *.c)
ASM_SRC		:= $(wildcard *.S *.s)

C_OBJS		:= $(subst .s,.o,$(subst .S,.o,${ASM_SRC}))
ASM_OBJS	:= $(subst .s,.o,$(subst .S,.o,${ASM_SRC}))
OBJS_BASE	:= ${C_OBJS} ${ASM_OBJS}

#=========================================================
# Per test-instance test definition
#	These variables are what make the instance of the test
#	unique. 

CONFIG_BASE		:= 0x80000000
MARCH          	:= -march=rv32imc_zicsr -mabi=ilp32

CC_FLAGS	:= 
OBJS_TMP	:= ${ASM_OBJS} ${C_OBJS}
ASM_FLAGS 	:= -DCONFIG_BASE=${CONFIG_BASE} ${MARCH}
LD_FILE 	:= 
LD_FLAGS	:= -T riscv_test.ld
RUN_FLAGS 	:= 
XLEN		:= 32
OBJDIR_TMP	:= $(strip ${XLEN} ${ASM_FLAGS} ${CC_FLAGS} ${LD_FILE} ${LD_FLAGS} ${RUN_FLAGS})


# Create a unique objdir name for the variations of the test.
# make does not do a good, general job of string processing with
#	spaces,  so we'll use sed instead with

UNIQ_TESTNAME  	:= $(shell echo ${OBJDIR_TMP} | sed 's/ /__/g' | sed 's/-/_/g' | sed 's/=/_/g')
$(info UNIQ_TESTNAME: ${UNIQ_TESTNAME})

OBJDIR			:= $(addsuffix .artifactdir,${UNIQ_TESTNAME})
$(info OBJDIR: ${OBJDIR})

OBJS		:= $(addprefix ${OBJDIR}/,${OBJS_TMP})

TESTLIST 		:= $(call set_insert,${UNIQ_TESTNAME},${TESTLIST})
TESTLIST_BUILD	:= $(call set_insert,${OBJDIR}/test.elf,${TESTLIST_BUILD})
OBJDIRS_SET   	:= $(call set_insert,${OBJDIR},${OBJDIRS_SET})

$(call set,C_SRC_AA,${UNIQ_TESTNAME},${C_SRC})
$(call set,CC_FLAGS_AA,${UNIQ_TESTNAME},${CC_FLAGS})
$(call set,ASM_SRC_AA,${UNIQ_TESTNAME},${ASM_SRC})
$(call set,ASM_FLAGS_AA,${UNIQ_TESTNAME},${ASM_FLAGS})
$(call set,RUN_FLAGS_AA,${UNIQ_TESTNAME},${RUN_FLAGS})
$(call set,XLEN_AA,${UNIQ_TESTNAME},${XLEN})
$(call set,OBJDIR_AA,${UNIQ_TESTNAME},${OBJDIR})
$(call set,OBJS_AA,${UNIQ_TESTNAME},${OBJS})
$(call set,LD_FLAGS_AA,${UNIQ_TESTNAME},${LD_FLAGS})

$(info TESTLIST_BUILD: ${TESTLIST_BUILD})
$(info C_SRC: $(call get,C_SRC_AA,${UNIQ_TESTNAME}))
$(info ASM_SRC: $(call get,ASM_SRC_AA,${UNIQ_TESTNAME}))
$(info ASM_FLAGS: $(call get,ASM_FLAGS_AA,${UNIQ_TESTNAME}))
$(info RUN_FLAGS: $(call get,RUN_FLAGS_AA,${UNIQ_TESTNAME}))
$(info XLEN: $(call get,XLEN_AA,${UNIQ_TESTNAME}))
$(info OBJDIR: $(call get,OBJDIR_AA,${UNIQ_TESTNAME}))
$(info OBJS: $(call get,OBJS_AA,${UNIQ_TESTNAME}))
$(info LD_FLAGS: $(call get,LD_FLAGS_AA,${UNIQ_TESTNAME}))
#=========================================================
#=========================================================
# A test definition

CONFIG_BASE		:= 0x80000000
MARCH          	:= -march=rv64imc_zicsr -mabi=lp64

CC_FLAGS	:= 
OBJS_TMP	:= ${ASM_OBJS} ${C_OBJS}
ASM_FLAGS 	:= -DCONFIG_BASE=${CONFIG_BASE} ${MARCH}
LD_FILE 	:= 
LD_FLAGS	:= -T riscv_test.ld
RUN_FLAGS 	:= 
XLEN		:= 64
OBJDIR_TMP	:= $(strip ${XLEN} ${ASM_FLAGS} ${CC_FLAGS} ${LD_FILE} ${LD_FLAGS} ${RUN_FLAGS})


# Create a unique objdir name for the variations of the test.
# make does not do a good, general job of string processing with
#	spaces,  so we'll use sed instead with

UNIQ_TESTNAME  	:= $(shell echo ${OBJDIR_TMP} | sed 's/ /__/g' | sed 's/-/_/g' | sed 's/=/_/g')
$(info UNIQ_TESTNAME: ${UNIQ_TESTNAME})

OBJDIR			:= $(addsuffix .artifactdir,${UNIQ_TESTNAME})
$(info OBJDIR: ${OBJDIR})

OBJS		:= $(addprefix ${OBJDIR}/,${OBJS_TMP})

TESTLIST 		:= $(call set_insert,${UNIQ_TESTNAME},${TESTLIST})
TESTLIST_BUILD	:= $(call set_insert,${OBJDIR}/test.elf,${TESTLIST_BUILD})
OBJDIRS_SET   	:= $(call set_insert,${OBJDIR},${OBJDIRS_SET})
$(info TESTLIST_BUILD: ${TESTLIST_BUILD})
$(call set,C_SRC_AA,${UNIQ_TESTNAME},${C_SRC})
$(info C_SRC: $(call get,C_SRC_AA,${UNIQ_TESTNAME}))
$(call set,ASM_SRC_AA,${UNIQ_TESTNAME},${ASM_SRC})
$(info ASM_SRC: $(call get,ASM_SRC_AA,${UNIQ_TESTNAME}))
$(call set,ASM_FLAGS_AA,${UNIQ_TESTNAME},${ASM_FLAGS})
$(info ASM_FLAGS: $(call get,ASM_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,RUN_FLAGS_AA,${UNIQ_TESTNAME},${RUN_FLAGS})
$(info RUN_FLAGS: $(call get,RUN_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,XLEN_AA,${UNIQ_TESTNAME},${XLEN})
$(info XLEN: $(call get,XLEN_AA,${UNIQ_TESTNAME}))
$(call set,OBJDIR_AA,${UNIQ_TESTNAME},${OBJDIR})
$(info OBJDIR: $(call get,OBJDIR_AA,${UNIQ_TESTNAME}))
$(call set,OBJS_AA,${UNIQ_TESTNAME},${OBJS})
$(info OBJS: $(call get,OBJS_AA,${UNIQ_TESTNAME}))
$(call set,LD_FLAGS_AA,${UNIQ_TESTNAME},${LD_FLAGS})
$(info LD_FLAGS: $(call get,LD_FLAGS_AA,${UNIQ_TESTNAME}))
#=========================================================

$(info TESTLIST: ${TESTLIST})

TESTDIRS 		:= $(wildcard *.testdir)
ARTIFACTDIRS	:= $(wildcard *.artifactdir)

include ${TEST_DIR_PATH}/lib/Makefile.common


