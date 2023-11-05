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
# A test definition

ASM_FLAGS 	:=
RUN_FLAGS 	:= -h
XLEN		:= RV32
OBJDIR_TMP	:= $(strip ${XLEN} ${ASM_FLAGS} ${RUN_FLAGS})


# Create a unique objdir name for the variations of the test.
# make does not do a good, general job of string processing with
#	spaces,  so we'll use sed instead with

UNIQ_TESTNAME  	:= $(shell echo ${OBJDIR_TMP} | sed 's/ /__/g' | sed 's/-/_/g')
$(info UNIQ_TESTNAME: ${UNIQ_TESTNAME})

OBJDIR			:= $(addsuffix .artifactdir,${UNIQ_TESTNAME})
$(info OBJDIR: ${OBJDIR})

TESTLIST 		:= $(call set_insert,${UNIQ_TESTNAME},${TESTLIST})
$(call set,ASM_FLAGS_AA,${UNIQ_TESTNAME},${ASM_FLAGS})
$(info ASM_FLAGS: $(call get,ASM_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,RUN_FLAGS_AA,${UNIQ_TESTNAME},${RUN_FLAGS})
$(info RUN_FLAGS: $(call get,RUN_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,XLEN_AA,${UNIQ_TESTNAME},${XLEN})
$(info XLEN: $(call get,XLEN_AA,${UNIQ_TESTNAME}))
#=========================================================

#=========================================================
# A test definition

C_SRC		:= $(wildcard *.c)
C_OBJS		:= $(subst .c,.o,${C_SRC})
CC_FLAGS	:= 
ASM_SRC		:= $(wildcard *.S *.s)
ASM_OBJS	:= $(subst .s,.o,$(subst .S,.o,${ASM_SRC}))
OBJS		:= ${C_OBJS} ${ASM_OBJS}
ASM_FLAGS 	:=
LD_FILE 	:= 
LD_FLAGS	:=
RUN_FLAGS 	:= -h
XLEN		:= RV64
OBJDIR_TMP	:= $(strip ${XLEN} ${ASM_FLAGS} ${CC_FLAGS} ${LD_FILE} ${LD_FLAGS} ${RUN_FLAGS})


# Create a unique objdir name for the variations of the test.
# make does not do a good, general job of string processing with
#	spaces,  so we'll use sed instead with

UNIQ_TESTNAME  	:= $(shell echo ${OBJDIR_TMP} | sed 's/ /__/g' | sed 's/-/_/g')
$(info UNIQ_TESTNAME: ${UNIQ_TESTNAME})

OBJDIR			:= $(addsuffix .artifactdir,${UNIQ_TESTNAME})
$(info OBJDIR: ${OBJDIR})

TESTLIST 		:= $(call set_insert,${UNIQ_TESTNAME},${TESTLIST})
$(call set,ASM_FLAGS_AA,${UNIQ_TESTNAME},${ASM_FLAGS})
$(info ASM_FLAGS: $(call get,ASM_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,RUN_FLAGS_AA,${UNIQ_TESTNAME},${RUN_FLAGS})
$(info RUN_FLAGS: $(call get,RUN_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,XLEN_AA,${UNIQ_TESTNAME},${XLEN})
$(info XLEN: $(call get,XLEN_AA,${UNIQ_TESTNAME}))
#=========================================================
#=========================================================
# A test definition

ASM_FLAGS 	:=
RUN_FLAGS 	:= -invalid_switch
XLEN		:= RV64
OBJDIR_TMP	:= $(strip ${XLEN} ${ASM_FLAGS} ${RUN_FLAGS})


# Create a unique objdir name for the variations of the test.
# make does not do a good, general job of string processing with
#	spaces,  so we'll use sed instead with

UNIQ_TESTNAME  	:= $(shell echo ${OBJDIR_TMP} | sed 's/ /__/g' | sed 's/-/_/g')
$(info UNIQ_TESTNAME: ${UNIQ_TESTNAME})

OBJDIR			:= $(addsuffix .artifactdir,${UNIQ_TESTNAME})
$(info OBJDIR: ${OBJDIR})

TESTLIST 		:= $(call set_insert,${UNIQ_TESTNAME},${TESTLIST})
$(call set,ASM_FLAGS_AA,${UNIQ_TESTNAME},${ASM_FLAGS})
$(info ASM_FLAGS: $(call get,ASM_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,RUN_FLAGS_AA,${UNIQ_TESTNAME},${RUN_FLAGS})
$(info RUN_FLAGS: $(call get,RUN_FLAGS_AA,${UNIQ_TESTNAME}))
$(call set,XLEN_AA,${UNIQ_TESTNAME},${XLEN})
$(info XLEN: $(call get,XLEN_AA,${UNIQ_TESTNAME}))
#=========================================================

$(info TESTLIST: ${TESTLIST})

TESTDIRS 		:= $(wildcard *.testdir)
ARTIFACTDIRS	:= $(wildcard *.artifactdir)








all:


build:


install:


# Run in parallel (potentially,  based on the -j switch to make)
#	TODO: also redirect stderr into test.failed
.PHONY: ${TESTLIST}
run_tests : ${TESTLIST}
${TESTLIST} :
	@echo "making \"$@\"" ;
	@mkdir -p $@.artifactdir || ( echo "unable to create $@.artifactdir" >> test.failed ; exit $$? ; ) ;
	@if [ ! -e ${TEST_DIR_PATH}/../../c_emulator/riscv_sim_$(call get,XLEN_AA,$@) ] ; 									\
		then																						\
		echo "${TEST_DIR_PATH}/../../c_emulator/riscv_sim_$@.$(call get,XLEN_AA,$@) does not exist." >> $@.artifactdir/test.failed ;	\
		fi ;
	@${TEST_DIR_PATH}/../../c_emulator/riscv_sim_$(call get,XLEN_AA,$@) $(call get,arr_sw,$@)> $@.artifactdir/test.run.stdout	; 					\
	if [ $$? -ne 0 ] ;                                              								\
		then                                                            							\
		echo "riscv_sim_$@.$(call get,XLEN_AA,$@) exited with nonzero exit status" >> $@.artifactdir/test.failed ;						\
		fi ;
	@if [ ! -e $@.artifactdir/test.run.stdout ] ;																\
		then																						\
		echo "file, \"$@.artifactdir/test.run.stdout\" not found" >> $@.artifactdir/test.failed ;										\
		fi ;
	@if [ ! -e $@.artifactdir/test.failed ] ;																	\
		then																						\
		echo "${PWD} passed" >> $@.artifactdir/test.passed ;													\
		fi;


# Gather all the test results from this directory  on down.
#	Do not run this target in parallel,  else the output into
#	./test.failed will get intermixed and become unreadable.
check :
	@echo "$$PWD: making \"$@\"" ;
	@rm -f test.passed test.failed ;
	@for testdir in ${TESTDIRS}; 										\
		do																\
		if [ ! -e $$testdir/Makefile ] ;								\
			then														\
			echo "ERROR: no Makefile in $$testdir." >> test.failed;		\
			fi ;														\
		make -C $$testdir $@ ;											\
		if [ $$? -ne 0 ] ;                                              			\
			then                                                            		\
			echo "'make -C $$testdir $@' exited with nonzero exit status" >> test.failed ;	\
			fi ;																			\
		done;
	@for artifactdir in ${ARTIFACTDIRS}; 										\
		do																		\
		if [ -e $$artifactdir/test.failed ] ;									\
			then																\
			echo "$$artifactdir/test.failed exists." >> test.failed;			\
			cat $$artifactdir/test.failed >> test.failed ;						\
			fi;																	\
		if [ -e $$artifactdir/test.passed ] ;									\
			then																\
			echo "$$PWD/$$artifactdir/test.passed exists." >> test.passed;			\
			fi;																	\
		if [ ! -e $$artifactdir/test.failed ] ;									\
			then																\
			if [ ! -e $$artifactdir/test.passed ] ;								\
				then															\
				echo "neither $$PWD/$$artifactdir/test.failed nor test.passed exists." >> test.failed ; 	\
				fi ;																				\
			fi;																						\
		done ;
	
	

clean:
	rm -f test.failed test.passed
	rm -rf *.artifactdir

# Cleans local artifacts and the install location
clean_all:



