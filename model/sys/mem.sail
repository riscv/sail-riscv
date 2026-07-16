// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Physical memory model.
//
// This assumes that the platform memory map has been defined, so that accesses
// to MMIO regions can be dispatched.
//
// The implementation below supports the reading and writing of memory
// metadata in addition to raw memory data.
//
// The external API for this module is composed of three central functions
//
//   mem_read_priv_meta
//   mem_write_ea
//   mem_write_value_priv_meta
//
// and some special cases which partially apply these functions:
//
//   mem_read_priv - strips metadata from reads
//   mem_read_meta - uses effectivePrivilege
//   mem_read      - both of the above partial applications
//
//   mem_write_value_meta - uses effectivePrivilege
//   mem_write_value_priv - uses a default value for metadata
//   mem_write_value      - both of the above partial applications
//
// The internal implementation first performs a PMP check (if PMP is
// enabled) and a PMA check, and then dispatches to MMIO regions or physical
// memory as per the platform memory map.

private function read_kind_of_flags (aq : bool, rl : bool, res : bool) -> read_kind =
  match (aq, rl, res) {
    (false, false, false) => Read_plain,
    (true, false, false)  => internal_error(__FILE__, __LINE__, "Unreserved load with acquire semantics should be unreachable"),
    (true, true, false)   => internal_error(__FILE__, __LINE__, "Unreserved load with acquire-release semantics should be unreachable"),
    (false, false, true)  => Read_RISCV_reserved,
    (true, false, true)   => Read_RISCV_reserved_acquire,
    (true, true, true)    => Read_RISCV_reserved_strong_acquire,
    // This is never called with rl=true and aq=false.
    (false, true, false)  => internal_error(__FILE__, __LINE__, "Unreserved Load with release semantics should be unreachable"),
    (false, true, true)   => internal_error(__FILE__, __LINE__, "Load-reserved with release semantics should be unreachable"),
  }

function write_kind_of_flags (aq : bool, rl : bool, con : bool) -> write_kind =
  match (aq, rl, con) {
    (false, false, false) => Write_plain,
    (false, true,  false) => internal_error(__FILE__, __LINE__, "Unconditional store with release semantics should be unreachable"),
    (false, false, true)  => Write_RISCV_conditional,
    (false, true , true)  => Write_RISCV_conditional_release,
    (true,  true,  false) => internal_error(__FILE__, __LINE__, "Unconditional store with acquire-release semantics should be unreachable"),
    (true,  true , true)  => Write_RISCV_conditional_strong_release,
    // This is never called with aq=true and rl=false.
    (true,  false, false) => internal_error(__FILE__, __LINE__, "Unconditional store with acquire semantics should be unreachable"),
    (true,  false, true)  => internal_error(__FILE__, __LINE__, "Store-conditional with acquire semantics should be unreachable"),
  }


// Information used to access physical memory.
//
// It specifies whether the access should be split, and if so, the MAG
// granule to use. In future, this could be extended to cover memory
// ordering properties.

struct Phys_Mem_Access_Info = {
  // Whether the access should be split.
  splittable : Splittability,
  // The granule size to use for any splitting.
  granule_size_exp : mag_size_exp,
}

private function pmaCheck forall 'n, 0 < 'n <= max_mem_access .
(
  paddr      : physaddr,
  width      : int('n),
  access     : MemoryAccessType(mem_payload),
  pbmt       : page_based_mem_type,
  res_or_con : bool,
)  -> result(Phys_Mem_Access_Info, ExceptionType) = {

  let attributes : PMA = match matching_pma_region(pma_regions, paddr, width) {
    None() =>
      return Err(accessFaultFromAccessType(access)),
    Some(struct { attributes, _ }) =>
      override_PMA(attributes, pbmt),
  };

  // The spec is silent about the order in which PMA checks are done,
  // but after address translation (i.e. here), access faults have
  // higher priority than misaligned exceptions so those are checked
  // first. See the "Synchronous exception priority in decreasing
  // priority order." table in the ISA manual.

  let canAccess : bool = match access {
    InstructionFetch()     => attributes.executable,
    Load(Data)             => {assert(not(res_or_con)); attributes.readable},
    Load(Vector)           => {assert(not(res_or_con)); attributes.readable},
    Load(PageTableEntry)   => {assert(not(res_or_con)); attributes.supports_pte_read},
    Store(Data)            => {assert(not(res_or_con)); attributes.writable},
    Store(Vector)          => {assert(not(res_or_con)); attributes.writable},
    Store(PageTableEntry)  => {assert(not(res_or_con)); attributes.supports_pte_write},

    // For LR/SC, we currently don't differentiate between the presence (RsrvEventual)
    // or absence (RsrvNonEventual) of an eventual success guarantee.
    LoadReserved(_, _, Data)      => {assert(res_or_con); attributes.readable & attributes.reservability != RsrvNone},
    StoreConditional(_, _, Data)  => {assert(res_or_con); attributes.writable & attributes.reservability != RsrvNone},
    Atomic(op, _, _, Data, Data)  => {assert(res_or_con); attributes.readable & attributes.writable & pma_allows_atomic_op(attributes.atomic_support, op, width)},

    // "The PMA checks are extended to require memory referenced by shadow stack instructions
    // to be idempotent."
    Load(ShadowStack)      => {assert(not(res_or_con)); attributes.readable & attributes.read_idempotent},
    Store(ShadowStack)     => {assert(not(res_or_con)); attributes.writable & attributes.write_idempotent},
    Atomic(AMOSWAP, _, _, ShadowStack, ShadowStack) => {assert(res_or_con); attributes.readable & attributes.writable & attributes.read_idempotent & attributes.write_idempotent & pma_allows_atomic_op(attributes.atomic_support, AMOSWAP, width)},

    // TODO for the CMO extensions: "The PMAs shall be the
    // same for all physical addresses in the cache block, and
    // if write permission is granted by the supported access
    // type PMAs, read permission shall also be granted."

    // "A cache-block zero instruction is permitted to access
    // the specified cache block whenever a store instruction
    // is permitted to access the corresponding physical
    // addresses and when the PMAs indicate that cache-block
    // zero instructions are a supported access type."
    CacheAccess(CB_zero())      => attributes.writable & attributes.supports_cbo_zero,

    // "A cache-block management instruction is permitted to
    // access the specified cache block whenever a load
    // instruction or store instruction is permitted to access
    // the corresponding physical addresses. If neither a load
    // instruction nor store instruction is permitted to
    // access the physical addresses, but an instruction fetch
    // is permitted to access the physical addresses, whether
    // a cache-block management instruction is permitted to
    // access the cache block is UNSPECIFIED."
    // TODO: handle the second sentence.
    CacheAccess(CB_manage(_))   => attributes.readable | attributes.writable,

    // "A cache-block prefetch instruction is permitted to
    // access the specified cache block whenever a load
    // instruction, store instruction, or instruction fetch is
    // permitted to access the corresponding physical
    // addresses."
    CacheAccess(CB_prefetch(p)) => match p {
      PREFETCH_R => attributes.readable,
      PREFETCH_W => attributes.writable,
      PREFETCH_I => attributes.executable,
    },

    LoadReserved(_, _, p)          => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for LoadReserved."),
    StoreConditional(_, _, p)      => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for StoreConditional."),

    Atomic(op, _, _, ShadowStack, ShadowStack) => internal_error(__FILE__, __LINE__, "Invalid op (" ^ amo_mnemonic(op) ^ ") for ShadowStack Atomic."),
    Atomic(_, _, _, rp, wp)                    => internal_error(__FILE__, __LINE__, "Invalid payloads (" ^ mem_payload_name(rp) ^ ", " ^ mem_payload_name(wp) ^ ") for Atomic."),
  };

  if not(canAccess) then {
    if get_config_print_pma()
    then print_log("PMA access check failed for a " ^ dec_str(width) ^ "-byte wide " ^ to_str(access) ^ " access to address " ^ hex_bits_str(bits_of(paddr)) ^ " with PMA {" ^ to_str(attributes) ^ "}");

    return Err(accessFaultFromAccessType(access));
  };

  // Check if we need to raise an exception for misalignment.

  match mag_pma_check(attributes, access, paddr, width) {
    Ok((splittable, granule_size_exp)) => Ok(struct { splittable, granule_size_exp }),

    Err(e) => {
      if get_config_print_pma()
      then print_log("MAG PMA check failed for a " ^ dec_str(width) ^ "-byte wide " ^ to_str(access) ^ " access to address " ^ hex_bits_str(bits_of(paddr)) ^ " with PMA {" ^ to_str(attributes) ^ "}");
      match e {
        AccessFault        => Err(accessFaultFromAccessType(access)),
        AlignmentException => Err(alignmentFaultFromAccessType(access)),
      }
    },
  }
}

// Check if access is permitted according to PMPs _and_ PMAs.
// NOTE: this function is only used for unsplit accesses such
// as CBOs and an unpaired SC.
function phys_access_check forall 'n, 0 < 'n <= max_mem_access . (
  access : MemoryAccessType(mem_payload),
  pbmt : page_based_mem_type,
  priv : Privilege,
  paddr : physaddr,
  width : int('n),
  res_or_con : bool,
) -> result(Phys_Mem_Access_Info, ExceptionType) = {

  // Although the relative ordering of PMA and PMP checks is
  // unspecified, access faults do have a higher priority than
  // misaligned exceptions (see comment in `pmaCheck()` above).  This
  // implementation prioritizes PMP checks before PMA checks, as PMP
  // checks do not raise misaligned exceptions.

  match pmpCheck(paddr, width, access, priv) {
    Some(e) => Err(e),
    None()  => pmaCheck(paddr, width, access, pbmt, res_or_con)
  }
}

// Local helper to check a possibly-split access against PMAs,
// prioritizing PMP check failures above failed PMA checks.
//
// There are two issues to handle here:
//
// - PMA checks might require splitting the access due to the MAG
//   PMA. If the access is split, the spec requires that PMP checks
//   must be done on each decomposed access.
//
// - If a PMP check results in an access fault, it has higher
//   priority than a misaligned fault from a PMA check.
//
// The PMA check runs first since its result determines the splitting.
// In case it fails, any access fault from the (full-width) PMP check
// has higher priority than a misaligned exception from the PMA check.
//
// Note that unlike `phys_access_check()` above, the PMP check is
// _not_ done in this function when the PMA check succeeds, but later
// per split in the individual checked_mem_{read,write} and mem_write_ea
// functions.
private function check_pma_with_pmp_priority forall 'n, 0 < 'n <= max_mem_access . (
  access     : MemoryAccessType(mem_payload),
  pbmt       : page_based_mem_type,
  priv       : Privilege,
  paddr      : physaddr,
  width      : int('n),
  res_or_con : bool,
) -> result(Phys_Mem_Access_Info, ExceptionType) =
  match pmaCheck(paddr, width, access, pbmt, res_or_con) {
    // PMP checks are done later per-split, and might still fail.
    Ok(access_info) => Ok(access_info),

    // Prioritize PMP failures above PMA failures.
    Err(pmaExc) => match pmpCheck(paddr, width, access, priv) {
      Some(pmpExc) => Err(pmpExc),
      None()       => Err(pmaExc),
    },
  }

// dispatches to MMIO regions or physical memory regions depending on physical memory map
private function checked_mem_read forall 'n, 0 < 'n <= max_mem_access . (
  access : MemoryAccessType(mem_payload),
  pbmt : page_based_mem_type,
  priv : Privilege,
  paddr : physaddr,
  width : int('n),
  aq : bool,
  rl : bool,
  res: bool,
  meta : bool,
) -> MemoryOpResult((bits(8 * 'n), mem_meta)) = {

  let access_info : Phys_Mem_Access_Info = match check_pma_with_pmp_priority(access, pbmt, priv, paddr, width, res) {
    Ok(access_info) => access_info,
    Err(e)          => return Err(e),
  };

  // If the load is misaligned or an allowed misaligned access,
  // split into `N` (single-copy-atomic) memory operations, each
  // of `split_width` width. If the load is aligned, then `N` = 1
  // and `split_width` == `width`.
  let ('N, 'split_width) = split_misaligned(paddr, width, access_info.granule_size_exp, access_info.splittable);

  let paddr_bits = bits_of(paddr);

  var data = zeros(8 * N * split_width);
  // TODO: handle folding of read metadata across all the splits.

  let (first, last, step) = misaligned_order(N);
  var i : range(0, 'N - 1) = first;
  var finished : bool = false;

  let rk = read_kind_of_flags(aq, rl, res);

  repeat {
    let offset = i;
    let paddr = Physaddr(paddr_bits + (offset * split_width));

    // As mentioned above, PMP checks are done on each split access.
    match pmpCheck(paddr, split_width, access, priv) {
      Some(e) => return Err(e),
      None()  => (),
    };

    // Since splitting is within 4K page boundaries and PMAs are
    // page-aligned, every split will be in a homogeneous region,
    // though the code looks otherwise.

    let split_data =
      if   within_mmio_readable(paddr, split_width)
      then match mmio_read(access, paddr, split_width) {
        Err(e) => return Err(e),
        Ok(mmio_data) => mmio_data,
      } else {
        let (ram_data, _meta) = read_ram(rk, paddr, split_width, meta);
        ram_data
      };
    data[(8 * (offset + 1) * split_width - 1) .. 8 * offset * split_width] = split_data;

    if offset == last then {
      finished = true
    } else {
      i = offset + step
    }
  } until finished;

  // See above: metadata is not handled.
  Ok((data, default_meta))
}

// This lets the Rocq extraction know why the repeat loop above terminates
termination_measure checked_mem_read repeat N

// Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers.

val mem_read      : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), page_based_mem_type, physaddr, int('n), bool, bool, bool)       -> MemoryOpResult(bits(8 * 'n))
val mem_read_priv : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), page_based_mem_type, Privilege, physaddr, int('n), bool, bool, bool)       -> MemoryOpResult(bits(8 * 'n))
val mem_read_meta : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), page_based_mem_type, physaddr, int('n), bool, bool, bool, bool) -> MemoryOpResult((bits(8 * 'n), mem_meta))
val mem_read_priv_meta : forall 'n, 0 < 'n <= max_mem_access . (MemoryAccessType(mem_payload), page_based_mem_type, Privilege, physaddr, int('n), bool, bool, bool, bool) -> MemoryOpResult((bits(8 * 'n), mem_meta))

// The most generic memory read operation
function mem_read_priv_meta (access, pbmt, priv, paddr, width, aq, rl, res, meta) = {
  let result : MemoryOpResult((bits(8 * 'n), mem_meta)) = match (aq, rl, res) {
    (false, true,  false) => throw(Error_not_implemented("load.rl")),
    (false, true,  true)  => throw(Error_not_implemented("lr.rl")),
    (_, _, _)             => checked_mem_read(access, pbmt, priv, paddr, width, aq, rl, res, meta)
  };
  match result {
    Ok(value, _) => mem_read_callback(to_str(access), bits_of(paddr), width, value),
    Err(e) => mem_exception_callback(bits_of(paddr), exceptionType_bits(e)),
  };
  result
}

function mem_read_meta (access, pbmt, paddr, width, aq, rl, res, meta) =
  mem_read_priv_meta(access, pbmt, effectivePrivilege(access, mstatus, cur_privilege), paddr, width, aq, rl, res, meta)

// Specialized mem_read_meta that drops the metadata
function mem_read_priv (access, pbmt, priv, paddr, width, aq, rl, res) =
  MemoryOpResult_drop_meta(mem_read_priv_meta(access, pbmt, priv, paddr, width, aq, rl, res, false))

// Specialized mem_read_priv that operates at the default effective privilege
function mem_read (access, pbmt, paddr, width, aq, rel, res) =
  mem_read_priv(access, pbmt, effectivePrivilege(access, mstatus, cur_privilege), paddr, width, aq, rel, res)

// This function is always called before `mem_write_value`, i.e. it is not used before `mem_write_value_priv`.
// It hence operates at effective privilege.
val mem_write_ea : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), MemoryAccessType(mem_payload), page_based_mem_type, bool, bool, bool) -> MemoryOpResult(unit)
function mem_write_ea(paddr, width, access, pbmt, aq, rl, con) = {
  let priv = effectivePrivilege(access, mstatus, cur_privilege);

  // This function should only succeed when `mem_write_value` would
  // succeed, and fail when `mem_write_value` would fail. This means
  // it should at least perform the same PMP/PMA checks, and includes
  // matching behavior for split accesses.
  //
  // However, there is a corner case that is not handled here: writes
  // to MMIO regions, where the failure of those writes can only be
  // determined currently by actually trying to perform those
  // writes. In such cases, `mem_write_ea` could still succeed when
  // the `mem_write_value` would fail. Since `mem_write_ea` is used
  // only for the concurrency model, this will be an issue when that
  // model is extended for MMIO, but until then, this should suffice
  // for concurrency of RAM accesses.

  let access_info : Phys_Mem_Access_Info = match check_pma_with_pmp_priority(access, pbmt, priv, paddr, width, con) {
    Ok(access_info) => access_info,
    Err(e)          => return Err(e),
  };

  let ('N, 'split_width) = split_misaligned(paddr, width, access_info.granule_size_exp, access_info.splittable);

  let paddr_bits = bits_of(paddr);

  let (first, last, step) = misaligned_order(N);
  var i : range(0, 'N - 1) = first;
  var finished : bool = false;

  let wk = write_kind_of_flags(aq, rl, con);

  repeat {
    let offset = i;
    let paddr = Physaddr(paddr_bits + (offset * split_width));

    match pmpCheck(paddr, split_width, access, priv) {
      Some(e) => return Err(e),
      None()  => write_ram_ea(wk, paddr, split_width),
    };

    if offset == last then {
      finished = true
    } else {
      i = offset + step
    }

  } until finished;

  Ok(())
}

// This lets the Rocq extraction know why the repeat loop above terminates
termination_measure mem_write_ea repeat N

// dispatches to MMIO regions or physical memory regions depending on physical memory map
function checked_mem_write forall 'n, 0 < 'n <= max_mem_access . (
  paddr : physaddr,
  width : int('n),
  data: bits(8 * 'n),
  access : MemoryAccessType(mem_payload),
  pbmt : page_based_mem_type,
  priv : Privilege,
  meta: mem_meta,
  aq : bool,
  rl : bool,
  con : bool,
) -> MemoryOpResult(bool) = {

  let access_info : Phys_Mem_Access_Info = match check_pma_with_pmp_priority(access, pbmt, priv, paddr, width, con) {
    Ok(access_info) => access_info,
    Err(e)          => return Err(e),
  };

  // If the store is misaligned or an allowed misaligned access,
  // split into `N` (single-copy-atomic) memory operations, each
  // of `split_width` width. If the store is aligned, then `N` = 1
  // and `split_width` == `width`.
  let ('N, 'split_width) = split_misaligned(paddr, width, access_info.granule_size_exp, access_info.splittable);
  // TODO: handle any splits of metadata across the splits.

  let paddr_bits = bits_of(paddr);
  var write_success : bool = true;

  let (first, last, step) = misaligned_order(N);
  var i : range(0, 'N - 1) = first;
  var finished : bool = false;

  let wk = write_kind_of_flags(aq, rl, con);

  repeat {
    let offset = i;
    let paddr = Physaddr(paddr_bits + (offset * split_width));

    // As mentioned above (see `checked_mem_read()`), PMP checks are
    // done on each split access.
    match pmpCheck(paddr, split_width, access, priv) {
      Some(e) => return Err(e),
      None()  => (),
    };

    let write_value = data[(8 * (offset + 1) * split_width) - 1 .. 8 * offset * split_width];

    // See comment above in `checked_mem_read` about the
    // homogeneity of the split accesses.
    if   within_mmio_writable(paddr, split_width)
    then match mmio_write(paddr, split_width, write_value) {
      Ok(v)  => write_success = write_success & v,
      Err(e) => return Err(e),
    } else {
      // This assumes that the same metadata applies to every split.
      let v = write_ram(wk, paddr, split_width, write_value, meta);
      write_success = write_success & v
    };

    if offset == last then {
      finished = true
    } else {
      i = offset + step
    }
  } until finished;

  Ok(write_success)
}

// This lets the Rocq extraction know why the repeat loop above terminates
termination_measure checked_mem_write repeat N

// Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers.

// Memory write with an explicit metadata value.  Metadata writes are
// currently assumed to have the same alignment constraints as their
// data.
val mem_write_value_priv_meta : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), MemoryAccessType(mem_payload), page_based_mem_type, Privilege, mem_meta, bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value_priv_meta (paddr, width, value, access, pbmt, priv, meta, aq, rl, con) = {
  let result = checked_mem_write(paddr, width, value, access, pbmt, priv, meta, aq, rl, con);
  match result {
    Ok(_) => mem_write_callback(to_str(access), bits_of(paddr), width, value),
    Err(e) => mem_exception_callback(bits_of(paddr), exceptionType_bits(e)),
  };
  result
}

// Memory write with explicit Privilege and MemoryAccessType, and implicit metadata
val mem_write_value_priv : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), Privilege, MemoryAccessType(mem_payload), page_based_mem_type, bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value_priv (paddr, width, value, priv, access, pbmt, aq, rl, con) =
  mem_write_value_priv_meta(paddr, width, value, access, pbmt, priv, default_meta, aq, rl, con)

// Memory write with explicit metadata and MemoryAccessType, and implicit Privilege
val mem_write_value_meta : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), MemoryAccessType(mem_payload), page_based_mem_type, mem_meta, bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value_meta (paddr, width, value, access, pbmt, meta, aq, rl, con) = {
  let ep = effectivePrivilege(access, mstatus, cur_privilege);
  mem_write_value_priv_meta(paddr, width, value, access, pbmt, ep, meta, aq, rl, con)
}

// Memory write with explicit MemoryAccessType, default metadata and implicit Privilege
val mem_write_value : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), MemoryAccessType(mem_payload), page_based_mem_type, bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value (paddr, width, value, access, pbmt, aq, rl, con) = {
  mem_write_value_meta(paddr, width, value, access, pbmt, default_meta, aq, rl, con)
}
