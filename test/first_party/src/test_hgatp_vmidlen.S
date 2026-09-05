#include "common/encoding.h"

// A test for the `memory.vmidlen` configuration parameter (VMIDLEN).
//
// The test is configured with an override of 0 implemented VMID bits.
// In that case the entire `VMID` field of `hgatp` must read as zero,
// even after writing all ones to it.
//
// See RISC-V Privileged ISA: "The number of implemented VMID bits,
// termed VMIDLEN, may be determined by writing one to every bit
// position in the VMID field" and "if VMIDLEN > 0, VMID[VMIDLEN-1:0]
// is writable" — i.e. with VMIDLEN=0 no VMID bits are writable.

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
#if __riscv_xlen == 32
  li t1, HGATP32_VMID
#else
  li t1, HGATP64_VMID
#endif
  and t0, t0, t1
  # With vmidlen=0, the entire VMID field must read as zero.
  li t1, 0
  bne t0, t1, fail

read_mode:
  # The MODE field must still be preserved.
  csrr t0, hgatp
#if __riscv_xlen == 32
  li t1, HGATP32_MODE * HGATP_MODE_SV32X4
#else
  li t1, (HGATP64_MODE & ~(HGATP64_MODE << 1)) * HGATP_MODE_SV39X4
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
