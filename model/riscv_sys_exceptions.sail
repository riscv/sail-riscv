/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* default exception model */

type ext_exception = unit

/* Is XRET from given mode permitted by extension? */
function ext_check_xret_priv (p : Privilege) : Privilege -> bool = true
/* Called if above check fails */
function ext_fail_xret_priv () : unit -> unit = ()

function handle_trap_extension(p : Privilege, v : Virtualization, pc : xlenbits, u : option(unit)) -> unit = ()

/* used for traps and ECALL */
function prepare_trap_vector(p : Privilege, v : Virtualization, cause : Mcause) -> xlenbits = {
  let tvec : Mtvec = match p {
                       Machine    => mtvec,
                       Supervisor => match v {
                         V0 => stvec,
                         V1 => vstvec,
                       },
                       User => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
                     };
  match tvec_addr(tvec, cause) {
    Some(epc) => epc,
    None()    => internal_error(__FILE__, __LINE__, "Invalid tvec mode")
  }
}

/* xRET handling involves three functions:
 *
 * get_xret_target:     used to read the value of the xret target  (no control flow transfer)
 * set_xret_target:     used to write a value of the xret target   (no control flow transfer)
 * prepare_xret_target: used to get the value for control transfer to the xret target
 */

val get_xret_target : (Privilege, Virtualization) -> xlenbits
function get_xret_target(p, v) =
  match p {
    Machine => mepc,
    Supervisor => match v {
      V0 => sepc,
      V1 => vsepc
    },
    User => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
  }

val set_xret_target : (Privilege, Virtualization, xlenbits) -> xlenbits
function set_xret_target(p, v, value) = {
  let target = legalize_xepc(value);
  match p {
    Machine => mepc = target,
    Supervisor => match v {
      V0 => sepc = target,
      V1 => vsepc = target
    },
    User => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
  };
  target
}

val prepare_xret_target : (Privilege, Virtualization) -> xlenbits
function prepare_xret_target(p, v) =
  get_xret_target(p, v)

/* other trap-related CSRs */

function get_mtvec() -> xlenbits =
  mtvec.bits

function get_stvec() -> xlenbits =
  stvec.bits

function set_mtvec(value : xlenbits) -> xlenbits = {
  mtvec = legalize_tvec(mtvec, value);
  mtvec.bits
}

function set_stvec(value : xlenbits) -> xlenbits = {
  stvec = legalize_tvec(stvec, value);
  stvec.bits
}
