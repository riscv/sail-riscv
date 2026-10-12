#include "common/encoding.h"

.global main
main:

  # Simple RV64 test that ensures a specified config value is reported
  # when invalid physical addresses are truncated.  This assumes
  # addresses are being truncated to 56 bits as in the default RV64
  # config.

#This address is valid after truncation, so the configured invalid
#address should be reported.
#define INVALID_PHYSADDR1  0x0f00000080000000
#define EXPECTED_TVAL1     0x00001badc0ffffee

#This address is invalid after truncation, so the truncated address
#should be reported.
#define INVALID_PHYSADDR2  0x0ff0000080000000
#define EXPECTED_TVAL2     0x00f0000080000000

  # Save return address and current trap handler
  mv s1, ra
  csrr s2, mtvec

set_trap_handler:
  la t0, test_trap_handler
  csrw mtvec, t0
  csrw mcause, x0

perform_access1:
  la s3, EXPECTED_TVAL1
  la t0, INVALID_PHYSADDR1
  lw t0, 0(t0)

perform_access2:
  la s3, EXPECTED_TVAL2
  la t0, INVALID_PHYSADDR2
  lw t0, 0(t0)
  j pass

.align 4
test_trap_handler:
  csrr t0, mcause
  li t1, CAUSE_LOAD_ACCESS
  bne t0, t1, fail
  # match expected tval
  csrr t1, mtval
  bne s3, t1, fail
  csrr t1, mepc
  addi t1, t1, 4
  csrw mepc, t1
  mret

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret
