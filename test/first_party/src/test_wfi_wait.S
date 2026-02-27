#include "common/encoding.h"

.global main
main:
  # This is a test to ensure WFI waits and can be interrupted.
  # It assumes a configuration where WFI is not a NOP, and can
  # wait at least 10 steps.

  # Save return address in temporary register we're not using.
  mv t6, ra

# Ensure at least 10 steps for an uninterrupted WFI.
test1:
  csrr t0, mcycle
  wfi
  csrr t1, mcycle
  addi t2, t0, 10
  blt t1, t2, fail

# Test that a waiting WFI can be interrupted.
test2:
  # Save mtvec before changing it.
  csrr s0, mtvec
  # Set trap handler for the test.
  la t0, test_trap_handler
  csrw mtvec, t0
  csrw mcause, 0
  # Don't delegate STI
  csrw mideleg, 0
  # Don't inhibit counters.
  csrw mcountinhibit, 0

  # Disable stimecmp until we need it
  li t0, -1
  csrw stimecmp, t0
  # Enable menvcfg.STCE so that STI using stimecmp works.
#if __riscv_xlen == 64
  li t0, MENVCFG_STCE
  csrs menvcfg, t0
#else
  li t0, MENVCFGH_STCE
  csrs menvcfgh, t0
#endif

  # Enable STI.
  li t0, MIP_STIP
  csrs mie, t0
  # Set timer for STI to fire 10 steps from now, during WFI.
  csrr t0, mcycle
  addi t0, t0, 10
  csrw stimecmp, t0
  # Enable interrupts.
  li t0, MSTATUS_MIE
  csrs mstatus, t0
wfi_pc:
  wfi
  # Should have been interrupted before getting here.
  csrw mtvec, s0
  j fail

.balign 4
test_trap_handler:
  # Disable interrupts.
  csrw mie, x0
  # Restore mtvec.
  csrw mtvec, s0
  la s0, fail
  # Should have trapped in WFI.  WFI actually retires
  # when interrupted, so mepc is 4 past wfi_pc.
  csrr t0, mepc
  la t1, wfi_pc
  add t1, t1, 4
  bne t0, t1, 1f
  # Should have trapped due to an interrupt.
  csrr t0, mcause
  bgtz t0, 1f
  la s0, pass

1:
  csrw mepc, s0
  mret

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
