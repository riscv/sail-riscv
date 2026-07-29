#include "common/encoding.h"

.global main
main:
  # A simple test to check the `physaddr_bits` attribute.
  #
  # The test is configured with an override of 33 physical address
  # bits, which is less than the default for both RV32 and RV64 but
  # still works with the default memory map.

  # Save the return address.
  mv s1, ra

write_satp:
#if __riscv_xlen == 32
  # Sv32
  li t0, 0x80000000
  # Write all ones to PPN (22 lowest bits on RV32)
  li t1, SATP32_PPN
  or t0, t0, t1
#else
  # Sv39
  li t0, (SATP_MODE & ~(SATP_MODE << 1)) * SATP_MODE_SV39
  # Write all ones to PPN (44 lowest bits on RV64).
  li t1, SATP64_PPN
  or t0, t0, t1
#endif
  csrw satp, t0

read_satp:
  csrr t0, satp
#if __riscv_xlen == 32
  li t1, SATP32_PPN
#else
  li t1, SATP64_PPN
#endif
  and t0, t0, t1
  # This should only have 33 - 12 = 21 bits set.
  li t1, 0x01FFFFF
  bne t0, t1, fail

test_pmp:
  # The crt0.s uses pmpcfg0 and pmpaddr0.  Use a different set instead.
  li t0, -1
  csrw pmpaddr3, t0
  csrr t0, pmpaddr3
  # Bits above 33 - 2 = 31 should be zero (since the lowest 2 bits are omitted in PMP addr CSRs.)
  li t1, 0x7FFFFFFF
  bne t0, t1, fail

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret
