#include "common/encoding.h"

# Tests a misaligned HLV load and HSV store that cross a page boundary where the first stage
# second page is mapped at VS-stage but at G-stage only the first page is mapped.
# A correct implementation splits the access and translates each page separately,
# taking a load guest-page fault on the second page at G-Stage. A faulty implementation
# translates only the base address and performs the whole load at once, so the
# fault is missed.

#if __riscv_xlen == 32
# The superpage A covers 0xBFC00000 -- 0xBFFFFFFF.
# The index of its PTE (given by its VPN[1]) in the root page table is 767.
# Page B is the next superpage, starting at 0xC0000000, with its PTE at index 768.
#define PAGE_A    0xBFC00000
#define VPN_IDX_A 767   # VPN[1] for 0xBFC00000 under Sv32
#define VPN_IDX_B 768   # VPN[1] for 0xC0000000
#define PTE_SHIFT 2     # 4-byte PTEs
#else
# The superpage A covers 0x80000000 -- 0xBFFFFFFF.
# The index of its PTE (given by its VPN[2]) in the root page table is 2.
# Page B is the next superpage, starting at 0xC0000000, with its PTE at index 3.
#define PAGE_A     0x80000000
#define VPN_IDX_A  2     # VPN[2] for 0x80000000 under Sv39
#define VPN_IDX_B  3     # VPN[2] for 0xC0000000
#define PTE_SHIFT  3     # 8-byte PTEs
#endif

#define PAGE_B     0xC0000000

# Address for a 4-byte load/store that straddles pages A and B.
#define STRADDLE_ADDR  0xBFFFFFFE

.global main
main:
  la t0, fail
  csrw mtvec, t0

# Set up the VS-stage page table. Map PAGE_A and PAGE_B as identity-mapped superpages.
# Both pages need to be mapped for the VS-stage walk to succeed.
vs_pt_init:
  li t0, PAGE_A
  srl t0, t0, RISCV_PGSHIFT - PTE_PPN_SHIFT
  ori t0, t0, PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D
  la t1, vspt_0
  li t2, VPN_IDX_A
  sll t2, t2, PTE_SHIFT
  add t1, t1, t2
  sw t0, 0(t1)

  li t0, PAGE_B
  srl t0, t0, RISCV_PGSHIFT - PTE_PPN_SHIFT
  ori t0, t0, PTE_V | PTE_R | PTE_W | PTE_X | PTE_A | PTE_D
  la t1, vspt_0
  li t2, VPN_IDX_B
  sll t2, t2, PTE_SHIFT
  add t1, t1, t2
  sw t0, 0(t1)

init_vsatp:
#if __riscv_xlen == 64
  li t0, (SATP_MODE & ~(SATP_MODE<<1)) * SATP_MODE_SV39
#else
  li t0, SATP32_MODE * SATP_MODE_SV32
#endif
  la t1, vspt_0
  srl t1, t1, RISCV_PGSHIFT
  or t1, t1, t0
  csrw vsatp, t1
  hfence.vvma

# Set up G-stage page table. Map only PAGE_A as an identity page. PAGE_B
# remains unmapped. For RV32, the memory region containing vstp_0 also
# needs to be mapped in order to perform a successful G-stage walk.
guest_pt_init:
  li t0, PAGE_A
  srl t0, t0, RISCV_PGSHIFT - PTE_PPN_SHIFT
  ori t0, t0, PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D
  la t1, gpt_0
  li t2, VPN_IDX_A
  sll t2, t2, PTE_SHIFT
  add t1, t1, t2
  sw t0, 0(t1)

#if __riscv_xlen == 32
  # Sv32 has no gigapage, so PAGE_A no longer covers vspt_0 for RV32.
  # Map it separately or the G-stage walk of the VS page table fails.
  la t0, vspt_0
  srli t2, t0, RISCV_PGSHIFT + RISCV_PGLEVEL_BITS   # VPN[1] index for vspt_0's megapage
  slli t0, t2, RISCV_PGSHIFT + RISCV_PGLEVEL_BITS   # round t0 down to the megapage base
  srl t0, t0, RISCV_PGSHIFT - PTE_PPN_SHIFT
  ori t0, t0, PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_A | PTE_D
  la t1, gpt_0
  sll t2, t2, PTE_SHIFT
  add t1, t1, t2
  sw t0, 0(t1)
#endif

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

hstatus_init:
  li t0, HSTATUS_SPVP
  csrs hstatus, t0

set_test_fault_handler:
  la t0, check_fault
  csrw mtvec, t0

test_load:
  li t0, STRADDLE_ADDR
  # Perform a load crossing a page boundary.
  li s1, 1
  hlv.w t2, 0(t0)
  j fail # A faulty implementation reaches here and raises no fault

test_store:
  # Perform a store crossing a page boundary.
  li t0, STRADDLE_ADDR
  li s1, 2
  hsv.w t2, 0(t0)
  j fail # A faulty implementation reaches here and raises no fault


.align 4
check_fault:
  # mtval = faulting GVA, in page B.
  csrr t0, mtval
  li t1, PAGE_B
  bne t0, t1, fail

  # mtval2 = faulting GPA (page B) >> 2.
  csrr t0, mtval2
  li t1, PAGE_B
  srli t1, t1, 2
  bne t0, t1, fail

  # G-stage fault on the page B half.
  csrr t0, mcause

  # Check if this was a fault from a load (hlv.w).
check_load_fault:
  li t2, 1
  bne t2, s1, check_store_fault

  li t1, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, t1, fail

  la t1, test_store
  csrw mepc, t1
  mret

  # Check store fault (hsv.w).
check_store_fault:
  li t2, 2
  bne t2, s1, fail

  li t1, CAUSE_STORE_GUEST_PAGE_FAULT
  bne t0, t1, fail

  # Done with both tests.
  j pass

.align 4
fail:
  li a0, 1
  ret

pass:
  li a0, 0
  ret

.bss

.align 12
vspt_0: .fill 4096, 1, 0 # VS-stage root page table

.align 14
gpt_0: .fill 16384, 1, 0 # G-Stage root page table
