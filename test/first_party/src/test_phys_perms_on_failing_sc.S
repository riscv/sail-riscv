#include "common/encoding.h"

.global main
main:
  # A simple test to ensure that a sc that fails due to a cancelled reservation
  # first also checks physical address permissions.

  # Save return address.
  mv s1, ra

  # Set up PMP bounds for a region.  This requires us to restrict the global
  # permissions set in crt0.S:init_pmp.  The linker script sets the RAM region
  # to start at 0x80000000 with a size of 512m, while the default RAM size in the
  # PMA config is 128m, so use the smaller one. To fit in a 32-bit range for RV32, take
  # the last page of RAM as the test region.
  # Assume a PMP grain of 0 as in the default config.
#define PMP_SHIFT 2
#define RAM_START 0x80000000
#define RAM_SIZE  (0x80000000 - 0x1000)
  # The forbidden test region starts beyond RAM.
#define TEST_REGION_START (RAM_START + RAM_SIZE)
#define TEST_REGION_PMP_ADDR (TEST_REGION_START >> PMP_SHIFT)
  # An address just within the RAM region.
#define RESERVE_ADDR (TEST_REGION_START - 8)
  # An address within the RAM region but outside the reservation range.
#define UNRESERVED_ADDR (RESERVE_ADDR - (1 << 8))
  # An inaccessible address in the test region.
#define TEST_ADDR TEST_REGION_START

reinit_pmp:
  # Save the current mtvec before changing it
  csrr s2, mtvec
  # Set a temporary handler that would just jump to 1:, in case PMPs or S-mode are not supported
  la t0, 1f
  csrw mtvec, t0
  # Disable address translation
  csrw satp, zero
  # Contract the first PMP region.  This works because the subsequent
  # entries set up by crt0.S:init_pmp will still allow access.
  la t0, TEST_REGION_PMP_ADDR
  csrw pmpaddr0, t0
  # Set this to have full access (redundant with crt0.S:init_pmp)
  li t1, PMP_TOR | PMP_R | PMP_W | PMP_X
  # Set the second PMP region to match the rest of memory
  la t0, -1
  csrw pmpaddr1, t0
  # Remove all permissions, and enforce it on M-mode.
  li t2, (PMP_L | PMP_TOR) << 8
  # Configure the two regions.
  or t0, t1, t2
  csrw pmpcfg0, t0
1:
  # Set trap handler for the test.
  la t0, test_trap_handler
  csrw mtvec, t0
  csrw mcause, x0

  # Token value
  li a3, -1
  # Default reservation address
  la a4, RESERVE_ADDR

test1:
  # Do a LR followed by a matching SC.
  lr.w t1, (a4)
  sc.w t1, a3, (a4)
  # This should succeed.
  bne t1, x0, fail

test2:
  # Do a LR followed by an unmatched SC.
  lr.w t1, (a4)
  la t0, UNRESERVED_ADDR
  sc.w t1, a3, (t0)
  # This should fail without exception.
  beq t1, x0, fail

test3:
  # Do a LR within region A, cancel the reservation, then do a matched SC.
  lr.w t1, (a4)
  sc.w t1, a3, (a4)
  # This should succeed and cancel the reservation.
  bne t1, x0, fail
  sc.w t1, a3, (a4)
  # This should fail without an exception.
  beq t1, x0, fail

test4:
  # There is no reservation now, so any SC should fail.  Do an SC to
  # a disallowed address.
  la t0, TEST_ADDR
failing_instruction:
  sc.w t1, a3, (t0)
  # This should fail with an Store-AMO exception, so we should not get here.
  j fail

.balign 4
test_trap_handler:
    la t2, fail
    # If mcause != SAMO-Access-Fault, return to `fail`.
    csrr t0, mcause
    li t1, CAUSE_STORE_ACCESS
    bne t0, t1, 1f
    # If mepc != `failing_instruction`, return to `fail`.
    csrr t0, mepc
    la t1, failing_instruction
    bne t0, t1, 1f
    # Otherwise return to `pass`.
    la t2, pass
1:
    csrw mepc, t2
    mret

pass:
    li a0, 0
    mv ra, s1
    ret
fail:
    li a0, 1
    mv ra, s1
    ret
