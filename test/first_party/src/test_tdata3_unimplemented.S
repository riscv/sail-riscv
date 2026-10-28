#include "common/encoding.h"

# Debug spec 1.0: tdata3 "is optional if no implemented triggers use it".
# With tdata3 and textra unimplemented, access raises illegal-instruction.
# tdata1 remains implemented for mcontrol6/icount.

.global main
main:
  mv t6, ra

  la t0, trap_handler
  csrw mtvec, t0

  # s1 is the address of the instruction expected to trap, or zero.
  li s1, 0
  # s3 is set by the trap handler when the expected trap occurred.
  li s3, 0
  # s4 collects one bit per failing case.
  li s4, 0

  # Case 1: tdata1 is still implemented.
  csrr t0, tdata1

  # Case 2: reading tdata3 is illegal.
  li s3, 0
  la s1, case_2_instruction
case_2_instruction:
  csrr t0, tdata3
  bnez s3, end_case_2
  ori s4, s4, 0b1
end_case_2:

  # Case 3: writing tdata3 is illegal.
  li s3, 0
  la s1, case_3_instruction
case_3_instruction:
  csrw tdata3, zero
  bnez s3, end_case_3
  ori s4, s4, 0b10
end_case_3:

end:
  mv a0, s4
  mv ra, t6
  ret

.balign 4
trap_handler:
  csrr t0, mepc
  csrr t1, mcause
  li t2, CAUSE_ILLEGAL_INSTRUCTION
  bne t1, t2, unexpected_trap
  bne t0, s1, unexpected_trap

  addi t0, t0, 4
  csrw mepc, t0
  li s3, 1
  mret

unexpected_trap:
  ori s4, s4, 0b100
  la t0, end
  csrw mepc, t0
  mret
