/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Hardware Performance Monitoring counters */
function clause extensionEnabled(Ext_Zihpm) = true

/* Hardware performance monitoring counters */
mapping clause csr_name_map = 0xC03  <-> "hpmcounter3"
mapping clause csr_name_map = 0xC04  <-> "hpmcounter4"
mapping clause csr_name_map = 0xC05  <-> "hpmcounter5"
mapping clause csr_name_map = 0xC06  <-> "hpmcounter6"
mapping clause csr_name_map = 0xC07  <-> "hpmcounter7"
mapping clause csr_name_map = 0xC08  <-> "hpmcounter8"
mapping clause csr_name_map = 0xC09  <-> "hpmcounter9"
mapping clause csr_name_map = 0xC0A  <-> "hpmcounter10"
mapping clause csr_name_map = 0xC0B  <-> "hpmcounter11"
mapping clause csr_name_map = 0xC0C  <-> "hpmcounter12"
mapping clause csr_name_map = 0xC0D  <-> "hpmcounter13"
mapping clause csr_name_map = 0xC0E  <-> "hpmcounter14"
mapping clause csr_name_map = 0xC0F  <-> "hpmcounter15"
mapping clause csr_name_map = 0xC10  <-> "hpmcounter16"
mapping clause csr_name_map = 0xC11  <-> "hpmcounter17"
mapping clause csr_name_map = 0xC12  <-> "hpmcounter18"
mapping clause csr_name_map = 0xC13  <-> "hpmcounter19"
mapping clause csr_name_map = 0xC14  <-> "hpmcounter20"
mapping clause csr_name_map = 0xC15  <-> "hpmcounter21"
mapping clause csr_name_map = 0xC16  <-> "hpmcounter22"
mapping clause csr_name_map = 0xC17  <-> "hpmcounter23"
mapping clause csr_name_map = 0xC18  <-> "hpmcounter24"
mapping clause csr_name_map = 0xC19  <-> "hpmcounter25"
mapping clause csr_name_map = 0xC1A  <-> "hpmcounter26"
mapping clause csr_name_map = 0xC1B  <-> "hpmcounter27"
mapping clause csr_name_map = 0xC1C  <-> "hpmcounter28"
mapping clause csr_name_map = 0xC1D  <-> "hpmcounter29"
mapping clause csr_name_map = 0xC1E  <-> "hpmcounter30"
mapping clause csr_name_map = 0xC1F  <-> "hpmcounter31"

mapping clause csr_name_map = 0xC83  <-> "hpmcounter3h"
mapping clause csr_name_map = 0xC84  <-> "hpmcounter4h"
mapping clause csr_name_map = 0xC85  <-> "hpmcounter5h"
mapping clause csr_name_map = 0xC86  <-> "hpmcounter6h"
mapping clause csr_name_map = 0xC87  <-> "hpmcounter7h"
mapping clause csr_name_map = 0xC88  <-> "hpmcounter8h"
mapping clause csr_name_map = 0xC89  <-> "hpmcounter9h"
mapping clause csr_name_map = 0xC8A  <-> "hpmcounter10h"
mapping clause csr_name_map = 0xC8B  <-> "hpmcounter11h"
mapping clause csr_name_map = 0xC8C  <-> "hpmcounter12h"
mapping clause csr_name_map = 0xC8D  <-> "hpmcounter13h"
mapping clause csr_name_map = 0xC8E  <-> "hpmcounter14h"
mapping clause csr_name_map = 0xC8F  <-> "hpmcounter15h"
mapping clause csr_name_map = 0xC90  <-> "hpmcounter16h"
mapping clause csr_name_map = 0xC91  <-> "hpmcounter17h"
mapping clause csr_name_map = 0xC92  <-> "hpmcounter18h"
mapping clause csr_name_map = 0xC93  <-> "hpmcounter19h"
mapping clause csr_name_map = 0xC94  <-> "hpmcounter20h"
mapping clause csr_name_map = 0xC95  <-> "hpmcounter21h"
mapping clause csr_name_map = 0xC96  <-> "hpmcounter22h"
mapping clause csr_name_map = 0xC97  <-> "hpmcounter23h"
mapping clause csr_name_map = 0xC98  <-> "hpmcounter24h"
mapping clause csr_name_map = 0xC99  <-> "hpmcounter25h"
mapping clause csr_name_map = 0xC9A  <-> "hpmcounter26h"
mapping clause csr_name_map = 0xC9B  <-> "hpmcounter27h"
mapping clause csr_name_map = 0xC9C  <-> "hpmcounter28h"
mapping clause csr_name_map = 0xC9D  <-> "hpmcounter29h"
mapping clause csr_name_map = 0xC9E  <-> "hpmcounter30h"
mapping clause csr_name_map = 0xC9F  <-> "hpmcounter31h"

/* hardware performance counter event selection */
mapping clause csr_name_map = 0x323  <-> "mhpmevent3"
mapping clause csr_name_map = 0x324  <-> "mhpmevent4"
mapping clause csr_name_map = 0x325  <-> "mhpmevent5"
mapping clause csr_name_map = 0x326  <-> "mhpmevent6"
mapping clause csr_name_map = 0x327  <-> "mhpmevent7"
mapping clause csr_name_map = 0x328  <-> "mhpmevent8"
mapping clause csr_name_map = 0x329  <-> "mhpmevent9"
mapping clause csr_name_map = 0x32A  <-> "mhpmevent10"
mapping clause csr_name_map = 0x32B  <-> "mhpmevent11"
mapping clause csr_name_map = 0x32C  <-> "mhpmevent12"
mapping clause csr_name_map = 0x32D  <-> "mhpmevent13"
mapping clause csr_name_map = 0x32E  <-> "mhpmevent14"
mapping clause csr_name_map = 0x32F  <-> "mhpmevent15"
mapping clause csr_name_map = 0x330  <-> "mhpmevent16"
mapping clause csr_name_map = 0x331  <-> "mhpmevent17"
mapping clause csr_name_map = 0x332  <-> "mhpmevent18"
mapping clause csr_name_map = 0x333  <-> "mhpmevent19"
mapping clause csr_name_map = 0x334  <-> "mhpmevent20"
mapping clause csr_name_map = 0x335  <-> "mhpmevent21"
mapping clause csr_name_map = 0x336  <-> "mhpmevent22"
mapping clause csr_name_map = 0x337  <-> "mhpmevent23"
mapping clause csr_name_map = 0x338  <-> "mhpmevent24"
mapping clause csr_name_map = 0x339  <-> "mhpmevent25"
mapping clause csr_name_map = 0x33A  <-> "mhpmevent26"
mapping clause csr_name_map = 0x33B  <-> "mhpmevent27"
mapping clause csr_name_map = 0x33C  <-> "mhpmevent28"
mapping clause csr_name_map = 0x33D  <-> "mhpmevent29"
mapping clause csr_name_map = 0x33E  <-> "mhpmevent30"
mapping clause csr_name_map = 0x33F  <-> "mhpmevent31"

/* machine hardware performance counters */
mapping clause csr_name_map = 0xB03  <-> "mhpmcounter3"
mapping clause csr_name_map = 0xB04  <-> "mhpmcounter4"
mapping clause csr_name_map = 0xB05  <-> "mhpmcounter5"
mapping clause csr_name_map = 0xB06  <-> "mhpmcounter6"
mapping clause csr_name_map = 0xB07  <-> "mhpmcounter7"
mapping clause csr_name_map = 0xB08  <-> "mhpmcounter8"
mapping clause csr_name_map = 0xB09  <-> "mhpmcounter9"
mapping clause csr_name_map = 0xB0A  <-> "mhpmcounter10"
mapping clause csr_name_map = 0xB0B  <-> "mhpmcounter11"
mapping clause csr_name_map = 0xB0C  <-> "mhpmcounter12"
mapping clause csr_name_map = 0xB0D  <-> "mhpmcounter13"
mapping clause csr_name_map = 0xB0E  <-> "mhpmcounter14"
mapping clause csr_name_map = 0xB0F  <-> "mhpmcounter15"
mapping clause csr_name_map = 0xB10  <-> "mhpmcounter16"
mapping clause csr_name_map = 0xB11  <-> "mhpmcounter17"
mapping clause csr_name_map = 0xB12  <-> "mhpmcounter18"
mapping clause csr_name_map = 0xB13  <-> "mhpmcounter19"
mapping clause csr_name_map = 0xB14  <-> "mhpmcounter20"
mapping clause csr_name_map = 0xB15  <-> "mhpmcounter21"
mapping clause csr_name_map = 0xB16  <-> "mhpmcounter22"
mapping clause csr_name_map = 0xB17  <-> "mhpmcounter23"
mapping clause csr_name_map = 0xB18  <-> "mhpmcounter24"
mapping clause csr_name_map = 0xB19  <-> "mhpmcounter25"
mapping clause csr_name_map = 0xB1A  <-> "mhpmcounter26"
mapping clause csr_name_map = 0xB1B  <-> "mhpmcounter27"
mapping clause csr_name_map = 0xB1C  <-> "mhpmcounter28"
mapping clause csr_name_map = 0xB1D  <-> "mhpmcounter29"
mapping clause csr_name_map = 0xB1E  <-> "mhpmcounter30"
mapping clause csr_name_map = 0xB1F  <-> "mhpmcounter31"

mapping clause csr_name_map = 0xB83  <-> "mhpmcounter3h"
mapping clause csr_name_map = 0xB84  <-> "mhpmcounter4h"
mapping clause csr_name_map = 0xB85  <-> "mhpmcounter5h"
mapping clause csr_name_map = 0xB86  <-> "mhpmcounter6h"
mapping clause csr_name_map = 0xB87  <-> "mhpmcounter7h"
mapping clause csr_name_map = 0xB88  <-> "mhpmcounter8h"
mapping clause csr_name_map = 0xB89  <-> "mhpmcounter9h"
mapping clause csr_name_map = 0xB8A  <-> "mhpmcounter10h"
mapping clause csr_name_map = 0xB8B  <-> "mhpmcounter11h"
mapping clause csr_name_map = 0xB8C  <-> "mhpmcounter12h"
mapping clause csr_name_map = 0xB8D  <-> "mhpmcounter13h"
mapping clause csr_name_map = 0xB8E  <-> "mhpmcounter14h"
mapping clause csr_name_map = 0xB8F  <-> "mhpmcounter15h"
mapping clause csr_name_map = 0xB90  <-> "mhpmcounter16h"
mapping clause csr_name_map = 0xB91  <-> "mhpmcounter17h"
mapping clause csr_name_map = 0xB92  <-> "mhpmcounter18h"
mapping clause csr_name_map = 0xB93  <-> "mhpmcounter19h"
mapping clause csr_name_map = 0xB94  <-> "mhpmcounter20h"
mapping clause csr_name_map = 0xB95  <-> "mhpmcounter21h"
mapping clause csr_name_map = 0xB96  <-> "mhpmcounter22h"
mapping clause csr_name_map = 0xB97  <-> "mhpmcounter23h"
mapping clause csr_name_map = 0xB98  <-> "mhpmcounter24h"
mapping clause csr_name_map = 0xB99  <-> "mhpmcounter25h"
mapping clause csr_name_map = 0xB9A  <-> "mhpmcounter26h"
mapping clause csr_name_map = 0xB9B  <-> "mhpmcounter27h"
mapping clause csr_name_map = 0xB9C  <-> "mhpmcounter28h"
mapping clause csr_name_map = 0xB9D  <-> "mhpmcounter29h"
mapping clause csr_name_map = 0xB9E  <-> "mhpmcounter30h"
mapping clause csr_name_map = 0xB9F  <-> "mhpmcounter31h"

// HPM (Hardware Performance Monitoring) counters. The lowest three values are
// not used but they are defined for simplicity.
register mhpmcounter : vector(32, bits(64))

// HPM events selector. These control what the HPM counters measure. The lowest
// three values are not used but they are defined for simplicity.
register mhpmevent : vector(32, xlenbits)

// Valid HPM counter indices. The lowest three are used for mcycle, mtime and minstret.
type hpmidx = range(3, 31)

// Convert the lowest 5 bits of a CSR index to an hpmidx. Asserts if it is 0..2.
function hpmidx_from_bits(b : bits(5)) -> hpmidx = {
  let index = unsigned(b);
  assert(index >= 3, "unreachable HPM index");
  index
}

function read_mhpmcounter(index : hpmidx) -> xlenbits = mhpmcounter[index][(xlen - 1) .. 0]
function read_mhpmcounterh(index : hpmidx) -> bits(32) = mhpmcounter[index][63 .. 32]
function read_mhpmevent(index : hpmidx) -> xlenbits = mhpmevent[index]

// Write the HPM CSRs. These return the new value of the CSR, for use in writeCSR.
function write_mhpmcounter(index : hpmidx, value : xlenbits) -> unit =
  if sys_writable_hpm_counters()[index] == bitone then mhpmcounter[index][(xlen - 1) .. 0] = value

function write_mhpmcounterh(index : hpmidx, value : bits(32)) -> unit =
  if sys_writable_hpm_counters()[index] == bitone then mhpmcounter[index][63 .. 32] = value

function write_mhpmevent(index : hpmidx, value : xlenbits) -> unit =
  if sys_writable_hpm_counters()[index] == bitone then mhpmevent[index] = value

/* Hardware Performance Monitoring event selection */
function clause is_CSR_defined(0b0011001 /* 0x320 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) // mhpmevent3..31
function clause read_CSR(0b0011001 /* 0x320 */ @ index : bits(5) if unsigned(index) >= 3) = read_mhpmevent(hpmidx_from_bits(index))
function clause write_CSR((0b0011001 /* 0x320 */ @ index : bits(5), value) if unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmevent(index, value);
  read_mhpmevent(index)
}

/* Hardware Performance Monitoring machine mode counters */
function clause is_CSR_defined(0b1011000 /* 0xB00 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) // mhpmcounter3..31
function clause is_CSR_defined(0b1011100 /* 0xB80 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & (xlen == 32) // mhpmcounterh3..31

function clause read_CSR(0b1011000 /* 0xB00 */ @ index : bits(5) if unsigned(index) >= 3) = read_mhpmcounter(hpmidx_from_bits(index))
function clause read_CSR(0b1011100 /* 0xB80 */ @ index : bits(5) if xlen == 32 & unsigned(index) >= 3) = read_mhpmcounterh(hpmidx_from_bits(index))

function clause write_CSR((0b1011000 /* 0xB00 */ @ index : bits(5), value) if unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmcounter(index, value);
  read_mhpmcounter(index)
}
function clause write_CSR((0b1011100 /* 0xB80 */ @ index : bits(5), value) if xlen == 32 & unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmcounterh(index, value);
  read_mhpmcounterh(index)
}

/* Hardware Performance Monitoring user mode counters */
function clause is_CSR_defined(0b1100000 /* 0xC00 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & extensionEnabled(Ext_U) // hpmcounter3..31
function clause is_CSR_defined(0b1100100 /* 0xC80 */ @ index : bits(5) if unsigned(index) >= 3) = extensionEnabled(Ext_Zihpm) & extensionEnabled(Ext_U) & (xlen == 32) // hpmcounterh3..31

function clause read_CSR(0b1100000 /* 0xC00 */ @ index : bits(5) if unsigned(index) >= 3) = read_mhpmcounter(hpmidx_from_bits(index))
function clause read_CSR(0b1100100 /* 0xC80 */ @ index : bits(5) if xlen == 32 & unsigned(index) >= 3) = read_mhpmcounterh(hpmidx_from_bits(index))
