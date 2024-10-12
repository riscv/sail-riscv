/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Mapping of csr addresses to their names. */

val csr_name_map : csreg <-> string

scattered mapping csr_name_map

// TODO: These csr_name_map definitions should be moved to the files
// corresponding to their extensions rather than all be here.

/* user entropy source */
mapping clause csr_name_map = 0x015  <-> "seed"
/* counter/timers */
mapping clause csr_name_map = 0xC00  <-> "cycle"
mapping clause csr_name_map = 0xC01  <-> "time"
mapping clause csr_name_map = 0xC02  <-> "instret"

mapping clause csr_name_map = 0xC80  <-> "cycleh"
mapping clause csr_name_map = 0xC81  <-> "timeh"
mapping clause csr_name_map = 0xC82  <-> "instreth"

/* supervisor trap setup */
mapping clause csr_name_map = 0x100  <-> "sstatus"
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
/* supervisor envcfg */
mapping clause csr_name_map = 0x10A  <-> "senvcfg"
/* machine trap setup */
mapping clause csr_name_map = 0x300  <-> "mstatus"
mapping clause csr_name_map = 0x301  <-> "misa"
mapping clause csr_name_map = 0x302  <-> "medeleg"
mapping clause csr_name_map = 0x303  <-> "mideleg"
mapping clause csr_name_map = 0x304  <-> "mie"
mapping clause csr_name_map = 0x305  <-> "mtvec"
mapping clause csr_name_map = 0x306  <-> "mcounteren"
mapping clause csr_name_map = 0x320  <-> "mcountinhibit"
/* machine envcfg */
mapping clause csr_name_map = 0x30A  <-> "menvcfg"
mapping clause csr_name_map = 0x31A  <-> "menvcfgh"
/* machine trap handling */
mapping clause csr_name_map = 0x340  <-> "mscratch"
mapping clause csr_name_map = 0x341  <-> "mepc"
mapping clause csr_name_map = 0x342  <-> "mcause"
mapping clause csr_name_map = 0x343  <-> "mtval"
mapping clause csr_name_map = 0x344  <-> "mip"
/* machine counters/timers */
mapping clause csr_name_map = 0xB00  <-> "mcycle"
mapping clause csr_name_map = 0xB02  <-> "minstret"

mapping clause csr_name_map = 0xB80  <-> "mcycleh"
mapping clause csr_name_map = 0xB82  <-> "minstreth"

val csr_name : csreg -> string
overload to_str = {csr_name}

/* Extensions may want to add additional CSR registers to the CSR address map.
 * These scattered functions support access to such registers.
 *
 * The default implementation provides access to the CSRs added by the 'N'
 * extension.
 */


/* returns whether a CSR exists
 */
val is_CSR_defined : (csreg) -> bool
scattered function is_CSR_defined

/* returns the value of the CSR if it is defined */
val read_CSR : csreg -> xlenbits
scattered function read_CSR

/* returns new value (after legalisation) if the CSR is defined */
val write_CSR : (csreg, xlenbits) -> xlenbits
scattered function write_CSR
