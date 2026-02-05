.section .text

.global main
main:
    # Self-checking test for Zclsd compressed load/store pair (c.ld/c.sd/c.ldsp/c.sdsp encodings).
    mv t6, ra

    # Reserve some stack space for c.ldsp/c.sdsp tests.
    addi sp, sp, -64

    # ---- Test: c.ldsp loads a pair from sp+16 into x8/x9 ----
    li t0, 0x00112233
    sw t0, 16(sp)
    li t0, 0x44556677
    sw t0, 20(sp)

    # c.ldsp x8, 16(sp)
    .hword 0x6442

    li t0, 0x00112233
    bne x8, t0, fail
    li t0, 0x44556677
    bne x9, t0, fail

    # ---- Test: c.sdsp stores a pair from x8/x9 to sp+16 ----
    li x8, 0x8899aabb
    li x9, 0xccddeeff
    sw zero, 16(sp)
    sw zero, 20(sp)

    # c.sdsp x8, 16(sp)
    .hword 0xe822

    lw t1, 16(sp)
    li t0, 0x8899aabb
    bne t1, t0, fail
    lw t1, 20(sp)
    li t0, 0xccddeeff
    bne t1, t0, fail

    # ---- Test: c.sd / c.ld using compressed regs (x8..x15) ----
    la x8, zclsd_buf
    li x10, 0x01234567
    li x11, 0x89abcdef

    # c.sd x10, 0(x8)
    .hword 0xe008

    li x10, 0
    li x11, 0

    # c.ld x10, 0(x8)
    .hword 0x6008

    li t0, 0x01234567
    bne x10, t0, fail
    li t0, 0x89abcdef
    bne x11, t0, fail

    addi sp, sp, 64

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret

.section .data
.balign 8
zclsd_buf:
    .word 0
    .word 0
