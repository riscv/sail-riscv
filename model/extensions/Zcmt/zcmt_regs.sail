// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zcmt) = hartSupports(Ext_Zcmt) & currentlyEnabled(Ext_Zca) & currentlyEnabled(Ext_Zicsr) & not(hartSupports(Ext_Zcd))

bitfield Jvt : xlenbits = {
  base : xlen - 1 .. 6,
  mode : 5 .. 0
}
register jvt : Jvt

function legalize_jvt(o : Jvt, v : xlenbits) -> Jvt = {
  let v = Mk_Jvt(v);
  [o with
    base = v[base],
    mode = 0b000000
  ]
}

mapping clause csr_name_map = 0x017  <-> "jvt"

function clause is_CSR_accessible(0x017, _, _) = currentlyEnabled(Ext_Zcmt)
function clause write_CSR(0x017, value) = { jvt = legalize_jvt(jvt, value); Ok(jvt.bits) }
function clause read_CSR(0x017) = jvt.bits
