#include "common/encoding.h"

// A test for the `memory.asidlen` configuration parameter (ASIDLEN).
//
// The test is configured with an override of 0 implemented ASID bits,
// which models implementations such as the StarFive JH7110 / SiFive U74
// (VisionFive 2) that implement ASIDLEN=0. In that case the entire `Asid`
// field of `satp` must read as zero, even after writing all ones to it.
//
// See RISC-V Privileged ISA: "The number of ASID bits is UNSPECIFIED and
// may be zero." and "if ASIDLEN > 0, ASID[ASIDLEN-1:0] is writable" — i.e.
// with ASIDLEN=0 no ASID bits are writable.

.global main
main:
  # Save the return address.
  mv s1, ra

write_satp:
#if __riscv_xlen == 32
  # Sv32: set MODE=Sv32 and write all ones to the ASID field.
  li t0, SATP32_MODE * SATP_MODE_SV32
  li t1, SATP32_ASID
  or t0, t0, t1
#else
  # Sv39: set MODE=Sv39 and write all ones to the ASID field.
  li t0, (SATP_MODE & ~(SATP_MODE << 1)) * SATP_MODE_SV39
  li t1, SATP64_ASID
  or t0, t0, t1
#endif
  csrw satp, t0

read_asid:
  csrr t0, satp
#if __riscv_xlen == 32
  li t1, SATP32_ASID
#else
  li t1, SATP64_ASID
#endif
  and t0, t0, t1
  # With asidlen=0, the entire ASID field must read as zero.
  li t1, 0
  bne t0, t1, fail

read_mode:
  # The MODE field must still be preserved.
  csrr t0, satp
#if __riscv_xlen == 32
  li t1, SATP32_MODE * SATP_MODE_SV32
#else
  li t1, (SATP_MODE & ~(SATP_MODE << 1)) * SATP_MODE_SV39
#endif
  and t0, t0, t1
  bne t0, t1, fail

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret
