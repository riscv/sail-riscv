/* These functions define the primitives for physical memory access.
 * They depend on the XLEN of the architecture.
 *
 * They also depend on the type of metadata that is read and written
 * to physical memory.  For models that do not require this metadata,
 * a unit type can be used.
 */

val write_ram : forall 'n, 'n > 0. (write_kind, xlenbits, atom('n), bits(8 * 'n), mem_meta) -> bool effect {wmv, wmvt}
function write_ram(wk, addr, width, data, meta) = {
  /* Write out metadata only if the value write succeeds.
   * It is assumed for now that this write always succeeds;
   * there is currently no return value.
   * FIXME: We should convert the external API to consume
   * the value along with the metadata to ensure atomicity.
   */
  let ret : bool = __write_mem(wk, sizeof(xlen), addr, width, data);
  if ret then __WriteRAM_Meta(addr, width, meta);
  ret
}

val __TraceMemoryWrite : forall 'n 'm.
  (atom('n), bits('m), bits(8 * 'n)) -> unit

val __ReadRAM = { lem: "MEMr", coq: "MEMr", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_acquire = { lem: "MEMr_acquire", coq: "MEMr_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_strong_acquire = { lem: "MEMr_strong_acquire", coq: "MEMr_strong_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_reserved = { lem: "MEMr_reserved", coq: "MEMr_reserved", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_reserved_acquire = { lem: "MEMr_reserved_acquire", coq: "MEMr_reserved_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_reserved_strong_acquire = { lem: "MEMr_reserved_strong_acquire", coq: "MEMr_reserved_strong_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

/* FIXME: the metadata is currently not read atomically wrt the value. */
val __RISCV_read : forall 'n, 'n >= 0. (xlenbits, atom('n), bool, bool, bool) -> option(bits(8 * 'n)) effect {rmem}
function __RISCV_read (addr, width, aq, rl, res) =
  match (aq, rl, res) {
    (false, false, false) => Some(__ReadRAM(sizeof(xlen), width, EXTZ(0x0), addr)),
    (true,  false, false) => Some(__ReadRAM_acquire(sizeof(xlen), width, EXTZ(0x0), addr)),
    (true,  true,  false) => Some(__ReadRAM_strong_acquire(sizeof(xlen), width, EXTZ(0x0), addr)),
    (false, false, true)  => Some(__ReadRAM_reserved(sizeof(xlen), width, EXTZ(0x0), addr)),
    (true,  false, true)  => Some(__ReadRAM_reserved_acquire(sizeof(xlen), width, EXTZ(0x0), addr)),
    (true,  true,  true)  => Some(__ReadRAM_reserved_strong_acquire(sizeof(xlen), width, EXTZ(0x0), addr)),
    (false, true,  false) => None(),
    (false, true,  true)  => None()
  }

val __TraceMemoryRead : forall 'n 'm. (atom('n), bits('m), bits(8 * 'n)) -> unit
