// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// This file implements utility functions for accessing memory that
// can be used by instruction definitions.
//
// These memory accessors performs address translation and return a
// Retire_Failure on error.  In order to support RVWMO memory model,
// address and when possible data arguments are passed as their source
// registers.
//
// All addresses are provided in integer source register arguments.
// For write accessors, there are functions for each kind of source
// data register type (integer, floating point, vector).
//
// The memory accessor functions split accesses that cross page
// boundaries into two. The two split accesses are performed in the
// order specified by `sys_misaligned_order_decreasing`.
//
// The Misaligned Atomicity Granule requires that misaligned loads,
// stores, and AMOs that do not cross a PMA granule boundary are
// atomic. The implementation below assumes that PMA granule sizes do
// not exceed a page size, and misaligned accesses that pass global
// misaligned checks (as configured by `memory.misaligned`) and that
// do not cross a page boundary are passed down intact to `mem.sail`,
// where PMA checks are done.

function is_access_within_page(Virtaddr(addr) : virtaddr, width : word_width_wide) -> bool =
  access_within(addr, width, pagesize_bits)

function plat_misaligned_exception(access : MemoryAccessType(mem_payload), res : bool) -> option(misaligned_exception) = {
  if is_amo_access(access) then plat_misaligned_access.amo
  else if res then Some(plat_misaligned_access.lrsc)
  else if is_vector_access(access) then plat_misaligned_access.vector
  else plat_misaligned_access.load_store
}

val vmem_read_addr : forall 'width, is_mem_width('width).
  (virtaddr, int('width), MemoryAccessType(mem_payload), bool, bool, bool)
  -> result(bits(8 * 'width), ExecutionResult)

function vmem_read_addr(vaddr, width, access, aq, rl, res) = {
  // "LR faults like a normal load, even though it's in the AMO major opcode space."
  // - Andrew Waterman, isa-dev, 10 Jul 2018.
  if not(is_aligned_addr(vaddr, width)) then {
    match plat_misaligned_exception(access, res) {
      Some(AccessFault)        => return Err(memory_exception(vaddr, E_Load_Access_Fault())),
      Some(AlignmentException) => return Err(memory_exception(vaddr, E_Load_Addr_Align())),
      // Even if the CPU does support misaligned accesses, it might be
      // that the PMA doesn't support misaligned accesses so you can
      // still get a fault later, but this will be after address
      // translation below.
      None()                   => (),
    };
  };

  let vaddr_bits = bits_of(vaddr);

  let (in_page_bytes, next_page_bytes) = split_on_page_boundary(vaddr_bits, width);

  var data = zeros(8 * width);

  // We should not split the access if (a) virtual memory is not in
  // effect, or (b) it does not cross a page boundary.  But if we do
  // split, perform the split access in the configured order.

  let do_split_access = translationMode(cur_privilege) != Bare & next_page_bytes > 0;

  // The second condition in the conjunction here and below is needed
  // for the type-checker to satisfy the constraints on
  // `next_page_bytes` for `mem_read`.
  if sys_misaligned_order_decreasing & do_split_access then {
    // Load-reserved cannot be misaligned.
    assert(not(res));

    // Do next page access first.
    let access_addr = Virtaddr(vaddr_bits + in_page_bytes);
    match translateAddr(access_addr, access) {
      Err(e,_) => return Err(memory_exception(access_addr, e)),

      Ok(paddr, pbmt, _) => match mem_read(access, pbmt, paddr, next_page_bytes, aq, rl, res) {
        Err(e) => return Err(memory_exception(access_addr, e)),
        Ok(v)  => data[8 * width - 1 .. 8 * in_page_bytes] = v,
      },
    }
  };

  match translateAddr(vaddr, access) {
    Err(e, _) => return Err(memory_exception(vaddr, e)),

    Ok(paddr, pbmt, _) => match mem_read(access, pbmt, paddr, in_page_bytes, aq, rl, res) {
      Err(e) => return Err(memory_exception(vaddr, e)),

      Ok(v)  => {
        if res then {
          load_reservation(bits_of(paddr), width);
        };

        data[8 * in_page_bytes - 1 .. 0] = v
      },
    },
  };

  if not(sys_misaligned_order_decreasing) & do_split_access then {
    // Load-reserved cannot be misaligned.
    assert(not(res));

    // Do next page access next.
    let access_addr = Virtaddr(vaddr_bits + in_page_bytes);
    match translateAddr(access_addr, access) {
      Err(e,_) => return Err(memory_exception(access_addr, e)),

      Ok(paddr, pbmt, _) => match mem_read(access, pbmt, paddr, next_page_bytes, aq, rl, res) {
        Err(e) => return Err(memory_exception(access_addr, e)),
        Ok(v)  => data[8 * width - 1 .. 8 * in_page_bytes] = v,
      },
    }
  };

  Ok(data)
}

val vmem_write_addr : forall 'width, is_mem_width('width).
  (virtaddr, int('width), bits(8 * 'width), MemoryAccessType(mem_payload), bool, bool, bool)
  -> result(bool, ExecutionResult)

function vmem_write_addr(vaddr, width, data, access, aq, rl, res) = {
  // See comments in vmem_read_addr for an explanation of this check.
  if not(is_aligned_addr(vaddr, width)) then {
    match plat_misaligned_exception(access, res) {
      Some(AccessFault)        => return Err(memory_exception(vaddr, E_SAMO_Access_Fault())),
      Some(AlignmentException) => return Err(memory_exception(vaddr, E_SAMO_Addr_Align())),
      None()                   => (),
    };
  };

  // See vmem_read_addr above for additional comments.

  let vaddr_bits = bits_of(vaddr);
  var write_success : bool = true;

  let (in_page_bytes, next_page_bytes) = split_on_page_boundary(vaddr_bits, width);

  let do_split_access = translationMode(cur_privilege) != Bare & next_page_bytes > 0;

  if sys_misaligned_order_decreasing & do_split_access then {
    // Store-conditionals cannot be misaligned.
    assert(not(is_store_conditional(access)));

    let access_addr = Virtaddr(vaddr_bits + in_page_bytes);
    match translateAddr(access_addr, access) {
      Err(e, _) => return Err(memory_exception(access_addr, e)),

      // NOTE: Currently, we only announce the effective address if
      // address translation is successful.  This may need revisiting,
      // particularly in the misaligned case.
      Ok(paddr, pbmt, _) => match mem_write_ea(paddr, next_page_bytes, aq, rl, res) {
        Err(e) => return Err(memory_exception(access_addr, e)),

        Ok(()) => {
          let write_value = data[8 * width - 1 .. 8 * in_page_bytes];
          match mem_write_value(paddr, next_page_bytes, write_value, access, pbmt, aq, rl, res) {
            Err(e) => return Err(memory_exception(access_addr, e)),
            Ok(s)  => write_success = write_success & s,
          }
        },
      },
    }
  };

  match translateAddr(vaddr, access) {
    Err(e, _) => return Err(memory_exception(vaddr, e)),

    // NOTE: Currently, we only announce the effective address if
    // address translation is successful.  This may need revisiting,
    // particularly in the misaligned case.
    Ok(paddr, pbmt, _) => {
      // If res is true, the store should be aligned.
      assert(res == is_store_conditional(access));
      if res & not(match_reservation(bits_of(paddr))) then {
        // Check PMA and PMP access controls before reporting the
        // cancelled reservation.
        // "Attempting to execute a store, store-conditional, or AMO
        // instruction which accesses a physical address within a
        // PMP region without write permissions raises a store
        // access-fault exception."
        let effPriv = effectivePrivilege(access, mstatus, cur_privilege);
        match phys_access_check(access, pbmt, effPriv, paddr, in_page_bytes, true) {
          Err(e) => return Err(memory_exception(vaddr, e)),
          Ok(_)  => write_success = false,
        }
      } else match mem_write_ea(paddr, in_page_bytes, aq, rl, res) {
        Err(e) => return Err(memory_exception(vaddr, e)),

        Ok(()) => {
          let write_value = data[8 * in_page_bytes - 1 .. 0];
          match mem_write_value(paddr, in_page_bytes, write_value, access, pbmt, aq, rl, res) {
            Err(e) => return Err(memory_exception(vaddr, e)),
            Ok(s)  => write_success = write_success & s,
          }
        },
      }
    },
  };

  if not(sys_misaligned_order_decreasing) & do_split_access then {
    // Store-conditionals cannot be misaligned.
    assert(not(is_store_conditional(access)));

    let access_addr = Virtaddr(vaddr_bits + in_page_bytes);
    match translateAddr(access_addr, access) {
      Err(e, _) => return Err(memory_exception(access_addr, e)),

      // NOTE: Currently, we only announce the effective address if
      // address translation is successful.  This may need revisiting,
      // particularly in the misaligned case.
      Ok(paddr, pbmt, _) => match mem_write_ea(paddr, next_page_bytes, aq, rl, res) {
        Err(e) => return Err(memory_exception(access_addr, e)),

        Ok(()) => {
          let write_value = data[8 * width - 1 .. 8 * in_page_bytes];
          match mem_write_value(paddr, next_page_bytes, write_value, access, pbmt, aq, rl, res) {
            Err(e) => return Err(memory_exception(access_addr, e)),
            Ok(s)  => write_success = write_success & s,
          }
        },
      },
    }
  };

  Ok(write_success)
}

val vmem_read : forall 'width, is_mem_width('width).
  (regidx, xlenbits, int('width), MemoryAccessType(mem_payload), bool, bool, bool)
  -> result(bits(8 * 'width), ExecutionResult)

function vmem_read(rs, offset, width, access, aq, rl, res) = {
  // Get the address, X(rs1) + offset.
  // Extensions might perform additional checks on address validity.
  let vaddr : virtaddr = match ext_data_get_addr(rs, offset, access, width) {
    Ext_DataAddr_OK(vaddr) => vaddr,
    Ext_DataAddr_Error(e)  => return Err(Ext_DataAddr_Check_Failure(e)),
  };

  vmem_read_addr(vaddr, width, access, aq, rl, res)
}

val vmem_write : forall 'width, is_mem_width('width).
  (regidx, xlenbits, int('width), bits(8 * 'width), MemoryAccessType(mem_payload), bool, bool, bool)
  -> result(bool, ExecutionResult)

function vmem_write(rs_addr, offset, width, data, access, aq, rl, res) = {
  // Get the address, X(rs_addr) + offset.
  // Extensions might perform additional checks on address validity.
  let vaddr : virtaddr = match ext_data_get_addr(rs_addr, offset, access, width) {
    Ext_DataAddr_OK(vaddr) => vaddr,
    Ext_DataAddr_Error(e)  => return Err(Ext_DataAddr_Check_Failure(e)),
  };

  vmem_write_addr(vaddr, width, data, access, aq, rl, res)
}
