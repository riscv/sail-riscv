/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* program counter */

register PC       : xlenbits
register nextPC   : xlenbits

/* internal state to hold instruction bits for faulting instructions */
register instbits : xlenbits

val rX : regno -> xlenbits
val wX : (regno, xlenbits) -> unit

function rX_bits(i: regidx) -> xlenbits = rX(regidx_to_regno(i))

function wX_bits(i: regidx, data: xlenbits) -> unit = {
  wX(regidx_to_regno(i)) = data
}

overload X = {rX_bits, wX_bits, rX, wX}

mapping creg_name_raw : bits(3) <-> string = {
  0b000 <-> "s0",
  0b001 <-> "s1",
  0b010 <-> "a0",
  0b011 <-> "a1",
  0b100 <-> "a2",
  0b101 <-> "a3",
  0b110 <-> "a4",
  0b111 <-> "a5"
}

mapping creg_name : cregidx <-> string = { Cregidx(i) <-> creg_name_raw(i) }

/* Mappings for encoding */

mapping encdec_creg : cregidx <-> bits(3) = { Cregidx(r) <-> r }

/* Initializtion */

val init_base_regs : unit -> unit
