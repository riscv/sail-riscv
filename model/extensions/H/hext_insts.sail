// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

mapping maybe_hlvx : hlvop <-> string = {
  HLV  <-> "",
  HLVX <-> "x",
}

union clause instruction = HLVTYPE : (word_width, hlvop, bool, regidx, regidx)

mapping clause encdec = HLVTYPE(width, HLV, is_unsigned, rs1, rd)
  <-> 0b0110 @ width_enc(width) @ 0b00000 @ bool_bit(is_unsigned) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_H) & valid_load_encdec(width, is_unsigned)

mapping clause encdec = HLVTYPE(width, HLVX, true, rs1, rd)
  <-> 0b0110 @ width_enc(width) @ 0b000011 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_H) & (width == 2 | width == 4)

function clause execute HLVTYPE(width, op, is_unsigned, rs1, rd) = {
  if inVirtualPrivilege()
  then return Virtual_Instruction()
  else if cur_privilege == User & hstatus[HU] == 0b0
  then return Illegal_Instruction();

  // A single access type is used for BOTH address translation and the physical read.
  // HLV is an ordinary load. HLVX uses LoadExecute, which models the spec's "execute
  // permission takes the place of read permission" while still behaving as a "load", it
  // honours vsstatus.SUM and raises load (not fetch) exceptions. The two-level
  // permission semantics (X-only in the page tables, but execute+read at the physical
  // level) are documented at the LoadExecute arms in model/sys/vmem_pte.sail
  // and model/sys/mem.sail + model/pmp/pmp_control.sail.
  let access : MemoryAccessType(mem_payload) = match op {
    HLV  => Load(Data),
    HLVX => LoadExecute(Data),
  };
  assert(width <= xlen_bytes);

  // HLV.*/HSV perform an explicit access with effective privilege VS
  // (`hstatus.SPVP=1`) or VU (`SPVP=0`).  HLVX.* are exempt (HLVX
  // emulates an implicit fetch, and the PMM fields only cover
  // HLV.*/HSV.*): `is_pmm_applicable` excludes their `LoadExecute`
  // access type.
  let eff_priv : Privilege = privLevel_bits(zero_extend(hstatus[SPVP]), 0b1);
  let access_info : AccessInfo = struct {
    eff_privilege = eff_priv,
    pmlen = get_hlsv_pmlen(access, eff_priv),
    as_guest = true,
  };

  match vmem_read_explicit(rs1, zeros(), width, access, access_info, false, false, false) {
    Ok(data) => {
      X(rd) = extend_value(is_unsigned, data);
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping clause assembly = HLVTYPE(width, op, is_unsigned, rs1, rd)
  <-> "hlv" ^ maybe_hlvx(op) ^ "." ^ width_mnemonic(width) ^ maybe_u(is_unsigned)  ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

union clause instruction = HSV : (word_width, regidx, regidx)

mapping clause encdec = HSV(width, rs1, rs2)
  <-> 0b0110 @ width_enc(width) @ 0b1 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H) & width <= xlen_bytes

function clause execute(HSV(width, rs1, rs2)) = {
  if inVirtualPrivilege()
  then return Virtual_Instruction()
  else if cur_privilege == User & hstatus[HU] == 0b0
  then return Illegal_Instruction();

  assert(width <= xlen_bytes);

  // HSV performs an explicit VS/VU access and is always subject to pointer masking
  // (see the HLV note above for the PMM-source rules).
  let eff_priv : Privilege = privLevel_bits(zero_extend(hstatus[SPVP]), 0b1);
  let access = Store(Data);
  let access_info : AccessInfo = struct {
    eff_privilege = eff_priv,
    pmlen = get_hlsv_pmlen(access, eff_priv),
    as_guest = true,
  };

  let data = X(rs2)[8 * width - 1 .. 0];
  match vmem_write_explicit(rs1, zeros(), width, data, access, access_info, false, false, false) {
    Ok(true)  => RETIRE_SUCCESS,
    Ok(false) => internal_error(__FILE__, __LINE__, "HSV got false from vmem_write_explicit"),
    Err(e)    => e,
  }
}

mapping clause assembly = HSV(width, rs1, rs2)
  <-> "hsv."  ^ width_mnemonic(width) ^ spc() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

union clause instruction = HFENCE_VVMA : (regidx, regidx)

mapping clause encdec = HFENCE_VVMA(rs1, rs2)
  <-> 0b0010001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute HFENCE_VVMA(rs1, rs2) = {
  if inVirtualPrivilege()
  then return Virtual_Instruction()
  else if cur_privilege == User
  then return Illegal_Instruction();

  let addr = if rs1 != zreg then Some(X(rs1)) else None();
  let asid : option(asidbits) = if rs2 != zreg then Some(if asidlen == 0 then zeros() else zero_extend(X(rs2)[asidlen - 1 .. 0])) else None();
  let vmid = Some(get_vmid(VS_Stage));

  flush_TLB(asid, vmid, addr, VS_Stage);
  RETIRE_SUCCESS
}

mapping clause assembly = HFENCE_VVMA(rs1, rs2)
  <-> "hfence.vvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

union clause instruction = HFENCE_GVMA : (regidx, regidx)

mapping clause encdec = HFENCE_GVMA(rs1, rs2)
  <-> 0b0110001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute HFENCE_GVMA(rs1, rs2) = {
  if inVirtualPrivilege()
  then return Virtual_Instruction()
  else if cur_privilege == User
  then return Illegal_Instruction()
  else if cur_privilege == Supervisor & mstatus[TVM] == 0b1
  then return Illegal_Instruction();

  // Software provides the guest physical address in rs1 right-shifted by 2 bits,
  // following the htval/tval2 convention for G-stage traps. Pass it unshifted.
  // flush_TLB_Entry recovers the full GPA in a wide type, which can exceed XLEN on RV32.
  let addr = if rs1 != zreg then Some(X(rs1)) else None();
  let vmid : option(vmidbits) = if rs2 != zreg then Some(if vmidlen == 0 then zeros() else zero_extend(X(rs2)[vmidlen - 1 .. 0])) else None();
  let asid : option(asidbits) = None();

  flush_TLB(asid, vmid, addr, G_Stage);
  RETIRE_SUCCESS
}

mapping clause assembly = HFENCE_GVMA(rs1, rs2)
  <-> "hfence.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
