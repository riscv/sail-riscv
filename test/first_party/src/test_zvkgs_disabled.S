#include "common/encoding.h"

# This test should run on a system with Zvkg but without Zvkgs.
# See the "zvkgs_disabled.json" config override.
# vgmul.vv must execute, vgmul.vs and vghsh.vs must be illegal.

.macro VGHSH_VS vd, vs2, vs1
    .word (0x47 << 25) | (\vs2 << 20) | (\vs1 << 15) | (2 << 12) | (\vd << 7) | 0x77
.endm
.macro VGMUL_VV vd, vs2
    .word (0x51 << 25) | (\vs2 << 20) | (17 << 15) | (2 << 12) | (\vd << 7) | 0x77
.endm
.macro VGMUL_VS vd, vs2
    .word (0x53 << 25) | (\vs2 << 20) | (17 << 15) | (2 << 12) | (\vd << 7) | 0x77
.endm

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
    li s0, 0

    li t0, 4
    vsetvli x0, t0, e32, m1, ta, ma

    VGMUL_VV 8, 4
    bnez s0, fail

    VGMUL_VS 8, 4
    beqz s0, fail

    li s0, 0
    VGHSH_VS 8, 4, 12
    beqz s0, fail

    j pass

.balign 4
trap_handler:
    # Only illegal instruction traps are expected.
    csrr t2, mcause
    li t3, 2
    bne t2, t3, fail
    li s0, 1
    csrr t2, mepc
    addi t2, t2, 4
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
