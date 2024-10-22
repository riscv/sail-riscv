/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the instructions in the 'Zicsr' extension.     */

/* ****************************************************************** */
union clause ast = CSR  : (csreg, regidx, regidx, bool, csrop)

mapping encdec_csrop : csrop <-> bits(2) = {
  CSRRW <-> 0b01,
  CSRRS <-> 0b10,
  CSRRC <-> 0b11
}

mapping clause encdec = CSR(csr, rs1, rd, is_imm, op)
  <-> csr @ rs1 @ bool_bits(is_imm) @ encdec_csrop(op) @ rd @ 0b1110011

// TODO: These read/write_CSR definitions should be moved to the files
// corresponding to their extensions rather than all be here.

/* machine mode */
function clause read_CSR(0xF11) = zero_extend(mvendorid)
function clause read_CSR(0xF12) = marchid
function clause read_CSR(0xF13) = mimpid
function clause read_CSR(0xF14) = mhartid
function clause read_CSR(0xF15) = mconfigptr
function clause read_CSR(0x300) = mstatus.bits[xlen - 1 .. 0]
function clause read_CSR(0x301) = misa.bits
function clause read_CSR(0x302) = medeleg.bits
function clause read_CSR(0x303) = mideleg.bits
function clause read_CSR(0x304) = mie.bits
function clause read_CSR(0x305) = get_mtvec()
function clause read_CSR(0x306) = zero_extend(mcounteren.bits)
function clause read_CSR(0x30A) = menvcfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x310 if xlen == 32) = mstatus.bits[63 .. 32]
function clause read_CSR(0x31A if xlen == 32) = menvcfg.bits[63 .. 32]
function clause read_CSR(0x320) = zero_extend(mcountinhibit.bits)

/* Hardware Performance Monitoring event selection */
function clause read_CSR(0b0011001 /* 0x320 */ @ index : bits(5) if unsigned(index) >= 3) = read_mhpmevent(hpmidx_from_bits(index))

function clause read_CSR(0x340) = mscratch
function clause read_CSR(0x341) = get_xret_target(Machine, V0) & pc_alignment_mask()
function clause read_CSR(0x342) = mcause.bits
function clause read_CSR(0x343) = mtval
function clause read_CSR(0x344) = mip.bits

// pmpcfgN
function clause read_CSR(0x3A @ idx : bits(4) if idx[0] == bitzero | xlen == 32) = pmpReadCfgReg(unsigned(idx))
// pmpaddrN. Unfortunately the PMP index does not nicely align with the CSR index bits.
function clause read_CSR(0x3B @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b00 @ idx))
function clause read_CSR(0x3C @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b01 @ idx))
function clause read_CSR(0x3D @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b10 @ idx))
function clause read_CSR(0x3E @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b11 @ idx))

/* machine mode counters */
function clause read_CSR(0xB00) = mcycle[(xlen - 1) .. 0]
function clause read_CSR(0xB02) = minstret[(xlen - 1) .. 0]
function clause read_CSR(0xB80 if xlen == 32)= mcycle[63 .. 32]
function clause read_CSR(0xB82 if xlen == 32) = minstret[63 .. 32]

/* Hardware Performance Monitoring machine mode counters */
function clause read_CSR(0b1011000 /* 0xB00 */ @ index : bits(5) if unsigned(index) >= 3) = read_mhpmcounter(hpmidx_from_bits(index))
function clause read_CSR(0b1011100 /* 0xB80 */ @ index : bits(5) if xlen == 32 & unsigned(index) >= 3) = read_mhpmcounterh(hpmidx_from_bits(index))

/* trigger/debug */
function clause read_CSR(0x7a0) = ~(tselect)  /* this indicates we don't have any trigger support */

/* supervisor mode */
function clause read_CSR(0x100) = (if cur_virtualization == V1 then vsstatus.bits else lower_mstatus(mstatus).bits)[(xlen - 1) .. 0]
function clause read_CSR(0x104) = if cur_virtualization == V1 then lower_mie_to_vsie(mie, hideleg).bits else lower_mie(mie, mideleg).bits
function clause read_CSR(0x105) = if cur_virtualization == V1 then get_vstvec() else get_stvec()
function clause read_CSR(0x106) = zero_extend(scounteren.bits)
function clause read_CSR(0x10A) = senvcfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x140) = if cur_virtualization == V1 then vsscratch else sscratch
function clause read_CSR(0x141) = get_xret_target(Supervisor, cur_virtualization) & pc_alignment_mask()
function clause read_CSR(0x142) = if cur_virtualization == V1 then vscause.bits else scause.bits
function clause read_CSR(0x143) = if cur_virtualization == V1 then vstval else stval
function clause read_CSR(0x144) = if cur_virtualization == V1 then lower_mip_to_vsip(mip, hideleg).bits else lower_mip(mip, mideleg).bits
function clause read_CSR(0x180) = if cur_virtualization == V1 then vsatp else satp

/* user mode counters */
function clause read_CSR(0xC00) = mcycle[(xlen - 1) .. 0]
function clause read_CSR(0xC01) = (if cur_virtualization == V0 then mtime else mtime + htimedelta)[(sizeof(xlen) - 1) .. 0]
function clause read_CSR(0xC02) = minstret[(xlen - 1) .. 0]
function clause read_CSR(0xC80 if xlen == 32) = mcycle[63 .. 32]
function clause read_CSR(0xC81 if xlen == 32) = (if cur_virtualization == V0 then mtime else mtime + htimedelta)[63 .. 32]
function clause read_CSR(0xC82 if xlen == 32) = minstret[63 .. 32]

/* Hardware Performance Monitoring user mode counters */
function clause read_CSR(0b1100000 /* 0xC00 */ @ index : bits(5) if unsigned(index) >= 3) = read_mhpmcounter(hpmidx_from_bits(index))
function clause read_CSR(0b1100100 /* 0xC80 */ @ index : bits(5) if xlen == 32 & unsigned(index) >= 3) = read_mhpmcounterh(hpmidx_from_bits(index))

/* user mode: Zkr */
function clause read_CSR(0x015) = read_seed_csr()

/* machine mode */
function clause write_CSR((0x300, value) if xlen == 32) = { mstatus = legalize_mstatus(mstatus, mstatus.bits[63 .. 32] @ value); mstatus.bits[31 .. 0] }
function clause write_CSR((0x300, value) if xlen == 64) = { mstatus = legalize_mstatus(mstatus, value); mstatus.bits }
function clause write_CSR(0x301, value) = { misa = legalize_misa(misa, value); misa.bits }
function clause write_CSR(0x302, value) = { medeleg = legalize_medeleg(medeleg, value); medeleg.bits }
function clause write_CSR(0x303, value) = { mideleg = legalize_mideleg(mideleg, value); mideleg.bits }
function clause write_CSR(0x304, value) = { mie = legalize_mie(mie, value); mie.bits }
function clause write_CSR(0x305, value) = { set_mtvec(value) }
function clause write_CSR(0x306, value) = { mcounteren = legalize_mcounteren(mcounteren, value); zero_extend(mcounteren.bits) }
function clause write_CSR((0x30A, value) if xlen == 32) = { menvcfg = legalize_menvcfg(menvcfg, menvcfg.bits[63 .. 32] @ value); menvcfg.bits[31 .. 0] }
function clause write_CSR((0x30A, value) if xlen == 64) = { menvcfg = legalize_menvcfg(menvcfg, value); menvcfg.bits }
function clause write_CSR((0x310, value) if xlen == 32) = { mstatus = legalize_mstatus(mstatus, value @ mstatus.bits[31 .. 0]); mstatus.bits[63 .. 32] }
function clause write_CSR((0x31A, value) if xlen == 32) = { menvcfg = legalize_menvcfg(menvcfg, value @ menvcfg.bits[31 .. 0]); menvcfg.bits[63 .. 32] }
function clause write_CSR(0x320, value) = { mcountinhibit = legalize_mcountinhibit(mcountinhibit, value); zero_extend(mcountinhibit.bits) }
function clause write_CSR(0x340, value) = { mscratch = value; mscratch }
function clause write_CSR(0x341, value) = { set_xret_target(Machine, V0, value) }
function clause write_CSR(0x342, value) = { mcause.bits = value; mcause.bits }
function clause write_CSR(0x343, value) = { mtval = value; mtval }
function clause write_CSR(0x344, value) = { mip = legalize_mip(mip, value); mip.bits }

// pmpcfgN
function clause write_CSR((0x3A @ idx : bits(4), value) if idx[0] == bitzero | xlen == 32) = {
  let idx = unsigned(idx);
  pmpWriteCfgReg(idx, value);
  pmpReadCfgReg(idx)
}

// pmpaddrN. Unfortunately the PMP index does not nicely align with the CSR index bits.
function clause write_CSR(0x3B @ idx : bits(4), value) = { let idx = unsigned(0b00 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }
function clause write_CSR(0x3C @ idx : bits(4), value) = { let idx = unsigned(0b01 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }
function clause write_CSR(0x3D @ idx : bits(4), value) = { let idx = unsigned(0b10 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }
function clause write_CSR(0x3E @ idx : bits(4), value) = { let idx = unsigned(0b11 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }

/* machine mode counters */
function clause write_CSR(0xB00, value) = { mcycle[(xlen - 1) .. 0] = value; value }
function clause write_CSR(0xB02, value) = { minstret[(xlen - 1) .. 0] = value; minstret_increment = false; value }
function clause write_CSR((0xB80, value) if xlen == 32) = { mcycle[63 .. 32] = value; value }
function clause write_CSR((0xB82, value) if xlen == 32) = { minstret[63 .. 32] = value; minstret_increment = false; value }

/* Hardware Performance Monitoring machine mode counters */
function clause write_CSR((0b0011001 /* 0x320 */ @ index : bits(5), value) if unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmevent(index, value);
  read_mhpmevent(index)
}
function clause write_CSR((0b1011000 /* 0xB00 */ @ index : bits(5), value) if unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmcounter(index, value);
  read_mhpmcounter(index)
}
function clause write_CSR((0b1011100 /* 0xB80 */ @ index : bits(5), value) if xlen == 32 & unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmcounterh(index, value);
  read_mhpmcounterh(index)
}

/* trigger/debug */
function clause write_CSR(0x7a0, value) = { tselect = value; tselect }

/* supervisor mode */
function clause write_CSR(0x100, value) = match cur_virtualization {
                                            V0 => { mstatus = legalize_sstatus(mstatus, value); mstatus.bits[(xlen - 1) .. 0] },
                                            V1 => { vsstatus = legalize_vsstatus(vsstatus, value); vsstatus.bits[(xlen - 1) .. 0] },
                                          }
function clause write_CSR(0x104, value) = match cur_virtualization {
                                            V0 => { mie = legalize_sie(mie, mideleg, value); mie.bits },
                                            V1 => { mie = legalize_vsie(mie, hideleg, value); mie.bits },
                                          }
function clause write_CSR(0x105, value) = match cur_virtualization {
                                            V0 => { set_stvec(value) },
                                            V1 => { set_vstvec(value) },
                                          }
function clause write_CSR(0x106, value) = { scounteren = legalize_scounteren(scounteren, value); zero_extend(scounteren.bits) }
function clause write_CSR(0x10A, value) = { senvcfg = legalize_senvcfg(senvcfg, zero_extend(value)); senvcfg.bits[xlen - 1 .. 0] }
function clause write_CSR(0x140, value) = match cur_virtualization {
                                            V0 => { sscratch = value; sscratch },
                                            V1 => { vsscratch = value; vsscratch },
                                          }
function clause write_CSR(0x141, value) = match cur_virtualization {
                                            V0 => { set_xret_target(Supervisor, V0, value) },
                                            V1 => { set_xret_target(Supervisor, V1, value) },
                                          }
function clause write_CSR(0x142, value) = match cur_virtualization {
                                            V0 => { scause.bits = value; scause.bits },
                                            V1 => { vscause.bits = value; vscause.bits },
                                          }
function clause write_CSR(0x143, value) = match cur_virtualization {
                                            V0 => { stval = value; stval },
                                            V1 => { vstval = value; vstval},
                                          }
function clause write_CSR(0x144, value) = match cur_virtualization {
                                            V0 => { mip = legalize_sip(mip, mideleg, value); mip.bits },
                                            V1 => { mip = legalize_vsip(mip, hideleg, value); mip.bits },
                                          }
function clause write_CSR(0x180, value) = match cur_virtualization {
                                            V0 => { satp = legalize_satp(cur_Architecture(), satp, value); satp },
                                            V1 => { vsatp = legalize_satp(cur_Architecture(), vsatp, value); vsatp },
                                          }

/* user mode: seed (entropy source). writes are ignored */
function clause write_CSR(0x015, value) = write_seed_csr()

function clause execute CSR(csr, rs1, rd, is_imm, op) = {
  let rs1_val : xlenbits = if is_imm then zero_extend(rs1) else X(rs1);
  let isWrite : bool = match op {
    CSRRW  => true,
    _      => if is_imm then unsigned(rs1_val) != 0 else unsigned(rs1) != 0
  };
  if not(check_CSR(csr, cur_privilege, cur_virtualization, isWrite))
  then {
    if extensionEnabled(Ext_H) & csr_access_raises_virtual_instr(csr, cur_privilege, cur_virtualization, isWrite)
    then handle_virtual_instr()
    else handle_illegal();
    RETIRE_FAIL
  }
  else if not(ext_check_CSR(csr, cur_privilege, isWrite))
  then { ext_check_CSR_fail(); RETIRE_FAIL }
  else {
    let csr_val = read_CSR(csr); /* could have side-effects, so technically shouldn't perform for CSRW[I] with rd == 0 */
    if isWrite then {
      let new_val : xlenbits = match op {
        CSRRW => rs1_val,
        CSRRS => csr_val | rs1_val,
        CSRRC => csr_val & ~(rs1_val)
      };
      let final_val = write_CSR(csr, new_val);
      if get_config_print_reg()
      then print_reg("CSR " ^ to_str(csr) ^ " <- " ^ bits_str(final_val) ^ " (input: " ^ bits_str(new_val) ^ ")")
    } else {
      if get_config_print_reg()
      then print_reg("CSR " ^ to_str(csr) ^ " -> " ^ bits_str(csr_val));
    };
    X(rd) = csr_val;
    RETIRE_SUCCESS
  }
}

mapping maybe_i : bool <-> string = {
  true  <-> "i",
  false <-> ""
}

mapping csr_mnemonic : csrop <-> string = {
  CSRRW <-> "csrrw",
  CSRRS <-> "csrrs",
  CSRRC <-> "csrrc"
}

mapping clause assembly = CSR(csr, rs1, rd, true, op)
  <-> csr_mnemonic(op) ^ "i" ^ spc() ^ reg_name(rd)  ^ sep() ^ csr_name_map(csr) ^ sep() ^ hex_bits_5(rs1)
mapping clause assembly = CSR(csr, rs1, rd, false, op)
  <-> csr_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ csr_name_map(csr) ^ sep() ^ reg_name(rs1)
