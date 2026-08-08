// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Smpmpind: indirect PMP CSR access.
//
// miselect 0x300..0x33F selects PMP entries 0..63. mireg accesses pmpaddr,
// while mireg2 accesses pmpcfg and the E bit.

function clause currentlyEnabled(Ext_Smpmpind) =
  hartSupports(Ext_Smpmpind) & currentlyEnabled(Ext_Smcsrind)

let SMPMPIND_SEL_BASE : nat = 768   // 0x300
let SMPMPIND_SEL_LAST : nat = 831   // 0x33F

private function smpmpind_sel_in_range(sel : Iselect) -> bool = {
  let v = unsigned(sel[csr]);
  (v >= SMPMPIND_SEL_BASE) & (v <= SMPMPIND_SEL_LAST)
}

private function smpmpind_read_entry(idx : range(0, 63), ireg_index : range(0, 6)) -> xlenbits =
  match ireg_index {
    1 => pmpReadAddrReg(idx),
    2 => {
      // pmpcfg byte in the low bits, E bit at MXLEN-1.
      let cfg_low : xlenbits = zero_extend(pmpcfg_n[idx].bits);
      [cfg_low with (xlen - 1) .. (xlen - 1) = pmp_E[idx]]
    },
    // mireg3..6 reserved WPRI: read zero, writes ignored.
    _ => zeros(),
  }

private function smpmpind_write_entry(idx : range(0, 63), ireg_index : range(0, 6), value : xlenbits) -> xlenbits =
  if idx >= sys_pmp_usable_count then zeros()
  else match ireg_index {
    1 => { pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) },
    2 => {
      let new_byte : bits(8) = value[7 .. 0];
      let new_E    : bits(1) = value[(xlen - 1) .. (xlen - 1)];

      let old_cfg = pmpcfg_n[idx];
      let was_locked = pmpLocked(old_cfg);

      if not(was_locked) then {
        pmpcfg_n[idx] = pmpWriteCfg(old_cfg, new_byte, new_E);
        pmp_E[idx] = new_E;
      };

      let cfg_low : xlenbits = zero_extend(pmpcfg_n[idx].bits);
      [cfg_low with (xlen - 1) .. (xlen - 1) = pmp_E[idx]]
    },
    _ => zeros(),
  }

function smpmpind_ireg_accessible(sel : Iselect, ireg : IregType) -> bool =
  ireg == Mireg & smpmpind_sel_in_range(sel)
  & (unsigned(sel[csr]) - SMPMPIND_SEL_BASE) < sys_pmp_count

function smpmpind_ireg_read(ireg : IregType, i : range(0, 6)) -> xlenbits = {
  if ireg == Mireg & smpmpind_sel_in_range(miselect) then {
    let raw_idx = unsigned(miselect[csr]) - SMPMPIND_SEL_BASE;
    if (raw_idx >= 0) & (raw_idx <= 63) & (raw_idx < sys_pmp_count)
    then {
      let idx : range(0, 63) = raw_idx;
      smpmpind_read_entry(idx, i)
    } else zeros()
  } else zeros()
}

function smpmpind_ireg_write(ireg : IregType, i : range(0, 6), value : xlenbits) -> xlenbits = {
  if ireg == Mireg & smpmpind_sel_in_range(miselect) then {
    let raw_idx = unsigned(miselect[csr]) - SMPMPIND_SEL_BASE;
    if (raw_idx >= 0) & (raw_idx <= 63) & (raw_idx < sys_pmp_count)
    then {
      let idx : range(0, 63) = raw_idx;
      smpmpind_write_entry(idx, i, value)
    } else zeros()
  } else zeros()
}
