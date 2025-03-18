.global main
.align 4
main:
    mv t6, ra
    # install custom trap handler to catch misalign jal target address
    la t0, trap_handler
    csrw mtvec, t0

    # set test pass count to 0
    li t5, 0

    # TODO: disable zca extension which is enabled by default
    jal misalign
    li t4, 1
    bne t5, t4, fail

    la t0, misalign
    jalr x1, 3(t0)
    li t4, 1
    bne t5, t4, fail

pass:
    li a0, 0
    j finish
fail:
    li a0, 1
    j finish
finish:
    mv ra, t6
    # uninstall custom trap handler
    csrwi mtvec, 0
    ret

    .space 2
misalign:
    .space 2
    ret

trap_handler:
    csrr t0, mcause
    li t1, 0  # E_Fetch_Addr_Align
    bne t0, t1, trap_exit

    # test pass count
    addi t5, t5, 1

    li a0, 0
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
trap_exit:
    mret
