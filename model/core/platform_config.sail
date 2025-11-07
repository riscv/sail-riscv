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

// whether the MMU should update dirty bits in PTEs
let plat_enable_dirty_update : bool = config memory.translation.dirty_update

// whether the platform supports misaligned accesses without trapping to M-mode. if false,
// misaligned loads/stores are trapped to Machine mode.
let plat_enable_misaligned_access : bool = config memory.misaligned.supported

// Location of clock-interface, which should match with the spec in the DTB
let plat_clint_base : physaddrbits = to_bits_checked(config platform.clint.base : int)
let plat_clint_size : physaddrbits = to_bits_checked(config platform.clint.size : int)

let plat_insns_per_tick : nat1 = config platform.instructions_per_tick
