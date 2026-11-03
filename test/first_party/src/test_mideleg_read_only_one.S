#include "common/encoding.h"

// A test for the `base.mideleg.read_only_one_bits` configuration
// parameter. The override config makes the S-level interrupt bits of
// `mideleg` (SSI, STI, SEI and LCOFI) read-only one, i.e. always
// delegated.
//
// See RISC-V Privileged ISA: "an implementation shall not fix as
// read-only one any bits of mideleg corresponding to machine-level
// interrupts (but may do so for lower-level interrupts)."

#define RO_ONE_BITS (MIP_SSIP | MIP_STIP | MIP_SEIP | MIP_LCOFIP)
// Bits that are read-only one in mideleg because of the H extension.
#define H_RO_ONE_BITS (MIP_VSSIP | MIP_VSTIP | MIP_VSEIP | MIP_SGEIP)

.global main
main:
  # Save the return address.
  mv s1, ra

  # The read-only-one bits must read as one out of reset.
reset_value:
  csrr t0, mideleg
  li t1, RO_ONE_BITS
  and t2, t0, t1
  bne t2, t1, fail

  # Writing zero must not clear the read-only-one bits.
write_zero:
  csrw mideleg, zero
  csrr t0, mideleg
  li t1, ~H_RO_ONE_BITS
  and t0, t0, t1
  li t1, RO_ONE_BITS
  bne t0, t1, fail

  # Writing all ones must not set any other bits, in particular those
  # for machine-level interrupts (MSI, MTI, MEI).
write_ones:
  li t0, -1
  csrw mideleg, t0
  csrr t0, mideleg
  li t1, ~H_RO_ONE_BITS
  and t0, t0, t1
  li t1, RO_ONE_BITS
  bne t0, t1, fail

  # Since the S-level interrupts are always delegated, the sie and sip
  # views must expose them even after writing zero to mideleg.
sie_view:
  csrw mideleg, zero
  li t0, MIP_SSIP | MIP_STIP | MIP_SEIP
  csrw mie, t0
  csrr t1, sie
  bne t0, t1, fail
  csrw mie, zero

sip_view:
  # SSIP is writable through sip only when SSI is delegated.
  csrw mip, zero
  li t0, SIP_SSIP
  csrs sip, t0
  csrr t1, mip
  and t1, t1, t0
  bne t1, t0, fail
  csrw mip, zero

pass:
  li a0, 0
  mv ra, s1
  ret

fail:
  li a0, 1
  mv ra, s1
  ret
