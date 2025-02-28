.global main
main:
    # This is a very simple self-checking test for minstret edge cases.

    # Save return address in temporary register we're not using.
    mv t6, ra

    # Zero minstret. This gets us into a known state and also deals with
    # simulators that use X.
#if __riscv_xlen == 32
    csrw minstreth, zero
#endif
    csrw minstret, zero

    # Basic test of explicit write to minstret with the same value it already had.

    nop # Increment instret to 1.
    csrr t0, minstret # Should read 1 and then increment to 2.
    csrr t1, minstret # Should read 2 and then increment to 3.
    csrrwi t2, minstret, 3 # Should read 3 and then write 3, suppressing the increment to 4.
    csrrwi t3, minstret, 10 # Should read 3 and write 10.
    csrr t4, minstret # Should read 10.

    li t5, 1
    bne t0, t5, fail
    li t5, 2
    bne t1, t5, fail
    li t5, 3
    bne t2, t5, fail
    bne t3, t5, fail
    li t5, 10
    bne t4, t5, fail

# Tricky minstreth edge cases.
#if __riscv_xlen == 32
    # Explicitly write 0x00000000FFFFFFFF
    li t0, 0xFFFFFFFF
    csrw minstreth, zero
    csrw minstret, t0
    # Minstret should be 0x00000000FFFFFFFF now.
    # Write 2 to minstreth. instret should now be 0x0000000200000000
    csrwi minstreth, 2
    csrr t1, minstreth

    li t2, 2
    bne t1, t2, fail

    # Try again but this time we'll write to the bottom half.
    li t0, 0xFFFFFFFF
    csrw minstreth, zero
    csrw minstret, t0
    # Minstret should be 0x00000000FFFFFFFF now.
    # Write 2 to minstret. instret should now be 0x0000000100000002
    csrwi minstret, 2
    csrr t1, minstreth

    li t2, 1
    bne t1, t2, fail

#endif

    # Check wrapping around 0xFFFFFFFFFFFFFFFF works.
    li t0, -1
#if __riscv_xlen == 32
    csrw minstreth, t0
#endif
    csrw minstret, t0 # Set instret to 0xFFFFFFFFFFFFFFFF
    csrr t1, minstret # Should read 0xFFFFFFFFFFFFFFFF and increment instret to 0.
    csrr t2, minstret # Should read 0.

    bne t1, t0, fail
    bne t2, zero, fail

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
