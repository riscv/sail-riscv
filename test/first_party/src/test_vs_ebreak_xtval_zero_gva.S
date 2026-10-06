#include "common/encoding.h"

// A VS-mode ebreak writes zero to stval since software_breakpoint is false
// (see software_breakpoint_xtval_zero.json).
// No GVA is written, so hstatus.GVA must be 0.

.global main
main:
  # Delegate breakpoints to HS-mode
  li t0, (1 << CAUSE_BREAKPOINT)
  csrw medeleg, t0

  # Switch to HS-mode
  li t0, MSTATUS_MPP & (MSTATUS_MPP >> 1)
  csrs mstatus, t0
  la t0, hs_mode
  csrw mepc, t0
  mret

.align 4
hs_mode:
  la t0, hs_trap_handler
  csrw stvec, t0

  # Don't delegate breakpoints further
  csrw hedeleg, zero

  # Switch to VS-mode
  li t0, HSTATUS_SPV
  csrs hstatus, t0
  li t0, SSTATUS_SPP
  csrs sstatus, t0
  la t0, guest
  csrw sepc, t0
  sret

.align 4
guest:
  ebreak
  j fail

.align 4
hs_trap_handler:
  csrr t0, scause
  li t1, CAUSE_BREAKPOINT
  bne t0, t1, fail

  # Make sure the trap came from VS-mode
  csrr t0, hstatus
  andi t1, t0, HSTATUS_SPV
  beqz t1, fail

  # Check EBREAK wrote 0 to stval
  csrr t2, stval
  bnez t2, fail

  # Check that hstatus.GVA is 0, no GVA is written to stval.
  andi t1, t0, HSTATUS_GVA
  bnez t1, fail

pass:
  li a0, 0
  ret
fail:
  li a0, 1
  ret
