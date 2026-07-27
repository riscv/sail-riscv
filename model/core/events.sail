// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Types for events supported by the model.

enum Event = {
  EV_TLB_MISS,
  EV_MISALIGNED_LOAD,
  EV_MISALIGNED_STORE,
}

mapping event_name : Event <-> string = {
  EV_TLB_MISS         <-> "TLB miss",
  EV_MISALIGNED_LOAD  <-> "misaligned load",
  EV_MISALIGNED_STORE <-> "misaligned store",
}

// For C++.
function name_of_event(e : Event) -> string = event_name(e)

val event_callback = impure {cpp: "event_callback", c: "event_callback"} : (Event, (Privilege, unit)) -> unit

function generate_event(ev : Event) -> unit =
  event_callback(ev, (cur_privilege, ()))

function generate_trap_event(trap : TrapCause) -> unit = {
  match trap {
    Exception(E_Load_Addr_Align()) => generate_event(EV_MISALIGNED_LOAD),
    Exception(E_SAMO_Addr_Align()) => generate_event(EV_MISALIGNED_STORE),
    _ => (),
  }
}

// This is defined here and not in `platform_config.sail` since it needs `types.sail`.
struct event_selector = {
  event    : Event,
  selector : bits(56),  // The value that should be in the event field of an `hpmeventx` CSR to select this event.
}

let platform_event_selectors : list(event_selector) = config platform.event_selectors
