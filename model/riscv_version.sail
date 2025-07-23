/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Privileged and unprivileged spec versions. The versioning system for specifications
// is unclear so we use the riscv-isa-manual Git commit hashes. Any commit you need
// to refer to should be added to this enum IN ORDER FROM OLDEST TO NEWEST.
enum IsaHash = {
  // Tag: Ratified-IMAFDQC (AKA 20191213)
  Hash_66bed2470f68520fadc4bf86c6c000d817fe73f2,

  // Requires PTE reserved bits to be zero.
  Hash_a432a8997892d0a103798c2e436d36ae66da7d34,

  // Tag: Priv-v1.12 (AKA 20211203)
  Hash_98964261c931d51884f733664b22efe43de93033,

  // Tag: 20240411
  Hash_6ee57d8997021aaa8025e208164763fe12e03c19,

  // Abitrary hash that is later than all real hashes.
  Hash_Latest,
}

// For convenience, version comparison operators. This relies on the order of hashes in the enum.
function isa_hash_lt(x : IsaHash, y : IsaHash) -> bool = num_of_IsaHash(x) < num_of_IsaHash(y)
function isa_hash_gt(x : IsaHash, y : IsaHash) -> bool = num_of_IsaHash(x) > num_of_IsaHash(y)
function isa_hash_le(x : IsaHash, y : IsaHash) -> bool = num_of_IsaHash(x) <= num_of_IsaHash(y)
function isa_hash_ge(x : IsaHash, y : IsaHash) -> bool = num_of_IsaHash(x) >= num_of_IsaHash(y)

overload operator < = {isa_hash_lt}
overload operator > = {isa_hash_gt}
overload operator <= = {isa_hash_le}
overload operator >= = {isa_hash_ge}

// Released versions of the privileged spec.
let PrivSpec_20211203 = Hash_98964261c931d51884f733664b22efe43de93033
let PrivSpec_20240411 = Hash_6ee57d8997021aaa8025e208164763fe12e03c19

// This mapping allows using a friendly name in the JSON config file.
mapping priv_spec_name : IsaHash <-> string = {
  Hash_98964261c931d51884f733664b22efe43de93033 <-> "20211203",
  Hash_6ee57d8997021aaa8025e208164763fe12e03c19 <-> "20240411",
  Hash_Latest <-> "latest",
}

let priv_spec_version : IsaHash = priv_spec_name(config base.priv_spec_version)

// Released versions of the unpriv spec.
let UnprivSpec_20191213 = Hash_66bed2470f68520fadc4bf86c6c000d817fe73f2
let UnprivSpec_20240411 = Hash_6ee57d8997021aaa8025e208164763fe12e03c19

mapping unpriv_spec_name : IsaHash <-> string = {
  Hash_66bed2470f68520fadc4bf86c6c000d817fe73f2 <-> "20191213",
  Hash_6ee57d8997021aaa8025e208164763fe12e03c19 <-> "20240411",
  Hash_Latest <-> "latest",
}

let unpriv_spec_version : IsaHash = config base.unpriv_spec_version

// Behavioural changes based on the version. These are named constants for readability.

// In this commit, a new requirement was added that reserved bits
// in PTEs must be zero otherwise the PTE is invalid.
let pte_reserved_bits_must_be_zero = priv_spec_version >= Hash_a432a8997892d0a103798c2e436d36ae66da7d34
