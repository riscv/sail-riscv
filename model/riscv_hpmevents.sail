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

    (0x323,  _) => mhpmevents[0],
    (0x324,  _) => mhpmevents[1],
    (0x325,  _) => mhpmevents[2],
    (0x326,  _) => mhpmevents[3],
    (0x327,  _) => mhpmevents[4],
    (0x328,  _) => mhpmevents[5],
    (0x329,  _) => mhpmevents[6],
    (0x32A,  _) => mhpmevents[7],
    (0x32B,  _) => mhpmevents[8],
    (0x32C,  _) => mhpmevents[9],
    (0x32D,  _) => mhpmevents[10],
    (0x32E,  _) => mhpmevents[11],
    (0x32F,  _) => mhpmevents[12],
    (0x330,  _) => mhpmevents[13],
    (0x331,  _) => mhpmevents[14],
    (0x332,  _) => mhpmevents[15],
    (0x333,  _) => mhpmevents[16],
    (0x334,  _) => mhpmevents[17],
    (0x335,  _) => mhpmevents[18],
    (0x336,  _) => mhpmevents[19],
    (0x337,  _) => mhpmevents[20],
    (0x338,  _) => mhpmevents[21],
    (0x339,  _) => mhpmevents[22],
    (0x33A,  _) => mhpmevents[23],
    (0x33B,  _) => mhpmevents[24],
    (0x33C,  _) => mhpmevents[25],
    (0x33D,  _) => mhpmevents[26],
    (0x33E,  _) => mhpmevents[27],
    (0x33F,  _) => mhpmevents[28],

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
    (0xB03,  _) => mhpmcounters[0][(sizeof(xlen) - 1) .. 0],
    (0xB04,  _) => mhpmcounters[1][(sizeof(xlen) - 1) .. 0],
    (0xB05,  _) => mhpmcounters[2][(sizeof(xlen) - 1) .. 0],
    (0xB06,  _) => mhpmcounters[3][(sizeof(xlen) - 1) .. 0],
    (0xB07,  _) => mhpmcounters[4][(sizeof(xlen) - 1) .. 0],
    (0xB08,  _) => mhpmcounters[5][(sizeof(xlen) - 1) .. 0],
    (0xB09,  _) => mhpmcounters[6][(sizeof(xlen) - 1) .. 0],
    (0xB0A,  _) => mhpmcounters[7][(sizeof(xlen) - 1) .. 0],
    (0xB0B,  _) => mhpmcounters[8][(sizeof(xlen) - 1) .. 0],
    (0xB0C,  _) => mhpmcounters[9][(sizeof(xlen) - 1) .. 0],
    (0xB0D,  _) => mhpmcounters[10][(sizeof(xlen) - 1) .. 0],
    (0xB0E,  _) => mhpmcounters[11][(sizeof(xlen) - 1) .. 0],
    (0xB0F,  _) => mhpmcounters[12][(sizeof(xlen) - 1) .. 0],
    (0xB10,  _) => mhpmcounters[13][(sizeof(xlen) - 1) .. 0],
    (0xB11,  _) => mhpmcounters[14][(sizeof(xlen) - 1) .. 0],
    (0xB12,  _) => mhpmcounters[15][(sizeof(xlen) - 1) .. 0],
    (0xB13,  _) => mhpmcounters[16][(sizeof(xlen) - 1) .. 0],
    (0xB14,  _) => mhpmcounters[17][(sizeof(xlen) - 1) .. 0],
    (0xB15,  _) => mhpmcounters[18][(sizeof(xlen) - 1) .. 0],
    (0xB16,  _) => mhpmcounters[19][(sizeof(xlen) - 1) .. 0],
    (0xB17,  _) => mhpmcounters[20][(sizeof(xlen) - 1) .. 0],
    (0xB18,  _) => mhpmcounters[21][(sizeof(xlen) - 1) .. 0],
    (0xB19,  _) => mhpmcounters[22][(sizeof(xlen) - 1) .. 0],
    (0xB1A,  _) => mhpmcounters[23][(sizeof(xlen) - 1) .. 0],
    (0xB1B,  _) => mhpmcounters[24][(sizeof(xlen) - 1) .. 0],
    (0xB1C,  _) => mhpmcounters[25][(sizeof(xlen) - 1) .. 0],
    (0xB1D,  _) => mhpmcounters[26][(sizeof(xlen) - 1) .. 0],
    (0xB1E,  _) => mhpmcounters[27][(sizeof(xlen) - 1) .. 0],
    (0xB1F,  _) => mhpmcounters[28][(sizeof(xlen) - 1) .. 0],

    (0xB80, 32) => mcycle[63 .. 32],
    (0xB82, 32) => minstret[63 .. 32],
    (0xB83, 32) => mhpmcounters[0][63 .. 32],
    (0xB84, 32) => mhpmcounters[1][63 .. 32],
    (0xB85, 32) => mhpmcounters[2][63 .. 32],
    (0xB86, 32) => mhpmcounters[3][63 .. 32],
    (0xB87, 32) => mhpmcounters[4][63 .. 32],
    (0xB88, 32) => mhpmcounters[5][63 .. 32],
    (0xB89, 32) => mhpmcounters[6][63 .. 32],
    (0xB8A, 32) => mhpmcounters[7][63 .. 32],
    (0xB8B, 32) => mhpmcounters[8][63 .. 32],
    (0xB8C, 32) => mhpmcounters[9][63 .. 32],
    (0xB8D, 32) => mhpmcounters[10][63 .. 32],
    (0xB8E, 32) => mhpmcounters[11][63 .. 32],
    (0xB8F, 32) => mhpmcounters[12][63 .. 32],
    (0xB90, 32) => mhpmcounters[13][63 .. 32],
    (0xB91, 32) => mhpmcounters[14][63 .. 32],
    (0xB92, 32) => mhpmcounters[15][63 .. 32],
    (0xB93, 32) => mhpmcounters[16][63 .. 32],
    (0xB94, 32) => mhpmcounters[17][63 .. 32],
    (0xB95, 32) => mhpmcounters[18][63 .. 32],
    (0xB96, 32) => mhpmcounters[19][63 .. 32],
    (0xB97, 32) => mhpmcounters[20][63 .. 32],
    (0xB98, 32) => mhpmcounters[21][63 .. 32],
    (0xB99, 32) => mhpmcounters[22][63 .. 32],
    (0xB9A, 32) => mhpmcounters[23][63 .. 32],
    (0xB9B, 32) => mhpmcounters[24][63 .. 32],
    (0xB9C, 32) => mhpmcounters[25][63 .. 32],
    (0xB9D, 32) => mhpmcounters[26][63 .. 32],
    (0xB9E, 32) => mhpmcounters[27][63 .. 32],
    (0xB9F, 32) => mhpmcounters[28][63 .. 32],

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
    (0xC03,  _) => mhpmcounters[0][(sizeof(xlen) - 1) .. 0],
    (0xC04,  _) => mhpmcounters[1][(sizeof(xlen) - 1) .. 0],
    (0xC05,  _) => mhpmcounters[2][(sizeof(xlen) - 1) .. 0],
    (0xC06,  _) => mhpmcounters[3][(sizeof(xlen) - 1) .. 0],
    (0xC07,  _) => mhpmcounters[4][(sizeof(xlen) - 1) .. 0],
    (0xC08,  _) => mhpmcounters[5][(sizeof(xlen) - 1) .. 0],
    (0xC09,  _) => mhpmcounters[6][(sizeof(xlen) - 1) .. 0],
    (0xC0A,  _) => mhpmcounters[7][(sizeof(xlen) - 1) .. 0],
    (0xC0B,  _) => mhpmcounters[8][(sizeof(xlen) - 1) .. 0],
    (0xC0C,  _) => mhpmcounters[9][(sizeof(xlen) - 1) .. 0],
    (0xC0D,  _) => mhpmcounters[10][(sizeof(xlen) - 1) .. 0],
    (0xC0E,  _) => mhpmcounters[11][(sizeof(xlen) - 1) .. 0],
    (0xC0F,  _) => mhpmcounters[12][(sizeof(xlen) - 1) .. 0],
    (0xC10,  _) => mhpmcounters[13][(sizeof(xlen) - 1) .. 0],
    (0xC11,  _) => mhpmcounters[14][(sizeof(xlen) - 1) .. 0],
    (0xC12,  _) => mhpmcounters[15][(sizeof(xlen) - 1) .. 0],
    (0xC13,  _) => mhpmcounters[16][(sizeof(xlen) - 1) .. 0],
    (0xC14,  _) => mhpmcounters[17][(sizeof(xlen) - 1) .. 0],
    (0xC15,  _) => mhpmcounters[18][(sizeof(xlen) - 1) .. 0],
    (0xC16,  _) => mhpmcounters[19][(sizeof(xlen) - 1) .. 0],
    (0xC17,  _) => mhpmcounters[20][(sizeof(xlen) - 1) .. 0],
    (0xC18,  _) => mhpmcounters[21][(sizeof(xlen) - 1) .. 0],
    (0xC19,  _) => mhpmcounters[22][(sizeof(xlen) - 1) .. 0],
    (0xC1A,  _) => mhpmcounters[23][(sizeof(xlen) - 1) .. 0],
    (0xC1B,  _) => mhpmcounters[24][(sizeof(xlen) - 1) .. 0],
    (0xC1C,  _) => mhpmcounters[25][(sizeof(xlen) - 1) .. 0],
    (0xC1D,  _) => mhpmcounters[26][(sizeof(xlen) - 1) .. 0],
    (0xC1E,  _) => mhpmcounters[27][(sizeof(xlen) - 1) .. 0],
    (0xC1F,  _) => mhpmcounters[28][(sizeof(xlen) - 1) .. 0],

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

// ==============================================================================
// Translated from C into Sail.  The C imnplementation can be found
//  on the hpm_events branch for the Sail model.  It is in the file 
//  riscv_hpmevents.c (and the associated header files).
//  In the riscv_hpmevents.c file,  the function is called riscv_write_mhpmevent()

enum model_event_id = {
//    E_not_defined = 0,          // TODO:  how to make this 0
    E_not_defined,          // TODO:  how to make this 0
    E_event_branch,
    E_event_jal,
    E_event_jalr,
    E_event_auipc,
    E_event_load,
    E_event_store,
    E_event_lr,
    E_event_sc,
    E_event_amo,
    E_event_shift,
    E_event_mulDiv,
    E_event_fp,
    E_event_fence,
    E_last
}

type mach_bits : Int = 64       // To match uint64_t in the riscv_hpmevents.c file

struct event_info = {
    // This is the event-id used by the platform software to identify
    // this event, for e.g. by writing this value to the mhpmevent
    // registers.  The model cannot support an event-id of 0.
    // plat_event_id   : mach_bits,
    plat_event_id   : xlenbits,
    // the index of the counter register mapped to this event
    // regidx          : mach_bits,
    //regidx          : int,
    regidx          : xlenbits,
    // how many times this event has been selected (i.e. if more than
    // once, then multiple counters need to be incremented, and the
    // above regidx is not useful)
    count           : int
}

//register event_map : vector(num_of_model_event_id(E_last), dec, event_info)   // TODO:  error message with this
register event_map : vector(25, dec, event_info) = [
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 24
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 23
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 22
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 21
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 20
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 19
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 18
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 17
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 16
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 15
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 14
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 13
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 12
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 11
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 10
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 09
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 08
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 07
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 06
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 05
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 04
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }, 	// 03
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },    // 02
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },    // 01
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }     // 00
]

// If there are multiple counters selected for the same event (e.g. if
// the same event selector is written to more than one hpmevent
// register), then the event_map cannot be used, and we need to use a
// slower path.
// NOTE:  DO NOT IMPLEMENT THE "slower path" FUNCTIONALITY. SIMPLY
// ITERATE THROUGH EACH INDEX.
register usable_event_map : bool

// A bitmask of unprocessed events that have occurred in this cycle.
// If we have more than 64 events, we will need multiple bitsets.
//uint64_t hpm_eventset;
//register hpm_eventset : bitvector(32, dec)
register hpm_eventset : bits(32)

infixl 7 <<
infixl 7 >>

// Events handled in and communicated from elsewhere in the simulator
val riscv_signal_event : (model_event_id) -> unit
function riscv_signal_event (id : model_event_id) = {
    hpm_eventset = hpm_eventset | (EXTZ(0x1) << num_of_model_event_id(id));
}

// Update our event map on every write to the event selector registers.
// val plat_write_mhpmevent = {c: "riscv_write_mhpmevent", ocaml: "Platform.write_mhpmevent"} : (xlenbits, xlenbits, xlenbits) -> unit
val plat_write_mhpmevent  : (xlenbits, xlenbits, xlenbits) -> unit
function plat_write_mhpmevent (regidx : xlenbits, new_event_id : xlenbits, prev_event_id : xlenbits) -> unit = {
    usable : bool = true;

    if (new_event_id != prev_event_id) then {
        foreach (eid from num_of_model_event_id(E_not_defined) to num_of_model_event_id(E_last)) {
            print_int("eid: ", eid);
            if (event_map[eid].plat_event_id != to_bits(sizeof(xlen), 0)) then {
                if (event_map[eid].plat_event_id == new_event_id) then {
                    event_map[eid].regidx = regidx;
                    event_map[eid].count = event_map[eid].count + 1;
                }
            };

            if (event_map[eid].plat_event_id == prev_event_id) then {
                event_map[eid].count = event_map[eid].count - 1;
                assert(event_map[eid].count >= 0);
            }
        };
    };

    // check whether the event map is still usable for a fast path: a
    // max of one counter per event.
    foreach (eid from num_of_model_event_id(E_not_defined) to num_of_model_event_id(E_last)) {
        if (event_map[eid].count > 1) then {
            usable = false;
        }
    };
    usable_event_map = usable;
}

/*  C implementation
void reset_platform_events(void) {
  for (int eid = 0; eid < E_last; eid++) {
    event_info *ei = &event_map[eid];
    ei->regidx = 0;
    ei->count = 0;
  }
  hpm_eventset = 0;
  usable_event_map = true;
}
*/
 
val reset_platform_events : unit -> unit
function reset_platform_events () -> unit = {
    foreach (eid from num_of_model_event_id(E_not_defined) to num_of_model_event_id(E_last)) {
        event_map[eid].regidx   = to_bits(sizeof(xlen), 0);
        event_map[eid].count    = 0;
    };

    hpm_eventset = to_bits(sizeof(xlen), 0);
    usable_event_map = true;
}

/* C implementation

static const int nregs = 29;

void increment_hpm_counter(uint64_t regidx) {
  uint64_t counterin = z_get_Counterin_bits(zmcountinhibit);
  int inhibit = 0x1 & (counterin >> (regidx + 3));
  printf("%s, %d, %s:\n", __FILE__, __LINE__, __FUNCTION__);
  if (!inhibit) {
    uint64_t *cntr = &zmhpmcounters.data[regidx];
    printf("%s, %d, %s:\n", __FILE__, __LINE__, __FUNCTION__);
    (*cntr)++;
  }
}

*/

//val increment_hpm_counter : forall ('n : Int) , (0 <= 'n <= 29) . (atom('n)) -> unit
//val increment_hpm_counter : forall ('n : Int) , (0 <= 'n <= 6) . (int('n)) -> unit
val increment_hpm_counter : forall ('n : Int) , (0 <= 'n <= 29) . (int('n)) -> unit
//val increment_hpm_counter : forall ('n : Int) , ('n <= 29) . (int('n)) -> unit

function increment_hpm_counter (regidx) -> unit =  {
    assert(regidx < 29);

//  let foobar : int('n) = 4096;    // Type error: int(4096 is not a subtype of int('n) as 4096 == 'n could not be proven
//  let foobar : int('n) = 4;
//  let foobar : 'n = 4;            // Type error: Type variable 'n in type 'n is Int rather than Type

    let inhibit_a : xlenbits = EXTZ(0x1) & (mcountinhibit.bits() >> (regidx + 3));
    let inhibit : bool = inhibit_a == EXTZ(0x1);
//  let inhibit_b : bool     = (EXTZ(0x1) & (counterin.bits() : bits(32) >> (regidx + 3))) == EXTZ(0x1);  // TODO:  Why does this not compile?

    if ( not(inhibit) ) then {
        mhpmcounters[regidx] = mhpmcounters[regidx] + 1;
    }
}

/*
static void slow_process_hpm_selector(uint64_t plat_event_id) {
  // check all selector registers
  for (uint64_t idx = 0; idx < nregs; idx++) {
    uint64_t pevid = zmhpmevents.data[idx]; // XXX: Test for RV32
    if (pevid == plat_event_id) {
      increment_hpm_counter(idx);
    }
  }
}
*/


// TODO: The number of platform events (and thus their IDs) is hardcoded.  Need 
//  a way to make this more general.
//val slow_process_hpm_selector :  forall (l'm 'n : Int) , ((0 <= 'n <= 25)  & (0 <= 'm <= 29)) . (int('n)) -> unit
//val slow_process_hpm_selector :  forall ('n : Int) , (0 <= 'n <= 6) . (int('n)) -> unit
//val slow_process_hpm_selector :  forall ('n : Int) , (0 <= 'n <= 29) . (int('n)) -> unit
//val slow_process_hpm_selector :  forall ('n : Int) , (0 <= 'n <= 29) . (bits('n)) -> unit
//val slow_process_hpm_selector :  forall ('n : Int) , (0 <= 'n <= 29) . (int('n)) -> unit
//val slow_process_hpm_selector :  forall ('n : Int) , (0 <= 'n <= 29) . (xlenbits) -> unit
val slow_process_hpm_selector :                                        (xlenbits) -> unit

function slow_process_hpm_selector (plat_event_id) -> unit = {
    let nregs : int = 29;
//  idx : 'm        = 0;
    idx : int       = 0;
//    let plat_event_id_int : int('n) = plat_event_id;

    foreach (idx from 0 to (nregs - 1)) {
        assert(idx < 29);
//        let pevid : int('n) = mhpmevents[idx];
//        let pevid : int('n) = mhpmevents[idx];
//      let a1    : bits(32) = to_bits(32, mhpmevents[idx]);        // nope
        let a1    : bits(32) = mhpmevents[idx];                   // compiles
//      let pevid : int('n)  = mhpmevents[idx][('n - 1) .. 0];
//      let pevid : int('n)  = a1['n .. 0];
//      let pevid : int('n)  = a1[('n - 1) .. 0];
//      let pevid : int('n)  = 0;                                   // int(0) is not a subtype of int('n)
//        let pevid : int      = 0;
//        let pevid : int('n) = mhpmevents[idx];                // mhpmevents[i] is type xlenbits (which is bits(xlen) )
        let pevid : xlenbits = mhpmevents[idx];                // mhpmevents[i] is type xlenbits (which is bits(xlen) )

        if (pevid == plat_event_id) then {
//        if (pevid == plat_event_id_int) then {
            increment_hpm_counter(idx);
        }

    };
}



/*
void process_hpm_events(void) {
  uint64_t acc = hpm_eventset;

  for (int eid = 0; eid < E_last; eid++) {
//    if (acc & 0x1) {
    if ( (acc >> eid) & 0x1) {
      event_info *ei = &event_map[eid];
      if (ei->plat_event_id == 0) continue;
      if (usable_event_map) {
        if (ei->count) increment_hpm_counter(ei->regidx);
      } else {
        slow_process_hpm_selector(ei->plat_event_id);
      }
    }
    acc >>= 1;
  }
  hpm_eventset = 0;
}
*/

val process_hpm_events : forall ('n : Int), (0 <= 'n <= 29) . (unit) -> unit 
function process_hpm_events (unit) -> unit = {
    acc : bits(32) = hpm_eventset;
    
    foreach (eid from num_of_model_event_id(E_not_defined) to num_of_model_event_id(E_last)) {
        tmp : bits(32) = (acc >> eid) & EXTZ(0x1);      // TODO:  FIX THIS!!
        if ( tmp == EXTZ(32, 0x1)) then {               // TODO:  FIX THIS!!
            if (event_map[eid].plat_event_id == EXTZ(0x0)) then {
                /* Do nothing */
                unit;
            } else {
                if (usable_event_map) then {
                    if (event_map[eid].count > 0) then {
//                        increment_hpm_counter(event_map[eid].regidx);
                        match event_map[eid].regidx {
                            0x00000000   => increment_hpm_counter(0),       // yes
                            0x00000001   => increment_hpm_counter(1),
                            0x00000002   => increment_hpm_counter(2),
                            0x00000003   => increment_hpm_counter(3),
                            0x00000004   => increment_hpm_counter(4),
                            0x00000005   => increment_hpm_counter(5),
                            0x00000006   => increment_hpm_counter(6),
                            0x00000007   => increment_hpm_counter(7),
                            0x00000008   => increment_hpm_counter(8),
                            0x00000009   => increment_hpm_counter(9),
                            0x0000000a   => increment_hpm_counter(10),
                            0x0000000b   => increment_hpm_counter(11),
                            0x0000000c   => increment_hpm_counter(12),
                            0x0000000d   => increment_hpm_counter(13),
                            0x0000000e   => increment_hpm_counter(14),
                            0x0000000f   => increment_hpm_counter(15),

                            0x00000010   => increment_hpm_counter(16),       // yes
                            0x00000011   => increment_hpm_counter(17),
                            0x00000012   => increment_hpm_counter(18),
                            0x00000013   => increment_hpm_counter(19),
                            0x00000014   => increment_hpm_counter(20),
                            0x00000015   => increment_hpm_counter(21),
                            0x00000016   => increment_hpm_counter(22),
                            0x00000017   => increment_hpm_counter(23),
                            0x00000018   => increment_hpm_counter(24),
                            0x00000019   => increment_hpm_counter(25),
                            0x0000001a   => increment_hpm_counter(26),
                            0x0000001b   => increment_hpm_counter(27),
                            0x0000001c   => increment_hpm_counter(28),
                            0x0000001d   => increment_hpm_counter(29),

                            _           => { print(__FILE__); print(", "); print(__LOC__); print(": "); print("Error: internal error\n"); }
                        }



                    } else {
//                        slow_process_hpm_selector(event_map[eid].plat_event_id);
                        match event_map[eid].regidx {
//                          0x00000000  => slow_process_hpm_selector(0x0),              // nope.
//                          0x00000000  => slow_process_hpm_selector(0x00000000),       // yes
                            0x00000000  => slow_process_hpm_selector(EXTZ(0x0)),        // yes
                            0x00000001  => slow_process_hpm_selector(EXTZ(0x1)),
                            0x00000002  => slow_process_hpm_selector(EXTZ(0x2)),
                            0x00000003  => slow_process_hpm_selector(EXTZ(0x3)),
                            0x00000004  => slow_process_hpm_selector(EXTZ(0x4)),
                            0x00000005  => slow_process_hpm_selector(EXTZ(0x5)),
                            0x00000006  => slow_process_hpm_selector(EXTZ(0x6)),
                            0x00000007  => slow_process_hpm_selector(EXTZ(0x7)),
                            0x00000008  => slow_process_hpm_selector(EXTZ(0x8)),
                            0x00000009  => slow_process_hpm_selector(EXTZ(0x9)),
                            0x0000000a  => slow_process_hpm_selector(EXTZ(0xa)),
                            0x0000000b  => slow_process_hpm_selector(EXTZ(0xb)),
                            0x0000000c  => slow_process_hpm_selector(EXTZ(0xc)),
                            0x0000000d  => slow_process_hpm_selector(EXTZ(0xd)),
                            0x0000000e  => slow_process_hpm_selector(EXTZ(0xe)),
                            0x0000000f  => slow_process_hpm_selector(EXTZ(0xf)),

                            0x00000010  => slow_process_hpm_selector(EXTZ(0x10)),
                            0x00000011  => slow_process_hpm_selector(EXTZ(0x11)),
                            0x00000012  => slow_process_hpm_selector(EXTZ(0x12)),
                            0x00000013  => slow_process_hpm_selector(EXTZ(0x13)),
                            0x00000014  => slow_process_hpm_selector(EXTZ(0x14)),
                            0x00000015  => slow_process_hpm_selector(EXTZ(0x15)),
                            0x00000016  => slow_process_hpm_selector(EXTZ(0x16)),
                            0x00000017  => slow_process_hpm_selector(EXTZ(0x17)),
                            0x00000018  => slow_process_hpm_selector(EXTZ(0x18)),
                            0x00000019  => slow_process_hpm_selector(EXTZ(0x19)),
                            0x0000001a  => slow_process_hpm_selector(EXTZ(0x1a)),
                            0x0000001b  => slow_process_hpm_selector(EXTZ(0x1b)),
                            0x0000001c  => slow_process_hpm_selector(EXTZ(0x1c)),
                            0x0000001d  => slow_process_hpm_selector(EXTZ(0x1d)),
                            0x0000001e  => slow_process_hpm_selector(EXTZ(0x1e)),
                            0x0000001f  => slow_process_hpm_selector(EXTZ(0x1f)),

                            _           => { print(__FILE__); print(", "); print(__LOC__); print(": "); print("Error: internal error\n"); }
                        }
                    }
                }
            }
        }
    };
    hpm_eventset = EXTZ(0x0);
}




// ==============================================================================


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
    (0x323,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 0), value, mhpmevents[0]); mhpmevents[0] = value; Some(value) },
    (0x324,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 1), value, mhpmevents[1]); mhpmevents[1] = value; Some(value) },
    (0x325,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 2), value, mhpmevents[2]); mhpmevents[2] = value; Some(value) },
    (0x326,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 3), value, mhpmevents[3]); mhpmevents[3] = value; Some(value) },
    (0x327,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 4), value, mhpmevents[4]); mhpmevents[4] = value; Some(value) },
    (0x328,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 5), value, mhpmevents[5]); mhpmevents[5] = value; Some(value) },
    (0x329,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 6), value, mhpmevents[6]); mhpmevents[6] = value; Some(value) },
    (0x32A,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 7), value, mhpmevents[7]); mhpmevents[7] = value; Some(value) },
    (0x32B,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 8), value, mhpmevents[8]); mhpmevents[8] = value; Some(value) },
    (0x32C,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 9), value, mhpmevents[9]); mhpmevents[9] = value; Some(value) },
    (0x32D,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 10), value, mhpmevents[10]); mhpmevents[10] = value; Some(value) },
    (0x32E,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 11), value, mhpmevents[11]); mhpmevents[11] = value; Some(value) },
    (0x32F,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 12), value, mhpmevents[12]); mhpmevents[12] = value; Some(value) },
    (0x330,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 13), value, mhpmevents[13]); mhpmevents[13] = value; Some(value) },
    (0x331,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 14), value, mhpmevents[14]); mhpmevents[14] = value; Some(value) },
    (0x332,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 15), value, mhpmevents[15]); mhpmevents[15] = value; Some(value) },
    (0x333,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 16), value, mhpmevents[16]); mhpmevents[16] = value; Some(value) },
    (0x334,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 17), value, mhpmevents[17]); mhpmevents[17] = value; Some(value) },
    (0x335,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 18), value, mhpmevents[18]); mhpmevents[18] = value; Some(value) },
    (0x336,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 19), value, mhpmevents[19]); mhpmevents[19] = value; Some(value) },
    (0x337,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 20), value, mhpmevents[10]); mhpmevents[20] = value; Some(value) },
    (0x338,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 21), value, mhpmevents[21]); mhpmevents[21] = value; Some(value) },
    (0x339,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 22), value, mhpmevents[22]); mhpmevents[22] = value; Some(value) },
    (0x33A,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 23), value, mhpmevents[23]); mhpmevents[23] = value; Some(value) },
    (0x33B,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 24), value, mhpmevents[24]); mhpmevents[24] = value; Some(value) },
    (0x33C,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 25), value, mhpmevents[25]); mhpmevents[25] = value; Some(value) },
    (0x33D,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 26), value, mhpmevents[26]); mhpmevents[26] = value; Some(value) },
    (0x33E,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 27), value, mhpmevents[27]); mhpmevents[27] = value; Some(value) },
    (0x33F,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 28), value, mhpmevents[28]); mhpmevents[28] = value; Some(value) },

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
    (0xB02,  _) => { minstret[(sizeof(xlen) - 1) .. 0] = value; minstret_written = true; Some(value) },
    (0xB03,  _) => { mhpmcounters[0][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB04,  _) => { mhpmcounters[1][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB05,  _) => { mhpmcounters[2][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB06,  _) => { mhpmcounters[3][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB07,  _) => { mhpmcounters[4][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB08,  _) => { mhpmcounters[5][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB09,  _) => { mhpmcounters[6][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0A,  _) => { mhpmcounters[7][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0B,  _) => { mhpmcounters[8][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0C,  _) => { mhpmcounters[9][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0D,  _) => { mhpmcounters[10][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0E,  _) => { mhpmcounters[11][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0F,  _) => { mhpmcounters[12][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB10,  _) => { mhpmcounters[13][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB11,  _) => { mhpmcounters[14][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB12,  _) => { mhpmcounters[15][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB13,  _) => { mhpmcounters[16][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB14,  _) => { mhpmcounters[17][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB15,  _) => { mhpmcounters[18][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB16,  _) => { mhpmcounters[19][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB17,  _) => { mhpmcounters[20][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB18,  _) => { mhpmcounters[21][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB19,  _) => { mhpmcounters[22][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1A,  _) => { mhpmcounters[23][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1B,  _) => { mhpmcounters[24][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1C,  _) => { mhpmcounters[25][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1D,  _) => { mhpmcounters[26][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1E,  _) => { mhpmcounters[27][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1F,  _) => { mhpmcounters[28][(sizeof(xlen) - 1) .. 0] = value; Some(value) },

    (0xB80, 32) => { mcycle[63 .. 32] = value; Some(value) },
    (0xB82, 32) => { minstret[63 .. 32] = value; minstret_written = true; Some(value) },
    (0xB83, 32) => { mhpmcounters[0][63 .. 32] = value; Some(value) },
    (0xB84, 32) => { mhpmcounters[1][63 .. 32] = value; Some(value) },
    (0xB85, 32) => { mhpmcounters[2][63 .. 32] = value; Some(value) },
    (0xB86, 32) => { mhpmcounters[3][63 .. 32] = value; Some(value) },
    (0xB87, 32) => { mhpmcounters[4][63 .. 32] = value; Some(value) },
    (0xB88, 32) => { mhpmcounters[5][63 .. 32] = value; Some(value) },
    (0xB89, 32) => { mhpmcounters[6][63 .. 32] = value; Some(value) },
    (0xB8A, 32) => { mhpmcounters[7][63 .. 32] = value; Some(value) },
    (0xB8B, 32) => { mhpmcounters[8][63 .. 32] = value; Some(value) },
    (0xB8C, 32) => { mhpmcounters[9][63 .. 32] = value; Some(value) },
    (0xB8D, 32) => { mhpmcounters[10][63 .. 32] = value; Some(value) },
    (0xB8E, 32) => { mhpmcounters[11][63 .. 32] = value; Some(value) },
    (0xB8F, 32) => { mhpmcounters[12][63 .. 32] = value; Some(value) },
    (0xB90, 32) => { mhpmcounters[13][63 .. 32] = value; Some(value) },
    (0xB91, 32) => { mhpmcounters[14][63 .. 32] = value; Some(value) },
    (0xB92, 32) => { mhpmcounters[15][63 .. 32] = value; Some(value) },
    (0xB93, 32) => { mhpmcounters[16][63 .. 32] = value; Some(value) },
    (0xB94, 32) => { mhpmcounters[17][63 .. 32] = value; Some(value) },
    (0xB95, 32) => { mhpmcounters[18][63 .. 32] = value; Some(value) },
    (0xB96, 32) => { mhpmcounters[19][63 .. 32] = value; Some(value) },
    (0xB97, 32) => { mhpmcounters[20][63 .. 32] = value; Some(value) },
    (0xB98, 32) => { mhpmcounters[21][63 .. 32] = value; Some(value) },
    (0xB99, 32) => { mhpmcounters[22][63 .. 32] = value; Some(value) },
    (0xB9A, 32) => { mhpmcounters[23][63 .. 32] = value; Some(value) },
    (0xB9B, 32) => { mhpmcounters[24][63 .. 32] = value; Some(value) },
    (0xB9C, 32) => { mhpmcounters[25][63 .. 32] = value; Some(value) },
    (0xB9D, 32) => { mhpmcounters[26][63 .. 32] = value; Some(value) },
    (0xB9E, 32) => { mhpmcounters[27][63 .. 32] = value; Some(value) },
    (0xB9F, 32) => { mhpmcounters[28][63 .. 32] = value; Some(value) },

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
