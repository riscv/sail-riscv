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
/*    William McSpadden, RISC-V International                                            */
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
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 24
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 23
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 22
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 21
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 20
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 19
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 18
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 17
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 16
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 15
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 14
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 13
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 12
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 11
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 10
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 09
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 08
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 07
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 06
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 05
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 04
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 03
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 02
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 01
    struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 }   // 00
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
                            0x00000000   => increment_hpm_counter(0),
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

                            0x00000010   => increment_hpm_counter(16),
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
                            0x00000000  => slow_process_hpm_selector(EXTZ(0x0)),
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
