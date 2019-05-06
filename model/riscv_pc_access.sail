/* accessors for default architectural addresses, for use from within instructions */
/* FIXME: see note in cheri_addr_checks.sail */

val get_next_pc : unit -> xlenbits effect {rreg}
function get_next_pc() = nextPC

val set_next_pc : xlenbits -> unit effect {wreg}
function set_next_pc(pc) = {
  nextPC = pc
}

val tick_pc : unit -> unit effect {rreg, wreg}
function tick_pc() = {
  PC = nextPC
}
