// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Callbacks for state-changing events

/// Called upon successful instruction fetch with the opcode.
/// If there is a fetch error then this is not called (but trap_callback() will be).
val fetch_callback = pure {c: "fetch_callback"} : forall 'n, 'n in {16, 32}. (bits('n)) -> unit
function fetch_callback(_) = ()

val mem_write_callback = pure {c: "mem_write_callback"} : forall 'n, 0 < 'n <= max_mem_access . (/* access type */ string, /* addr */ physaddrbits, /* width */ int('n), /* value */ bits(8 * 'n)) -> unit
function mem_write_callback(_) = ()

val mem_read_callback = pure {c: "mem_read_callback"} : forall 'n, 0 < 'n <= max_mem_access . (/* access type */ string, /* addr */ physaddrbits, /* width */ int('n), /* value */ bits(8 * 'n)) -> unit
function mem_read_callback(_) = ()

val mem_exception_callback = pure {c: "mem_exception_callback"} : (/* addr */ physaddrbits, /* exception code */ exc_code) -> unit
function mem_exception_callback(_) = ()

/// Called at the end of every step when PC is advanced to the next
/// instruction. This includes taken branches. It is not called when
/// the hart is waiting in WFI/WRS. The parameter is the new PC.

val pc_write_callback = pure {c: "pc_write_callback"} : (/* new_pc */ xlenbits) -> unit
function pc_write_callback(_) = ()

val xreg_full_write_callback = pure {c: "xreg_full_write_callback"} : (string, regidx, xlenbits) -> unit
function xreg_full_write_callback(_) = ()

val csr_full_write_callback = pure {c: "csr_full_write_callback"} : (string, csreg, xlenbits) -> unit
function csr_full_write_callback(_) = ()

val csr_full_read_callback = pure {c: "csr_full_read_callback"} : (string, csreg, xlenbits) -> unit
function csr_full_read_callback(_) = ()

/// Called when control flow is redirected from just executing the next instruction.
/// This includes:
///
///  * Unconditional jumps (jal, jalr)
///  * Traps
///  * Returning from trap handlers (mret, sret)
///  * Conditional branches that are taken (even if the target is the same instruction that
///    would have been executed if they were not taken).
///
/// The parameter is the new PC. pc_write_callback() will also be called after
/// this with the same parameter.
val redirect_callback = pure {c: "redirect_callback"} : (/* new_pc */ xlenbits) -> unit
function redirect_callback(_) = ()

/// Called on interrupts and exceptions. The exc_code does not include the 'interrupt' bit which is
/// in a separate bool.
val trap_callback = pure {c: "trap_callback"} : (/* is_interrupt */ bool, /* interrupt/exception cause */ exc_code) -> unit
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

//pt walks

// 在 callbacks.sail 中定义回调类型

// type ptw_callback_info = struct {
//   virtual_address : bits(64),
//   privilege_level : privilege_level,
//   read_write      : bool, // True for read, False for write
//   instruction     : bool, // True if from instruction fetch
//   satp            : bits(64), // SATP register value
//   // 其他可能相关的上下文信息
// }

val pt_walk_log = pure {c: "pt_walk_log"} : (bits(64),string,string,xlenbits) -> unit
function pt_walk_log(_) = ()



function pt_walk_callback(vpn:bits(64),pr : Privilege,readtype: AccessType(ext_access_type),satp : xlenbits) -> unit = {
  //  let access_str = match readtype {
  //       Read       => "Read",
  //       Write      => "Write",
  //       ReadWrite    => "ReadWrite",
  //       InstructionFetch => "InstructionFetch",
  //       _          => "unknown"
  //   };
  pt_walk_log(vpn,to_str(pr),to_str(readtype),satp)
        // println("[PTW ERROR] VA=" : hex(vpn) : 
        //         " Failed at level " : string(pr) :
        //         " Readtype: " : string(readtype));
        
        // println(" SATP: " : hex(satp) :
        //         " MODE=" : decimal(extract_bits(satp, 63, 60)) :
        //         " ASID=" : decimal(extract_bits(satp, 59, 44)) :
        //         " PPN=" : hex(extract_bits(satp, 43, 0)));
}