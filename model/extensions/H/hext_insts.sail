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

// HLV.*/HSV perform an explicit access with effective privilege VS (hstatus.SPVP=1)
// or VU (SPVP=0), so their effective address is subject to pointer masking via
// transform_hlsv_address. HLVX.* pass access = InstructionFetch() and are
// therefore exempt (HLVX emulates an implicit fetch). See hypervisor.adoc,
// "Hypervisor Virtual-Machine Load and Store Instructions".
function clause execute HLVTYPE(width, op, is_unsigned, rs1, rd) = {
  if inVirtualPrivilege()
  then return Virtual_Instruction()
  else if cur_privilege == User & hstatus[HU] == 0b0
  then return Illegal_Instruction()
  else {
    // A single access type is used for BOTH address translation and the physical read.
    // HLV is an ordinary load. HLVX uses LoadExecute, which models the spec's "execute
    // permission takes the place of read permission" while still behaving as a "load", it
    // honours vsstatus.SUM and raises load (not fetch) exceptions. The two-level
    // permission semantics (X-only in the page tables, but execute+read at the physical
    // level) are documented at the LoadExecute arms in model/sys/vmem_pte.sail (page-table
    // check) and model/sys/mem.sail + model/pmp/pmp_control.sail (physical check).
    let access : MemoryAccessType(mem_payload) = match op {
      HLV  => Load(Data),
      HLVX => LoadExecute(Data),
    };
    assert(width <= xlen_bytes);
    let eff_priv : Privilege = privLevel_bits(zero_extend(hstatus[SPVP]), 0b1);
    match ext_data_get_addr(rs1, zeros(), access, width) {
      Ext_DataAddr_Error(e)  => { Ext_DataAddr_Check_Failure(e) },
      Ext_DataAddr_OK(vaddr) => {
        let vaddr = transform_hlsv_address(vaddr, access, eff_priv);
        match plat_misaligned_exception(access, false) {
          Some(AccessFault)        => return Memory_Exception(exception_context(E_Load_Access_Fault(), bits_of(vaddr))),
          Some(AlignmentException) => return Memory_Exception(exception_context(E_Load_Addr_Align(), bits_of(vaddr))),
          None()                   => (),
        };
        match translateAddr_eff_priv(vaddr, access, eff_priv) {
          // No fetch->load exception conversion is needed: LoadExecute already raises load
          // (not fetch) exceptions on translation failure (see model/sys/vmem_ptw.sail),
          // matching the spec's "[HLVX] still raise the same exceptions as other load
          // instructions, rather than raising fetch exceptions instead."
          Err(e, _) => Memory_Exception(e),
          Ok(paddr, pbmt,_) => match mem_read(access, pbmt, paddr, width, false, false, false) {
            Ok(result) => { X(rd) = extend_value(is_unsigned, result); RETIRE_SUCCESS },
            Err(e) => Memory_Exception(exception_context(e, bits_of(vaddr))),
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

// HSV performs an explicit VS/VU access and is always subject to pointer masking
// (see the HLV note above for the PMM-source rules).
function clause execute(HSV(width, rs1, rs2)) = {
  if inVirtualPrivilege()
  then Virtual_Instruction()
  else if cur_privilege == User & hstatus[HU] == 0b0
  then Illegal_Instruction()
  else {
    assert(width <= xlen_bytes);
    let eff_priv : Privilege = privLevel_bits(zero_extend(hstatus[SPVP]), 0b1);
    match ext_data_get_addr(rs1, zeros(), Store(Data), width) {
      Ext_DataAddr_Error(e)  => Ext_DataAddr_Check_Failure(e),
      Ext_DataAddr_OK(vaddr) => {
        let vaddr = transform_hlsv_address(vaddr, Store(Data), eff_priv);
        match plat_misaligned_exception(Store(Data), false) {
          Some(AccessFault)        => return Memory_Exception(exception_context(E_SAMO_Access_Fault(), bits_of(vaddr))),
          Some(AlignmentException) => return Memory_Exception(exception_context(E_SAMO_Addr_Align(), bits_of(vaddr))),
          None()                   => (),
        };
        match translateAddr_eff_priv(vaddr, Store(Data), eff_priv) {
          Err(e, _) => Memory_Exception(e),
          Ok(paddr, pbmt, _) => {
            match mem_write_ea(paddr, width, false, false, false) {
              Err(e) => Memory_Exception(exception_context(e, bits_of(vaddr))),
              Ok(_) => {
                match mem_write_value(paddr, width, X(rs2)[8 * width - 1 .. 0], Store(Data), pbmt, false, false, false) {
                  Ok(true)  => RETIRE_SUCCESS,
                  Ok(false) => internal_error(__FILE__, __LINE__, "HSV got false from mem_write_value"),
                  Err(e) => { Memory_Exception(exception_context(e, bits_of(vaddr))) }
                }
              }
            }
          },
        }
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
  let vmid = Some(get_vmid(VS_Stage));
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
  // physical address
  // TODO: There is currently a bug in certain cases. If the address in rs1
  // happens to use bits 30 or 31, those bits are lost when shifting left by
  // two due to the limited width of "addr". We need to ensure that we either
  // support a 34-bit address here, or pass the 32-bit value unchanged and
  // apply the shift within the TLB instead.
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
