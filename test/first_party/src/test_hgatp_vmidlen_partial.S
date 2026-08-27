#include "common/encoding.h"

// A test for the `memory.vmidlen` configuration parameter (VMIDLEN) with a
// non-zero, non-maximal value (here 5). This exercises the general case:
// VMID[VMIDLEN-1:0] is writable, and bits above VMIDLEN are read-only zero.
//
// See RISC-V Privileged ISA: "The least-significant bits of VMID are
// implemented first: that is, if VMIDLEN > 0, VMID[VMIDLEN-1:0] is writable."

#define VMIDLEN 5

.global main
main:
  # Save the return address.
  mv s1, ra

write_hgatp:
#if __riscv_xlen == 32
  # Sv32x4: set MODE=Sv32x4 and write all ones to the VMID field.
  li t0, HGATP32_MODE * HGATP_MODE_SV32X4
  li t1, HGATP32_VMID
  or t0, t0, t1
#else
  # Sv39x4: set MODE=Sv39x4 and write all ones to the VMID field.
  li t0, (HGATP64_MODE & ~(HGATP64_MODE << 1)) * HGATP_MODE_SV39X4
  li t1, HGATP64_VMID
  or t0, t0, t1
#endif
  csrw hgatp, t0

read_vmid:
  csrr t0, hgatp
  # Extract the VMID field into the low bits of t2.
#if __riscv_xlen == 32
  # VMID occupies bits 28:22 (7 bits); shift down and mask to 7 bits.
  srli t2, t0, 22
  li t1, 0x7F
#else
  # VMID occupies bits 57:44 (14 bits); shift down and mask to 14 bits.
  srli t2, t0, 44
  li t1, 0x3FFF
#endif
  and t2, t2, t1

  # Only the low VMIDLEN bits may be set; the rest must read as zero.
  li t1, ((1 << VMIDLEN) - 1)
  bne t2, t1, fail

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret
