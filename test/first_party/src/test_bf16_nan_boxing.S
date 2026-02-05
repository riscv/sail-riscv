.global main
main:
#if __riscv_xlen == 64
    # Load improperly NaN-boxed bf16 value into f1
    li t0, 0xffffffff00000000
    fmv.d.x f1, t0

    # Convert to bf16 and back to fp32
    fcvt.s.bf16 f2, f1

    # Check result
    fmv.x.d t1, f2
    li t2, 0xffffffff7fc00000
    bne t1, t2, fail

#else
    # Build improperly NaN-boxed bf16 value on stack
    addi sp, sp, -8

    li t0, 0x00000000
    sw t0, 0(sp)

    li t0, 0xffffffff
    sw t0, 4(sp)

    # Load improperly NaN-boxed value from stack
    fld f1, 0(sp)
    addi sp, sp, 8

    # Convert to bf16 and back to fp32
    fcvt.s.bf16 f2, f1

    # Check result
    fmv.x.w t1, f2
    li t2, 0x7fc00000
    bne t1, t2, fail

#endif

pass:
    li a0, 0
    ret

fail:
    li a0, 1
    ret
