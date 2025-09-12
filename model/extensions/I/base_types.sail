/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

enum uop = {LUI, AUIPC}                          /* upper immediate ops */
enum bop = {BEQ, BNE, BLT, BGE, BLTU, BGEU}      /* branch ops */
enum iop = {ADDI, SLTI, SLTIU, XORI, ORI, ANDI}  /* immediate ops */
enum sop = {SLLI, SRLI, SRAI}                    /* shift ops */
enum rop = {ADD, SUB, SLL, SLT, SLTU, XOR,
            SRL, SRA, OR, AND}                   /* reg-reg ops */

enum ropw  = {ADDW, SUBW, SLLW, SRLW, SRAW}      /* reg-reg 32-bit ops */
enum sopw  = {SLLIW, SRLIW, SRAIW}               /* RV64-only shift ops */
