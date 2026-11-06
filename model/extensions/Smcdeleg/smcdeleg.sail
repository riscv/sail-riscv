// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// TODO: Section "Virtualizing Local-Counter-Overflow Interrupts" needs Smaia/Ssaia.
// Once supported, make LCOFI writable in mvip, mvien, hvip and hvien.

function clause currentlyEnabled(Ext_Smcdeleg) = hartSupports(Ext_Smcdeleg) & currentlyEnabled(Ext_Sscsrind)
function clause currentlyEnabled(Ext_Ssccfg) = hartSupports(Ext_Ssccfg) & currentlyEnabled(Ext_Sscsrind)

// siselect 0x40 to 0x5F
function clause indirect_reg_implemented((Sireg, sel, i) if unsigned(0x40) <= unsigned(sel) & unsigned(sel) <= unsigned(0x5F)) = {
  // Indirect HPM State Mappings table
  let state_exists : bool = match (sel[7 .. 0], i) {
    (0x40, 1) => currentlyEnabled(Ext_Zicntr),                 // mcycle
    (0x40, 2) => currentlyEnabled(Ext_Smcntrpmf),              // mcyclecfg
    (0x40, 4) => xlen == 32 & currentlyEnabled(Ext_Zicntr),    // mcycleh
    (0x40, 5) => xlen == 32 & currentlyEnabled(Ext_Smcntrpmf), // mcyclecfgh
    (0x41, _) => false,                                        // mtime
    (0x42, 1) => currentlyEnabled(Ext_Zicntr),                 // minstret
    (0x42, 2) => currentlyEnabled(Ext_Smcntrpmf),              // minstretcfg
    (0x42, 4) => xlen == 32 & currentlyEnabled(Ext_Zicntr),    // minstreth
    (0x42, 5) => xlen == 32 & currentlyEnabled(Ext_Smcntrpmf), // minstretcfgh
    (_, 1)    => currentlyEnabled(Ext_Zihpm),                  // mhpmcounterN
    (_, 2)    => currentlyEnabled(Ext_Zihpm),                  // mhpmeventN
    (_, 4)    => xlen == 32 & currentlyEnabled(Ext_Zihpm),     // mhpmcounterNh
    (_, 5)    => xlen == 32 & currentlyEnabled(Ext_Sscofpmf),  // mhpmeventNh
    _         => false,                                        // sireg3, sireg6
  };
  currentlyEnabled(Ext_Ssccfg) & menvcfg[CDE] == 0b1 & mcounteren.bits[unsigned(sel[4 .. 0])] == 0b1 & state_exists
}

// mcycle, mcycleh, minstret, minstreth

function clause get_ireg((Sireg, sel, 1) if unsigned(sel) == unsigned(0x40)) = mcycle[(xlen - 1) .. 0]
function clause get_ireg((Sireg, sel, 4) if xlen == 32 & unsigned(sel) == unsigned(0x40)) = mcycle[63 .. 32]
function clause get_ireg((Sireg, sel, 1) if unsigned(sel) == unsigned(0x42)) = minstret[(xlen - 1) .. 0]
function clause get_ireg((Sireg, sel, 4) if xlen == 32 & unsigned(sel) == unsigned(0x42)) = minstret[63 .. 32]

function clause set_ireg((Sireg, sel, 1, value) if unsigned(sel) == unsigned(0x40)) = { mcycle[(xlen - 1) .. 0] = value; Ok(value) }
function clause set_ireg((Sireg, sel, 4, value) if xlen == 32 & unsigned(sel) == unsigned(0x40)) = { mcycle[63 .. 32] = value; Ok(value) }
function clause set_ireg((Sireg, sel, 1, value) if unsigned(sel) == unsigned(0x42)) = { minstret[(xlen - 1) .. 0] = value; minstret_increment = false; Ok(value) }
function clause set_ireg((Sireg, sel, 4, value) if xlen == 32 & unsigned(sel) == unsigned(0x42)) = { minstret[63 .. 32] = value; minstret_increment = false; Ok(value) }

// mcyclecfg, mcyclecfgh, minstretcfg, minstretcfgh

// MINH is read-only 0 through sireg*
function read_sireg_cfg(c : CountSmcntrpmf) -> bits(64) = [c with MINH = 0b0].bits
function write_sireg_cfg(c : CountSmcntrpmf, v : bits(64)) -> CountSmcntrpmf =
  legalize_smcntrpmf(c, [Mk_CountSmcntrpmf(v) with MINH = c[MINH]].bits)

function clause get_ireg((Sireg, sel, 2) if unsigned(sel) == unsigned(0x40)) = read_sireg_cfg(mcyclecfg)[xlen - 1 .. 0]
function clause get_ireg((Sireg, sel, 5) if xlen == 32 & unsigned(sel) == unsigned(0x40)) = read_sireg_cfg(mcyclecfg)[63 .. 32]
function clause get_ireg((Sireg, sel, 2) if unsigned(sel) == unsigned(0x42)) = read_sireg_cfg(minstretcfg)[xlen - 1 .. 0]
function clause get_ireg((Sireg, sel, 5) if xlen == 32 & unsigned(sel) == unsigned(0x42)) = read_sireg_cfg(minstretcfg)[63 .. 32]

function clause set_ireg((Sireg, sel, 2, value) if xlen == 64 & unsigned(sel) == unsigned(0x40)) = { mcyclecfg = write_sireg_cfg(mcyclecfg, value); Ok(read_sireg_cfg(mcyclecfg)[xlen - 1 .. 0]) }
function clause set_ireg((Sireg, sel, 2, value) if xlen == 32 & unsigned(sel) == unsigned(0x40)) = { mcyclecfg = write_sireg_cfg(mcyclecfg, mcyclecfg.bits[63 .. 32] @ value); Ok(read_sireg_cfg(mcyclecfg)[xlen - 1 .. 0]) }
function clause set_ireg((Sireg, sel, 5, value) if xlen == 32 & unsigned(sel) == unsigned(0x40)) = { mcyclecfg = write_sireg_cfg(mcyclecfg, value @ mcyclecfg.bits[31 .. 0]); Ok(read_sireg_cfg(mcyclecfg)[63 .. 32]) }
function clause set_ireg((Sireg, sel, 2, value) if xlen == 64 & unsigned(sel) == unsigned(0x42)) = { minstretcfg = write_sireg_cfg(minstretcfg, value); Ok(read_sireg_cfg(minstretcfg)[xlen - 1 .. 0]) }
function clause set_ireg((Sireg, sel, 2, value) if xlen == 32 & unsigned(sel) == unsigned(0x42)) = { minstretcfg = write_sireg_cfg(minstretcfg, minstretcfg.bits[63 .. 32] @ value); Ok(read_sireg_cfg(minstretcfg)[xlen - 1 .. 0]) }
function clause set_ireg((Sireg, sel, 5, value) if xlen == 32 & unsigned(sel) == unsigned(0x42)) = { minstretcfg = write_sireg_cfg(minstretcfg, value @ minstretcfg.bits[31 .. 0]); Ok(read_sireg_cfg(minstretcfg)[63 .. 32]) }

// mhpmcounterN, mhpmeventN, mhpmcounterNh
function is_hpm_sel(sel : xlenbits) -> bool = unsigned(0x43) <= unsigned(sel) & unsigned(sel) <= unsigned(0x5F)

// MINH is read-only 0 through sireg* with Sscofpmf
function read_sireg_hpmevent(index : hpmidx) -> bits(64) =
  if currentlyEnabled(Ext_Sscofpmf)
  then [Mk_HpmEvent(mhpmevent[index]) with MINH = 0b0].bits
  else mhpmevent[index]

function write_sireg_hpmevent(index : hpmidx, value : bits(64)) -> unit =
  write_mhpmevent(index, if currentlyEnabled(Ext_Sscofpmf)
                         then [Mk_HpmEvent(value) with MINH = Mk_HpmEvent(mhpmevent[index])[MINH]].bits
                         else value)

function clause get_ireg((Sireg, sel, 1) if is_hpm_sel(sel)) = read_mhpmcounter(hpmidx_from_bits(sel[4 .. 0]))
function clause get_ireg((Sireg, sel, 2) if is_hpm_sel(sel)) = read_sireg_hpmevent(hpmidx_from_bits(sel[4 .. 0]))[xlen - 1 .. 0]
function clause get_ireg((Sireg, sel, 4) if xlen == 32 & is_hpm_sel(sel)) = read_mhpmcounterh(hpmidx_from_bits(sel[4 .. 0]))

// REVIEWER NOTE: The set_ireg* functions defined in this file are essentially
// identical to write_CSR in counters.sail. In theory, we could refactor them
// to use a shared function.

function clause set_ireg((Sireg, sel, 1, value) if is_hpm_sel(sel)) = {
  let index = hpmidx_from_bits(sel[4 .. 0]);
  let full_value : bits(64) = match xlen {
    32 => mhpmcounter[index][63 .. 32] @ value,
    64 => value,
    _  => internal_error(__FILE__, __LINE__, "Unsupported xlen"),
  };
  write_mhpmcounter(index, full_value);
  Ok(read_mhpmcounter(index))
}

function clause set_ireg((Sireg, sel, 2, value) if is_hpm_sel(sel)) = {
  let index = hpmidx_from_bits(sel[4 .. 0]);
  let full_value : bits(64) = match xlen {
    32 => mhpmevent[index][63 .. 32] @ value,
    64 => value,
    _  => internal_error(__FILE__, __LINE__, "Unsupported xlen"),
  };
  write_sireg_hpmevent(index, full_value);
  Ok(read_sireg_hpmevent(index)[xlen - 1 .. 0])
}

function clause set_ireg((Sireg, sel, 4, value) if xlen == 32 & is_hpm_sel(sel)) = {
  let index = hpmidx_from_bits(sel[4 .. 0]);
  write_mhpmcounter(index, value @ mhpmcounter[index][31 .. 0]);
  Ok(read_mhpmcounterh(index))
}

// mhpmeventNh
function clause get_ireg((Sireg, sel, 5) if xlen == 32 & is_hpm_sel(sel)) = read_sireg_hpmevent(hpmidx_from_bits(sel[4 .. 0]))[63 .. 32]

function clause set_ireg((Sireg, sel, 5, value) if xlen == 32 & is_hpm_sel(sel)) = {
  let index = hpmidx_from_bits(sel[4 .. 0]);
  write_sireg_hpmevent(index, value @ mhpmevent[index][31 .. 0]);
  Ok(read_sireg_hpmevent(index)[63 .. 32])
}
