// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function make_shadow_stack_exception() -> sync_exception =
  struct { trap    = E_Software_Check(),
           excinfo = Some(zero_extend(software_check_cause(SWC_SHADOW_STACK_FAULT))),
           ext     = None() }

// *****************************************************************

union clause instruction = SSPUSH : regidx

$[wavedrom "SSPUSH _ rs1 funct3 rd SYSTEM"]
mapping clause encdec = SSPUSH(rs2)
  <-> 0b1100111 @ encdec_reg(rs2) @ 0b00000 @ 0b100 @ 0b00000 @ 0b1110011
  when (rs2 == ra | rs2 == t0) & currentlyEnabled(Ext_Zicfiss) & zicfiss_xSSE(cur_privilege)

function clause execute SSPUSH(rs2) = {
  // This is redundant with the decoding predicate, but is here to
  // match the pseudo-code in the specification.
  if not(zicfiss_xSSE(cur_privilege)) then return RETIRE_SUCCESS;

  let vaddr_bits = ssp - xlen_bytes;
  let vaddr = Virtaddr(vaddr_bits);
  // "If the virtual address in ssp is not XLEN aligned, then the
  // SSPUSH/C.SSPUSH/SSPOPCHK/C.SSPOPCHK instructions cause a
  // store/AMO access-fault exception."
  //
  // `vmem_write_addr` throws a SAMO_Addr_Align exception,
  // so handle alignment checking here.

  // If xlen is changed dynamically, `ssp` could be misaligned.
  // TODO: get the dynamic xlen here.
  let width = xlen_bytes;
  if not(is_aligned_addr(vaddr, width))
  then return Memory_Exception(vaddr, E_SAMO_Access_Fault());

  match vmem_write_addr(vaddr, width, X(rs2), Store(ShadowStack), false, false, false) {
    Ok(_)  => { ssp = vaddr_bits; RETIRE_SUCCESS },
    Err(e) => e,
  }
}

mapping clause assembly = SSPUSH(rs2)
  <-> "sspush" ^ spc() ^ reg_name(rs2)

// *****************************************************************

union clause instruction = C_SSPUSH : unit

$[wavedrom "C.SSPUSH _ _ n[3:1] _ _ C1"]
mapping clause encdec_compressed = C_SSPUSH()
  <-> 0b011 @ 0b0 @ 0b0 @ 0b000 @ 0b1 @ 0b00000 @ 0b01
  when currentlyEnabled(Ext_Zicfiss) & currentlyEnabled(Ext_Zcmop) & zicfiss_xSSE(cur_privilege)

function clause execute C_SSPUSH() =
  ExecuteAs(SSPUSH(ra))

mapping clause assembly = C_SSPUSH()
  <-> "c.sspush" ^ spc() ^ reg_name(encdec_reg(0b00001))

// *****************************************************************

union clause instruction = SSPOPCHK : regidx

$[wavedrom "SSPOPCHK rs1 funct3 rd SYSTEM"]
mapping clause encdec = SSPOPCHK(rs1)
  <-> 0b110011011100  @ encdec_reg(rs1) @ 0b100 @ 0b00000 @ 0b1110011
  when (rs1 == ra | rs1 == t0) & currentlyEnabled(Ext_Zicfiss) & zicfiss_xSSE(cur_privilege)

function clause execute SSPOPCHK(rs1) = {
  // This is redundant with the decoding predicate, but is here to
  // match the pseudo-code in the specification.
  if not(zicfiss_xSSE(cur_privilege)) then return RETIRE_SUCCESS;

  let ssp_addr = Virtaddr(ssp);
  // See above on checking alignment.
  // TODO: get the dynamic xlen here.
  let width = xlen_bytes;
  if not(is_aligned_addr(ssp_addr, width))
  then return Memory_Exception(ssp_addr, E_SAMO_Access_Fault());

  match vmem_read_addr(ssp_addr, zeros(), width, Load(ShadowStack), false, false, false) {
    Ok(data) => {
      if X(rs1) != data then {
        Trap(cur_privilege, CTL_TRAP(make_shadow_stack_exception()), PC)
      } else {
        ssp = ssp + width;
        RETIRE_SUCCESS
      }
    },
    Err(e) => e,
  };
}

mapping clause assembly = SSPOPCHK(rs1)
  <-> "sspopchk" ^ spc() ^ reg_name(rs1)

// *****************************************************************

union clause instruction = C_SSPOPCHK : unit

$[wavedrom "C.SSPOPCHK _ _ n[3:1] _ _ C1"]
mapping clause encdec_compressed = C_SSPOPCHK()
  <-> 0b011 @ 0b0 @ 0b0 @ 0b010 @ 0b1 @ 0b00000 @ 0b01
  when currentlyEnabled(Ext_Zicfiss) & currentlyEnabled(Ext_Zcmop) & zicfiss_xSSE(cur_privilege)

function clause execute C_SSPOPCHK() =
  ExecuteAs(SSPOPCHK(t0))

mapping clause assembly = C_SSPOPCHK()
  <-> "c.sspopchk" ^ spc() ^ reg_name(encdec_reg(0b00101))

// *****************************************************************
union clause instruction = SSRDP : regidx

$[wavedrom "SSRDP _ funct3 dst SYSTEM"]
mapping clause encdec = SSRDP(rd)
  <-> 0b110011011100 @ 0b00000 @ 0b100 @ encdec_reg(rd) @ 0b1110011
  when currentlyEnabled(Ext_Zicfiss) & zicfiss_xSSE(cur_privilege)

function clause execute SSRDP(rd) = {
  if zicfiss_xSSE(cur_privilege)
  then X(rd) = ssp
  else X(rd) = zeros();

  RETIRE_SUCCESS
}

mapping clause assembly = SSRDP(rd)
  <-> "ssrdp" ^ spc() ^ reg_name(rd)

// *****************************************************************

union clause instruction = SSAMOSWAP : (bool, bool, regidx, regidx, word_width, regidx)

// This instruction decoding is not in the Zimop encoding space
// and is not predicated by xSSE.
$[wavedrom "SSAMOSWAP _ _ src addr funct3 dest AMO"]
mapping clause encdec = SSAMOSWAP(aq, rl, rs2, rs1, width, rd)
  <-> 0b01001 @ bool_bit(aq) @ bool_bit(rl) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ encdec_reg(rd) @ 0b0101111
  when (width == 4 | (xlen == 64 & width == 8)) & currentlyEnabled(Ext_Zicfiss)

function clause execute SSAMOSWAP(aq, rl, rs2, rs1, width, rd) = {
  // This instruction is not predicated by `xSSE`.
  match cur_privilege {
    Machine           => if not(currentlyEnabled(Ext_S))
                         then return Illegal_Instruction(),
    Supervisor        => { if not(bool_bit(menvcfg[SSE]))
                           then return Illegal_Instruction() },
    User              => if not(currentlyEnabled(Ext_S)) | not(bool_bit(read_senvcfg()[SSE]))
                         then return Illegal_Instruction(),
    VirtualSupervisor => { if not(bool_bit(menvcfg[SSE]))
                           then return Illegal_Instruction();
                           // TODO:
                           // else if not(bool_bit(read_henvcfg()[SSE]))
                           // then return Virtual_Instruction();
                           internal_error(__FILE__, __LINE__, "Hypervisor extension not supported") },
    VirtualUser       => { if not(bool_bit(menvcfg[SSE]))
                           then return Illegal_Instruction()
                           else if not(bool_bit(read_senvcfg()[SSE]))
                           then return Virtual_Instruction() },
  };

  let access = Atomic(AMOSWAP, ShadowStack, ShadowStack);

  let vaddr : virtaddr = match ext_data_get_addr(rs1, zeros(), access, width) {
    Ext_DataAddr_Error(e)  => return Ext_DataAddr_Check_Failure(e),
    Ext_DataAddr_OK(vaddr) => vaddr,
  };

  // "The same exception options [as AMOs in the A extension] apply if
  // the address is not naturally aligned."
  if not(is_aligned_addr(vaddr, width))
  then return Memory_Exception(vaddr, E_SAMO_Addr_Align());

  let paddr : physaddr = match translateAddr(vaddr, access) {
    Ok(addr, _) => addr,
    Err(e, _)   => return Memory_Exception(vaddr, e),
  };

  // The `aq` and `rl` flags follow the AMO model in Zaamo: "Just as
  // for AMOs in the A extension, SSAMOSWAP.W/D optionally provides
  // release consistency semantics, using the aq and rl bits, to help
  // implement multiprocessor synchronization."

  let 'width = width;
  let mem_val : bits('width * 8) = match mem_write_ea(paddr, width, aq & rl, rl, true) {
    Err(e) => return Memory_Exception(vaddr, e),
    Ok(_)  => match mem_read(access, paddr, width, aq, aq & rl, true) {
      Err(e) => return Memory_Exception(vaddr, e),
      Ok(v)  => v,
    },
  };

  // This constraint is ensured by the instruction decode clause.
  assert('width == 4 | (xlen == 64 & width == 8));
  let write_val : bits('width * 8) = X(rs2)['width * 8 - 1 .. 0];
  match mem_write_value(paddr, width, write_val, aq & rl, rl, true) {
    Ok(true)  => X(rd) = sign_extend(mem_val),
    Ok(false) => internal_error(__FILE__, __LINE__, "AMOSWAP_SS got false from mem_write_value"),
    Err(e)    => return Memory_Exception(vaddr, e),
  };

  RETIRE_SUCCESS
}

mapping clause assembly = SSAMOSWAP(aq, rl, rs2, rs1, width, rd)
  <-> "ssamoswap." ^ width_mnemonic(width) ^ maybe_aqrl(aq, rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"
  when width == 4 | width == 8
