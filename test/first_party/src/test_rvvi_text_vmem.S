// Sv39/Sv32: PTE/PT on walked accesses, 4K leaf (PT K), and a page-straddling load.

#include "common/encoding.h"

.global main
main:
    mv      s0, ra                  # save return address
    csrr    s1, mtvec               # save old mtvec

    # Install custom trap handler for the S-mode ecall.
    la      t0, vmem_trap_handler
    csrw    mtvec, t0

    la      t0, rvvi_page_table

    # Leaf PTE for PA 0x80000000 (R/W/X).
    li      t1, 0x80000000
    srli    t1, t1, RISCV_PGSHIFT - PTE_PPN_SHIFT
    ori     t1, t1, PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D

#if __riscv_xlen == 64
    # Sv39 gigapage at VPN[2]=2: identity-map 0x80000000 for S-mode fetch.
    sd      t1, 16(t0)
    # VPN[2]=3: map 0xC0000000 -> 0x80000000 so the data load walks a
    # different gigapage than the fetch (forces PTE on MEM D).
    sd      t1, 24(t0)
    # VPN[2]=1: root[1] -> l1[0] -> l0[0] -> PA 0x80000000, so the VA
    # 0x40000000 load walks all three Sv39 levels down to a 4K leaf
    # (PT K on the MEM D record).
    la      t2, rvvi_page_table_l1
    srli    t3, t2, RISCV_PGSHIFT - PTE_PPN_SHIFT
    ori     t3, t3, PTE_V
    sd      t3, 8(t0)               # root[1]: non-leaf pointer to l1
    la      t2, rvvi_page_table_l0
    srli    t3, t2, RISCV_PGSHIFT - PTE_PPN_SHIFT
    ori     t3, t3, PTE_V
    la      t4, rvvi_page_table_l1
    sd      t3, 0(t4)               # l1[0]: non-leaf pointer to l0
    sd      t1, 0(t2)               # l0[0]: 4K leaf for PA 0x80000000
    la      t3, rvvi_page_table
    srli    t3, t3, RISCV_PGSHIFT
    li      t2, 0x8000000000000000    # Sv39 mode
    or      t3, t3, t2
    csrw    satp, t3
#else
    # Sv32 megapage at VPN[1]=512: identity-map 0x80000000.
    li      t2, 2048
    add     t2, t0, t2
    sw      t1, 0(t2)
    # VPN[1]=768: map 0xC0000000 -> 0x80000000.
    li      t2, 3072
    add     t2, t0, t2
    sw      t1, 0(t2)
    # NOTE: Sail's Satp32 bitfield uses bit 31 as the single-bit Mode
    # field (not bits[31:30] as in the RISC-V spec), so we set bit 31.
    la      t3, rvvi_page_table
    srli    t3, t3, RISCV_PGSHIFT
    li      t2, 0x80000000            # Sv32 mode (bit 31)
    or      t3, t3, t2
    csrw    satp, t3
#endif

    sfence.vma

    # Set mstatus.MPP = S-mode (0b01) and mepc = s_mode_entry.
    csrr    t0, mstatus
    li      t1, ~MSTATUS_MPP
    and     t0, t0, t1               # clear MPP
    li      t1, MSTATUS_MPP >> 1     # S-mode = 0b01 (bit 11)
    or      t0, t0, t1
    csrw    mstatus, t0
    la      t0, s_mode_entry
    csrw    mepc, t0
    mret

.align 4
s_mode_entry:
    # Load from a VA on a different root PTE than the PC so this access
    # takes a page-table walk (PTE/PT on MEM D).
    li      t0, 0xC0000000
#if __riscv_xlen == 64
    ld      t1, 0(t0)
#else
    lw      t1, 0(t0)
#endif

    # Full 3-level Sv39 walk: root[1] -> l1[0] -> l0[0] leaf, so this
    # MEM D carries PT K (4K page) instead of the gigapage PT G.
#if __riscv_xlen == 64
    li      t0, 0x40000000
    ld      t1, 0(t0)
#endif

    # 4K-straddling load: two MEM D records whose bytes sum to the width.
    li      t0, 0xC0000FFE
#if __riscv_xlen == 64
    ld      t1, 0(t0)
#else
    lw      t1, 0(t0)
#endif
    ecall

.p2align 6
vmem_trap_handler:
    # Verify this is an S-mode ecall (cause 9), skip it, and return to
    # m_finish in M-mode by setting MPP=M.
    csrr    t0, mcause
    li      t1, CAUSE_SUPERVISOR_ECALL
    bne     t0, t1, vmem_fail
    csrr    t0, mepc
    addi    t0, t0, 4
    csrw    mepc, t0
    li      t0, MSTATUS_MPP
    csrs    mstatus, t0
    la      t0, m_finish
    csrw    mepc, t0
    csrw    mtvec, s1
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
.balign 4096
rvvi_page_table_l1:
    .fill 4096, 1, 0
.balign 4096
rvvi_page_table_l0:
    .fill 4096, 1, 0
