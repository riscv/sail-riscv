#include "common/encoding.h"

.global main
main:
    # Save return address in temporary register.
    mv s1, ra
    # Save original trap vector.
    csrr s2, mtvec

    # Enable vector.
    li t0, MSTATUS_VS
    csrs mstatus, t0

test_valid_group:
    # Set SEW=32, LMUL=8. With these settings, vrgatherei16.vv has
    # vs1 (index) EMUL = (16/SEW)*LMUL = (16/32)*8 = 4.
    # Register v4 is valid for EMUL=4 (4 % 4 == 0), but would be
    # incorrectly rejected if checked against LMUL=8.
    vsetivli zero, 2, e32, m8, ta, ma

    # Set trap handler.
    la t0, valid_group_trap_handler
    csrw mtvec, t0

    # vrgatherei16.vv with vs1=v4.
    # vs1 EMUL = 4, so v4 is a valid register group start.
    # This instruction should NOT raise an illegal instruction exception.
test_group_instruction:
    vrgatherei16.vv v8, v24, v4
    # If execution reaches here without a trap, the instruction is valid.

test_invalid_lmul:
    # Set SEW=8, LMUL=8.  With these settings, vrgatherei16.vv has
    # vs1 (index) EMUL = (16/SEW)*LMUL = (16/8)*8 = 16.
    # This is an invalid LMUL and should be rejected.
    vsetivli zero, 2, e8, m8, ta, ma

    # Set trap handler.
    la t0, invalid_lmul_trap_handler
    csrw mtvec, t0

test_invalid_instruction:
    # vs1 with EMUL=16 starts at v16 so that the group is in-bounds.
    # vd with EMUL=8 is v0, so vs2 with EMUL=8 is v8.
    vrgatherei16.vv v0, v8, v16
    # The instruction is illegal and we should not get here.
    j fail

.balign 4
valid_group_trap_handler:
    # Any trap at the test instruction is a test failure.
    la t2, fail
    csrw mepc, t2
    # Restore original handler.
    csrw mtvec, s2
    mret

.balign 4
invalid_lmul_trap_handler:
    # Restore original handler.
    csrw mtvec, s2
    la t2, fail

    # The trap should be due to an illegal instruction.
    csrr t0, mcause
    li t1, CAUSE_ILLEGAL_INSTRUCTION
    bne t0, t1, 1f

    # The instruction should be the expected one.
    csrr t0, mepc
    la t1, test_invalid_instruction
    bne t0, t1, 1f

    # All good.
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
