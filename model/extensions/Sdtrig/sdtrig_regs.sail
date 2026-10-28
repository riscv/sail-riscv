// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Sdtrig) = hartSupports(Ext_Sdtrig)

register triggers : vector(num_triggers, Trigger) = vector_init(trig_reset_val)

register tselect : xlenbits = zeros()
mapping clause csr_name_map = 0x7a0  <-> "tselect"
function clause is_CSR_accessible(0x7a0, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a0) = tselect
function clause write_CSR(0x7a0, value) = {
  if num_triggers == 0
  then tselect = zeros()
  else if unsigned(value) >= num_triggers
  then tselect = to_bits(num_triggers - 1)
  else tselect = value;
  Ok(tselect)
}

// If a trigger is written to by a CSR write, it might need processing
// after the current instruction has finished (e.g. the count for
// `icount` triggers).  Store the index to be processed.
private enum tdata = {TDATA1, TDATA2, TDATA3}
register written_trigger_index : option((trigger_index, tdata)) = None()

mapping clause csr_name_map = 0x7a1  <-> "tdata1"
function clause is_CSR_accessible(0x7a1, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a1) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "read(tdata1): out-of-range tselect: " ^ bits_str(tselect));
  tdata1_of_trigger(triggers[idx])
}
function clause write_CSR(0x7a1, value) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "write(tdata1): out-of-range tselect: " ^ bits_str(tselect));
  let t = triggers[idx];
  let t = trigger_write_tdata1(idx, t, value);
  triggers[idx] = t;
  written_trigger_index = Some(idx, TDATA1);
  Ok(tdata1_of_trigger(t))
}

mapping clause csr_name_map = 0x7a2  <-> "tdata2"
function clause is_CSR_accessible(0x7a2, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a2) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "read(tdata2): out-of-range tselect: " ^ bits_str(tselect));
  tdata2_of_trigger(triggers[idx])
}
function clause write_CSR(0x7a2, value) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "write(tdata2): out-of-range tselect: " ^ bits_str(tselect));
  let t = trigger_write_tdata2(idx, triggers[idx], value);
  triggers[idx] = t;
  written_trigger_index = Some(idx, TDATA2);
  Ok(tdata2_of_trigger(t))
}

mapping clause csr_name_map = 0x7a3  <-> "tdata3"
function clause is_CSR_accessible(0x7a3, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a3) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "read(tdata3): out-of-range tselect: " ^ bits_str(tselect));
  tdata3_of_trigger(triggers[idx])
}
function clause write_CSR(0x7a3, value) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "write(tdata3): out-of-range tselect: " ^ bits_str(tselect));
  let t = trigger_write_tdata3(idx, triggers[idx], value);
  triggers[idx] = t;
  written_trigger_index = Some(idx, TDATA3);
  Ok(tdata3_of_trigger(t))
}

mapping clause csr_name_map = 0x7a4  <-> "tinfo"
function clause is_CSR_accessible(0x7a4, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a4) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "read(tinfo): out-of-range tselect: " ^ bits_str(tselect));
  tinfo_of_trigger(triggers[idx]).bits
}
function clause write_CSR(0x7a4, _value) = {
  let idx = unsigned(tselect);
  assert(idx < num_triggers, "write(tinfo): out-of-range tselect: " ^ bits_str(tselect));
  // Writing the tinfo CSR has no effect.
  Ok(tinfo_of_trigger(triggers[idx]).bits)
}

register tcontrol : TControl = Mk_TControl(zeros())
mapping clause csr_name_map = 0x7a5  <-> "tcontrol"
function clause is_CSR_accessible(0x7a5, _, _) = currentlyEnabled(Ext_Sdtrig) & sdtrig_has_tcontrol
function clause read_CSR(0x7a5) = tcontrol.bits
let use_tcontrol_reentrancy = sdtrig_breakpoint_reentrancy == Use_tcontrol
function clause write_CSR(0x7a5, value) = {
  let v = Mk_TControl(value);
  tcontrol = [tcontrol with
    mpte = if use_tcontrol_reentrancy then v[mpte] else 0b0,
    mte  = if use_tcontrol_reentrancy then v[mte] else 0b0
  ];
  Ok(tcontrol.bits)
}

function tcontrol_trap_into_mmode() -> unit = {
  tcontrol = [tcontrol with mpte = tcontrol[mte], mte = 0b0];
  csr_write_callback("tcontrol", tcontrol.bits);
}

function tcontrol_mret_from_mmode() -> unit = {
  tcontrol = [tcontrol with mte = tcontrol[mpte]];
  csr_write_callback("tcontrol", tcontrol.bits);
}

let sdtrig_scontext_width : range(0, 32) = config extensions.Sdtrig.scontext.width
let scontext_mask : bits(32) = zero_extend(ones(sdtrig_scontext_width))

register scontext : SContext = Mk_SContext(zeros())
mapping clause csr_name_map = 0x5a8  <-> "scontext"
function clause is_CSR_accessible(0x5a8, _, _) = currentlyEnabled(Ext_Sdtrig) & sdtrig_has_scontext
function clause read_CSR(0x5a8) = scontext.bits
function clause write_CSR(0x5a8, value) = {
  let v = Mk_SContext(value);
  scontext = [scontext with data = v[data] & scontext_mask];
  Ok(scontext.bits)
}

let sdtrig_hcontext_width : range(0, 14) = config extensions.Sdtrig.hcontext.width
let hcontext_mask : bits(14) = zero_extend(ones(sdtrig_hcontext_width))

register mcontext : MContext = Mk_MContext(zeros())
mapping clause csr_name_map = 0x7a8  <-> "mcontext"
function clause is_CSR_accessible(0x7a8, _, _) = currentlyEnabled(Ext_Sdtrig) & (sdtrig_has_mcontext | sdtrig_has_hcontext)
function clause read_CSR(0x7a8) = mcontext.bits
function clause write_CSR(0x7a8, value) = {
  let v = Mk_MContext(value);
  mcontext = [mcontext with hcontext = v[hcontext] & hcontext_mask];
  Ok(mcontext.bits)
}

mapping clause csr_name_map = 0x6a8  <-> "hcontext"
function clause is_CSR_accessible(0x6a8, _, _) = currentlyEnabled(Ext_Sdtrig) & currentlyEnabled(Ext_H) & sdtrig_has_hcontext
function clause read_CSR(0x6a8) = mcontext.bits
function clause write_CSR(0x6a8, value) = {
  let v = Mk_MContext(value);
  mcontext = [mcontext with hcontext = v[hcontext]];
  Ok(mcontext.bits)
}
