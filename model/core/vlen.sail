// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// The order of vector_support is significant - each level implies all of the previous levels.
enum vector_support = {
  Disabled,
  Integer,
  Float_single,
  Float_double,
  Full,
}

let vector_support_level : vector_support = config extensions.V.support_level

function vector_support_lt(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) < num_of_vector_support(y)
function vector_support_gt(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) > num_of_vector_support(y)
function vector_support_le(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) <= num_of_vector_support(y)
function vector_support_ge(x : vector_support, y : vector_support) -> bool = num_of_vector_support(x) >= num_of_vector_support(y)

overload operator < = {vector_support_lt}
overload operator > = {vector_support_gt}
overload operator <= = {vector_support_le}
overload operator >= = {vector_support_ge}

type vlen_exp : Int = config extensions.V.vlen_exp
constraint 3 <= vlen_exp <= 16

// Note: ELEN=32 requires a different encoding of the CSR vtype.
// The current version of vtype implementation corresponds to the ELEN=64 configuration.
// TODO: the configuration of ELEN and its corresponding vtype implementations.
type elen_exp : Int = config extensions.V.elen_exp
constraint 3 <= elen_exp <= 16 & elen_exp <= vlen_exp

let vlen_exp = sizeof(vlen_exp)
let elen_exp = sizeof(elen_exp)

type vlen : Int = 2 ^ vlen_exp
type elen : Int = 2 ^ elen_exp

let vlen = sizeof(vlen)
let elen = sizeof(elen)
