/* default exception model */

type ext_exception = unit

function handle_trap_extension(p : Privilege, pc : xlenbits, u : option(unit)) -> unit = ()

/* used for traps and ECALL */
function prepare_trap_vector(p : Privilege, cause : Mcause) -> xlenbits = {
  let tvec : Mtvec = match p {
                       Machine    => mtvec,
                       Supervisor => stvec,
                       User       => utvec
                     };
  match tvec_addr(tvec, cause) {
    Some(epc) => epc,
    None()    => internal_error("Invalid tvec mode")
  }
}

/* used for xRET */
val get_xret_target : Privilege -> xlenbits effect {rreg}
function get_xret_target(p) =
  match p {
    Machine    => mepc,
    Supervisor => sepc,
    User       => uepc
  }

val set_xret_target : (Privilege, xlenbits) -> xlenbits effect {rreg, wreg}
function set_xret_target(p, value) = {
  let target = legalize_xepc(value);
  match p {
    Machine    => mepc = target,
    Supervisor => sepc = target,
    User       => uepc = target
  };
  target
}
