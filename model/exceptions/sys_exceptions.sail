// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// default exception model

type ext_exception = unit

// Is XRET from given mode permitted by extension?
function ext_check_xret_priv (_p : Privilege) : Privilege -> bool = true
// Called if above check fails
function ext_fail_xret_priv () : unit -> unit = ()

function handle_trap_extension(_p : Privilege, _pc : xlenbits, _u : option(unit)) -> unit = ()

// used for traps and ECALL
function prepare_trap_vector(p : Privilege, cause : Mcause) -> xlenbits = {
  let tvec : Mtvec = match p {
    Machine           => mtvec,
    Supervisor        => stvec,
    User              => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualSupervisor => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
  };
  match tvec_addr(tvec, cause) {
    Some(epc) => epc,
    None()    => internal_error(__FILE__, __LINE__, "Invalid tvec mode")
  }
}

// xRET handling involves three functions:
//
// get_xepc:            used to read the value of the xret target  (no control flow transfer)
// set_xepc:            used to write a value of the xret target   (no control flow transfer)
// prepare_xret_target: used to get the value for control transfer to the xret target

function get_xepc(p : Privilege) -> xlenbits =
  match p {
    Machine           => align_pc(mepc),
    Supervisor        => align_pc(sepc),
    User              => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualSupervisor => align_pc(vsepc),
  }

function set_xepc(p : Privilege, value : xlenbits) -> xlenbits = {
  let target = legalize_xepc(value);
  match p {
    Machine           => mepc = target,
    Supervisor        => sepc = target,
    User              => internal_error(__FILE__, __LINE__, "Invalid privilege level"),
    VirtualUser       => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported"),
    VirtualSupervisor => vsepc = target,
  };
  target
}

function prepare_xret_target(p : Privilege) -> xlenbits =
  get_xepc(p)

// other trap-related CSRs

function get_mtvec() -> xlenbits =
  mtvec.bits

function get_stvec() -> xlenbits =
  stvec.bits

function get_vstvec() -> xlenbits =
  vstvec.bits

function set_mtvec(value : xlenbits) -> xlenbits = {
  mtvec = legalize_tvec(mtvec, value);
  mtvec.bits
}

function set_stvec(value : xlenbits) -> xlenbits = {
  stvec = legalize_tvec(stvec, value);
  stvec.bits
}

function set_vstvec(value : xlenbits) -> xlenbits = {
  vstvec = legalize_tvec(vstvec, value);
  vstvec.bits
}

mapping clause csr_name_map = 0x205  <-> "vstvec"
mapping clause csr_name_map = 0x241  <-> "vsepc"
mapping clause csr_name_map = 0x105  <-> "stvec"
mapping clause csr_name_map = 0x141  <-> "sepc"
mapping clause csr_name_map = 0x305  <-> "mtvec"
mapping clause csr_name_map = 0x341  <-> "mepc"

function clause is_CSR_accessible(0x205, _, _) = currentlyEnabled(Ext_H) // vstvec
function clause is_CSR_accessible(0x241, _, _) = currentlyEnabled(Ext_H) // vsepc
function clause is_CSR_accessible(0x105, _, _) = currentlyEnabled(Ext_S) // stvec
function clause is_CSR_accessible(0x141, _, _) = currentlyEnabled(Ext_S) // sepc
function clause is_CSR_accessible(0x305, _, _) = true // mtvec
function clause is_CSR_accessible(0x341, _, _) = true // mepc

function clause read_CSR(0x205) = get_vstvec()
function clause read_CSR(0x241) = get_xepc(VirtualSupervisor)
function clause read_CSR(0x105) = if privLevel_is_virtual(cur_privilege) then get_vstvec() else get_stvec()
function clause read_CSR(0x141) = get_xepc(if privLevel_is_virtual(cur_privilege) then VirtualSupervisor else Supervisor)
function clause read_CSR(0x305) = get_mtvec()
function clause read_CSR(0x341) = get_xepc(Machine)

function clause write_CSR(0x205, value) = { Ok(set_vstvec(value)) }
function clause write_CSR(0x241, value) = { Ok(set_xepc(VirtualSupervisor, value)) }
function clause write_CSR(0x105, value) = { Ok(if privLevel_is_virtual(cur_privilege) then set_vstvec(value) else set_stvec(value)) }
function clause write_CSR(0x141, value) = { Ok(set_xepc(if privLevel_is_virtual(cur_privilege) then VirtualSupervisor else Supervisor, value)) }
function clause write_CSR(0x305, value) = { Ok(set_mtvec(value)) }
function clause write_CSR(0x341, value) = { Ok(set_xepc(Machine, value)) }
