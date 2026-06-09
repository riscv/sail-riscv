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
// not exceed a page size.  Misaligned accesses that pass global
// misaligned checks (as configured by `memory.misaligned`) and that
// do not cross a page boundary are passed down intact to `mem.sail`,
// where PMA checks are done.

function plat_misaligned_exception(access : MemoryAccessType(mem_payload), res : bool) -> option(misaligned_exception) = {
  if is_amo_access(access) then plat_misaligned_access.amo
  else if res then Some(plat_misaligned_access.lrsc)
  else if is_vector_access(access) then plat_misaligned_access.vector
  else plat_misaligned_access.load_store
}

// Memory exceptions from `mem.sail` are reported in terms of
// `physaddr`, while the utilities here need to report them in terms
// of the corresponding `virtaddr`.  In particular, since the original
// `virtaddr` access may be split into smaller `physaddr` accesses,
// the correct offset from the base `virtaddr` needs to be reported.
// Since `virtaddr` accesses that straddle page boundaries are already
// split, the offset computation is quite simple.

private function offset_virtaddr_by(
  Virtaddr(base_vaddr) : virtaddr,
  Physaddr(base_paddr) : physaddr,
  Physaddr(exc_paddr)  : physaddr,
) -> virtaddr = {
  // Physical addresses may have a different size.
  let offset = (exc_paddr - base_paddr)[xlen - 1 .. 0];
  Virtaddr(base_vaddr + offset)
}

// External API

// Apply pointer masking to an effective address given a precomputed PMLEN.
// Whether the address is virtual (sign-extend) or physical (zero-extend) follows
// the first-stage satp register feeding the address: vsatp for VS/VU, otherwise
// satp. A guest-physical address (vsatp.MODE == Bare) is treated as physical.
function pm_transform_for_priv(vaddr : virtaddr, eff_privilege : Privilege, pmlen : {0, 7, 16}) -> virtaddr = {
  let mode = if eff_privilege == VirtualSupervisor | eff_privilege == VirtualUser
             then vsatp_mode(eff_privilege)
             else satp_mode(eff_privilege);
  if mode == Bare then pm_transform_PA(vaddr, pmlen) else pm_transform_VA(vaddr, pmlen)
}

// Transforms the effective address of a regular explicit access based on PMM
// settings and the current translation mode.
function transform_effective_address(vaddr : virtaddr, access : MemoryAccessType(mem_payload)) -> virtaddr = {
  let eff_privilege = effectivePrivilege(access, mstatus, cur_privilege);
  pm_transform_for_priv(vaddr, eff_privilege, get_pmlen(access, eff_privilege))
}

// Transforms the effective address of an HLV/HSV explicit access, whose effective
// privilege (VS/VU) is taken from hstatus.SPVP rather than effectivePrivilege.
function transform_hlsv_address(vaddr : virtaddr, access : MemoryAccessType(mem_payload), eff_privilege : Privilege) -> virtaddr =
  pm_transform_for_priv(vaddr, eff_privilege, get_hlsv_pmlen(access, eff_privilege))

val vmem_read_addr : forall 'width, is_mem_width('width).
  (virtaddr, int('width), MemoryAccessType(mem_payload), bool, bool, bool)
  -> result(bits(8 * 'width), ExecutionResult)

function vmem_read_addr(vaddr, width, access, aq, rl, res) = {
  // "LR faults like a normal load, even though it's in the AMO major opcode space."
  // - Andrew Waterman, isa-dev, 10 Jul 2018.
  if not(is_aligned_addr(vaddr, width)) then {
    match plat_misaligned_exception(access, res) {
      Some(AccessFault)        => return Err(Memory_Exception(exception_context((E_Load_Access_Fault(), bits_of(vaddr))))),
      Some(AlignmentException) => return Err(Memory_Exception(exception_context((E_Load_Addr_Align(), bits_of(vaddr))))),
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

  // We should only split the access before address translation if (a)
  // virtual memory is in effect, and (b) it crosses a page boundary.
  // If we do split, perform the split access in the configured order.
  let effPriv = effectivePrivilege(access, mstatus, cur_privilege);
  let do_split_access = translationMode(effPriv) != Bare & next_page_bytes > 0;

  if sys_misaligned_order_decreasing & do_split_access then {
    // Load-reserved cannot be misaligned.
    assert(not(res));

    // Do next page access first.
    let access_addr = Virtaddr(vaddr_bits + in_page_bytes);
    match translateAddr(access_addr, access) {
      Err(e,_) => return Err(Memory_Exception(e)),

      Ok(paddr, pbmt, _) => match mem_read(access, pbmt, paddr, next_page_bytes, aq, rl, res) {
        Err(exc_paddr, e) => {
          let exc_vaddr = offset_virtaddr_by(access_addr, paddr, exc_paddr);
          return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
        },
        Ok(v)  => data[8 * width - 1 .. 8 * in_page_bytes] = v,
      },
    }
  };

  // If the access was split, only the in-page bytes should be
  // accessed, otherwise all bytes should be accessed.
  let access_width = if do_split_access then in_page_bytes else width;
  match translateAddr(vaddr, access) {
    Err(e, _) => return Err(Memory_Exception(e)),

    Ok(paddr, pbmt, _) => match mem_read(access, pbmt, paddr, access_width, aq, rl, res) {
      Err(exc_paddr, e) => {
        let exc_vaddr = offset_virtaddr_by(vaddr, paddr, exc_paddr);
        return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
      },
      Ok(v)  => {
        if res then {
          load_reservation(bits_of(paddr), width);
        };

        data[8 * access_width - 1 .. 0] = v
      },
    },
  };

  if not(sys_misaligned_order_decreasing) & do_split_access then {
    // Load-reserved cannot be misaligned.
    assert(not(res));

    // Do next page access next.
    let access_addr = Virtaddr(vaddr_bits + in_page_bytes);
    match translateAddr(access_addr, access) {
      Err(e,_) => return Err(Memory_Exception(e)),

      Ok(paddr, pbmt, _) => match mem_read(access, pbmt, paddr, next_page_bytes, aq, rl, res) {
        Err(exc_paddr, e) => {
          let exc_vaddr = offset_virtaddr_by(access_addr, paddr, exc_paddr);
          return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
        },
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
      Some(AccessFault)        => return Err(Memory_Exception(exception_context((E_SAMO_Access_Fault(), bits_of(vaddr))))),
      Some(AlignmentException) => return Err(Memory_Exception(exception_context((E_SAMO_Addr_Align(), bits_of(vaddr))))),
      None()                   => (),
    };
  };

  // See vmem_read_addr above for additional comments.

  // NOTE: The `mem_write_value` calls here go down to the physical
  // memory layer, where they may get split to handle misalignment.
  // This may result in mismatches with the `mem_write_ea` calls: one
  // `mem_write_ea` call with a wider width may be called for multiple
  // lower level value writes of smaller widths.  This needs to be
  // handled along with https://github.com/riscv/sail-riscv/issues/1761.

  let vaddr_bits = bits_of(vaddr);
  var write_success : bool = true;

  let (in_page_bytes, next_page_bytes) = split_on_page_boundary(vaddr_bits, width);

  let effPriv = effectivePrivilege(access, mstatus, cur_privilege);
  let do_split_access = translationMode(effPriv) != Bare & next_page_bytes > 0;

  if sys_misaligned_order_decreasing & do_split_access then {
    // Store-conditionals cannot be misaligned.
    assert(not(is_store_conditional(access)));

    let access_addr = Virtaddr(vaddr_bits + in_page_bytes);
    match translateAddr(access_addr, access) {
      Err(e, _) => return Err(Memory_Exception(e)),

      Ok(paddr, pbmt, _) => match mem_write_ea(paddr, next_page_bytes, access, pbmt, aq, rl, res) {
        Err(exc_paddr, e) => {
          let exc_vaddr = offset_virtaddr_by(access_addr, paddr, exc_paddr);
          return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
        },

        Ok(()) => {
          let write_value = data[8 * width - 1 .. 8 * in_page_bytes];
          match mem_write_value(paddr, next_page_bytes, write_value, access, pbmt, aq, rl, res) {
            Err(exc_paddr, e) => {
              let exc_vaddr = offset_virtaddr_by(access_addr, paddr, exc_paddr);
              return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
            },
            Ok(s)  => write_success = write_success & s,
          }
        },
      },
    }
  };

  let access_width = if do_split_access then in_page_bytes else width;
  match translateAddr(vaddr, access) {
    Err(e, _) => return Err(Memory_Exception(e)),

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
        match phys_access_check(access, pbmt, effPriv, paddr, access_width, true) {
          Err(e) => return Err(Memory_Exception(exception_context((e, bits_of(vaddr))))),
          Ok(_)  => write_success = false,
        }
      } else match mem_write_ea(paddr, access_width, access, pbmt, aq, rl, res) {
        Err(exc_paddr, e) => {
          let exc_vaddr = offset_virtaddr_by(vaddr, paddr, exc_paddr);
          return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
        },

        Ok(()) => {
          let write_value = data[8 * access_width - 1 .. 0];
          match mem_write_value(paddr, access_width, write_value, access, pbmt, aq, rl, res) {
            Err(exc_paddr, e) => {
              let exc_vaddr = offset_virtaddr_by(vaddr, paddr, exc_paddr);
              return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
            },
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
      Err(e, _) => return Err(Memory_Exception(exception_context((e, bits_of(access_addr))))),

      Ok(paddr, pbmt, _) => match mem_write_ea(paddr, next_page_bytes, access, pbmt, aq, rl, res) {
        Err(exc_paddr, e) => {
          let exc_vaddr = offset_virtaddr_by(access_addr, paddr, exc_paddr);
          return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
        },

        Ok(()) => {
          let write_value = data[8 * width - 1 .. 8 * in_page_bytes];
          match mem_write_value(paddr, next_page_bytes, write_value, access, pbmt, aq, rl, res) {
            Err(exc_paddr, e) => {
              let exc_vaddr = offset_virtaddr_by(access_addr, paddr, exc_paddr);
              return Err(Memory_Exception(exception_context((e, bits_of(exc_vaddr)))))
            },
            Ok(s)  => write_success = write_success & s,
          }
        },
      },
    }
  };

  Ok(write_success)
}

// Compute effective address with extension checks and apply pointer masking.
function get_transformed_data_addr(base : regidx, offset : xlenbits, acc : MemoryAccessType(mem_payload), width : mem_access_width)
         -> Ext_DataAddr_Check(ext_data_addr_error) = {
  match ext_data_get_addr(base, offset, acc, width) {
    Ext_DataAddr_Error(e) => Ext_DataAddr_Error(e),
    Ext_DataAddr_OK(vaddr) => {
      let vaddr = transform_effective_address(vaddr, acc);
      Ext_DataAddr_OK(vaddr)
    }
  }
}

val vmem_read : forall 'width, is_mem_width('width).
  (regidx, xlenbits, int('width), MemoryAccessType(mem_payload), bool, bool, bool)
  -> result(bits(8 * 'width), ExecutionResult)

function vmem_read(rs, offset, width, access, aq, rl, res) = {
  // Get the address, X(rs1) + offset.
  // Extensions might perform additional checks on address validity.
  let vaddr : virtaddr = match get_transformed_data_addr(rs, offset, access, width) {
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
  let vaddr : virtaddr = match get_transformed_data_addr(rs_addr, offset, access, width) {
    Ext_DataAddr_OK(vaddr) => vaddr,
    Ext_DataAddr_Error(e)  => return Err(Ext_DataAddr_Check_Failure(e)),
  };

  vmem_write_addr(vaddr, width, data, access, aq, rl, res)
}