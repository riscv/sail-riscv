// S-mode load page fault: MEM I for the fetch, no MEM D for the failed translation.

#include "common/encoding.h"

.global main
main:
    mv      s0, ra
    csrr    s1, mtvec
    la      t0, trap_mem_handler
    csrw    mtvec, t0

    // Identity-map 0x80000000 so S-mode code can fetch.
    la      t0, rvvi_page_table
    li      t1, 0x80000000
    srli    t1, t1, RISCV_PGSHIFT - PTE_PPN_SHIFT
    ori     t1, t1, PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D
#if __riscv_xlen == 64
    sd      t1, 16(t0)
    la      t3, rvvi_page_table
    srli    t3, t3, RISCV_PGSHIFT
    li      t2, 0x8000000000000000
    or      t3, t3, t2
    csrw    satp, t3
#else
    li      t2, 2048
    add     t2, t0, t2
    sw      t1, 0(t2)
    la      t3, rvvi_page_table
    srli    t3, t3, RISCV_PGSHIFT
    li      t2, 0x80000000
    or      t3, t3, t2
    csrw    satp, t3
#endif
    sfence.vma

    csrr    t0, mstatus
    li      t1, ~MSTATUS_MPP
    and     t0, t0, t1
    li      t1, MSTATUS_MPP >> 1
    or      t0, t0, t1
    csrw    mstatus, t0
    la      t0, s_fault
    csrw    mepc, t0
    mret

.align 4
s_fault:
    li      t0, 0x40000000          // unmapped
#if __riscv_xlen == 64
    ld      t1, 0(t0)
#else
    lw      t1, 0(t0)
#endif
    j       vmem_fail               // must not get here

.p2align 6
trap_mem_handler:
    csrr    t0, mcause
    li      t1, CAUSE_LOAD_PAGE_FAULT
    bne     t0, t1, vmem_fail
    csrw    mtvec, s1
    li      t0, MSTATUS_MPP
    csrs    mstatus, t0
    la      t0, m_finish
    csrw    mepc, t0
    mret

m_finish:
    li      a0, 0
    mv      ra, s0
    ret

vmem_fail:
    li      a0, 1
    mv      ra, s0
    ret

.bss
.balign 4096
rvvi_page_table:
    .fill 4096, 1, 0
