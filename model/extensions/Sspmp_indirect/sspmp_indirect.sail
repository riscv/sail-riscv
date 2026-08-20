// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Sspmp_indirect: indirect SPMP CSR access.
//
// SPMP entries have no directly addressed CSRs. siselect and miselect values
// 0x100..0x13F select entries 0..63, sireg/mireg access spmpaddr, and
// sireg2/mireg2 access spmpcfg.

let SSPMP_SEL_BASE : nat = 256  // 0x100
let SSPMP_SEL_LAST : nat = 319  // 0x13F

private function sspmp_sel_in_range(sel : Iselect) -> bool = {
  let v = unsigned(sel[csr]);
  (v >= SSPMP_SEL_BASE) & (v <= SSPMP_SEL_LAST)
}

private function sspmp_entry_idx(sel : Iselect) -> int = unsigned(sel[csr]) - SSPMP_SEL_BASE

private function sspmp_sel_reg(ireg : IregType) -> Iselect =
  match ireg { Mireg => miselect, Sireg => siselect }

// Unimplemented entries remain accessible but read as zero and ignore writes.
function sspmp_ireg_accessible(sel : Iselect, _ireg : IregType) -> bool =
  sspmp_sel_in_range(sel)

function sspmp_ireg_read(ireg : IregType, i : range(0, 6)) -> xlenbits = {
  let sel = sspmp_sel_reg(ireg);
  if sspmp_sel_in_range(sel) then {
    let idx = sspmp_entry_idx(sel);
    match (ireg, i) {
      (Sireg, 1) => spmp_read_addr_indirect(idx),
      (Sireg, 2) => zero_extend(spmp_read_cfg_indirect(idx).bits),
      (Mireg, 1) => spmp_mmode_read_addr_indirect(idx),
      (Mireg, 2) => zero_extend(spmp_mmode_read_cfg_indirect(idx).bits),
      // sireg3..6 and mireg3..6 are WPRI: reads return zero, writes are ignored.
      (_, _)     => zeros(),
    }
  } else zeros()
}

function sspmp_ireg_write(ireg : IregType, i : range(0, 6), value : xlenbits) -> xlenbits = {
  let sel = sspmp_sel_reg(ireg);
  if sspmp_sel_in_range(sel) then {
    let idx = sspmp_entry_idx(sel);
    match (ireg, i) {
      (Sireg, 1) => { spmp_write_addr_indirect(idx, value); spmp_read_addr_indirect(idx) },
      (Sireg, 2) => {
        spmp_write_cfg_indirect(idx, Mk_Spmpcfg_ent(value[9 .. 0]));
        zero_extend(spmp_read_cfg_indirect(idx).bits)
      },
      (Mireg, 1) => { spmp_mmode_write_addr_indirect(idx, value); spmp_mmode_read_addr_indirect(idx) },
      (Mireg, 2) => {
        spmp_mmode_write_cfg_indirect(idx, Mk_Spmpcfg_ent(value[9 .. 0]));
        zero_extend(spmp_mmode_read_cfg_indirect(idx).bits)
      },
      (_, _)     => zeros(),
    }
  } else zeros()
}
