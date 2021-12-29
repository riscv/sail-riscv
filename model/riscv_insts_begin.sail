/* Instruction definitions.
 *
 * This includes decoding, execution, and assembly parsing and printing.
 */

scattered union ast

/* returns whether an instruction was retired, used for computing minstret */
val execute : ast -> Retired effect {escape, wreg, rreg, wmv, wmvt, eamem, rmem, rmemt, barr, exmem, undef}
scattered function execute

val assembly : ast <-> string
scattered mapping assembly

val encdec : ast <-> bits(32) effect {rreg}
scattered mapping encdec

val encdec_compressed : ast <-> bits(16) effect {rreg}
scattered mapping encdec_compressed
