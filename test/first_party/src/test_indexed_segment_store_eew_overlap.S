#include "common/encoding.h"

# The vector spec requires that a vector register is not read with more than
# one EEW by a single instruction, "including when the vector register appears
# at different positions within two or more vector register groups"
# (norm:vreg_source_eew_rsv). Overlapping source operands are allowed when
# both of them are read with the same EEW.
#
# Indexed segment stores read the index register group with the index EEW and
# all of the nf data fields with EEW=SEW, so every field takes part in that
# rule and not just the first one.

.global main
main:
  # Save return address in temporary register.
  mv t6, ra

  # Enable vector.
  li t0, MSTATUS_VS
  csrs mstatus, t0

  # Set trap handler.
  la t0, trap_handler
  csrw mtvec, t0

  # Address the stores below write to. An index of zero is used for the data,
  # but a wrong index must not fault, so make this buffer large enough for
  # the largest possible byte index.
  la a0, scratch

  # s1 is the address of the instruction that is expected to raise an
  # illegal instruction exception, or zero when no trap is expected.
  li s1, 0
  # s3 is set by the trap handler when the expected trap has occurred.
  li s3, 0
  # s4 collects one bit per case that does not behave as expected, so that
  # the failure output names every case that is wrong.
  li s4, 0

  # Case 1: the index EEW is 32, which is also SEW, so reading v2 as both
  # the index group and the first data field is legal.
  vsetivli zero, 2, e32, m1, ta, ma
  vxor.vv v2, v2, v2
  vsuxseg2ei32.v v2, (a0), v2

  # Case 2: as case 1 but with LMUL=2.
  vsetivli zero, 2, e32, m2, ta, ma
  vxor.vv v4, v4, v4
  vsuxseg2ei32.v v4, (a0), v4

  # Case 3: SEW is 32 but the index EEW is 8. The data fields are v2 and v3
  # and the index group is v3, so v3 is read with two different EEWs.
  vsetivli zero, 2, e32, m1, ta, ma
  vxor.vv v3, v3, v3
  la s1, case_3_instruction
case_3_instruction:
  vsuxseg2ei8.v v2, (a0), v3
  bnez s3, end_case_3
  ori s4, s4, 0b1000
end_case_3:

  # Case 4: as case 3 but with LMUL=2, so the data fields are v4:v5 and
  # v6:v7 and the index group is v6, i.e. the index overlaps the second data
  # field instead of the first one.
  vsetivli zero, 2, e32, m2, ta, ma
  vxor.vv v6, v6, v6
  li s3, 0
  la s1, case_4_instruction
case_4_instruction:
  vsuxseg2ei8.v v4, (a0), v6
  bnez s3, end_case_4
  ori s4, s4, 0b10000
end_case_4:

end:
  mv a0, s4
  mv ra, t6
  ret

.balign 4
trap_handler:
  # Only an illegal instruction exception raised by the instruction that is
  # expected to trap is acceptable.
  csrr t0, mepc
  csrr t1, mcause
  li t2, CAUSE_ILLEGAL_INSTRUCTION
  bne t1, t2, unexpected_trap
  bne t0, s1, unexpected_trap

  # Resume after the trapping instruction and record that it trapped.
  addi t0, t0, 4
  csrw mepc, t0
  li s3, 1
  mret

unexpected_trap:
  # Stop the test, since resuming the instruction that trapped unexpectedly
  # would just trap again.
  ori s4, s4, 0b100000
  la t0, end
  csrw mepc, t0
  mret

.bss
.balign 16
scratch:
  .space 1024
