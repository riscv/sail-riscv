#include "common/encoding.h"

# Check that the vector-scalar GHASH instructions (Zvkgs) match the
# vector-vector instructions (Zvkg) when the hash subkey is broadcast,
# and that a destination group overlapping the vs2 scalar group traps.

# OP-VE encodings (funct3 = OPMVV, vm = 1).
.macro VGHSH_VV vd, vs2, vs1
    .word (0x59 << 25) | (\vs2 << 20) | (\vs1 << 15) | (2 << 12) | (\vd << 7) | 0x77
.endm
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

    # Two element groups at SEW=32.
    li t0, 8
    vsetvli x0, t0, e32, m2, ta, ma

    # v4:v5 = hash subkey H in both element groups (for the .vv forms).
    # v6:v7 = H in the first element group, garbage in the second (for the
    # .vs forms, which must only read the first element group of vs2).
    la t1, h_both
    vle32.v v4, (t1)
    la t1, h_first
    vle32.v v6, (t1)

    # v8:v9 and v10:v11 both hold the same multiplier / partial hash Y.
    la t1, y_data
    vle32.v v8, (t1)
    vle32.v v10, (t1)
    # v16:v17 = cipher text X.
    la t1, x_data
    vle32.v v16, (t1)

    # vgmul: v8 = v8 * H (.vv) and v10 = v10 * H (.vs).
    VGMUL_VV 8, 4
    VGMUL_VS 10, 6
    vmsne.vv v0, v8, v10
    vfirst.m t0, v0
    bgez t0, fail
    # The product must differ from the input.
    la t1, y_data
    vle32.v v12, (t1)
    vmsne.vv v0, v8, v12
    vfirst.m t0, v0
    bltz t0, fail

    # vghsh: v12 = vghsh.vv(v12, H, X) and v14 = vghsh.vs(v14, H, X).
    la t1, y_data
    vle32.v v12, (t1)
    vle32.v v14, (t1)
    VGHSH_VV 12, 4, 16
    VGHSH_VS 14, 6, 16
    vmsne.vv v0, v12, v14
    vfirst.m t0, v0
    bgez t0, fail

    # A .vs instruction whose vd group overlaps vs2 is reserved.
    li s0, 0
    VGMUL_VS 6, 6
    beqz s0, fail
    li s0, 0
    VGHSH_VS 6, 6, 16
    beqz s0, fail

    # The .vv forms are unaffected by the overlap rule.
    li s0, 0
    VGMUL_VV 6, 6
    bnez s0, fail

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

.data
.balign 16
h_both:
    .word 0x01234567, 0x89abcdef, 0xfedcba98, 0x76543210
    .word 0x01234567, 0x89abcdef, 0xfedcba98, 0x76543210
h_first:
    .word 0x01234567, 0x89abcdef, 0xfedcba98, 0x76543210
    .word 0xdeadbeef, 0x0badf00d, 0xcafebabe, 0x13579bdf
y_data:
    .word 0x11111111, 0x22222222, 0x33333333, 0x44444444
    .word 0x11111111, 0x22222222, 0x33333333, 0x44444444
x_data:
    .word 0xa5a5a5a5, 0x5a5a5a5a, 0x0f0f0f0f, 0xf0f0f0f0
    .word 0xa5a5a5a5, 0x5a5a5a5a, 0x0f0f0f0f, 0xf0f0f0f0
