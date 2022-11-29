/* ************************************************************************** */
/* This file implements functions used by vector instructions.                */

/* ************************************************************************** */


/* Vector mask mapping */
mapping maybe_vmask : string <-> bits(1) = {
  ""              <-> 0b1, /* unmasked by default */
  sep() ^ "v0.t"  <-> 0b0
}

/* Check for valid vsew and lmul values */
val vcheck_vsew_lmul : (int, real) -> bool
function vcheck_vsew_lmul(vsew_bits, lmul) = {
  if  vsew_bits < 8     |
      vsew_bits > 64    |
      lmul      < 0.125 |
      lmul      > 8.0 then false else true
}

/* Check for vstart value */
val assert_vstart : int -> bool effect {rreg}
function assert_vstart(i) = {
  if unsigned(vstart) != i then false else true
}

/* Scalar register shaping */
val get_scalar : forall 'n, 'n >= 8. (regidx, int('n)) -> bits('n) effect {escape, rreg}
function get_scalar(rs1, vsew_bits) = {
  if sizeof(xlen) > vsew_bits then {
    /* Least significant SEW bits */
    slice(X(rs1), 0, vsew_bits)
  } else if sizeof(xlen) < vsew_bits then {
    /* Sign extend to SEW */
    sail_sign_extend(X(rs1), vsew_bits)
  } else {
    X(rs1)
  }
}

/* Get the starting element index from csr vtype */
val get_start_element : unit -> int effect {escape, rreg, wreg}
function get_start_element() = {
  start_element : int = unsigned(vstart);
  vsew_bits     : int = get_vtype_vsew();
  /* The use of vstart values greater than the largest element
    index for the current SEW setting is reserved.
    It is recommended that implementations trap if vstart is out of bounds.
    It is not required to trap, as a possible future use of upper vstart bits
    is to store imprecise trap information. */
  if start_element > ((8 * get_vlen() / vsew_bits) - 1) then {
    start_element = -1;
  };
  start_element
}

/* Get the ending element index from csr vl */
val get_end_element : unit -> int effect {escape, rreg, wreg}
function get_end_element() = {
  let end_element : int = unsigned(vl) - 1;
  end_element
}

/* Mask handling; creates a pre-masked result vector for vstart, vl, vta/vma, and vm */
/* vm should be baked into vm_val from doing read_vmask */
/* tail masking when lmul < 1 is handled in write_vreg */
/* Returns two vectors:
 *   vector1 is the result vector with values applied to masked elements
 *   vector2 is a "mask" vector that is true for an element if the corresponding element
 *     in the result vector should be updated by the calling instruction
 */
val init_masked_result : forall 'n 'm, 8 <= 'm <= 128. (int('n), int('m), real, vector('n, dec, bits('m)), vector('n, dec, bool)) -> (vector('n, dec, bits('m)), vector('n, dec, bool)) effect {escape, rreg, undef, wreg}
function init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val) = {
  let start_element : int                       = get_start_element();
  let end_element   : int                       = get_end_element();
  let tail_ag       : agtype                    = get_vtype_vta();
  let mask_ag       : agtype                    = get_vtype_vma();
  mask_helper       : vector('n, dec, bool)     = undefined;
  result            : vector('n, dec, bits('m)) = undefined;

  if start_element < 0 then {
    /* start element is not valid */
    result      = undefined;
    mask_helper = undefined;
  } else {
    /* Determine the actual number of elements when lmul < 1 */
    let real_num_elem = if lmul >= 1.0 then num_elem else floor(lmul * to_real(num_elem));
    assert(num_elem >= real_num_elem);

    foreach (i from 0 to (num_elem - 1)) {
      if i < start_element then {
        /* Prestart elements defined by vstart */
        result[i] = vd_val[i];
        mask_helper[i] = false
      } else if i > end_element then {
        /* Tail elements defined by vl */
        if tail_ag == UNDISTURBED then {
          result[i] = vd_val[i];
        } else if tail_ag == AGNOSTIC then {
          result[i] = vd_val[i];
        };
        mask_helper[i] = false
      } else if i >= real_num_elem then {
        /* Tail elements defined by lmul < 1 */
        if tail_ag == UNDISTURBED then {
          result[i] = vd_val[i];
        } else if tail_ag == AGNOSTIC then {
          result[i] = vd_val[i];
        };
        mask_helper[i] = false
      } else if vm_val[i] == false then {
        /* Inactive body elements defined by vm */
        if mask_ag == UNDISTURBED then {
          result[i] = vd_val[i]
        } else if mask_ag == AGNOSTIC then {
          result[i] = vd_val[i]
        };
        mask_helper[i] = false
      } else {
        /* Active body elements */
        mask_helper[i] = true;
      }
    };    
  };

  (result, mask_helper)
}

/* Mask handling for carry functions that use masks as input/output */
/* Only prestart and tail elements are masked in a mask value */
val init_masked_result_carry : forall 'n 'm, 8 <= 'm <= 128. (int('n), int('m), real, vector('n, dec, bool)) -> (vector('n, dec, bool), vector('n, dec, bool)) effect {escape, rreg, undef, wreg}
function init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val) = {
  let start_element : int                   = get_start_element();
  let end_element   : int                   = get_end_element();
  mask_helper       : vector('n, dec, bool) = undefined;
  result            : vector('n, dec, bool) = undefined;

  /* Determine the actual number of elements when lmul < 1 */
  let real_num_elem = if lmul >= 1.0 then num_elem else floor(lmul * to_real(num_elem));
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      result[i] = vd_val[i];
      mask_helper[i] = false
    } else if i > end_element then {
      /* Tail elements defined by vl */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i];
      mask_helper[i] = false
    } else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i];
      mask_helper[i] = false
    } else {
      /* Active body elements */
      mask_helper[i] = true
    }
  };

  (result, mask_helper)
}

/* Mask handling for cmp functions that use masks as output */
val init_masked_result_cmp : forall 'n 'm, 8 <= 'm <= 128. (int('n), int('m), real, vector('n, dec, bool), vector('n, dec, bool)) -> (vector('n, dec, bool), vector('n, dec, bool)) effect {escape, rreg, undef, wreg}
function init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val) = {
  let start_element : int                       = get_start_element();
  let end_element   : int                       = get_end_element();
  let mask_ag       : agtype                    = get_vtype_vma();
  mask_helper       : vector('n, dec, bool)     = undefined;
  result            : vector('n, dec, bool)     = undefined;

  /* Determine the actual number of elements when lmul < 1 */
  let real_num_elem = if lmul >= 1.0 then num_elem else floor(lmul * to_real(num_elem));
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      result[i] = vd_val[i];
      mask_helper[i] = false
    } else if i > end_element then {
      /* Tail elements defined by vl */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i];
      mask_helper[i] = false
    } else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      /* Mask tail is always agnostic */
      result[i] = vd_val[i];
      mask_helper[i] = false
    } else if vm_val[i] == false then {
      /* Inactive body elements defined by vm */
      if mask_ag == UNDISTURBED then {
        result[i] = vd_val[i]
      } else if mask_ag == AGNOSTIC then {
	      result[i] = vd_val[i]
      };
      mask_helper[i] = false
    } else {
      /* Active body elements */
      mask_helper[i] = true
    }
  };

  (result, mask_helper)
}

/* Misc number functions */
val is_zeros : forall 'n, 'n >= 0. bits('n) -> bool
function is_zeros(bitval) = {
  bitval == zeros('n)
}

val is_ones : forall 'n, 'n >= 0. bits('n) -> bool
function is_ones(bitval) = {
  bitval == ones('n)
}

/* Floating point canonical NaN for 16-bit, 32-bit, 64-bit and 128-bit types */
val canonical_NaN : forall 'm, 'm in {16, 32, 64, 128}. int('m) -> bits('m)
function canonical_NaN('m) = {
  match 'm {
    16   => 0x_7e00,
    32   => 0x_7fc0_0000,
    64   => 0x_7ff8_0000_0000_0000,
    128  => 0x_7fff_8000_0000_0000_0000_0000_0000_0000
  }
}

/* Floating point NaN boxing / unboxing that support 16-bit to 128-bit types */
val nan_box_new : forall 'm, ('m in {16, 32, 64, 128} & 'm <= flen). bits('m) -> flenbits
function nan_box_new   unboxed = {
  if sizeof(flen) == 'm
  then unboxed
  else sail_ones(sizeof(flen) - 'm) @ unboxed 
}

val nan_unbox_new : forall 'm, ('m in {16, 32, 64, 128} & 'm <= flen). (flenbits, int('m)) -> bits('m)
function nan_unbox_new(regval, 'm) = {
  if sizeof(flen) == 'm
  then regval
  else if slice(regval, 'm, sizeof(flen) - 'm) == ones()
  then slice(regval, 0, 'm)
  else canonical_NaN('m)
}

/* Check if the floating point number is a signaling NaN */
val      f_is_SNaN : forall 'm, ('m in {16, 32, 64, 128} & 'm <= flen). bits('m) -> bool
function f_is_SNaN   xf = {
  match 'm {
    16   => is_ones(xf[14..10]) & is_zeros(xf[9..9]) & ~(is_zeros(xf[8..0])),
    32   => is_ones(xf[30..23]) & is_zeros(xf[22..22]) & ~(is_zeros(xf[21..0])),
    64   => is_ones(xf[62..52]) & is_zeros(xf[51..51]) & ~(is_zeros(xf[50..0])),
    128  => is_ones(xf[126..112]) & is_zeros(xf[111..111]) & ~(is_zeros(xf[110..0]))
  }
}

/* Either QNaN or SNan */
val      f_is_NaN : forall 'm, ('m in {16, 32, 64, 128} & 'm <= flen). bits('m) -> bool
function f_is_NaN   xf = {
  match 'm {
    16   => is_ones(xf[14..10]) & ~(is_zeros(xf[9..0])),
    32   => is_ones(xf[30..23]) & ~(is_zeros(xf[22..0])),
    64   => is_ones(xf[62..52]) & ~(is_zeros(xf[51..0])),
    128  => is_ones(xf[126..112]) & ~(is_zeros(xf[111..0]))
  }
}

val      f_is_neg_zero : forall 'm, ('m in {16, 32, 64, 128} & 'm <= flen). bits('m) -> bool
function f_is_neg_zero   xf = {
  match 'm {
    16   => is_ones(xf[15..15]) & is_zeros(xf[14..0]),
    32   => is_ones(xf[31..31]) & is_zeros(xf[30..0]),
    64   => is_ones(xf[63..63]) & is_zeros(xf[62..0]),
    128  => is_ones(xf[127..127]) & is_zeros(xf[126..0])
  }
}

val      f_is_pos_zero : forall 'm, ('m in {16, 32, 64, 128} & 'm <= flen). bits('m) -> bool
function f_is_pos_zero   xf = {
  match 'm {
    16   => is_zeros(xf),
    32   => is_zeros(xf),
    64   => is_zeros(xf),
    128  => is_zeros(xf)
  }
}

/* Scalar register shaping for floating point operations */
val get_scalar_fp : forall 'n, 'n in {16, 32, 64, 128}. (regidx, int('n)) -> bits('n) effect {escape, rreg}
function get_scalar_fp(rs1, vsew_bits) = {
  if sizeof(xlen) >= vsew_bits then {
    /* Least significant SEW bits */
    nan_unbox_new(F(rs1), vsew_bits)
  } else {
    canonical_NaN(vsew_bits)
  }
}

/* Shift amounts */
val get_shift_amount : forall 'n 'm, 0 <= 'n & 8 <= 'm <= 1024. (bits('n), int('m)) -> int effect {escape}
function get_shift_amount(bit_val, vsew_bits) = {
  let lowlog2bits : int = log2(vsew_bits);
  assert(0 <= lowlog2bits & lowlog2bits < vsew_bits);
  unsigned(slice(bit_val, 0, lowlog2bits));
}

/* Fixed point rounding increment */
val get_fixed_rounding_incr : forall ('m 'n : Int), ('m > 0 & 'n >= 0). (bits('m), int('n)) -> bits(1) effect {rreg, undef}
function get_fixed_rounding_incr(vec_elem, shift_amount) = {
  rounding_incr : bits(1) = undefined;
  if shift_amount == 0 then rounding_incr = 0b0
  else {
    let rounding_mode = vxrm[1 .. 0];
    rounding_incr = match rounding_mode {
      0b00 => slice(vec_elem, shift_amount - 1, 1),
      0b01 => bool_to_bits(
        (slice(vec_elem, shift_amount - 1, 1) == 0b1) & (slice(vec_elem, 0, shift_amount - 1) != zeros() | slice(vec_elem, shift_amount, 1) == 0b1)),
      0b10 => 0b0,
      0b11 => bool_to_bits(
        ~(slice(vec_elem, shift_amount, 1) == 0b1) & (slice(vec_elem, 0, shift_amount) != zeros()))
    }; 
  };
  rounding_incr
}

/* Fixed point unsigned saturation */
val unsigned_saturation : forall ('m 'n: Int), ('n >= 'm > 0). (int('m), bits('n)) -> bits('m) effect {escape, rreg, undef, wreg}
function unsigned_saturation(len, elem) = {
  elem_sat : bits('m) = undefined;
  if unsigned(elem) > unsigned(ones('m)) then {
    elem_sat = EXTZ('m, ones('m));
    writeCSR(csr_name_map("vxsat"), EXTZ(0b1))
  } else {
    elem_sat = slice(elem, 0, 'm);
    writeCSR(csr_name_map("vxsat"), EXTZ(0b0))
  };
  elem_sat
}

/* Fixed point signed saturation */
val signed_saturation : forall ('m 'n: Int), ('n >= 'm > 0). (int('m), bits('n)) -> bits('m) effect {escape, rreg, undef, wreg}
function signed_saturation(len, elem) = {
  elem_sat : bits('m) = undefined;
  if signed(elem) > signed( EXTZ('m, ones('m - 1)) ) then {
    elem_sat = EXTZ('m, ones('m - 1));
    writeCSR(csr_name_map("vxsat"), EXTZ(0b1))
  } else if signed(elem) < signed( EXTZ('m, 0b1) << ('m - 1) ) then {
    elem_sat = to_bits('m, signed( EXTZ('m, 0b1) << ('m - 1) ) );
    writeCSR(csr_name_map("vxsat"), EXTZ(0b1))
  } else {
    elem_sat = slice(elem, 0, 'm);
    writeCSR(csr_name_map("vxsat"), EXTZ(0b0))
  };
  elem_sat
}

/* Get the floating point rounding mode from csr fcsr */
val get_fp_rounding_mode : unit -> rounding_mode effect {rreg}
function get_fp_rounding_mode() = encdec_rounding_mode(fcsr.FRM())

/* Split sign and the remain of floating point number */
val      fsplitsign : forall 'n, 'n in {16, 32, 64}. bits('n) -> (bits(1), bits('n - 1))
function fsplitsign   (xf) = {
  match 'n{
    16 => (xf[15..15], xf[14..0]),
    32 => (xf[31..31], xf[30..0]),
    64 => (xf[63..63], xf[62..0])
  }
}

/* Make a floating point number by sign and the remains bits */
val      fmakesign : forall 'n, 'n in {16, 32, 64}. (bits(1), bits('n - 1)) -> bits('n)
function fmakesign (sign, remain) = sign @ remain

/* Negate a floating point number */
val negate_fp : forall 'n, 'n in {16, 32, 64}. bits('n) -> bits('n) 
function negate_fp (xf) = {
  let (sign, remain) = fsplitsign(xf);
  let new_sign = if (sign == 0b0) then 0b1 else 0b0;
  fmakesign (new_sign, remain)
}


/* Floating point functions */
val fp_add: forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_add(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16Add(rm_3b, op1, op2),
    32  => riscv_f32Add(rm_3b, op1, op2),
    64  => riscv_f64Add(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fp_sub: forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_sub(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16Sub(rm_3b, op1, op2),
    32  => riscv_f32Sub(rm_3b, op1, op2),
    64  => riscv_f64Sub(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fp_min : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_min(op1, op2) = {
  let (temp_flags, op1_lt_op2) : (bits_fflags, bool) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };

  let result_val  = if (f_is_NaN(op1) & f_is_NaN(op2)) then canonical_NaN('n)
                    else if f_is_NaN(op1) then op2
                    else if f_is_NaN(op2) then op1
                    else if (f_is_neg_zero(op1) & f_is_pos_zero(op2)) then op1
                    else if (f_is_neg_zero(op2) & f_is_pos_zero(op1)) then op2
                    else if op1_lt_op2 then op1
                    else op2;

  let fflags = if (f_is_SNaN(op1) | f_is_SNaN(op2)) then nvFlag() else zeros();
  accrue_fflags(fflags);
  update_softfloat_fflags(fflags); /* to avoid inconsistency about NaN operands */

  result_val
}

val fp_max : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_max(op1, op2) = {
  let (temp_flags, op1_lt_op2) : (bits_fflags, bool) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };

  let result_val  = if (f_is_NaN(op1) & f_is_NaN(op2)) then canonical_NaN('n)
                    else if f_is_NaN(op1) then op2
                    else if f_is_NaN(op2) then op1
                    else if (f_is_neg_zero(op1) & f_is_pos_zero(op2)) then op2
                    else if (f_is_neg_zero(op2) & f_is_pos_zero(op1)) then op1
                    else if op1_lt_op2 then op2
                    else op1;

  let fflags = if (f_is_SNaN(op1) | f_is_SNaN(op2)) then nvFlag() else zeros();
  accrue_fflags(fflags);
  update_softfloat_fflags(fflags); /* to avoid inconsistency about NaN operands */

  result_val
}

val fp_eq : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_eq(op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bool) = match 'n {
    16  => riscv_f16Eq(op1, op2),
    32  => riscv_f32Eq(op1, op2),
    64  => riscv_f64Eq(op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fp_gt : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_gt(op1, op2) = {
  let (fflags, temp_val) : (bits_fflags, bool) = match 'n {
    16  => riscv_f16Le(op1, op2),
    32  => riscv_f32Le(op1, op2),
    64  => riscv_f64Le(op1, op2)
  };
  let result_val = (if fflags == 0b10000 then false else ~(temp_val));
  write_fflags(fflags);
  result_val
}

val fp_ge : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_ge(op1, op2) = {
  let (fflags, temp_val) : (bits_fflags, bool) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };
  let result_val = (if fflags == 0b10000 then false else ~(temp_val));
  write_fflags(fflags);
  result_val
}

val fp_lt : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_lt(op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bool) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fp_le : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_le(op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bool) = match 'n {
    16  => riscv_f16Le(op1, op2),
    32  => riscv_f32Le(op1, op2),
    64  => riscv_f64Le(op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fp_mul : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_mul(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16Mul(rm_3b, op1, op2),
    32  => riscv_f32Mul(rm_3b, op1, op2),
    64  => riscv_f64Mul(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fp_div : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_div(rm_3b, op1, op2) = {
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16Div(rm_3b, op1, op2),
    32  => riscv_f32Div(rm_3b, op1, op2),
    64  => riscv_f64Div(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fp_muladd : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_muladd(rm_3b, op1, op2, opadd) = {
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opadd),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opadd),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opadd)
  };
  write_fflags(fflags);
  result_val
}

val fp_nmuladd : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_nmuladd(rm_3b, op1, op2, opadd) = {
  let op1 = negate_fp(op1);
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opadd),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opadd),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opadd)
  };
  write_fflags(fflags);
  result_val
}

val fp_mulsub : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_mulsub(rm_3b, op1, op2, opsub) = {
  let opsub = negate_fp(opsub);
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opsub),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opsub),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opsub)
  };
  write_fflags(fflags);
  result_val
}

val fp_nmulsub : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_nmulsub(rm_3b, op1, op2, opsub) = {
  let opsub = negate_fp(opsub);
  let op1 = negate_fp(op1);
  let (fflags, result_val) : (bits_fflags, bits('n)) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opsub),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opsub),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opsub)
  };
  write_fflags(fflags);
  result_val
}

val fp_widen : forall 'm, ('m in {16, 32} & 'm <= flen). bits('m) -> bits('m * 2) effect {escape, rreg, undef, wreg}
function fp_widen(nval) = {
  let rm_3b = fcsr.FRM();
  let (fflags, wval) : (bits_fflags, bits('m * 2)) = match 'm {
    16 => riscv_f16ToF32(rm_3b, nval),
    32 => riscv_f32ToF64(rm_3b, nval)
  };
  accrue_fflags(fflags);
  wval
}
