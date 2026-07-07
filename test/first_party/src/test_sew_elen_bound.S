#include "common/encoding.h"

# This test should run on a system with ELEN=32.
# See the "elen_32.json" config override.

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

    # Try to set an SEW that exceeds ELEN, i.e. SEW=64 for a system
    # with ELEN=32.
    vsetivli x0, 4, e64, m2, ta, ma

    # vtype[vill] should be set.
    csrr t0, vtype
    blt t0, zero, pass

    j fail

.balign 4
trap_handler:
    # Any trap is a test failure.
    la t2, fail
    csrw mepc, t2
1:
    mret

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
