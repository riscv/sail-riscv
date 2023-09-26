/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the instructions in the 'Zicsr' extension.     */

/* ****************************************************************** */
union clause ast = CSR  : (bits(12), regidx, regidx, bool, csrop)

mapping encdec_csrop : csrop <-> bits(2) = {
  CSRRW <-> 0b01,
  CSRRS <-> 0b10,
  CSRRC <-> 0b11
}

mapping clause encdec = CSR(csr, rs1, rd, is_imm, op)
  <-> csr @ rs1 @ bool_bits(is_imm) @ encdec_csrop(op) @ rd @ 0b1110011

function readCSR csr : csreg -> xlenbits = {
  let res : xlenbits =
  match (csr, sizeof(xlen)) {
    /* machine mode */
    (0xF11,  _) => zero_extend(mvendorid),
    (0xF12,  _) => marchid,
    (0xF13,  _) => mimpid,
    (0xF14,  _) => mhartid,
    (0x300,  _) => mstatus.bits(),
    (0x301,  _) => misa.bits(),
    (0x302,  _) => medeleg.bits(),
    (0x303,  _) => mideleg.bits(),
    (0x304,  _) => mie.bits(),
    (0x305,  _) => get_mtvec(),
    (0x306,  _) => zero_extend(mcounteren.bits()),
    (0x30A,  _) => menvcfg.bits()[sizeof(xlen) - 1 .. 0],
    (0x310, 32) => mstatush.bits(),
    (0x31A, 32) => menvcfg.bits()[63 .. 32],
    (0x320,  _) => zero_extend(mcountinhibit.bits()),

    (0x340,  _) => mscratch,
    (0x341,  _) => get_xret_target(Machine) & pc_alignment_mask(),
    (0x342,  _) => mcause.bits(),
    (0x343,  _) => mtval,
    (0x344,  _) => mip.bits(),

    (0x3A0,  _) => pmpReadCfgReg(0),           // pmpcfg0
    (0x3A1, 32) => pmpReadCfgReg(1),           // pmpcfg1
    (0x3A2,  _) => pmpReadCfgReg(2),           // pmpcfg2
    (0x3A3, 32) => pmpReadCfgReg(3),           // pmpcfg3

    (0x3B0,  _) => pmpaddr0,
    (0x3B1,  _) => pmpaddr1,
    (0x3B2,  _) => pmpaddr2,
    (0x3B3,  _) => pmpaddr3,
    (0x3B4,  _) => pmpaddr4,
    (0x3B5,  _) => pmpaddr5,
    (0x3B6,  _) => pmpaddr6,
    (0x3B7,  _) => pmpaddr7,
    (0x3B8,  _) => pmpaddr8,
    (0x3B9,  _) => pmpaddr9,
    (0x3BA,  _) => pmpaddr10,
    (0x3BB,  _) => pmpaddr11,
    (0x3BC,  _) => pmpaddr12,
    (0x3BD,  _) => pmpaddr13,
    (0x3BE,  _) => pmpaddr14,
    (0x3BF,  _) => pmpaddr15,

    /* machine mode counters */
    (0xB00,  _) => mcycle[(sizeof(xlen) - 1) .. 0],
    (0xB02,  _) => minstret[(sizeof(xlen) - 1) .. 0],
    (0xB80, 32) => mcycle[63 .. 32],
    (0xB82, 32) => minstret[63 .. 32],
    (0x350,  _) => zero_extend(0b0),
    (0x351,  _) => zero_extend(0b0),
    (0x352,  _) => zero_extend(0b0),
    (0x353,  _) => zero_extend(0b0),
    (0x355,  _) => zero_extend(0b0),
    (0x356,  _) => zero_extend(0b0),
    (0x357,  _) => zero_extend(0b0),

    /* vector */
    (0x008, _) => zero_extend(vstart),
    (0x009, _) => zero_extend(vxsat),
    (0x00A, _) => zero_extend(vxrm),
    (0x00F, _) => zero_extend(vcsr.bits()),
    (0xC20, _) => vl,
    (0xC21, _) => vtype.bits(),
    (0xC22, _) => vlenb,

    /* trigger/debug */
    (0x7a0,  _) => ~(tselect),  /* this indicates we don't have any trigger support */

    /* supervisor mode */
    (0x100,  _) => lower_mstatus(mstatus).bits(),
    (0x102,  _) => sedeleg.bits(),
    (0x103,  _) => sideleg.bits(),
    (0x104,  _) => lower_mie(mie, mideleg).bits(),
    (0x105,  _) => get_stvec(),
    (0x106,  _) => zero_extend(scounteren.bits()),
    (0x10A,  _) => senvcfg.bits()[sizeof(xlen) - 1 .. 0],
    (0x140,  _) => sscratch,
    (0x141,  _) => get_xret_target(Supervisor) & pc_alignment_mask(),
    (0x142,  _) => scause.bits(),
    (0x143,  _) => stval,
    (0x144,  _) => lower_mip(mip, mideleg).bits(),
    (0x180,  _) => satp,

    (0x150,  _) => siselect.bits(),
    (0x151,  _) => zero_extend(0b0),
    (0x152,  _) => zero_extend(0b0),
    (0x153,  _) => zero_extend(0b0),
    (0x155,  _) => zero_extend(0b0),
    (0x156,  _) => zero_extend(0b0),
    (0x157,  _) => zero_extend(0b0),

    /* user mode counters */
    (0xC00,  _) => mcycle[(sizeof(xlen) - 1) .. 0],
    (0xC01,  _) => mtime[(sizeof(xlen) - 1) .. 0],
    (0xC02,  _) => minstret[(sizeof(xlen) - 1) .. 0],
    (0xC80, 32) => mcycle[63 .. 32],
    (0xC81, 32) => mtime[63 .. 32],
    (0xC82, 32) => minstret[63 .. 32],

    /* user mode: Zkr */
    (0x015,  _) => read_seed_csr(),

    _           => /* check extensions */
                   match ext_read_CSR(csr) {
                     Some(res) => res,
                     None()    => { print_bits("unhandled read to CSR ", csr);
                                    zero_extend(0x0) }
                   }
  };
  if   get_config_print_reg()
  then print_reg("CSR " ^ to_str(csr) ^ " -> " ^ BitStr(res));
  res
}

function writeCSR (csr : csreg, value : xlenbits) -> unit = {
  let res : option(xlenbits) =
  match (csr, sizeof(xlen)) {
    /* machine mode */
    (0x300,  _) => { mstatus = legalize_mstatus(mstatus, value); Some(mstatus.bits()) },
    (0x301,  _) => { misa = legalize_misa(misa, value); Some(misa.bits()) },
    (0x302,  _) => { medeleg = legalize_medeleg(medeleg, value); Some(medeleg.bits()) },
    (0x303,  _) => { mideleg = legalize_mideleg(mideleg, value); Some(mideleg.bits()) },
    (0x304,  _) => { mie = legalize_mie(mie, value); Some(mie.bits()) },
    (0x305,  _) => { Some(set_mtvec(value)) },
    (0x306,  _) => { mcounteren = legalize_mcounteren(mcounteren, value); Some(zero_extend(mcounteren.bits())) },
    (0x30A, 32) => { menvcfg = legalize_envcfg(menvcfg, menvcfg.bits()[63 .. 32] @ value); Some(menvcfg.bits()[31 .. 0]) },
    (0x30A, 64) => { menvcfg = legalize_envcfg(menvcfg, value); Some(menvcfg.bits()) },
    (0x310, 32) => { Some(mstatush.bits()) }, // ignore writes for now
    (0x31A, 32) => { menvcfg = legalize_envcfg(menvcfg, value @ menvcfg.bits()[31 .. 0]); Some(menvcfg.bits()[63 .. 32]) },
    (0x320,  _) => { mcountinhibit = legalize_mcountinhibit(mcountinhibit, value); Some(zero_extend(mcountinhibit.bits())) },
    (0x340,  _) => { mscratch = value; Some(mscratch) },
    (0x341,  _) => { Some(set_xret_target(Machine, value)) },
    (0x342,  _) => { mcause->bits() = value; Some(mcause.bits()) },
    (0x343,  _) => { mtval = value; Some(mtval) },
    (0x344,  _) => { mip = legalize_mip(mip, value); Some(mip.bits()) },

    // Note: Some(value) returned below is not the legalized value due to locked entries
    (0x3A0,  _) => { pmpWriteCfgReg(0, value); Some(pmpReadCfgReg(0)) },  // pmpcfg0
    (0x3A1, 32) => { pmpWriteCfgReg(1, value); Some(pmpReadCfgReg(1)) },  // pmpcfg1
    (0x3A2,  _) => { pmpWriteCfgReg(2, value); Some(pmpReadCfgReg(2)) },  // pmpcfg2
    (0x3A3, 32) => { pmpWriteCfgReg(3, value); Some(pmpReadCfgReg(3)) },  // pmpcfg3

    (0x3B0,  _) => { pmpaddr0  = pmpWriteAddr(pmpLocked(pmp0cfg),  pmpTORLocked(pmp1cfg),  pmpaddr0,  value); Some(pmpaddr0) },
    (0x3B1,  _) => { pmpaddr1  = pmpWriteAddr(pmpLocked(pmp1cfg),  pmpTORLocked(pmp2cfg),  pmpaddr1,  value); Some(pmpaddr1) },
    (0x3B2,  _) => { pmpaddr2  = pmpWriteAddr(pmpLocked(pmp2cfg),  pmpTORLocked(pmp3cfg),  pmpaddr2,  value); Some(pmpaddr2) },
    (0x3B3,  _) => { pmpaddr3  = pmpWriteAddr(pmpLocked(pmp3cfg),  pmpTORLocked(pmp4cfg),  pmpaddr3,  value); Some(pmpaddr3) },
    (0x3B4,  _) => { pmpaddr4  = pmpWriteAddr(pmpLocked(pmp4cfg),  pmpTORLocked(pmp5cfg),  pmpaddr4,  value); Some(pmpaddr4) },
    (0x3B5,  _) => { pmpaddr5  = pmpWriteAddr(pmpLocked(pmp5cfg),  pmpTORLocked(pmp6cfg),  pmpaddr5,  value); Some(pmpaddr5) },
    (0x3B6,  _) => { pmpaddr6  = pmpWriteAddr(pmpLocked(pmp6cfg),  pmpTORLocked(pmp7cfg),  pmpaddr6,  value); Some(pmpaddr6) },
    (0x3B7,  _) => { pmpaddr7  = pmpWriteAddr(pmpLocked(pmp7cfg),  pmpTORLocked(pmp8cfg),  pmpaddr7,  value); Some(pmpaddr7) },
    (0x3B8,  _) => { pmpaddr8  = pmpWriteAddr(pmpLocked(pmp8cfg),  pmpTORLocked(pmp9cfg),  pmpaddr8,  value); Some(pmpaddr8) },
    (0x3B9,  _) => { pmpaddr9  = pmpWriteAddr(pmpLocked(pmp9cfg),  pmpTORLocked(pmp10cfg), pmpaddr9,  value); Some(pmpaddr9) },
    (0x3BA,  _) => { pmpaddr10 = pmpWriteAddr(pmpLocked(pmp10cfg), pmpTORLocked(pmp11cfg), pmpaddr10, value); Some(pmpaddr10) },
    (0x3BB,  _) => { pmpaddr11 = pmpWriteAddr(pmpLocked(pmp11cfg), pmpTORLocked(pmp12cfg), pmpaddr11, value); Some(pmpaddr11) },
    (0x3BC,  _) => { pmpaddr12 = pmpWriteAddr(pmpLocked(pmp12cfg), pmpTORLocked(pmp13cfg), pmpaddr12, value); Some(pmpaddr12) },
    (0x3BD,  _) => { pmpaddr13 = pmpWriteAddr(pmpLocked(pmp13cfg), pmpTORLocked(pmp14cfg), pmpaddr13, value); Some(pmpaddr13) },
    (0x3BE,  _) => { pmpaddr14 = pmpWriteAddr(pmpLocked(pmp14cfg), pmpTORLocked(pmp15cfg), pmpaddr14, value); Some(pmpaddr14) },
    (0x3BF,  _) => { pmpaddr15 = pmpWriteAddr(pmpLocked(pmp15cfg), false,                  pmpaddr15, value); Some(pmpaddr15) },

    /* machine mode counters */
    (0xB00,  _) => { mcycle[(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB02,  _) => { minstret[(sizeof(xlen) - 1) .. 0] = value; minstret_increment = false; Some(value) },
    (0xB80, 32) => { mcycle[63 .. 32] = value; Some(value) },
    (0xB82, 32) => { minstret[63 .. 32] = value; minstret_increment = false; Some(value) },
    (0x350,  _) => { Some(value) },
    (0x351,  _) => { Some(value) },
    (0x352,  _) => { Some(value) },
    (0x353,  _) => { Some(value) },
    (0x355,  _) => { Some(value) },
    (0x356,  _) => { Some(value) },
    (0x357,  _) => { Some(value) },

    /* trigger/debug */
    (0x7a0,  _) => { tselect = value; Some(tselect) },

    /* supervisor mode */
    (0x100,  _) => { mstatus = legalize_sstatus(mstatus, value); Some(mstatus.bits()) },
    (0x102,  _) => { sedeleg = legalize_sedeleg(sedeleg, value); Some(sedeleg.bits()) },
    (0x103,  _) => { sideleg->bits() = value; Some(sideleg.bits()) }, /* TODO: does this need legalization? */
    (0x104,  _) => { mie = legalize_sie(mie, mideleg, value); Some(mie.bits()) },
    (0x105,  _) => { Some(set_stvec(value)) },
    (0x106,  _) => { scounteren = legalize_scounteren(scounteren, value); Some(zero_extend(scounteren.bits())) },
    (0x10A,  _) => { senvcfg = legalize_envcfg(senvcfg, zero_extend(value)); Some(senvcfg.bits()[sizeof(xlen) - 1 .. 0]) },
    (0x140,  _) => { sscratch = value; Some(sscratch) },
    (0x141,  _) => { Some(set_xret_target(Supervisor, value)) },
    (0x142,  _) => { scause->bits() = value; Some(scause.bits()) },
    (0x143,  _) => { stval = value; Some(stval) },
    (0x144,  _) => { mip = legalize_sip(mip, mideleg, value); Some(mip.bits()) },
    (0x180,  _) => { satp = legalize_satp(cur_Architecture(), satp, value); Some(satp) },

    (0x150,  _) => { siselect = legalize_siselect(siselect, value); Some(value) },
    (0x151,  _) => { Some(value) },
    (0x152,  _) => { Some(value) },
    (0x153,  _) => { Some(value) },
    (0x155,  _) => { Some(value) },
    (0x156,  _) => { Some(value) },
    (0x157,  _) => { Some(value) },

    /* user mode: seed (entropy source). writes are ignored */
    (0x015,  _) => write_seed_csr(),

    /* vector */
    (0x008, _) => { let vstart_length = get_vlen_pow(); vstart = zero_extend(16, value[(vstart_length - 1) .. 0]); Some(zero_extend(vstart)) },
    (0x009, _) => { vxsat = value[0 .. 0]; Some(zero_extend(vxsat)) },
    (0x00A, _) => { vxrm = value[1 .. 0]; Some(zero_extend(vxrm)) },
    (0x00F, _) => { vcsr->bits() = value[2 ..0]; Some(zero_extend(vcsr.bits())) },
    (0xC20, _) => { vl = value; Some(vl) },
    (0xC21, _) => { vtype->bits() = value; Some(vtype.bits()) },
    (0xC22, _) => { vlenb = value; Some(vlenb) },

    _           => ext_write_CSR(csr, value)
  };
  match res {
    Some(v) => if   get_config_print_reg()
               then print_reg("CSR " ^ to_str(csr) ^ " <- " ^ BitStr(v) ^ " (input: " ^ BitStr(value) ^ ")"),
    None()  => print_bits("unhandled write to CSR ", csr)
  }
}

function clause execute CSR(csr, rs1, rd, is_imm, op) = {
  let rs1_val : xlenbits = if is_imm then zero_extend(rs1) else X(rs1);
  let isWrite : bool = match op {
    CSRRW  => true,
    _      => if is_imm then unsigned(rs1_val) != 0 else unsigned(rs1) != 0
  };
  if not(check_CSR(csr, cur_privilege, isWrite))
  then { handle_illegal(); RETIRE_FAIL }
  else if not(ext_check_CSR(csr, cur_privilege, isWrite))
  then { ext_check_CSR_fail(); RETIRE_FAIL }
  else {
    let csr_val = readCSR(csr); /* could have side-effects, so technically shouldn't perform for CSRW[I] with rd == 0 */
    if isWrite then {
      let new_val : xlenbits = match op {
        CSRRW => rs1_val,
        CSRRS => csr_val | rs1_val,
        CSRRC => csr_val & ~(rs1_val)
      };
      writeCSR(csr, new_val)
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
