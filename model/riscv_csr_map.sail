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

/* Mapping of csr addresses to their names. */

val csr_name_map : csreg <-> string

scattered mapping csr_name_map

/* user trap setup */
mapping clause csr_name_map = 0x000  <-> "ustatus"
mapping clause csr_name_map = 0x004  <-> "uie"
mapping clause csr_name_map = 0x005  <-> "utvec"
/* user trap handling */
mapping clause csr_name_map = 0x040  <-> "uscratch"
mapping clause csr_name_map = 0x041  <-> "uepc"
mapping clause csr_name_map = 0x042  <-> "ucause"
mapping clause csr_name_map = 0x043  <-> "utval"
mapping clause csr_name_map = 0x044  <-> "uip"
/* user floating-point context */
mapping clause csr_name_map = 0x001  <-> "fflags"
mapping clause csr_name_map = 0x002  <-> "frm"
mapping clause csr_name_map = 0x003  <-> "fcsr"
/* user entropy source */
mapping clause csr_name_map = 0x015  <-> "seed"
/* counter/timers */
mapping clause csr_name_map = 0xC00  <-> "cycle"
mapping clause csr_name_map = 0xC01  <-> "time"
mapping clause csr_name_map = 0xC02  <-> "instret"
mapping clause csr_name_map = 0xC80  <-> "cycleh"
mapping clause csr_name_map = 0xC81  <-> "timeh"
mapping clause csr_name_map = 0xC82  <-> "instreth"
/* TODO: other hpm counters */
/* supervisor trap setup */
mapping clause csr_name_map = 0x100  <-> "sstatus"
mapping clause csr_name_map = 0x102  <-> "sedeleg"
mapping clause csr_name_map = 0x103  <-> "sideleg"
mapping clause csr_name_map = 0x104  <-> "sie"
mapping clause csr_name_map = 0x105  <-> "stvec"
mapping clause csr_name_map = 0x106  <-> "scounteren"
/* supervisor trap handling */
mapping clause csr_name_map = 0x140  <-> "sscratch"
mapping clause csr_name_map = 0x141  <-> "sepc"
mapping clause csr_name_map = 0x142  <-> "scause"
mapping clause csr_name_map = 0x143  <-> "stval"
mapping clause csr_name_map = 0x144  <-> "sip"
/* supervisor protection and translation */
mapping clause csr_name_map = 0x180  <-> "satp"
/* machine information registers */
mapping clause csr_name_map = 0xF11  <-> "mvendorid"
mapping clause csr_name_map = 0xF12  <-> "marchid"
mapping clause csr_name_map = 0xF13  <-> "mimpid"
mapping clause csr_name_map = 0xF14  <-> "mhartid"
/* machine trap setup */
mapping clause csr_name_map = 0x300  <-> "mstatus"
mapping clause csr_name_map = 0x301  <-> "misa"
mapping clause csr_name_map = 0x302  <-> "medeleg"
mapping clause csr_name_map = 0x303  <-> "mideleg"
mapping clause csr_name_map = 0x304  <-> "mie"
mapping clause csr_name_map = 0x305  <-> "mtvec"
mapping clause csr_name_map = 0x306  <-> "mcounteren"
mapping clause csr_name_map = 0x320  <-> "mcountinhibit"
/* machine trap handling */
mapping clause csr_name_map = 0x340  <-> "mscratch"
mapping clause csr_name_map = 0x341  <-> "mepc"
mapping clause csr_name_map = 0x342  <-> "mcause"
mapping clause csr_name_map = 0x343  <-> "mtval"
mapping clause csr_name_map = 0x344  <-> "mip"
/* machine protection and translation */
mapping clause csr_name_map = 0x3A0  <-> "pmpcfg0"
mapping clause csr_name_map = 0x3A1  <-> "pmpcfg1"
mapping clause csr_name_map = 0x3A2  <-> "pmpcfg2"
mapping clause csr_name_map = 0x3A3  <-> "pmpcfg3"
mapping clause csr_name_map = 0x3B0  <-> "pmpaddr0"
mapping clause csr_name_map = 0x3B1  <-> "pmpaddr1"
mapping clause csr_name_map = 0x3B2  <-> "pmpaddr2"
mapping clause csr_name_map = 0x3B3  <-> "pmpaddr3"
mapping clause csr_name_map = 0x3B4  <-> "pmpaddr4"
mapping clause csr_name_map = 0x3B5  <-> "pmpaddr5"
mapping clause csr_name_map = 0x3B6  <-> "pmpaddr6"
mapping clause csr_name_map = 0x3B7  <-> "pmpaddr7"
mapping clause csr_name_map = 0x3B8  <-> "pmpaddr8"
mapping clause csr_name_map = 0x3B9  <-> "pmpaddr9"
mapping clause csr_name_map = 0x3BA  <-> "pmpaddr10"
mapping clause csr_name_map = 0x3BB  <-> "pmpaddr11"
mapping clause csr_name_map = 0x3BC  <-> "pmpaddr12"
mapping clause csr_name_map = 0x3BD  <-> "pmpaddr13"
mapping clause csr_name_map = 0x3BE  <-> "pmpaddr14"
mapping clause csr_name_map = 0x3BF  <-> "pmpaddr15"
/* machine counters/timers */
mapping clause csr_name_map = 0xB00  <-> "mcycle"
mapping clause csr_name_map = 0xB02  <-> "minstret"
mapping clause csr_name_map = 0xB80  <-> "mcycleh"
mapping clause csr_name_map = 0xB82  <-> "minstreth"
/* TODO: other hpm counters and events */
/* trigger/debug */
mapping clause csr_name_map = 0x7a0  <-> "tselect"
mapping clause csr_name_map = 0x7a1  <-> "tdata1"
mapping clause csr_name_map = 0x7a2  <-> "tdata2"
mapping clause csr_name_map = 0x7a3  <-> "tdata3"
/* hpm counters and events */
mapping clause csr_name_map = 0x323  <-> "mhpmevent3"
mapping clause csr_name_map = 0x324  <-> "mhpmevent4"
mapping clause csr_name_map = 0x325  <-> "mhpmevent5"
mapping clause csr_name_map = 0x326  <-> "mhpmevent6"
mapping clause csr_name_map = 0x327  <-> "mhpmevent7"
mapping clause csr_name_map = 0x328  <-> "mhpmevent8"
mapping clause csr_name_map = 0x329  <-> "mhpmevent9"
mapping clause csr_name_map = 0x32A  <-> "mhpmevent10"
mapping clause csr_name_map = 0x32B  <-> "mhpmevent11"
mapping clause csr_name_map = 0x32C  <-> "mhpmevent12"
mapping clause csr_name_map = 0x32D  <-> "mhpmevent13"
mapping clause csr_name_map = 0x32E  <-> "mhpmevent14"
mapping clause csr_name_map = 0x32F  <-> "mhpmevent15"
mapping clause csr_name_map = 0x330  <-> "mhpmevent16"
mapping clause csr_name_map = 0x331  <-> "mhpmevent17"
mapping clause csr_name_map = 0x332  <-> "mhpmevent18"
mapping clause csr_name_map = 0x333  <-> "mhpmevent19"
mapping clause csr_name_map = 0x334  <-> "mhpmevent20"
mapping clause csr_name_map = 0x335  <-> "mhpmevent21"
mapping clause csr_name_map = 0x336  <-> "mhpmevent22"
mapping clause csr_name_map = 0x337  <-> "mhpmevent23"
mapping clause csr_name_map = 0x338  <-> "mhpmevent24"
mapping clause csr_name_map = 0x339  <-> "mhpmevent25"
mapping clause csr_name_map = 0x33A  <-> "mhpmevent26"
mapping clause csr_name_map = 0x33B  <-> "mhpmevent27"
mapping clause csr_name_map = 0x33C  <-> "mhpmevent28"
mapping clause csr_name_map = 0x33D  <-> "mhpmevent29"
mapping clause csr_name_map = 0x33E  <-> "mhpmevent30"
mapping clause csr_name_map = 0x33F  <-> "mhpmevent31"

mapping clause csr_name_map = 0xB03  <-> "mhpmcounter3"
mapping clause csr_name_map = 0xB04  <-> "mhpmcounter4"
mapping clause csr_name_map = 0xB05  <-> "mhpmcounter5"
mapping clause csr_name_map = 0xB06  <-> "mhpmcounter6"
mapping clause csr_name_map = 0xB07  <-> "mhpmcounter7"
mapping clause csr_name_map = 0xB08  <-> "mhpmcounter8"
mapping clause csr_name_map = 0xB09  <-> "mhpmcounter9"
mapping clause csr_name_map = 0xB0A  <-> "mhpmcounter10"
mapping clause csr_name_map = 0xB0B  <-> "mhpmcounter11"
mapping clause csr_name_map = 0xB0C  <-> "mhpmcounter12"
mapping clause csr_name_map = 0xB0D  <-> "mhpmcounter13"
mapping clause csr_name_map = 0xB0E  <-> "mhpmcounter14"
mapping clause csr_name_map = 0xB0F  <-> "mhpmcounter15"
mapping clause csr_name_map = 0xB10  <-> "mhpmcounter16"
mapping clause csr_name_map = 0xB11  <-> "mhpmcounter17"
mapping clause csr_name_map = 0xB12  <-> "mhpmcounter18"
mapping clause csr_name_map = 0xB13  <-> "mhpmcounter19"
mapping clause csr_name_map = 0xB14  <-> "mhpmcounter20"
mapping clause csr_name_map = 0xB15  <-> "mhpmcounter21"
mapping clause csr_name_map = 0xB16  <-> "mhpmcounter22"
mapping clause csr_name_map = 0xB17  <-> "mhpmcounter23"
mapping clause csr_name_map = 0xB18  <-> "mhpmcounter24"
mapping clause csr_name_map = 0xB19  <-> "mhpmcounter25"
mapping clause csr_name_map = 0xB1A  <-> "mhpmcounter26"
mapping clause csr_name_map = 0xB1B  <-> "mhpmcounter27"
mapping clause csr_name_map = 0xB1C  <-> "mhpmcounter28"
mapping clause csr_name_map = 0xB1D  <-> "mhpmcounter29"
mapping clause csr_name_map = 0xB1E  <-> "mhpmcounter30"
mapping clause csr_name_map = 0xB1F  <-> "mhpmcounter31"

mapping clause csr_name_map = 0xB83  <-> "mhpmcounter3h"
mapping clause csr_name_map = 0xB84  <-> "mhpmcounter4h"
mapping clause csr_name_map = 0xB85  <-> "mhpmcounter5h"
mapping clause csr_name_map = 0xB86  <-> "mhpmcounter6h"
mapping clause csr_name_map = 0xB87  <-> "mhpmcounter7h"
mapping clause csr_name_map = 0xB88  <-> "mhpmcounter8h"
mapping clause csr_name_map = 0xB89  <-> "mhpmcounter9h"
mapping clause csr_name_map = 0xB8A  <-> "mhpmcounter10h"
mapping clause csr_name_map = 0xB8B  <-> "mhpmcounter11h"
mapping clause csr_name_map = 0xB8C  <-> "mhpmcounter12h"
mapping clause csr_name_map = 0xB8D  <-> "mhpmcounter13h"
mapping clause csr_name_map = 0xB8E  <-> "mhpmcounter14h"
mapping clause csr_name_map = 0xB8F  <-> "mhpmcounter15h"
mapping clause csr_name_map = 0xB90  <-> "mhpmcounter16h"
mapping clause csr_name_map = 0xB91  <-> "mhpmcounter17h"
mapping clause csr_name_map = 0xB92  <-> "mhpmcounter18h"
mapping clause csr_name_map = 0xB93  <-> "mhpmcounter19h"
mapping clause csr_name_map = 0xB94  <-> "mhpmcounter20h"
mapping clause csr_name_map = 0xB95  <-> "mhpmcounter21h"
mapping clause csr_name_map = 0xB96  <-> "mhpmcounter22h"
mapping clause csr_name_map = 0xB97  <-> "mhpmcounter23h"
mapping clause csr_name_map = 0xB98  <-> "mhpmcounter24h"
mapping clause csr_name_map = 0xB99  <-> "mhpmcounter25h"
mapping clause csr_name_map = 0xB9A  <-> "mhpmcounter26h"
mapping clause csr_name_map = 0xB9B  <-> "mhpmcounter27h"
mapping clause csr_name_map = 0xB9C  <-> "mhpmcounter28h"
mapping clause csr_name_map = 0xB9D  <-> "mhpmcounter29h"
mapping clause csr_name_map = 0xB9E  <-> "mhpmcounter30h"
mapping clause csr_name_map = 0xB9F  <-> "mhpmcounter31h"

mapping clause csr_name_map = 0xC03  <-> "hpmcounter3"
mapping clause csr_name_map = 0xC04  <-> "hpmcounter4"
mapping clause csr_name_map = 0xC05  <-> "hpmcounter5"
mapping clause csr_name_map = 0xC06  <-> "hpmcounter6"
mapping clause csr_name_map = 0xC07  <-> "hpmcounter7"
mapping clause csr_name_map = 0xC08  <-> "hpmcounter8"
mapping clause csr_name_map = 0xC09  <-> "hpmcounter9"
mapping clause csr_name_map = 0xC0A  <-> "hpmcounter10"
mapping clause csr_name_map = 0xC0B  <-> "hpmcounter11"
mapping clause csr_name_map = 0xC0C  <-> "hpmcounter12"
mapping clause csr_name_map = 0xC0D  <-> "hpmcounter13"
mapping clause csr_name_map = 0xC0E  <-> "hpmcounter14"
mapping clause csr_name_map = 0xC0F  <-> "hpmcounter15"
mapping clause csr_name_map = 0xC10  <-> "hpmcounter16"
mapping clause csr_name_map = 0xC11  <-> "hpmcounter17"
mapping clause csr_name_map = 0xC12  <-> "hpmcounter18"
mapping clause csr_name_map = 0xC13  <-> "hpmcounter19"
mapping clause csr_name_map = 0xC14  <-> "hpmcounter20"
mapping clause csr_name_map = 0xC15  <-> "hpmcounter21"
mapping clause csr_name_map = 0xC16  <-> "hpmcounter22"
mapping clause csr_name_map = 0xC17  <-> "hpmcounter23"
mapping clause csr_name_map = 0xC18  <-> "hpmcounter24"
mapping clause csr_name_map = 0xC19  <-> "hpmcounter25"
mapping clause csr_name_map = 0xC1A  <-> "hpmcounter26"
mapping clause csr_name_map = 0xC1B  <-> "hpmcounter27"
mapping clause csr_name_map = 0xC1C  <-> "hpmcounter28"
mapping clause csr_name_map = 0xC1D  <-> "hpmcounter29"
mapping clause csr_name_map = 0xC1E  <-> "hpmcounter30"
mapping clause csr_name_map = 0xC1F  <-> "hpmcounter31"

val csr_name : csreg -> string
overload to_str = {csr_name}

/* Extensions may want to add additional CSR registers to the CSR address map.
 * These scattered functions support access to such registers.
 *
 * The default implementation provides access to the CSRs added by the 'N'
 * extension.
 */


/* returns whether a CSR is defined and accessible at a given address
 * and privilege
 */
val ext_is_CSR_defined : (csreg, Privilege) -> bool effect {rreg}
scattered function ext_is_CSR_defined

/* returns the value of the CSR if it is defined */
val ext_read_CSR : csreg -> option(xlenbits) effect {rreg}
scattered function ext_read_CSR

/* returns new value (after legalisation) if the CSR is defined */
val ext_write_CSR : (csreg, xlenbits) -> option(xlenbits) effect {rreg, wreg, escape}
scattered function ext_write_CSR
