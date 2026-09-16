.global main
main:
    mv t6, ra

    // Replace `li a0, 1` with `li a0, 0`, then execute the new instruction
    // without FENCE.I. Ziccid guarantees eventual visibility; this sequential
    // model provides immediate visibility because fetches read shared memory.
    la t0, patch_me
    li t1, 0x00000513
    sw t1, 0(t0)
    jalr ra, t0, 0

    mv ra, t6
    ret

.balign 4
patch_me:
    li a0, 1
    ret
