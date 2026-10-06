#include "common/encoding.h"

// A VS-mode ebreak with vsstatus.SDT set causes a double trap into M-mode.
// The ebreak writes zero to mtval since software_breakpoint is false
// (see ssdbltrp_software_breakpoint_xtval_zero.json), so mstatus.GVA must be 0.

#define SSTATUS_SDT 0x01000000
#define MENVCFG_DTE 0x0800000000000000
#define MENVCFGH_DTE 0x08000000
#define CAUSE_DOUBLE_TRAP 0x10

.global main
main:
  # Delegate breakpoints to VS-mode
  li t0, (1 << CAUSE_BREAKPOINT)
  csrw medeleg, t0
  csrw hedeleg, t0

  # Reaching VS-mode means there was no double trap
  la t0, fail
  csrw vstvec, t0
  la t0, m_trap_handler
  csrw mtvec, t0

  # Enable Double-Trap Extension in VS-Mode
#if __riscv_xlen == 32
  li t0, MENVCFGH_DTE
  csrs menvcfgh, t0
  csrs henvcfgh, t0
  li t0, MSTATUSH_MPV
  csrs mstatush, t0
#else
  li t0, MENVCFG_DTE
  csrs menvcfg, t0
  csrs henvcfg, t0
  li t0, MSTATUS_MPV
  csrs mstatus, t0
#endif

  # Switch to VS-mode
  li t0, MSTATUS_MPP & (MSTATUS_MPP >> 1)
  csrs mstatus, t0
  la t0, guest
  csrw mepc, t0
  mret

.align 4
guest:
  # Set vsstatus.SDT
  li t0, SSTATUS_SDT
  csrs sstatus, t0
  ebreak
  j fail

.align 4
m_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_DOUBLE_TRAP
  bne t0, t1, fail

  csrr t0, mtval2
  li t1, CAUSE_BREAKPOINT
  bne t0, t1, fail

  # Check EBREAK wrote 0 to mtval
  csrr t0, mtval
  bnez t0, fail

  # Check that mstatus.GVA is 0, no GVA is written to mtval.
#if __riscv_xlen == 32
  csrr t0, mstatush
  andi t0, t0, MSTATUSH_GVA
#else
  csrr t0, mstatus
  li t1, MSTATUS_GVA
  and t0, t0, t1
#endif
  bnez t0, fail

pass:
  li a0, 0
  ret
fail:
  li a0, 1
  ret
