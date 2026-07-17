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

// The ratification commits (or the closest such commits) for the
// versions in the specification repository are specified in comments
// when available.
enum Privileged_ISA_Version = {
  // commit f467e5dfd4acb4391870b8bfcfd687a0e5d8eddc (tag: Ratified-IMFDQC-and-Priv-v1.11)
  Privileged_ISA_1_11,
  // commit 75b2fbbdd783d539da69826fc3c11478b070c10b
  Privileged_ISA_1_12,
  // commit 2c07aa2bcc02fd5fb2e53e42a32dc62a3eb0aa62 (tag: riscv-isa-release-2c07aa2-2024-10-18)
  Privileged_ISA_1_13,
}

mapping privileged_isa_version_name : Privileged_ISA_Version <-> string = {
  Privileged_ISA_1_11 <-> "1.11",
  Privileged_ISA_1_12 <-> "1.12",
  Privileged_ISA_1_13 <-> "1.13",
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
let pte_reserved_bits_must_be_zero = priv_isa_version >= Privileged_ISA_1_12


// CSRs added in version 1.12. These CSRs are not
// available in earlier versions.
let xenvcfg_csrs_are_defined = priv_isa_version >= Privileged_ISA_1_12
let mconfigptr_is_defined = priv_isa_version >= Privileged_ISA_1_12
let mseccfg_csrs_are_defined = priv_isa_version >= Privileged_ISA_1_12
let mstatush_is_defined = priv_isa_version >= Privileged_ISA_1_12
// PMP register count is checked in validate_config() by check_version_constraints().

// CSRs added in version 1.13. These CSRs are not
// available in earlier versions.
let delegh_csrs_are_defined = priv_isa_version >= Privileged_ISA_1_13
