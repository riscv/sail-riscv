// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// TODO: HLV(X)/HSV do not properly forward traps using the additional state
// defined in the Execution_Context struct. A follow-up PR will implement proper
// trap handling.

mapping maybe_hlvx : hlvop <-> string = {
  HLV  <-> "",
  HLVX <-> "x",
}

function translationExceptionFetch(e : ExceptionType) -> ExceptionType = {
  match e {
    E_Fetch_Access_Fault() => E_Load_Access_Fault(),
    E_Fetch_Page_Fault()   => E_Load_Page_Fault(),
    E_Fetch_GPage_Fault()  => E_Load_GPage_Fault(),
    _                      => e,
  }
}

union clause instruction = HLVTYPE : (word_width, hlvop, bool, regidx, regidx)

mapping clause encdec = HLVTYPE(width, HLV, is_unsigned, rs1, rd)
  <-> 0b0110 @ width_enc(width) @ 0b00000 @ bool_bit(is_unsigned) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_H) & valid_load_encdec(width, is_unsigned)

mapping clause encdec = HLVTYPE(width, HLVX, true, rs1, rd)
  <-> 0b0110 @ width_enc(width) @ 0b000011 @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_H) & (width == 1 | width == 2)

// TODO/NOTE: We should likely perform fine-grained, byte-wise memory accesses.
function clause execute HLVTYPE(width, op, is_unsigned, rs1, rd) = {
  if inVirtualPrivilege()
  then return Virtual_Instruction()
  else if cur_privilege == User & hstatus[HU] == 0b0
  then return Illegal_Instruction()
  else {
    let (access, physical_access) : (MemoryAccessType(mem_payload), MemoryAccessType(mem_payload)) = match op {
      HLV  => (Load(Data), Load(Data)),
      HLVX => (InstructionFetch(), ExecuteLoad()),
    };
    assert(width <= xlen_bytes);
    match ext_data_get_addr(rs1, zeros(), access, width) {
      Ext_DataAddr_Error(e)  => { Ext_DataAddr_Check_Failure(e) },
      Ext_DataAddr_OK(vaddr) => {
        if check_misaligned(vaddr, width)
        then { return Memory_Exception(vaddr, E_Load_Addr_Align()) }
        else match translateAddr_eff_priv(vaddr, access, privLevel_bits(zero_extend(hstatus[SPVP]), 0b1)) {
          // TODO/NOTE: The original code returned RETIRE_SUCCESS even when address translation failed.
          // https://github.com/trdthg/sail-riscv/blob/91189354d003966b876d6842b4354ed51daa349e/model/extensions/H/hext_insts.sail#L35
          Err(e_cont, _) => Memory_Exception(vaddr, match op {
              HLV  => e_cont.trap,
              HLVX => translationExceptionFetch(e_cont.trap),
          }),
          Ok(paddr, _) => match mem_read(physical_access, paddr, width, false, false, false) {
            Ok(result) => { X(rd) = extend_value(is_unsigned, result); RETIRE_SUCCESS },
            Err(e) => Memory_Exception(vaddr, e),
          },
        };
      }
    }
  }
}

mapping clause assembly = HLVTYPE(width, op, is_unsigned, rs1, rd)
  <-> "hlv" ^ maybe_hlvx(op) ^ "." ^ width_mnemonic(width) ^ maybe_u(is_unsigned)  ^ spc() ^ reg_name(rd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

union clause instruction = HSV : (word_width, regidx, regidx)

mapping clause encdec = HSV(width, rs1, rs2)
  <-> 0b0110 @ width_enc(width) @ 0b1 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H) & width <= xlen_bytes

// TODO/NOTE: We should likely perform fine-grained, byte-wise memory accesses.
function clause execute(HSV(width, rs1, rs2)) = {
  if inVirtualPrivilege()
  then Virtual_Instruction()
  else if cur_privilege == User & hstatus[HU] == 0b0
  then Illegal_Instruction()
  else {
    assert(width <= xlen_bytes);
    match ext_data_get_addr(rs1, zeros(), Store(Data), width) {
      Ext_DataAddr_Error(e)  => Ext_DataAddr_Check_Failure(e),
      Ext_DataAddr_OK(vaddr) =>
        if check_misaligned(vaddr, width)
        then Memory_Exception(vaddr, E_SAMO_Addr_Align())
        else match translateAddr_eff_priv(vaddr, Store(Data), privLevel_bits(zero_extend(hstatus[SPVP]), 0b1)) {
          // TODO/NOTE: The original code returned RETIRE_SUCCESS even when address translation failed.
          // https://github.com/trdthg/sail-riscv/blob/91189354d003966b876d6842b4354ed51daa349e/model/extensions/H/hext_insts.sail#L35
          Err(e_cont, _) => Memory_Exception(vaddr, e_cont.trap),
          Ok(paddr, _) => {
            match mem_write_ea(paddr, width, false, false, false) {
              Err(e) => Memory_Exception(vaddr, e),
              Ok(_) => {
                match mem_write_value(paddr, width, X(rs2)[8 * width - 1 .. 0], false, false, false) {
                  Ok(true)  => RETIRE_SUCCESS,
                  Ok(false) => internal_error(__FILE__, __LINE__, "HSV got false from mem_write_value"),
                  Err(e) => { Memory_Exception(vaddr, e) }
                }
              }
            }
          },
        }
    }
  }
}

mapping clause assembly = HSV(width, rs1, rs2)
  <-> "hsv."  ^ width_mnemonic(width) ^ spc() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

union clause instruction = HFENCE_VVMA : (regidx, regidx)

mapping clause encdec = HFENCE_VVMA(rs1, rs2)
  <-> 0b0010001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute HFENCE_VVMA(rs1, rs2) = {
  let addr = if rs1 != zreg then Some(X(rs1)) else None();
  let asid = if rs2 != zreg then Some(X(rs2)[asidlen - 1 .. 0]) else None();
  let vmid = Some(get_vmid());
  match cur_privilege {
    VirtualUser       => { Virtual_Instruction() },
    User              => { Illegal_Instruction() },
    VirtualSupervisor => { Virtual_Instruction() },
    Supervisor        => { flush_TLB(asid, vmid, addr, VS_Stage); RETIRE_SUCCESS },
    Machine           => { flush_TLB(asid, vmid, addr, VS_Stage); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_VVMA(rs1, rs2)
  <-> "hfence.vvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

union clause instruction = HFENCE_GVMA : (regidx, regidx)

mapping clause encdec = HFENCE_GVMA(rs1, rs2)
  <-> 0b0110001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when currentlyEnabled(Ext_H)

function clause execute HFENCE_GVMA(rs1, rs2) = {
  // Software provides the guest physical address in rs1 right-shifted by 2 bits,
  // following the htval/tval2 convention for G-stage traps (faulting GPA is
  // reported as gpa >> 2 to accommodate addresses wider than XLEN). Since the
  // TLB stores unshifted addresses, shift left by 2 to recover the actual guest
  // physical address (TODO: Needs to be tested and double checked).
  let addr = if rs1 != zreg then Some(X(rs1) << 2) else None();
  let vmid = if rs2 != zreg then Some(X(rs2)[vmidlen - 1 .. 0]) else None();
  let asid : option(asidbits) = None();
  match cur_privilege {
    VirtualUser       => { Virtual_Instruction() },
    User              => { Illegal_Instruction() },
    VirtualSupervisor => { Virtual_Instruction() },
    Supervisor        => match mstatus[TVM] {
                            0b1 => { Illegal_Instruction() },
                            0b0 => { flush_TLB(asid, vmid, addr, G_Stage); RETIRE_SUCCESS }
                        },
    Machine           => { flush_TLB(asid, vmid, addr, G_Stage); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_GVMA(rs1, rs2)
  <-> "hfence.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
