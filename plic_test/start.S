    .section .text.init
    .globl _start
_start:
    la   sp, stack_top
    la   gp, __global_pointer$
    call main
1:  j    1b

    .p2align 2
    .globl trap_entry
trap_entry:
    addi sp, sp, -64
    sd   ra, 56(sp)
    sd   t0, 0(sp)
    sd   t1, 8(sp)
    sd   t2, 16(sp)
    sd   t3, 24(sp)
    sd   t4, 32(sp)
    sd   t5, 40(sp)
    sd   t6, 48(sp)

    csrr t0, mcause
    bltz t0, 1f              # interrupt => mcause is negative
    j    9f

1:
    andi t0, t0, 0xff        # low bits = cause code
    li   t1, 11              # Machine external interrupt
    bne  t0, t1, 9f

    # PLIC claim/complete for ctx0(M): PLIC_BASE + 0x200004
    li   t2, 0x0c000000
    li   t3, 0x200004
    add  t2, t2, t3

    lw   t3, 0(t2)           # claim id
    li   t4, 10
    bne  t3, t4, 8f

    la   t5, g_claim
    sw   t3, 0(t5)
    la   t5, g_irq_seen
    li   t6, 1
    sw   t6, 0(t5)

8:
    sw   t3, 0(t2)           # complete (write back claimed id)

9:
    ld   ra, 56(sp)
    ld   t0, 0(sp)
    ld   t1, 8(sp)
    ld   t2, 16(sp)
    ld   t3, 24(sp)
    ld   t4, 32(sp)
    ld   t5, 40(sp)
    ld   t6, 48(sp)
    addi sp, sp, 64
    mret
