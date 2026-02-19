// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

let rcidlen : range(1, 12) = config extensions.Ssqosid.rcid_length
let mcidlen : range(1, 12) = config extensions.Ssqosid.mcid_length

bitfield Srmcfg : xlenbits = {
  RCID  : 27 .. 16,
  MCID  : 11 .. 0
}

function clause currentlyEnabled(Ext_Ssqosid) = hartSupports(Ext_Ssqosid) & currentlyEnabled(Ext_Zicsr)

private function legalize_srmcfg(o: Srmcfg, value : xlenbits) -> Srmcfg = {
  let v = Mk_Srmcfg(value);
  let rcid_mask : bits(12) = zero_extend(ones(rcidlen));
  let mcid_mask : bits(12) = zero_extend(ones(mcidlen));
  [o with
    RCID = v[RCID] & rcid_mask,
    MCID = v[MCID] & mcid_mask
  ]
}

register srmcfg : Srmcfg

// Ssqosid - Quality-of-Service (Qos) Identifiers
mapping clause csr_name_map = 0x181  <-> "srmcfg"

function clause is_CSR_accessible(0x181, _, _) = csr_requires_ext(Ext_Ssqosid)

function clause read_CSR(0x181) = srmcfg.bits

function clause write_CSR(0x181, value) = { srmcfg = legalize_srmcfg(srmcfg, value); Ok(srmcfg.bits) }
