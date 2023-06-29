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

// ==============================================================================
// The following was taken from riscv_hpmevents_impl.h

struct riscv_hpm_event = {
    // This is a model internal event-id, used to identify the model
    // supported events.
    event           : model_event_id,

    // This is the event-id used by the platform software to identify
    // this event, for e.g. by writing this value to the mhpmevent
    // registers.  The model cannot support an event-id of 0.
    //
    // The data type of plat_event_id is xlenbits.  This is because it is
    //  the value that will be written to the mhpmevent register,  which
    //  xlenbits wide.

    plat_event_id   : xlenbits
}

// TODO:  This needs to be configured dynamically at initialization time, and
//          it needs to be done from a RISCV Config structure
//register platform_events : vector(30, dec, riscv_hpm_event) = [
register platform_events : vector(14, dec, riscv_hpm_event) = [
//register platform_events : vector(14, inc, riscv_hpm_event) = [
    struct { event = E_last,          plat_event_id = to_bits(sizeof(xlen),  0 ) },   // 0        // 14       // This should be the last entry.
//  struct { event = E_event_branch,  plat_event_id = to_bits(sizeof(xlen),  15 ) },  // 29       // 1
//  struct { event = E_event_jal,     plat_event_id = to_bits(sizeof(xlen),  14 ) },  // 28       // 2
//  struct { event = E_event_jalr,    plat_event_id = to_bits(sizeof(xlen),  13 ) },  // 27       // 3
//  struct { event = E_event_auipc,   plat_event_id = to_bits(sizeof(xlen),  12 ) },  // 26       // 4
//  struct { event = E_event_load,    plat_event_id = to_bits(sizeof(xlen),  11 ) },  // 25       // 5
//  struct { event = E_event_store,   plat_event_id = to_bits(sizeof(xlen),  10 ) },  // 24       // 6
//  struct { event = E_event_lr,      plat_event_id = to_bits(sizeof(xlen),  9  ) },  // 23       // 7
//  struct { event = E_event_sc,      plat_event_id = to_bits(sizeof(xlen),  8  ) }, // 22       // 8
//  struct { event = E_event_amo,     plat_event_id = to_bits(sizeof(xlen),  7  ) }, // 21       // 9
//  struct { event = E_event_shift,   plat_event_id = to_bits(sizeof(xlen),  6  ) }, // 20       // 10
//  struct { event = E_event_mulDiv,  plat_event_id = to_bits(sizeof(xlen),  5  ) }, // 19       // 11
//  struct { event = E_event_fp,      plat_event_id = to_bits(sizeof(xlen),  4  ) }, // 18       // 12
//  struct { event = E_event_fence,   plat_event_id = to_bits(sizeof(xlen),  3  ) }  // 17       // 13
    struct { event = E_event_branch,  plat_event_id = to_bits(sizeof(xlen),  3  ) },  // 29       // 1
    struct { event = E_event_jal,     plat_event_id = to_bits(sizeof(xlen),  4  ) },  // 28       // 2
    struct { event = E_event_jalr,    plat_event_id = to_bits(sizeof(xlen),  5  ) },  // 27       // 3
    struct { event = E_event_auipc,   plat_event_id = to_bits(sizeof(xlen),  6  ) },  // 26       // 4
    struct { event = E_event_load,    plat_event_id = to_bits(sizeof(xlen),  7  ) },  // 25       // 5
    struct { event = E_event_store,   plat_event_id = to_bits(sizeof(xlen),  8  ) },  // 24       // 6
    struct { event = E_event_lr,      plat_event_id = to_bits(sizeof(xlen),  9  ) },  // 23       // 7
    struct { event = E_event_sc,      plat_event_id = to_bits(sizeof(xlen),  10 ) }, // 22       // 8
    struct { event = E_event_amo,     plat_event_id = to_bits(sizeof(xlen),  11 ) }, // 21       // 9
    struct { event = E_event_shift,   plat_event_id = to_bits(sizeof(xlen),  12 ) }, // 20       // 10
    struct { event = E_event_mulDiv,  plat_event_id = to_bits(sizeof(xlen),  13 ) }, // 19       // 11
    struct { event = E_event_fp,      plat_event_id = to_bits(sizeof(xlen),  14 ) }, // 18       // 12
    struct { event = E_event_fence,   plat_event_id = to_bits(sizeof(xlen),  18 ) }  // 17       // 13
//  struct { event = E_not_defined,   plat_event_id = 16 }, // 16
//  struct { event = E_not_defined,   plat_event_id = 17 }, // 15
//  struct { event = E_event_fence,   plat_event_id = 18 }, // 14
//  struct { event = E_not_defined,   plat_event_id = 19 }, // 13
//  struct { event = E_not_defined,   plat_event_id = 20 }, // 12
//  struct { event = E_not_defined,   plat_event_id = 21 }, // 11
//  struct { event = E_not_defined,   plat_event_id = 22 }, // 10
//  struct { event = E_not_defined,   plat_event_id = 23 }, // 9
//  struct { event = E_not_defined,   plat_event_id = 24 }, // 8 
//  struct { event = E_not_defined,   plat_event_id = 25 }, // 7
//  struct { event = E_not_defined,   plat_event_id = 26 }, // 6
//  struct { event = E_not_defined,   plat_event_id = 27 }, // 5
//  struct { event = E_not_defined,   plat_event_id = 28 }, // 4
//  struct { event = E_not_defined,   plat_event_id = 29 }, // 3
//  struct { event = E_not_defined,   plat_event_id = 30 }, // 2
//  struct { event = E_not_defined,   plat_event_id = 31 }, // 1
]


// ==============================================================================

val print_event_map : (unit) -> unit


// ==============================================================================
// The following was taken from riscv_events_example.c


// ==============================================================================

type mach_bits : Int = 64       // To match uint64_t in the riscv_hpmevents.c file

struct event_info = {
    // This is the event-id used by the platform software to identify
    // this event, for e.g. by writing this value to the mhpmevent
    // registers.  The model cannot support an event-id of 0.
    // plat_event_id   : mach_bits,
    plat_event_id   : xlenbits,
    // plat_event_id   : range(0,63),
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
//register event_map : vector(25, dec, event_info) = [
register event_map : vector(16, dec, event_info) = [
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 24
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 23
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 22
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 21
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 20
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 19
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 18
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 17
//  struct { plat_event_id = to_bits(sizeof(xlen), 0), regidx = to_bits(sizeof(xlen), 0), count = 0 },  // 16
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
        foreach (eid from 0 to (length(event_map) - 1) ) {
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
    foreach (eid from 0 to (length(event_map) - 1) ) {
        if (event_map[eid].count > 1) then {
            usable = false;
        }
    };
    usable_event_map = usable;
}


val sail_init_platform_events : (unit) -> unit
function sail_init_platform_events ( u ) = {
    trace(__FILE__, __LINE__, "sail_init_platform_events()");
    hpm_eventset = to_bits(sizeof(xlen), 0);
    usable_event_map = true;
//  events : vector(14, dec, riscv_hpm_event) = platform_events;

    foreach (emid from 0 to (length(event_map) - 1)) {
        event_map[emid].plat_event_id   = to_bits(sizeof(xlen), 0); 
        event_map[emid].regidx          = to_bits(sizeof(xlen), 0);
        event_map[emid].count           = 0;
    };

    event_cnt : int = 0;
    trace(__FILE__, __LINE__, "length(platform_events): " ^ string_of_int(length(platform_events)) );
//  foreach( i from 0 to (length(platform_events) - 1))  {      // Do not look at last item
//  foreach( i from 0 to (length(platform_events) - 2))  {      // Do not look at last item
//  foreach( i from (length(platform_events) - 1) to 1)  {      // Do not look at last item     // Doesn't work;  does not decrement.
    foreach( i from 0 to (length(platform_events) - 2))  {      // Do not look at last item
        assert(event_cnt < 64);
        assert( i < 30);
        trace(__FILE__, __LINE__, "platform_events[" ^ string_of_int(i) ^ "].plat_event_id: " ^ string_of_bits(platform_events[i].plat_event_id) );
        assert(platform_events[i].plat_event_id != to_bits(sizeof(xlen), 0));
        assert( (unsigned(platform_events[i].plat_event_id) >= 1) & ( unsigned(platform_events[i].plat_event_id) < 32 ) );
        // TODO:  This is not right.
        let jb : bits(4)     = platform_events[i].plat_event_id[3..0];
        let j : range(0,15)  = unsigned(jb);

        event_map[j].plat_event_id = platform_events[i].plat_event_id;
        event_cnt = event_cnt + 1;
    };
    print_event_map();
}

function print_event_map (unit) = {
    print("emid:    plat_event_id:      regidx:       count:");
    foreach (emid from 0 to (length(event_map) - 1)) {
        print(string_of_int(emid) ^ "        " ^ string_of_bits(event_map[emid].plat_event_id) ^ "        " ^ string_of_bits(event_map[emid].regidx) ^ "         " ^ string_of_int(event_map[emid].count) );
    };

}

val reset_platform_events : unit -> unit
function reset_platform_events () -> unit = {
    foreach (eid from num_of_model_event_id(E_not_defined) to num_of_model_event_id(E_last)) {
        event_map[eid].regidx   = to_bits(sizeof(xlen), 0);
        event_map[eid].count    = 0;
    };

    hpm_eventset = to_bits(sizeof(xlen), 0);
    usable_event_map = true;
}

val increment_hpm_counter : forall ('n : Int) , (0 <= 'n <  29) . (int('n)) -> unit

function increment_hpm_counter (regidx) -> unit =  {
    assert(regidx <  29);

    trace(__FILE__, __LINE__, "increment_hpm_counter, regidx: " ^ string_of_int(regidx) );

    let inhibit_a : xlenbits = EXTZ(0x1) & (mcountinhibit.bits() >> (regidx + 3));
    let inhibit : bool = inhibit_a == EXTZ(0x1);
//  let inhibit : bool     = ( (EXTZ(sizeof(xlen),0x1) ) & (counterin.bits() : bits(32) >> (regidx + 3))) == EXTZ(0x1);  // TODO:  Why does this not compile?

    if ( not(inhibit) ) then {
        mhpmcounters[regidx] = mhpmcounters[regidx] + 1;
    }
}


// TODO: The number of platform events (and thus their IDs) is hardcoded.  Need 
//  a way to make this more general.

val slow_process_hpm_selector : (xlenbits) -> unit

function slow_process_hpm_selector (plat_event_id) -> unit = {
    let nregs : int = 29;
    idx : int       = 0;

    trace(__FILE__, __LINE__, "slow_process_hpm_selector(), plat_event_id: " ^ string_of_bits(plat_event_id));

    foreach (idx from 0 to (nregs - 1)) {
        assert(idx < 29);
        let pevid : xlenbits = mhpmevents[idx];                // mhpmevents[i] is type xlenbits (which is bits(xlen) )

        if (pevid == plat_event_id) then {
            increment_hpm_counter(idx);
        }

    };
}

val sail_process_hpm_events : (unit) -> unit 
function sail_process_hpm_events (unit) -> unit = {
    acc : bits(32) = hpm_eventset;

    trace(__FILE__, __LINE__, "sail_process_hpm_events(): hpm_eventset: " ^ string_of_bits(hpm_eventset) );
    
    foreach (eid from 0 to (length(event_map) - 1)      ) {
        trace(__FILE__, __LINE__, "eid: " ^ string_of_int(eid));
        tmp : bits(32) = (acc >> eid) & EXTZ(0x1);      // TODO:  FIX THIS!!
//      if ( (acc >> eid) & EXTZ(0x1) == EXTZ(32, 0x1)) then {      // TODO:  why doesn't this compile
        if ( tmp == EXTZ(32, 0x1)) then {               // TODO:  FIX THIS!!
            if (event_map[eid].plat_event_id == EXTZ(0x0)) then {
                /* Do nothing */
                trace(__FILE__, __LINE__, "");
                unit;
            } else {
                if (usable_event_map) then {
                    trace(__FILE__, __LINE__, "");
                    if (event_map[eid].count > 0) then {
                        trace(__FILE__, __LINE__, "");
                        increment_hpm_counter(unsigned(event_map[eid].regidx) % 29);    // Mask off the upper unused bits
                    } else {
                        trace(__FILE__, __LINE__, "");
                        slow_process_hpm_selector(event_map[eid].plat_event_id);
                    }
                }
            }
        }
    };
    hpm_eventset = EXTZ(0x0);
}


// The following is patterned after riscv_events_example.c 

val sail_signal_platform_events : (unit) -> unit
function sail_signal_platform_events(unit) -> unit = {

    let ast = ext_decode(instruction);

    trace(__FILE__, __LINE__, to_str(ast));

    // Count types of instructions.
    match encdec(instruction) {
        UTYPE(_, _, op)         => {
            match op {
                RISCV_AUIPC         => { riscv_signal_event(E_event_auipc); trace(__FILE__, __LINE__, ""); },
                RISCV_LUI           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
            }
        },

        RISCV_JAL(_, _)         => { riscv_signal_event(E_event_jal);  trace(__FILE__, __LINE__, ""); },
        RISCV_JALR(_, _, _)     => { riscv_signal_event(E_event_jalr); trace(__FILE__, __LINE__, ""); },

        BTYPE(   _, _, op)       => {       // TODO:  Error does not print out file/line
//      BTYPE(_, _, _, op)       => {
            match op {
                RISCV_BEQ           => { riscv_signal_event(E_event_branch); trace(__FILE__, __LINE__, ""); },
                RISCV_BNE           => { riscv_signal_event(E_event_branch); trace(__FILE__, __LINE__, ""); },
                RISCV_BLT           => { riscv_signal_event(E_event_branch); trace(__FILE__, __LINE__, ""); },
                RISCV_BGE           => { riscv_signal_event(E_event_branch); trace(__FILE__, __LINE__, ""); },
                RISCV_BLTU          => { riscv_signal_event(E_event_branch); trace(__FILE__, __LINE__, ""); },
                RISCV_BGEU          => { riscv_signal_event(E_event_branch); trace(__FILE__, __LINE__, ""); },
            }

        },
        ITYPE(_, _, _, op)      => {
            match op {
                RISCV_ADDI          => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SLTI          => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SLTIU         => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_ANDI          => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_ORI           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_XORI          => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
            }
        },

        RTYPE(_, _, _, op)       => {
            match op {
                RISCV_ADD           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SLT           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SLTU          => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_AND           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_OR            => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_XOR           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SLL           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SRL           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SUB           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
                RISCV_SRA           => { riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); },
            }
        },

        LOAD(_, _, _, _, word_width, _, _)  => {
            riscv_signal_event(E_event_load); trace(__FILE__, __LINE__, "");

            /* Several other types of events might be useful to check for here:
            *   address/address-range
            *   misaligned
            *   width
            *  For now,  we're just going to count LOADs.
            */
        },

        STORE( _, _, _, word_width, _, _)  => {
            riscv_signal_event(E_event_store); trace(__FILE__, __LINE__, "");

            /* Several other types of events might be useful to check for here:
            *   address/address-range
            *   misaligned
            *   width
            *  For now,  we're just going to count STOREs.
            */
        },

        SHIFTIOP(_, _, _, op)   => {
            match op {
                RISCV_SLLI          => { riscv_signal_event(E_event_shift); trace(__FILE__, __LINE__, ""); },
                RISCV_SRLI          => { riscv_signal_event(E_event_shift); trace(__FILE__, __LINE__, ""); },
                RISCV_SRAI          => { riscv_signal_event(E_event_shift); trace(__FILE__, __LINE__, ""); },
            }
        },

        FENCE(_, _)             => { 
            riscv_signal_event(E_event_fence); trace(__FILE__, __LINE__, ""); 
        },

        FENCE_TSO(_, _)         => { 
            riscv_signal_event(E_event_fence); trace(__FILE__, __LINE__, ""); 
        },

        FENCEI()                => { 
            riscv_signal_event(E_event_fence); trace(__FILE__, __LINE__, ""); 
        },

        ECALL()                 => { 
            riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); 
        },

        MRET()                  => { 
            riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); 
        },

        SRET()                  => { 
            riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); 
        },

        EBREAK()                => { 
            riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); 
        },

        WFI()                   => { 
            riscv_signal_event(E_not_defined); trace(__FILE__, __LINE__, ""); 
        },

        SFENCE_VMA(_, _)        => { 
            riscv_signal_event(E_event_fence); trace(__FILE__, __LINE__, ""); 
        },

        _                       => print("no match")
    }

}






