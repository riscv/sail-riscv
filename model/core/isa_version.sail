/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Privileged spec version. This uses the same version for both of
// what the specification sometimes calls "Machine ISA" and
// "Supervisor ISA", and just the "Machine" and "Supervisor" privilege
// levels in the latest version of the spec.  It is conceivable that
// in the future, the Machine and Supervisor portions could get
// different versions.  But for now, there is a single version for
// both for simplicity.

enum Privileged_ISA_Version = {
  Privileged_ISA_1_11,
  Privileged_ISA_1_12,
  Privileged_ISA_1_13,
}

// For convenience, version comparison operators. This relies on the order of values in the enum.
function privileged_isa_version_lt(x : Privileged_ISA_Version, y : Privileged_ISA_Version) -> bool =
  num_of_Privileged_ISA_Version(x) < num_of_Privileged_ISA_Version(y)
function privileged_isa_version_gt(x : Privileged_ISA_Version, y : Privileged_ISA_Version) -> bool =
  num_of_Privileged_ISA_Version(x) > num_of_Privileged_ISA_Version(y)
function privileged_isa_version_le(x : Privileged_ISA_Version, y : Privileged_ISA_Version) -> bool =
  num_of_Privileged_ISA_Version(x) <= num_of_Privileged_ISA_Version(y)
function privileged_isa_version_ge(x : Privileged_ISA_Version, y : Privileged_ISA_Version) -> bool =
  num_of_Privileged_ISA_Version(x) >= num_of_Privileged_ISA_Version(y)

overload operator <  = {privileged_isa_version_lt}
overload operator >  = {privileged_isa_version_gt}
overload operator <= = {privileged_isa_version_le}
overload operator >= = {privileged_isa_version_ge}

let priv_isa_version : Privileged_ISA_Version = config base.privileged_isa_version

// Behavioural changes based on the version. These are named constants for readability.

// In this version, a new requirement was added that reserved bits
// in PTEs must be zero otherwise the PTE is invalid.
// TODO: This is not used yet; this is an example that will be implemented in a future commit.
let pte_reserved_bits_must_be_zero = priv_isa_version >= Privileged_ISA_1_12

// This version defined the `{m,s,h}envcfg` CSRs. These CSRs are not
// available in earlier versions.
let xenvcfg_csrs_are_defined = priv_isa_version >= Privileged_ISA_1_12
