/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Instruction definitions.
 *
 * This includes decoding, execution, and assembly parsing and printing.
 */

scattered union instruction

/* returns whether an instruction was retired, used for computing minstret */
val execute : instruction -> ExecutionResult
scattered function execute

val assembly : instruction <-> string
scattered mapping assembly

val encdec : instruction <-> bits(32)
scattered mapping encdec

val encdec_compressed : instruction <-> bits(16)
scattered mapping encdec_compressed

/*
 * We declare the ILLEGAL/C_ILLEGAL instruction clauses here instead of in
 * riscv_insts_end, so that model extensions can make use of them.
 * However, the encdec mapping must come last to ensure that all
 * unmatched encodings decode to an illegal instruction.
 */
union clause instruction = ILLEGAL : word
union clause instruction = C_ILLEGAL : half
