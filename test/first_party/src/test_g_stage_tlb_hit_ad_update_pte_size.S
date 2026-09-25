#include "common/encoding.h"

# Tests that a hardware A/D-bit update performed on a G-stage TLB hit writes
# back a PTE of the correct size.  translate_TLB_hit() used to pick an 8-byte
# PTE for Sv32x4, so on RV32 the D-bit write-back for a G-stage TLB hit stored
# 8 bytes and clobbered the neighbouring PTE with zeros.
#
# The test builds a G-stage page table with two adjacent leaf PTEs: PTE A maps
# the superpage holding `buf` with A=D=0, and PTE B maps the next superpage.
# An HLV load of `buf` walks the table (TLB miss) and sets A; an HSV store of
# `buf` then hits in the TLB and must set D.  Afterwards PTE A must have A and
# D set and PTE B must be unchanged.

#if __riscv_xlen == 32
# Sv32x4: 4 MiB megapages, 4-byte PTEs.  VPN[1] of 0x80000000 is 512.
#define PAGE_A     0x80000000
#define PAGE_B     0x80400000
#define VPN_IDX_A  512
#define PTE_SIZE   4
#define PTE_SHIFT  2
#define STORE      sw
#define LOAD       lw
#else
# Sv39x4: 1 GiB gigapages, 8-byte PTEs.  VPN[2] of 0x80000000 is 2.
#define PAGE_A     0x80000000
#define PAGE_B     0xC0000000
#define VPN_IDX_A  2
#define PTE_SIZE   8
#define PTE_SHIFT  3
#define STORE      sd
#define LOAD       ld
#endif

.global main
main:
  la t0, fail
  csrw mtvec, t0

  # Enable hardware A/D updates (Svadu) for both G-stage (menvcfg.ADUE) and
  # VS-stage (henvcfg.ADUE).  Harmless if Svadu is not implemented.
#if __riscv_xlen == 32
  li t0, MENVCFGH_ADUE
  csrs menvcfgh, t0
  li t0, HENVCFGH_ADUE
  csrs henvcfgh, t0
#else
  li t0, MENVCFG_ADUE
  csrs menvcfg, t0
  li t0, HENVCFG_ADUE
  csrs henvcfg, t0
#endif

  # G-stage page table.  s1 points at PTE A; PTE B is the next entry.
  la s1, gpt_0
  li t2, VPN_IDX_A
  sll t2, t2, PTE_SHIFT
  add s1, s1, t2

  # PTE A: identity-map PAGE_A with A=D=0 so that hardware must update them.
  li t0, PAGE_A
  srl t0, t0, RISCV_PGSHIFT - PTE_PPN_SHIFT
  ori t0, t0, PTE_V | PTE_R | PTE_W | PTE_X | PTE_U
  STORE t0, 0(s1)

  # PTE B: identity-map PAGE_B; remember its value in s2.
  li t0, PAGE_B
  srl t0, t0, RISCV_PGSHIFT - PTE_PPN_SHIFT
  ori t0, t0, PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D
  STORE t0, PTE_SIZE(s1)
  mv s2, t0

init_hgatp:
#if __riscv_xlen == 64
  li t0, (HGATP64_MODE & ~(HGATP64_MODE<<1)) * HGATP_MODE_SV39X4
#else
  li t0, HGATP32_MODE * HGATP_MODE_SV32X4
#endif
  la t1, gpt_0
  srl t1, t1, RISCV_PGSHIFT
  or t1, t1, t0
  csrw hgatp, t1
  hfence.gvma

  # VS-stage is Bare, so GVA == GPA and only the G-stage translates.
  csrw vsatp, zero
  hfence.vvma

  # HLV/HSV translate as VS-mode accesses.
  li t0, HSTATUS_SPVP
  csrs hstatus, t0

  # 1. Load: G-stage TLB miss.  The walk sets PTE A's A bit.
  la a0, buf
  hlv.w t0, 0(a0)

  # 2. Store: G-stage TLB hit.  The hit path must set PTE A's D bit.
  hsv.w t0, 0(a0)

  # PTE A must now have both A and D set.
  LOAD t0, 0(s1)
  andi t0, t0, PTE_A | PTE_D
  li t1, PTE_A | PTE_D
  bne t0, t1, fail

  # PTE B must be untouched by the write-back of PTE A.
  LOAD t0, PTE_SIZE(s1)
  bne t0, s2, fail

  j pass

.align 4
fail:
  li a0, 1
  ret

pass:
  li a0, 0
  ret

.bss

.align 4
buf: .fill 8, 1, 0

.align 14
gpt_0: .fill 16384, 1, 0 # G-Stage root page table
