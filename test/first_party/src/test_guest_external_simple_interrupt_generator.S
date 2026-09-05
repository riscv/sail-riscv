#include "common/encoding.h"

#define SIG_VERSION_OFFSET 0
#define SIG_PLATFORM_OFFSET 4
#define SIG_GUEST_OFFSET 8

#define SIG_REQUIRED_MAJOR_VERSION 1
#define SIG_MINIMUM_MINOR_VERSION 1
#define SIG_BASE 0x0C000000

# Bit 31 is the value to drive, the remaining bits select which lines it
# applies to.
#define SIG_VALUE_HIGH (1 << 31)

.global main
main:
  # Enable VSSIP, VSTIP, VSEIP and SGEIP.
  li t0, MIP_HS_MASK
  csrw mie, t0

  li t0, MIP_VS_MASK
  csrw mideleg, t0

  # Switch to HS-Mode
  li t0, MSTATUS_MPP & (MSTATUS_MPP >> 1)
  csrs mstatus, t0
  la t0, hs_mode
  csrw mepc, t0
  mret

.align 4
hs_mode:
  # Trap handlers for both privilege levels.
  la t0, hs_trap_handler
  csrw stvec, t0
  la t0, vs_trap_handler
  csrw vstvec, t0

  # mideleg delegates SGEIP and the VS interrupts to HS-mode.
  # Delegate the VS interrupts one step further so they reach VS-mode.
  # SGEIP cannot be delegated, it always stops at HS-mode.
  li t0, MIP_VS_MASK
  csrw hideleg, t0

  # Enable interrupts for HS-Mode.
  li t0, SSTATUS_SIE
  csrs sstatus, t0

  # Enable interrupts for VS-Mode.
  li t0, SSTATUS_SIE
  csrs vsstatus, t0

  # Select guest interrupt file 1 for the guest we are about to run. VSEIP is
  # the hgeip bit that VGEIN selects, so this has to be set for the guest to
  # see the interrupt at all.
  li t0, (1 << 12)              # hstatus.VGEIN = 1
  csrw hstatus, t0

  # SGEIP is the OR of hgeip & hgeie, so enable file 1 to be notified here.
  li t0, (1 << 1)
  csrw hgeie, t0

  # Assert hgeip[1] via the SIG. SGEIP becomes pending immediately and traps
  # to hs_trap_handler on the next instruction.
  li t3, SIG_BASE
  li t1, SIG_VALUE_HIGH | 1
  sw t1, SIG_GUEST_OFFSET(t3)

  # SGEIP should have been taken before we get here.
  j fail

.align 4
hs_trap_handler:
  # hgeip is read-only to software and driven by the SIG, so file 1 must be set.
  csrr t0, hgeip
  li t1, (1 << 1)
  and t0, t0, t1
  beqz t0, fail

  # hip should show SGEIP and VSEIP pending.
  csrr t0, hip
  li t1, MIP_SGEIP | MIP_VSEIP
  and t0, t0, t1
  bne t0, t1, fail

  # Stop SGEIP. hgeip[1] stays asserted, so VSEIP is still
  # pending. Without this the (still) pending SGEIP would retrap to HS-mode as
  # soon as we enter VS-mode, since HS-level interrupts always preempt the guest.
  csrw hgeie, zero

  # Switch to VS-mode.
  # The pending VSEIP traps to vs_trap_handler immediately.
  li t0, HSTATUS_SPV
  csrs hstatus, t0
  li t0, SSTATUS_SPP
  csrs sstatus, t0
  la t0, guest
  csrw sepc, t0
  sret

.align 4
guest:
  # VSEIP should have been taken on entry to VS-mode.
  j fail

.align 4
vs_trap_handler:
  # The guest sees VSEIP as SEIP, so check sip.seip.
  csrr t0, sip
  li t1, MIP_SEIP
  and t0, t0, t1
  beqz t0, fail

  # Clear hgeip[1] via the SIG. Bit 31 low means clear, the low bits select
  # the guest interrupt file.
  li t3, SIG_BASE
  li t1, 1
  sw t1, SIG_GUEST_OFFSET(t3)

  # Check that the guest external interrupt is no longer pending.
  csrr t0, sip
  li t1, MIP_SEIP
  and t0, t0, t1
  bnez t0, fail

  j pass

pass:
  li a0, 0
  ret
fail:
  li a0, 1
  ret
