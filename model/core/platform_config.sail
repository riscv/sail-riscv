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
let plat_reservation_set_size_exp : range(2, 12) = config platform.reservation_set_size_exp

// whether the MMU should update dirty bits in PTEs
let plat_enable_dirty_update : bool = config memory.translation.dirty_update

// whether the platform supports misaligned accesses without trapping to M-mode. if false,
// misaligned loads/stores are trapped to Machine mode.
let plat_enable_misaligned_access : bool = config memory.misaligned.supported

// Location of clock-interface, which should match with the spec in the DTB
let plat_clint_base : physaddrbits = to_bits_checked(config platform.clint.base : int)
let plat_clint_size : physaddrbits = to_bits_checked(config platform.clint.size : int)

let plat_insns_per_tick : nat1 = config platform.instructions_per_tick

// which exceptions write information into `xtval`
let illegal_instruction_writes_xtval : bool = config base.xtval_nonzero.illegal_instruction
let software_breakpoint_writes_xtval : bool = config base.xtval_nonzero.software_breakpoint
let hardware_breakpoint_writes_xtval : bool = config base.xtval_nonzero.hardware_breakpoint
let misaligned_load_writes_xtval : bool = config base.xtval_nonzero.load_address_misaligned
let load_access_fault_writes_xtval : bool = config base.xtval_nonzero.load_access_fault
let load_page_fault_writes_xtval : bool = config base.xtval_nonzero.load_page_fault
let misaligned_samo_writes_xtval : bool = config base.xtval_nonzero.samo_address_misaligned
let samo_access_fault_writes_xtval : bool = config base.xtval_nonzero.samo_access_fault
let samo_page_fault_writes_xtval : bool = config base.xtval_nonzero.samo_page_fault
let misaligned_fetch_writes_xtval : bool = config base.xtval_nonzero.fetch_address_misaligned
let fetch_access_fault_writes_xtval : bool = config base.xtval_nonzero.fetch_access_fault
let fetch_page_fault_writes_xtval : bool = config base.xtval_nonzero.fetch_page_fault
let software_check_fault_writes_xtval : bool = config base.xtval_nonzero.software_check
let reserved_exceptions_write_xtval : bool = config base.xtval_nonzero.reserved_exceptions
