// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Sdtrig) = hartSupports(Ext_Sdtrig)

// If Sdtrig is implemented, at least one trigger is supported.
// The upper bound should reflect the constraint checked in the
// `check_sdtrig()` validator.  It is needed for the typechecker to
// ensure that it fits into tselect.

type trigger_vector_length = if num_triggers <= 0 then 1 else num_triggers
type trigger_index = range(0, trigger_vector_length - 1)

// If num_triggers = 0 is allowed (e.g. as in Spike), then it can be
// handled by returning tdata1 corresponding to TT_none (i.e. zeros())
// in read_CSR for tdata1 for a tselect of 0.
register triggers : vector(trigger_vector_length, Trigger) = vector_init(trig_reset_val)

register tselect : xlenbits = zeros()
mapping clause csr_name_map = 0x7a0  <-> "tselect"
function clause is_CSR_accessible(0x7a0, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a0) = tselect
function clause write_CSR(0x7a0, value) = {
  if sizeof(num_triggers) == 0
  then tselect = zeros()
  else if unsigned(value) >= sizeof(num_triggers)
  then tselect = to_bits(sizeof(num_triggers) - 1)
  else tselect = value;
  Ok(tselect)
}

mapping clause csr_name_map = 0x7a1  <-> "tdata1"
function clause is_CSR_accessible(0x7a1, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a1) = {
  if sizeof(num_triggers) == 0 then return zeros();

  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "read(tdata1): out-of-range tselect: " ^ bits_str(tselect));
  tdata1_of_trigger(triggers[idx])
}
function clause write_CSR(0x7a1, value) = {
  if sizeof(num_triggers) == 0 then return Ok(zeros());

  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "write(tdata1): out-of-range tselect: " ^ bits_str(tselect));
  let t = triggers[idx];
  let t = trigger_write_tdata1(t, value);
  triggers[idx] = t;
  Ok(tdata1_of_trigger(t))
}

mapping clause csr_name_map = 0x7a2  <-> "tdata2"
function clause is_CSR_accessible(0x7a2, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a2) = {
  if sizeof(num_triggers) == 0 then return zeros();

  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "read(tdata2): out-of-range tselect: " ^ bits_str(tselect));
  tdata2_of_trigger(triggers[idx])
}
function clause write_CSR(0x7a2, value) = {
  if sizeof(num_triggers) == 0 then return Ok(zeros());

  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "write(tdata2): out-of-range tselect: " ^ bits_str(tselect));
  let t = trigger_write_tdata2(triggers[idx], value);
  triggers[idx] = t;
  Ok(tdata2_of_trigger(t))
}

mapping clause csr_name_map = 0x7a3  <-> "tdata3"
function clause is_CSR_accessible(0x7a3, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a3) = {
  if sizeof(num_triggers) == 0 then return zeros();

  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "read(tdata3): out-of-range tselect: " ^ bits_str(tselect));
  tdata3_of_trigger(triggers[idx])
}
function clause write_CSR(0x7a3, value) = {
  if sizeof(num_triggers) == 0 then return Ok(zeros());

  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "write(tdata3): out-of-range tselect: " ^ bits_str(tselect));
  let t = trigger_write_tdata3(triggers[idx], value);
  triggers[idx] = t;
  Ok(tdata3_of_trigger(t))
}

mapping clause csr_name_map = 0x7a4  <-> "tinfo"
function clause is_CSR_accessible(0x7a4, _, _) = currentlyEnabled(Ext_Sdtrig)
function clause read_CSR(0x7a4) = {
  // indicate that the trigger does not exist.
  if sizeof(num_triggers) == 0 then return zero_extend(0x1);

  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "read(tinfo): out-of-range tselect: " ^ bits_str(tselect));
  tinfo_of_trigger(triggers[idx]).bits
}
function clause write_CSR(0x7a4, _value) = {
  let idx = unsigned(tselect);
  assert(idx < sizeof(num_triggers), "write(tinfo): out-of-range tselect: " ^ bits_str(tselect));
  // Writing the tinfo CSR has no effect.
  Ok(tinfo_of_trigger(triggers[idx]).bits)
}

register tcontrol : TControl = Mk_TControl(zeros())
mapping clause csr_name_map = 0x7a5  <-> "tcontrol"
function clause is_CSR_accessible(0x7a5, _, _) = currentlyEnabled(Ext_Sdtrig) & sdtrig_has_tcontrol
function clause read_CSR(0x7a5) = tcontrol.bits
function clause write_CSR(0x7a5, value) = {
  let v = Mk_TControl(value);
  tcontrol = [tcontrol with mpte = v[mpte], mte = v[mte]];
  Ok(tcontrol.bits)
}

function tcontrol_trap_into_mmode() -> unit = {
  tcontrol = [tcontrol with mpte = tcontrol[mte], mte = 0b0];
}

function tcontrol_mret_from_mmode() -> unit = {
  tcontrol = [tcontrol with mte = tcontrol[mpte]];
}

// TODO: hcontext @ 0x6a8

register scontext : SContext = Mk_SContext(zeros())
mapping clause csr_name_map = 0x5a8  <-> "scontext"
function clause is_CSR_accessible(0x5a8, _, _) = currentlyEnabled(Ext_Sdtrig) & sdtrig_has_scontext
function clause read_CSR(0x5a8) = scontext.bits
function clause write_CSR(0x5a8, value) = {
  let v = Mk_SContext(value);
  scontext = [scontext with data = v[data]];
  Ok(scontext.bits)
}

// mscontext is an alias for scontext
mapping clause csr_name_map = 0x7aa  <-> "mscontext"
function clause is_CSR_accessible(0x7aa, _, _) = currentlyEnabled(Ext_Sdtrig) & sdtrig_has_scontext
function clause read_CSR(0x7aa) = scontext.bits
function clause write_CSR(0x7aa, value) = {
  let v = Mk_SContext(value);
  scontext = [scontext with data = v[data]];
  Ok(scontext.bits)
}

register mcontext : MContext = Mk_MContext(zeros())
mapping clause csr_name_map = 0x7a8  <-> "mcontext"
function clause is_CSR_accessible(0x7a8, _, _) = currentlyEnabled(Ext_Sdtrig) & sdtrig_has_mcontext
function clause read_CSR(0x7a8) = mcontext.bits
function clause write_CSR(0x7a8, value) = {
  let v = Mk_MContext(value);
  mcontext = [mcontext with hcontext = v[hcontext]];
  Ok(mcontext.bits)
}
