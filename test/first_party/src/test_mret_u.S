#include "common/encoding.h"

.global main
main:
  # This test ensures we can't mret into U when misa.U is clear.

  # Save return address in temporary register we're not using.
  mv s1, ra

#define MISA_U 20
#define MISA_S 18

  # Check if misa.U is writable.

  csrr s2, misa
  li s3, 1 << MISA_U

  # Try to toggle misa.U
  srli t0, s2, MISA_U
  andi t0, t0, 1
  beqz t0, try_set_u
try_clear_u:
  # This also clears misa.S if that is set.
  csrc misa, s3
  j check_immut
try_set_u:
  csrs misa, s3
check_immut:
  # Compare with the original value.  If there is no change,
  # pass the test since misa.U is read-only and this test is
  # irrelevant.
  csrr t0, misa
  beq t0, s2, pass

set_u:
  # Ensure that misa.U is set.  This will make
  # mstatus.MPP legal below.
  csrs misa, s3

set_mstatus_mpp:
  # Set mstatus.MPP to U.
  li s4, MSTATUS_MPP
  not t1, s4
  csrr t0, mstatus
  and t0, t0, t1
  csrw mstatus, t0

clear_u:
  # Now clear misa.U.
  csrc misa, s3

  # misa.S should be zero.
  csrr t0, misa
  srli t0, t0, MISA_S
  andi t0, t0, 1
  bnez t0, fail

  # A breakpoint will be used to trap into M-mode.  This
  # will be handled in M-mode, since medeleg is irrelevant
  # now that S-mode has been disabled.

test:
  # Set execution address for U-mode.
  la t0, user_space
  csrw mepc, t0
  # Save old trap-handler
  csrr s5, mtvec
  # Tap to check_mstatus
  la t0, check_mstatus
  csrw mtvec, t0
  mret
user_space:
  # To get `cur_privilege`, trap using a breakpoint
  # and then check mstatus.MPP.
  ebreak
  nop

check_mstatus:
  # Restore old trap-handler
  csrw mtvec, s5
  # Check cause
  csrr t0, mcause
  li t1, CAUSE_BREAKPOINT
  bne t0, t1, fail
  # Check trap origin
  csrr t0, mepc
  la t1, user_space
  bne t0, t1, fail
  # Check mstatus.MPP
  csrr t0, mstatus
  and t0, t0, s4
  # If zero, we were in U-mode.
  beqz t0, fail

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret
