#include "common/encoding.h"

# Shlcofideleg: "If the Shlcofideleg extension is implemented, hideleg bit 13
# is writable; otherwise, it is read-only zero. When bit 13 of hideleg is zero,
# vsip.LCOFIP and vsie.LCOFIE are read-only zeros. Else, vsip.LCOFIP and
# vsie.LCOFIE are aliases of sip.LCOFIP and sie.LCOFIE."
#
# This test checks each of those statements, and that a pending LCOFI that is
# delegated through mideleg and hideleg is taken in VS-mode with cause 13.

.global main
main:
  # Delegate LCOFI from M-mode to HS-mode. Leave it disabled in mie for now.
  li t0, MIP_LCOFIP
  csrs mideleg, t0

  # Switch to HS-mode.
  li t0, MSTATUS_MPP & (MSTATUS_MPP >> 1)
  csrs mstatus, t0
  la t0, hs_mode
  csrw mepc, t0
  mret

.align 4
hs_mode:
  # No trap should reach HS-mode in this test.
  la t0, fail
  csrw stvec, t0
  la t0, vs_trap_handler
  csrw vstvec, t0

  li t1, MIP_LCOFIP

  # hideleg bit 13 is clear: writes to vsie.LCOFIE are ignored ...
  csrs vsie, t1
  csrr t0, vsie
  and t0, t0, t1
  bnez t0, fail
  csrr t0, sie
  and t0, t0, t1
  bnez t0, fail

  # ... and vsip.LCOFIP reads as zero even when sip.LCOFIP is set.
  # LCOFI is still disabled in sie, so it does not trap.
  csrs sip, t1
  csrr t0, sip
  and t0, t0, t1
  beqz t0, fail
  csrr t0, vsip
  and t0, t0, t1
  bnez t0, fail

  # hideleg bit 13 is writable.
  csrs hideleg, t1
  csrr t0, hideleg
  and t0, t0, t1
  beqz t0, fail

  # vsip.LCOFIP is now an alias of sip.LCOFIP.
  csrr t0, vsip
  and t0, t0, t1
  beqz t0, fail

  # vsie.LCOFIE is now an alias of sie.LCOFIE.
  csrs vsie, t1
  csrr t0, sie
  and t0, t0, t1
  beqz t0, fail

  # Enable interrupts for VS-mode and enter the guest. The pending LCOFI is
  # delegated to VS-mode, so it traps to vs_trap_handler immediately.
  li t0, SSTATUS_SIE
  csrs vsstatus, t0
  li t0, HSTATUS_SPV
  csrs hstatus, t0
  li t0, SSTATUS_SPP
  csrs sstatus, t0
  la t0, guest
  csrw sepc, t0
  sret

.align 4
guest:
  # LCOFI should have been taken on entry to VS-mode.
  j fail

.align 4
vs_trap_handler:
  # vscause must be interrupt 13 (not translated, unlike the VS-level
  # interrupts 2, 6 and 10).
  csrr t0, scause
  bgez t0, fail
  slli t0, t0, 1
  srli t0, t0, 1
  li t2, IRQ_LCOF
  bne t0, t2, fail

  # The guest sees LCOFIP in its sip (vsip).
  li t1, MIP_LCOFIP
  csrr t0, sip
  and t0, t0, t1
  beqz t0, fail

  # Clearing it through the alias clears the pending interrupt.
  csrc sip, t1
  csrr t0, sip
  and t0, t0, t1
  bnez t0, fail

  j pass

pass:
  li a0, 0
  ret
fail:
  li a0, 1
  ret
