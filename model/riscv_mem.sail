/* Physical memory model.
 *
 * This assumes that the platform memory map has been defined, so that accesses
 * to MMIO regions can be dispatched.
 *
 * The implementation below supports the reading and writing of memory
 * metadata in addition to raw memory data.
 *
 * The external API for this module is
 *   {mem_read, mem_read_meta, mem_write_ea, mem_write_value_meta, mem_write_value}
 * where mem_write_value is a special case of mem_write_value_meta that uses
 * a default value of the metadata.
 *
 * The internal implementation first performs a PMP check (if PMP is
 * enabled), and then dispatches to MMIO regions or physical memory as
 * per the platform memory map.
 */

function is_aligned_addr forall 'n. (addr : xlenbits, width : atom('n)) -> bool =
  unsigned(addr) % width == 0

function read_kind_of_flags (aq : bool, rl : bool, res : bool) -> option(read_kind) =
  match (aq, rl, res) {
    (false, false, false) => Some(Read_plain),
    (true, false, false)  => Some(Read_RISCV_acquire),
    (true, true, false)   => Some(Read_RISCV_strong_acquire),
    (false, false, true)  => Some(Read_RISCV_reserved),
    (true, false, true)   => Some(Read_RISCV_reserved_acquire),
    (true, true, true)    => Some(Read_RISCV_reserved_strong_acquire),
    (false, true, false)  => None(), /* should these be instead throwing error_not_implemented as below? */
    (false, true, true)   => None()
  }

// only used for actual memory regions, to avoid MMIO effects
function phys_mem_read forall 'n, 0 < 'n <= max_mem_access . (t : AccessType(ext_access_type), paddr : xlenbits, width : atom('n), aq : bool, rl: bool, res : bool, meta : bool) -> MemoryOpResult((bits(8 * 'n), mem_meta)) = {
  let result = (match read_kind_of_flags(aq, rl, res) {
    Some(rk) => Some(read_ram(rk, paddr, width, meta)),
    None()   => None()
  }) : option((bits(8 * 'n), mem_meta));
  match (t, result) {
    (Execute(),  None()) => MemException(E_Fetch_Access_Fault()),
    (Read(Data), None()) => MemException(E_Load_Access_Fault()),
    (_,          None()) => MemException(E_SAMO_Access_Fault()),
    (_,      Some(v, m)) => { if   get_config_print_mem()
                              then print_mem("mem[" ^ to_str(t) ^ "," ^ BitStr(paddr) ^ "] -> " ^ BitStr(v));
                              MemValue(v, m) }
  }
}

/* dispatches to MMIO regions or physical memory regions depending on physical memory map */
function checked_mem_read forall 'n, 0 < 'n <= max_mem_access . (t : AccessType(ext_access_type), paddr : xlenbits, width : atom('n), aq : bool, rl : bool, res: bool, meta : bool) -> MemoryOpResult((bits(8 * 'n), mem_meta)) =
  if   within_mmio_readable(paddr, width)
  then MemoryOpResult_add_meta(mmio_read(t, paddr, width), default_meta)
  else if within_phys_mem(paddr, width)
  then phys_mem_read(t, paddr, width, aq, rl, res, meta)
  else match t {
    Execute()  => MemException(E_Fetch_Access_Fault()),
    Read(Data) => MemException(E_Load_Access_Fault()),
    _          => MemException(E_SAMO_Access_Fault())
  }

/* PMP checks if enabled */
function pmp_mem_read forall 'n, 0 < 'n <= max_mem_access . (t : AccessType(ext_access_type), paddr : xlenbits, width : atom('n), aq : bool, rl : bool, res: bool, meta : bool) -> MemoryOpResult((bits(8 * 'n), mem_meta)) =
  if   (~ (plat_enable_pmp ()))
  then checked_mem_read(t, paddr, width, aq, rl, res, meta)
  else {
    match pmpCheck(paddr, width, t, effectivePrivilege(t, mstatus, cur_privilege)) {
      None()  => checked_mem_read(t, paddr, width, aq, rl, res, meta),
      Some(e) => MemException(e)
    }
  }

/* Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers. */

$ifdef RVFI_DII
val rvfi_read : forall 'n, 'n > 0. (xlenbits, atom('n), MemoryOpResult(bits(8 * 'n))) -> unit effect {wreg}
function rvfi_read (addr, width, result) = {
  rvfi_exec->rvfi_mem_addr() = EXTZ(addr);
  match result {
    MemValue(v) => if   width <= 8
                   then { rvfi_exec->rvfi_mem_rdata() = sail_zero_extend(v,64);
                          rvfi_exec->rvfi_mem_rmask() = rvfi_encode_width_mask(width) }
                   else { rvfi_exec->rvfi_mem_rdata() = v[63..0];
                          rvfi_exec->rvfi_mem_rmask() = 0xFF},
    MemException(_) => ()
  };
}
$else
val rvfi_read : forall 'n, 'n > 0. (xlenbits, atom('n), MemoryOpResult(bits(8 * 'n))) -> unit
function rvfi_read (addr, width, value) = ()
$endif

/* NOTE: The rreg effect is due to MMIO. */
$ifdef RVFI_DII
val mem_read      : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), xlenbits, atom('n), bool, bool, bool)       -> MemoryOpResult(bits(8 * 'n))             effect {wreg, rmem, rmemt, rreg, escape}
val mem_read_meta : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), xlenbits, atom('n), bool, bool, bool, bool) -> MemoryOpResult((bits(8 * 'n), mem_meta)) effect {wreg, rmem, rmemt, rreg, escape}
$else
val mem_read      : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), xlenbits, atom('n), bool, bool, bool)       -> MemoryOpResult(bits(8 * 'n))             effect {rmem, rmemt, rreg, escape}
val mem_read_meta : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), xlenbits, atom('n), bool, bool, bool, bool) -> MemoryOpResult((bits(8 * 'n), mem_meta)) effect {rmem, rmemt, rreg, escape}
$endif

function mem_read_meta (typ, paddr, width, aq, rl, res, meta) = {
  let result : MemoryOpResult((bits(8 * 'n), mem_meta)) =
    if (aq | res) & (~ (is_aligned_addr(paddr, width)))
    then MemException(E_Load_Addr_Align())
    else match (aq, rl, res) {
      (false, true,  false) => throw(Error_not_implemented("load.rl")),
      (false, true,  true)  => throw(Error_not_implemented("lr.rl")),
      (_, _, _)             => pmp_mem_read(typ, paddr, width, aq, rl, res, meta)
    };
  rvfi_read(paddr, width, MemoryOpResult_drop_meta(result));
  result
}

function mem_read (typ, paddr, width, aq, rl, res) =
  MemoryOpResult_drop_meta(mem_read_meta(typ, paddr, width, aq, rl, res, false))

val mem_write_ea : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, atom('n), bool, bool, bool) -> MemoryOpResult(unit) effect {eamem, escape}

function mem_write_ea (addr, width, aq, rl, con) = {
  if (rl | con) & (~ (is_aligned_addr(addr, width)))
  then MemException(E_SAMO_Addr_Align())
  else match (aq, rl, con) {
    (false, false, false) => MemValue(write_ram_ea(Write_plain, addr, width)),
    (false, true,  false) => MemValue(write_ram_ea(Write_RISCV_release, addr, width)),
    (false, false, true)  => MemValue(write_ram_ea(Write_RISCV_conditional, addr, width)),
    (false, true , true)  => MemValue(write_ram_ea(Write_RISCV_conditional_release, addr, width)),
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  true,  false) => MemValue(write_ram_ea(Write_RISCV_strong_release, addr, width)),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq")),
    (true,  true , true)  => MemValue(write_ram_ea(Write_RISCV_conditional_strong_release, addr, width))
  }
}

$ifdef RVFI_DII
val rvfi_write : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, atom('n), bits(8 * 'n)) -> unit effect {wreg}
function rvfi_write (addr, width, value) = {
  rvfi_exec->rvfi_mem_addr() = EXTZ(addr);
  if width <= 8 then {
    rvfi_exec->rvfi_mem_wdata() = sail_zero_extend(value,64);
    rvfi_exec->rvfi_mem_wmask() = rvfi_encode_width_mask(width);
  } else {
    rvfi_exec->rvfi_mem_wdata() = value[63..0];
    rvfi_exec->rvfi_mem_wmask() = 0xFF;
  }
}
$else
val rvfi_write : forall 'n, 'n > 0. (xlenbits, atom('n), bits(8 * 'n)) -> unit
function rvfi_write (addr, width, value) = ()
$endif

// only used for actual memory regions, to avoid MMIO effects
function phys_mem_write forall 'n, 0 < 'n <= max_mem_access . (wk : write_kind, paddr : xlenbits, width : atom('n), data : bits(8 * 'n), meta : mem_meta) -> MemoryOpResult(bool) = {
  rvfi_write(paddr, width, data);
  let result = MemValue(write_ram(wk, paddr, width, data, meta));
  if   get_config_print_mem()
  then print_mem("mem[" ^ BitStr(paddr) ^ "] <- " ^ BitStr(data));
  result
}

/* dispatches to MMIO regions or physical memory regions depending on physical memory map */
function checked_mem_write forall 'n, 0 < 'n <= max_mem_access . (wk : write_kind, paddr : xlenbits, width : atom('n), data: bits(8 * 'n), meta: mem_meta) -> MemoryOpResult(bool) =
  if   within_mmio_writable(paddr, width)
  then mmio_write(paddr, width, data)
  else if within_phys_mem(paddr, width)
  then phys_mem_write(wk, paddr, width, data, meta)
  else MemException(E_SAMO_Access_Fault())

/* PMP checks if enabled */
function pmp_mem_write forall 'n, 0 < 'n <= max_mem_access . (wk: write_kind, paddr : xlenbits, width : atom('n), data: bits(8 * 'n), ext_acc: ext_access_type, meta: mem_meta) -> MemoryOpResult(bool) =
  if   (~ (plat_enable_pmp ()))
  then checked_mem_write(wk, paddr, width, data, meta)
  else {
    let typ : AccessType(ext_access_type) = Write(ext_acc);
    match pmpCheck(paddr, width, typ, effectivePrivilege(typ, mstatus, cur_privilege)) {
      None()  => checked_mem_write(wk, paddr, width, data, meta),
      Some(e) => MemException(e)
    }
  }

/* Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers. */

/* Memory write with an explicit metadata value.  Metadata writes are
 * currently assumed to have the same alignment constraints as their
 * data.
 * NOTE: The wreg effect is due to MMIO, the rreg is due to checking mtime.
 */
val mem_write_value_meta : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, atom('n), bits(8 * 'n), ext_access_type, mem_meta, bool, bool, bool) -> MemoryOpResult(bool) effect {wmv, wmvt, rreg, wreg, escape}
function mem_write_value_meta (paddr, width, value, ext_acc, meta, aq, rl, con) = {
  rvfi_write(paddr, width, value);
  if (rl | con) & (~ (is_aligned_addr(paddr, width)))
  then MemException(E_SAMO_Addr_Align())
  else match (aq, rl, con) {
    (false, false, false) => pmp_mem_write(Write_plain, paddr, width, value, ext_acc, meta),
    (false, true,  false) => pmp_mem_write(Write_RISCV_release, paddr, width, value, ext_acc, meta),
    (false, false, true)  => pmp_mem_write(Write_RISCV_conditional, paddr, width, value, ext_acc, meta),
    (false, true , true)  => pmp_mem_write(Write_RISCV_conditional_release, paddr, width, value, ext_acc, meta),
    (true,  true,  false) => pmp_mem_write(Write_RISCV_strong_release, paddr, width, value, ext_acc, meta),
    (true,  true , true)  => pmp_mem_write(Write_RISCV_conditional_strong_release, paddr, width, value, ext_acc, meta),
    // throw an illegal instruction here?
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq"))
  }
}

/* Memory write with a default metadata value. */
val mem_write_value : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, atom('n), bits(8 * 'n), bool, bool, bool) -> MemoryOpResult(bool) effect {wmv, wmvt, rreg, wreg, escape}
function mem_write_value (paddr, width, value, aq, rl, con) =
  mem_write_value_meta(paddr, width, value, default_write_acc, default_meta, aq, rl, con)
