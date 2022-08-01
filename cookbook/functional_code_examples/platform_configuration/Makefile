# vim: tabstop=4  shiftwidth=4  noexpandtab
# --------------------------------------------------------------------------------------------
# @file			Makefile
#
#               LICENSE:
#
#               Copyright 2021 Seagate Technology LLC and/or its Affiliates
#               
#               Licensed under the Apache License, Version 2.0 (the "License");
#               you may not use this file except in compliance with the License.
#               You may obtain a copy of the License at
#               
#                   http://www.apache.org/licenses/LICENSE-2.0
#               
#               Unless required by applicable law or agreed to in writing, software
#               distributed under the License is distributed on an "AS IS" BASIS,
#               WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#               See the License for the specific language governing permissions and
#               limitations under the License.
#
#
#
# @brief		Makefile for building a sample test for stimulating a RISC-V trace encoder
#
#
#				History:  See git log
#
# @author		Bill McSpadden (bill.mcspadden@seagate.com)
# --------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------
# USER MUST SET THESE TO A PROPER SETTING

XLEN			:= 32
TOOL_OPT		:= linux-gnu
RISCV			:= /opt/riscv${XLEN}
CONFIG_BASE		:= 0x80000000
MARCH          	:= -march=rv32imc -mabi=ilp32
LD_FILE			:= ./riscv_test.ld
RUN_TOOL		:= ../../../c_emulator/riscv_sim_RV32

# USER MUST SET THESE TO A PROPER SETTING
# --------------------------------------------------------------------------------------------
#
#

ifndef RISCV
$(error The make variable, RISCV, must be set.  It is the path to the compiler tool chain)
endif

ifndef CONFIG_BASE
$(error The make variable, CONFIG_BASE,  is not defined.  It is needed for the test variable, also named CONFIG_BASE)
endif

ifndef MARCH
$(error The make variable, MARCH, must be set.)
endif

ifndef RUN_TOOL
$(error The make variable, RUN_TOOL, must be set.)
endif


BIN				:= ${RISCV}/bin

CC				:= ${BIN}/riscv${XLEN}-unknown-${TOOL_OPT}-gcc
ASM				:= ${BIN}/riscv${XLEN}-unknown-${TOOL_OPT}-gcc
LD				:= ${BIN}/riscv${XLEN}-unknown-${TOOL_OPT}-ld
OBJDUMP			:= ${BIN}/riscv${XLEN}-unknown-${TOOL_OPT}-objdump

TARGET			:= test.elf
DUMP			:= $(subst .elf,.dump,${TARGET})

ASM_SRC			:= $(wildcard *.S *.s)
ASM_OBJS		:= $(subst .S,.o,${ASM_SRC}) 
ASM_FLAGS		:= -DCONFIG_BASE=${CONFIG_BASE} ${MARCH}
OBJDUMPFLAGS	= -t -Dz -Mnumeric

C_SRC		:= $(wildcard *.c)
C_OBJS		:= $(subst .c,.o,${C_SRC})
C_FLAGS		:= -DCONFIG_BASE=${CONFIG_BASE} ${MARCH}

LD_FLAGS	:= -T ${LD_FILE}

OBJS		:= ${ASM_OBJS} ${C_OBJS}

OUT_FILE		:= ./sim.out

$(info =================================================================)
$(info Make variable settings....)
$(info     RISCV:     ${RISCV})
$(info     ASM_SRC:   ${ASM_SRC})
$(info     ASM_FLAGS: ${ASM_FLAGS})
$(info     ASM_OBJS:  ${ASM_OBJS})
$(info     C_SRC:     ${C_SRC})
$(info     C_FLAGS:   ${C_FLAGS})
$(info     C_OBJS:    ${C_OBJS})
$(info     OBJS:      ${OBJS})
$(info     LD_FLAGS:  ${LD_FLAGS})
$(info     TARGET:    ${TARGET})
$(info     DUMP:      ${DUMP})
$(info =================================================================)

all: ${TARGET} ${DUMP}

${TARGET}	: ${OBJS} ${LD_FILE}
	${LD} ${LD_FLAGS} -o $@ ${OBJS}

${DUMP} : ${TARGET}
	${OBJDUMP} ${OBJDUMPFLAGS} ${TARGET} > $@

%.o	: %.S
	${ASM} -c ${ASM_FLAGS} -o $@ $<

%.o	: %.c
	${CC} -c ${C_FLAGS} -o $@ $<

build: ${TARGET} ${DUMP}

dump: ${DUMP}

install:

clean:
	rm -f ${OBJS} ${TARGET} ${DUMP} ${OUT_FILE}

run: ${TARGET}
	${RUN_TOOL} ${TARGET} -y rv32i_platform.yaml -u rv32i_isa.yaml 2>&1 | tee ${OUT_FILE}

ddd: ${TARGET}
	echo "${TARGET} -y rv32i_platform.yaml -u rv32i_isa.yaml" ;
	ddd ${RUN_TOOL}

clean_all: clean






