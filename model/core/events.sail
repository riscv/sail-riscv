// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Types for events supported by the model.

enum Event = {
  EV_FENCE,
  EV_TLB_MISS,
  EV_MISALIGNED_LOAD_EXCEPTION,
  EV_MISALIGNED_STORE_EXCEPTION,
}

mapping event_name : Event <-> string = {
  EV_FENCE                      <-> "fence",
  EV_TLB_MISS                   <-> "TLB miss",
  EV_MISALIGNED_LOAD_EXCEPTION  <-> "misaligned load exception",
  EV_MISALIGNED_STORE_EXCEPTION <-> "misaligned store exception",
}

// For C++.
function name_of_event(event : Event) -> string = event_name(event)

val event_callback = impure {cpp: "event_callback", c: "event_callback"} : (Event, Privilege) -> unit

function generate_event(event : Event) -> unit =
  event_callback(event, cur_privilege)

function generate_trap_event(trap : TrapCause) -> unit = {
  match trap {
    Exception(struct ExceptionContext { trap = E_Load_Addr_Align(), _ }) => generate_event(EV_MISALIGNED_LOAD_EXCEPTION),
    Exception(struct ExceptionContext { trap = E_SAMO_Addr_Align(), _ }) => generate_event(EV_MISALIGNED_STORE_EXCEPTION),
    _                                                                    => (),
  }
}

// This is defined here and not in `platform_config.sail` since it needs `types.sail`.

struct event_selector = {
  event    : Event,
  selector : bits(64),  // The value that should be in the event field of an `hpmeventx` CSR to select this event.
}

let platform_event_selectors : list(event_selector) = config platform.event_selectors

// Selector utilities

function event_selector_width() -> range(1, 64) =
  plat_hpmevent_width_bits

function selector_value(event_code : bits(64)) -> bits(64) =
  zero_extend(event_code[plat_hpmevent_width_bits - 1 .. 0])

// The event dispatch function.
val dispatch_events = impure {cpp : "dispatch_events"} : unit -> unit
function dispatch_events() -> unit = ()
