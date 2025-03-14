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

function handle_trap_extension(p : Privilege, pc : xlenbits, u : option(unit)) -> unit = ()

/* used for traps and ECALL */
function prepare_trap_vector(p : Privilege, cause : Mcause) -> xlenbits = {
  let tvec : Mtvec = match p {
                       Machine    => mtvec,
                       Supervisor => stvec,
                       User       => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
                     };
  match tvec_addr(tvec, cause) {
    Some(epc) => epc,
    None()    => internal_error(__FILE__, __LINE__, "Invalid tvec mode")
  }
}

/* xRET handling involves three functions:
 *
 * get_xepc:            used to read the value of the xret target  (no control flow transfer)
 * set_xepc:            used to write a value of the xret target   (no control flow transfer)
 * prepare_xret_target: used to get the value for control transfer to the xret target
 */

val get_xepc : Privilege -> xlenbits
function get_xepc(p) =
  match p {
    Machine    => align_pc(mepc),
    Supervisor => align_pc(sepc),
    User       => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
  }

val set_xepc : (Privilege, xlenbits) -> xlenbits
function set_xepc(p, value) = {
  let target = legalize_xepc(value);
  match p {
    Machine    => mepc = target,
    Supervisor => sepc = target,
    User       => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
  };
  target
}

val prepare_xret_target : (Privilege) -> xlenbits
function prepare_xret_target(p) =
  get_xepc(p)

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

mapping clause csr_name_map = 0x105  <-> "stvec"
mapping clause csr_name_map = 0x141  <-> "sepc"
mapping clause csr_name_map = 0x305  <-> "mtvec"
mapping clause csr_name_map = 0x341  <-> "mepc"

function clause is_CSR_defined(0x105) = extensionEnabled(Ext_S) // stvec
function clause is_CSR_defined(0x141) = extensionEnabled(Ext_S) // sepc
function clause is_CSR_defined(0x305) = true // mtvec
function clause is_CSR_defined(0x341) = true // mepc

function clause read_CSR(0x105) = get_stvec()
function clause read_CSR(0x141) = get_xepc(Supervisor)
function clause read_CSR(0x305) = get_mtvec()
function clause read_CSR(0x341) = get_xepc(Machine)

function clause write_CSR(0x105, value) = { set_stvec(value) }
function clause write_CSR(0x141, value) = { set_xepc(Supervisor, value) }
function clause write_CSR(0x305, value) = { set_mtvec(value) }
function clause write_CSR(0x341, value) = { set_xepc(Machine, value) }
