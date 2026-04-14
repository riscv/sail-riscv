#include "common/encoding.h"
.global main
main:
  # Switch to S-Mode
  li t0, MSTATUS_MPP & (MSTATUS_MPP >> 1)
  csrs mstatus, t0
  la t0, s_mode
  csrw mepc, t0
  la t0, trap_handler_pmp
  csrw mtvec, t0
  mret

.align 4
s_mode:
  # Build identity mapping 0x80000000 -> 0x80000000
  la t0, page_table
  li t1, 0x80000000
  srli t1, t1, RISCV_PGSHIFT - PTE_PPN_SHIFT
  ori t1, t1, PTE_V | PTE_R | PTE_W | PTE_X
#if __riscv_xlen == 64
  # Sv39
  # VPN[2] = 0x80000000 >> 30 = 2, offset = 2 * 8 = 16
  sd t1, 16(t0)
  li t2, (SATP_MODE & ~(SATP_MODE << 1)) * SATP_MODE_SV39
  la t3, page_table
  srli t3, t3, RISCV_PGSHIFT
  or t3, t3, t2
  csrw satp, t3
#else
  # Sv32
  # VPN[1] = 0x80000000 >> 22 = 512, offset = 512 * 4 = 2048
  # 2048 doesn't fit in sw immediate so compute address first
  li t2, 2048
  add t2, t0, t2
  sw t1, 0(t2)
  # Set Sv32 mode
  lui t2, 0x80000
  la t3, page_table
  srli t3, t3, RISCV_PGSHIFT
  or t3, t3, t2
  csrw satp, t3
#endif
  sfence.vma
  # Warm up TLB
  li t0, 0x80000000
#if __riscv_xlen == 64
  ld t1, 0(t0)
#else
  lw t1, 0(t0)
#endif
  ecall

.align 4
trap_handler_pmp:
  # Block PTE address, no RWX
  la t0, page_table
#if __riscv_xlen == 64
  addi t0, t0, 16          # PTE at page_table+16 (8-byte NAPOT)
  srli t0, t0, 2
  ori t0, t0, 1
  csrw pmpaddr0, t0
  li t0, 0xFFFFFFFF
  csrw pmpaddr1, t0
  li t0, (PMP_NAPOT | PMP_R | PMP_W | PMP_X) << 8 | PMP_NAPOT
#else
  li t1, 2048
  add t0, t0, t1           # PTE at page_table+2048 (NA4, 4-byte)
  srli t0, t0, 2
  csrw pmpaddr0, t0
  li t0, 0xFFFFFFFF
  csrw pmpaddr1, t0
  li t0, (PMP_NAPOT | PMP_R | PMP_W | PMP_X) << 8 | PMP_NA4
#endif
  csrw pmpcfg0, t0

  la t0, try_panic
  csrw mepc, t0

  la t0, pass
  csrw mtvec, t0

  mret

try_panic:
  # Expected to raise an exception, but not trigger a panic
  li t0, 0x80000000
#if __riscv_xlen == 64
  sd t0, 0(t0)
#else
  sw t0, 0(t0)
#endif

fail:
  li a0, 1
  ret

pass:
  li a0, 0
  ret

.bss

.align 12
page_table:
.zero 4096
