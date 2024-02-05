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
    (0x300,  _) => mstatus.bits,
    (0x301,  _) => misa.bits,
    (0x302,  _) => medeleg.bits,
    (0x303,  _) => mideleg.bits,
    (0x304,  _) => mie.bits,
    (0x305,  _) => get_mtvec(),
    (0x306,  _) => zero_extend(mcounteren.bits),
    (0x30A,  _) => menvcfg.bits[sizeof(xlen) - 1 .. 0],
    (0x310, 32) => mstatush.bits,
    (0x31A, 32) => menvcfg.bits[63 .. 32],
    (0x320,  _) => zero_extend(mcountinhibit.bits),

    (0x340,  _) => mscratch,
    (0x341,  _) => get_xret_target(Machine, V0) & pc_alignment_mask(),
    (0x342,  _) => mcause.bits,
    (0x343,  _) => mtval,
    (0x344,  _) => mip.bits,
    (0x34A,  _) => mtinst,
    (0x34B,  _) => mtval2,

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

    /* vector */
    (0x008, _) => zero_extend(vstart),
    (0x009, _) => zero_extend(vxsat),
    (0x00A, _) => zero_extend(vxrm),
    (0x00F, _) => zero_extend(vcsr.bits),
    (0xC20, _) => vl,
    (0xC21, _) => vtype.bits,
    (0xC22, _) => vlenb,

    /* trigger/debug */
    (0x7a0,  _) => ~(tselect),  /* this indicates we don't have any trigger support */

    /* hypervisor extended supervisor mode */
    (0x600,  _) => hstatus.bits,
    (0x602,  _) => hedeleg.bits,
    (0x603,  _) => hideleg.bits,
    (0x604,  _) => lower_mie_to_hie(mie).bits,
    (0x606,  _) => zero_extend(hcounteren.bits),
    (0x607,  _) => hgeie,
    (0x643,  _) => htval,
    (0x644,  _) => lower_mip_to_hip(mip).bits,
    (0x645,  _) => lower_mip_to_hvip(mip).bits,
    (0x64A,  _) => htinst,
    (0xE12,  _) => hgeip, // hgeip is read-only
    (0x60A,  _) => henvcfg.bits[sizeof(xlen) - 1 .. 0],
    (0x61A, 32) => henvcfg.bits[63 .. 32],
    (0x680,  _) => hgatp,
    // (0x6A8,  _) => hcontext,                       // TODO: henvcfg read handle
    (0x605,  _) => htimedelta[sizeof(xlen) - 1 .. 0],
    (0x615, 32) => htimedelta[63 .. 32],

    /* supervisor mode */
    (0x100,  _) => if cur_virtualization == V1 then vsstatus.bits else lower_mstatus(mstatus).bits,
    (0x102,  _) => sedeleg.bits,
    (0x103,  _) => sideleg.bits,
    (0x104,  _) =>  if cur_virtualization == V1 then lower_mie_to_vsie(mie, hideleg).bits else lower_mie(mie, mideleg).bits,
    (0x105,  _) => get_trap_vector(Supervisor, cur_virtualization),
    (0x106,  _) => zero_extend(scounteren.bits),
    (0x10A,  _) => senvcfg.bits[sizeof(xlen) - 1 .. 0],
    (0x140,  _) => if cur_virtualization == V1 then vsscratch else sscratch,
    (0x141,  _) => get_xret_target(Supervisor, cur_virtualization) & pc_alignment_mask(),
    (0x142,  _) => if cur_virtualization == V1 then vscause.bits else scause.bits,
    (0x143,  _) => if cur_virtualization == V1 then vstval else stval,
    (0x144,  _) => if cur_virtualization == V1 then lower_mip_to_vsip(mip, hideleg).bits else lower_mip_to_sip(mip, mideleg).bits,
    (0x180,  _) => if cur_virtualization == V1 then vsatp else satp,

    /* virtual supervisor mode */
    (0x200,  _) => vsstatus.bits,
    (0x204,  _) => lower_mie_to_vsie(mie, hideleg).bits,
    (0x205,  _) => get_trap_vector(Supervisor, V1),
    (0x240,  _) => vsscratch,
    (0x241,  _) => get_xret_target(Supervisor, V1),
    (0x242,  _) => vscause.bits,
    (0x243,  _) => vstval,
    (0x244,  _) => lower_mip_to_vsip(mip, hideleg).bits,
    (0x280,  _) => vsatp,

    /* user mode counters */
    (0xC00,  _) => mcycle[(sizeof(xlen) - 1) .. 0],
    (0xC01,  _) => (if cur_virtualization == V0 then mtime else mtime + htimedelta)[(sizeof(xlen) - 1) .. 0],
    (0xC02,  _) => minstret[(sizeof(xlen) - 1) .. 0],
    (0xC80, 32) => mcycle[63 .. 32],
    (0xC81, 32) => (if cur_virtualization == V0 then mtime else mtime + htimedelta)[63 .. 32],
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
    (0x300,  _) => { mstatus = legalize_mstatus(mstatus, value); Some(mstatus.bits) },
    (0x301,  _) => { misa = legalize_misa(misa, value); Some(misa.bits) },
    (0x302,  _) => { medeleg = legalize_medeleg(medeleg, value); Some(medeleg.bits) },
    (0x303,  _) => { mideleg = legalize_mideleg(mideleg, value); Some(mideleg.bits) },
    (0x304,  _) => { mie = legalize_mie(mie, value); Some(mie.bits) },
    (0x305,  _) => { Some(set_mtvec(value)) },
    (0x306,  _) => { mcounteren = legalize_mcounteren(mcounteren, value); Some(zero_extend(mcounteren.bits)) },
    (0x30A, 32) => { menvcfg = legalize_envcfg(menvcfg, menvcfg.bits[63 .. 32] @ value); Some(menvcfg.bits[31 .. 0]) },
    (0x30A, 64) => { menvcfg = legalize_envcfg(menvcfg, value); Some(menvcfg.bits) },
    (0x310, 32) => { Some(mstatush.bits) }, // ignore writes for now
    (0x31A, 32) => { menvcfg = legalize_envcfg(menvcfg, value @ menvcfg.bits[31 .. 0]); Some(menvcfg.bits[63 .. 32]) },
    (0x320,  _) => { mcountinhibit = legalize_mcountinhibit(mcountinhibit, value); Some(zero_extend(mcountinhibit.bits)) },
    (0x340,  _) => { mscratch = value; Some(mscratch) },
    (0x341,  _) => { Some(set_xret_target(Machine, V0, value)) },
    (0x342,  _) => { mcause.bits = value; Some(mcause.bits) },
    (0x343,  _) => { mtval = value; Some(mtval) },
    (0x344,  _) => { mip = legalize_mip(mip, value); Some(mip.bits) },

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

    /* trigger/debug */
    (0x7a0,  _) => { tselect = value; Some(tselect) },

    /* hypervisor extendended supervisor mode */
    (0x34A,  _) => { mtinst = value; Some(mtinst) },
    (0x34B,  _) => { mtval2 = value; Some(mtval2) },
    (0x600,  _) => { hstatus = legalize_hstatus(hstatus, value); Some(hstatus.bits) },
    (0x602,  _) => { hedeleg = legalize_hedeleg(hedeleg, value); Some(hedeleg.bits) },
    (0x603,  _) => { hideleg = legalize_hideleg(hideleg, value); Some(hideleg.bits) },
    (0x604,  _) => { mie = legalize_hie(mie, value); Some(lower_mie_to_hie(mie).bits) },
    (0x606,  _) => { hcounteren = legalize_hcounteren(hcounteren, value); Some(zero_extend(hcounteren.bits)) },
    (0x607,  _) => { hgeie = legalize_hgeie(value); Some(hgeie) },
    (0x60A, 64) => { henvcfg = legalize_envcfg(henvcfg, value); Some(henvcfg.bits) },
    (0x60A, 32) => { henvcfg = legalize_envcfg(henvcfg, henvcfg.bits[63 .. 32] @ value); Some(henvcfg.bits[31 .. 0]) },
    (0x61A, 32) => { henvcfg = legalize_envcfg(henvcfg, value @ henvcfg.bits[31 .. 0]); Some(henvcfg.bits[63 .. 32]) },
    (0x643,  _) => { htval = value; Some(htval) },
    (0x644,  _) => { mip = legalize_hip(mip, value); Some(lower_mip_to_hip(mip).bits) },
    (0x645,  _) => { mip = legalize_hvip(mip, value); Some(lower_mip_to_hvip(mip).bits) },
    (0x64A,  _) => { htinst = value; Some(htinst) },
    (0x680,  _) => { hgatp = legalize_hgatp(cur_Architecture(), hgatp, value); Some(hgatp) },
    (0x605,  _) => { htimedelta[(sizeof(xlen) - 1) .. 0] = value; Some(htimedelta[(sizeof(xlen) - 1) .. 0])},
    (0x615, 32) => { htimedelta[63 .. 32] = value; Some(htimedelta[63 .. 32])},

    /* supervisor mode */
    (0x100,  _) => match cur_virtualization {
                    V0 => { mstatus = legalize_sstatus(mstatus, value); Some(mstatus.bits) },
                    V1 => { vsstatus = legalize_vsstatus(vsstatus, value); Some(vsstatus.bits) }
                  },
    (0x102,  _) => { sedeleg = legalize_sedeleg(sedeleg, value); Some(sedeleg.bits) },
    (0x103,  _) => { sideleg->bits() = value; Some(sideleg.bits) }, /* TODO: does this need legalization? */
    (0x104,  _) => match cur_virtualization {
                    V0 => { mie = legalize_sie(mie, mideleg, value); Some(lower_mie(mie, mideleg).bits) },
                    V1 => { mie = legalize_vsie(mie, hideleg, value); Some(lower_mie_to_vsie(mie, hideleg).bits) },
                  },
    (0x105,  _) => { Some(set_trap_vector(Supervisor, cur_virtualization, value)) },
    (0x106,  _) => { scounteren = legalize_scounteren(scounteren, value); Some(zero_extend(scounteren.bits)) },
    (0x10A,  _) => { senvcfg = legalize_envcfg(senvcfg, zero_extend(value)); Some(senvcfg.bits[sizeof(xlen) - 1 .. 0]) },
    (0x140,  _) => match cur_virtualization {
                    V0 => { sscratch = value; Some(sscratch) },
                    V1 => { vsscratch = value; Some(vsscratch) },
                  },
    (0x141,  _) => { Some(set_xret_target(Supervisor, cur_virtualization, value)) },
    (0x142,  _) => match cur_virtualization {
                    V0 => { scause->bits() = value; Some(scause.bits) },
                    V1 => { vscause->bits() = value; Some(vscause.bits) }
                  },
    (0x143,  _) => match cur_virtualization {
                    V0 => { stval = value; Some(stval) },
                    V1 => { vstval = value; Some(vstval) }
                  },
    (0x144,  _) => match cur_virtualization {
                    V0 => { mip = legalize_sip(mip, mideleg, value); Some(lower_mip_to_sip(mip, mideleg).bits) },
                    V1 => { mip = legalize_vsip(mip, hideleg, value); Some(lower_mip_to_vsip(mip, hideleg).bits) },
                  },
    (0x180,  _) => match cur_virtualization {
                    V0 => { satp = legalize_satp(cur_Architecture(), satp, value); Some(satp) },
                    V1 => { vsatp = legalize_satp(cur_Architecture(), vsatp, value); Some(vsatp) },
                  },

    /* virtual supervisor mode */
    (0x200,  _) => { vsstatus = legalize_vsstatus(vsstatus, value); Some(vsstatus.bits) },
    (0x204,  _) => { mie = legalize_vsie(mie, hideleg, value); Some(lower_mie_to_vsie(mie, hideleg).bits) },
    (0x205,  _) => { Some(set_trap_vector(Supervisor, V1, value)) },
    (0x240,  _) => { vsscratch = value; Some(vsscratch) },
    (0x241,  _) => { Some(set_xret_target(Supervisor, V1, value)) },
    (0x242,  _) => { vscause->bits() = value; Some(vscause.bits) },
    (0x243,  _) => { vstval = value; Some(vstval) },
    (0x244,  _) => { mip = legalize_vsip(mip, hideleg, value); Some(lower_mip_to_vsip(mip, hideleg).bits) },
    (0x280,  _) => { vsatp = value; Some(vsatp) },

    /* user mode: seed (entropy source). writes are ignored */
    (0x015,  _) => write_seed_csr(),

    /* vector */
    (0x008, _) => { let vstart_length = get_vlen_pow(); vstart = zero_extend(16, value[(vstart_length - 1) .. 0]); Some(zero_extend(vstart)) },
    (0x009, _) => { vxsat = value[0 .. 0]; Some(zero_extend(vxsat)) },
    (0x00A, _) => { vxrm = value[1 .. 0]; Some(zero_extend(vxrm)) },
    (0x00F, _) => { vcsr.bits = value[2 ..0]; Some(zero_extend(vcsr.bits)) },
    (0xC20, _) => { vl = value; Some(vl) },
    (0xC21, _) => { vtype.bits = value; Some(vtype.bits) },
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
  if not(check_CSR(csr, cur_privilege, cur_virtualization, isWrite))
  then {
    if haveHExt() & csr_access_raises_virtual_instr(csr, cur_privilege, cur_virtualization, isWrite)
    then handle_virtual_instr()
    else handle_illegal();
    RETIRE_FAIL
  }
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
