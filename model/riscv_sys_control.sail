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

/* Machine-mode and supervisor-mode functionality. */


/* CSR access control */

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> priv_level = csr[9..8]

function is_CSR_defined (csr : csreg, p : Privilege) -> bool =
  match (csr) {
    /* machine mode: informational */
    0xf11 => p == Machine, // mvendorid
    0xf12 => p == Machine, // marchdid
    0xf13 => p == Machine, // mimpid
    0xf14 => p == Machine, // mhartid
    /* machine mode: trap setup */
    0x300 => p == Machine, // mstatus
    0x301 => p == Machine, // misa
    0x302 => p == Machine & (haveSupMode() | haveNExt()), // medeleg
    0x303 => p == Machine & (haveSupMode() | haveNExt()), // mideleg
    0x304 => p == Machine, // mie
    0x305 => p == Machine, // mtvec
    0x306 => p == Machine & haveUsrMode(), // mcounteren
    0x310 => p == Machine & (sizeof(xlen) == 32), // mstatush
    0x320 => p == Machine, // mcountinhibit

    /* machine mode: event selectors */
    0x323 => p == Machine, // mhpmevents[0]
    0x324 => p == Machine, // mhpmevents[1]
    0x325 => p == Machine, // mhpmevents[2]
    0x326 => p == Machine, // mhpmevents[3]
    0x327 => p == Machine, // mhpmevents[4]
    0x328 => p == Machine, // mhpmevents[5]
    0x329 => p == Machine, // mhpmevents[6]
    0x32A => p == Machine, // mhpmevents[7]
    0x32B => p == Machine, // mhpmevents[8]
    0x32C => p == Machine, // mhpmevents[9]
    0x32D => p == Machine, // mhpmevents[10]
    0x32E => p == Machine, // mhpmevents[11]
    0x32F => p == Machine, // mhpmevents[12]
    0x330 => p == Machine, // mhpmevents[13]
    0x331 => p == Machine, // mhpmevents[14]
    0x332 => p == Machine, // mhpmevents[15]
    0x333 => p == Machine, // mhpmevents[16]
    0x334 => p == Machine, // mhpmevents[17]
    0x335 => p == Machine, // mhpmevents[18]
    0x336 => p == Machine, // mhpmevents[19]
    0x337 => p == Machine, // mhpmevents[20]
    0x338 => p == Machine, // mhpmevents[21]
    0x339 => p == Machine, // mhpmevents[22]
    0x33A => p == Machine, // mhpmevents[23]
    0x33B => p == Machine, // mhpmevents[24]
    0x33C => p == Machine, // mhpmevents[25]
    0x33D => p == Machine, // mhpmevents[26]
    0x33E => p == Machine, // mhpmevents[27]
    0x33F => p == Machine, // mhpmevents[28]

    /* machine mode: trap handling */
    0x340 => p == Machine, // mscratch
    0x341 => p == Machine, // mepc
    0x342 => p == Machine, // mcause
    0x343 => p == Machine, // mtval
    0x344 => p == Machine, // mip

    0x3A0 => p == Machine,                        // pmpcfg0
    0x3A1 => p == Machine & (sizeof(xlen) == 32), // pmpcfg1
    0x3A2 => p == Machine,                        // pmpcfg2
    0x3A3 => p == Machine & (sizeof(xlen) == 32), // pmpcfg3

    0x3B0 => p == Machine, // pmpaddr0
    0x3B1 => p == Machine, // pmpaddr1
    0x3B2 => p == Machine, // pmpaddr2
    0x3B3 => p == Machine, // pmpaddr3
    0x3B4 => p == Machine, // pmpaddr4
    0x3B5 => p == Machine, // pmpaddr5
    0x3B6 => p == Machine, // pmpaddr6
    0x3B7 => p == Machine, // pmpaddr7
    0x3B8 => p == Machine, // pmpaddr8
    0x3B9 => p == Machine, // pmpaddr9
    0x3BA => p == Machine, // pmpaddrA
    0x3BB => p == Machine, // pmpaddrB
    0x3BC => p == Machine, // pmpaddrC
    0x3BD => p == Machine, // pmpaddrD
    0x3BE => p == Machine, // pmpaddrE
    0x3BF => p == Machine, // pmpaddrF

    /* counters */
    0xB00 => p == Machine, // mcycle
    0xB02 => p == Machine, // minstret
    0xB03 => p == Machine, // mhpmcounters[0]
    0xB04 => p == Machine, // mhpmcounters[1]
    0xB05 => p == Machine, // mhpmcounters[2]
    0xB06 => p == Machine, // mhpmcounters[3]
    0xB07 => p == Machine, // mhpmcounters[4]
    0xB08 => p == Machine, // mhpmcounters[5]
    0xB09 => p == Machine, // mhpmcounters[6]
    0xB0A => p == Machine, // mhpmcounters[7]
    0xB0B => p == Machine, // mhpmcounters[8]
    0xB0C => p == Machine, // mhpmcounters[9]
    0xB0D => p == Machine, // mhpmcounters[10]
    0xB0E => p == Machine, // mhpmcounters[11]
    0xB0F => p == Machine, // mhpmcounters[12]
    0xB10 => p == Machine, // mhpmcounters[13]
    0xB11 => p == Machine, // mhpmcounters[14]
    0xB12 => p == Machine, // mhpmcounters[15]
    0xB13 => p == Machine, // mhpmcounters[16]
    0xB14 => p == Machine, // mhpmcounters[17]
    0xB15 => p == Machine, // mhpmcounters[18]
    0xB16 => p == Machine, // mhpmcounters[19]
    0xB17 => p == Machine, // mhpmcounters[20]
    0xB18 => p == Machine, // mhpmcounters[21]
    0xB19 => p == Machine, // mhpmcounters[22]
    0xB1A => p == Machine, // mhpmcounters[23]
    0xB1B => p == Machine, // mhpmcounters[24]
    0xB1C => p == Machine, // mhpmcounters[25]
    0xB1D => p == Machine, // mhpmcounters[26]
    0xB1E => p == Machine, // mhpmcounters[27]
    0xB1F => p == Machine, // mhpmcounters[28]

    0xB80 => p == Machine & (sizeof(xlen) == 32), // mcycleh
    0xB82 => p == Machine & (sizeof(xlen) == 32), // minstreth
    0xB83 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[0]
    0xB84 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[1]
    0xB85 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[2]
    0xB86 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[3]
    0xB87 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[4]
    0xB88 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[5]
    0xB89 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[6]
    0xB8A => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[7]
    0xB8B => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[8]
    0xB8C => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[9]
    0xB8D => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[10]
    0xB8E => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[11]
    0xB8F => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[12]
    0xB90 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[13]
    0xB91 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[14]
    0xB92 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[15]
    0xB93 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[16]
    0xB94 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[17]
    0xB95 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[18]
    0xB96 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[19]
    0xB97 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[20]
    0xB98 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[21]
    0xB99 => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[22]
    0xB9A => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[23]
    0xB9B => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[24]
    0xB9C => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[25]
    0xB9D => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[26]
    0xB9E => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[27]
    0xB9F => p == Machine & (sizeof(xlen) == 32), // mhpmcounters[28]

    /* disabled trigger/debug module */
    0x7a0 => p == Machine,

    /* supervisor mode: trap setup */
    0x100 => haveSupMode() & (p == Machine | p == Supervisor), // sstatus
    0x102 => haveSupMode() & haveNExt() & (p == Machine | p == Supervisor), // sedeleg
    0x103 => haveSupMode() & haveNExt() & (p == Machine | p == Supervisor), // sideleg
    0x104 => haveSupMode() & (p == Machine | p == Supervisor), // sie
    0x105 => haveSupMode() & (p == Machine | p == Supervisor), // stvec
    0x106 => haveSupMode() & (p == Machine | p == Supervisor), // scounteren

    /* supervisor mode: trap handling */
    0x140 => haveSupMode() & (p == Machine | p == Supervisor), // sscratch
    0x141 => haveSupMode() & (p == Machine | p == Supervisor), // sepc
    0x142 => haveSupMode() & (p == Machine | p == Supervisor), // scause
    0x143 => haveSupMode() & (p == Machine | p == Supervisor), // stval
    0x144 => haveSupMode() & (p == Machine | p == Supervisor), // sip

    /* supervisor mode: address translation */
    0x180 => haveSupMode() & (p == Machine | p == Supervisor), // satp

    /* user mode: counters */
    0xC00 => haveUsrMode(),    // cycle
    0xC01 => haveUsrMode(),    // time
    0xC02 => haveUsrMode(),    // instret
    0xC03 => haveUsrMode(),    // hpmcounters[0]
    0xC04 => haveUsrMode(),    // hpmcounters[1]
    0xC05 => haveUsrMode(),    // hpmcounters[2]
    0xC06 => haveUsrMode(),    // hpmcounters[3]
    0xC07 => haveUsrMode(),    // hpmcounters[4]
    0xC08 => haveUsrMode(),    // hpmcounters[5]
    0xC09 => haveUsrMode(),    // hpmcounters[6]
    0xC0A => haveUsrMode(),    // hpmcounters[7]
    0xC0B => haveUsrMode(),    // hpmcounters[8]
    0xC0C => haveUsrMode(),    // hpmcounters[9]
    0xC0D => haveUsrMode(),    // hpmcounters[10]
    0xC0E => haveUsrMode(),    // hpmcounters[11]
    0xC0F => haveUsrMode(),    // hpmcounters[12]
    0xC10 => haveUsrMode(),    // hpmcounters[13]
    0xC11 => haveUsrMode(),    // hpmcounters[14]
    0xC12 => haveUsrMode(),    // hpmcounters[15]
    0xC13 => haveUsrMode(),    // hpmcounters[16]
    0xC14 => haveUsrMode(),    // hpmcounters[17]
    0xC15 => haveUsrMode(),    // hpmcounters[18]
    0xC16 => haveUsrMode(),    // hpmcounters[19]
    0xC17 => haveUsrMode(),    // hpmcounters[20]
    0xC18 => haveUsrMode(),    // hpmcounters[21]
    0xC19 => haveUsrMode(),    // hpmcounters[22]
    0xC1A => haveUsrMode(),    // hpmcounters[23]
    0xC1B => haveUsrMode(),    // hpmcounters[24]
    0xC1C => haveUsrMode(),    // hpmcounters[25]
    0xC1D => haveUsrMode(),    // hpmcounters[26]
    0xC1E => haveUsrMode(),    // hpmcounters[27]
    0xC1F => haveUsrMode(),    // hpmcounters[28]

    0xC80 => haveUsrMode() & (sizeof(xlen) == 32),     // cycleh
    0xC81 => haveUsrMode() & (sizeof(xlen) == 32),     // timeh
    0xC82 => haveUsrMode() & (sizeof(xlen) == 32),     // instreth

    /* user mode: Zkr */
    0x015 => haveZkr(),

    /* check extensions */
    _     => ext_is_CSR_defined(csr, p)
  }

val check_CSR_access : (csrRW, priv_level, Privilege, bool) -> bool
function check_CSR_access(csrrw, csrpr, p, isWrite) =
    not(isWrite == true & csrrw == 0b11)  /* read/write */
  & (privLevel_to_bits(p) >=_u csrpr)      /* privilege */

function check_TVM_SATP(csr : csreg, p : Privilege) -> bool =
  not(csr == 0x180 & p == Supervisor & mstatus.TVM() == 0b1)

function check_Counteren(csr : csreg, p : Privilege) -> bool =
  match(csr, p) {
    (0xC00, Supervisor) => mcounteren.CY() == 0b1,
    (0xC01, Supervisor) => mcounteren.TM() == 0b1,
    (0xC02, Supervisor) => mcounteren.IR() == 0b1,
    (0xC03, Supervisor) => mcounteren.HPM()[0] == bitone,
    (0xC04, Supervisor) => mcounteren.HPM()[1] == bitone,
    (0xC05, Supervisor) => mcounteren.HPM()[2] == bitone,
    (0xC06, Supervisor) => mcounteren.HPM()[3] == bitone,
    (0xC07, Supervisor) => mcounteren.HPM()[4] == bitone,
    (0xC08, Supervisor) => mcounteren.HPM()[5] == bitone,
    (0xC09, Supervisor) => mcounteren.HPM()[6] == bitone,
    (0xC0A, Supervisor) => mcounteren.HPM()[7] == bitone,
    (0xC0B, Supervisor) => mcounteren.HPM()[8] == bitone,
    (0xC0C, Supervisor) => mcounteren.HPM()[9] == bitone,
    (0xC0D, Supervisor) => mcounteren.HPM()[10] == bitone,
    (0xC0E, Supervisor) => mcounteren.HPM()[11] == bitone,
    (0xC0F, Supervisor) => mcounteren.HPM()[12] == bitone,
    (0xC10, Supervisor) => mcounteren.HPM()[13] == bitone,
    (0xC11, Supervisor) => mcounteren.HPM()[14] == bitone,
    (0xC12, Supervisor) => mcounteren.HPM()[15] == bitone,
    (0xC13, Supervisor) => mcounteren.HPM()[16] == bitone,
    (0xC14, Supervisor) => mcounteren.HPM()[17] == bitone,
    (0xC15, Supervisor) => mcounteren.HPM()[18] == bitone,
    (0xC16, Supervisor) => mcounteren.HPM()[19] == bitone,
    (0xC17, Supervisor) => mcounteren.HPM()[10] == bitone,
    (0xC18, Supervisor) => mcounteren.HPM()[21] == bitone,
    (0xC19, Supervisor) => mcounteren.HPM()[22] == bitone,
    (0xC1A, Supervisor) => mcounteren.HPM()[23] == bitone,
    (0xC1B, Supervisor) => mcounteren.HPM()[24] == bitone,
    (0xC1C, Supervisor) => mcounteren.HPM()[25] == bitone,
    (0xC1D, Supervisor) => mcounteren.HPM()[26] == bitone,
    (0xC1E, Supervisor) => mcounteren.HPM()[27] == bitone,
    (0xC1F, Supervisor) => mcounteren.HPM()[28] == bitone,

//  (0xC00, User) => mcounteren.CY() == 0b1 & (not(haveSupMode()) | scounteren.CY() == 0b1),
//    (0xC01, User) => mcounteren.TM() == 0b1 & (not(haveSupMode()) | scounteren.TM() == 0b1),
//  (0xC02, User) => mcounteren.IR() == 0b1 & (not(haveSupMode()) | scounteren.IR() == 0b1),

    (0xC80, User) => mcounteren.CY() == 0b1 & ((~ (haveSupMode())) | scounteren.CY() == 0b1),   // TODO: check address
    (0xC81, User) => mcounteren.TM() == 0b1 & ((~ (haveSupMode())) | scounteren.TM() == 0b1),   // TODO: check address
    (0xC82, User) => mcounteren.IR() == 0b1 & ((~ (haveSupMode())) | scounteren.IR() == 0b1),   // TODO: check address
    (0xC83, User) => mcounteren.HPM()[0] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[0] == bitone),
    (0xC84, User) => mcounteren.HPM()[1] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[1] == bitone),
    (0xC85, User) => mcounteren.HPM()[2] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[2] == bitone),
    (0xC86, User) => mcounteren.HPM()[3] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[3] == bitone),
    (0xC87, User) => mcounteren.HPM()[4] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[4] == bitone),
    (0xC88, User) => mcounteren.HPM()[5] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[5] == bitone),
    (0xC89, User) => mcounteren.HPM()[6] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[6] == bitone),
    (0xC8A, User) => mcounteren.HPM()[7] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[7] == bitone),
    (0xC8B, User) => mcounteren.HPM()[8] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[8] == bitone),
    (0xC8C, User) => mcounteren.HPM()[9] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[9] == bitone),
    (0xC8D, User) => mcounteren.HPM()[10] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[10] == bitone),
    (0xC8E, User) => mcounteren.HPM()[11] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[11] == bitone),
    (0xC8F, User) => mcounteren.HPM()[12] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[12] == bitone),
    (0xC90, User) => mcounteren.HPM()[13] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[13] == bitone),
    (0xC91, User) => mcounteren.HPM()[14] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[14] == bitone),
    (0xC92, User) => mcounteren.HPM()[15] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[15] == bitone),
    (0xC93, User) => mcounteren.HPM()[16] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[16] == bitone),
    (0xC94, User) => mcounteren.HPM()[17] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[17] == bitone),
    (0xC95, User) => mcounteren.HPM()[18] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[18] == bitone),
    (0xC96, User) => mcounteren.HPM()[19] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[19] == bitone),
    (0xC97, User) => mcounteren.HPM()[20] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[20] == bitone),
    (0xC98, User) => mcounteren.HPM()[21] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[21] == bitone),
    (0xC99, User) => mcounteren.HPM()[22] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[22] == bitone),
    (0xC9A, User) => mcounteren.HPM()[23] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[23] == bitone),
    (0xC9B, User) => mcounteren.HPM()[24] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[24] == bitone),
    (0xC9C, User) => mcounteren.HPM()[25] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[25] == bitone),
    (0xC9D, User) => mcounteren.HPM()[26] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[26] == bitone),
    (0xC9E, User) => mcounteren.HPM()[27] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[27] == bitone),
    (0xC9F, User) => mcounteren.HPM()[28] == bitone & ((~ (haveSupMode())) | scounteren.HPM()[28] == bitone),
    (_, _) => true
  }


/* Seed may only be accessed if we are doing a write, and access has been
 * allowed in the current priv mode
 */
function check_seed_CSR (csr : csreg, p : Privilege, isWrite : bool) -> bool = {
  if not(csr == 0x015) then {
    true
  } else if not(isWrite) then {
    /* Read-only access to the seed CSR is not allowed */
    false
  } else {
    match (p) {
      Machine => true,
      Supervisor => false, /* TODO: base this on mseccfg */
      User => false, /* TODO: base this on mseccfg */
      _ => false
    }
  }
}

function check_CSR(csr : csreg, p : Privilege, isWrite : bool) -> bool =
    is_CSR_defined(csr, p)
  & check_CSR_access(csrAccess(csr), csrPriv(csr), p, isWrite)
  & check_TVM_SATP(csr, p)
  & check_Counteren(csr, p)
  & check_seed_CSR(csr, p, isWrite)

/* Reservation handling for LR/SC.
 *
 * The reservation state is maintained external to the model since the
 * reservation behavior is platform-specific anyway and maintaining
 * this state outside the model simplifies the concurrency analysis.
 *
 * These are externs are defined here in the system module since
 * we currently perform reservation cancellation on privilege level
 * transition.  Ideally, the platform should get more visibility into
 * where cancellation can be performed.
 */

val speculate_conditional = {ocaml: "Platform.speculate_conditional", interpreter: "excl_res", c: "speculate_conditional", lem: "speculate_conditional_success"} : unit -> bool effect {exmem}

val load_reservation = {ocaml: "Platform.load_reservation", interpreter: "Platform.load_reservation", c: "load_reservation", lem: "load_reservation"} : xlenbits -> unit
val match_reservation = {ocaml: "Platform.match_reservation", interpreter: "Platform.match_reservation", lem: "match_reservation", c: "match_reservation"} : xlenbits -> bool
val cancel_reservation = {ocaml: "Platform.cancel_reservation", interpreter: "Platform.cancel_reservation", c: "cancel_reservation", lem: "cancel_reservation"} : unit -> unit

/* Exception delegation: given an exception and the privilege at which
 * it occured, returns the privilege at which it should be handled.
 */
function exception_delegatee(e : ExceptionType, p : Privilege) -> Privilege = {
  let idx   = num_of_ExceptionType(e);
  let super = bit_to_bool(medeleg.bits()[idx]);
  /* if S-mode is absent, medeleg delegates to U-mode if 'N' is supported. */
  let user  = if   haveSupMode()
              then super & haveNExt() & bit_to_bool(sedeleg.bits()[idx])
              else super & haveNExt();
  let deleg = if      haveUsrMode() & user  then User
              else if haveSupMode() & super then Supervisor
              else                               Machine;
  /* We cannot transition to a less-privileged mode. */
  if   privLevel_to_bits(deleg) <_u privLevel_to_bits(p)
  then p else deleg
}

/* Interrupts are prioritized in privilege order, and for each
 * privilege, in the order: external, software, timers.
 */
function findPendingInterrupt(ip : xlenbits) -> option(InterruptType) = {
  let ip = Mk_Minterrupts(ip);
  if      ip.MEI() == 0b1 then Some(I_M_External)
  else if ip.MSI() == 0b1 then Some(I_M_Software)
  else if ip.MTI() == 0b1 then Some(I_M_Timer)
  else if ip.SEI() == 0b1 then Some(I_S_External)
  else if ip.SSI() == 0b1 then Some(I_S_Software)
  else if ip.STI() == 0b1 then Some(I_S_Timer)
  else if ip.UEI() == 0b1 then Some(I_U_External)
  else if ip.USI() == 0b1 then Some(I_U_Software)
  else if ip.UTI() == 0b1 then Some(I_U_Timer)
  else                         None()
}

/* Process the pending interrupts xip at a privilege according to
 * the enabled flags xie and the delegation in xideleg. Return
 * either the set of pending interrupts, or the set of interrupts
 * delegated to the next lower privilege.
 */
union interrupt_set = {
  Ints_Pending   : xlenbits,
  Ints_Delegated : xlenbits,
  Ints_Empty     : unit
}
function processPending(xip : Minterrupts, xie : Minterrupts, xideleg : xlenbits,
                        priv_enabled : bool) -> interrupt_set = {
  /* interrupts that are enabled but not delegated are pending */
  let  effective_pend = xip.bits() & xie.bits() & (~ (xideleg));
  /* the others are delegated */
  let  effective_delg = xip.bits() & xideleg;
  /* we have pending interrupts if this privilege is enabled */
  if      priv_enabled & (effective_pend != EXTZ(0b0))
  then    Ints_Pending(effective_pend)
  else if effective_delg != EXTZ(0b0)
  then    Ints_Delegated(effective_delg)
  else    Ints_Empty()
}

/* Given the current privilege level, iterate over privileges to get a
 * pending set for an enabled privilege. This is only called for M/U or
 * M/S/U systems.
 *
 * We don't use the lowered views of {xie,xip} here, since the spec
 * allows for example the M_Timer to be delegated to the U-mode.
 */
function getPendingSet(priv : Privilege) -> option((xlenbits, Privilege)) = {
  assert(haveUsrMode(), "no user mode: M/U or M/S/U system required");
  let effective_pending = mip.bits() & mie.bits();
  if  effective_pending == EXTZ(0b0) then None() /* fast path */
  else {
    /* Higher privileges than the current one are implicitly enabled,
     * while lower privileges are blocked.  An unsupported privilege is
     * considered blocked.
     */
    let mIE = priv != Machine | (priv == Machine & mstatus.MIE() == 0b1);
    let sIE = haveSupMode() & (priv == User | (priv == Supervisor & mstatus.SIE() == 0b1));
    let uIE = haveNExt() & (priv == User & mstatus.UIE() == 0b1);
    match processPending(mip, mie, mideleg.bits(), mIE) {
      Ints_Empty()      => None(),
      Ints_Pending(p)   => let r = (p, Machine) in Some(r),
      Ints_Delegated(d) =>
        if not(haveSupMode()) then {
          if uIE then let r = (d, User) in Some(r)
          else                             None()
        } else {
          /* the delegated bits are pending for S-mode */
          match processPending(Mk_Minterrupts(d), mie, sideleg.bits(), sIE) {
            Ints_Empty()      => None(),
            Ints_Pending(p)   => let r = (p, Supervisor) in Some(r),
            Ints_Delegated(d) => if   uIE
                                 then let r = (d, User) in Some(r)
                                 else None()
          }
        }
    }
  }
}

/* Examine the current interrupt state and return an interrupt to be *
 * handled (if any), and the privilege it should be handled at.
 */
function dispatchInterrupt(priv : Privilege) -> option((InterruptType, Privilege)) = {
  /* If we don't have different privilege levels, we don't need to check delegation.
   * Absence of U-mode implies absence of S-mode.
   */
  if not(haveUsrMode()) | (not(haveSupMode()) & not(haveNExt())) then {
    assert(priv == Machine, "invalid current privilege");
    let enabled_pending = mip.bits() & mie.bits();
    match findPendingInterrupt(enabled_pending) {
      Some(i) => let r = (i, Machine) in Some(r),
      None()  => None()
    }
  } else {
    match getPendingSet(priv) {
      None()      => None(),
      Some(ip, p) => match findPendingInterrupt(ip) {
                       None()  => None(),
                       Some(i) => let r = (i, p) in Some(r)
                     }
    }
  }
}

/* types of privilege transitions */

union ctl_result = {
  CTL_TRAP : sync_exception,
  CTL_SRET : unit,
  CTL_MRET : unit,
  CTL_URET : unit
}

/* trap value */

function tval(excinfo : option(xlenbits)) -> xlenbits = {
  match (excinfo) {
    Some(e) => e,
    None()  => EXTZ(0b0)
  }
}

$ifdef RVFI_DII
val rvfi_trap : unit -> unit effect {wreg}
// TODO: record rvfi_trap_data
function rvfi_trap () =
  rvfi_inst_data->rvfi_trap() = 0x01
$else
val rvfi_trap : unit -> unit
function rvfi_trap () = ()
$endif

/* handle exceptional ctl flow by updating nextPC and operating privilege */

function trap_handler(del_priv : Privilege, intr : bool, c : exc_code, pc : xlenbits, info : option(xlenbits), ext : option(ext_exception))
                     -> xlenbits = {
  rvfi_trap();
  if   get_config_print_platform()
  then print_platform("handling " ^ (if intr then "int#" else "exc#")
                      ^ BitStr(c) ^ " at priv " ^ to_str(del_priv)
                      ^ " with tval " ^ BitStr(tval(info)));

  cancel_reservation();

  match (del_priv) {
    Machine => {
       mcause->IsInterrupt() = bool_to_bits(intr);
       mcause->Cause()       = EXTZ(c);

       mstatus->MPIE() = mstatus.MIE();
       mstatus->MIE()  = 0b0;
       mstatus->MPP()  = privLevel_to_bits(cur_privilege);
       mtval           = tval(info);
       mepc            = pc;

       cur_privilege   = del_priv;

       handle_trap_extension(del_priv, pc, ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));

       prepare_trap_vector(del_priv, mcause)
    },
    Supervisor => {
       assert (haveSupMode(), "no supervisor mode present for delegation");

       scause->IsInterrupt() = bool_to_bits(intr);
       scause->Cause()       = EXTZ(c);

       mstatus->SPIE() = mstatus.SIE();
       mstatus->SIE()  = 0b0;
       mstatus->SPP()  = match cur_privilege {
                           User => 0b0,
                           Supervisor => 0b1,
                           Machine => internal_error(__FILE__, __LINE__, "invalid privilege for s-mode trap")
                         };
       stval           = tval(info);
       sepc            = pc;

       cur_privilege   = del_priv;

       handle_trap_extension(del_priv, pc, ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));

       prepare_trap_vector(del_priv, scause)
    },
    User => {
       assert(haveUsrMode(), "no user mode present for delegation");

       ucause->IsInterrupt() = bool_to_bits(intr);
       ucause->Cause()       = EXTZ(c);

       mstatus->UPIE() = mstatus.UIE();
       mstatus->UIE()  = 0b0;
       utval           = tval(info);
       uepc            = pc;

       cur_privilege   = del_priv;

       handle_trap_extension(del_priv, pc, ext);

       if   get_config_print_reg()
       then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));

       prepare_trap_vector(del_priv, ucause)
    }
  };
}

function exception_handler(cur_priv : Privilege, ctl : ctl_result,
                           pc: xlenbits) -> xlenbits = {
  match (cur_priv, ctl) {
    (_, CTL_TRAP(e)) => {
      let del_priv = exception_delegatee(e.trap, cur_priv);
      if   get_config_print_platform()
      then print_platform("trapping from " ^ to_str(cur_priv) ^ " to " ^ to_str(del_priv)
                          ^ " to handle " ^ to_str(e.trap));
      trap_handler(del_priv, false, exceptionType_to_bits(e.trap), pc, e.excinfo, e.ext)
    },
    (_, CTL_MRET())  => {
      let prev_priv   = cur_privilege;
      mstatus->MIE()  = mstatus.MPIE();
      mstatus->MPIE() = 0b1;
      cur_privilege   = privLevel_of_bits(mstatus.MPP());
      mstatus->MPP()  = privLevel_to_bits(if haveUsrMode() then User else Machine);
      if   cur_privilege != Machine
      then mstatus->MPRV() = 0b0;

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv) ^ " to " ^ to_str(cur_privilege));

      cancel_reservation();
      prepare_xret_target(Machine) & pc_alignment_mask()
    },
    (_, CTL_SRET())  => {
      let prev_priv   = cur_privilege;
      mstatus->SIE()  = mstatus.SPIE();
      mstatus->SPIE() = 0b1;
      cur_privilege   = if mstatus.SPP() == 0b1 then Supervisor else User;
      mstatus->SPP()  = 0b0;
      if   cur_privilege != Machine
      then mstatus->MPRV() = 0b0;

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv)
                          ^ " to " ^ to_str(cur_privilege));

      cancel_reservation();
      prepare_xret_target(Supervisor) & pc_alignment_mask()
    },
    (_, CTL_URET())  => {
      let prev_priv   = cur_privilege;
      mstatus->UIE()  = mstatus.UPIE();
      mstatus->UPIE() = 0b1;
      cur_privilege   = User;

      if   get_config_print_reg()
      then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()));
      if   get_config_print_platform()
      then print_platform("ret-ing from " ^ to_str(prev_priv) ^ " to " ^ to_str(cur_privilege));

      cancel_reservation();
      prepare_xret_target(User) & pc_alignment_mask()
    }
  }
}

function handle_mem_exception(addr : xlenbits, e : ExceptionType) -> unit = {
  let t : sync_exception = struct { trap    = e,
                                    excinfo = Some(addr),
                                    ext     = None() } in
  set_next_pc(exception_handler(cur_privilege, CTL_TRAP(t), PC))
}

function handle_exception(e: ExceptionType) -> unit = {
  let t : sync_exception = struct { trap    = e,
                                    excinfo = None(),
                                    ext     = None() } in
  set_next_pc(exception_handler(cur_privilege, CTL_TRAP(t), PC))
}

function handle_interrupt(i : InterruptType, del_priv : Privilege) -> unit =
  set_next_pc(trap_handler(del_priv, true, interruptType_to_bits(i), PC, None(), None()))

/* state state initialization */

function init_sys() -> unit = {
  cur_privilege = Machine;

  mhartid     = EXTZ(0b0);

  misa->MXL() = arch_to_bits(if sizeof(xlen) == 32 then RV32 else RV64);
  misa->A()   = 0b1;                            /* atomics */
  misa->C()   = bool_to_bits(sys_enable_rvc()); /* RVC */
  misa->I()   = 0b1;                            /* base integer ISA */
  misa->M()   = 0b1;                            /* integer multiply/divide */
  misa->U()   = 0b1;                            /* user-mode */
  misa->S()   = 0b1;                            /* supervisor-mode */

  if   sys_enable_fdext() & sys_enable_zfinx()
  then internal_error(__FILE__, __LINE__, "F and Zfinx cannot both be enabled!");

  /* We currently support both F and D */
  misa->F()   = bool_to_bits(sys_enable_fdext());      /* single-precision */
  misa->D()   = if   sizeof(flen) >= 64
                then bool_to_bits(sys_enable_fdext())  /* double-precision */
                else 0b0;

  mstatus = set_mstatus_SXL(mstatus, misa.MXL());
  mstatus = set_mstatus_UXL(mstatus, misa.MXL());
  mstatus->SD()   = 0b0;

  /* set to little-endian mode */
  if sizeof(xlen) == 64 then {
    mstatus = Mk_Mstatus([mstatus.bits() with 37 .. 36 = 0b00])
  };
  mstatush->bits() = EXTZ(0b0);

  mip->bits()     = EXTZ(0b0);
  mie->bits()     = EXTZ(0b0);
  mideleg->bits() = EXTZ(0b0);
  medeleg->bits() = EXTZ(0b0);
  mtvec->bits()   = EXTZ(0b0);
  mcause->bits()  = EXTZ(0b0);
  mepc            = EXTZ(0b0);
  mtval           = EXTZ(0b0);
  mscratch        = EXTZ(0b0);

  mcycle          = EXTZ(0b0);
  mtime           = EXTZ(0b0);

  mcounteren->bits() = EXTZ(0b0);

  minstret           = EXTZ(0b0);
  minstret_written   = false;

  foreach (i from 0 to 28) {
    mhpmevents[i]   = sail_zeros(sizeof(xlen));
    mhpmcounters[i] = sail_zeros(64);
  };

  init_pmp();

  // log compatibility with spike
  if   get_config_print_reg()
  then print_reg("CSR mstatus <- " ^ BitStr(mstatus.bits()) ^ " (input: " ^ BitStr(EXTZ(0b0) : xlenbits) ^ ")")
}

/* memory access exceptions, defined here for use by the platform model. */

union MemoryOpResult ('a : Type) = {
  MemValue     : 'a,
  MemException : ExceptionType
}

val MemoryOpResult_add_meta : forall ('t : Type). (MemoryOpResult('t), mem_meta) -> MemoryOpResult(('t, mem_meta))
function MemoryOpResult_add_meta(r, m) = match r {
  MemValue(v)     => MemValue(v, m),
  MemException(e) => MemException(e)
}

val MemoryOpResult_drop_meta : forall ('t : Type). MemoryOpResult(('t, mem_meta)) -> MemoryOpResult('t)
function MemoryOpResult_drop_meta(r) = match r {
  MemValue(v, m)  => MemValue(v),
  MemException(e) => MemException(e)
}
