/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Physical memory model.
 *
 * This assumes that the platform memory map has been defined, so that accesses
 * to MMIO regions can be dispatched.
 *
 * The implementation below supports the reading and writing of memory
 * metadata in addition to raw memory data.
 *
 * The external API for this module is composed of three central functions
 *
 *   mem_read_priv_meta
 *   mem_write_ea
 *   mem_write_value_priv_meta
 *
 * and some special cases which partially apply these functions:
 *
 *   mem_read_priv - strips metadata from reads
 *   mem_read_meta - uses effectivePrivilege
 *   mem_read      - both of the above partial applications
 *
 *   mem_write_value_meta - uses effectivePrivilege
 *   mem_write_value_priv - uses a default value for metadata
 *   mem_write_value      - both of the above partial applications
 *
 * The internal implementation first performs a PMP check (if PMP is
 * enabled), and then dispatches to MMIO regions or physical memory as
 * per the platform memory map.
 *
 * A helper to check address alignment is also provided in the external API.
 *
 *   is_aligned_addr - checks for alignment of a physical or virtual address
 */

function is_aligned_paddr(Physaddr(addr) : physaddr, width : nat1) -> bool =
  unsigned(addr) % width == 0

function is_aligned_vaddr(Virtaddr(addr) : virtaddr, width : nat1) -> bool =
  unsigned(addr) % width == 0

function is_aligned_bits(vaddr : xlenbits, width : word_width) -> bool =
  match width {
    1 => true,
    2 => vaddr[0..0] == zeros(),
    4 => vaddr[1..0] == zeros(),
    8 => vaddr[2..0] == zeros(),
  }

overload is_aligned_addr = {is_aligned_paddr, is_aligned_vaddr, is_aligned_bits}

function read_kind_of_flags (aq : bool, rl : bool, res : bool) -> read_kind =
  match (aq, rl, res) {
    (false, false, false) => Read_plain,
    (true, false, false)  => internal_error(__FILE__, __LINE__, "Load with acquire semantics should be unreachable"),
    (true, true, false)   => internal_error(__FILE__, __LINE__, "Load with acquire-release semantics should be unreachable"),
    (false, false, true)  => Read_RISCV_reserved,
    (true, false, true)   => Read_RISCV_reserved_acquire,
    (true, true, true)    => Read_RISCV_reserved_strong_acquire,
    // This is never called with rl=true and aq=false.
    (false, true, false)  => internal_error(__FILE__, __LINE__, "Load with release semantics should be unreachable"),
    (false, true, true)   => internal_error(__FILE__, __LINE__, "Load-reserved with release semantics should be unreachable"),
  }

function write_kind_of_flags (aq : bool, rl : bool, con : bool) -> write_kind =
  match (aq, rl, con) {
    (false, false, false) => Write_plain,
    (false, true,  false) => internal_error(__FILE__, __LINE__, "Store with release semantics should be unreachable"),
    (false, false, true)  => Write_RISCV_conditional,
    (false, true , true)  => Write_RISCV_conditional_release,
    (true,  true,  false) => internal_error(__FILE__, __LINE__, "Store with aquire-release semantics should be unreachable"),
    (true,  true , true)  => Write_RISCV_conditional_strong_release,
    // This is never called with aq=true and rl=false.
    (true,  false, false) => internal_error(__FILE__, __LINE__, "Store with acquire semantics should be unreachable"),
    (true,  false, true)  => internal_error(__FILE__, __LINE__, "Store-conditional with acquire semantics should be unreachable"),
  }

// Check if access is permitted according to PMPs and PMAs.
val phys_access_check : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), Privilege, physaddr, int('n)) -> option(ExceptionType)
function phys_access_check (t, p, paddr, width) = {
  let pmpError : option(ExceptionType) = if sys_pmp_count == 0 then None() else pmpCheck(paddr, width, t, p);
  // TODO: Also check PMAs and select the highest priority fault.
  pmpError
}

/* dispatches to MMIO regions or physical memory regions depending on physical memory map */
function checked_mem_read forall 'n, 0 < 'n <= max_mem_access . (
  t : AccessType(ext_access_type),
  priv : Privilege,
  paddr : physaddr,
  width : int('n),
  aq : bool,
  rl : bool,
  res: bool,
  meta : bool,
) -> MemoryOpResult((bits(8 * 'n), mem_meta)) =
  match phys_access_check(t, priv, paddr, width) {
    Some(e) => Err(e),
    None() => {
      if   within_mmio_readable(paddr, width)
      then MemoryOpResult_add_meta(mmio_read(t, paddr, width), default_meta)
      else if within_phys_mem(paddr, width)
      then {
        let rk = read_kind_of_flags(aq, rl, res);
        Ok(read_ram(rk, paddr, width, meta))
      } else match t {
        InstructionFetch() => Err(E_Fetch_Access_Fault()),
        Read(Data) => Err(E_Load_Access_Fault()),
        _          => Err(E_SAMO_Access_Fault())
      }
    }
  }

/* Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers. */

val mem_read      : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), physaddr, int('n), bool, bool, bool)       -> MemoryOpResult(bits(8 * 'n))
val mem_read_priv : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), Privilege, physaddr, int('n), bool, bool, bool)       -> MemoryOpResult(bits(8 * 'n))
val mem_read_meta : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), physaddr, int('n), bool, bool, bool, bool) -> MemoryOpResult((bits(8 * 'n), mem_meta))
val mem_read_priv_meta : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), Privilege, physaddr, int('n), bool, bool, bool, bool) -> MemoryOpResult((bits(8 * 'n), mem_meta))

/* The most generic memory read operation */
function mem_read_priv_meta (typ, priv, paddr, width, aq, rl, res, meta) = {
  let result : MemoryOpResult((bits(8 * 'n), mem_meta)) =
    if (aq | res) & not(is_aligned_addr(paddr, width))
    then Err(E_Load_Addr_Align())
    else match (aq, rl, res) {
      (false, true,  false) => throw(Error_not_implemented("load.rl")),
      (false, true,  true)  => throw(Error_not_implemented("lr.rl")),
      (_, _, _)             => checked_mem_read(typ, priv, paddr, width, aq, rl, res, meta)
    };
  match result {
    Ok(value, _) => mem_read_callback(to_str(typ), bits_of(paddr), width, value),
    Err(e) => mem_exception_callback(bits_of(paddr), num_of_ExceptionType(e)),
  };
  result
}

function mem_read_meta (typ, paddr, width, aq, rl, res, meta) =
  mem_read_priv_meta(typ, effectivePrivilege(typ, mstatus, cur_privilege), paddr, width, aq, rl, res, meta)

/* Specialized mem_read_meta that drops the metadata */
function mem_read_priv (typ, priv, paddr, width, aq, rl, res) =
  MemoryOpResult_drop_meta(mem_read_priv_meta(typ, priv, paddr, width, aq, rl, res, false))

/* Specialized mem_read_priv that operates at the default effective privilege */
function mem_read (typ, paddr, width, aq, rel, res) =
  mem_read_priv(typ, effectivePrivilege(typ, mstatus, cur_privilege), paddr, width, aq, rel, res)

val mem_write_ea : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bool, bool, bool) -> MemoryOpResult(unit)
function mem_write_ea (addr, width, aq, rl, con) =
  if (rl | con) & not(is_aligned_addr(addr, width))
  then Err(E_SAMO_Addr_Align())
  else Ok(write_ram_ea(write_kind_of_flags(aq, rl, con), addr, width))

/* dispatches to MMIO regions or physical memory regions depending on physical memory map */
function checked_mem_write forall 'n, 0 < 'n <= max_mem_access . (
  paddr : physaddr,
  width : int('n),
  data: bits(8 * 'n),
  typ : AccessType(ext_access_type),
  priv : Privilege,
  meta: mem_meta,
  aq : bool,
  rl : bool,
  con : bool,
) -> MemoryOpResult(bool) =
  match phys_access_check(typ, priv, paddr, width) {
    Some(e) => Err(e),
    None() => {
      if   within_mmio_writable(paddr, width)
      then mmio_write(paddr, width, data)
      else if within_phys_mem(paddr, width)
      then {
        let wk = write_kind_of_flags(aq, rl, con);
        Ok(write_ram(wk, paddr, width, data, meta))
      } else Err(E_SAMO_Access_Fault())
    }
  }

/* Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers. */

/* Memory write with an explicit metadata value.  Metadata writes are
 * currently assumed to have the same alignment constraints as their
 * data.
 */
val mem_write_value_priv_meta : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), AccessType(ext_access_type), Privilege, mem_meta, bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value_priv_meta (paddr, width, value, typ, priv, meta, aq, rl, con) = {
  if (rl | con) & not(is_aligned_addr(paddr, width))
  then Err(E_SAMO_Addr_Align())
  else {
    let result = checked_mem_write(paddr, width, value, typ, priv, meta, aq, rl, con);
    match result {
      Ok(_) => mem_write_callback(to_str(typ), bits_of(paddr), width, value),
      Err(e) => mem_exception_callback(bits_of(paddr), num_of_ExceptionType(e)),
    };
    result
  }
}

/* Memory write with explicit Privilege, implicit AccessType and metadata */
val mem_write_value_priv : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), Privilege, bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value_priv (paddr, width, value, priv, aq, rl, con) =
  mem_write_value_priv_meta(paddr, width, value, Write(default_write_acc), priv, default_meta, aq, rl, con)

/* Memory write with explicit metadata and AccessType, implicit and Privilege */
val mem_write_value_meta : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), ext_access_type, mem_meta, bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value_meta (paddr, width, value, ext_acc, meta, aq, rl, con) = {
  let typ = Write(ext_acc);
  let ep = effectivePrivilege(typ, mstatus, cur_privilege);
  mem_write_value_priv_meta(paddr, width, value, typ, ep, meta, aq, rl, con)
}

/* Memory write with default AccessType, Privilege, and metadata */
val mem_write_value : forall 'n, 0 < 'n <= max_mem_access . (physaddr, int('n), bits(8 * 'n), bool, bool, bool) -> MemoryOpResult(bool)
function mem_write_value (paddr, width, value, aq, rl, con) = {
  mem_write_value_meta(paddr, width, value, default_write_acc, default_meta, aq, rl, con)
}
