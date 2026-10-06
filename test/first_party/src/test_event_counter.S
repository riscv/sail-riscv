#include "common/encoding.h"

.global main
main:

  # This is a simple test to ensure event generation increments event
  # counters.  It uses events triggered by fences and misaligned load
  # accesses using the default selector codes of 0x1 and 0x2.

setup:
  # Save the return address
  mv s1, ra
  # Save the current mtvec before changing it
  csrr s2, mtvec
  # Setup trivial handler
  la t0, ignore_trap
  csrw mtvec, t0
  csrw mcause, x0
  # Enable event counters
  csrw mcountinhibit, zero
  # In case we want to test other privilege levels.
  li t0, 0xFFFFFFFF
  csrw mcounteren, t0
  # Register interest in the events
  li t0, 0x1
  csrw mhpmevent3, t0
  li t0, 0x2
  csrw mhpmevent31, t0
  # Zero counters
  csrw mhpmcounter3, zero
  csrw mhpmcounter31, zero

trigger_events:
  # Trigger fence
  fence
  # Trigger misaligned load
  la t1, test_data
  lw t2, 0x1(t1)

check_events:
  # There should be 1 instance of each registered event
  li t3, 1
  csrr t4, mhpmcounter3
  bne t3, t4, fail
  csrr t4, mhpmcounter31
  bne t3, t4, fail

setup_lcofi:
  # Setup LCOFI handler
  la t0, trap_lcofi
  csrw mtvec, t0
  csrw mcause, x0
  # Enable LCOFI interrupt
  li t0, MIP_LCOFIP
  csrs mie, t0
  li t0, MSTATUS_MIE
  csrs mstatus, t0

trigger_lcofi:
  # Trigger overflow
  li t3, -1
  csrw mhpmcounter3, t3
#if __riscv_xlen == 32
  csrw mhpmcounter3h, t3
#endif
  # Setup a test flag to ensure an interrupt occurred
  li s3, 1
  fence

check_lcofi:
  # Check test flag
  bne s3, zero, fail
  j pass

.p2align 3
ignore_trap:
  # Advance PC and return.
  csrr t5, mepc
  addi t5, t5, 4
  csrw mepc, t5
  mret

.p2align 3
trap_lcofi:
  # Check mcause is an interrupt
  csrr t0, mcause
  bge t0, zero, fail
  # Check it is LCOFI
  slli t0, t0, 1
  srli t0, t0, 1
  li t1, IRQ_LCOF
  bne t0, t1, fail
  # Clear the interrupt
  li t1, MIP_LCOFIP
  csrc mip, t1
  # Clear test flag
  mv s3, zero
  # Return
  j ignore_trap

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret

.data
.p2align 4
test_data:
  .word 0x12345678
  .word 0x87654321
