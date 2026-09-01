// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Instructions of the Zimt memory tagging extension (v0.2, DRAFT):
// gentag, addtag, settag, checktag.
//
// All four are taken from the Zimop MOP.RR encoding space (SYSTEM
// opcode, funct3 0b100): gentag/addtag/checktag from MOP.RR.1
// (funct7 0b1000011) and settag from MOP.RR.0 (funct7 0b1000001).
// Within MOP.RR.1, gentag has rs1 = x0 and tag_imm4 = 0, addtag has
// tag_imm4 != 0, and checktag has rd = x0.
//
// The decode clauses are guarded on currentlyEnabled(Ext_Zimt); when
// Zimt is not enabled the encodings fall through to the ZIMOP_MOP_RR
// clause (the `mops` module is loaded after `extensions` for exactly
// this reason). When Zimt is enabled but memory tagging is disabled
// in the current execution environment, the execute clauses implement
// the spec-mandated fallback: zero the destination (identical to
// Zimop), except addtag which copies rs1 to rd so that rd always
// holds a valid pointer on an MT-implementing hart.

union clause instruction = GENTAG : (regidx)
union clause instruction = ADDTAG : (bits(4), regidx, regidx)
union clause instruction = SETTAG : (bits(4), regidx)
union clause instruction = CHECKTAG : (bits(4), regidx)

mapping clause encdec = GENTAG(rd)
  <-> 0b1000011 @ 0b0 @ 0b0000 @ 0b00000 @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_Zimt) & rd != zreg

mapping clause encdec = ADDTAG(imm, rs1, rd)
  <-> 0b1000011 @ 0b0 @ imm @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_Zimt) & imm != 0b0000 & rd != zreg

mapping clause encdec = CHECKTAG(imm, rs1)
  <-> 0b1000011 @ 0b0 @ imm @ encdec_reg(rs1) @ 0b100 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_Zimt) & rs1 != zreg

mapping clause encdec = SETTAG(imm, rs1)
  <-> 0b1000001 @ 0b0 @ imm @ encdec_reg(rs1) @ 0b100 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_Zimt) & rs1 != zreg

// gentag state.
//
// TG DISCUSSION ITEM: the spec requires gentag to produce
// pseudorandom, uniformly distributed tags over the permitted values.
// A deterministic reference model cannot be both reproducible and
// unpredictable; this implementation keeps a free-running 7-bit
// counter and returns the first permitted tag value cyclically at or
// above it, which guarantees every permitted value occurs but NOT
// uniformity or unpredictability. Tests must not rely on specific
// generated values, except when the exclusion mask permits exactly
// one value.
register zimt_gentag_state : bits(7) = zeros()

// First tag value permitted by `mask`, searching cyclically from
// `start`. The exclusion-mask WARL rule guarantees at least one
// permitted value in [15:0], so the search always succeeds.
function zimt_pick_tag(mask : bits(128), start : range(0, 127), num_tags : {16, 128}) -> range(0, 127) = {
  var chosen : range(0, 127) = 0;
  var found : bool = false;
  foreach (i from 0 to 127) {
    if (i < num_tags) & not(found) then {
      let cand = (start + i) % num_tags;
      if mask[cand] == bitzero then {
        chosen = cand;
        found = true;
      }
    }
  };
  assert(found, "Zimt: exclusion mask permits no tag value");
  chosen
}

function clause execute GENTAG(rd) = {
  let mode = get_mt_mode(cur_privilege);
  if mode == MT_MODE_Disabled then {
    // Zimop fallback: zero the destination.
    X(rd) = zeros();
    return RETIRE_SUCCESS
  };
  let w = enabled_pointer_tag_width(mode);
  let num_tags : {16, 128} = if w == 4 then 16 else 128;
  let mask = get_mtag_exclusion_mask(cur_privilege);
  zimt_gentag_state = zimt_gentag_state + 1;
  let start = unsigned(zimt_gentag_state) % num_tags;
  let tag = zimt_pick_tag(mask, start, num_tags);
  X(rd) = insert_pointer_tag(zeros(), to_bits(7, tag), w);
  RETIRE_SUCCESS
}

function clause execute ADDTAG(imm, rs1, rd) = {
  let mode = get_mt_mode(cur_privilege);
  if mode == MT_MODE_Disabled then {
    // Implemented-but-disabled: move rs1 to rd (NOT the Zimop
    // zeroing), so rd always holds a valid pointer.
    X(rd) = X(rs1);
    return RETIRE_SUCCESS
  };
  let w = enabled_pointer_tag_width(mode);
  let tag = extract_pointer_tag(X(rs1), w) + zero_extend(imm);
  X(rd) = insert_pointer_tag(X(rs1), tag, w);
  RETIRE_SUCCESS
}

function clause execute SETTAG(imm, rs1) = {
  let mode = get_mt_mode(cur_privilege);
  // Zimop fallback (write x0) is a no-op.
  if mode == MT_MODE_Disabled then return RETIRE_SUCCESS;
  let w = enabled_pointer_tag_width(mode);
  let raw = X(rs1);
  let mc_tag = mc_tag_of_pointer_tag(extract_pointer_tag(raw, w), mode);
  let vitt : xlenbits = match get_vitt_base(cur_privilege) {
    Some(base) => base,
    // No tag table (Svatag/Smvatag not enabled for this privilege).
    None() => return memory_exception(E_SAMO_Access_Fault(), raw, Store(Tag)),
  };
  // Strip the pointer tag via the pointer-masking transform; the
  // first chunk is at the 16-byte aligned address.
  let va = bits_of(transform_effective_address(Virtaddr(raw), Store(Data)));
  let chunk0 = va >> 4;
  foreach (i from 0 to unsigned(imm)) {
    match zimt_store_mc_tag(vitt, chunk0 + to_bits(xlen, i), mc_tag, mode) {
      Err(e) => return e,
      Ok(()) => (),
    }
  };
  RETIRE_SUCCESS
}

function clause execute CHECKTAG(imm, rs1) = {
  let mode = get_mt_mode(cur_privilege);
  // Zimop fallback (write x0) is a no-op.
  if mode == MT_MODE_Disabled then return RETIRE_SUCCESS;
  let w = enabled_pointer_tag_width(mode);
  let raw = X(rs1);
  let expected = mc_tag_of_pointer_tag(extract_pointer_tag(raw, w), mode);
  let vitt : xlenbits = match get_vitt_base(cur_privilege) {
    Some(base) => base,
    None() => return memory_exception(E_Load_Access_Fault(), raw, Load(Tag)),
  };
  let va = bits_of(transform_effective_address(Virtaddr(raw), Load(Data)));
  // checktag checks whole chunks: chunk_count + 1 chunks of 16 bytes
  // starting at the chunk containing va.
  let chunk0 = va >> 4;
  foreach (i from 0 to unsigned(imm)) {
    match zimt_load_mc_tag(vitt, chunk0 + to_bits(xlen, i), mode) {
      Err(e) => return e,
      Ok(mc_tag) => if mc_tag != expected then return trap(make_mem_tag_exception(Load(Tag))),
    }
  };
  RETIRE_SUCCESS
}

mapping clause assembly = GENTAG(rd)
  <-> "gentag" ^ spc() ^ reg_name(rd)
mapping clause assembly = ADDTAG(imm, rs1, rd)
  <-> "addtag" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm)
mapping clause assembly = SETTAG(imm, rs1)
  <-> "settag" ^ spc() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm)
mapping clause assembly = CHECKTAG(imm, rs1)
  <-> "checktag" ^ spc() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm)
