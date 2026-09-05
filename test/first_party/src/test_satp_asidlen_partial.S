#include "common/encoding.h"

// A test for the `memory.asidlen` configuration parameter (ASIDLEN) with a
// non-zero, non-maximal value (here 7). This exercises the general case:
// ASID[ASIDLEN-1:0] is writable, and bits above ASIDLEN are read-only zero.
//
// See RISC-V Privileged ISA: "The least-significant bits of ASID are
// implemented first: that is, if ASIDLEN > 0, ASID[ASIDLEN-1:0] is writable."

#define ASIDLEN 7

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
  # Extract the ASID field into the low bits of t2.
#if __riscv_xlen == 32
  # ASID occupies bits 30:22 (9 bits); shift down and mask to 9 bits.
  srli t2, t0, 22
  li t1, 0x1FF
#else
  # ASID occupies bits 59:44 (16 bits); shift down and mask to 16 bits.
  srli t2, t0, 44
  li t1, 0xFFFF
#endif
  and t2, t2, t1

  # Only the low ASIDLEN bits may be set; the rest must read as zero.
  li t1, ((1 << ASIDLEN) - 1)
  bne t2, t1, fail

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret
