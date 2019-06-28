/* Mapping of csr addresses to their names. */

val csr_name : csreg -> string
function csr_name(csr) = {
  match (csr) {
    /* user trap setup */
    0x000  => "ustatus",
    0x004  => "uie",
    0x005  => "utvec",
    /* user trap handling */
    0x040  => "uscratch",
    0x041  => "uepc",
    0x042  => "ucause",
    0x043  => "utval",
    0x044  => "uip",

    /* user floating-point context */
    0x001  => "fflags",
    0x002  => "frm",
    0x003  => "fcsr",
    /* counter/timers */
    0xC00  => "cycle",
    0xC01  => "time",
    0xC02  => "instret",
    0xC80  => "cycleh",
    0xC81  => "timeh",
    0xC82  => "instreth",
    /* TODO: other hpm counters */
    /* supervisor trap setup */
    0x100  => "sstatus",
    0x102  => "sedeleg",
    0x103  => "sideleg",
    0x104  => "sie",
    0x105  => "stvec",
    0x106  => "scounteren",
    /* supervisor trap handling */
    0x140  => "sscratch",
    0x141  => "sepc",
    0x142  => "scause",
    0x143  => "stval",
    0x144  => "sip",
    /* supervisor protection and translation */
    0x180  => "satp",
    /* machine information registers */
    0xF11  => "mvendorid",
    0xF12  => "marchid",
    0xF13  => "mimpid",
    0xF14  => "mhartid",
    /* machine trap setup */
    0x300  => "mstatus",
    0x301  => "misa",
    0x302  => "medeleg",
    0x303  => "mideleg",
    0x304  => "mie",
    0x305  => "mtvec",
    0x306  => "mcounteren",
    /* machine trap handling */
    0x340  => "mscratch",
    0x341  => "mepc",
    0x342  => "mcause",
    0x343  => "mtval",
    0x344  => "mip",

    0x3A0  => "pmpcfg0",
    0x3B0  => "pmpaddr0",
    /* TODO: machine protection and translation */
    /* machine counters/timers */
    0xB00  => "mcycle",
    0xB02  => "minstret",
    0xB80  => "mcycleh",
    0xB82  => "minstreth",
    /* TODO: other hpm counters and events */
    /* trigger/debug */
    0x7a0  => "tselect",
    _      => "UNKNOWN"
  }
}

overload to_str = {csr_name}

mapping csr_name_map : csreg <-> string = {
    /* user trap setup */
    0x000  <-> "ustatus",
    0x004  <-> "uie",
    0x005  <-> "utvec",
    /* user trap handling */
    0x040  <-> "uscratch",
    0x041  <-> "uepc",
    0x042  <-> "ucause",
    0x043  <-> "utval",
    0x044  <-> "uip",
    /* user floating-point context */
    0x001  <-> "fflags",
    0x002  <-> "frm",
    0x003  <-> "fcsr",
    /* counter/timers */
    0xC00  <-> "cycle",
    0xC01  <-> "time",
    0xC02  <-> "instret",
    0xC80  <-> "cycleh",
    0xC81  <-> "timeh",
    0xC82  <-> "instreth",
    /* TODO: other hpm counters */
    /* supervisor trap setup */
    0x100  <-> "sstatus",
    0x102  <-> "sedeleg",
    0x103  <-> "sideleg",
    0x104  <-> "sie",
    0x105  <-> "stvec",
    0x106  <-> "scounteren",
    /* supervisor trap handling */
    0x140  <-> "sscratch",
    0x141  <-> "sepc",
    0x142  <-> "scause",
    0x143  <-> "stval",
    0x144  <-> "sip",
    /* supervisor protection and translation */
    0x180  <-> "satp",
    /* machine information registers */
    0xF11  <-> "mvendorid",
    0xF12  <-> "marchid",
    0xF13  <-> "mimpid",
    0xF14  <-> "mhartid",
    /* machine trap setup */
    0x300  <-> "mstatus",
    0x301  <-> "misa",
    0x302  <-> "medeleg",
    0x303  <-> "mideleg",
    0x304  <-> "mie",
    0x305  <-> "mtvec",
    0x306  <-> "mcounteren",
    /* machine trap handling */
    0x340  <-> "mscratch",
    0x341  <-> "mepc",
    0x342  <-> "mcause",
    0x343  <-> "mtval",
    0x344  <-> "mip",
    /* machine protection and translation */
    0x3A0  <-> "pmpcfg0",
    0x3A1  <-> "pmpcfg1",
    0x3A2  <-> "pmpcfg2",
    0x3A3  <-> "pmpcfg3",
    0x3B0  <-> "pmpaddr0",
    0x3B1  <-> "pmpaddr1",
    0x3B2  <-> "pmpaddr2",
    0x3B3  <-> "pmpaddr3",
    0x3B4  <-> "pmpaddr4",
    0x3B5  <-> "pmpaddr5",
    0x3B6  <-> "pmpaddr6",
    0x3B7  <-> "pmpaddr7",
    0x3B8  <-> "pmpaddr8",
    0x3B9  <-> "pmpaddr9",
    0x3BA  <-> "pmpaddr10",
    0x3BB  <-> "pmpaddr11",
    0x3BC  <-> "pmpaddr12",
    0x3BD  <-> "pmpaddr13",
    0x3BE  <-> "pmpaddr14",
    0x3BF  <-> "pmpaddr15",
    /* machine counters/timers */
    0xB00  <-> "mcycle",
    0xB02  <-> "minstret",
    0xB80  <-> "mcycleh",
    0xB82  <-> "minstreth",
    /* TODO: other hpm counters and events */
    /* trigger/debug */
    0x7a0  <-> "tselect",
    0x7a1  <-> "tdata1",
    0x7a2  <-> "tdata2",
    0x7a3  <-> "tdata3"

    /* numeric fallback */
    /* reg    <-> hex_bits_12(reg) */
 }

