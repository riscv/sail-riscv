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

/* register file and accessors */

/*
 * I vs E populates a vector of references to either x1-x15 (E) or x1-x31 (I).
 *
 * This is exposed as a function because we cannot forward-declare non-function
 * values.
 */
val xreg_by_index : range(1,regno_range_max) -> register(regtype)

function rX (Regno(r) : regno) -> xlenbits = {
  let v : regtype = if r == 0 then zero_reg else __deref(xreg_by_index(r));
  regval_from_reg(v)
}

$ifdef RVFI_DII
function rvfi_wX (Regno(r) : regno, v : xlenbits) -> unit = {
  rvfi_int_data[rvfi_rd_wdata] = zero_extend(v);
  rvfi_int_data[rvfi_rd_addr] = to_bits(8,r);
  rvfi_int_data_present = true;
}
$else
function rvfi_wX (r : regno, v : xlenbits) -> unit = ()
$endif

function wX (Regno(r) : regno, in_v : xlenbits) -> unit = {
  let v = regval_into_reg(in_v);
  if r == 0 then () else *(xreg_by_index(r)) = v;
  if (r != 0) then {
     rvfi_wX(Regno(r), in_v);
     if   get_config_print_reg()
     then print_reg("x" ^ dec_str(r) ^ " <- " ^ RegStr(v));
  }
}

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

val reg_name_raw : bits(regidx_bits_width) <-> string
mapping reg_name : regidx <-> string = { Regidx(i) <-> reg_name_raw(i) }

mapping creg_name : cregidx <-> string = { Cregidx(i) <-> creg_name_raw(i) }

/* Mappings for encoding */

mapping encdec_creg : cregidx <-> bits(3) = { Cregidx(r) <-> r }
