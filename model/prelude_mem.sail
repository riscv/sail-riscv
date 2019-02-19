/* These functions define the primitives for physical memory access.
 * They depend on the XLEN of the architecture.
 */

val __WriteRAM = {lem: "MEMw", _: "write_ram"} : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> bool effect {wmv}

val __WriteRAM_release = {lem: "MEMw_release", _: "write_ram"} : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> bool effect {wmv}

val __WriteRAM_strong_release = {lem: "MEMw_strong_release", _: "write_ram"} : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> bool effect {wmv}

val __WriteRAM_conditional = {lem: "MEMw_conditional", _: "write_ram"} : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> bool effect {wmv}

val __WriteRAM_conditional_release = {lem: "MEMw_conditional_release", _: "write_ram"} : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> bool effect {wmv}

val __WriteRAM_conditional_strong_release = {lem: "MEMw_conditional_strong_release", _: "write_ram"} : forall 'n 'm.
  (atom('m), atom('n), bits('m), bits('m), bits(8 * 'n)) -> bool effect {wmv}

val __RISCV_write : forall 'n. (xlenbits, atom('n), bits(8 * 'n), bool, bool, bool) -> bool effect {wmv}
function __RISCV_write (addr, width, data, aq, rl, con) =
  match (aq, rl, con) {
    (false, false, false) => __WriteRAM(sizeof(xlen), width, EXTZ(0x0), addr, data),
    (false, true,  false) => __WriteRAM_release(sizeof(xlen), width, EXTZ(0x0), addr, data),
    (false, false, true)  => __WriteRAM_conditional(sizeof(xlen), width, EXTZ(0x0), addr, data),
    (false, true,  true)  => __WriteRAM_conditional_release(sizeof(xlen), width, EXTZ(0x0), addr, data),
    (true,  true,  false) => __WriteRAM_strong_release(sizeof(xlen), width, EXTZ(0x0), addr, data),
    (true,  true,  true)  => __WriteRAM_conditional_strong_release(sizeof(xlen), width, EXTZ(0x0), addr, data),
    (true,  false, false) => false,
    (true,  false, true)  => false
  }

val __TraceMemoryWrite : forall 'n 'm.
  (atom('n), bits('m), bits(8 * 'n)) -> unit

val __ReadRAM = { lem: "MEMr", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_acquire = { lem: "MEMr_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_strong_acquire = { lem: "MEMr_strong_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_reserved = { lem: "MEMr_reserved", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_reserved_acquire = { lem: "MEMr_reserved_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val __ReadRAM_reserved_strong_acquire = { lem: "MEMr_reserved_strong_acquire", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
  (atom('m), atom('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

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
