/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Counter OverFlow and Privilege Mode Filtering */
function clause currentlyEnabled(Ext_Sscofpmf) = hartSupports(Ext_Sscofpmf) & currentlyEnabled(Ext_Zihpm)

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

mapping clause csr_name_map = 0xDA0  <-> "scountovf"

function read_mhpmeventh(index : hpmidx) -> bits(32) = mhpmevent[index].bits[63 .. 32]

function write_mhpmeventh(index : hpmidx, value : bits(32)) -> unit =
  if sys_writable_hpm_counters[index] == bitone then
  mhpmevent[index] = legalize_hpmevent(Mk_HpmEvent(value @ mhpmevent[index].bits[31 .. 0]))

// mhpmevent3..31h
function clause is_CSR_defined(0b0111001 /* 0x720 */ @ index : bits(5) if unsigned(index) >= 3) = currentlyEnabled(Ext_Sscofpmf) & (xlen == 32)
function clause read_CSR(0b0111001 /* 0x720 */ @ index : bits(5) if xlen == 32 & unsigned(index) >= 3) = read_mhpmeventh(hpmidx_from_bits(index))
function clause write_CSR((0b0111001 /* 0x720 */ @ index : bits(5), value) if xlen == 32 & unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmeventh(index, value);
  read_mhpmeventh(index)
}

// scountovf collates the OF (overflow) bit for each event.
function get_scountovf(priv : Privilege) -> bits(32) = {
  let overflow =
    mhpmevent[31][OF] @ mhpmevent[30][OF] @ mhpmevent[29][OF] @ mhpmevent[28][OF] @
    mhpmevent[27][OF] @ mhpmevent[26][OF] @ mhpmevent[25][OF] @ mhpmevent[24][OF] @
    mhpmevent[23][OF] @ mhpmevent[22][OF] @ mhpmevent[21][OF] @ mhpmevent[20][OF] @
    mhpmevent[19][OF] @ mhpmevent[18][OF] @ mhpmevent[17][OF] @ mhpmevent[16][OF] @
    mhpmevent[15][OF] @ mhpmevent[14][OF] @ mhpmevent[13][OF] @ mhpmevent[12][OF] @
    mhpmevent[11][OF] @ mhpmevent[10][OF] @ mhpmevent[ 9][OF] @ mhpmevent[ 8][OF] @
    mhpmevent[ 7][OF] @ mhpmevent[ 6][OF] @ mhpmevent[ 5][OF] @ mhpmevent[ 4][OF] @
    mhpmevent[ 3][OF] @ 0b000;

  match priv {
    Machine => overflow,
    Supervisor => overflow & mcounteren.bits,
    User => internal_error(__FILE__, __LINE__, "scountovf not readable from User mode"),
    _ => internal_error(__FILE__, __LINE__, "Hypervisor extension not supported yet"),
  }
}

// scountovf
function clause is_CSR_defined(0xDA0) = currentlyEnabled(Ext_Sscofpmf) & currentlyEnabled(Ext_S)
function clause read_CSR(0xDA0) = zero_extend(get_scountovf(cur_privilege))
// scountovf is read-only.
