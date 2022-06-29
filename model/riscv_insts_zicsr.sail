/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2021                                                              */
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
    (0xF11,  _) => EXTZ(mvendorid),
    (0xF12,  _) => marchid,
    (0xF13,  _) => mimpid,
    (0xF14,  _) => mhartid,
    (0x300,  _) => mstatus.bits(),
    (0x301,  _) => misa.bits(),
    (0x302,  _) => medeleg.bits(),
    (0x303,  _) => mideleg.bits(),
    (0x304,  _) => mie.bits(),
    (0x305,  _) => get_mtvec(),
    (0x306,  _) => EXTZ(mcounteren.bits()),
    (0x310, 32) => mstatush.bits(),
    (0x320,  _) => EXTZ(mcountinhibit.bits()),

    (0x340,  _) => mscratch,
    (0x341,  _) => get_xret_target(Machine) & pc_alignment_mask(),
    (0x342,  _) => mcause.bits(),
    (0x343,  _) => mtval,
    (0x344,  _) => mip.bits(),

    (0x3A0,  _) => pmpReadCfgReg(0),           // pmpcfg0
    (0x3A1, 32) => pmpReadCfgReg(1),           // pmpcfg1
    (0x3A2,  _) => pmpReadCfgReg(2),           // pmpcfg2
    (0x3A3, 32) => pmpReadCfgReg(3),           // pmpcfg3
    (0x3A4,  _) => pmpReadCfgReg(4),           // pmpcfg4
    (0x3A5, 32) => pmpReadCfgReg(5),           // pmpcfg5
    (0x3A6,  _) => pmpReadCfgReg(6),           // pmpcfg6
    (0x3A7, 32) => pmpReadCfgReg(7),           // pmpcfg7
    (0x3A8,  _) => pmpReadCfgReg(8),           // pmpcfg8
    (0x3A9, 32) => pmpReadCfgReg(9),           // pmpcfg9
    (0x3AA,  _) => pmpReadCfgReg(10),          // pmpcfg10
    (0x3AB, 32) => pmpReadCfgReg(11),          // pmpcfg11
    (0x3AC,  _) => pmpReadCfgReg(12),          // pmpcfg12
    (0x3AD, 32) => pmpReadCfgReg(13),          // pmpcfg13
    (0x3AE,  _) => pmpReadCfgReg(14),          // pmpcfg14
    (0x3AF, 32) => pmpReadCfgReg(15),          // pmpcfg15

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
    (0x3C0,  _) => pmpaddr16,
    (0x3C1,  _) => pmpaddr17,
    (0x3C2,  _) => pmpaddr18,
    (0x3C3,  _) => pmpaddr19,
    (0x3C4,  _) => pmpaddr20,
    (0x3C5,  _) => pmpaddr21,
    (0x3C6,  _) => pmpaddr22,
    (0x3C7,  _) => pmpaddr23,
    (0x3C8,  _) => pmpaddr24,
    (0x3C9,  _) => pmpaddr25,
    (0x3CA,  _) => pmpaddr26,
    (0x3CB,  _) => pmpaddr27,
    (0x3CC,  _) => pmpaddr28,
    (0x3CD,  _) => pmpaddr29,
    (0x3CE,  _) => pmpaddr30,
    (0x3CF,  _) => pmpaddr31,
    (0x3D0,  _) => pmpaddr32,
    (0x3D1,  _) => pmpaddr33,
    (0x3D2,  _) => pmpaddr34,
    (0x3D3,  _) => pmpaddr35,
    (0x3D4,  _) => pmpaddr36,
    (0x3D5,  _) => pmpaddr37,
    (0x3D6,  _) => pmpaddr38,
    (0x3D7,  _) => pmpaddr39,
    (0x3D8,  _) => pmpaddr40,
    (0x3D9,  _) => pmpaddr41,
    (0x3DA,  _) => pmpaddr42,
    (0x3DB,  _) => pmpaddr43,
    (0x3DC,  _) => pmpaddr44,
    (0x3DD,  _) => pmpaddr45,
    (0x3DE,  _) => pmpaddr46,
    (0x3DF,  _) => pmpaddr47,
    (0x3E0,  _) => pmpaddr48,
    (0x3E1,  _) => pmpaddr49,
    (0x3E2,  _) => pmpaddr50,
    (0x3E3,  _) => pmpaddr51,
    (0x3E4,  _) => pmpaddr52,
    (0x3E5,  _) => pmpaddr53,
    (0x3E6,  _) => pmpaddr54,
    (0x3E7,  _) => pmpaddr55,
    (0x3E8,  _) => pmpaddr56,
    (0x3E9,  _) => pmpaddr57,
    (0x3EA,  _) => pmpaddr58,
    (0x3EB,  _) => pmpaddr59,
    (0x3EC,  _) => pmpaddr60,
    (0x3ED,  _) => pmpaddr61,
    (0x3EE,  _) => pmpaddr62,
    (0x3EF,  _) => pmpaddr63,

    /* machine mode counters */
    (0xB00,  _) => mcycle[(sizeof(xlen) - 1) .. 0],
    (0xB02,  _) => minstret[(sizeof(xlen) - 1) .. 0],
    (0xB80, 32) => mcycle[63 .. 32],
    (0xB82, 32) => minstret[63 .. 32],

    /* trigger/debug */
    (0x7a0,  _) => ~(tselect),  /* this indicates we don't have any trigger support */

    /* supervisor mode */
    (0x100,  _) => lower_mstatus(mstatus).bits(),
    (0x102,  _) => sedeleg.bits(),
    (0x103,  _) => sideleg.bits(),
    (0x104,  _) => lower_mie(mie, mideleg).bits(),
    (0x105,  _) => get_stvec(),
    (0x106,  _) => EXTZ(scounteren.bits()),
    (0x140,  _) => sscratch,
    (0x141,  _) => get_xret_target(Supervisor) & pc_alignment_mask(),
    (0x142,  _) => scause.bits(),
    (0x143,  _) => stval,
    (0x144,  _) => lower_mip(mip, mideleg).bits(),
    (0x180,  _) => satp,

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
                                    EXTZ(0x0) }
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
    (0x306,  _) => { mcounteren = legalize_mcounteren(mcounteren, value); Some(EXTZ(mcounteren.bits())) },
    (0x310, 32) => { Some(mstatush.bits()) }, // ignore writes for now
    (0x320,  _) => { mcountinhibit = legalize_mcountinhibit(mcountinhibit, value); Some(EXTZ(mcountinhibit.bits())) },
    (0x340,  _) => { mscratch = value; Some(mscratch) },
    (0x341,  _) => { Some(set_xret_target(Machine, value)) },
    (0x342,  _) => { mcause->bits() = value; Some(mcause.bits()) },
    (0x343,  _) => { mtval = value; Some(mtval) },
    (0x344,  _) => { mip = legalize_mip(mip, value); Some(mip.bits()) },

    // Note: Some(value) returned below is not the legalized value due to locked entries
    (0x3A0,  _) => { pmpWriteCfgReg(0,  value); Some(pmpReadCfgReg(0)) },   // pmpcfg0
    (0x3A1, 32) => { pmpWriteCfgReg(1,  value); Some(pmpReadCfgReg(1)) },   // pmpcfg1
    (0x3A2,  _) => { pmpWriteCfgReg(2,  value); Some(pmpReadCfgReg(2)) },   // pmpcfg2
    (0x3A3, 32) => { pmpWriteCfgReg(3,  value); Some(pmpReadCfgReg(3)) },   // pmpcfg3
    (0x3A4,  _) => { pmpWriteCfgReg(4,  value); Some(pmpReadCfgReg(4)) },   // pmpcfg4
    (0x3A5, 32) => { pmpWriteCfgReg(5,  value); Some(pmpReadCfgReg(5)) },   // pmpcfg5
    (0x3A6,  _) => { pmpWriteCfgReg(6,  value); Some(pmpReadCfgReg(6)) },   // pmpcfg6
    (0x3A7, 32) => { pmpWriteCfgReg(7,  value); Some(pmpReadCfgReg(7)) },   // pmpcfg7
    (0x3A8,  _) => { pmpWriteCfgReg(8,  value); Some(pmpReadCfgReg(8)) },   // pmpcfg8
    (0x3A9, 32) => { pmpWriteCfgReg(9,  value); Some(pmpReadCfgReg(9)) },   // pmpcfg9
    (0x3AA,  _) => { pmpWriteCfgReg(10, value); Some(pmpReadCfgReg(10)) },  // pmpcfg10
    (0x3AB, 32) => { pmpWriteCfgReg(11, value); Some(pmpReadCfgReg(11)) },  // pmpcfg11
    (0x3AC,  _) => { pmpWriteCfgReg(12, value); Some(pmpReadCfgReg(12)) },  // pmpcfg12
    (0x3AD, 32) => { pmpWriteCfgReg(13, value); Some(pmpReadCfgReg(13)) },  // pmpcfg13
    (0x3AE,  _) => { pmpWriteCfgReg(14, value); Some(pmpReadCfgReg(14)) },  // pmpcfg14
    (0x3AF, 32) => { pmpWriteCfgReg(15, value); Some(pmpReadCfgReg(15)) },  // pmpcfg15

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
    (0x3BF,  _) => { pmpaddr15 = pmpWriteAddr(pmpLocked(pmp15cfg), pmpTORLocked(pmp16cfg), pmpaddr15, value); Some(pmpaddr15) },
    (0x3C0,  _) => { pmpaddr16 = pmpWriteAddr(pmpLocked(pmp16cfg), pmpTORLocked(pmp17cfg), pmpaddr16, value); Some(pmpaddr16) },
    (0x3C1,  _) => { pmpaddr17 = pmpWriteAddr(pmpLocked(pmp17cfg), pmpTORLocked(pmp18cfg), pmpaddr17, value); Some(pmpaddr17) },
    (0x3C2,  _) => { pmpaddr18 = pmpWriteAddr(pmpLocked(pmp18cfg), pmpTORLocked(pmp19cfg), pmpaddr18, value); Some(pmpaddr18) },
    (0x3C3,  _) => { pmpaddr19 = pmpWriteAddr(pmpLocked(pmp19cfg), pmpTORLocked(pmp20cfg), pmpaddr19, value); Some(pmpaddr19) },
    (0x3C4,  _) => { pmpaddr20 = pmpWriteAddr(pmpLocked(pmp20cfg), pmpTORLocked(pmp21cfg), pmpaddr20, value); Some(pmpaddr20) },
    (0x3C5,  _) => { pmpaddr21 = pmpWriteAddr(pmpLocked(pmp21cfg), pmpTORLocked(pmp22cfg), pmpaddr21, value); Some(pmpaddr21) },
    (0x3C6,  _) => { pmpaddr22 = pmpWriteAddr(pmpLocked(pmp22cfg), pmpTORLocked(pmp23cfg), pmpaddr22, value); Some(pmpaddr22) },
    (0x3C7,  _) => { pmpaddr23 = pmpWriteAddr(pmpLocked(pmp23cfg), pmpTORLocked(pmp24cfg), pmpaddr23, value); Some(pmpaddr23) },
    (0x3C8,  _) => { pmpaddr24 = pmpWriteAddr(pmpLocked(pmp24cfg), pmpTORLocked(pmp25cfg), pmpaddr24, value); Some(pmpaddr24) },
    (0x3C9,  _) => { pmpaddr25 = pmpWriteAddr(pmpLocked(pmp25cfg), pmpTORLocked(pmp26cfg), pmpaddr25, value); Some(pmpaddr25) },
    (0x3CA,  _) => { pmpaddr26 = pmpWriteAddr(pmpLocked(pmp26cfg), pmpTORLocked(pmp27cfg), pmpaddr26, value); Some(pmpaddr26) },
    (0x3CB,  _) => { pmpaddr27 = pmpWriteAddr(pmpLocked(pmp27cfg), pmpTORLocked(pmp28cfg), pmpaddr27, value); Some(pmpaddr27) },
    (0x3CC,  _) => { pmpaddr28 = pmpWriteAddr(pmpLocked(pmp28cfg), pmpTORLocked(pmp29cfg), pmpaddr28, value); Some(pmpaddr28) },
    (0x3CD,  _) => { pmpaddr29 = pmpWriteAddr(pmpLocked(pmp29cfg), pmpTORLocked(pmp30cfg), pmpaddr29, value); Some(pmpaddr29) },
    (0x3CE,  _) => { pmpaddr30 = pmpWriteAddr(pmpLocked(pmp30cfg), pmpTORLocked(pmp31cfg), pmpaddr30, value); Some(pmpaddr30) },
    (0x3CF,  _) => { pmpaddr31 = pmpWriteAddr(pmpLocked(pmp31cfg), pmpTORLocked(pmp32cfg), pmpaddr31, value); Some(pmpaddr31) },
    (0x3D0,  _) => { pmpaddr32 = pmpWriteAddr(pmpLocked(pmp32cfg), pmpTORLocked(pmp33cfg), pmpaddr32, value); Some(pmpaddr32) },
    (0x3D1,  _) => { pmpaddr33 = pmpWriteAddr(pmpLocked(pmp33cfg), pmpTORLocked(pmp34cfg), pmpaddr33, value); Some(pmpaddr33) },
    (0x3D2,  _) => { pmpaddr34 = pmpWriteAddr(pmpLocked(pmp34cfg), pmpTORLocked(pmp35cfg), pmpaddr34, value); Some(pmpaddr34) },
    (0x3D3,  _) => { pmpaddr35 = pmpWriteAddr(pmpLocked(pmp35cfg), pmpTORLocked(pmp36cfg), pmpaddr35, value); Some(pmpaddr35) },
    (0x3D4,  _) => { pmpaddr36 = pmpWriteAddr(pmpLocked(pmp36cfg), pmpTORLocked(pmp37cfg), pmpaddr36, value); Some(pmpaddr36) },
    (0x3D5,  _) => { pmpaddr37 = pmpWriteAddr(pmpLocked(pmp37cfg), pmpTORLocked(pmp38cfg), pmpaddr37, value); Some(pmpaddr37) },
    (0x3D6,  _) => { pmpaddr38 = pmpWriteAddr(pmpLocked(pmp38cfg), pmpTORLocked(pmp39cfg), pmpaddr38, value); Some(pmpaddr38) },
    (0x3D7,  _) => { pmpaddr39 = pmpWriteAddr(pmpLocked(pmp39cfg), pmpTORLocked(pmp40cfg), pmpaddr39, value); Some(pmpaddr39) },
    (0x3D8,  _) => { pmpaddr40 = pmpWriteAddr(pmpLocked(pmp40cfg), pmpTORLocked(pmp41cfg), pmpaddr40, value); Some(pmpaddr40) },
    (0x3D9,  _) => { pmpaddr41 = pmpWriteAddr(pmpLocked(pmp41cfg), pmpTORLocked(pmp42cfg), pmpaddr41, value); Some(pmpaddr41) },
    (0x3DA,  _) => { pmpaddr42 = pmpWriteAddr(pmpLocked(pmp42cfg), pmpTORLocked(pmp43cfg), pmpaddr42, value); Some(pmpaddr42) },
    (0x3DB,  _) => { pmpaddr43 = pmpWriteAddr(pmpLocked(pmp43cfg), pmpTORLocked(pmp44cfg), pmpaddr43, value); Some(pmpaddr43) },
    (0x3DC,  _) => { pmpaddr44 = pmpWriteAddr(pmpLocked(pmp44cfg), pmpTORLocked(pmp45cfg), pmpaddr44, value); Some(pmpaddr44) },
    (0x3DD,  _) => { pmpaddr45 = pmpWriteAddr(pmpLocked(pmp45cfg), pmpTORLocked(pmp46cfg), pmpaddr45, value); Some(pmpaddr45) },
    (0x3DE,  _) => { pmpaddr46 = pmpWriteAddr(pmpLocked(pmp46cfg), pmpTORLocked(pmp47cfg), pmpaddr46, value); Some(pmpaddr46) },
    (0x3DF,  _) => { pmpaddr47 = pmpWriteAddr(pmpLocked(pmp47cfg), pmpTORLocked(pmp48cfg), pmpaddr47, value); Some(pmpaddr47) },
    (0x3E0,  _) => { pmpaddr48 = pmpWriteAddr(pmpLocked(pmp48cfg), pmpTORLocked(pmp49cfg), pmpaddr48, value); Some(pmpaddr48) },
    (0x3E1,  _) => { pmpaddr49 = pmpWriteAddr(pmpLocked(pmp49cfg), pmpTORLocked(pmp50cfg), pmpaddr49, value); Some(pmpaddr49) },
    (0x3E2,  _) => { pmpaddr50 = pmpWriteAddr(pmpLocked(pmp50cfg), pmpTORLocked(pmp51cfg), pmpaddr50, value); Some(pmpaddr50) },
    (0x3E3,  _) => { pmpaddr51 = pmpWriteAddr(pmpLocked(pmp51cfg), pmpTORLocked(pmp52cfg), pmpaddr51, value); Some(pmpaddr51) },
    (0x3E4,  _) => { pmpaddr52 = pmpWriteAddr(pmpLocked(pmp52cfg), pmpTORLocked(pmp53cfg), pmpaddr52, value); Some(pmpaddr52) },
    (0x3E5,  _) => { pmpaddr53 = pmpWriteAddr(pmpLocked(pmp53cfg), pmpTORLocked(pmp54cfg), pmpaddr53, value); Some(pmpaddr53) },
    (0x3E6,  _) => { pmpaddr54 = pmpWriteAddr(pmpLocked(pmp54cfg), pmpTORLocked(pmp55cfg), pmpaddr54, value); Some(pmpaddr54) },
    (0x3E7,  _) => { pmpaddr55 = pmpWriteAddr(pmpLocked(pmp55cfg), pmpTORLocked(pmp56cfg), pmpaddr55, value); Some(pmpaddr55) },
    (0x3E8,  _) => { pmpaddr56 = pmpWriteAddr(pmpLocked(pmp56cfg), pmpTORLocked(pmp57cfg), pmpaddr56, value); Some(pmpaddr56) },
    (0x3E9,  _) => { pmpaddr57 = pmpWriteAddr(pmpLocked(pmp57cfg), pmpTORLocked(pmp58cfg), pmpaddr57, value); Some(pmpaddr57) },
    (0x3EA,  _) => { pmpaddr58 = pmpWriteAddr(pmpLocked(pmp58cfg), pmpTORLocked(pmp59cfg), pmpaddr58, value); Some(pmpaddr58) },
    (0x3EB,  _) => { pmpaddr59 = pmpWriteAddr(pmpLocked(pmp59cfg), pmpTORLocked(pmp60cfg), pmpaddr59, value); Some(pmpaddr59) },
    (0x3EC,  _) => { pmpaddr60 = pmpWriteAddr(pmpLocked(pmp60cfg), pmpTORLocked(pmp61cfg), pmpaddr60, value); Some(pmpaddr60) },
    (0x3ED,  _) => { pmpaddr61 = pmpWriteAddr(pmpLocked(pmp61cfg), pmpTORLocked(pmp62cfg), pmpaddr61, value); Some(pmpaddr61) },
    (0x3EE,  _) => { pmpaddr62 = pmpWriteAddr(pmpLocked(pmp62cfg), pmpTORLocked(pmp63cfg), pmpaddr62, value); Some(pmpaddr62) },
    (0x3EF,  _) => { pmpaddr63 = pmpWriteAddr(pmpLocked(pmp63cfg), false,                  pmpaddr63, value); Some(pmpaddr63) },

    /* machine mode counters */
    (0xB00,  _) => { mcycle[(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB02,  _) => { minstret[(sizeof(xlen) - 1) .. 0] = value; minstret_written = true; Some(value) },
    (0xB80, 32) => { mcycle[63 .. 32] = value; Some(value) },
    (0xB82, 32) => { minstret[63 .. 32] = value; minstret_written = true; Some(value) },

    /* trigger/debug */
    (0x7a0,  _) => { tselect = value; Some(tselect) },

    /* supervisor mode */
    (0x100,  _) => { mstatus = legalize_sstatus(mstatus, value); Some(mstatus.bits()) },
    (0x102,  _) => { sedeleg = legalize_sedeleg(sedeleg, value); Some(sedeleg.bits()) },
    (0x103,  _) => { sideleg->bits() = value; Some(sideleg.bits()) }, /* TODO: does this need legalization? */
    (0x104,  _) => { mie = legalize_sie(mie, mideleg, value); Some(mie.bits()) },
    (0x105,  _) => { Some(set_stvec(value)) },
    (0x106,  _) => { scounteren = legalize_scounteren(scounteren, value); Some(EXTZ(scounteren.bits())) },
    (0x140,  _) => { sscratch = value; Some(sscratch) },
    (0x141,  _) => { Some(set_xret_target(Supervisor, value)) },
    (0x142,  _) => { scause->bits() = value; Some(scause.bits()) },
    (0x143,  _) => { stval = value; Some(stval) },
    (0x144,  _) => { mip = legalize_sip(mip, mideleg, value); Some(mip.bits()) },
    (0x180,  _) => { satp = legalize_satp(cur_Architecture(), satp, value); Some(satp) },

    /* user mode: seed (entropy source). writes are ignored */
    (0x015,  _) => write_seed_csr(),

    _           => ext_write_CSR(csr, value)
  };
  match res {
    Some(v) => if   get_config_print_reg()
               then print_reg("CSR " ^ to_str(csr) ^ " <- " ^ BitStr(v) ^ " (input: " ^ BitStr(value) ^ ")"),
    None()  => print_bits("unhandled write to CSR ", csr)
  }
}

function clause execute CSR(csr, rs1, rd, is_imm, op) = {
  let rs1_val : xlenbits = if is_imm then EXTZ(rs1) else X(rs1);
  let isWrite : bool = match op {
    CSRRW  => true,
    _      => if is_imm then unsigned(rs1_val) != 0 else unsigned(rs1) != 0
  };
  if ~ (check_CSR(csr, cur_privilege, isWrite))
  then { handle_illegal(); RETIRE_FAIL }
  else if ~ (ext_check_CSR(csr, cur_privilege, isWrite))
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
