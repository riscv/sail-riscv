#include "common/encoding.h"

.global main
main:
    # Simple test to double check that using misaligned vector register groups
    # raises an illegal instruction exception. This is reserved behaviour
    # so this test is specific to the default configuration of the Sail model.

    # Save return address in temporary register we're not using.
    mv t6, ra

    # Enable vector.
    li t0, MSTATUS_VS
    csrs mstatus, t0

    # Set LMUL to 2
    vsetivli zero, 0, e32, m2

    # Set trap handler
    la t0, trap_handler
    csrw mtvec, t0

    # Vector add with even registers should be fine.
    vadd.vv v0, v2, v4

    # Do a vector add from an odd register.
failing_instruction:
    vadd.vv v0, v2, v5

    # There should be an exception. If we get here it failed.
    j fail

.balign 4
trap_handler:
    la t2, fail

    # If mcause != ILLEGAL, return to `fail`.
    csrr t0, mcause
    li t1, CAUSE_ILLEGAL_INSTRUCTION
    bne t0, t1, 1f

    # If mtval != `failing_instruction`, return to `fail`.
    csrr t0, mtval
    la t1, failing_instruction
    bne t0, t1, 1f

    # Otherwise return to `pass`.
    la t2, pass
1:
    csrw mepc, t2
    mret

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
