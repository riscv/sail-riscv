// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

struct mul_op = {
  result_part : VectorHalf,
  signed_rs1  : Signedness,
  signed_rs2  : Signedness
}
