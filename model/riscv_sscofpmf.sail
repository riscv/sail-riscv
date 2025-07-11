/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Counter OverFlow and Privilege Mode Filtering */
function clause currentlyEnabled(Ext_Sscofpmf) = hartSupports(Ext_Sscofpmf) & currentlyEnabled(Ext_Zihpm)

mapping clause csr_name_map = 0x723  <-> "mhpmevent3h"
mapping clause csr_name_map = 0x724  <-> "mhpmevent4h"
mapping clause csr_name_map = 0x725  <-> "mhpmevent5h"
mapping clause csr_name_map = 0x726  <-> "mhpmevent6h"
mapping clause csr_name_map = 0x727  <-> "mhpmevent7h"
mapping clause csr_name_map = 0x728  <-> "mhpmevent8h"
mapping clause csr_name_map = 0x729  <-> "mhpmevent9h"
mapping clause csr_name_map = 0x72A  <-> "mhpmevent10h"
mapping clause csr_name_map = 0x72B  <-> "mhpmevent11h"
mapping clause csr_name_map = 0x72C  <-> "mhpmevent12h"
mapping clause csr_name_map = 0x72D  <-> "mhpmevent13h"
mapping clause csr_name_map = 0x72E  <-> "mhpmevent14h"
mapping clause csr_name_map = 0x72F  <-> "mhpmevent15h"
mapping clause csr_name_map = 0x730  <-> "mhpmevent16h"
mapping clause csr_name_map = 0x731  <-> "mhpmevent17h"
mapping clause csr_name_map = 0x732  <-> "mhpmevent18h"
mapping clause csr_name_map = 0x733  <-> "mhpmevent19h"
mapping clause csr_name_map = 0x734  <-> "mhpmevent20h"
mapping clause csr_name_map = 0x735  <-> "mhpmevent21h"
mapping clause csr_name_map = 0x736  <-> "mhpmevent22h"
mapping clause csr_name_map = 0x737  <-> "mhpmevent23h"
mapping clause csr_name_map = 0x738  <-> "mhpmevent24h"
mapping clause csr_name_map = 0x739  <-> "mhpmevent25h"
mapping clause csr_name_map = 0x73A  <-> "mhpmevent26h"
mapping clause csr_name_map = 0x73B  <-> "mhpmevent27h"
mapping clause csr_name_map = 0x73C  <-> "mhpmevent28h"
mapping clause csr_name_map = 0x73D  <-> "mhpmevent29h"
mapping clause csr_name_map = 0x73E  <-> "mhpmevent30h"
mapping clause csr_name_map = 0x73F  <-> "mhpmevent31h"

mapping clause csr_name_map = 0xDA0  <-> "scountovf"

function read_mhpmeventh(index : hpmidx) -> bits(32) = mhpmevent[index].bits[63 .. 32]

function write_mhpmeventh(index : hpmidx, value : bits(32)) -> unit =
  if sys_writable_hpm_counters[index] == bitone then
  mhpmevent[index] = legalize_hpmevent(Mk_HpmEvent(value @ mhpmevent[index].bits[31 .. 0]))

// mhpmevent3..31h
function clause is_CSR_accessible((0b0111001 /* 0x720 */ @ index : bits(5), _, _) if unsigned(index) >= 3) = currentlyEnabled(Ext_Sscofpmf) & (xlen == 32)
function clause read_CSR(0b0111001 /* 0x720 */ @ index : bits(5) if xlen == 32 & unsigned(index) >= 3) = read_mhpmeventh(hpmidx_from_bits(index))
function clause write_CSR((0b0111001 /* 0x720 */ @ index : bits(5), value) if xlen == 32 & unsigned(index) >= 3) = {
  let index = hpmidx_from_bits(index);
  write_mhpmeventh(index, value);
  Ok(read_mhpmeventh(index))
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
  }
}

// scountovf
function clause is_CSR_accessible(0xDA0, _, _) = currentlyEnabled(Ext_Sscofpmf) & currentlyEnabled(Ext_S)
function clause read_CSR(0xDA0) = zero_extend(get_scountovf(cur_privilege))
// scountovf is read-only.
