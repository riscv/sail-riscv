// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Callbacks for state-changing events
val mem_write_callback = pure {cpp: "mem_write_callback"} : forall 'n, 0 < 'n <= max_mem_access . (/* access type */ string, /* addr */ physaddrbits, /* width */ int('n), /* value */ bits(8 * 'n)) -> unit
function mem_write_callback(_) = ()

val mem_read_callback = pure {cpp: "mem_read_callback"} : forall 'n, 0 < 'n <= max_mem_access . (/* access type */ string, /* addr */ physaddrbits, /* width */ int('n), /* value */ bits(8 * 'n)) -> unit
function mem_read_callback(_) = ()

val mem_exception_callback = pure {cpp: "mem_exception_callback"} : forall 'n, 0 <= 'n < xlen . (/* addr */ physaddrbits, /* num_of_ExceptionType */ int('n)) -> unit
function mem_exception_callback(_) = ()

val pc_write_callback = pure {cpp: "pc_write_callback"} : xlenbits -> unit
function pc_write_callback(_) = ()

val xreg_full_write_callback = pure {cpp: "xreg_full_write_callback"} : (string, regidx, xlenbits) -> unit
function xreg_full_write_callback(_) = ()

val csr_full_write_callback = pure {cpp: "csr_full_write_callback"} : (string, csreg, xlenbits) -> unit
function csr_full_write_callback(_) = ()

val csr_full_read_callback = pure {cpp: "csr_full_read_callback"} : (string, csreg, xlenbits) -> unit
function csr_full_read_callback(_) = ()

val trap_callback = pure {cpp: "trap_callback"} : unit -> unit
function trap_callback(_) = ()

// Overloads for easier use of callbacks
function csr_name_write_callback(name : string, value : xlenbits) -> unit = {
  let csr = csr_name_map(name);
  csr_full_write_callback(name, csr, value);
}
function csr_id_write_callback(csr : csreg, value : xlenbits) -> unit = {
  let name = csr_name_map(csr);
  csr_full_write_callback(name, csr, value);
}
function csr_name_read_callback(name : string, value : xlenbits) -> unit = {
  let csr = csr_name_map(name);
  csr_full_read_callback(name, csr, value);
}
function csr_id_read_callback(csr : csreg, value : xlenbits) -> unit = {
  let name = csr_name_map(csr);
  csr_full_read_callback(name, csr, value);
}

overload csr_write_callback = {csr_name_write_callback, csr_id_write_callback, csr_full_write_callback}
overload csr_read_callback = {csr_name_read_callback, csr_id_read_callback, csr_full_read_callback}

function long_csr_write_callback(name : string, name_high : string, value : bits(64)) -> unit = {
  csr_write_callback(name, value[xlen - 1 .. 0]);
  if xlen == 32
  then csr_write_callback(name_high, value[63 .. 32]);
}
