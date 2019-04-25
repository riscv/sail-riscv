/* Physical memory model.
 *
 * This assumes that the platform memory map has been defined, so that accesses
 * to MMIO regions can be dispatched.
 */

function is_aligned_addr forall 'n. (addr : xlenbits, width : atom('n)) -> bool =
  unsigned(addr) % width == 0

// only used for actual memory regions, to avoid MMIO effects
function phys_mem_read forall 'n, 'n > 0. (t : ReadType, addr : xlenbits, width : atom('n), aq : bool, rl: bool, res : bool) -> MemoryOpResult(bits(8 * 'n)) = {
  let result = (match (aq, rl, res) {
    (false, false, false) => Some(__read_mem(Read_plain, sizeof(xlen), addr, width)),
    (true, false, false)  => Some(__read_mem(Read_RISCV_acquire, sizeof(xlen), addr, width)),
    (true, true, false)   => Some(__read_mem(Read_RISCV_strong_acquire, sizeof(xlen), addr, width)),
    (false, false, true)  => Some(__read_mem(Read_RISCV_reserved, sizeof(xlen), addr, width)),
    (true, false, true)   => Some(__read_mem(Read_RISCV_reserved_acquire, sizeof(xlen), addr, width)),
    (true, true, true)    => Some(__read_mem(Read_RISCV_reserved_strong_acquire, sizeof(xlen), addr, width)),
    (false, true, false)  => None(), /* should these be instead throwing error_not_implemented as below? */
    (false, true, true)   => None()
  }) : option(bits(8 * 'n));
  match (t, result) {
    (Instruction, None()) => MemException(E_Fetch_Access_Fault),
    (Data, None())        => MemException(E_Load_Access_Fault),
    (_, Some(v))          => { print_mem("mem[" ^ t ^ "," ^ BitStr(addr) ^ "] -> " ^ BitStr(v));
                               MemValue(v) }
  }
}

function checked_mem_read forall 'n, 'n > 0. (t : ReadType, addr : xlenbits, width : atom('n), aq : bool, rl : bool, res: bool) -> MemoryOpResult(bits(8 * 'n)) =
  /* treat MMIO regions as not executable for now. TODO: this should actually come from PMP/PMA. */
  if   t == Data & within_mmio_readable(addr, width)
  then mmio_read(addr, width)
  else if within_phys_mem(addr, width)
  then phys_mem_read(t, addr, width, aq, rl, res)
  else MemException(E_Load_Access_Fault)

/* Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers. */

$ifdef RVFI_DII
val rvfi_read : forall 'n, 'n > 0. (xlenbits, atom('n), MemoryOpResult(bits(8 * 'n))) -> unit effect {wreg}
function rvfi_read (addr, width, result) = {
  rvfi_exec->rvfi_mem_addr() = addr;
  match result {
  MemValue(v) =>
    if width <= 8
    then {
      rvfi_exec->rvfi_mem_wdata() = sail_zero_extend(v,64);
      rvfi_exec->rvfi_mem_wmask() = to_bits(8,width)
    } else (),
  MemException(_) => ()
  };
}
$else
val rvfi_read : forall 'n, 'n > 0. (xlenbits, atom('n), MemoryOpResult(bits(8 * 'n))) -> unit
function rvfi_read (addr, width, value) = ()
$endif

/* NOTE: The rreg effect is due to MMIO. */
$ifdef RVFI_DII
val mem_read : forall 'n, 'n > 0. (xlenbits, atom('n), bool, bool, bool) -> MemoryOpResult(bits(8 * 'n)) effect {wreg, rmem, rreg, escape}
$else
val mem_read : forall 'n, 'n > 0. (xlenbits, atom('n), bool, bool, bool) -> MemoryOpResult(bits(8 * 'n)) effect {rmem, rreg, escape}
$endif

function mem_read (addr, width, aq, rl, res) = {
 let result : MemoryOpResult(bits(8 * 'n)) =
  if (aq | res) & (~ (is_aligned_addr(addr, width)))
  then MemException(E_Load_Addr_Align)
  else match (aq, rl, res) {
    (false, true,  false) => throw(Error_not_implemented("load.rl")),
    (false, true,  true)  => throw(Error_not_implemented("lr.rl")),
    (_, _, _)             => checked_mem_read(Data, addr, width, aq, rl, res)
  };
 rvfi_read(addr, width, result);
 result
}

val mem_write_ea : forall 'n, 'n > 0. (xlenbits, atom('n), bool, bool, bool) -> MemoryOpResult(unit) effect {eamem, escape}

function mem_write_ea (addr, width, aq, rl, con) = {
  if (rl | con) & (~ (is_aligned_addr(addr, width)))
  then MemException(E_SAMO_Addr_Align)
  else match (aq, rl, con) {
    (false, false, false) => MemValue(__write_mem_ea(Write_plain, sizeof(xlen), addr, width)),
    (false, true,  false) => MemValue(__write_mem_ea(Write_RISCV_release, sizeof(xlen), addr, width)),
    (false, false, true)  => MemValue(__write_mem_ea(Write_RISCV_conditional, sizeof(xlen), addr, width)),
    (false, true , true)  => MemValue(__write_mem_ea(Write_RISCV_conditional_release, sizeof(xlen), addr, width)),
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  true,  false) => MemValue(__write_mem_ea(Write_RISCV_strong_release, sizeof(xlen), addr, width)),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq")),
    (true,  true , true)  => MemValue(__write_mem_ea(Write_RISCV_conditional_strong_release, sizeof(xlen), addr, width))
  }
}

// only used for actual memory regions, to avoid MMIO effects
function phys_mem_write forall 'n, 'n > 0. (addr : xlenbits, width : atom('n), data : bits(8 * 'n), meta : mem_meta, aq : bool, rl : bool, con : bool) -> MemoryOpResult(bool) = {
  let result = (match (aq, rl, con) {
    (false, false, false) => MemValue(write_ram(Write_plain, addr, width, data, meta)),
    (false, true,  false) => MemValue(write_ram(Write_RISCV_release, addr, width, data, meta)),
    (false, false, true)  => MemValue(write_ram(Write_RISCV_conditional, addr, width, data, meta)),
    (false, true , true)  => MemValue(write_ram(Write_RISCV_conditional_release, addr, width, data, meta)),
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  true,  false) => MemValue(write_ram(Write_RISCV_strong_release, addr, width, data, meta)),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq")),
    (true,  true , true)  => MemValue(write_ram(Write_RISCV_conditional_strong_release, addr, width, data, meta))
  }) : MemoryOpResult(bool);
  print_mem("mem[" ^ BitStr(addr) ^ "] <- " ^ BitStr(data));
  result
}

// dispatches to MMIO regions or physical memory regions depending on physical memory map
function checked_mem_write forall 'n, 'n > 0. (addr : xlenbits, width : atom('n), data: bits(8 * 'n), meta: mem_meta, aq : bool, rl : bool, con : bool) -> MemoryOpResult(bool) =
  if   within_mmio_writable(addr, width)
  then mmio_write(addr, width, data)
  else if within_phys_mem(addr, width)
  then phys_mem_write(addr, width, data, meta, aq, rl, con)
  else MemException(E_SAMO_Access_Fault)

/* Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers. */

$ifdef RVFI_DII
val rvfi_write : forall 'n, 'n > 0. (xlenbits, atom('n), bits(8 * 'n)) -> unit effect {wreg}
function rvfi_write (addr, width, value) = {
  rvfi_exec->rvfi_mem_addr() = addr;
  if width <= 8 then {
    rvfi_exec->rvfi_mem_wdata() = sail_zero_extend(value,64);
    rvfi_exec->rvfi_mem_wmask() = to_bits(8,width);
  }
}
$else
val rvfi_write : forall 'n, 'n > 0. (xlenbits, atom('n), bits(8 * 'n)) -> unit
function rvfi_write (addr, width, value) = ()
$endif

/* Memory write with a default metadata value */
/* NOTE: The wreg effect is due to MMIO, the rreg is due to checking mtime. */
val mem_write_value : forall 'n, 'n > 0. (xlenbits, atom('n), bits(8 * 'n), bool, bool, bool) -> MemoryOpResult(bool) effect {wmv, wmvt, rreg, wreg, escape}
function mem_write_value (addr, width, value, aq, rl, con) = {
  rvfi_write(addr, width, value);
  if (rl | con) & (~ (is_aligned_addr(addr, width)))
  then MemException(E_SAMO_Addr_Align)
  else match (aq, rl, con) {
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq")),
    (_, _, _)             => checked_mem_write(addr, width, value, default_meta, aq, rl, con)
  }
}

/* Memory write with an explicit metadata value */
/* NOTE: The wreg effect is due to MMIO, the rreg is due to checking mtime. */
val mem_write_value_meta : forall 'n, 'n > 0. (xlenbits, atom('n), bits(8 * 'n), mem_meta, bool, bool, bool) -> MemoryOpResult(bool) effect {wmv, wmvt, rreg, wreg, escape}
function mem_write_value_meta (addr, width, value, meta, aq, rl, con) = {
  rvfi_write(addr, width, value);
  if (rl | con) & (~ (is_aligned_addr(addr, width)))
  then MemException(E_SAMO_Addr_Align)
  else match (aq, rl, con) {
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq")),
    (_, _, _)             => checked_mem_write(addr, width, value, meta, aq, rl, con)
  }
}
