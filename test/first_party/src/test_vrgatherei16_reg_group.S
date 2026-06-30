#include "common/encoding.h"

.global main
main:
    # Save return address in temporary register.
    mv t6, ra

    # Enable vector.
    li t0, MSTATUS_VS
    csrs mstatus, t0

    # Set SEW=32, LMUL=8. With these settings, vrgatherei16.vv has
    # vs1 (index) EMUL = (16/SEW)*LMUL = (16/32)*8 = 4.
    # Register v4 is valid for EMUL=4 (4 % 4 == 0), but would be
    # incorrectly rejected if checked against LMUL=8.
    vsetivli zero, 2, e32, m8, ta, ma

    # Set trap handler.
    la t0, trap_handler
    csrw mtvec, t0

    # vrgatherei16.vv with vs1=v4.
    # vs1 EMUL = 4, so v4 is a valid register group start.
    # This instruction should NOT raise an illegal instruction exception.
test_instruction:
    vrgatherei16.vv v8, v24, v4

    # If execution reaches here without a trap, the instruction is valid.
    j pass

.balign 4
trap_handler:
    # Any trap at the test instruction is a test failure.
    la t2, fail

    csrr t0, mepc
    la t1, test_instruction
    bne t0, t1, 1f

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
