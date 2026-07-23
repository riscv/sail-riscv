// Virtual-memory RVVI-TEXT trace validation: set up an Sv39 (RV64) or
// Sv32 (RV32) identity mapping for 0x80000000, switch to S-mode, do a
// load (triggering a page-table walk), then ecall back to M-mode. The
// PTW produces a MEM entry with PTE/PPN/PAGE_TYPE signals. A custom
// trap handler catches the S-mode ecall and returns to M-mode.

#include "common/encoding.h"

.global main
main:
    mv      s0, ra                  # save return address
    csrr    s1, mtvec               # save old mtvec

    # Install custom trap handler for the S-mode ecall.
    la      t0, vmem_trap_handler
    csrw    mtvec, t0

    # Identity-map 0x80000000 with a leaf PTE in the root table
    # (1 GiB for Sv39, 4 MiB for Sv32).
    la      t0, rvvi_page_table
    li      t1, 0x80000000
    srli    t1, t1, RISCV_PGSHIFT - PTE_PPN_SHIFT  # t1 = PPN << PTE_PPN_SHIFT
    ori     t1, t1, PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D
#if __riscv_xlen == 64
    # Sv39: VPN[2] = 0x80000000 >> 30 = 2 -> entry [2] at offset 16.
    sd      t1, 16(t0)
    la      t3, rvvi_page_table
    srli    t3, t3, RISCV_PGSHIFT
    li      t2, 0x8000000000000000    # Sv39 mode
    or      t3, t3, t2
    csrw    satp, t3
#else
    # Sv32: VPN[1] = 0x80000000 >> 22 = 512 -> entry [512] at offset 2048.
    li      t2, 2048
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
    # Now in S-mode. Load from 0x80000000 (triggers a page-table walk).
    li      t0, 0x80000000
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
