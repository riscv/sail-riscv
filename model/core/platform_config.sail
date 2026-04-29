// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Platform-specific configuration parameters.

// Cache block size is 2^cache_block_size_exp. Max is `max_mem_access` (4096)
// because this model performs `cbo.zero` with a single write, and the behaviour
// with cache blocks larger than a page is not clearly defined.
let plat_cache_block_size_exp : range(0, 12) = config platform.cache_block_size_exp

// Reservation set size is 2^reservation_set_size_exp.
//
// The reservation set must lie completely within a 4KiB page on systems with
// page-based virtual memory and the "A" extension.  Although reservation sets could
// theoretically be larger on non-MMU systems, the probability of a successful LR/SC
// increases if contended synchronization variables are placed in different
// reservation sets, and practical systems will hence constrain the reservation set
// size for performance reasons.  This motivates constraining the maximum to
// `max_mem_access` (4096) because larger sizes are unrealistic.
// Reservation sets are also naturally aligned. Reservation sets need to subsume
// their LR operands (4 bytes for LR.W, 8 bytes for LR.D).
let plat_reservation_set_size_exp : range(2, 12) = config platform.reservation.reservation_set_size_exp

// The exceptions that a misaligned access could generate.  For
// example, a misaligned LR/SC always raises an exception.
enum misaligned_exception = { AccessFault, AlignmentException }
mapping misaligned_exception_str : misaligned_exception <-> string = {
  AccessFault        <-> "AccessFault",
  AlignmentException <-> "AlignmentException",
}
overload to_str = {misaligned_exception_str}

function optional_misaligned_exception_str(opt_e : option(misaligned_exception)) -> string =
  match opt_e {
    None()  => "NoFault",
    Some(e) => misaligned_exception_str(e),
  }
overload to_str = {optional_misaligned_exception_str}

function misaligned_exception_is_access_fault(e : option(misaligned_exception)) -> bool =
  match e {
    Some(AccessFault) => true,
    _                 => false,
  }

// Some misaligned accesses could proceed or generate exceptions.
// When used in the global (pre-address translation) configuration,
// `None` indicates that the handling is deferred to the underlying
// PMA (if any).
struct GlobalMisalignedExceptions = {
  load_store : option(misaligned_exception),
  vector     : option(misaligned_exception),
  // LR/SC must always be aligned. Returning a misaligned exception indicates
  // that the access can be emulated (the OS/firmware can transparently break
  // it down into multiple aligned accesses) which isn't the case for LR/SC
  // in normal implementations.
  lrsc       : misaligned_exception,
  // TODO: Support for the MAG PMA will change this field to an option(misaligned_exception).
  amo        : misaligned_exception,
}

// The handling of misaligned accesses before address translation.
let plat_misaligned_access : GlobalMisalignedExceptions = config memory.misaligned.exceptions

// Location of clock-interface, which should match with the spec in the DTB
let plat_have_clint : bool = config platform.clint.supported
let plat_clint_base : physaddrbits = to_bits_checked(config platform.clint.base : int)
let plat_clint_size : physaddrbits = to_bits_checked(config platform.clint.size : int)

// Simple Interrupt Generator. See docs/SimpleInterruptGenerator.md for details.
let plat_have_sig : bool = config platform.simple_interrupt_generator.supported
let plat_sig_base : physaddrbits = to_bits_checked(config platform.simple_interrupt_generator.base : int)
let plat_sig_size : physaddrbits = zero_extend(0x20)

let plat_insns_per_tick : nat1 = config platform.instructions_per_tick

// Maximum increment in the time CSR to wait for wait instructions.  This is not
// used within the model but instead configures the external C++ harness.
let max_wait_time : nat = config platform.max_time_to_wait

// which exceptions write information into `xtval`
let illegal_instruction_writes_xtval : bool = config base.xtval_nonzero.illegal_instruction
let virtual_instruction_writes_xtval : bool = false
let software_breakpoint_writes_xtval : bool = config base.xtval_nonzero.software_breakpoint
let hardware_breakpoint_writes_xtval : bool = config base.xtval_nonzero.hardware_breakpoint
let misaligned_load_writes_xtval : bool = config base.xtval_nonzero.load_address_misaligned
let load_access_fault_writes_xtval : bool = config base.xtval_nonzero.load_access_fault
let load_page_fault_writes_xtval : bool = config base.xtval_nonzero.load_page_fault
let load_guest_page_fault_writes_xtval : bool = false
let misaligned_samo_writes_xtval : bool = config base.xtval_nonzero.samo_address_misaligned
let samo_access_fault_writes_xtval : bool = config base.xtval_nonzero.samo_access_fault
let samo_page_fault_writes_xtval : bool = config base.xtval_nonzero.samo_page_fault
let samo_guest_page_fault_writes_xtval : bool = false
let misaligned_fetch_writes_xtval : bool = config base.xtval_nonzero.fetch_address_misaligned
let fetch_access_fault_writes_xtval : bool = config base.xtval_nonzero.fetch_access_fault
let fetch_page_fault_writes_xtval : bool = config base.xtval_nonzero.fetch_page_fault
let fetch_guest_page_fault_writes_xtval : bool = false
let software_check_fault_writes_xtval : bool = config base.xtval_nonzero.software_check
let reserved_exceptions_write_xtval : bool = config base.xtval_nonzero.reserved_exceptions

// Define the policy for handling reserved behaviors.

enum AmocasOddRegisterReservedBehavior = {
  AMOCAS_Fatal,
  AMOCAS_Illegal,
}

enum FcsrRmReservedBehavior = {
  Fcsr_RM_Fatal,
  Fcsr_RM_Illegal,
}

enum PmpWriteOnlyReservedBehavior = {
  PMP_Fatal,
  PMP_ClearPermissions,
}

enum XenvcfgCbieReservedBehavior = {
  Xenvcfg_Fatal,
  Xenvcfg_ClearPermissions,
}

enum XtvecModeReservedBehavior = {
  Xtvec_Fatal,
  Xtvec_Ignore,
}

enum RV32ZdinxOddRegisterReservedBehavior = {
  Zdinx_Fatal,
  Zdinx_Illegal,
}

let amocas_odd_register_reserved_behavior : AmocasOddRegisterReservedBehavior = config base.reserved_behavior.amocas_odd_register
let fcsr_rm_reserved_behavior : FcsrRmReservedBehavior = config base.reserved_behavior.fcsr_rm
let pmp_write_only_reserved_behavior : PmpWriteOnlyReservedBehavior = config base.reserved_behavior.pmpcfg_write_only
let xenvcfg_cbie_reserved_behavior : XenvcfgCbieReservedBehavior = config base.reserved_behavior.xenvcfg_cbie
let xtvec_mode_reserved_behavior : XtvecModeReservedBehavior = config base.reserved_behavior.xtvec_mode
let rv32zdinx_odd_register_reserved_behavior : RV32ZdinxOddRegisterReservedBehavior = config base.reserved_behavior.rv32zdinx_odd_register
