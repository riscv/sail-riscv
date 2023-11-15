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


TESTDIRS 		:= $(wildcard *.testdir)
ARTIFACTDIRS	:= $(wildcard *.artifactdir)

$(info Including ${TEST_DIR_PATH}/lib/Makefile.common...)
include ${TEST_DIR_PATH}/lib/Makefile.common


