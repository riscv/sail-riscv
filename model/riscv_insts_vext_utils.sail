/* ************************************************************************** */
/* This file implements functions used by vector instructions.                */

/* ************************************************************************** */


/* ****************************************************************** */
/* Vector mask mapping */
mapping maybe_vmask : string <-> bits(1) = {
  ""              <-> 0b1, /* unmasked by default */
  sep() ^ "v0.t"  <-> 0b0
}

/* Check for valid vew and lmul values */
val vcheck_vsew_lmul : (int, real) -> Retired
function vcheck_vsew_lmul(vsew_bits, lmul) = {
  if vsew_bits < 8   |
     vsew_bits > 64  |
     lmul      < 0.125 |
     lmul      > 8.0 then {
    print("status=fail,invalid double vsew!");
    RETIRE_FAIL
  }
  else {
    RETIRE_SUCCESS
  }
}

/* Check for vstart value */
val assert_vstart : int -> Retired effect {rreg}
function assert_vstart(i) = {
  if unsigned(readCSR(csr_name_map("vstart"))) != i then {
    RETIRE_FAIL
  }
  else {
    RETIRE_SUCCESS
  }
}

/* Scalar register shaping */
val get_scalar : forall 'n, 'n >= 8. (regidx, int('n)) -> bits('n) effect {escape, rreg}
function get_scalar(rs1, vsew_bits) = {
  if sizeof(xlen) > vsew_bits then {
    /* Least significant SEW bits */
    slice(X(rs1), 0, vsew_bits)
  }
  else if sizeof(xlen) < vsew_bits then {
    /* Sign extend to SEW */
    sail_sign_extend(X(rs1), vsew_bits)
  }
  else {
    X(rs1)
  }
}

/* Get the starting element index from csr vtype */
val get_start_element : unit -> int effect {escape, rreg, wreg}
function get_start_element() = {
  start_element     : int = unsigned(vstart);
  vsew_bits : int = get_vtype_vsew();
  //print("start_element0=" ^ BitStr(to_bits(sizeof(xlen),start_element)));
  //print("element_width0=" ^ BitStr(to_bits(sizeof(xlen),vsew_bits)));
  /* The use of vstart values greater than the largest element
       index for the current SEW setting is reserved.
     It is recommended that implementations trap if vstart is out of bounds.
       It is not required to trap, as a possible future use of upper vstart bits
       is to store imprecise trap information. */
  if start_element > ((8 * sizeof(vlen) / vsew_bits) - 1) then {
    //handle_illegal()
    start_element = -1;
    print("illegal start_element or luml")
  };
  //print("end get");
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
  //print_int("start_element",start_element);
  //print_int("end_element",end_element);

  if start_element < 0 then {
    /* start element is not valid */
    result      = undefined;
    mask_helper = undefined;
  }
  else {
    /* Determine the actual number of elements when lmul < 1 */
    var real_num_elem : int = undefined;
    if lmul >= 1.0 then {
      real_num_elem = num_elem;
      //print("init_masked_result: lmul >= 1.0")
    }
    else {
      real_num_elem = floor(lmul * to_real(num_elem))
    };
    assert(num_elem >= real_num_elem);

    foreach (i from 0 to (num_elem - 1)) {
      if i < start_element then {
        /* Prestart elements defined by vstart */
        result[i] = vd_val[i];
        mask_helper[i] = false
      }
      else if i > end_element then {
        /* Tail elements defined by vl */
        if tail_ag == UNDISTURBED then {
          result[i] = vd_val[i];
          //print("undisturbed")
        }
        else if tail_ag == AGNOSTIC then {
          //result[i] = sail_sign_extend(0b1, vsew_bits)
          result[i] = vd_val[i];
          //print("agnositc")
        };
        mask_helper[i] = false
      }
      else if i >= real_num_elem then {
        /* Tail elements defined by lmul < 1 */
        if tail_ag == UNDISTURBED then {
          result[i] = vd_val[i];
          //print("undisturbed0")
        }
        else if tail_ag == AGNOSTIC then {
          //result[i] = sail_sign_extend(0b1, vsew_bits)
          result[i] = vd_val[i];
          //print("agnostic0")
        };
        mask_helper[i] = false
      }

      else if vm_val[i] == false then {
        /* Inactive body elements defined by vm */
        if mask_ag == UNDISTURBED then {
          result[i] = vd_val[i]
        }
        else if mask_ag == AGNOSTIC then {
          //result[i] = sail_sign_extend(0b1, vsew_bits)
          result[i] = vd_val[i]
        };
        mask_helper[i] = false
      }
      else {
        /* Active body elements */
        mask_helper[i] = true;
        //print_int("i=",i)
      }
    };
    //print("end loop")
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
  var real_num_elem : int = undefined;
  if lmul >= 1.0 then {
    real_num_elem = num_elem
  }
  else {
    real_num_elem = floor(lmul * to_real(num_elem))
  };
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      result[i] = vd_val[i];
      mask_helper[i] = false
    }
    else if i > end_element then {
      /* Tail elements defined by vl */
      /* Mask tail is always agnostic */
      //result[i] = bitone
      result[i] = vd_val[i];
      mask_helper[i] = false
    }
    else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      /* Mask tail is always agnostic */
      //result[i] = bitone
      result[i] = vd_val[i];
      mask_helper[i] = false
    }
    else {
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
  var real_num_elem : int = undefined;
  if lmul >= 1.0 then {
    real_num_elem = num_elem
  }
  else {
    real_num_elem = floor(lmul * to_real(num_elem))
  };
  assert(num_elem >= real_num_elem);

  foreach (i from 0 to (num_elem - 1)) {
    if i < start_element then {
      /* Prestart elements defined by vstart */
      result[i] = vd_val[i];
      mask_helper[i] = false
    }
    else if i > end_element then {
      /* Tail elements defined by vl */
      /* Mask tail is always agnostic */
      //result[i] = bitone
      result[i] = vd_val[i];
      mask_helper[i] = false
    }
    else if i >= real_num_elem then {
      /* Tail elements defined by lmul < 1 */
      /* Mask tail is always agnostic */
      //result[i] = bitone
      result[i] = vd_val[i];
      mask_helper[i] = false
    }
    else if vm_val[i] == false then {
      /* Inactive body elements defined by vm */
      if mask_ag == UNDISTURBED then {
        result[i] = vd_val[i]
      }
      else if mask_ag == AGNOSTIC then {
        //result[i] = bitone
	      result[i] = vd_val[i]
      };
      mask_helper[i] = false
    }
    else {
      /* Active body elements */
      mask_helper[i] = true
    }
  };

  (result, mask_helper)
}

/* Misc number functions */

val negate_int : int -> int
function negate_int(value) = {
  let negated : int = 0 - value;
  negated
}

val negate_real : real -> real
function negate_real(value) = {
  let negated : real = 0.0 - value;
  negated
}

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
  }
  else {
    canonical_NaN(vsew_bits)
  }
}

val log2 : forall 'n, 8 <= 'n <= 1024. int('n) -> int
function log2(n) = {
  let result : int = match n {
    8    => 3,
    16   => 4,
    32   => 5,
    64   => 6,
    128  => 7,
    256  => 8,
    512  => 9,
    1024 => 10
  };
  result
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
    let rounding_mode = readCSR(csr_name_map("vxrm"));
    rounding_incr = match rounding_mode {
      _ : bits(xlen - 2) @ 0b00 => slice(vec_elem, shift_amount - 1, 1),
      _ : bits(xlen - 2) @ 0b01 => bool_to_bits(
        (slice(vec_elem, shift_amount - 1, 1) == 0b1) & (slice(vec_elem, 0, shift_amount - 1) != zeros() | slice(vec_elem, shift_amount, 1) == 0b1)),
      _ : bits(xlen - 2) @ 0b10 => 0b0,
      _ : bits(xlen - 2) @ 0b11 => bool_to_bits(
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
  }
  else {
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
  }
  else if signed(elem) < signed( EXTZ('m, 0b1) << ('m - 1) ) then {
    elem_sat = to_bits('m, signed( EXTZ('m, 0b1) << ('m - 1) ) );
    writeCSR(csr_name_map("vxsat"), EXTZ(0b1))
  }
  else {
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


/*
 * Floating point functions
 *
 * fp_to_real       - converts fp bitvector to real number with separate sign and type
 * fpzero           - get a fp bitvector of zero
 * fpsat            - get a fp bitvector of the largest possible pos/neg number
 * fpnan            - get a fp bitvector of not-a-number
 * fpinf            - get a fp bitvector of pos/neg infinity
 * fpexception      - write a floating-point exception flag to fcsr
 * real_to_fp       - converts a real number to a fp bitvector
 * fp_process_nan*  - checks not-a-number status
 * fp_*             - do operations between fp bitvectors
 * fpreal_*         - do operations between real numbers
 *
 */
val fp_to_real : forall 'n, 'n in {16, 32, 64, 128}. bits('n) -> (FPType, bits(1), real) effect {undef}
function fp_to_real(fpval) = {
  fptype : FPType  = undefined;
  sign   : bits(1) = undefined;
  result : real    = undefined;

  match ('n, get_vector_datatype()) {
    (16, FP_VDATATYPE) => {
                            sign            = [fpval[15]];
                            exp  : bits(5)   = slice(fpval, 10, 5);
                            frac : bits(10) = slice(fpval, 0, 10);
                            if is_zeros(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPZERO;
                                result = 0.0;
                              }
                              else {
                                fptype = FPNONZERO;
                                result = 2.0 ^ (unsigned(exp) - 15) * (to_real(unsigned(frac)) * 2.0 ^ negate_int(10))
                              }
                            }
                            else if is_ones(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPINF;
                                result = 2.0 ^ 1000000
                              }
                              else {
                                fptype = if [frac[9]] == 0b1 then FPQNAN else FPSNAN;
                                result = 0.0
                              }
                            }
                            else {
                              fptype = FPNONZERO;
                              result = 2.0 ^ (unsigned(exp) - 15) * (1.0 + to_real(unsigned(frac)) * 2.0 ^ negate_int(10))
                            }
                          },
    (32, FP_VDATATYPE) => {
                            sign            = [fpval[31]];
                            exp  : bits(8)  = slice(fpval, 23, 8);
                            frac : bits(23) = slice(fpval, 0, 23);
                            if is_zeros(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPZERO;
                                result = 0.0;
                              }
                              else {
                                fptype = FPNONZERO;
                                result = 2.0 ^ (unsigned(exp) - 127) * (to_real(unsigned(frac)) * 2.0 ^ negate_int(23))
                              }
                            }
                            else if is_ones(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPINF;
                                result = 2.0 ^ 1000000
                              }
                              else {
                                fptype = if [frac[22]] == 0b1 then FPQNAN else FPSNAN;
                                result = 0.0
                              }
                            }
                            else {
                              fptype = FPNONZERO;
                              result = 2.0 ^ (unsigned(exp) - 127) * (1.0 + to_real(unsigned(frac)) * 2.0 ^ negate_int(23))
                            }
                          },
    (64, FP_VDATATYPE) => {
                            sign            = [fpval[63]];
                            exp  : bits(11) = slice(fpval, 52, 11);
                            frac : bits(52) = slice(fpval, 0, 52);
                            if is_zeros(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPZERO;
                                result = 0.0;
                              }
                              else {
                                fptype = FPNONZERO;
                                result = 2.0 ^ (unsigned(exp) - 1023) * (to_real(unsigned(frac)) * 2.0 ^ negate_int(52))
                              }
                            }
                            else if is_ones(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPINF;
                                result = 2.0 ^ 1000000
                              }
                              else {
                                fptype = if [frac[51]] == 0b1 then FPQNAN else FPSNAN;
                                result = 0.0
                              }
                            }
                            else {
                              fptype = FPNONZERO;
                              result = 2.0 ^ (unsigned(exp) - 1023) * (1.0 + to_real(unsigned(frac)) * 2.0 ^ negate_int(52))
                            }
                          },
    (128,FP_VDATATYPE) => {
    	  		    sign             = [fpval[127]];
			    exp  : bits(15)  = slice(fpval, 112, 15);
			    frac : bits(112) = slice(fpval, 0, 112);
			    if is_zeros(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPZERO;
                                result = 0.0;
                              }
                              else {
                                fptype = FPNONZERO;
                                result = 2.0 ^ (unsigned(exp) - 16383) * (to_real(unsigned(frac)) * 2.0 ^ negate_int(112))
                              }
                            }
                            else if is_ones(exp) then {
                              if is_zeros(frac) then {
                                fptype = FPINF;
                                result = 2.0 ^ 1000000
                              }
                              else {
                                fptype = if [frac[111]] == 0b1 then FPQNAN else FPSNAN;
                                result = 0.0
                              }
                            }
                            else {
                              fptype = FPNONZERO;
                              result = 2.0 ^ (unsigned(exp) - 16383) * (1.0 + to_real(unsigned(frac)) * 2.0 ^ negate_int(112))
                            }
                          }
  };

  if sign == 0b1 then result = negate_real(result);
  (fptype, sign, result)
}

val fpzero : forall 'n, 'n in {16, 32, 64, 128}. (implicit('n), bits(1)) -> bits('n)
function fpzero(numbits, sign) = {
  match ('n, get_vector_datatype()) {
    (16, FP_VDATATYPE) => {
                            exp  : bits(5)  = EXTZ(0b0);
                            frac : bits(10) = EXTZ(0b0);
                            (sign @ exp) @ frac
                	  },
    (32, FP_VDATATYPE) => {
                            exp  : bits(8)  = EXTZ(0b0);
                            frac : bits(23) = EXTZ(0b0);
                            (sign @ exp) @ frac
                	  },
    (64, FP_VDATATYPE) => {
                            exp  : bits(11) = EXTZ(0b0);
                            frac : bits(52) = EXTZ(0b0);
                            (sign @ exp) @ frac
                	  },
    (128,FP_VDATATYPE) => {
    		            exp  : bits(15)  = EXTZ(0b0);
			    frac : bits(112) = EXTZ(0b0);
			    (sign @ exp) @ frac
                          }
  }
}

val fpsat : forall 'n, 'n in {16, 32, 64, 128}. (implicit('n), bits(1)) -> bits('n)
function fpsat(numbits, sign) = {
  match ('n, get_vector_datatype()) {
    (16, FP_VDATATYPE) => {
                            exp  : bits(5)  = sail_sign_extend(0b1, 4) @ 0b0;
                            frac : bits(10) = EXTS(0b1);
                            (sign @ exp) @ frac
                	  },
    (32, FP_VDATATYPE) => {
                            exp  : bits(8)  = sail_sign_extend(0b1, 7) @ 0b0;
                            frac : bits(23) = EXTS(0b1);
                            (sign @ exp) @ frac
                	  },
    (64, FP_VDATATYPE) => {
                            exp  : bits(11) = sail_sign_extend(0b1, 10) @ 0b0;
                            frac : bits(52) = EXTS(0b1);
                            (sign @ exp) @ frac
                	  },
    (128,FP_VDATATYPE) => {
    		            exp  : bits(15)  = sail_sign_extend(0b1, 14) @ 0b0;
			    frac : bits(112) = EXTS(0b1);
			    (sign @ exp) @ frac
                          }
  }
}

val fpnan : forall 'n, 'n in {16, 32, 64, 128}. (implicit('n)) -> bits('n)
function fpnan(numbits) = {
  let sign : bits(1) = 0b0;
  match ('n, get_vector_datatype()) {
    (16, FP_VDATATYPE) => {
                            exp  : bits(5)  = EXTS(0b1);
                            frac : bits(10) = 0b1 @ sail_zero_extend(0b0, 9);
                            (sign @ exp) @ frac
                	  },
    (32, FP_VDATATYPE) => {
                            exp  : bits(8)  = EXTS(0b1);
                            frac : bits(23) = 0b1 @ sail_zero_extend(0b0, 22);
                            (sign @ exp) @ frac
                	  },
    (64, FP_VDATATYPE) => {
                            exp  : bits(11) = EXTS(0b1);
                            frac : bits(52) = 0b1 @ sail_zero_extend(0b0, 51);
                            (sign @ exp) @ frac
                	  },
    (128,FP_VDATATYPE) => {
    		            exp  : bits(15)  = EXTS(0b1);
			    frac : bits(112) = 0b1 @ sail_zero_extend(0b0, 111);
			    (sign @ exp) @ frac
                          }
  }
}

val fpinf : forall 'n, 'n in {16, 32, 64, 128}. (implicit('n), bits(1)) -> bits('n)
function fpinf(numbits, sign) = {
  match ('n, get_vector_datatype()) {
    (16, FP_VDATATYPE) => {
                            exp  : bits(5)  = EXTS(0b1);
                            frac : bits(10) = EXTZ(0b0);
                            (sign @ exp) @ frac
                	  },
    (32, FP_VDATATYPE) => {
                            exp  : bits(8)  = EXTS(0b1);
                            frac : bits(23) = EXTZ(0b0);
                            (sign @ exp) @ frac
                	  },
    (64, FP_VDATATYPE) => {
                            exp  : bits(11) = EXTS(0b1);
                            frac : bits(52) = EXTZ(0b0);
                            (sign @ exp) @ frac
                	  },
    (128,FP_VDATATYPE) => {
    		            exp  : bits(15)  = EXTS(0b1);
			    frac : bits(112) = EXTZ(0b0);
			    (sign @ exp) @ frac
                          }
  }
}

val fpexception : bits(5) -> unit effect {escape, rreg, wreg} 
function fpexception(fflag) = {
  accrue_fflags(fflag)
}

val real_to_fp : forall 'n, 'n in {16, 32, 64, 128}. (implicit('n), real) -> bits('n) effect {escape, rreg, undef, wreg}
function real_to_fp(numbits, realval) = {
  round_type : rounding_mode = get_fp_rounding_mode();
  result     : bits('n)   = undefined;
  sign       : bits(1)    = undefined;
  exp        : int        = 0;
  frac       : real       = undefined;
  expbits    : int        = undefined;
  fracbits   : int        = undefined;
  minexp     : int        = undefined;
  (expbits, fracbits, minexp) = match ('n, get_vector_datatype()) {
    (16, FP_VDATATYPE)  => (5, 10, negate_int(14)),
    (32, FP_VDATATYPE)  => (8, 23, negate_int(126)),
    (64, FP_VDATATYPE)  => (11, 52, negate_int(1022)),
    (128, FP_VDATATYPE) => (15, 112, negate_int(16382))
  };
  let expbits  = expbits;
  let fracbits = fracbits;

  if realval < 0.0 then {
    sign = 0b1;
    frac = negate_real(realval)
  }
  else {
    sign = 0b0;
    frac = realval;
  };

  while frac < 1.0 do {
    frac = frac * 2.0;
    exp  = exp - 1;
  };
  while frac >= 2.0 do {
    frac = frac / 2.0;
    exp  = exp + 1
  };

  if exp < minexp then {
    return(fpzero(sign))
  };

  biased_exp : int = max(exp - minexp + 1, 0);
  if biased_exp == 0 then frac = frac / 2.0 ^ (minexp - exp);
  
  int_frac : int  = floor(frac * 2.0 ^ fracbits);
  error    : real = frac * 2.0 ^ fracbits - to_real(int_frac);

  if biased_exp == 0 & error != 0.0 then {
    fpexception(ufFlag())
  };

  overflow_to_inf : bool = undefined;
  round_up        : bool = undefined;
  match round_type {
    RM_RNE => {
    	        /* Round to nearest, ties to even */
		round_up = error > 0.5 | error == 0.5 & get_slice_int(1, int_frac, 0) == 0b1;
                overflow_to_inf = true
              },
    RM_RTZ => {
                /* Round towards zero */
                round_up        = false;
		overflow_to_inf = false
              },
    RM_RDN => {
    	        /* Round down towards negative infinity */
		round_up = error != 0.0 & sign == 0b1;
                overflow_to_inf = sign == 0b1
              },
    RM_RUP => {
    	        /* Round up towards positive infinity */
		round_up = error != 0.0 & sign == 0b0;
                overflow_to_inf = sign == 0b0
              },
    RM_RMM => {
                /* Round to nearest, ties to max magnitude */
		round_up        = error >= 0.5;
		overflow_to_inf = true
              }
  };
  if round_up then {
    int_frac = int_frac + 1;
    if int_frac == 2 ^ fracbits then {
      biased_exp = 1;
    };
    if int_frac == 2 ^ (fracbits + 1) then {
      biased_exp = biased_exp + 1;
      int_frac = int_frac / 2;
    }   
  };

  if 'n > 16 then {
    if biased_exp >= 2 ^ expbits - 1 then {
      result = if overflow_to_inf then fpinf(sign) else fpsat(sign);
      fpexception(ofFlag());
      error = 1.0
    }
    else {
      result = (sign @ get_slice_int('n - fracbits - 1, biased_exp, 0)) @ get_slice_int(fracbits, int_frac, 0)
    }
  }
  else {
    if biased_exp >= 2 ^ expbits then {
      result = sign @ ones('n - 1);
      fpexception(nvFlag());
      error = 0.0
    }
    else {
      result = (sign @ get_slice_int('n - fracbits - 1, biased_exp, 0)) @ get_slice_int(fracbits, int_frac, 0)
    }
  };

  if error != 0.0 then {
    fpexception(nxFlag())
  };

  result
}

val fp_process_nan : forall 'n, 'n in {16, 32, 64, 128}. (FPType, bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_process_nan(type1, op1) = {
  topfrac : int      = undefined;
  result  : bits('n) = undefined;
  topfrac = match ('n, get_vector_datatype()) {
    (16, FP_VDATATYPE) => 9,
    (32, FP_VDATATYPE) => 22,
    (64, FP_VDATATYPE) => 51,
    (128, FP_VDATATYPE) => 111
  };
  let topfrac = topfrac;
  assert(0 <= topfrac & topfrac < 'n);
  result = op1;
  if type1 == FPSNAN then {
    result[topfrac] = bitone;
    fpexception(nvFlag())
  };
  result
}

val fp_process_nan2 : forall 'n, 'n in {16, 32, 64, 128}. (FPType, FPType, bits('n), bits('n)) -> (bool, bits('n)) effect {escape, rreg, undef, wreg}
function fp_process_nan2(type1, type2, op1, op2) = {
  done   : bool     = undefined;
  result : bits('n) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    done   = true;
    result = fp_process_nan(type1, op1)
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    done   = true;
    result = fp_process_nan(type2, op2)
  }
  else {
    done   = false;
    result = zeros('n)
  };
  (done, result)
}

val fp_process_nan_cmp : forall 'n, 'n in {16, 32, 64, 128}. (FPType, FPType, bits('n), bits('n)) -> (bool, bool) effect {escape, rreg, undef, wreg}
function fp_process_nan_cmp(type1, type2, op1, op2) = {
  done   : bool = undefined;
  result : bool = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    done   = true;
    result = false
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    done   = true;
    result = false
  }
  else {
    done   = false;
    result = true
  };

  if type1 == FPSNAN | type2 == FPSNAN then {
    fpexception(nvFlag())
  };

  (done, result)
}

val fp_process_nan3 : forall 'n, 'n in {16, 32, 64, 128}. (FPType, FPType, FPType, bits('n), bits('n), bits('n)) -> (bool, bits('n)) effect {escape, rreg, undef, wreg}
function fp_process_nan3(type1, type2, type3, op1, op2, op3) = {
  done   : bool     = undefined;
  result : bits('n) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    done   = true;
    result = fp_process_nan(type1, op1)
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    done   = true;
    result = fp_process_nan(type2, op2)
  }
  else if type3 == FPSNAN | type3 == FPQNAN then {
    done   = true;
    result = fp_process_nan(type3, op3)
  }
  else {
    done   = false;
    result = zeros('n)
  };
  (done, result)
}

/* This function is the special NaN processing for floating point max and min. It returns the other operand if one operand is NaN. */
val fp_process_nan4 : forall 'n, 'n in {16, 32, 64, 128}. (FPType, FPType, bits('n), bits('n)) -> (bool, bits('n)) effect {escape, rreg, undef, wreg}
function fp_process_nan4(type1, type2, op1, op2) = {
  done   : bool     = undefined;
  result : bits('n) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    done   = true;
    result = op2
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    done   = true;
    result = op1
  }
  else {
    done   = false;
    result = zeros('n)
  };
  (done, result)
}
/*
val fp_add : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_add(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan2(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    zero1 : bool = type1 == FPZERO;
    zero2 : bool = type2 == FPZERO;
    if (inf1 & inf2) & sign1 == ~(sign2) then {
      result = fpnan();
      fpexception(nvFlag())
    }
    else if inf1 & sign1 == 0b0 | inf2 & sign2 == 0b0 then {
      result = fpinf(0b0)
    }
    else if inf1 & sign1 == 0b1 | inf2 & sign2 == 0b1 then {
      result = fpinf(0b1)
    }
    else if (zero1 & zero2) & sign1 == sign2 then {
      result = fpzero(sign1)
    }
    else {
      result_value : real = val1 + val2;
      if result_value == 0.0 then {
        result = fpzero(0b0)
      }
      else {
        result = real_to_fp(result_value)
      }
    }
  };

  result
}
*/
val fp_add: forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_add(rm_3b, op1, op2) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  (fflags, result_val) = match 'n {
    16  => riscv_f16Add(rm_3b, op1, op2),
    32  => riscv_f32Add(rm_3b, op1, op2),
    64  => riscv_f64Add(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fpreal_add : ((FPType, bits(1), real), (FPType, bits(1), real)) -> (FPType, bits(1), real) effect {escape, rreg, undef, wreg}
function fpreal_add((type1, sign1, val1), (type2, sign2, val2)) = {
  resultval  : real    = undefined;
  resulttype : FPType  = undefined;
  resultsign : bits(1) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    resulttype = type1;
    resultsign = sign1;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    resulttype = type2;
    resultsign = sign2;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    zero1 : bool = type1 == FPZERO;
    zero2 : bool = type2 == FPZERO;
    if (inf1 & inf2) & sign1 == ~(sign2) then {
      resultval  = 0.0;
      resulttype = FPQNAN;
      resultsign = 0b0;
      fpexception(nvFlag())
    }
    else if inf1 & sign1 == 0b0 | inf2 & sign2 == 0b0 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b0
    }
    else if inf1 & sign1 == 0b1 | inf2 & sign2 == 0b1 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b1
    }
    else if (zero1 & zero2) & sign1 == sign2 then {
      resultval  = 0.0;
      resulttype = FPZERO;
      resultsign = sign1
    }
    else {
      resultval = val1 + val2;
      if resultval == 0.0 then {
        resulttype = FPZERO;
	      resultsign = 0b0
      }
      else {
        resulttype = FPNONZERO;
	      if resultval >= 0.0 then resultsign = 0b0 else resultsign = 0b1
      }
    }
  };

  (resulttype, resultsign, resultval)
}
/*
val fp_sub : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_sub(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan2(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    zero1 : bool = type1 == FPZERO;
    zero2 : bool = type2 == FPZERO;
    if (inf1 & inf2) & sign1 == sign2 then {
      result = fpnan();
      fpexception(nvFlag())
    }
    else if inf1 & sign1 == 0b0 | inf2 & sign2 == 0b1 then {
      result = fpinf(0b0)
    }
    else if inf1 & sign1 == 0b1 | inf2 & sign2 == 0b0 then {
      result = fpinf(0b1)
    }
    else if (zero1 & zero2) & sign1 == ~(sign2) then {
      result = fpzero(sign1)
    }
    else {
      result_value : real = val1 - val2;
      if result_value == 0.0 then {
        result = fpzero(0b0)
      }
      else {
        result = real_to_fp(result_value)
      }
    }
  };

  result
}
*/

val fp_sub: forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_sub(rm_3b, op1, op2) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  (fflags, result_val) = match 'n {
    16  => riscv_f16Sub(rm_3b, op1, op2),
    32  => riscv_f32Sub(rm_3b, op1, op2),
    64  => riscv_f64Sub(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}

val fpreal_sub : ((FPType, bits(1), real), (FPType, bits(1), real)) -> (FPType, bits(1), real) effect {escape, rreg, undef, wreg}
function fpreal_sub((type1, sign1, val1), (type2, sign2, val2)) = {
  resultval  : real    = undefined;
  resulttype : FPType  = undefined;
  resultsign : bits(1) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    resulttype = type1;
    resultsign = sign1;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    resulttype = type2;
    resultsign = ~(sign2);
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    zero1 : bool = type1 == FPZERO;
    zero2 : bool = type2 == FPZERO;
    if (inf1 & inf2) & sign1 == sign2 then {
      resultval  = 0.0;
      resulttype = FPQNAN;
      resultsign = 0b0;
      fpexception(nvFlag())
    }
    else if inf1 & sign1 == 0b0 | inf2 & sign2 == 0b1 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b0
    }
    else if inf1 & sign1 == 0b1 | inf2 & sign2 == 0b0 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b1
    }
    else if (zero1 & zero2) & sign1 == ~(sign2) then {
      resultval  = 0.0;
      resulttype = FPZERO;
      resultsign = sign1
    }
    else {
      resultval = val1 - val2;
      if resultval == 0.0 then {
        resulttype = FPZERO;
	      resultsign = 0b0
      }
      else {
        resulttype = FPNONZERO;
	      if resultval >= 0.0 then resultsign = 0b0 else resultsign = 0b1
      }
    }
  };

  (resulttype, resultsign, resultval)
}
/*
val fp_min : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_min(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan4(type1, type2, op1, op2);
  
  if ~(done) then {
    mtype  : FPType  = undefined;
    msign  : bits(1) = undefined;
    mval   : real    = undefined;
    if val1 < val2 then (mtype, msign, mval) = (type1, sign1, val1)
    else (mtype, msign, mval) = (type2, sign2, val2);

    if mtype == FPINF then {
      result = fpinf(msign)
    }
    else if mtype == FPZERO then {
      msign  = sign1 | sign2;
      result = fpzero(msign)
    }
    else {
      result = real_to_fp(mval)
    }
  };
  
  result
}
*/
val fp_min : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_min(op1, op2) = {
  fflags     : bits_fflags = undefined;
  temp_flags : bits_fflags = undefined;
  op1_lt_op2 : bool = undefined;
  result_val : bits('n) = undefined;

  (temp_flags, op1_lt_op2) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };

  result_val  = if (f_is_NaN(op1) & f_is_NaN(op2)) then canonical_NaN('n)
                else if f_is_NaN(op1) then op2
                else if f_is_NaN(op2) then op1
                else if (f_is_neg_zero(op1) & f_is_pos_zero(op2)) then op1
                else if (f_is_neg_zero(op2) & f_is_pos_zero(op1)) then op2
                else if op1_lt_op2 then op1
                else op2;
  if f_is_SNaN(op1) then print("op1\n");
  if f_is_SNaN(op2) then print("op2\n");
  fflags = if (f_is_SNaN(op1) | f_is_SNaN(op2)) then nvFlag() else zeros();
  write_fflags(fflags);
  result_val
}


/*
val fp_max : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_max(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan4(type1, type2, op1, op2);
  
  if ~(done) then {
    mtype  : FPType  = undefined;
    msign  : bits(1) = undefined;
    mval   : real    = undefined;
    if val1 > val2 then (mtype, msign, mval) = (type1, sign1, val1)
    else (mtype, msign, mval) = (type2, sign2, val2);

    if mtype == FPINF then {
      result = fpinf(msign)
    }
    else if mtype == FPZERO then {
      msign  = sign1 | sign2;
      result = fpzero(msign)
    }
    else {
      result = real_to_fp(mval)
    }
  };
  
  result
}
*/
val fp_max : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_max(op1, op2) = {
  fflags     : bits_fflags = undefined;
  temp_flags : bits_fflags = undefined;
  op1_lt_op2 : bool = undefined;
  result_val : bits('n) = undefined;

  (temp_flags, op1_lt_op2) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };

  result_val  = if (f_is_NaN(op1) & f_is_NaN(op2)) then canonical_NaN('n)
                else if f_is_NaN(op1) then op2
                else if f_is_NaN(op2) then op1
                else if (f_is_neg_zero(op1) & f_is_pos_zero(op2)) then op2
                else if (f_is_neg_zero(op2) & f_is_pos_zero(op1)) then op1
                else if op1_lt_op2 then op2
                else op1;
  if f_is_SNaN(op1) then print("op1\n");
  if f_is_SNaN(op2) then print("op2\n");
  fflags = if (f_is_SNaN(op1) | f_is_SNaN(op2)) then nvFlag() else zeros();
  write_fflags(fflags);
  result_val
}


/*
val fp_eq : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_eq(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bool     = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan_cmp(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    if inf1 | inf2 then {
      result = false;
      fpexception(nvFlag())
    }
    else if sign1 == sign2 & val1 == val2 then {
      result = true
    }
    else {
      result = false
    }
  };

  result
}
*/
val fp_eq : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_eq(op1, op2) = {
  fflags     : bits_fflags = undefined;
  result_val : bool = undefined;

  (fflags,result_val) = match 'n {
    16  => riscv_f16Eq(op1, op2),
    32  => riscv_f32Eq(op1, op2),
    64  => riscv_f64Eq(op1, op2)
  };
  write_fflags(fflags);
  result_val
}

/*
val fp_gt : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_gt(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bool     = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan_cmp(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    if inf1 | inf2 then {
      result = false;
      fpexception(nvFlag())
    }
    else if sign1 == 0b1 & sign2 == 0b0 then {
      result = false
    }
    else if sign1 == 0b0 & sign2 == 0b1 then {
      result = true
    }
    else {
      result = val1 > val2
    }
  };

  if type1 == FPQNAN | type2 == FPQNAN then {
    fpexception(nvFlag())
  };

  result
}
*/
val fp_gt : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_gt(op1, op2) = {
  fflags     : bits_fflags = undefined;
  temp_val   : bool = undefined;
  result_val : bool = undefined;

  (fflags, temp_val) = match 'n {
    16  => riscv_f16Le(op1, op2),
    32  => riscv_f32Le(op1, op2),
    64  => riscv_f64Le(op1, op2)
  };
  result_val = (if fflags == 0b10000 then false else ~(temp_val));
  write_fflags(fflags);
  result_val
}

/*
val fp_ge : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_ge(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bool     = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan_cmp(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    if inf1 | inf2 then {
      result = false;
      fpexception(nvFlag())
    }
    else if sign1 == 0b1 & sign2 == 0b0 then {
      result = false
    }
    else if sign1 == 0b0 & sign2 == 0b1 then {
      result = true
    }
    else {
      result = val1 >= val2
    }
  };

  if type1 == FPQNAN | type2 == FPQNAN then {
    fpexception(nvFlag())
  };

  result
}
*/
val fp_ge : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_ge(op1, op2) = {
  fflags     : bits_fflags = undefined;
  temp_val   : bool = undefined;
  result_val : bool = undefined;

  (fflags, temp_val) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };
  result_val = (if fflags == 0b10000 then false else ~(temp_val));
  write_fflags(fflags);
  result_val
}

/*
val fp_lt : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_lt(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bool     = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan_cmp(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    if inf1 | inf2 then {
      result = false;
      fpexception(nvFlag())
    }
    else if sign1 == 0b1 & sign2 == 0b0 then {
      result = true
    }
    else if sign1 == 0b0 & sign2 == 0b1 then {
      result = false
    }
    else {
      result = val1 < val2
    }
  };

  if type1 == FPQNAN | type2 == FPQNAN then {
    fpexception(nvFlag())
  };

  result
}
*/
val fp_lt : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_lt(op1, op2) = {
  fflags     : bits_fflags = undefined;
  result_val : bool = undefined;

  (fflags,result_val) = match 'n {
    16  => riscv_f16Lt(op1, op2),
    32  => riscv_f32Lt(op1, op2),
    64  => riscv_f64Lt(op1, op2)
  };
  write_fflags(fflags);
  result_val
}

/*
val fp_le : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_le(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bool     = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan_cmp(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    if inf1 | inf2 then {
      result = false;
      fpexception(nvFlag())
    }
    else if sign1 == 0b1 & sign2 == 0b0 then {
      result = true
    }
    else if sign1 == 0b0 & sign2 == 0b1 then {
      result = false
    }
    else {
      result = val1 <= val2
    }
  };

  if type1 == FPQNAN | type2 == FPQNAN then {
    fpexception(nvFlag())
  };

  result
}
*/
val fp_le : forall 'n, 'n in {16, 32, 64}. (bits('n), bits('n)) -> bool effect {escape, rreg, undef, wreg}
function fp_le(op1, op2) = {
  fflags     : bits_fflags = undefined;
  result_val : bool = undefined;

  (fflags,result_val) = match 'n {
    16  => riscv_f16Le(op1, op2),
    32  => riscv_f32Le(op1, op2),
    64  => riscv_f64Le(op1, op2)
  };
  write_fflags(fflags);
  result_val
}

/*
val fp_mul : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_mul(op1, op2) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (done, result) = fp_process_nan2(type1, type2, op1, op2);

  if ~(done) then {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    zero1 : bool = type1 == FPZERO;
    zero2 : bool = type2 == FPZERO;
    if inf1 & zero2 | zero1 & inf2 then {
      result = fpnan();
      fpexception(nvFlag());
    }
    else if inf1 | inf2 then {
      result = fpinf(sign1 ^ sign2)
    }
    else if zero1 | zero2 then {
      result = fpzero(sign1 ^ sign2)
    }
    else {
      result = real_to_fp(val1 * val2)
    }
  };

  result
}
*/
val fp_mul : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_mul(rm_3b, op1, op2) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  (fflags, result_val) = match 'n {
    16  => riscv_f16Mul(rm_3b, op1, op2),
    32  => riscv_f32Mul(rm_3b, op1, op2),
    64  => riscv_f64Mul(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}


val fpreal_mul : ((FPType, bits(1), real), (FPType, bits(1), real)) -> (FPType, bits(1), real) effect {escape, rreg, undef, wreg}
function fpreal_mul((type1, sign1, val1), (type2, sign2, val2)) = {
  resultval  : real    = undefined;
  resulttype : FPType  = undefined;
  resultsign : bits(1) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    resulttype = type1;
    resultsign = sign1;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    resulttype = type2;
    resultsign = sign2;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else {
    inf1  : bool = type1 == FPINF;
    inf2  : bool = type2 == FPINF;
    zero1 : bool = type1 == FPZERO;
    zero2 : bool = type2 == FPZERO;
    if inf1 & zero2 | zero1 & inf2 then {
      resultval  = 0.0;
      resulttype = FPQNAN;
      resultsign = 0b0;
      fpexception(nvFlag())
    }
    else if inf1 | inf2 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = sign1 ^ sign2
    }
    else if zero1 | zero2 then {
      resultval  = 0.0;
      resulttype = FPZERO;
      resultsign = sign1 ^ sign2
    }
    else {
      resultval = val1 * val2;
      if resultval == 0.0 then {
        resulttype = FPZERO;
	      resultsign = 0b0
      }
      else {
        resulttype = FPNONZERO;
	      if resultval >= 0.0 then resultsign = 0b0 else resultsign = 0b1
      }
    }
  };

  (resulttype, resultsign, resultval)
}

val fp_div : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_div(rm_3b, op1, op2) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  (fflags, result_val) = match 'n {
    16  => riscv_f16Div(rm_3b, op1, op2),
    32  => riscv_f32Div(rm_3b, op1, op2),
    64  => riscv_f64Div(rm_3b, op1, op2)
  };
  write_fflags(fflags);
  result_val
}

/*
val fp_muladd : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_muladd(op1, op2, opadd) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  signa  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  typea  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  vala   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (typea, signa, vala) = fp_to_real(opadd);
  (done, result) = fp_process_nan3(type1, type2, typea, op1, op2, opadd);

  let inf1  : bool = type1 == FPINF;
  let inf2  : bool = type2 == FPINF;
  let infa  : bool = typea == FPINF;
  let zero1 : bool = type1 == FPZERO;
  let zero2 : bool = type2 == FPZERO;
  let zeroa : bool = typea == FPZERO;
  if typea == FPQNAN & (inf1 & zero2 | zero1 & inf2) then {
    result = fpnan();
    fpexception(nvFlag())
  };

  if ~(done) then {
    signp : bits(1) = sign1 ^ sign2;
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      result = fpnan();
      fpexception(nvFlag())
    }
    else if infa & signa == 0b0 | infp & signp == 0b0 then {
      result = fpinf(0b0)
    }
    else if infa & signa == 0b1 | infp & signp == 0b1 then {
      result = fpinf(0b1)
    }
    else if (zeroa & zerop) & signa == signp then {
      result = fpzero(signa)
    }
    else {
      result_value : real = (val1 * val2) + vala;
      if result_value == 0.0 then {
        result = fpzero(0b0)
      }
      else {
        result = real_to_fp(result_value)
      }
    }
  };
  
  result
}
*/

val fp_muladd : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_muladd(rm_3b, op1, op2, opadd) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  (fflags, result_val) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opadd),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opadd),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opadd)
  };
  write_fflags(fflags);
  result_val
}

val fpreal_muladd : ((FPType, bits(1), real), (FPType, bits(1), real), (FPType, bits(1), real)) -> (FPType, bits(1), real) effect {escape, rreg, undef, wreg}
function fpreal_muladd((type1, sign1, val1), (type2, sign2, val2), (typea, signa, vala)) = {
  resultval  : real    = undefined;
  resulttype : FPType  = undefined;
  resultsign : bits(1) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    resulttype = type1;
    resultsign = sign1;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    resulttype = type2;
    resultsign = sign2;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if typea == FPSNAN | typea == FPQNAN then {
    resulttype = typea;
    resultsign = signa;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else {
    let inf1  : bool = type1 == FPINF;
    let inf2  : bool = type2 == FPINF;
    let infa  : bool = typea == FPINF;
    let zero1 : bool = type1 == FPZERO;
    let zero2 : bool = type2 == FPZERO;
    let zeroa : bool = typea == FPZERO;
    signp : bits(1) = sign1 ^ sign2;
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      resultval  = 0.0;
      resulttype = FPQNAN;
      resultsign = 0b0;
      fpexception(nvFlag())
    }
    else if infa & signa == 0b0 | infp & signp == 0b0 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b0
    }
    else if infa & signa == 0b1 | infp & signp == 0b1 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b1
    }
    else if (zeroa & zerop) & signa == signp then {
      resultval  = 0.0;
      resulttype = FPZERO;
      resultsign = signa
    }
    else {
      resultval = (val1 * val2) + vala;
      if resultval == 0.0 then {
        resulttype = FPZERO;
        resultsign = 0b0
      }
      else {
        resulttype = FPNONZERO;
        if resultval >= 0.0 then resultsign = 0b0 else resultsign = 0b1
      }
    }
  };
  
  (resulttype, resultsign, resultval)
}

val fp_nmuladd : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_nmuladd(rm_3b, op1, op2, opadd) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  let op1 = negate_fp(op1);
  (fflags, result_val) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opadd),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opadd),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opadd)
  };
  write_fflags(fflags);
  result_val
}


/*
val fp_nmuladd : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_nmuladd(op1, op2, opadd) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  signa  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  typea  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  vala   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (typea, signa, vala) = fp_to_real(opadd);
  (done, result) = fp_process_nan3(type1, type2, typea, op1, op2, opadd);

  let inf1  : bool = type1 == FPINF;
  let inf2  : bool = type2 == FPINF;
  let infa  : bool = typea == FPINF;
  let zero1 : bool = type1 == FPZERO;
  let zero2 : bool = type2 == FPZERO;
  let zeroa : bool = typea == FPZERO;
  if typea == FPQNAN & (inf1 & zero2 | zero1 & inf2) then {
    result = fpnan();
    fpexception(nvFlag())
  };

  if ~(done) then {
    signp : bits(1) = ~(sign1 ^ sign2);
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      result = fpnan();
      fpexception(nvFlag())
    }
    else if infa & signa == 0b0 | infp & signp == 0b0 then {
      result = fpinf(0b0)
    }
    else if infa & signa == 0b1 | infp & signp == 0b1 then {
      result = fpinf(0b1)
    }
    else if (zeroa & zerop) & signa == signp then {
      result = fpzero(signa)
    }
    else {
      result_value : real = negate_real(val1 * val2) + vala;
      if result_value == 0.0 then {
        result = fpzero(0b0)
      }
      else {
        result = real_to_fp(result_value)
      }
    }
  };
  
  result
}
*/
val fpreal_nmuladd : ((FPType, bits(1), real), (FPType, bits(1), real), (FPType, bits(1), real)) -> (FPType, bits(1), real) effect {escape, rreg, undef, wreg}
function fpreal_nmuladd((type1, sign1, val1), (type2, sign2, val2), (typea, signa, vala)) = {
  resultval  : real    = undefined;
  resulttype : FPType  = undefined;
  resultsign : bits(1) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    resulttype = type1;
    resultsign = ~(sign1);
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    resulttype = type2;
    resultsign = ~(sign2);
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if typea == FPSNAN | typea == FPQNAN then {
    resulttype = typea;
    resultsign = signa;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else {
    let inf1  : bool = type1 == FPINF;
    let inf2  : bool = type2 == FPINF;
    let infa  : bool = typea == FPINF;
    let zero1 : bool = type1 == FPZERO;
    let zero2 : bool = type2 == FPZERO;
    let zeroa : bool = typea == FPZERO;
    signp : bits(1) = ~(sign1 ^ sign2);
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      resultval  = 0.0;
      resulttype = FPQNAN;
      resultsign = 0b0;
      fpexception(nvFlag())
    }
    else if infa & signa == 0b0 | infp & signp == 0b0 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b0
    }
    else if infa & signa == 0b1 | infp & signp == 0b1 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b1
    }
    else if (zeroa & zerop) & signa == signp then {
      resultval  = 0.0;
      resulttype = FPZERO;
      resultsign = signa
    }
    else {
      resultval = negate_real(val1 * val2) + vala;
      if resultval == 0.0 then {
        resulttype = FPZERO;
        resultsign = 0b0
      }
      else {
        resulttype = FPNONZERO;
        if resultval >= 0.0 then resultsign = 0b0 else resultsign = 0b1
      }
    }
  };
  
  (resulttype, resultsign, resultval)
}
/*
val fp_mulsub : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_mulsub(op1, op2, opa) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  signa  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  typea  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  vala   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (typea, signa, vala) = fp_to_real(opa);
  (done, result) = fp_process_nan3(type1, type2, typea, op1, op2, opa);

  let inf1  : bool = type1 == FPINF;
  let inf2  : bool = type2 == FPINF;
  let infa  : bool = typea == FPINF;
  let zero1 : bool = type1 == FPZERO;
  let zero2 : bool = type2 == FPZERO;
  let zeroa : bool = typea == FPZERO;
  if typea == FPQNAN & (inf1 & zero2 | zero1 & inf2) then {
    result = fpnan();
    fpexception(nvFlag())
  };

  if ~(done) then {
    signp : bits(1) = sign1 ^ sign2;
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      result = fpnan();
      fpexception(nvFlag())
    }
    else if infa & signa == 0b1 | infp & signp == 0b0 then {
      result = fpinf(0b0)
    }
    else if infa & signa == 0b0 | infp & signp == 0b1 then {
      result = fpinf(0b1)
    }
    else if (zeroa & zerop) & ~(signa) == signp then {
      result = fpzero(signp)
    }
    else {
      result_value : real = (val1 * val2) - vala;
      if result_value == 0.0 then {
        result = fpzero(0b0)
      }
      else {
        result = real_to_fp(result_value)
      }
    }
  };
  
  result
}
*/

val fp_mulsub : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_mulsub(rm_3b, op1, op2, opsub) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  let opsub = negate_fp(opsub);
  (fflags, result_val) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opsub),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opsub),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opsub)
  };
  write_fflags(fflags);
  result_val
}
val fpreal_mulsub : ((FPType, bits(1), real), (FPType, bits(1), real), (FPType, bits(1), real)) -> (FPType, bits(1), real) effect {escape, rreg, undef, wreg}
function fpreal_mulsub((type1, sign1, val1), (type2, sign2, val2), (typea, signa, vala)) = {
  resultval  : real    = undefined;
  resulttype : FPType  = undefined;
  resultsign : bits(1) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    resulttype = type1;
    resultsign = sign1;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    resulttype = type2;
    resultsign = sign2;
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if typea == FPSNAN | typea == FPQNAN then {
    resulttype = typea;
    resultsign = ~(signa);
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else {
    let inf1  : bool = type1 == FPINF;
    let inf2  : bool = type2 == FPINF;
    let infa  : bool = typea == FPINF;
    let zero1 : bool = type1 == FPZERO;
    let zero2 : bool = type2 == FPZERO;
    let zeroa : bool = typea == FPZERO;
    signp : bits(1) = sign1 ^ sign2;
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      resultval  = 0.0;
      resulttype = FPQNAN;
      resultsign = 0b0;
      fpexception(nvFlag())
    }
    else if infa & signa == 0b1 | infp & signp == 0b0 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b0
    }
    else if infa & signa == 0b0 | infp & signp == 0b1 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b1
    }
    else if (zeroa & zerop) & ~(signa) == signp then {
      resultval  = 0.0;
      resulttype = FPZERO;
      resultsign = signp
    }
    else {
      resultval = (val1 * val2) - vala;
      if resultval == 0.0 then {
        resulttype = FPZERO;
        resultsign = 0b0
      }
      else {
        resulttype = FPNONZERO;
        if resultval >= 0.0 then resultsign = 0b0 else resultsign = 0b1
      }
    }
  };
  
  (resulttype, resultsign, resultval)
}

/*
val fp_nmulsub : forall 'n, 'n in {16, 32, 64, 128}. (bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_nmulsub(op1, op2, opa) = {
  sign1  : bits(1)  = undefined;
  sign2  : bits(1)  = undefined;
  signa  : bits(1)  = undefined;
  type1  : FPType   = undefined;
  type2  : FPType   = undefined;
  typea  : FPType   = undefined;
  val1   : real     = undefined;
  val2   : real     = undefined;
  vala   : real     = undefined;
  result : bits('n) = undefined;
  done   : bool     = undefined;
  (type1, sign1, val1) = fp_to_real(op1);
  (type2, sign2, val2) = fp_to_real(op2);
  (typea, signa, vala) = fp_to_real(opa);
  (done, result) = fp_process_nan3(type1, type2, typea, op1, op2, opa);

  let inf1  : bool = type1 == FPINF;
  let inf2  : bool = type2 == FPINF;
  let infa  : bool = typea == FPINF;
  let zero1 : bool = type1 == FPZERO;
  let zero2 : bool = type2 == FPZERO;
  let zeroa : bool = typea == FPZERO;
  if typea == FPQNAN & (inf1 & zero2 | zero1 & inf2) then {
    result = fpnan();
    fpexception(nvFlag())
  };

  if ~(done) then {
    signp : bits(1) = ~(sign1 ^ sign2);
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      result = fpnan();
      fpexception(nvFlag())
    }
    else if infa & signa == 0b1 | infp & signp == 0b0 then {
      result = fpinf(0b0)
    }
    else if infa & signa == 0b0 | infp & signp == 0b1 then {
      result = fpinf(0b1)
    }
    else if (zeroa & zerop) & ~(signa) == signp then {
      result = fpzero(signp)
    }
    else {
      result_value : real = negate_real(val1 * val2) - vala;
      if result_value == 0.0 then {
        result = fpzero(0b0)
      }
      else {
        result = real_to_fp(result_value)
      }
    }
  };
  result
}
*/
val fp_nmulsub : forall 'n, 'n in {16, 32, 64}. (bits(3), bits('n), bits('n), bits('n)) -> bits('n) effect {escape, rreg, undef, wreg}
function fp_nmulsub(rm_3b, op1, op2, opsub) = {
  fflags : bits_fflags = undefined;
  result_val : bits('n) = undefined;
  let opsub = negate_fp(opsub);
  let op1 = negate_fp(op1);
  (fflags, result_val) = match 'n {
    16  => riscv_f16MulAdd(rm_3b, op1, op2, opsub),
    32  => riscv_f32MulAdd(rm_3b, op1, op2, opsub),
    64  => riscv_f64MulAdd(rm_3b, op1, op2, opsub)
  };
  write_fflags(fflags);
  result_val
}
val fpreal_nmulsub : ((FPType, bits(1), real), (FPType, bits(1), real), (FPType, bits(1), real)) -> (FPType, bits(1), real) effect {escape, rreg, undef, wreg}
function fpreal_nmulsub((type1, sign1, val1), (type2, sign2, val2), (typea, signa, vala)) = {
  resultval  : real    = undefined;
  resulttype : FPType  = undefined;
  resultsign : bits(1) = undefined;
  if type1 == FPSNAN | type1 == FPQNAN then {
    resulttype = type1;
    resultsign = ~(sign1);
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if type2 == FPSNAN | type2 == FPQNAN then {
    resulttype = type2;
    resultsign = ~(sign2);
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else if typea == FPSNAN | typea == FPQNAN then {
    resulttype = typea;
    resultsign = ~(signa);
    resultval  = 0.0;
    fpexception(nvFlag())
  }
  else {
    let inf1  : bool = type1 == FPINF;
    let inf2  : bool = type2 == FPINF;
    let infa  : bool = typea == FPINF;
    let zero1 : bool = type1 == FPZERO;
    let zero2 : bool = type2 == FPZERO;
    let zeroa : bool = typea == FPZERO;
    signp : bits(1) = ~(sign1 ^ sign2);
    infp  : bool    = inf1 | inf2;
    zerop : bool    = zero1 | zero2;
    if (inf1 & zero2 | zero1 & inf2) | (infa & infp) & signa != signp then {
      resultval  = 0.0;
      resulttype = FPQNAN;
      resultsign = 0b0;
      fpexception(nvFlag())
    }
    else if infa & signa == 0b1 | infp & signp == 0b0 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b0
    }
    else if infa & signa == 0b0 | infp & signp == 0b1 then {
      resultval  = 0.0;
      resulttype = FPINF;
      resultsign = 0b1
    }
    else if (zeroa & zerop) & ~(signa) == signp then {
      resultval  = 0.0;
      resulttype = FPZERO;
      resultsign = signp
    }
    else {
      resultval = negate_real(val1 * val2) - vala;
      if resultval == 0.0 then {
        resulttype = FPZERO;
        resultsign = 0b0
      }
      else {
        resulttype = FPNONZERO;
        if resultval >= 0.0 then resultsign = 0b0 else resultsign = 0b1
      }
    }
  };
  
  (resulttype, resultsign, resultval)
}

val fp_class : forall 'n, 'n in {16, 32, 64, 128}. bits('n) -> bits('n) effect {undef}
function fp_class(op) = {
  opsign   : bits(1)  = undefined;
  optype   : FPType   = undefined;
  opval    : real     = undefined;
  (optype, opsign, opval) = fp_to_real(op);

  let class_10b : bits (10) = match optype {
    FPNONZERO  => {
                    if opsign == 0b0 then {
                      match 'n {
                        16  => {if is_zeros(op[('n - 2)..('n - 6)])  
                                then 0b_00_0010_0000 else 0b_00_0100_0000},
                        32  => {if is_zeros(op[('n - 2)..('n - 9)])  
                                then 0b_00_0010_0000 else 0b_00_0100_0000},
                        64  => {if is_zeros(op[('n - 2)..('n - 12)]) 
                                then 0b_00_0010_0000 else 0b_00_0100_0000},
                        128 => {if is_zeros(op[('n - 2)..('n - 16)]) 
                                then 0b_00_0010_0000 else 0b_00_0100_0000}
                      }
                    }
                    else {
                      match 'n {
                        16  => {if is_zeros(op[('n - 2)..('n - 6)])  
                                then 0b_00_0000_0100 else 0b_00_0000_0010},
                        32  => {if is_zeros(op[('n - 2)..('n - 9)])  
                                then 0b_00_0000_0100 else 0b_00_0000_0010},
                        64  => {if is_zeros(op[('n - 2)..('n - 12)]) 
                                then 0b_00_0000_0100 else 0b_00_0000_0010},
                        128 => {if is_zeros(op[('n - 2)..('n - 16)]) 
                                then 0b_00_0000_0100 else 0b_00_0000_0010}
                      }
                    }
                  },
    FPZERO     => {
                    if opsign == 0b0 then 0b_00_0001_0000
                    else 0b_00_0000_1000
                  },
    FPINF      => {
                    if opsign == 0b0 then 0b_00_1000_0000
                    else 0b_00_0000_0001 
                  },
    FPQNAN     => 0b_10_0000_0000,
    FPSNAN     => 0b_01_0000_0000
  };

  EXTZ(class_10b);
}

val fp_widen : forall 'm, ('m in {16, 32} & 'm <= flen). bits('m) -> bits('m * 2)
function fp_widen(nval) = {
  let rm_3b = fcsr.FRM();
  fflags : bits_fflags  = undefined;
  wval   : bits('m * 2) = undefined;
  (fflags, wval) = match 'm {
    16 => riscv_f16ToF32(rm_3b, nval),
    32 => riscv_f32ToF64(rm_3b, nval)
  };
  accrue_fflags(fflags);
  wval
}
