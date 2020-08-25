/* Mapping of csr addresses to their names. */

val csr_name_map : csreg <-> string

scattered mapping csr_name_map

/* user trap setup */
mapping clause csr_name_map = 0x000  <-> "ustatus"
mapping clause csr_name_map = 0x004  <-> "uie"
mapping clause csr_name_map = 0x005  <-> "utvec"
/* user trap handling */
mapping clause csr_name_map = 0x040  <-> "uscratch"
mapping clause csr_name_map = 0x041  <-> "uepc"
mapping clause csr_name_map = 0x042  <-> "ucause"
mapping clause csr_name_map = 0x043  <-> "utval"
mapping clause csr_name_map = 0x044  <-> "uip"
/* user floating-point context */
mapping clause csr_name_map = 0x001  <-> "fflags"
mapping clause csr_name_map = 0x002  <-> "frm"
mapping clause csr_name_map = 0x003  <-> "fcsr"
/* counter/timers */
mapping clause csr_name_map = 0xC00  <-> "cycle"
mapping clause csr_name_map = 0xC01  <-> "time"
mapping clause csr_name_map = 0xC02  <-> "instret"
mapping clause csr_name_map = 0xC80  <-> "cycleh"
mapping clause csr_name_map = 0xC81  <-> "timeh"
mapping clause csr_name_map = 0xC82  <-> "instreth"
/* TODO: other hpm counters */
/* supervisor trap setup */
mapping clause csr_name_map = 0x100  <-> "sstatus"
mapping clause csr_name_map = 0x102  <-> "sedeleg"
mapping clause csr_name_map = 0x103  <-> "sideleg"
mapping clause csr_name_map = 0x104  <-> "sie"
mapping clause csr_name_map = 0x105  <-> "stvec"
mapping clause csr_name_map = 0x106  <-> "scounteren"
/* supervisor trap handling */
mapping clause csr_name_map = 0x140  <-> "sscratch"
mapping clause csr_name_map = 0x141  <-> "sepc"
mapping clause csr_name_map = 0x142  <-> "scause"
mapping clause csr_name_map = 0x143  <-> "stval"
mapping clause csr_name_map = 0x144  <-> "sip"
/* supervisor protection and translation */
mapping clause csr_name_map = 0x180  <-> "satp"
/* machine information registers */
mapping clause csr_name_map = 0xF11  <-> "mvendorid"
mapping clause csr_name_map = 0xF12  <-> "marchid"
mapping clause csr_name_map = 0xF13  <-> "mimpid"
mapping clause csr_name_map = 0xF14  <-> "mhartid"
/* machine trap setup */
mapping clause csr_name_map = 0x300  <-> "mstatus"
mapping clause csr_name_map = 0x301  <-> "misa"
mapping clause csr_name_map = 0x302  <-> "medeleg"
mapping clause csr_name_map = 0x303  <-> "mideleg"
mapping clause csr_name_map = 0x304  <-> "mie"
mapping clause csr_name_map = 0x305  <-> "mtvec"
mapping clause csr_name_map = 0x306  <-> "mcounteren"
mapping clause csr_name_map = 0x320  <-> "mcountinhibit"
/* machine trap handling */
mapping clause csr_name_map = 0x340  <-> "mscratch"
mapping clause csr_name_map = 0x341  <-> "mepc"
mapping clause csr_name_map = 0x342  <-> "mcause"
mapping clause csr_name_map = 0x343  <-> "mtval"
mapping clause csr_name_map = 0x344  <-> "mip"
/* machine protection and translation */
mapping clause csr_name_map = 0x3A0  <-> "pmpcfg0"
mapping clause csr_name_map = 0x3A1  <-> "pmpcfg1"
mapping clause csr_name_map = 0x3A2  <-> "pmpcfg2"
mapping clause csr_name_map = 0x3A3  <-> "pmpcfg3"
mapping clause csr_name_map = 0x3B0  <-> "pmpaddr0"
mapping clause csr_name_map = 0x3B1  <-> "pmpaddr1"
mapping clause csr_name_map = 0x3B2  <-> "pmpaddr2"
mapping clause csr_name_map = 0x3B3  <-> "pmpaddr3"
mapping clause csr_name_map = 0x3B4  <-> "pmpaddr4"
mapping clause csr_name_map = 0x3B5  <-> "pmpaddr5"
mapping clause csr_name_map = 0x3B6  <-> "pmpaddr6"
mapping clause csr_name_map = 0x3B7  <-> "pmpaddr7"
mapping clause csr_name_map = 0x3B8  <-> "pmpaddr8"
mapping clause csr_name_map = 0x3B9  <-> "pmpaddr9"
mapping clause csr_name_map = 0x3BA  <-> "pmpaddr10"
mapping clause csr_name_map = 0x3BB  <-> "pmpaddr11"
mapping clause csr_name_map = 0x3BC  <-> "pmpaddr12"
mapping clause csr_name_map = 0x3BD  <-> "pmpaddr13"
mapping clause csr_name_map = 0x3BE  <-> "pmpaddr14"
mapping clause csr_name_map = 0x3BF  <-> "pmpaddr15"
/* machine counters/timers */
mapping clause csr_name_map = 0xB00  <-> "mcycle"
mapping clause csr_name_map = 0xB02  <-> "minstret"
mapping clause csr_name_map = 0xB80  <-> "mcycleh"
mapping clause csr_name_map = 0xB82  <-> "minstreth"
/* TODO: other hpm counters and events */
/* trigger/debug */
mapping clause csr_name_map = 0x7a0  <-> "tselect"
mapping clause csr_name_map = 0x7a1  <-> "tdata1"
mapping clause csr_name_map = 0x7a2  <-> "tdata2"
mapping clause csr_name_map = 0x7a3  <-> "tdata3"

val csr_name : csreg -> string
overload to_str = {csr_name}

/* Extensions may want to add additional CSR registers to the CSR address map.
 * These scattered functions support access to such registers.
 *
 * The default implementation provides access to the CSRs added by the 'N'
 * extension.
 */


/* returns whether a CSR is defined and accessible at a given address
 * and privilege
 */
val ext_is_CSR_defined : (csreg, Privilege) -> bool effect {rreg}
scattered function ext_is_CSR_defined

/* returns the value of the CSR if it is defined */
val ext_read_CSR : csreg -> option(xlenbits) effect {rreg}
scattered function ext_read_CSR

/* returns new value (after legalisation) if the CSR is defined */
val ext_write_CSR : (csreg, xlenbits) -> option(xlenbits) effect {rreg, wreg}
scattered function ext_write_CSR