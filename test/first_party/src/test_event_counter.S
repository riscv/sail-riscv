.global main
main:

  # This is a simple test to ensure event generation increments event
  # counters.  It uses events triggered by misaligned load and store
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
  la t1, test_data
  lw t2, 0x2(t1)
  sw t2, 0x2(t1)

check_events:
  # Restore trap handler
  csrw mtvec, s2
  # There should be 1 instance of each registered event
  li t3, 1
  csrr t4, mhpmcounter3
  bne t3, t4, fail
  csrr t4, mhpmcounter31
  bne t3, t4, fail
  j pass

.p2align 3
ignore_trap:
  # Advance PC and return.
  csrr t5, mepc
  addi t5, t5, 4
  csrw mepc, t5
  mret

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
