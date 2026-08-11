#include "common/encoding.h"

#define SIG_VERSION_OFFSET 0
#define SIG_PLATFORM_OFFSET 4

#define SIG_REQUIRED_MAJOR_VERSION 1
#define SIG_MINIMUM_MINOR_VERSION 0
#define SIG_BASE 0x0C000000

# Bit 31 is the value to drive, the remaining bits select which lines it
# applies to.
#define SIG_VALUE_HIGH (1 << 31)

.global main
main:
  # WFI must wake for a locally enabled machine external interrupt.
  # This test is for the simple test generator and assumes that the base of the simple
  # platform's memory-mapped interrupt controller is at 0x0C000000 by default (see config/config.json.in).

  mv t6, ra

  # Keep interrupts from actually being taken.
  # WFI must wake regardless of mstatus.MIE.
  li t0, MSTATUS_MIE
  csrc mstatus, t0

  # Only the machine external interrupt is locally enabled, so nothing else
  # can wake the WFI below.
  li t0, MIP_MEIP
  csrw mie, t0

  li t3, SIG_BASE

  # Check the device version of the simple interrupt generator before using it.
  lw t0, SIG_VERSION_OFFSET(t3)
  srli t1, t0, 16

  li t2, SIG_REQUIRED_MAJOR_VERSION
  bne t1, t2, fail

  li t2, 0xFFFF
  and t0, t0, t2
  li t2, SIG_MINIMUM_MINOR_VERSION
  bltu t0, t2, fail

  # Drive MEIP high.
  li t1, SIG_VALUE_HIGH | MIP_MEIP
  sw t1, SIG_PLATFORM_OFFSET(t3)

  # Reading mip includes the platform interrupts, so MEIP must be visible
  # here. If it isn't, the SIG write did not take effect and the rest of the
  # test would be measuring nothing.
  csrr t0, mip
  li t1, MIP_MEIP
  and t0, t0, t1
  beqz t0, fail

  csrr t0, time
  wfi
  csrr t1, time

  # 2 if it woke, ~11 if it ran out max_time_to_wait.
  # Assumes instructions_per_tick is 2 and max_time_to_wait is 10 as per default.
  sub t1, t1, t0
  li t2, 2
  bne t1, t2, fail

  j pass

pass:
  li a0, 0
  mv ra, t6
  ret
fail:
  li a0, 1
  mv ra, t6
  ret
