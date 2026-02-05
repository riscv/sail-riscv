.global main
main:
    # Save return address in temporary register we're not using.
    mv t6, ra

    # Load improperly NaN-boxed bf16 value into f1
    #if __riscv_xlen == 64
    li t0, 0xffffffff00000000
    fmv.d.x f1, t0

    # Convert to bf16 and back to integer
    fcvt.s.bf16 f2, f1

    # Check result
    fmv.x.d t1, f2
    li t2, 0xffffffff7fc00000
    bne t1, t2, fail
    #endif

pass:
    li a0, 0
    mv ra, t6
    ret
fail:
    li a0, 1
    mv ra, t6
    ret
