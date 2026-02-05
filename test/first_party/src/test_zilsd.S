.section .text

.global main
main:
    # Self-checking test for Zilsd (RV32 load/store pair via ld/sd encodings).
    mv t6, ra

    # ---- Test: ld load pair works ----
    la t0, zilsd_ld_src
    # ld x6, 0(x5)
    .word 0x0002b303

    li t3, 0x00112233
    bne x6, t3, fail
    li t3, 0x44556677
    bne x7, t3, fail

    # ---- Test: misaligned load pair ----
    addi t0, t0, 2
    # ld x6, 0(x5)
    .word 0x0002b303

    li t3, 0x66770011
    bne x6, t3, fail
    li t3, 0xaabb4455
    bne x7, t3, fail

    addi t0, t0, -2

    # ---- Test: pair store works ----
    la t0, zilsd_sd_dst
    li x6, 0xaabbccdd
    li x7, 0xeeff0011

    # sd x6, 0(x5)
    .word 0x0062b023  # sd x6, 0(x5)

    lw t2, 0(t0)
    li t1, 0xaabbccdd
    bne t2, t1, fail
    lw t2, 4(t0)
    li t1, 0xeeff0011
    bne t2, t1, fail

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
zilsd_ld_src:
    .word 0x00112233
    .word 0x44556677
    .word 0x8899aabb
    .word 0xccddeeff

.balign 8
zilsd_sd_dst:
    .word 0
    .word 0
