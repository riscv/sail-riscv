#include "common/encoding.h"

# Test that misaligned accesses to RAM that is configured to raise access
# faults on misaligned access actually does raise an access fault.

# This must be in the correctly configured RAM region (see config.json.in).
#define TEST_ADDRESS 0xF0000001

.global main
main:
    # Save return address in temporary register we're not using.
    mv t6, ra

    la t0, trap_handler
    csrw mtvec, t0

    li t0, TEST_ADDRESS
trapping_instruction:
    lw t0, 0(t0)
    # We should get a trap; if not it's a failure.
    j fail

.balign 4
trap_handler:
    # mepc should be `trapping_instruction`.
    csrr t0, mepc
    la t1, trapping_instruction
    bne t0, t1, fail

    # mtval should be the test address.
    csrr t0, mtval
    li t1, TEST_ADDRESS
    bne t0, t1, fail

    # mcause should be access fault.
    csrr t0, mcause
    li t1, CAUSE_LOAD_ACCESS
    bne t0, t1, fail

    j pass

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
