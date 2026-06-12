/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Privileged and unprivileged spec versions. The versioning system for specifications
// is unclear so we specify the riscv-isa-manual Git commit hashes in comments. Any commit you need
// to refer to should be added to this enum IN ORDER FROM OLDEST TO NEWEST.
enum IsaVersion = {
  // Tag: Ratified-IMAFDQC (AKA 20191213). Commit: 66bed2470f68520fadc4bf86c6c000d817fe73f2
  Isa_20191213,

  // Requires PTE reserved bits to be zero. Commit: a432a8997892d0a103798c2e436d36ae66da7d34
  Isa_Draft_20211102,

  // Tag: Priv-v1.12 (AKA 20211203). Commit: 98964261c931d51884f733664b22efe43de93033
  Isa_20211203,

  // Tag: 20240411. Commit: 6ee57d8997021aaa8025e208164763fe12e03c19
  Isa_20240411,

  // Arbitrary version that is later than all other versions.
  Isa_Latest,
}

// For convenience, version comparison operators. This relies on the order of hashes in the enum.
function isa_version_lt(x : IsaVersion, y : IsaVersion) -> bool = num_of_IsaVersion(x) < num_of_IsaVersion(y)
function isa_version_gt(x : IsaVersion, y : IsaVersion) -> bool = num_of_IsaVersion(x) > num_of_IsaVersion(y)
function isa_version_le(x : IsaVersion, y : IsaVersion) -> bool = num_of_IsaVersion(x) <= num_of_IsaVersion(y)
function isa_version_ge(x : IsaVersion, y : IsaVersion) -> bool = num_of_IsaVersion(x) >= num_of_IsaVersion(y)

overload operator < = {isa_version_lt}
overload operator > = {isa_version_gt}
overload operator <= = {isa_version_le}
overload operator >= = {isa_version_ge}

let isa_version : IsaVersion = config base.isa_version

// Behavioural changes based on the version. These are named constants for readability.

// In this commit, a new requirement was added that reserved bits
// in PTEs must be zero otherwise the PTE is invalid.
// TODO: This is not used yet; this is an example that will be implemented in a future commit.
let pte_reserved_bits_must_be_zero = isa_version >= Isa_Draft_20211102
