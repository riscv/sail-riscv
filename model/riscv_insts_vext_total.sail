/* ****************************************************************** */
/* This file specifies the instructions in the vector set.      */


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
val assert_vstart : int -> Retired
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

/* Get the floating point rounding mode from csr fcsr */
val get_fp_rounding_mode : unit -> rounding_mode effect {rreg}
function get_fp_rounding_mode() = encdec_rounding_mode(fcsr.FRM())

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

val fpexception : bits(5) -> unit effect {rreg, wreg} 
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

val fp_process_nan_cmp : forall 'n, 'n in {16, 32, 64, 128}. (FPType, FPType, bits('n), bits('n)) -> (bool, bool) effect {rreg, undef, wreg}
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



/* **************************VSET_TYPE(3)**************************************** */
/* **************************VSET_TYPE(2 + 1)**************************************** */
mapping sew_flag : string <-> bits(3) = {
  "e8"    <-> 0b000,
  "e16"   <-> 0b001,
  "e32"   <-> 0b010,
  "e64"   <-> 0b011,
  "e128"  <-> 0b100,
  "e256"  <-> 0b101,
  "e512"  <-> 0b110,
  "e1024" <-> 0b111
} 

mapping maybe_lmul_flag : string <-> bits(3) = {
  ""              <-> 0b000, /* m1 by default */
  sep() ^ "mf8"   <-> 0b101,
  sep() ^ "mf4"   <-> 0b110,
  sep() ^ "mf2"   <-> 0b111,
  sep() ^ "m1"    <-> 0b000,
  sep() ^ "m2"    <-> 0b001,
  sep() ^ "m4"    <-> 0b010,
  sep() ^ "m8"    <-> 0b011
}

mapping maybe_ta_flag : string <-> bits(1) = {
  ""           <-> 0b0, /* tu by default */
  sep() ^ "ta" <-> 0b1,
  sep() ^ "tu" <-> 0b0
}

mapping maybe_ma_flag : string <-> bits(1) = {
  ""           <-> 0b0, /* mu by default */
  sep() ^ "ma" <-> 0b1,
  sep() ^ "mu" <-> 0b0
}

union clause ast = VSET_TYPE : (vsetop, bits(1), bits(1), bits(3), bits(3), bits(5), regidx) /*bits(5) may be a regidx*/

/**vsetvli&vsetvl**/
mapping encdec_vsetop : vsetop <-> bits (4) ={
  VSETVLI <-> 0b0000,
  VSETVL <-> 0b1000
}

mapping clause encdec = VSET_TYPE(op, ma, ta, sew, lmul, rs1, rd)  
  <-> encdec_vsetop(op) @ ma @ ta @ sew @ lmul @rs1 @ 0b111 @ rd @ 0b1010111 /*vsetvl may be a little different*/

function clause execute VSET_TYPE(op, ma, ta, sew, lmul, rs1, rd) = {
  AVL : int = undefined;
  VLMAX : int = undefined;
  SEW_new : int = undefined;
  LMUL_new : real = undefined;

  let LMUL_ori : real = get_vtype_LMUL();
  let SEW_ori : int = get_vtype_vsew();
  //print_int("SEW_ori=",SEW_ori);
  let ratio_ori : real = to_real(SEW_ori) / LMUL_ori;
  
  /****** vsetvli part *******/
  if (op == VSETVLI) then{
    let vtype_reserved = zeros(sizeof(xlen) - 9);
    let vtype_val : xlenbits = 0b0 @ vtype_reserved @ ma @ ta @ sew @ lmul;
    writeCSR(csr_name_map("vtype"), vtype_val);
    let LMUL_new : real = get_vtype_LMUL();
    let SEW_new : int = get_vtype_vsew();
    //print_int("SEW_NEW=",SEW_new);
    VLMAX = floor (LMUL_new * to_real(sizeof(vlen)) / to_real (SEW_new)) /* VLMAX=LUML*VLEN/SEW */
    //print_int("VLMAX=",VLMAX);
    /* vtype->vma()   = ma;
    vtype->vta()   = ta;
    vtype->vsew()  = sew;
    vtype->vlmul() = lmul; */
  };

  /****** vsetvl part *******/
  if (op == VSETVL) then {
    let sew_append_lmul : bits(6) = (sail_zero_extend(sew, 6) << 3) | (sail_zero_extend(lmul, 6));
    let rs2 : regidx = slice (sew_append_lmul, 0 , 5);
    let rs2_val = X(rs2);
    writeCSR(csr_name_map("vtype"), rs2_val);
    let LMUL_new : real = get_vtype_LMUL();
    let SEW_new : int = get_vtype_vsew();
    VLMAX = floor (LMUL_new * to_real(sizeof(vlen)) / to_real (SEW_new)) /* VLMAX=LUML*VLEN/SEW */
    //print_int("VLMAX=",VLMAX);
  };

  if (rs1 != 0b00000) then{
    let rs1_val = X(rs1);
    AVL = unsigned(rs1_val);
    //print_int("rs1=zero,AVL=",AVL);
      /*writeCSR(csr_name_map("vl"), rs1_val);*/
    X(rd) = rs1_val
  }

  else if (rd != 0b00000) then {
    AVL = 0;/*the maximum unsigned integer value (~0) is used as the AVL, I'm not sure*/
    /* writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), VLMAX));*/
    X(rd) = to_bits(sizeof(xlen), VLMAX)
  }

  else {
    let ratio_new : real = to_real(SEW_new) / LMUL_new;
    if (ratio_new != ratio_ori) then {
        writeCSR(csr_name_map("vtype"), 0b1 @ zeros(sizeof(xlen) - 1))
    }
    else 
        { AVL = unsigned (readCSR(csr_name_map("vl"))) }
  };

  if (AVL <= VLMAX) then {
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), AVL))
  };

  /* if ((AVL < 2 * VLMAX) & ((unsigned (readCSR(csr_name_map("vl"))) > VLMAX) | (unsigned (readCSR(csr_name_map("vl"))) < ceil(AVL / 2)) )) then
  handle_illegal () ;*/

  if (AVL >= 2 * VLMAX) then {
    print("AVL >= 2 * VLMAX");
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), VLMAX));
  };

  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  RETIRE_SUCCESS
}

mapping vsettype_mnemonic : vsetop <-> string ={
  VSETVLI <-> "vsetvli",
  VSETVL <-> "vsetvli"
}

mapping clause assembly = VSET_TYPE(op, ma, ta, sew, lmul, rs1, rd) 
  <-> vsettype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)

/* ************VSETI_TYPE(1)*************** */
/**vsetivli**/
union clause ast = VSETI_TYPE : ( bits(1), bits(1), bits(3), bits(3), bits(5), regidx) /*bits(5) may be a regidx*/

mapping clause encdec = VSETI_TYPE(ma, ta, sew, lmul, uimm, rd)  
  <-> 0b1100 @ ma @ ta @ sew @ lmul @uimm @ 0b111 @ rd @ 0b1010111 /*vsetvl may be a little different*/

function clause execute VSETI_TYPE(ma, ta, sew, lmul, uimm, rd) = {
  AVL : int = undefined;
  VLMAX : int = undefined; 

  let LMUL_ori : real = get_vtype_LMUL();
  let SEW_ori : int = get_vtype_vsew();
  //print_int("SEW_ori=",SEW_ori);
  let ratio_ori : real = to_real(SEW_ori) / LMUL_ori;
 
  let vtype_reserved = zeros(sizeof(xlen) - 9);
  let vtype_val : xlenbits = 0b0 @ vtype_reserved @ ma @ ta @ sew @ lmul;
  /* vtype->vma()   = ma;
  vtype->vta()   = ta;
  vtype->vsew()  = sew;
  vtype->vlmul() = lmul; */
  //print("vtype_val=" ^ BitStr(vtype_val));
  //print("ma,ta,sew,lmul=" ^ BitStr(ma) ^ BitStr(ta) ^ BitStr(sew) ^ BitStr(lmul));
  writeCSR(csr_name_map("vtype"), vtype_val);
  let LMUL_new : real = get_vtype_LMUL();
  let SEW_new : int = get_vtype_vsew();
  //print_int("SEW_NEW=",SEW_new);
  VLMAX = floor (LMUL_new * to_real(sizeof(vlen)) / to_real (SEW_new)); /* VLMAX=LUML*VLEN/SEW */
  //print_int("VLMAX=",VLMAX);
  
  /****** vsetivli part *******/
  AVL = unsigned(sail_zero_extend(uimm,sizeof(xlen))); /*AVL is encoded as 5-bit zero-extended imm in the rs1 field */
  //print_int("AVL=",AVL);
  X(rd) = to_bits(sizeof(xlen), AVL); /* ??? */

  if (AVL <= VLMAX) then {
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), AVL))
  };

  /* if ((AVL < 2 * VLMAX) & ((unsigned (readCSR(csr_name_map("vl"))) > VLMAX) | (unsigned (readCSR(csr_name_map("vl"))) < ceil(AVL / 2)) )) then
  handle_illegal () ;*/

  if (AVL >= 2 * VLMAX) then {
    print("AVL >= 2 * VLMAX");
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), VLMAX));
  };

  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  RETIRE_SUCCESS
}

mapping clause assembly = VSETI_TYPE(ma, ta, sew, lmul, uimm, rd) 
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)

/* ****************************************************************** */

val write_single_element : forall 'm 'x, 8 <= 'm <= 128. (int('m), int('x), real, regidx, bits('m)) -> unit  effect {escape, rreg, wreg}
function write_single_element(elem_width_bits, index, emul, vrid, value) = {
  real_vrid : regidx = vrid;
  real_index : int = index;
  let elem_per_reg : int = sizeof(vlen) / elem_width_bits;
  let 'elem_per_reg = elem_per_reg;
  if emul > 1.0 then {
    real_vrid = vrid + to_bits(5, floor(to_real(index) / to_real(elem_per_reg)));
    real_index = index % elem_per_reg;
  };
  let vrid_val : vector('elem_per_reg, dec, bits('m)) = read_single_vreg(elem_per_reg, elem_width_bits, real_vrid);
  r : vregtype = zeros(sizeof(vreglen));
  foreach (i from (elem_per_reg - 1) downto 0) {
    r = r << elem_width_bits;
    if i == real_index then {
      r = r | sail_zero_extend(value, length(r));
    }else {
      r = r | sail_zero_extend(vrid_val[i], length(r));
    }
  };
  V(real_vrid) = r;
}

mapping nfields_int : bits(3) <-> int = {
  0b000     <-> 1,
  0b001     <-> 2,
  0b010     <-> 3,
  0b011     <-> 4,
  0b100     <-> 5,
  0b101     <-> 6,
  0b110     <-> 7,
  0b111     <-> 8
}

mapping nfields_string : bits(3) <-> string = {
  0b000     <-> "1",
  0b001     <-> "2",
  0b010     <-> "3",
  0b011     <-> "4",
  0b100     <-> "5",
  0b101     <-> "6",
  0b110     <-> "7",
  0b111     <-> "8"
}

mapping vlewidth_bitsnumberstr : vlewidth <-> string = {
  VLE8      <-> "8",
  VLE16     <-> "16",
  VLE32     <-> "32",
  VLE64     <-> "64"
}

mapping encdec_vlewidth : vlewidth <-> bits(3) = {
  VLE8      <-> 0b000,
  VLE16     <-> 0b101,
  VLE32     <-> 0b110,
  VLE64     <-> 0b111
}

mapping vlewidth_bytesnumber : vlewidth <-> int = {
  VLE8      <-> 1,
  VLE16     <-> 2,
  VLE32     <-> 4,
  VLE64     <-> 8
}

mapping bytes_wordwidth : int <-> word_width = {
  1 <-> BYTE,
  2 <-> HALF,
  4 <-> WORD,
  8 <-> DOUBLE
}

/* Vector misaligned checking (used in vload) */
val vcheck_misaligned : (xlenbits, word_width) -> bool effect {undef}
function vcheck_misaligned(vaddr : xlenbits, width : word_width) -> bool = {
  if   plat_enable_misaligned_access() then false
  else match width {
         BYTE      => false,
         HALF      => vaddr[0] == bitone,
         WORD      => vaddr[0] == bitone | vaddr[1] == bitone,
         DOUBLE    => vaddr[0] == bitone | vaddr[1] == bitone | vaddr[2] == bitone
       };
}

/* *****VLOAD**************VLETYPE(Vector Load Unit-Strided Normal, nf=0, mop=0, lumop=0)*************************** */
union clause ast = VLETYPE : (bits(1), regidx, vlewidth, regidx)

mapping clause encdec = VLETYPE(vm, rs1, width, vd)
  <-> 0b000 @ 0b0 @ 0b00 @ vm @ 0b00000 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111
  /* nf mew mop vm lumop rs1 width vd */

val process_vle : forall 'b 'n, (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vle (vm, vd, load_width_bytes, rs1, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  //let start_element : int = get_start_element();
  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vd);
  total : vector('n, dec, bits('b * 8)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;
  status : Retired  = RETIRE_SUCCESS;

  (total, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vd_val, vm_val);
  
  foreach (i from 0 to (num_elem - 1)) {
    //print("lala");
    if mask_helper[i] == true then{
      let elem_offset = i * load_width_bytes ; // int
      //print_int("elem_offset=",elem_offset);
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL; print("fail0") },
        Ext_DataAddr_OK(vaddr)  => 
          if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
            { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL; print("fail1") }
          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL; print("fail2"); print("vaddr="^BitStr(vaddr)) },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                MemValue(result) => {
                    //print("ok");
		                total[i] = result; 
                  },
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL; print("fail3") }
              }
            }
          }
      }
    }
  };
  
  if status == RETIRE_SUCCESS then write_vreg(num_elem, load_width_bytes * 8, emul, vd, total);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

function clause execute(VLETYPE(vm, rs1, width, vd)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vle(vm, vd, load_width_bytes, rs1,  emul, num_elem)
}

mapping vletype_mnemonic : vlewidth <-> string = {
  VLE8        <-> "vle8.v",
  VLE16       <-> "vle16.v",
  VLE32       <-> "vle32.v",
  VLE64       <-> "vle64.v"
}

mapping clause assembly = VLETYPE(vm, rs1, width, vd)
  <-> vletype_mnemonic(width) ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ maybe_vmask(vm)


/* *****VSTORE**************VSETYPE(Vector Store Unit-Strided Normal, nf=0, mop=0, sumop=0)*************************** */

union clause ast = VSETYPE : (bits(1), regidx, vlewidth, regidx)

mapping clause encdec = VSETYPE(vm, rs1, width, vs3)
  <-> 0b000 @ 0b0 @ 0b00 @ vm @ 0b00000 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111
  /* nf mew mop vm lumop rs1 width vs3 */

val process_vse : forall 'b 'n, (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vse (vm, vs3, load_width_bytes, rs1, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  //let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs3_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vs3);
  total : vector('n, dec, bits('b * 8)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;
  status : Retired  = RETIRE_SUCCESS;

  (total, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vs3_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    let elem_offset = i * load_width_bytes;
    if mask_helper[i] == true then {
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
          if   vcheck_misaligned(vaddr, width_type)
          then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Write(Data)) {
            TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              let eares : MemoryOpResult(unit) = mem_write_ea(paddr, load_width_bytes, false, false, false);
              match (eares) {
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                MemValue(_) => {
                  let res : MemoryOpResult(bool) = mem_write_value(paddr, load_width_bytes, vs3_val[i], false, false, false);
                  match (res) {
                    MemValue(true)  => status = RETIRE_SUCCESS,
                    MemValue(false) => internal_error("store got false from mem_write_value"),
                    MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                  }
                }
              }
            }
          }
      }
    }
  };
  
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

function clause execute(VSETYPE(vm, rs1, width, vs3)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vse(vm, vs3, load_width_bytes, rs1, emul, num_elem)
}

mapping vsetype_mnemonic : vlewidth <-> string = {
  VLE8        <-> "vse8.v",
  VLE16       <-> "vse16.v",
  VLE32       <-> "vse32.v",
  VLE64       <-> "vse64.v"
}

mapping clause assembly = VSETYPE(vm, rs1, width, vs3)
  <-> vsetype_mnemonic(width) ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ maybe_vmask(vm)


/* ****VLOAD************VLSETYPE(Vector Load Strided Normal, nf=0, mop=10)*************************** */

union clause ast = VLSETYPE : (bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VLSETYPE(vm, rs2, rs1, width, vd)
  <-> 0b000 @ 0b0 @ 0b10 @ vm @ rs2 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

val process_vlse : forall 'b 'n, (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('b), regidx, regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vlse (vm, vd, load_width_bytes, rs1, rs2, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  //let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vd);
  let rs2_val : int = signed(get_scalar(rs2, sizeof(xlen)));
  total : vector('n, dec, bits('b * 8)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;
  status : Retired = RETIRE_SUCCESS;

  (total, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    let elem_offset = i * rs2_val;
    if mask_helper[i] == true then {
      //print("true");
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL /*; print("fail0"）*/},
        Ext_DataAddr_OK(vaddr)  => 
          if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
            { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL /*; print("fail1")*/ }
          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL/*; print("fail2")*/ },
            TR_Address(paddr, _) => {
              //print("paddr1="^BitStr(paddr));
              match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                MemValue(result) => {
		                total[i] = result; 
                    //print("result="^BitStr(result));
                    //print("paddr2="^BitStr(paddr));
                    //print("vaddr="^BitStr(vaddr));
                  },
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL /*; print("fail3")*/ }
              }
           }
          }
      }
    }
  };
  
  if status== RETIRE_SUCCESS then write_vreg(num_elem, load_width_bytes * 8, emul, vd, total);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

function clause execute(VLSETYPE(vm, rs2, rs1, width, vd)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  //print_int("veew_bits=",veew_bits );
  let vsew_bits : int = get_vtype_vsew();
  //print_int("vsew_bits=",vsew_bits );
  let lmul : real = get_vtype_LMUL();
  //print_real("lmul=",lmul );
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  //print_real("emul=",emul );
  let num_elem : int  = get_num_elem(emul, veew_bits);
  //print_int("num_elem=",num_elem  );

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vlse(vm, vd, load_width_bytes, rs1, rs2, emul, num_elem)
}

mapping vlsetype_mnemonic : vlewidth <-> string = {
  VLE8        <-> "vlse8.v",
  VLE16       <-> "vlse16.v",
  VLE32       <-> "vlse32.v",
  VLE64       <-> "vlse64.v"
}

mapping clause assembly = VLSETYPE(vm, rs2, rs1, width, vd)
  <-> vlsetype_mnemonic(width) ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)^ sep() ^ maybe_vmask(vm)


/* *****VSTORE**************VSSETYPE(Vector Store Strided Normal, nf=0, mop=10)*************************** */

union clause ast = VSSETYPE : (bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VSSETYPE(vm, rs2, rs1, width, vs3)
  <-> 0b000 @ 0b0 @ 0b10 @ vm @ rs2 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111
  /* nf mew mop vm lumop rs1 width vs3 */

val process_vsse : forall 'b 'n, (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('b), regidx, regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vsse (vm, vs3, load_width_bytes, rs1, rs2, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  //let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs3_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vs3);
  let rs2_val : int = signed(get_scalar(rs2, sizeof(xlen)));
  total : vector('n, dec, bits('b * 8)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;
  status : Retired  = RETIRE_SUCCESS;
  
  (total, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vs3_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    let elem_offset = i * rs2_val;
    if mask_helper[i] == true then {
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
          if   vcheck_misaligned(vaddr, width_type)
          then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Write(Data)) {
            TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              let eares : MemoryOpResult(unit) = mem_write_ea(paddr, load_width_bytes, false, false, false);
              match (eares) {
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                MemValue(_) => {
                  let res : MemoryOpResult(bool) = mem_write_value(paddr, load_width_bytes, vs3_val[i], false, false, false);
                  match (res) {
                    MemValue(true)  => status = RETIRE_SUCCESS,
                    MemValue(false) => internal_error("store got false from mem_write_value"),
                    MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                  }
                }
              }
            }
          }
      }
    }
  };
  
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

function clause execute(VSSETYPE(vm, rs2, rs1, width, vs3)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vsse(vm, vs3, load_width_bytes, rs1, rs2, emul, num_elem)
}

mapping vssetype_mnemonic : vlewidth <-> string = {
  VLE8        <-> "vsse8.v",
  VLE16       <-> "vsse16.v",
  VLE32       <-> "vsse32.v",
  VLE64       <-> "vsse64.v"
}

mapping clause assembly = VSSETYPE(vm, rs2, rs1, width, vs3)
  <-> vssetype_mnemonic(width) ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)^ sep() ^ maybe_vmask(vm)


/* *****VLOAD**************VLUXEITYPE(Vector Load Indexed Unordered, nf=0, mop=01)*************************** */

union clause ast = VLUXEITYPE : (bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VLUXEITYPE(vm, vs2, rs1, width, vd)
  <-> 0b000 @ 0b0 @ 0b01 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

val process_vlxei : forall 'ib 'db 'n, (0 < 'ib & 'ib <= 8) & (0 < 'db & 'db <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('ib), int('db), regidx, regidx, int('n), int) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vlxei (vm, vd, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, mop) = {
  let index_eew_bits : int = index_eew_bytes * 8;
  let data_eew_bits = data_eew_bytes * 8;
  let data_emul : real = get_vtype_LMUL();
  let index_emul : real = (to_real( index_eew_bits / data_eew_bits )) * data_emul;
  assert (8 <= data_eew_bits & data_eew_bits <= 64);

  let width_type : word_width = bytes_wordwidth(data_eew_bytes);
  let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val : vector('n, dec, bits('db * 8)) = read_vreg(num_elem, data_eew_bytes * 8, data_emul, vd);
  let vs2_val : vector('n, dec, bits('ib * 8)) = read_vreg(num_elem, index_eew_bytes * 8, index_emul, vs2);
  total : vector('n, dec, bits('db * 8)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (total, mask_helper) = init_masked_result(num_elem, data_eew_bytes * 8, data_emul, vd_val, vm_val);
  status : Retired  = RETIRE_SUCCESS;

  /* Currently mop = 1(unordered) or 3(ordered) do the same operations */
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let elem_offset = signed(vs2_val[i]);
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr)  => 
          if vcheck_misaligned(vaddr, width_type) then
            { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, data_eew_bytes, false, false, false) {
                MemValue(result) => {
                    total[i] = result; 
                  },
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
              }
           }
          }
      }
    }
  };
  
  if status == RETIRE_SUCCESS then write_vreg(num_elem, data_eew_bits, data_emul, vd, total);
  status
}

function clause execute(VLUXEITYPE(vm, vs2, rs1, width, vd)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vlxei(vm, vd, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 1)
}

mapping clause assembly = VLUXEITYPE(vm, vs2, rs1, width, vd)
  <-> "vluxei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* *****VLOAD**************VLOXEITYPE(Vector Load Indexed Ordered, nf=0, mop=11)*************************** */

union clause ast = VLOXEITYPE : (bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VLOXEITYPE(vm, vs2, rs1, width, vd)
  <-> 0b000 @ 0b0 @ 0b11 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

function clause execute(VLOXEITYPE(vm, vs2, rs1, width, vd)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vlxei(vm, vd, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 3)
}

mapping clause assembly = VLOXEITYPE(vm, vs2, rs1, width, vd)
  <-> "vloxei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* *****VSTORE**************VSUXEITYPE(Vector Store Indexed Unordered, nf=0, mop=01)*************************** */

union clause ast = VSUXEITYPE : (bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VSUXEITYPE(vm, vs2, rs1, width, vs3)
  <-> 0b000 @ 0b0 @ 0b01 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111

val process_vsxei : forall 'ib 'db 'n, (0 < 'ib & 'ib <= 8) & (0 < 'db & 'db <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('ib), int('db), regidx, regidx, int('n), int) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vsxei (vm, vs3, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, mop) = {
  let index_eew_bits : int = index_eew_bytes * 8;
  let data_eew_bits = data_eew_bytes * 8;
  let data_emul : real = get_vtype_LMUL();
  let index_emul : real = (to_real( index_eew_bits / data_eew_bits )) * data_emul;
  assert (8 <= data_eew_bits & data_eew_bits <= 64);

  let width_type : word_width = bytes_wordwidth(data_eew_bytes);
  let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs3_val : vector('n, dec, bits('db * 8)) = read_vreg(num_elem, data_eew_bytes * 8, data_emul, vs3);
  let vs2_val : vector('n, dec, bits('ib * 8)) = read_vreg(num_elem, index_eew_bytes * 8, index_emul, vs2);
  total : vector('n, dec, bits('db * 8)) = undefined; /* just used to generate mask_helper */
  mask_helper : vector('n, dec, bool)     = undefined;
  (total, mask_helper) = init_masked_result(num_elem, data_eew_bytes * 8, data_emul, vs3_val, vm_val);
  status : Retired  = RETIRE_SUCCESS;
  /* Currently mop = 1(unordered) or 3(ordered) do the same operations */
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let elem_offset = signed(vs2_val[i]);
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr) =>
            if   vcheck_misaligned(vaddr, width_type)
            then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Write(Data)) {
              TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                let eares : MemoryOpResult(unit) = mem_write_ea(paddr, data_eew_bytes, false, false, false);
                match (eares) {
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                  MemValue(_) => {
                    let res : MemoryOpResult(bool) = mem_write_value(paddr, data_eew_bytes, vs3_val[i], false, false, false);
                    match (res) {
                      MemValue(true)  => status = RETIRE_SUCCESS,
                      MemValue(false) => internal_error("store got false from mem_write_value"),
                      MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                    }
                  }
                }
              }
            }
        }
    }
  };
  
  status
}

function clause execute(VSUXEITYPE(vm, vs2, rs1, width, vs3)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vsxei(vm, vs3, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 1)
}

mapping clause assembly = VSUXEITYPE(vm, vs2, rs1, width, vs3)
  <-> "vsuxei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* *****VSTORE**************VSOXEITYPE(Vector Store Indexed Ordered, nf=0, mop=11)*************************** */

union clause ast = VSOXEITYPE : (bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VSOXEITYPE(vm, vs2, rs1, width, vs3)
  <-> 0b000 @ 0b0 @ 0b11 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111

function clause execute(VSOXEITYPE(vm, vs2, rs1, width, vs3)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vsxei(vm, vs3, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 3)
}

mapping clause assembly = VSOXEITYPE(vm, vs2, rs1, width, vs3)
  <-> "vsoxei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* *****VLOAD**************VLEFFTYPE(Vector Load Unit-Strided Fault-Only-First, nf=0, mop=0, lumop=10000)*************************** */

union clause ast = VLEFFTYPE : (bits(1), regidx, vlewidth, regidx)

mapping clause encdec = VLEFFTYPE(vm, rs1, width, vd)
  <-> 0b000 @ 0b0 @ 0b00 @ vm @ 0b10000 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111
  /* nf mew mop vm lumop rs1 width vd */

val process_vleff : forall 'b 'n, (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vleff (vm, vd, load_width_bytes, rs1, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  //let start_element : int = get_start_element();
  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vd);
  total : vector('n, dec, bits('b * 8)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;
  status : Retired  = RETIRE_SUCCESS;

  foreach (i from 0 to (num_elem - 1)) {
    (total, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vd_val, vm_val);
    if mask_helper[i] == true then {
      let elem_offset = i * load_width_bytes ; // int
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => {
          if i == 0 then {
            ext_handle_data_check_error(e);
            status = RETIRE_SUCCESS
            }
          else {
            writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), i));
            ext_handle_data_check_error(e);
            status = RETIRE_SUCCESS
            }
        },
        Ext_DataAddr_OK(vaddr)  => {
          if vcheck_misaligned(vaddr, width_type) then {
            if i == 0 then {
              handle_mem_exception(vaddr, E_Load_Addr_Align());
              status = RETIRE_SUCCESS
            }
            else {
              writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), i));
              handle_mem_exception(vaddr, E_Load_Addr_Align());
              status = RETIRE_SUCCESS
            }
          }

          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { 
              if i == 0 then {
                handle_mem_exception(vaddr, e);
                status = RETIRE_SUCCESS
              }
              else {
                writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), i));
                handle_mem_exception(vaddr, e);
                status = RETIRE_SUCCESS
              }
            },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                MemValue(result) => {
		                total[i] = result; 
                  },
                MemException(e) => {
                  if i == 0 then {
                    handle_mem_exception(vaddr, e);
                    status = RETIRE_SUCCESS
                  }
                  else {
                    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), i));
                    handle_mem_exception(vaddr, e);
                    status = RETIRE_SUCCESS
                  }
                }
              }
            }
          }
        }
      }
    }
  };
  
  if status == RETIRE_SUCCESS then write_vreg(num_elem, load_width_bytes * 8, emul, vd, total);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

function clause execute(VLEFFTYPE(vm, rs1, width, vd)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  process_vle(vm, vd, load_width_bytes, rs1,  emul, num_elem)
}

mapping vlefftype_mnemonic : vlewidth <-> string = {
  VLE8        <-> "vle8ff.v",
  VLE16       <-> "vle16ff.v",
  VLE32       <-> "vle32ff.v",
  VLE64       <-> "vle64ff.v"
}

mapping clause assembly = VLEFFTYPE(vm, rs1, width, vd)
  <-> vlefftype_mnemonic(width) ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ maybe_vmask(vm)


/* ****VLOAD***********VLSEGTYPE(Vector Load Unit-Strided Segments, mop=0, lumop=00000)*************************** */

union clause ast = VLSEGTYPE : (bits(3), bits(1), regidx, vlewidth, regidx)

mapping clause encdec = VLSEGTYPE(nf, vm, rs1, width, vd)
  <-> nf @ 0b0 @ 0b00 @ vm @ 0b00000 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

val process_vlseg : forall 'f 'b 'n, (0 < 'f & 'f <= 8) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen)  . (int('f), bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vlseg (nf, vm, vd, load_width_bytes, rs1, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  //let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  //let num_ele_per_register : int = ceil ( to_real(num_elem) / emul );
  status : Retired  = RETIRE_SUCCESS;
  vd_a = vd;
  vd_t = vd;
  //print_int("nf_int=",nf);
  //print("vd="^BitStr(vd));

  foreach(a from 0 to (nf - 1)) {
    //print_int("nftemp=", a);
    //print_real("emul=", emul);
    //print("vd_t="^BitStr(vd_t));
    if vd_t == vd_a & a != 0 then vd_t = vd_t + 1; // emul < 1
    let vd_t_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vd_t);
    total : vector('n, dec, bits('b * 8)) = undefined;
    mask_helper : vector('n, dec, bool) = undefined;
    (total, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vd_t_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if (mask_helper[i] == true) then {
        let elem_offset = load_width_bytes * (a + i * nf); //int
        //print_int("elem_offset=", elem_offset);
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL; print("fail0") },
          Ext_DataAddr_OK(vaddr)  => 
              if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
                { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL; print("fail1") }
              else match translateAddr(vaddr, Read(Data)) {
                TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL; print("fail2") },
                TR_Address(paddr, _) => {
                  match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                    MemValue(result) => {
                        total[i] = result;
                        ii = i + 1;
                    },
                    MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL; print("fail3") }
                  }
                }
              }
        }
      }
    };

    if status == RETIRE_SUCCESS then write_vreg(num_elem, load_width_bytes * 8, emul, vd_t, total);
    vd_a = vd_t;
    vd_t = vd_t + to_bits(5, ceil(emul))
  };
  
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  status
}

function clause execute(VLSEGTYPE(nf, vm, rs1, width, vd)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  //print_int("veew_bits=",veew_bits );
  let vsew_bits : int = get_vtype_vsew();
  //print_int("vsew_bits=",vsew_bits );
  let lmul : real = get_vtype_LMUL();
  //print_real("lmul=",lmul );
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  //print_real("emul=",emul );
  let num_elem : int  = get_num_elem(emul, veew_bits);// # of element of each register group
  //print_int("num_elem=",num_elem  );//16
  let nf_int = nfields_int(nf);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vlseg(nf_int, vm, vd, load_width_bytes, rs1, emul, num_elem);
}

mapping clause assembly = VLSEGTYPE(nf, vm, rs1, width, vd)
  <-> "vlseg" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ sep() ^ maybe_vmask(vm)


/* ****VLOAD*****VLSEGFFTYPE(Vector Load Unit-Strided Segments Fault-Only-First, mop=0, lumop=00000)******** */

union clause ast = VLSEGFFTYPE : (bits(3), bits(1), regidx, vlewidth, regidx)

mapping clause encdec = VLSEGFFTYPE(nf, vm, rs1, width, vd)
  <-> nf @ 0b0 @ 0b00 @ vm @ 0b00000 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

val process_vlsegff : forall 'f 'b 'n, (0 < 'f & 'f <= 8) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vlsegff (nf, vm, vd, load_width_bytes, rs1, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  status : Retired  = RETIRE_SUCCESS;
  if start_element >= num_elem then return status;

  loop_times : int = num_elem - 1;
  foreach (i from start_element to loop_times) {
    assert( i >= 0 & i < num_elem );
    if (vm_val[i] == true) then {
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = (i * nf + j) * load_width_bytes;
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
          Ext_DataAddr_Error(e)  => { if i == 0 then ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr)  => 
            if vcheck_misaligned(vaddr, width_type) then 
              { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Read(Data)) {
              TR_Failure(e, _) => { if i == 0 then handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                  MemValue(result) => {
                      write_single_element(load_width_bytes * 8, i, emul, vd + to_bits(5, j * ceil(emul)) , result);
                    },
                  MemException(e) => { if i == 0 then handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                }
              }
            }
        }
      };
      if status == RETIRE_FAIL then loop_times = i;
    }
  };
  status
}

function clause execute(VLSEGFFTYPE(nf, vm, rs1, width, vd)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);
  let nf_int = nfields_int(nf);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vlsegff(nf_int, vm, vd, load_width_bytes, rs1, emul, num_elem);
}

mapping clause assembly = VLSEGTYPE(nf, vm, rs1, width, vd)
  <-> "vlseg" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ "ff.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ maybe_vmask(vm)


/* ****VSTORE***********VSSEGTYPE(Vector Store Unit-Strided Segments, mop=0, sumop=00000)*************************** */

union clause ast = VSSEGTYPE : (bits(3), bits(1), regidx, vlewidth, regidx)

mapping clause encdec = VSSEGTYPE(nf, vm, rs1, width, vs3)
  <-> nf @ 0b0 @ 0b00 @ vm @ 0b00000 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111

val process_vsseg : forall 'f 'b 'n, (0 < 'f & 'f <= 8) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vsseg (nf, vm, vs3, load_width_bytes, rs1, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  status : Retired  = RETIRE_SUCCESS;
  if start_element >= num_elem then return status;
  assert(start_element >= 0);
  foreach (i from start_element to (num_elem - 1)) {
    if vm_val[i] == true then {
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = (i * nf + j) * load_width_bytes;
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr) =>
            if   vcheck_misaligned(vaddr, width_type)
            then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Write(Data)) {
              TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                let eares : MemoryOpResult(unit) = mem_write_ea(paddr, load_width_bytes, false, false, false);
                match (eares) {
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                  MemValue(_) => {
                    let one_elem_val : bits('b * 8) = read_single_element(load_width_bytes * 8, i, emul, vs3 + to_bits(5, j * ceil(emul)));
                    let res : MemoryOpResult(bool) = mem_write_value(paddr, load_width_bytes, one_elem_val, false, false, false);
                    match (res) {
                      MemValue(true)  => status = RETIRE_SUCCESS,
                      MemValue(false) => internal_error("store got false from mem_write_value"),
                      MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                    }
                  }
                }
              }
            }
        }
      };
    }
  };
  
  status
}

function clause execute(VSSEGTYPE(nf, vm, rs1, width, vs3)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);
  let nf_int = nfields_int(nf);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vsseg(nf_int, vm, vs3, load_width_bytes, rs1, emul, num_elem)
}

mapping clause assembly = VSSEGTYPE(nf, vm, rs1, width, vs3)
  <-> "vsseg" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ maybe_vmask(vm)


/* ****VLOAD***********VLSSEGTYPE(Vector Load Strided Segments, mop=10)*************************** */

union clause ast = VLSSEGTYPE : (bits(3), bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VLSSEGTYPE(nf, vm, rs2, rs1, width, vd)
  <-> nf @ 0b0 @ 0b10 @ vm @ rs2 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

val process_vlsseg : forall 'f 'b 'n, (0 < 'f & 'f <= 8) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('b), regidx, regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vlsseg (nf, vm, vd, load_width_bytes, rs1, rs2, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vd); // only to generate mask_helper
  result      : vector('n, dec, bits('b * 8)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vd_val, vm_val);

  let rs2_val : int = signed(get_scalar(rs2, sizeof(xlen)));
  status : Retired  = RETIRE_SUCCESS;
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = i * rs2_val + j * load_width_bytes;
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr)  => 
            if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
              { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Read(Data)) {
              TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                  MemValue(result) => {
                      write_single_element(load_width_bytes * 8, i, emul, vd + to_bits(5, j * ceil(emul)) , result);
                    },
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                }
              }
            }
        }
      }
    }
  };
  status
}

function clause execute(VLSSEGTYPE(nf, vm, rs2, rs1, width, vd)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);
  let nf_int = nfields_int(nf);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vlsseg(nf_int, vm, vd, load_width_bytes, rs1, rs2, emul, num_elem);
}

mapping clause assembly = VLSSEGTYPE(nf, vm, rs2, rs1, width, vd)
  <-> "vlsseg" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ maybe_vmask(vm)


/* ****VSTORE***********VSSSEGTYPE(Vector Store Strided Segments, mop=0, sumop=00000)*************************** */

union clause ast = VSSSEGTYPE : (bits(3), bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VSSSEGTYPE(nf, vm, rs2, rs1, width, vs3)
  <-> nf @ 0b0 @ 0b10 @ vm @ rs2 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111

val process_vssseg : forall 'f 'b 'n, (0 < 'f & 'f <= 8) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('b), regidx, regidx, real, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vssseg (nf, vm, vs3, load_width_bytes, rs1, rs2, emul, num_elem) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs3_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vs3); // only to generate mask_helper
  result      : vector('n, dec, bits('b * 8)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vs3_val, vm_val);
  let rs2_val : int = signed(get_scalar(rs2, sizeof(xlen)));
  status : Retired  = RETIRE_SUCCESS;
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = i * rs2_val + j * load_width_bytes;
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr) =>
            if   vcheck_misaligned(vaddr, width_type)
            then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Write(Data)) {
              TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                let eares : MemoryOpResult(unit) = mem_write_ea(paddr, load_width_bytes, false, false, false);
                match (eares) {
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                  MemValue(_) => {
                    let one_elem_val : bits('b * 8) = read_single_element(load_width_bytes * 8, i, emul, vs3 + to_bits(5, j * ceil(emul)));
                    let res : MemoryOpResult(bool) = mem_write_value(paddr, load_width_bytes, one_elem_val, false, false, false);
                    match (res) {
                      MemValue(true)  => status = RETIRE_SUCCESS,
                      MemValue(false) => internal_error("store got false from mem_write_value"),
                      MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                    }
                  }
                }
              }
            }
        }
      };
    }
  };
  
  status
}

function clause execute(VSSSEGTYPE(nf, vm, rs2, rs1, width, vs3)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);
  let nf_int = nfields_int(nf);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vssseg(nf_int, vm, vs3, load_width_bytes, rs1, rs2, emul, num_elem)
}

mapping clause assembly = VSSSEGTYPE(nf, vm, rs2, rs1, width, vs3)
  <-> "vssseg" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ maybe_vmask(vm)


/* ****VLOAD***********VLUXSEGTYPE(Vector Load Indexed Unordered Segments, mop=01)*************************** */

union clause ast = VLUXSEGTYPE : (bits(3), bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VLUXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> nf @ 0b0 @ 0b01 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

val process_vlxseg : forall 'f 'ib 'db 'n, (0 < 'f & 'f <= 8) & (0 < 'ib & 'ib <= 8) & (0 < 'db & 'db <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('ib), int('db), regidx, regidx, int('n), int) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vlxseg (nf, vm, vd, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, mop) = {
  let index_eew_bits : int = index_eew_bytes * 8;
  let data_eew_bits = data_eew_bytes * 8;
  let data_emul : real = get_vtype_LMUL();
  let index_emul : real = (to_real( index_eew_bits / data_eew_bits )) * data_emul;
  assert (8 <= data_eew_bits & data_eew_bits <= 64);

  let width_type : word_width = bytes_wordwidth(data_eew_bytes);
  let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val : vector('n, dec, bits('db * 8)) = read_vreg(num_elem, data_eew_bytes * 8, data_emul, vd);
  let vs2_val : vector('n, dec, bits('ib * 8)) = read_vreg(num_elem, index_eew_bytes * 8, index_emul, vs2);
  total : vector('n, dec, bits('db * 8)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (total, mask_helper) = init_masked_result(num_elem, data_eew_bytes * 8, data_emul, vd_val, vm_val);
  status : Retired  = RETIRE_SUCCESS;

  /* Currently mop = 1(unordered) or 3(ordered) do the same operations */
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      foreach (j from 0 to (nf - 1)) {
        let elem_offset : int = signed(vs2_val[i]) + j * data_eew_bytes;
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr)  => 
            if vcheck_misaligned(vaddr, width_type) then
              { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Read(Data)) {
              TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                match mem_read(Read(Data), paddr, data_eew_bytes, false, false, false) {
                  MemValue(result) => {
                      write_single_element(data_eew_bits, i, data_emul, vd + to_bits(5, j * ceil(data_emul)) , result);
                    },
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                }
            }
            }
        }
      }
    }
  };
  
  status
}

function clause execute(VLUXSEGTYPE(nf, vm, vs2, rs1, width, vd)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/
  let nf_int = nfields_int(nf);

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vlxseg(nf_int, vm, vd, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 1);
}

mapping clause assembly = VLUXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> "vluxseg" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* ****VLOAD***********VLOXSEGTYPE(Vector Load Indexed Unordered Segments, mop=11)*************************** */

union clause ast = VLOXSEGTYPE : (bits(3), bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VLOXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> nf @ 0b0 @ 0b11 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

function clause execute(VLOXSEGTYPE(nf, vm, vs2, rs1, width, vd)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/
  let nf_int = nfields_int(nf);

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vlxseg(nf_int, vm, vd, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 3);
}

mapping clause assembly = VLOXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> "vloxseg" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* ****VSTORE***********VSUXSEGTYPE(Vector Store Indexed Unordered Segments, mop=01)*************************** */

union clause ast = VSUXSEGTYPE : (bits(3), bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VSUXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> nf @ 0b0 @ 0b01 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111

val process_vsxseg : forall 'f 'ib 'db 'n, (0 < 'f & 'f <= 8) & (0 < 'ib & 'ib <= 8) & (0 < 'db & 'db <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('ib), int('db), regidx, regidx, int('n), int) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vsxseg (nf, vm, vs3, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, mop) = {
  let index_eew_bits : int = index_eew_bytes * 8;
  let data_eew_bits = data_eew_bytes * 8;
  let data_emul : real = get_vtype_LMUL();
  let index_emul : real = (to_real( index_eew_bits / data_eew_bits )) * data_emul;
  assert (8 <= data_eew_bits & data_eew_bits <= 64);

  let width_type : word_width = bytes_wordwidth(data_eew_bytes);
  let start_element : int = get_start_element();
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs3_val : vector('n, dec, bits('db * 8)) = read_vreg(num_elem, data_eew_bytes * 8, data_emul, vs3);
  let vs2_val : vector('n, dec, bits('ib * 8)) = read_vreg(num_elem, index_eew_bytes * 8, index_emul, vs2);
  total : vector('n, dec, bits('db * 8)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (total, mask_helper) = init_masked_result(num_elem, data_eew_bytes * 8, data_emul, vs3_val, vm_val);
  status : Retired  = RETIRE_SUCCESS;

  /* Currently mop = 1(unordered) or 3(ordered) do the same operations */
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      foreach (j from 0 to (nf - 1)) {
        let elem_offset : int = signed(vs2_val[i]) + j * data_eew_bytes;
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr) =>
            if   vcheck_misaligned(vaddr, width_type)
            then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Write(Data)) {
              TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                let eares : MemoryOpResult(unit) = mem_write_ea(paddr, data_eew_bytes, false, false, false);
                match (eares) {
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                  MemValue(_) => {
                    let one_elem_val : bits('db * 8) = read_single_element(data_eew_bits, i, data_emul, vs3 + to_bits(5, j * ceil(data_emul)));
                    let res : MemoryOpResult(bool) = mem_write_value(paddr, data_eew_bytes, one_elem_val, false, false, false);
                    match (res) {
                      MemValue(true)  => status = RETIRE_SUCCESS,
                      MemValue(false) => internal_error("store got false from mem_write_value"),
                      MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                    }
                  }
                }
              }
            }
        }
      }
    }
  };
  
  status
}

function clause execute(VSUXSEGTYPE(nf, vm, vs2, rs1, width, vs3)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/
  let nf_int = nfields_int(nf);

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vsxseg(nf_int, vm, vs3, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 1);
}
mapping clause assembly = VSUXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> "vsuxseg" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* ****VSTORE***********VSOXSEGTYPE(Vector Store Indexed Ordered Segments, mop=11)*************************** */

union clause ast = VSOXSEGTYPE : (bits(3), bits(1), regidx, regidx, vlewidth, regidx)

mapping clause encdec = VSOXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> nf @ 0b0 @ 0b11 @ vm @ vs2 @ rs1 @ encdec_vlewidth(width) @ vs3 @ 0b0100111

function clause execute(VSOXSEGTYPE(nf, vm, vs2, rs1, width, vs3)) = {
  let index_eew_bytes  : int = vlewidth_bytesnumber(width);
  let data_eew_bits : int = get_vtype_vsew();
  let data_eew_bytes : int = data_eew_bits / 8;
  let data_emul : real = get_vtype_LMUL();
  let num_elem : int  = get_num_elem(data_emul, data_eew_bits); /* number of data and indeces are the same*/
  let nf_int = nfields_int(nf);

  assert ( (0 < index_eew_bytes) & (index_eew_bytes <= 8) );
  assert ( (0 < data_eew_bytes) & (data_eew_bytes <= 8) );
  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );
  assert ((0 < '_nf_int & '_nf_int <= 8));

  process_vsxseg(nf_int, vm, vs3, index_eew_bytes, data_eew_bytes, rs1, vs2, num_elem, 3);
}
mapping clause assembly = VSUXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> "vsuoseg" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* ****VLOAD***************VLRETYPE(Vector Load Unit-Steided Whole Register, vm=1, mop=0, lumop=01000)*************************** */

union clause ast = VLRETYPE : (bits(3), regidx, vlewidth, regidx)

mapping clause encdec = VLRETYPE(nf, rs1, width, vd)
  <-> nf @ 0b0 @ 0b00 @ 0b1 @ 0b01000 @ rs1 @ encdec_vlewidth(width) @ vd @ 0b0000111

val process_vlre : forall 'f 'b 'n, ('f in {1, 2, 4, 8}) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), regidx, int('b), regidx, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vlre (nf, vd, load_width_bytes, rs1, elem_per_reg) = {
  let width_type : word_width = bytes_wordwidth(load_width_bytes);
  status : Retired  = RETIRE_SUCCESS;
  start_element : int = get_start_element();
  if start_element >= nf * elem_per_reg then {
    /* no elements are written */
    return status;
  };
  cur_field : int = start_element / elem_per_reg;
  elem_to_align : int = start_element % elem_per_reg;

  if elem_to_align > 0 then {
    foreach (i from elem_to_align to (elem_per_reg - 1)) {
      let elem_offset : int = start_element * load_width_bytes;
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr)  => 
          if vcheck_misaligned(vaddr, width_type) then
            { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                MemValue(result) => {
                    write_single_element(load_width_bytes * 8, i, to_real(1), vd + to_bits(5, cur_field) , result);
                  },
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
              }
            }
          }
      };
      start_element = start_element + 1;
    };
    cur_field = cur_field + 1;
  };
  total : vector('n, dec, bits('b * 8)) = undefined;
  foreach (j from cur_field to (nf - 1)) {
    total = undefined;
    foreach (i from 0 to (elem_per_reg - 1)) {
      let elem_offset = start_element * load_width_bytes;
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr)  => 
          if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
            { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                MemValue(result) => {
                    total[i] = result; 
                  },
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
              }
            }
          }
      };
      start_element = start_element + 1;
    };

    if status == RETIRE_SUCCESS then write_vreg(elem_per_reg, load_width_bytes * 8, to_real(1), vd + to_bits(5, j), total); /*emul=1*/
  };
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}


function clause execute(VLRETYPE(nf, rs1, width, vd)) = {
  let load_width_bytes  : int = vlewidth_bytesnumber(width);
  let veew_bits : int = load_width_bytes * 8;
  let elem_per_reg : int  = sizeof(vlen) / veew_bits;
  let nf_int = nfields_int(nf);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= elem_per_reg) & (elem_per_reg <= sizeof(vlen)) );
  assert( (nf_int == 1) | (nf_int == 2) | (nf_int == 4) | (nf_int == 8) );

  process_vlre(nf_int, vd, load_width_bytes, rs1, elem_per_reg)
}

mapping clause assembly = VLRETYPE(nf, rs1, width, vd)
  <-> "vl" ^ nfields_string(nf) ^ "re" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)


/* ****VSTORE***************VSRETYPE(Vector Store Unit-Strided Whole Register, vm=1, mop=0, lumop=01000)*************************** */

union clause ast = VSRETYPE : (bits(3), regidx, regidx)

mapping clause encdec = VSRETYPE(nf, rs1, vs3)
  <-> nf @ 0b0 @ 0b00 @ 0b1 @ 0b01000 @ rs1 @ 0b000 @ vs3 @ 0b0000111

val process_vsre : forall 'f 'b 'n, ('f in {1, 2, 4, 8}) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), int('b), regidx, regidx, int('n)) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vsre (nf, load_width_bytes, rs1, vs3, elem_per_reg) = {
  let width_type : word_width = BYTE;
  start_element : int = get_start_element();
  status : Retired  = RETIRE_SUCCESS;
  if start_element >= nf * elem_per_reg then {
    /* no elements are written */
    return status;
  };
  cur_field : int = start_element / elem_per_reg;
  elem_to_align : int = start_element % elem_per_reg;

  if elem_to_align > 0 then {
    foreach (i from elem_to_align to (elem_per_reg - 1)) {
      let elem_offset : int = start_element * load_width_bytes;
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
          if   vcheck_misaligned(vaddr, width_type)
          then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Write(Data)) {
            TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              let eares : MemoryOpResult(unit) = mem_write_ea(paddr, load_width_bytes, false, false, false);
              match (eares) {
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                MemValue(_) => {
                  let one_elem_val : bits('b * 8) = read_single_element(load_width_bytes * 8, i, to_real(1), vs3 + to_bits(5, cur_field));
                  let res : MemoryOpResult(bool) = mem_write_value(paddr, load_width_bytes, one_elem_val, false, false, false);
                  match (res) {
                    MemValue(true)  => status = RETIRE_SUCCESS,
                    MemValue(false) => internal_error("store got false from mem_write_value"),
                    MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                  }
                }
              }
            }
          }
      };
      start_element = start_element + 1;
    };
    cur_field = cur_field + 1;
  };

  foreach (j from cur_field to (nf - 1)) {
    let vs_val : vector('n, dec, bits('b * 8)) = read_vreg(elem_per_reg, load_width_bytes * 8, to_real(1), vs3 + to_bits(5, j));
    foreach (i from 0 to (elem_per_reg - 1)) {
      let elem_offset = start_element * load_width_bytes;
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr) =>
          if   vcheck_misaligned(vaddr, width_type)
          then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Write(Data)) {
            TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              let eares : MemoryOpResult(unit) = mem_write_ea(paddr, load_width_bytes, false, false, false);
              match (eares) {
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                MemValue(_) => {
                  let res : MemoryOpResult(bool) = mem_write_value(paddr, load_width_bytes, vs_val[i], false, false, false);
                  match (res) {
                    MemValue(true)  => status = RETIRE_SUCCESS,
                    MemValue(false) => internal_error("store got false from mem_write_value"),
                    MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                  }
                }
              }
            }
          }
      };
      start_element = start_element + 1;
    };
  };
  status
}

function clause execute(VSRETYPE(nf, rs1, vs3)) = {
  let load_width_bytes  : int = 1;
  let veew_bits : int = 8;
  let elem_per_reg : int  = sizeof(vlen) / veew_bits;
  let nf_int = nfields_int(nf);

  assert ( (0 < load_width_bytes) & (load_width_bytes <= 8) );
  assert ( (0 <= elem_per_reg) & (elem_per_reg <= sizeof(vlen)) );
  assert( (nf_int == 1) | (nf_int == 2) | (nf_int == 4) | (nf_int == 8) );

  process_vsre(nf_int, load_width_bytes, rs1, vs3, elem_per_reg)
}

mapping clause assembly = VSRETYPE(nf, rs1, vs3)
  <-> "vs" ^ nfields_string(nf) ^ "r.v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ reg_name(rs1)


/* *****VLOAD&VSTORE**************VMTYPE(Vector MASK Load&STORE Unit-Strided Normal, nf=0, mop=0, lumop=0)*************************** */

union clause ast = VMTYPE : (regidx, regidx, vmlsop)

mapping encdec_lsop : vmlsop <-> bits(7) = {
  VLM      <-> 0b0000111,
  VSM      <-> 0b0100111
}

mapping clause encdec = VMTYPE(rs1, vd_or_vs3, op)
  <-> 0b000 @ 0b0 @ 0b00 @ 0b1 @ 0b01011 @ rs1 @ 0b000 @ vd_or_vs3 @ encdec_lsop(op)
  /* nf mew op unmask umop rs1 width vd_or_vs3 */

val process_vm : forall 'n, (0 <= 'n & 'n <= vlen) . (regidx, regidx, real, int('n), vmlsop) -> Retired effect {escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
function process_vm(vd_or_vs3, rs1, emul, num_elem, op) = {
  let width_type : word_width = BYTE;
  let start_element : int = get_start_element();
  let vd_or_vs3_val : vector('n, dec, bits(8)) = read_vreg(num_elem, 8, emul, vd_or_vs3);
  total : vector('n, dec, bits(8)) = undefined;
  elem_offset : int = undefined;
  status : Retired  = RETIRE_SUCCESS;
  
  foreach (i from 0 to (num_elem - 1)) {
    let elem_offset = i ;                     // int
    if op == VLM  then {                // load
      if i < start_element then {
        total[i] = vd_or_vs3_val[i]
      }
      else {
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr)  => 
            if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
              { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Read(Data)) {
              TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                match mem_read(Read(Data), paddr, 1, false, false, false) {
                  MemValue(result) => {
                      if i < num_elem then total[i] = result; 
                    },
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                }
            }
            }
        }
      };
      if status == RETIRE_SUCCESS then write_vreg(num_elem, 8, emul, vd_or_vs3, total);
    }

    else if op == VSM then {       //store
      if i > start_element  then {
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Write(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr) =>
            if   vcheck_misaligned(vaddr, width_type)
            then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); status = RETIRE_FAIL }
            else match translateAddr(vaddr, Write(Data)) {
              TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
              TR_Address(paddr, _) => {
                let eares : MemoryOpResult(unit) = mem_write_ea(paddr, 1, false, false, false);
                match (eares) {
                  MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                  MemValue(_) => {
                    let res : MemoryOpResult(bool) = mem_write_value(paddr, 1, vd_or_vs3_val[i], false, false, false);
                    match (res) {
                      MemValue(true)  => status = RETIRE_SUCCESS,
                      MemValue(false) => internal_error("store got false from mem_write_value"),
                      MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
                    }
                  }
                }
              }
            }
        }
      }
    } 

  };
  
  status
}

function clause execute(VMTYPE(rs1, vd_or_vs3, op)) = {
  let veew_bits : int = 8;
  let vsew_bits : int = get_vtype_vsew();
  let emul : real = 1.0;
  let tmp : int = unsigned(readCSR(csr_name_map("vl")));
  let num_elem : int = ceil( to_real(tmp) / 8.0);

  assert ( (0 <= num_elem) & (num_elem <= sizeof(vlen)) );

  /* unmask vle8 except that the effective vector length is evl=ceil(vl/8) */
  process_vm(vd_or_vs3, rs1, emul, num_elem, op); 

}

mapping vmtype_mnemonic : vmlsop <-> string = {
  VLM      <-> "vlm.v",
  VSM      <-> "vsm.v"
}

mapping clause assembly = VMTYPE(rs1, vd_or_vs3, op)
  <-> vmtype_mnemonic(op) ^ spc() ^ vreg_name(vd_or_vs3) ^ sep() ^ reg_name(rs1)



/* **************************OPIVV(VVTYPE)**************************************** */

union clause ast = VVTYPE : (vvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vvfunct6 : vvfunct6 <-> bits(6) = {
  VV_VADD          <-> 0b000000,
  VV_VSUB          <-> 0b000010,
  VV_VMINU         <-> 0b000100,
  VV_VMIN          <-> 0b000101,
  VV_VMAXU         <-> 0b000110,
  VV_VMAX          <-> 0b000111,
  VV_VAND          <-> 0b001001,
  VV_VOR           <-> 0b001010,
  VV_VXOR          <-> 0b001011,
  VV_VRGATHER      <-> 0b001100,
  VV_VRGATHEREI16  <-> 0b001110,
  VV_VSADDU        <-> 0b100000,
  VV_VSADD         <-> 0b100001,
  VV_VSSUBU        <-> 0b100010,
  VV_VSSUB         <-> 0b100011,  
  VV_VSLL          <-> 0b100101,
  VV_VSMUL         <-> 0b100111,
  VV_VSRL          <-> 0b101000,
  VV_VSRA          <-> 0b101001,
  VV_VSSRL         <-> 0b101010,
  VV_VSSRA         <-> 0b101011
}

mapping clause encdec = VVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_vvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /* |
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined | 
     | mask_helper == undefined */ 
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      //print("vs1_val[i]=" ^ BitStr(vs1_val[i]));
      //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VV_VADD         => vs2_val[i] + vs1_val[i],
          VV_VSUB         => vs2_val[i] - vs1_val[i],
          VV_VAND         => vs2_val[i] & vs1_val[i],
          VV_VOR          => vs2_val[i] | vs1_val[i],
          VV_VXOR         => vs2_val[i] ^ vs1_val[i],
          VV_VSADDU       => unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, vs1_val[i]) ),
          VV_VSADD        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, vs1_val[i]) ),
          VV_VSSUBU       => {
                               if unsigned(vs2_val[i]) < unsigned(vs1_val[i]) then zeros()
                               else unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, vs1_val[i]) )
                             },
          VV_VSSUB        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, vs1_val[i]) ),
          VV_VSMUL        => {
                               result_mul = to_bits('m * 2, signed(vs2_val[i]) * signed(vs1_val[i]));
                               rounding_incr = get_fixed_rounding_incr(result_mul, 'm - 1);
                               result_wide = (result_mul >> ('m - 1)) + EXTZ('m * 2, rounding_incr);
                               signed_saturation('m, result_wide['m..0])
                             },
          VV_VSLL         => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] << shift_amount
                             },
          VV_VSRL         => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] >> shift_amount
                             },
          VV_VSRA         => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits)
                             },
          VV_VSSRL        => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               (vs2_val[i] >> shift_amount) + EXTZ('m, rounding_incr)
                             },
          VV_VSSRA        => {
                               let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits) + EXTZ('m, rounding_incr)
                             },
          VV_VMINU        => to_bits(vsew_bits, min(unsigned(vs2_val[i]), unsigned(vs1_val[i]))),
          VV_VMIN         => to_bits(vsew_bits, min(signed(vs2_val[i]), signed(vs1_val[i]))),
          VV_VMAXU        => to_bits(vsew_bits, max(unsigned(vs2_val[i]), unsigned(vs1_val[i]))),
          VV_VMAX         => to_bits(vsew_bits, max(signed(vs2_val[i]), signed(vs1_val[i]))),
          VV_VRGATHER     => {
                               assert(vs1 != vd & vs2 != vd);
                               let idx = unsigned(vs1_val[i]);
                               vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                               if idx < vlmax then {
                                 assert(idx < 'n); 
                                 vs2_val[idx]
                               } else zeros() 
                             },
          VV_VRGATHEREI16 => {
                               assert(vs1 != vd & vs2 != vd);
                               /* vrgatherei16.vv uses SEW/LMUL for the data in vs2 but EEW=16 and EMUL = (16/SEW)*LMUL for the indices in vs1 */
                               let vs1_new : vector('n, dec, bits(16)) = read_vreg(num_elem, 16, (lmul * 16.0 / to_real(vsew_bits)), vs1);
                               let idx = unsigned(vs1_new[i]);
                               vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                               if idx < vlmax then {
                                 assert(idx < 'n); 
                                 vs2_val[idx]
                               } else zeros()                   
                             }
        };
        //print_int("mask_helper_true", i);
        //print("result[i]=" ^ BitStr(result[i]))
      }
    };
    
    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0))
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvtype_mnemonic : vvfunct6 <-> string = {
  VV_VADD          <-> "vadd.vv",
  VV_VSUB          <-> "vsub.vv",
  VV_VAND          <-> "vand.vv",
  VV_VOR           <-> "vor.vv",
  VV_VXOR          <-> "vxor.vv",
  VV_VRGATHER      <-> "vrgather.vv",
  VV_VRGATHEREI16  <-> "vrgatherei16.vv",
  VV_VSADDU        <-> "vsaddu.vv",
  VV_VSADD         <-> "vsadd.vv",
  VV_VSSUBU        <-> "vssubu.vv",
  VV_VSSUB         <-> "vssub.vv",
  VV_VSLL          <-> "vsll.vv",
  VV_VSMUL         <-> "vsmul.vv",
  VV_VSRL          <-> "vsrl.vv",
  VV_VSRA          <-> "vsra.vv",
  VV_VSSRL         <-> "vssrl.vv",
  VV_VSSRA         <-> "vssra.vv",
  VV_VMINU         <-> "vminu.vv",
  VV_VMIN          <-> "vmin.vv",
  VV_VMAXU         <-> "vmaxu.vv",
  VV_VMAX          <-> "vmax.vv"
}

mapping clause assembly = VVTYPE(funct6, vm, vs2, vs1, vd)
  <-> vvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************OPIVV(VVTYPE) Reduction**************************************** */

union clause ast = RIVVTYPE : (rivvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rivvfunct6 : rivvfunct6 <-> bits(6) = {
  IVV_VWREDSUMU   <-> 0b110000,
  IVV_VWREDSUM    <-> 0b110001
}

mapping clause encdec = RIVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_rivvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

val process_rivv : forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rivvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rivv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  let 'double_vsew = double_vsew;
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  assert ( 8 <= 'double_vsew & 'double_vsew <= 64 );
  let vd_val   : vector('n, dec, bits('double_vsew)) = read_vreg(num_elem, double_vsew, double_lmul, vd); // only to generate mask_helper
  result       : vector('n, dec, bits('double_vsew))     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);

  vs1_0 : bits('double_vsew) = read_single_element(double_vsew, 0, double_lmul, vs1);
  sum_elems : bits('double_vsew) = match funct6 {
    IVV_VWREDSUMU  => to_bits(double_vsew, unsigned(vs1_0)),
    IVV_VWREDSUM   => to_bits(double_vsew, signed(vs1_0))
  };
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      sum_elems = match funct6 {
        IVV_VWREDSUMU  => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(sum_elems)),
        IVV_VWREDSUM   => to_bits(double_vsew, signed(vs2_val[i]) + signed(sum_elems))
      };
    }
  };
  
  write_single_element(double_vsew, 0, double_lmul, vd, sum_elems);
  RETIRE_SUCCESS
}

function clause execute(RIVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  process_rivv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
}

mapping rivvtype_mnemonic : rivvfunct6 <-> string = {
  IVV_VWREDSUMU  <-> "vwredsumu.vs",
  IVV_VWREDSUM   <-> "vwredsum.vs"
}

mapping clause assembly = RIVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rivvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************OPIVV(VVTYPE)Widened**************************************** */

union clause ast = WVVTYPE : (wvvfunct6, bits(1), regidx, regidx, regidx)
mapping encdec_wvvfunct6 : wvvfunct6 <-> bits(6) = {
  WVV_VADD       <-> 0b110001,
  WVV_VSUB       <-> 0b110011,
  WVV_VADDU      <-> 0b110000,
  WVV_VSUBU      <-> 0b110010,
  WVV_VWMUL      <-> 0b111011,
  WVV_VWMULU     <-> 0b111000,
  WVV_VWMULSU    <-> 0b111010
}

mapping clause encdec = WVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_wvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(WVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;
  assert(8 <= double_vsew & double_vsew <= 64);

  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd);
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  result : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if vm_val == undefined  
  then {
    status = RETIRE_FAIL;
    //print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    //assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print_int("vs1=", signed(vs1_val[i]));
        //print_int("vs1=", signed(vs2_val[i]));
        result[i] = match funct6 {
          WVV_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(vs1_val[i])),
          WVV_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(vs1_val[i])),
          WVV_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(vs1_val[i])),
          WVV_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(vs1_val[i])),
          WVV_VWMUL        => to_bits(double_vsew, signed(vs2_val[i]) * signed(vs1_val[i])),
          WVV_VWMULU       => to_bits(double_vsew, unsigned(vs2_val[i]) * unsigned(vs1_val[i])),
          WVV_VWMULSU      => to_bits(double_vsew, signed(vs2_val[i]) * unsigned(vs1_val[i]))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0))
  };
  
  status = vcheck_vsew_lmul(double_vsew, double_lmul);
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wvvtype_mnemonic : wvvfunct6 <-> string = {
  WVV_VADD       <-> "vwadd.vv",
  WVV_VSUB       <-> "vwsub.vv",
  WVV_VADDU      <-> "vwaddu.vv",
  WVV_VSUBU      <-> "vwsubu.vv",
  WVV_VWMUL      <-> "vwmul.vv",
  WVV_VWMULU     <-> "vwmulu.vv",
  WVV_VWMULSU    <-> "vwmulsu.vv"
}

mapping clause assembly = WVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> wvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************WVTYPE**************************************** */

union clause ast = WVTYPE : (wvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wvfunct6 : wvfunct6 <-> bits(6) = {
  WV_VADD       <-> 0b110101,
  WV_VSUB       <-> 0b110111,
  WV_VADDU      <-> 0b110100,
  WV_VSUBU      <-> 0b110110
}

mapping clause encdec = WVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_wvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(WVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs1_val     : vector('n, dec, bits('m)) = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('o)) = undefined;
  result      : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs1_val = read_vreg(num_elem, vsew_bits, lmul, vs1);
    vs2_val = read_vreg(num_elem, double_vsew, double_lmul, vs2);
    vd_val  = read_vreg(num_elem, double_vsew, double_lmul, vd)
  };

  if vm_val      == undefined /*|
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          WV_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(vs1_val[i])),
          WV_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(vs1_val[i])),
          WV_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(vs1_val[i])),
          WV_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(vs1_val[i]))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wvtype_mnemonic : wvfunct6 <-> string = {
  WV_VADD       <-> "vwadd.wv",
  WV_VSUB       <-> "vwsub.wv",
  WV_VADDU      <-> "vwaddu.wv",
  WV_VSUBU      <-> "vwsubu.wv"
}

mapping clause assembly = WVTYPE(funct6, vm, vs2, vs1, vd)
  <-> wvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************NVSTYPE(Narrowing)**************************************** */

union clause ast = NVSTYPE : (nvsfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nvsfunct6 : nvsfunct6 <-> bits(6) = {
  NVS_VNSRL       <-> 0b101100,
  NVS_VNSRA       <-> 0b101101
}

mapping clause encdec = NVSTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_nvsfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(NVSTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs1_val     : vector('n, dec, bits('m)) = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if (double_vsew > sizeof(elen) | double_lmul > 8.0) then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs1_val = read_vreg(num_elem, vsew_bits, lmul, vs1);
    vs2_val = read_vreg(num_elem, double_vsew, double_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          NVS_VNSRL    => {
                           let shift_amount = get_shift_amount(vs1_val[i], double_vsew);
                           assert(shift_amount >= 0);
                           slice(vs2_val[i] >> shift_amount, 0, vsew_bits)
                         },
          NVS_VNSRA    => {
                           let shift_amount = get_shift_amount(vs1_val[i], double_vsew);
                           assert(shift_amount >= 0);
                           let v_double : bits('o * 2) = EXTS(vs2_val[i]);
                           let arith_shifted : bits('o) = slice(v_double >> shift_amount, 0, double_vsew);
                           slice(arith_shifted, 0, vsew_bits)
                         }
        }
      }
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping nvstype_mnemonic : nvsfunct6 <-> string = {
  NVS_VNSRL       <-> "vnsrl.wv",
  NVS_VNSRA       <-> "vnsra.wv"
}

mapping clause assembly = NVSTYPE(funct6, vm, vs2, vs1, vd)
  <-> nvstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* **************************NVTYPE(Narrowing)**************************************** */

union clause ast = NVTYPE : (nvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nvfunct6 : nvfunct6 <-> bits(6) = {
  NV_VNCLIPU     <-> 0b101110,
  NV_VNCLIP      <-> 0b101111
}

mapping clause encdec = NVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_nvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(NVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let shift_amount = get_shift_amount(vs1_val[i], vsew_bits);
      assert(shift_amount >= 0);
      let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
      result[i] = match funct6 {
        NV_VNCLIPU  => {                    
                         result_wide = (vs2_val[i] >> shift_amount) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         unsigned_saturation('m, result_wide);
                       },
        NV_VNCLIP   => {          
                         assert(('m * 4) >= 'o);
                         let v_double : bits('m * 4) = sail_sign_extend(vs2_val[i], 'm * 4);
                         result_wide = slice(v_double >> shift_amount, 0, 'o) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         signed_saturation('m, result_wide);
                       }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);

  RETIRE_SUCCESS
}

mapping nvtype_mnemonic : nvfunct6 <-> string = {
  NV_VNCLIPU     <-> "vnclipu.wv",
  NV_VNCLIP      <-> "vnclip.wv"
}

mapping clause assembly = NVTYPE(funct6, vm, vs2, vs1, vd)
  <-> nvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

  
/* **************************VEXT2**************************************** */

union clause ast = VEXT2TYPE : (vext2funct6, bits(1), regidx, regidx)

mapping vext2_vs1 : vext2funct6 <-> bits(5) = {
  VEXT2_ZVF2  <-> 0b00110,
  VEXT2_SVF2  <-> 0b00111
}

mapping clause encdec = VEXT2TYPE(funct6, vm, vs2, vd)
  <-> 0b010010 @ vm @ vs2 @ vext2_vs1(funct6) @ 0b010 @ vd @ 0b1010111

function clause execute(VEXT2TYPE(funct6, vm, vs2, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);
  let half_vsew  : int  = vsew_bits / 2;
  let half_lmul  : real = lmul / 2.0;

  //assert(16 <= vsew_bits & vsew_bits <= 64);
  //assert(8 <= half_vsew & half_vsew <= 32);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = half_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(half_vsew, half_lmul);

  if status == RETIRE_SUCCESS then {
    assert(8 <= half_vsew & half_vsew <= 64);
    assert(half_vsew < vsew_bits);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, half_vsew, half_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(8 <= half_vsew & half_vsew <= 64);
    assert(half_vsew < vsew_bits);
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VEXT2_ZVF2  => sail_zero_extend(vs2_val[i], vsew_bits),
          VEXT2_SVF2  => sail_sign_extend(vs2_val[i], vsew_bits)
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vext2type_mnemonic : vext2funct6 <-> string = {
  VEXT2_ZVF2  <-> "vzext.vf2",
  VEXT2_SVF2  <-> "vsext.vf2"
}

mapping clause assembly = VEXT2TYPE(funct6, vm, vs2, vd)
  <-> vext2type_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VEXT4**************************************** */

union clause ast = VEXT4TYPE : (vext4funct6, bits(1), regidx, regidx)

mapping vext4_vs1 : vext4funct6 <-> bits(5) = {
  VEXT4_ZVF4  <-> 0b00100,
  VEXT4_SVF4  <-> 0b00101
}

mapping clause encdec = VEXT4TYPE(funct6, vm, vs2, vd)
  <-> 0b010010 @ vm @ vs2 @ vext4_vs1(funct6) @ 0b010 @ vd @ 0b1010111

function clause execute(VEXT4TYPE(funct6, vm, vs2, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);
  let quart_vsew : int  = vsew_bits / 4;
  let quart_lmul : real = lmul / 4.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = quart_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(quart_vsew, quart_lmul);

  if status == RETIRE_SUCCESS then {
    assert(8 <= quart_vsew & quart_vsew <= 64);
    assert(quart_vsew < vsew_bits);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, quart_vsew, quart_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(8 <= quart_vsew & quart_vsew <= 64);
    assert(quart_vsew < vsew_bits);
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VEXT4_ZVF4  => sail_zero_extend(vs2_val[i], vsew_bits),
          VEXT4_SVF4  => sail_sign_extend(vs2_val[i], vsew_bits)
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vext4type_mnemonic : vext4funct6 <-> string = {
  VEXT4_ZVF4  <-> "vzext.vf4",
  VEXT4_SVF4  <-> "vsext.vf4"
}

mapping clause assembly = VEXT4TYPE(funct6, vm, vs2, vd)
  <-> vext4type_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VEXT8**************************************** */

union clause ast = VEXT8TYPE : (vext8funct6, bits(1), regidx, regidx)

mapping vext8_vs1 : vext8funct6 <-> bits(5) = {
  VEXT8_ZVF8  <-> 0b00010,
  VEXT8_SVF8  <-> 0b00011
}

mapping clause encdec = VEXT8TYPE(funct6, vm, vs2, vd)
  <-> 0b010010 @ vm @ vs2 @ vext8_vs1(funct6) @ 0b010 @ vd @ 0b1010111

function clause execute(VEXT8TYPE(funct6, vm, vs2, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let eighth_vsew : int  = vsew_bits / 8;
  let eighth_lmul : real = lmul / 8.0;

  //assert(vsew_bits <= 64);
  //assert(eighth_vsew <= 8);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = eighth_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('m)) = undefined;
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(eighth_vsew, eighth_lmul);

  if status == RETIRE_SUCCESS then {
    assert(8 <= eighth_vsew & eighth_vsew <= 64);
    assert(eighth_vsew <= vsew_bits);
    assert(8 <= 'o );
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, eighth_vsew, eighth_lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(8 <= eighth_vsew & eighth_vsew <= 64);
    assert(eighth_vsew <= vsew_bits);
    assert(8 <= 'o );
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VEXT8_ZVF8  => sail_zero_extend(vs2_val[i], vsew_bits),
          VEXT8_SVF8  => sail_sign_extend(vs2_val[i], vsew_bits)
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vext8type_mnemonic : vext8funct6 <-> string = {
  VEXT8_ZVF8  <-> "vzext.vf8",
  VEXT8_SVF8  <-> "vsext.vf8"
}

mapping clause assembly = VEXT8TYPE(funct6, vm, vs2, vd)
  <-> vext8type_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VVMTYPE**************************************** */
/* VVM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VVMTYPE : (vvmfunct6, regidx, regidx, regidx)

mapping encdec_vvmfunct6 : vvmfunct6 <-> bits(6) = {
  VVM_VMADC    <-> 0b010001, /* Carry in, carry out */
  VVM_VMSBC    <-> 0b010011
}

mapping clause encdec = VVMTYPE(funct6, vs2, vs1, vd)
  <-> encdec_vvmfunct6(funct6) @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVMTYPE(funct6, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
  let vs1_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vm_val      == undefined |
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VVM_VMADC    => if unsigned(vs2_val[i]) + unsigned(vs1_val[i]) + unsigned(bool_to_bits(vm_val[i])) > 2 ^ vsew_bits - 1 then true else false,
          VVM_VMSBC    => if unsigned(vs2_val[i]) - unsigned(vs1_val[i]) - unsigned(bool_to_bits(vm_val[i])) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvmtype_mnemonic : vvmfunct6 <-> string = {
  VVM_VMADC    <-> "vmadc.vvm", /* Carry in, carry out */
  VVM_VMSBC    <-> "vmsbc.vvm"
}

mapping clause assembly = VVMTYPE(funct6, vs2, vs1, vd)
  <-> vvmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0"


/* **************************VVMCTYPE**************************************** */
/* VVMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VVMCTYPE : (vvmcfunct6, regidx, regidx, regidx)

mapping encdec_vvmcfunct6 : vvmcfunct6 <-> bits(6) = {
  VVMC_VMADC    <-> 0b010001, /* Carry in, carry out */
  VVMC_VMSBC    <-> 0b010011
}

mapping clause encdec = VVMCTYPE(funct6, vs2, vs1, vd)
  <-> encdec_vvmcfunct6(funct6) @ 0b1 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVMCTYPE(funct6, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs1_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VVMC_VMADC    => if unsigned(vs2_val[i]) + unsigned(vs1_val[i]) > 2 ^ vsew_bits - 1 then true else false,
          VVMC_VMSBC    => if unsigned(vs2_val[i]) - unsigned(vs1_val[i]) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvmctype_mnemonic : vvmcfunct6 <-> string = {
  VVMC_VMADC    <-> "vmadc.vv", /* No carry in, carry out */
  VVMC_VMSBC    <-> "vmsbc.vv"
}

mapping clause assembly = VVMCTYPE(funct6, vs2, vs1, vd)
  <-> vvmctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)


/* **************************VVMSTYPE**************************************** */
/* VVMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VVMSTYPE : (vvmsfunct6, regidx, regidx, regidx)

mapping encdec_vvmsfunct6 : vvmsfunct6 <-> bits(6) = {
  VVMS_VADC     <-> 0b010000, /* Carry in, no carry out */
  VVMS_VSBC     <-> 0b010010
}

mapping clause encdec = VVMSTYPE(funct6, vs2, vs1, vd)
  <-> encdec_vvmsfunct6(funct6) @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVMSTYPE(funct6, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  vm_val       : vector('n, dec, bool)     = undefined;
  vs1_val      : vector('n, dec, bits('m)) = undefined;
  vs2_val      : vector('n, dec, bits('m)) = undefined;
  vd_val       : vector('n, dec, bits('m)) = undefined;
  result       : vector('n, dec, bits('m)) = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /* For bypassing vm masking in init_masked_result */
  all_trues : vector('n, dec, bool) = undefined;
  foreach (i from 0 to (num_elem - 1)) {
    all_trues[i] = true
  };

  if vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    vm_val  = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
    vs1_val = read_vreg(num_elem, vsew_bits, lmul, vs1);
    vs2_val = read_vreg(num_elem, vsew_bits, lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  /*if vm_val      == undefined |
     vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, all_trues);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VVMS_VADC     => to_bits(vsew_bits, signed(vs2_val[i]) + signed(vs1_val[i]) + signed(bool_to_bits(vm_val[i]))),
          VVMS_VSBC     => to_bits(vsew_bits, signed(vs2_val[i]) - signed(vs1_val[i]) - signed(bool_to_bits(vm_val[i])))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vvmstype_mnemonic : vvmsfunct6 <-> string = {
  VVMS_VADC     <-> "vadc.vvm", /* Carry in, no carry out */
  VVMS_VSBC     <-> "vsbc.vvm"
}

mapping clause assembly = VVMSTYPE(funct6, vs2, vs1, vd)
  <-> vvmstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0"


/* **************************VVCMPTYPE**************************************** */
/* VVCMP instructions' destination is a mask register */

union clause ast = VVCMPTYPE : (vvcmpfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vvcmpfunct6 : vvcmpfunct6 <-> bits(6) = {
  VVCMP_VMSEQ    <-> 0b011000,
  VVCMP_VMSNE    <-> 0b011001,
  VVCMP_VMSLTU   <-> 0b011010,
  VVCMP_VMSLT    <-> 0b011011,
  VVCMP_VMSLEU   <-> 0b011100,
  VVCMP_VMSLE    <-> 0b011101
}

mapping clause encdec = VVCMPTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_vvcmpfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(VVCMPTYPE(funct6, vm, vs2, vs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VVCMP_VMSEQ    => if vs2_val[i] == vs1_val[i] then true else false,
          VVCMP_VMSNE    => if vs2_val[i] != vs1_val[i] then true else false,
          VVCMP_VMSLTU   => if unsigned(vs2_val[i]) < unsigned(vs1_val[i]) then true else false,
          VVCMP_VMSLT    => if signed(vs2_val[i]) < signed(vs1_val[i]) then true else false,
          VVCMP_VMSLEU   => if unsigned(vs2_val[i]) <= unsigned(vs1_val[i]) then true else false,
          VVCMP_VMSLE    => if signed(vs2_val[i]) <= signed(vs1_val[i]) then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

mapping vvcmptype_mnemonic : vvcmpfunct6 <-> string = {
  VVCMP_VMSEQ    <-> "vmseq.vv",
  VVCMP_VMSNE    <-> "vmsne.vv",
  VVCMP_VMSLTU   <-> "vmsltu.vv",
  VVCMP_VMSLT    <-> "vmslt.vv",
  VVCMP_VMSLEU   <-> "vmsleu.vv",
  VVCMP_VMSLE    <-> "vmsle.vv"
}

mapping clause assembly = VVCMPTYPE(funct6, vm, vs2, vs1, vd)
  <-> vvcmptype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)



/* **************************instructions*************************************** */
/* **************************OPIVX(VXtype)************************************** */

union clause ast = VXTYPE : (vxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vxfunct6 : vxfunct6 <-> bits(6) = {
  VX_VADD       <-> 0b000000,
  VX_VSUB       <-> 0b000010,
  VX_VRSUB      <-> 0b000011,
  VX_VMINU      <-> 0b000100,
  VX_VMIN       <-> 0b000101,
  VX_VMAXU      <-> 0b000110,
  VX_VMAX       <-> 0b000111,
  VX_VAND       <-> 0b001001,
  VX_VOR        <-> 0b001010,
  VX_VXOR       <-> 0b001011,
  VX_VSADDU     <-> 0b100000,
  VX_VSADD      <-> 0b100001,
  VX_VSSUBU     <-> 0b100010,
  VX_VSSUB      <-> 0b100011,
  VX_VSLL       <-> 0b100101,
  VX_VSMUL      <-> 0b100111,
  VX_VSRL       <-> 0b101000,
  VX_VSRA       <-> 0b101001,
  VX_VSSRL      <-> 0b101010,
  VX_VSSRA      <-> 0b101011
}

mapping clause encdec = VXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_vxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  //print_int("num_elem=", num_elem);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                             = get_scalar(rs1, vsew_bits);
  //print("rs1_val=" ^ BitStr(rs1_val));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    //print("status=success");
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
          VX_VADD         => vs2_val[i] + rs1_val,
          VX_VSUB         => vs2_val[i] - rs1_val,
          VX_VRSUB        => rs1_val - vs2_val[i],
          VX_VAND         => vs2_val[i] & rs1_val,
          VX_VOR          => vs2_val[i] | rs1_val,
          VX_VXOR         => vs2_val[i] ^ rs1_val,
          VX_VSADDU       => unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, rs1_val) ),
          VX_VSADD        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, rs1_val) ),
          VX_VSSUBU       => {
                               if unsigned(vs2_val[i]) < unsigned(rs1_val) then zeros()
                               else unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, rs1_val) )
                             },
          VX_VSSUB        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, rs1_val) ),
          VX_VSMUL        => {
                               result_mul = to_bits('m * 2, signed(vs2_val[i]) * signed(rs1_val));
                               rounding_incr = get_fixed_rounding_incr(result_mul, 'm - 1);
                               result_wide = (result_mul >> ('m - 1)) + EXTZ('m * 2, rounding_incr);
                               signed_saturation('m, result_wide['m..0])
                             },
          VX_VSLL         => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] << shift_amount
                             },
          VX_VSRL         => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] >> shift_amount
                             },
          VX_VSRA         => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits)
                             },
          VX_VSSRL        => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               (vs2_val[i] >> shift_amount) + EXTZ('m, rounding_incr)
                             },
          VX_VSSRA        => {
                               let shift_amount = get_shift_amount(rs1_val, vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits) + EXTZ('m, rounding_incr)
                             },
          VX_VMINU        => to_bits(vsew_bits, min(unsigned(vs2_val[i]), unsigned(rs1_val))),
          VX_VMIN         => to_bits(vsew_bits, min(signed(vs2_val[i]), signed(rs1_val))),
          VX_VMAXU        => to_bits(vsew_bits, max(unsigned(vs2_val[i]), unsigned(rs1_val))),
          VX_VMAX         => to_bits(vsew_bits, max(signed(vs2_val[i]), signed(rs1_val)))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0)); //All instruction are designed to reset the vstart CSR to zero at the end of execution
    //print_int("vstart=", unsigned(readCSR(csr_name_map("vstart"))))
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxtype_mnemonic : vxfunct6 <-> string = {
  VX_VADD       <-> "vadd.vx",
  VX_VSUB       <-> "vsub.vx",
  VX_VRSUB      <-> "vrsub.vx",
  VX_VAND       <-> "vand.vx",
  VX_VOR        <-> "vor.vx",
  VX_VXOR       <-> "vxor.vx",
  VX_VSADDU     <-> "vsaddu.vx",
  VX_VSADD      <-> "vsadd.vx",
  VX_VSSUBU     <-> "vssubu.vx",
  VX_VSSUB      <-> "vssub.vx",
  VX_VSLL       <-> "vsll.vx",
  VX_VSMUL      <-> "vsmul.vx",
  VX_VSRL       <-> "vsrl.vx",
  VX_VSRA       <-> "vsra.vx",
  VX_VSSRL      <-> "vssrl.vx",
  VX_VSSRA      <-> "vssra.vx",
  VX_VMINU      <-> "vminu.vx",
  VX_VMIN       <-> "vmin.vx",
  VX_VMAXU      <-> "vmaxu.vx",
  VX_VMAX       <-> "vmax.vx"
}

mapping clause assembly = VXTYPE(funct6, vm, vs2, rs1, vd)
  <-> vxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************VXMTYPE**************************************** */
/* VXM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VXMTYPE : (vxmfunct6, regidx, regidx, regidx)

mapping encdec_vxmfunct6 : vxmfunct6 <-> bits(6) = {
  VXM_VMADC    <-> 0b010001, /* Carry in, carry out */
  VXM_VMSBC    <-> 0b010011
}

mapping clause encdec = VXMTYPE(funct6, vs2, rs1, vd)
  <-> encdec_vxmfunct6(funct6) @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXMTYPE(funct6, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
  let rs1_val                              = get_scalar(rs1, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VXM_VMADC    => if unsigned(vs2_val[i]) + unsigned(rs1_val) + unsigned(bool_to_bits(vm_val[i])) > 2 ^ vsew_bits - 1 then true else false,
          VXM_VMSBC    => if unsigned(vs2_val[i]) - unsigned(rs1_val) - unsigned(bool_to_bits(vm_val[i])) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxmtype_mnemonic : vxmfunct6 <-> string = {
  VXM_VMADC    <-> "vmadc.vxm", /* Carry in, carry out */
  VXM_VMSBC    <-> "vmsbc.vxm"
}

mapping clause assembly = VXMTYPE(funct6, vs2, rs1, vd)
  <-> vxmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0"


/* **************************VXMCTYPE**************************************** */
/* VXMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VXMCTYPE : (vxmcfunct6, regidx, regidx, regidx)

mapping encdec_vxmcfunct6 : vxmcfunct6 <-> bits(6) = {
  VXMC_VMADC    <-> 0b010001, /* Carry in, carry out */
  VXMC_VMSBC    <-> 0b010011
}

mapping clause encdec = VXMCTYPE(funct6, vs2, rs1, vd)
  <-> encdec_vxmcfunct6(funct6) @ 0b1 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXMCTYPE(funct6, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let rs1_val                              = get_scalar(rs1, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VXMC_VMADC    => if unsigned(vs2_val[i]) + unsigned(rs1_val) > 2 ^ vsew_bits - 1 then true else false,
          VXMC_VMSBC    => if unsigned(vs2_val[i]) - unsigned(rs1_val) < 0 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxmctype_mnemonic : vxmcfunct6 <-> string = {
  VXMC_VMADC    <-> "vmadc.vx", /* Carry in, carry out */
  VXMC_VMSBC    <-> "vmsbc.vx"
}

mapping clause assembly = VXMCTYPE(funct6, vs2, rs1, vd)
  <-> vxmctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1)


/* **************************VXMSTYPE**************************************** */
/* VXMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VXMSTYPE : (vxmsfunct6, regidx, regidx, regidx)

mapping encdec_vxmsfunct6 : vxmsfunct6 <-> bits(6) = {
  VXMS_VADC     <-> 0b010000, /* Carry in, no carry out */
  VXMS_VSBC     <-> 0b010010
}

mapping clause encdec = VXMSTYPE(funct6, vs2, rs1, vd)
  <-> encdec_vxmsfunct6(funct6) @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXMSTYPE(funct6, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  vm_val       : vector('n, dec, bool)     = undefined;
  rs1_val                                  = get_scalar(rs1, vsew_bits);
  vs2_val      : vector('n, dec, bits('m)) = undefined;
  vd_val       : vector('n, dec, bits('m)) = undefined;
  result       : vector('n, dec, bits('m)) = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /* For bypassing vm masking in init_masked_result */
  all_trues : vector('n, dec, bool) = undefined;
  foreach (i from 0 to (num_elem - 1)) {
    all_trues[i] = true
  };

  if vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    vm_val  = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, vsew_bits, lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, all_trues);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VXMS_VADC     => to_bits(vsew_bits, signed(vs2_val[i]) + signed(rs1_val) + signed(bool_to_bits(vm_val[i]))),
          VXMS_VSBC     => to_bits(vsew_bits, signed(vs2_val[i]) - signed(rs1_val) - signed(bool_to_bits(vm_val[i])))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vxmstype_mnemonic : vxmsfunct6 <-> string = {
  VXMS_VADC     <-> "vadc.vxm", /* Carry in, no carry out */
  VXMS_VSBC     <-> "vsbc.vxm"
}

mapping clause assembly = VXMSTYPE(funct6, vs2, rs1, vd)
  <-> vxmstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0"


/* **************************VXCMPTYPE**************************************** */
/* VXCMP instructions' destination is a mask register */

union clause ast = VXCMPTYPE : (vxcmpfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vxcmpfunct6 : vxcmpfunct6 <-> bits(6) = {
  VXCMP_VMSEQ    <-> 0b011000,
  VXCMP_VMSNE    <-> 0b011001,
  VXCMP_VMSLTU   <-> 0b011010,
  VXCMP_VMSLT    <-> 0b011011,
  VXCMP_VMSLEU   <-> 0b011100,
  VXCMP_VMSLE    <-> 0b011101,
  VXCMP_VMSGTU   <-> 0b011110,
  VXCMP_VMSGT    <-> 0b011111
}

mapping clause encdec = VXCMPTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_vxcmpfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXCMPTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                              = get_scalar(rs1, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VXCMP_VMSEQ    => if vs2_val[i] == rs1_val then true else false,
          VXCMP_VMSNE    => if vs2_val[i] != rs1_val then true else false,
          VXCMP_VMSLTU   => if unsigned(vs2_val[i]) < unsigned(rs1_val) then true else false,
          VXCMP_VMSLT    => if signed(vs2_val[i]) < signed(rs1_val) then true else false,
          VXCMP_VMSLEU   => if unsigned(vs2_val[i]) <= unsigned(rs1_val) then true else false,
          VXCMP_VMSLE    => if signed(vs2_val[i]) <= signed(rs1_val) then true else false,
          VXCMP_VMSGTU   => if unsigned(vs2_val[i]) > unsigned(rs1_val) then true else false,
          VXCMP_VMSGT    => if signed(vs2_val[i]) > signed(rs1_val) then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

mapping vxcmptype_mnemonic : vxcmpfunct6 <-> string = {
  VXCMP_VMSEQ    <-> "vmseq.vx",
  VXCMP_VMSNE    <-> "vmsne.vx",
  VXCMP_VMSLTU   <-> "vmsltu.vx",
  VXCMP_VMSLT    <-> "vmslt.vx",
  VXCMP_VMSLEU   <-> "vmsleu.vx",
  VXCMP_VMSLE    <-> "vmsle.vx",
  VXCMP_VMSGTU   <-> "vmsgtu.vx",
  VXCMP_VMSGT    <-> "vmsgt.vx"
}

mapping clause assembly = VXCMPTYPE(funct6, vm, vs2, rs1, vd)
  <-> vxcmptype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************OPIVX(VXtype)Widened*************************************** */

union clause ast = WVXTYPE : (wvxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wvxfunct6 : wvxfunct6 <-> bits(6) = {
  WVX_VADD       <-> 0b110001,
  WVX_VSUB       <-> 0b110011,
  WVX_VADDU      <-> 0b110000,
  WVX_VSUBU      <-> 0b110010,
  WVX_VWMUL      <-> 0b111011,
  WVX_VWMULU     <-> 0b111000,
  WVX_VWMULSU    <-> 0b111010
}

mapping clause encdec = WVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_wvxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd @ 0b1010111

function clause execute(WVXTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;
  assert(8 <= double_vsew & double_vsew <= 64);

  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd);
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  result : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined */ then {
    status = RETIRE_FAIL;
    //print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print_int("vs2=", signed(vs2_val[i]));
        //print_int("rs1=", signed(rs1_val));        
        result[i] = match funct6 {
          WVX_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(rs1_val)),
          WVX_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(rs1_val)),
          WVX_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(rs1_val)),
          WVX_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(rs1_val)),
          WVX_VWMUL        => to_bits(double_vsew, signed(vs2_val[i]) * signed(rs1_val)),
          WVX_VWMULU       => to_bits(double_vsew, unsigned(vs2_val[i]) * unsigned(rs1_val)),
          WVX_VWMULSU      => to_bits(double_vsew, signed(vs2_val[i]) * unsigned(rs1_val))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0))
  };
  
  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wvxtype_mnemonic : wvxfunct6 <-> string = {
  WVX_VADD       <-> "vwadd.vx",
  WVX_VSUB       <-> "vwsub.vx",
  WVX_VADDU      <-> "vwaddu.vx",
  WVX_VSUBU      <-> "vwsubu.vx",
  WVX_VWMUL      <-> "vwmul.vx",
  WVX_VWMULU     <-> "vwmulu.vx",
  WVX_VWMULSU    <-> "vwmulsu.vx"
}

mapping clause assembly = WVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> wvxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************WXTYPE**************************************** */

union clause ast = WXTYPE : (wxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wxfunct6 : wxfunct6 <-> bits(6) = {
  WX_VADD       <-> 0b110101,
  WX_VSUB       <-> 0b110111,
  WX_VADDU      <-> 0b110100,
  WX_VSUBU      <-> 0b110110
}

mapping clause encdec = WXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_wxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd @ 0b1010111

function clause execute(WXTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  vm_val      : vector('n, dec, bool)     = undefined;
  rs1_val                                 = get_scalar(rs1, vsew_bits);
  vs2_val     : vector('n, dec, bits('o)) = undefined;
  vd_val      : vector('n, dec, bits('o)) = undefined;
  result      : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    vm_val  = read_vmask(num_elem, vm, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, double_vsew, double_lmul, vs2);
    vd_val  = read_vreg(num_elem, double_vsew, double_lmul, vd)
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    assert(16 <= double_vsew & double_vsew <= 64);
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);
  
    let start_element : int = get_start_element();
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          WX_VADD         => to_bits(double_vsew, signed(vs2_val[i]) + signed(rs1_val)),
          WX_VSUB         => to_bits(double_vsew, signed(vs2_val[i]) - signed(rs1_val)),
          WX_VADDU        => to_bits(double_vsew, unsigned(vs2_val[i]) + unsigned(rs1_val)),
          WX_VSUBU        => to_bits(double_vsew, unsigned(vs2_val[i]) - unsigned(rs1_val))
        }
      }
    };
  
    write_vreg(num_elem, double_vsew, double_lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wxtype_mnemonic : wxfunct6 <-> string = {
  WX_VADD       <-> "vwadd.wx",
  WX_VSUB       <-> "vwsub.wx",
  WX_VADDU      <-> "vwaddu.wx",
  WX_VSUBU      <-> "vwsubu.wx"
}

mapping clause assembly = WXTYPE(funct6, vm, vs2, rs1, vd)
  <-> wxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************NXSTYPE(Narrowing)**************************************** */

union clause ast = NXSTYPE : (nxsfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nxsfunct6 : nxsfunct6 <-> bits(6) = {
  NXS_VNSRL       <-> 0b101100,
  NXS_VNSRA       <-> 0b101101
}

mapping clause encdec = NXSTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_nxsfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(NXSTYPE(funct6, vm, vs2, rs1, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  
  assert(8 <= vsew_bits & vsew_bits <= 32);
  assert(16 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  if (double_vsew > sizeof(elen) | double_lmul > 8.0) then {
    status = RETIRE_FAIL
  };

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                             = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          NXS_VNSRL    => {
                           let shift_amount = get_shift_amount(rs1_val, double_vsew);
                           assert(shift_amount >= 0);
                           slice(vs2_val[i] >> shift_amount, 0, vsew_bits)
                         },
          NXS_VNSRA    => {
                           let shift_amount = get_shift_amount(rs1_val, double_vsew);
                           assert(shift_amount >= 0);
                           let v_double : bits('o * 2) = EXTS(vs2_val[i]);
                           let arith_shifted : bits('o) = slice(v_double >> shift_amount, 0, double_vsew);
                           slice(arith_shifted, 0, vsew_bits)
                         }
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping nxstype_mnemonic : nxsfunct6 <-> string = {
  NXS_VNSRL       <-> "vnsrl.wx",
  NXS_VNSRA       <-> "vnsra.wx"
}

mapping clause assembly = NXSTYPE(funct6, vm, vs2, rs1, vd)
  <-> nxstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)
  

/* **************************NXTYPE(Narrowing)**************************************** */

union clause ast = NXTYPE : (nxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nxfunct6 : nxfunct6 <-> bits(6) = {
  NX_VNCLIPU     <-> 0b101110,
  NX_VNCLIP      <-> 0b101111
}

mapping clause encdec = NXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_nxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(NXTYPE(funct6, vm, vs2, rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val                             = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let shift_amount = get_shift_amount(rs1_val, vsew_bits);
      assert(shift_amount >= 0);
      let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);

      result[i] = match funct6 {
        NX_VNCLIPU  => {                    
                         result_wide = (vs2_val[i] >> shift_amount) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         unsigned_saturation('m, result_wide)
                       },
        NX_VNCLIP   => { 
                         assert(('m * 4) >= 'o);         
                         let v_double : bits('m * 4) = sail_sign_extend(vs2_val[i], 'm * 4);
                         result_wide = slice(v_double >> shift_amount, 0, 'o) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         signed_saturation('m, result_wide)
                       }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);

  RETIRE_SUCCESS
}

mapping nxtype_mnemonic : nxfunct6 <-> string = {
  NX_VNCLIPU     <-> "vnclipu.wx",
  NX_VNCLIP      <-> "vnclip.wx"
}

mapping clause assembly = NXTYPE(funct6, vm, vs2, rs1, vd)
  <-> nxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* **************************OPIVI(VItype)**************************************** */

union clause ast = VITYPE : (vifunct6, bits(1), regidx, bits(5), regidx)

mapping encdec_vifunct6 : vifunct6 <-> bits(6) = {
  VI_VADD       <-> 0b000000,
  VI_VRSUB      <-> 0b000011,
  VI_VAND       <-> 0b001001,
  VI_VOR        <-> 0b001010,
  VI_VXOR       <-> 0b001011,
  VI_VSADDU     <-> 0b100000,
  VI_VSADD      <-> 0b100001,
  VI_VSLL       <-> 0b100101,
  VI_VSRL       <-> 0b101000,
  VI_VSRA       <-> 0b101001,
  VI_VSSRL      <-> 0b101010,
  VI_VSSRA      <-> 0b101011
}

mapping clause encdec = VITYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_vifunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VITYPE(funct6, vm, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                             = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /* |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined */then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
          VI_VADD         => vs2_val[i] + imm_val,
          VI_VRSUB        => imm_val - vs2_val[i],
          VI_VAND         => vs2_val[i] & imm_val,
          VI_VOR          => vs2_val[i] | imm_val,
          VI_VXOR         => vs2_val[i] ^ imm_val,
          VI_VSADDU       => unsigned_saturation('m, EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, imm_val) ),
          VI_VSADD        => signed_saturation('m, EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, imm_val) ),
          VI_VSLL         => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] << shift_amount
                             },
          VI_VSRL         => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               vs2_val[i] >> shift_amount
                             },
          VI_VSRA         => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits)
                             },
          VI_VSSRL        => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               (vs2_val[i] >> shift_amount) + EXTZ('m, rounding_incr)
                             },
          VI_VSSRA        => {
                               let shift_amount = get_shift_amount(sail_zero_extend(simm, vsew_bits), vsew_bits);
                               assert(shift_amount >= 0);
                               let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
                               let v_double : bits('m * 2) = EXTS(vs2_val[i]);
                               slice(v_double >> shift_amount, 0, vsew_bits) + EXTZ('m, rounding_incr)
                             }
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vitype_mnemonic : vifunct6 <-> string = {
  VI_VADD   <-> "vadd.vi",
  VI_VRSUB  <-> "vrsub.vi",
  VI_VAND   <-> "vand.vi",
  VI_VOR    <-> "vor.vi",
  VI_VXOR   <-> "vxor.vi",
  VI_VSADDU <-> "vsaddu.vi",
  VI_VSADD  <-> "vsadd.vi",
  VI_VSLL   <-> "vsll.vi",
  VI_VSRL   <-> "vsrl.vi",
  VI_VSRA   <-> "vsra.vi",
  VI_VSSRL  <-> "vssrl.vi",
  VI_VSSRA  <-> "vssra.vi"
}

mapping clause assembly = VITYPE(funct6, vm, vs2, simm, vd)
  <-> vitype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm)


/* **************************VIMTYPE**************************************** */
/* VIM instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VIMTYPE : (vimfunct6, regidx, regidx, regidx)

mapping encdec_vimfunct6 : vimfunct6 <-> bits(6) = {
  VIM_VMADC    <-> 0b010001 /* Carry in, carry out */
}

mapping clause encdec = VIMTYPE(funct6, vs2, simm, vd)
  <-> encdec_vimfunct6(funct6) @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VIMTYPE(funct6, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
  let imm_val                              = sail_sign_extend(simm, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VIM_VMADC    => if unsigned(vs2_val[i]) + unsigned(imm_val) + unsigned(bool_to_bits(vm_val[i])) > 2 ^ vsew_bits - 1 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vimtype_mnemonic : vimfunct6 <-> string = {
  VIM_VMADC    <-> "vmadc.vim" /* Carry in, carry out */
}

mapping clause assembly = VIMTYPE(funct6, vs2, simm, vd)
  <-> vimtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0"


/* **************************VIMCTYPE**************************************** */
/* VIMC instructions' destination is a mask register (e.g. carry out) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VIMCTYPE : (vimcfunct6, regidx, regidx, regidx)

mapping encdec_vimcfunct6 : vimcfunct6 <-> bits(6) = {
  VIMC_VMADC    <-> 0b010001 /* Carry in, carry out */
}

mapping clause encdec = VIMCTYPE(funct6, vs2, simm, vd)
  <-> encdec_vimcfunct6(funct6) @ 0b1 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VIMCTYPE(funct6, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let imm_val                              = sail_sign_extend(simm, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /*if vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VIMC_VMADC    => if unsigned(vs2_val[i]) + unsigned(imm_val) > 2 ^ vsew_bits - 1 then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vimctype_mnemonic : vimcfunct6 <-> string = {
  VIMC_VMADC    <-> "vmadc.vi" /* Carry in, carry out */
}

mapping clause assembly = VIMCTYPE(funct6, vs2, simm, vd)
  <-> vimctype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm)


/* **************************VIMSTYPE**************************************** */
/* VIMS instructions' destination is a vector register (e.g. actual sum) */
/* Instructions with no carry out will set mask result to current mask value */
/* May or may not read from source mask register (e.g. carry in) */

union clause ast = VIMSTYPE : (vimsfunct6, regidx, regidx, regidx)

mapping encdec_vimsfunct6 : vimsfunct6 <-> bits(6) = {
  VIMS_VADC     <-> 0b010000 /* Carry in, no carry out */
}

mapping clause encdec = VIMSTYPE(funct6, vs2, simm, vd)
  <-> encdec_vimsfunct6(funct6) @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VIMSTYPE(funct6, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  vm_val       : vector('n, dec, bool)     = undefined;
  imm_val                                  = sail_sign_extend(simm, vsew_bits);
  vs2_val      : vector('n, dec, bits('m)) = undefined;
  vd_val       : vector('n, dec, bits('m)) = undefined;
  result       : vector('n, dec, bits('m)) = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  /* For bypassing vm masking in init_masked_result */
  all_trues : vector('n, dec, bool) = undefined;
  foreach (i from 0 to (num_elem - 1)) {
    all_trues[i] = true
  };

  if vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    vm_val  = read_vmask_carry(num_elem, 0b0, vreg_name("v0"));
    vs2_val = read_vreg(num_elem, vsew_bits, lmul, vs2);
    vd_val  = read_vreg(num_elem, vsew_bits, lmul, vd)
  };

  /*if vm_val      == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, all_trues);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VIMS_VADC     => to_bits(vsew_bits, signed(vs2_val[i]) + signed(imm_val) + signed(bool_to_bits(vm_val[i])))
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping vimstype_mnemonic : vimsfunct6 <-> string = {
  VIMS_VADC     <-> "vadc.vim" /* Carry in, no carry out */
}

mapping clause assembly = VIMSTYPE(funct6, vs2, simm, vd)
  <-> vimstype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0"


/* **************************VICMPTYPE**************************************** */
/* VICMP instructions' destination is a mask register */

union clause ast = VICMPTYPE : (vicmpfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vicmpfunct6 : vicmpfunct6 <-> bits(6) = {
  VICMP_VMSEQ    <-> 0b011000,
  VICMP_VMSNE    <-> 0b011001,
  VICMP_VMSLEU   <-> 0b011100,
  VICMP_VMSLE    <-> 0b011101,
  VICMP_VMSGTU   <-> 0b011110,
  VICMP_VMSGT    <-> 0b011111
}

mapping clause encdec = VICMPTYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_vicmpfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VICMPTYPE(funct6, vm, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                              = sail_sign_extend(simm, vsew_bits);
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val   : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vd);
  result       : vector('n, dec, bool)     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    let start_element : int = get_start_element();
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VICMP_VMSEQ    => if vs2_val[i] == imm_val then true else false,
          VICMP_VMSNE    => if vs2_val[i] != imm_val then true else false,
          VICMP_VMSLEU   => if unsigned(vs2_val[i]) <= unsigned(imm_val) then true else false,
          VICMP_VMSLE    => if signed(vs2_val[i]) <= signed(imm_val) then true else false,
          VICMP_VMSGTU   => if unsigned(vs2_val[i]) > unsigned(imm_val) then true else false,
          VICMP_VMSGT    => if signed(vs2_val[i]) > signed(imm_val) then true else false
        };
        result[i] = resval
      }
    };
  
    write_vmask(num_elem, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

mapping vicmptype_mnemonic : vicmpfunct6 <-> string = {
  VICMP_VMSEQ    <-> "vmseq.vi",
  VICMP_VMSNE    <-> "vmsne.vi",
  VICMP_VMSLEU   <-> "vmsleu.vi",
  VICMP_VMSLE    <-> "vmsle.vi",
  VICMP_VMSGTU   <-> "vmsgtu.vi",
  VICMP_VMSGT    <-> "vmsgt.vi"
}

mapping clause assembly = VICMPTYPE(funct6, vm, vs2, simm, vd)
  <-> vicmptype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm)


/* **************************NITYPE(Narrowing)**************************************** */

union clause ast = NISTYPE : (nisfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nisfunct6 : nisfunct6 <-> bits(6) = {
  NIS_VNSRL       <-> 0b101100,
  NIS_VNSRA       <-> 0b101101
}

mapping clause encdec = NISTYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_nisfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(NISTYPE(funct6, vm, vs2, simm, vd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  if (double_vsew > sizeof(elen) | double_lmul > 8.0) then {
    status = RETIRE_FAIL
  };

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                             = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
                NIS_VNSRL    => {
                                  let shift_amount = get_shift_amount(imm_val, double_vsew);
                                  assert(shift_amount >= 0);
                                  slice(vs2_val[i] >> shift_amount, 0, vsew_bits)
                                },
                NIS_VNSRA    => {
                                  let shift_amount = get_shift_amount(imm_val, double_vsew);
                                  assert(shift_amount >= 0);
                                  let v_double : bits('o * 2) = EXTS(vs2_val[i]);
                                  let arith_shifted : bits('o) = slice(v_double >> shift_amount, 0, double_vsew);
                                  slice(arith_shifted, 0, vsew_bits)
                                }
        }
      }
    };
  
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };
  
  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping nistype_mnemonic : nisfunct6 <-> string = {
  NIS_VNSRL       <-> "vnsrl.wi",
  NIS_VNSRA       <-> "vnsra.wi"
}

mapping clause assembly = NISTYPE(funct6, vm, vs2, simm, vd)
  <-> nistype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm) 


/* **************************MMTYPE**************************************** */

union clause ast = MMTYPE : (mmfunct6, regidx, regidx, regidx)

mapping encdec_mmfunct6 : mmfunct6 <-> bits(6) = {
  MM_VMAND     <-> 0b011001,
  MM_VMNAND    <-> 0b011101,
  MM_VMANDNOT  <-> 0b011000,
  MM_VMXOR     <-> 0b011011,
  MM_VMOR      <-> 0b011010,
  MM_VMNOR     <-> 0b011110,
  MM_VMORNOT   <-> 0b011100,
  MM_VMXNOR    <-> 0b011111
}

mapping clause encdec = MMTYPE(funct6, vs2, vs1, vd)
  <-> encdec_mmfunct6(funct6) @ 0b1 @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(MMTYPE(funct6, vs2, vs1, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs1_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs1);
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /*if vs1_val     == undefined |
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined then {
    status = RETIRE_FAIL
  };*/

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_carry(num_elem, vsew_bits, lmul, vd_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        resval : bool = match funct6 {
          MM_VMAND     => vs2_val[i] & vs1_val[i],
          MM_VMNAND    => ~(vs2_val[i] & vs1_val[i]),
          MM_VMANDNOT  => vs2_val[i] & ~(vs1_val[i]),
          MM_VMXOR     => vs2_val[i] ^ vs1_val[i],
          MM_VMOR      => vs2_val[i] | vs1_val[i],
          MM_VMNOR     => ~(vs2_val[i] | vs1_val[i]),
          MM_VMORNOT   => vs2_val[i] | ~(vs1_val[i]),
          MM_VMXNOR    => ~(vs2_val[i] ^ vs1_val[i])
        };
	result[i] = resval
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping mmtype_mnemonic : mmfunct6 <-> string = {
  MM_VMAND     <-> "vmand.mm",
  MM_VMNAND    <-> "vmnand.mm",
  MM_VMANDNOT  <-> "vmandnot.mm",
  MM_VMXOR     <-> "vmxor.mm",
  MM_VMOR      <-> "vmor.mm",
  MM_VMNOR     <-> "vmnor.mm",
  MM_VMORNOT   <-> "vmornot.mm",
  MM_VMXNOR    <-> "vmxnor.mm"
}

mapping clause assembly = MMTYPE(funct6, vs2, vs1, vd)
  <-> mmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)


/* **************************VCPOP_M******************** ******************** */

union clause ast = VCPOP_M : (bits(1), regidx, regidx)

mapping clause encdec = VCPOP_M(vm, vs2, rd)
  <-> 0b010000 @ vm @ vs2 @ 0b10000 @ 0b010 @ rd @ 0b1010111

function clause execute(VCPOP_M(vm, vs2, rd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  var result      : int                   = 0;
  mask_result : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  if status == RETIRE_SUCCESS then {
    //print("status is success!");
    (mask_result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vs2_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print("masked");
        if vs2_val[i] == true then {
          //print("vs2[i]=1");
          result = result + 1;
        }
      }
    };
    
    X(rd) = to_bits(sizeof(xlen), result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  status
}

mapping clause assembly = VCPOP_M(vm, vs2, rd)
  <-> "vpopc.m" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VFIRST_M**************************************** */

union clause ast = VFIRST_M : (bits(1), regidx, regidx)

mapping clause encdec = VFIRST_M(vm, vs2, rd)
  <-> 0b010000 @ vm @ vs2 @ 0b10001 @ 0b010 @ rd @ 0b1010111

function clause execute(VFIRST_M(vm, vs2, rd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  result      : int                   = -1;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  if status == RETIRE_SUCCESS then {

    foreach (i from 0 to (num_elem - 1)) {
      if result == -1 then {
        if vm_val[i] == true then {
          if vs2_val[i] == true then {
            result = i
          }
        };
      };
    };

    X(rd) = to_bits(sizeof(xlen), result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VFIRST_M(vm, vs2, rd)
  <-> "vfirst.m" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VMSBF_M**************************************** */

union clause ast = VMSBF_M : (bits(1), regidx, regidx)

mapping clause encdec = VMSBF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b00001 @ 0b010 @ vd @ 0b1010111

function clause execute(VMSBF_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var found_elem : bool = false;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        if vs2_val[i] == true then {
          found_elem = true
        };

        if found_elem then {
          result[i] = false
        }
	      else {
          result[i] = true
        }
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VMSBF_M(vm, vs2, vd)
  <-> "vmsbf.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VMSIF_M**************************************** */

union clause ast = VMSIF_M : (bits(1), regidx, regidx)

mapping clause encdec = VMSIF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b00011 @ 0b010 @ vd @ 0b1010111

function clause execute(VMSIF_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var found_elem : bool = false;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        if found_elem then {
          result[i] = false
        }
	      else {
          result[i] = true
        };

        if vs2_val[i] == true then {
          found_elem = true
        }
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VMSIF_M(vm, vs2, vd)
  <-> "vmsif.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VMSOF_M**************************************** */

union clause ast = VMSOF_M : (bits(1), regidx, regidx)

mapping clause encdec = VMSOF_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b00010 @ 0b010 @ vd @ 0b1010111

function clause execute(VMSOF_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);
  result      : vector('n, dec, bool) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var found_elem : bool = false;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        if vs2_val[i] == true & found_elem == false then {
          result[i] = true;
	        found_elem = true
        }
	      else {
          result[i] = false
        }
      }
    };
    
    write_vmask(num_elem, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VMSOF_M(vm, vs2, vd)
  <-> "vmsof.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VIOTA_M**************************************** */

union clause ast = VIOTA_M : (bits(1), regidx, regidx)

mapping clause encdec = VIOTA_M(vm, vs2, vd)
  <-> 0b010100 @ vm @ vs2 @ 0b10000 @ 0b010 @ vd @ 0b1010111

function clause execute(VIOTA_M(vm, vs2, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  /* Value of vstart must be 0 */
  status = assert_vstart(0);

  /* If masking is enabled, then dest reg cannot be v0 */
  if vm == 0b0 & vd == vreg_name("v0") then {
    status = RETIRE_FAIL
  };

  /* Dest reg cannot be the same as source reg */
  if vd == vs2 then {
    status = RETIRE_FAIL
  };

  if vm_val      == undefined /*|
     vs2_val     == undefined |
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

    var total : int = 0;
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
	      result[i] = to_bits(vsew_bits, total);
        if vs2_val[i] == true then total = total + 1
      }
    };
    
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VIOTA_M(vm, vs2, vd)
  <-> "viota.m" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* **************************VID_V**************************************** */

union clause ast = VID_V : (bits(1), regidx)

mapping clause encdec = VID_V(vm, vd)
  <-> 0b010100 @ vm @ 0b00000 @ 0b10001 @ 0b010 @ vd @ 0b1010111

function clause execute(VID_V(vm, vd)) = {
  status         : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  if vm_val      == undefined /*|
     vd_val      == undefined |
     mask_helper == undefined*/ then {
    status = RETIRE_FAIL
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = to_bits(vsew_bits, i)
      }
    };
    
    write_vreg(num_elem, vsew_bits, lmul, vd, result)
  };

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping clause assembly = VID_V(vm, vd)
  <-> "vid.v" ^ spc() ^ vreg_name(vd) ^ maybe_vmask(vm)


/* **************************NITYPE(Narrowing)**************************************** */

union clause ast = NITYPE : (nifunct6, bits(1), regidx, regidx, regidx)

mapping encdec_nifunct6 : nifunct6 <-> bits(6) = {
  NI_VNCLIPU     <-> 0b101110,
  NI_VNCLIP      <-> 0b101111
}

mapping clause encdec = NITYPE(funct6, vm, vs2, simm, vd)
  <-> encdec_nifunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(NITYPE(funct6, vm, vs2, simm, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(8 <= double_vsew & double_vsew <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val                             = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      let shift_amount = get_shift_amount(imm_val, vsew_bits);
      assert(shift_amount >= 0);
      let rounding_incr = get_fixed_rounding_incr(vs2_val[i], shift_amount);
      result[i] = match funct6 {
        NI_VNCLIPU  => {                    
                         result_wide = (vs2_val[i] >> shift_amount) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         unsigned_saturation('m, result_wide)
                       },
        NI_VNCLIP   => { 
                         assert(('m * 4) >= 'o);         
                         let v_double : bits('m * 4) = sail_sign_extend(vs2_val[i], 'm * 4);
                         result_wide = slice(v_double >> shift_amount, 0, 'o) + EXTZ('o, rounding_incr);
                         assert('o >= 'm & 'm > 0);
                         signed_saturation('m, result_wide)
                       }
      };
    };
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);

  RETIRE_SUCCESS
}

mapping nitype_mnemonic : nifunct6 <-> string = {
  NI_VNCLIPU     <-> "vnclipu.wi",
  NI_VNCLIP      <-> "vnclip.wi"
}

mapping clause assembly = NITYPE(funct6, vm, vs2, simm, vd)
  <-> nitype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ maybe_vmask(vm) 
  

/* *******************************OPIVX(Vector Slide & Gather Instructions)******************************** */
/* Slide and gather instructions extend rs1 / imm to XLEN bits (not SEW bits as others do) */

union clause ast = VXSG : (vxsgfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_vxsgfunct6 : vxsgfunct6 <-> bits(6) = {
  VX_VSLIDEUP     <-> 0b001110,
  VX_VSLIDEDOWN   <-> 0b001111,
  VX_VRGATHER     <-> 0b001100
}

mapping clause encdec = VXSG(funct6, vm, vs2, rs1, vd)
  <-> encdec_vxsgfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(VXSG(funct6, vm, vs2, rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val : int                       = unsigned(X(rs1));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        VX_VSLIDEUP     => {
                              assert(vs2 != vd);
                              assert(i - rs1_val < 'n);
                              if i >= rs1_val then vs2_val[i - rs1_val] else vd_val[i]
                           },
        VX_VSLIDEDOWN   => {
                              assert(i + rs1_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if i + rs1_val < vlmax then {
                                assert(i + rs1_val < 'n); 
                                vs2_val[i + rs1_val]
                              } else zeros()
                           },
        VX_VRGATHER     => {
                              assert(vs2 != vd);
                              assert(rs1_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if rs1_val < vlmax then {
                                assert(rs1_val < 'n); 
                                vs2_val[rs1_val]
                              } else zeros() 
                           }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  RETIRE_SUCCESS
} 

mapping vxsg_mnemonic : vxsgfunct6 <-> string = {
  VX_VSLIDEUP     <-> "vslideup.vx",
  VX_VSLIDEDOWN   <-> "vslidedown.vx",
  VX_VRGATHER     <-> "vrgather.vx"
}

mapping clause assembly = VXSG(funct6, vm, vs2, rs1, vd)
  <-> vxsg_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* *******************************OPIVI(Vector Slide & Gather Instructions)******************************** */
/* Slide and gather instructions extend rs1 / imm to XLEN bits (not SEW bits as others do) */

union clause ast = VISG : (visgfunct6, bits(1), regidx, bits(5), regidx)

mapping encdec_visgfunct6 : visgfunct6 <-> bits(6) = {
  VI_VSLIDEUP     <-> 0b001110,
  VI_VSLIDEDOWN   <-> 0b001111,
  VI_VRGATHER     <-> 0b001100
}

mapping clause encdec = VISG(funct6, vm, vs2, simm, vd)
  <-> encdec_visgfunct6(funct6) @ vm @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VISG(funct6, vm, vs2, simm, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let imm_val : int                       = unsigned(EXTZ(sizeof(xlen), simm));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        VI_VSLIDEUP     => {
                              assert(vs2 != vd);
                              assert(i - imm_val < 'n);
                              if i >= imm_val then vs2_val[i - imm_val] else vd_val[i]
                           },
        VI_VSLIDEDOWN   => {
                              assert(i + imm_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if i + imm_val < vlmax then {
                                assert(i + imm_val < 'n); 
                                vs2_val[i + imm_val]
                              } else zeros()
                           },
        VI_VRGATHER     => {
                              assert(vs2 != vd);
                              assert(imm_val >= 0);
                              vlmax = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
                              if imm_val < vlmax then {
                                assert(imm_val < 'n); 
                                vs2_val[imm_val]
                              } else zeros() 
                           }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  RETIRE_SUCCESS
} 

mapping visg_mnemonic : visgfunct6 <-> string = {
  VI_VSLIDEUP     <-> "vslideup.vi",
  VI_VSLIDEDOWN   <-> "vslidedown.vi",
  VI_VRGATHER     <-> "vrgather.vi"
}

mapping clause assembly = VISG(funct6, vm, vs2, simm, vd)
  <-> visg_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(simm) ^ maybe_vmask(vm)


/* ******************************Whole Vector Register Move(OPIVI)******************************** */

union clause ast = VMVRTYPE : (regidx, bits(5), regidx)

mapping clause encdec = VMVRTYPE(vs2, simm, vd)
  <-> 0b100111 @ 0b1 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(VMVRTYPE(vs2, simm, vd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let imm_val    : int  = unsigned(EXTZ(sizeof(xlen), simm));
  let lmul       : int = imm_val + 1;
  assert( (lmul == 1) | (lmul == 2) | (lmul == 4) | (lmul == 8) );
  let num_elem   : int = get_num_elem(to_real(lmul), vsew_bits);
  assert(8 <= vsew_bits & vsew_bits <= 64);

  let 'num_elem = num_elem;
  let 'veew_bits = vsew_bits;
  let vs2_val : vector('num_elem, dec, bits('veew_bits)) = read_vreg(num_elem, vsew_bits, to_real(lmul), vs2);
  write_vreg(num_elem, vsew_bits, to_real(lmul), vd, vs2_val);

  RETIRE_SUCCESS
} 

mapping simm_string : bits(5) <-> string = {
  0b00000 <-> "1",
  0b00001 <-> "2",
  0b00011 <-> "4",
  0b00111 <-> "8"
}

mapping clause assembly = VMVRTYPE(vs2, simm, vd)
  <-> "vmv" ^ simm_string(simm) ^ "r.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2)


/* ******************************OPMVV(MVVtype)*********************************** */

union clause ast = MVVTYPE : (mvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvvfunct6 : mvvfunct6 <-> bits(6) = {
  MVV_VAADDU      <-> 0b001000,
  MVV_VAADD       <-> 0b001001,
  MVV_VASUBU      <-> 0b001010,
  MVV_VASUB       <-> 0b001011,
  MVV_VMUL        <-> 0b100101,
  MVV_VMULH       <-> 0b100111,
  MVV_VMULHU      <-> 0b100100,
  MVV_VMULHSU     <-> 0b100110,
  MVV_VDIVU       <-> 0b100000,
  MVV_VDIV        <-> 0b100001,
  MVV_VREMU       <-> 0b100010,
  MVV_VREM        <-> 0b100011
}

mapping clause encdec = MVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_mvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(MVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  status : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;  

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then{
        //print("vs1_val[i]=" ^ BitStr(vs1_val[i]));
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
          MVV_VAADDU         => {
                                  result_add = EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                  slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)                              
                                },
          MVV_VAADD          => {
                                  result_add = EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                  slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                                },
          MVV_VASUBU         => {
                                  result_sub = EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                  slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)                             
                                },
          MVV_VASUB          => {
                                  result_sub = EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, vs1_val[i]);
                                  rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                  slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                                },
          MVV_VMUL         => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(vs1_val[i])), 0, vsew_bits),
          MVV_VMULH        => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(vs1_val[i])), vsew_bits, vsew_bits),
          MVV_VMULHU       => slice(to_bits(vsew_bits * 2, unsigned(vs2_val[i]) * unsigned(vs1_val[i])), vsew_bits, vsew_bits),
          MVV_VMULHSU      => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * unsigned(vs1_val[i])), vsew_bits, vsew_bits),
          MVV_VDIVU        => {
                              let q : int = if unsigned(vs1_val[i]) == 0 then -1 else quot_round_zero(unsigned(vs2_val[i]), unsigned(vs1_val[i]));
                              to_bits(vsew_bits, q)
                            },
          MVV_VDIV         => {
                              let sew_max : int = 2 ^ (vsew_bits - 1) - 1;
                              let sew_min : int = 0 - 2 ^ (vsew_bits - 1);
                              let q : int = if signed(vs1_val[i]) == 0 then -1 else quot_round_zero(signed(vs2_val[i]), signed(vs1_val[i]));
                              /* check for signed overflow */
                              let q' : int = if q > sew_max then sew_min else q;
                              to_bits(vsew_bits, q')
                            },
          MVV_VREMU        => {
                              let r : int = if unsigned(vs1_val[i]) == 0 then unsigned(vs2_val[i]) else rem_round_zero(unsigned(vs2_val[i]), unsigned(vs1_val[i]));
                              /* signed overflow case returns zero naturally as required due to -1 divisor */
                              to_bits(vsew_bits, r)
                            },
          MVV_VREM         => {
                              let r : int = if signed(vs1_val[i]) == 0 then signed(vs2_val[i]) else rem_round_zero(signed(vs2_val[i]), signed(vs1_val[i]));
                              /* signed overflow case returns zero naturally as required due to -1 divisor */
                              to_bits(vsew_bits, r)
                            }
        }
        //print_int("result[i]=", signed(result[i]))
      }
    }
  };
  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  RETIRE_SUCCESS
}

mapping mvvtype_mnemonic : mvvfunct6 <-> string = {
  MVV_VAADDU   <-> "vaaddu.vv",
  MVV_VAADD    <-> "vaadd.vv",
  MVV_VASUBU   <-> "vasubu.vv",
  MVV_VASUB    <-> "vasub.vv",
  MVV_VMUL     <-> "vmul.vv",
  MVV_VMULH    <-> "vmulh.vv",
  MVV_VMULHU   <-> "vmulhu.vv",
  MVV_VMULHSU  <-> "vmulhsu.vv",
  MVV_VDIVU    <-> "vdivu.vv",
  MVV_VDIV     <-> "vdiv.vv",
  MVV_VREMU    <-> "vremu.vv",
  MVV_VREM     <-> "vrem.vv"
}

mapping clause assembly = MVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> mvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)  


/* ******************************OPMVV(MVVtype Multiply-Add)*********************************** */
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2) */

union clause ast = MVVMATYPE : (mvvmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvvmafunct6 : mvvmafunct6 <-> bits(6) = {
  MVV_VMACC       <-> 0b101101,
  MVV_VNMSAC      <-> 0b101111,
  MVV_VMADD       <-> 0b101001,
  MVV_VNMSUB      <-> 0b101011
}

mapping clause encdec = MVVMATYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> encdec_mvvmafunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd_or_rd @ 0b1010111

function clause execute(MVVMATYPE(funct6, vm, vs2, vs1, vd_or_rd)) = {
  status : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_or_rd_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd_or_rd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_or_rd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)){
      if mask_helper[i] == true then{
        //print("vs1_val[i]=" ^ BitStr(vs1_val[i]));
        //print("vs2_val[i]=" ^ BitStr(vs2_val[i]));
        result[i] = match funct6 {
        MVV_VMACC          => slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vs2_val[i]) ), 0, vsew_bits) + vd_or_rd_val[i],
        MVV_VNMSAC         => vd_or_rd_val[i] - slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vs2_val[i]) ), 0, vsew_bits),
        MVV_VMADD          => slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vd_or_rd_val[i]) ), 0, vsew_bits) + vs2_val[i],
        MVV_VNMSUB         => vs2_val[i] - slice(to_bits(sizeof(vlen) , signed(vs1_val[i]) * signed(vd_or_rd_val[i]) ), 0, vsew_bits)
        }
      }
    }
  };
  write_vreg(num_elem, vsew_bits, lmul, vd_or_rd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  RETIRE_SUCCESS
}

mapping mvvmatype_mnemonic : mvvmafunct6 <-> string = {
  MVV_VMACC    <-> "vmacc.vv",
  MVV_VNMSAC   <-> "vnmsac.vv",
  MVV_VMADD    <-> "vmadd.vv",
  MVV_VNMSUB   <-> "vnmsub.vv"
}

mapping clause assembly = MVVMATYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> mvvmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)  


/* *******************************OPMVX(MVXtype)********************************** */

union clause ast = MVXTYPE : (mvxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvxfunct6 : mvxfunct6 <-> bits(6) = {
  MVX_VAADDU        <-> 0b001000,
  MVX_VAADD         <-> 0b001001,
  MVX_VASUBU        <-> 0b001010,
  MVX_VASUB         <-> 0b001011,
  MVX_VSLIDE1UP     <-> 0b001110,
  MVX_VSLIDE1DOWN   <-> 0b001111,
  MVX_VMUL          <-> 0b100101,
  MVX_VMULH         <-> 0b100111,
  MVX_VMULHU        <-> 0b100100,
  MVX_VMULHSU       <-> 0b100110,
  MVX_VDIVU         <-> 0b100000,
  MVX_VDIV          <-> 0b100001,
  MVX_VREMU         <-> 0b100010,
  MVX_VREM          <-> 0b100011
}

mapping clause encdec = MVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_mvxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd @ 0b1010111 

function clause execute(MVXTYPE(funct6, vm, vs2, rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vd_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        MVX_VAADDU         => {
                                result_add = EXTZ('m + 1, vs2_val[i]) + EXTZ('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)                              
                              },
        MVX_VAADD          => {
                                result_add = EXTS('m + 1, vs2_val[i]) + EXTS('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_add, 1);
                                slice(result_add >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                              },
        MVX_VASUBU         => {
                                result_sub = EXTZ('m + 1, vs2_val[i]) - EXTZ('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)                               
                              },
        MVX_VASUB          => {
                                result_sub = EXTS('m + 1, vs2_val[i]) - EXTS('m + 1, rs1_val);
                                rounding_incr = get_fixed_rounding_incr(result_sub, 1);
                                slice(result_sub >> 1, 0, 'm) + EXTZ('m, rounding_incr)
                              },
        MVX_VSLIDE1UP      => {
                                assert(vs2 != vd);
                                if i == 0 then rs1_val else vs2_val[i - 1]
                              },
        MVX_VSLIDE1DOWN    => {
                                assert(vs2 != vd);
                                let last_elem = get_end_element();
                                assert(last_elem < num_elem);
                                if i < last_elem then vs2_val[i + 1] else rs1_val
                              },
        MVX_VMUL         => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(rs1_val)), 0, vsew_bits),
        MVX_VMULH        => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * signed(rs1_val)), vsew_bits, vsew_bits),
        MVX_VMULHU       => slice(to_bits(vsew_bits * 2, unsigned(vs2_val[i]) * unsigned(rs1_val)), vsew_bits, vsew_bits),
        MVX_VMULHSU      => slice(to_bits(vsew_bits * 2, signed(vs2_val[i]) * unsigned(rs1_val)), vsew_bits, vsew_bits),
        MVX_VDIVU        => {
                             let q : int = if unsigned(rs1_val) == 0 then -1 else quot_round_zero(unsigned(vs2_val[i]), unsigned(rs1_val));
                             to_bits(vsew_bits, q)
                           },
        MVX_VDIV         => {
                             let sew_max : int = 2 ^ (vsew_bits - 1) - 1;
                             let sew_min : int = 0 - 2 ^ (vsew_bits - 1);
                             let q : int = if signed(rs1_val) == 0 then -1 else quot_round_zero(signed(vs2_val[i]), signed(rs1_val));
                             /* check for signed overflow */
                             let q' : int = if q > sew_max then sew_min else q;
                             to_bits(vsew_bits, q')
                           },
        MVX_VREMU        => {
                             let r : int = if unsigned(rs1_val) == 0 then unsigned(vs2_val[i]) else rem_round_zero(unsigned(vs2_val[i]), unsigned(rs1_val));
                             /* signed overflow case returns zero naturally as required due to -1 divisor */
                             to_bits(vsew_bits, r)
                           },
        MVX_VREM         => {
                             let r : int = if signed(rs1_val) == 0 then signed(vs2_val[i]) else rem_round_zero(signed(vs2_val[i]), signed(rs1_val));
                             /* signed overflow case returns zero naturally as required due to -1 divisor */
                             to_bits(vsew_bits, r)
                           }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  RETIRE_SUCCESS
}

mapping mvxtype_mnemonic : mvxfunct6 <-> string = {
  MVX_VAADDU        <-> "vaaddu.vx",
  MVX_VAADD         <-> "vaadd.vx",
  MVX_VASUBU        <-> "vasubu.vx",
  MVX_VASUB         <-> "vasub.vx",
  MVX_VSLIDE1UP     <-> "vslide1up.vx",
  MVX_VSLIDE1DOWN   <-> "vslide1down.vx",
  MVX_VMUL          <-> "vmul.vx",
  MVX_VMULH         <-> "vmulh.vx",
  MVX_VMULHU        <-> "vmulhu.vx",
  MVX_VMULHSU       <-> "vmulhsu.vx",
  MVX_VDIVU         <-> "vdivu.vx",
  MVX_VDIV          <-> "vdiv.vx",
  MVX_VREMU         <-> "vremu.vx",
  MVX_VREM          <-> "vrem.vx"
}

mapping clause assembly = MVXTYPE(funct6, vm, vs2, rs1, vd)
  <-> mvxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm) 


/* *******************************OPMVX(MVXtype Multiply-Add)********************************** */
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2)  */

union clause ast = MVXMATYPE : (mvxmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_mvxmafunct6 : mvxmafunct6 <-> bits(6) = {
  MVX_VMACC         <-> 0b101101,
  MVX_VNMSAC        <-> 0b101111,
  MVX_VMADD         <-> 0b101001,
  MVX_VNMSUB        <-> 0b101011
}

mapping clause encdec = MVXMATYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> encdec_mvxmafunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd_or_rd @ 0b1010111 

function clause execute(MVXMATYPE(funct6, vm, vs2, rs1, vd_or_rd)) = {
  status : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vd_or_rd_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd_or_rd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if 
     vm_val      == undefined /*
    | vs2_val     == undefined |
     vd_val     == undefined   */
  then {
    status = RETIRE_FAIL;
    print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_or_rd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)){
      if mask_helper[i] == true then{
        result[i] = match funct6 {
        MVX_VMACC          => slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vs2_val[i]) ), 0, vsew_bits) + vd_or_rd_val[i],
        MVX_VNMSAC         => vd_or_rd_val[i] - slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vs2_val[i]) ), 0, vsew_bits),
        MVX_VMADD          => slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vd_or_rd_val[i]) ), 0, vsew_bits) + vs2_val[i],
        MVX_VNMSUB         => vs2_val[i] - slice(to_bits(sizeof(vlen) , signed(rs1_val) * signed(vd_or_rd_val[i]) ), 0, vsew_bits)
        }
      }
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd_or_rd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  RETIRE_SUCCESS
}

mapping mvxmatype_mnemonic : mvxmafunct6 <-> string = {
  MVX_VMACC         <-> "vmacc.vx",
  MVX_VNMSAC        <-> "vnmsac.vx",
  MVX_VMADD         <-> "vmadd.vx",
  MVX_VNMSUB        <-> "vnmsub.vx"
}

mapping clause assembly = MVXMATYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> mvxmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm) 


/* **************************OPMVV(MVVtype) Reduction********************************* */

 union clause ast = RMVVTYPE : (rmvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rmvvfunct6 : rmvvfunct6 <-> bits(6) = {
  MVV_VREDSUM     <-> 0b000000,
  MVV_VREDAND     <-> 0b000001,
  MVV_VREDOR      <-> 0b000010,
  MVV_VREDXOR     <-> 0b000011,
  MVV_VREDMINU    <-> 0b000100,
  MVV_VREDMIN     <-> 0b000101,
  MVV_VREDMAXU    <-> 0b000110,
  MVV_VREDMAX     <-> 0b000111
}

mapping clause encdec = RMVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_rmvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

val process_rmvv : forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rmvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rmvv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val   : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd); // only to generate mask_helper
  result       : vector('n, dec, bits('m))     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

  ans : bits('m) = read_single_element(vsew_bits, 0, lmul, vs1);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      ans = match funct6 {
        MVV_VREDSUM   => ans + vs2_val[i],
        MVV_VREDAND   => ans & vs2_val[i],
        MVV_VREDOR    => ans | vs2_val[i],
        MVV_VREDXOR   => ans ^ vs2_val[i],
        MVV_VREDMIN   => to_bits(vsew_bits, min(signed(vs2_val[i]), signed(ans))),
        MVV_VREDMINU  => to_bits(vsew_bits, min(unsigned(vs2_val[i]), unsigned(ans))),
        MVV_VREDMAX   => to_bits(vsew_bits, max(signed(vs2_val[i]), signed(ans))),
        MVV_VREDMAXU  => to_bits(vsew_bits, max(unsigned(vs2_val[i]), unsigned(ans)))
      }
    }
  };
  write_single_element(vsew_bits, 0, lmul, vd, ans);
  RETIRE_SUCCESS
}

function clause execute(RMVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  process_rmvv(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
}

mapping rmvvtype_mnemonic : rmvvfunct6 <-> string = {
  MVV_VREDSUM   <-> "vredsum.vs",
  MVV_VREDAND   <-> "vredand.vs",
  MVV_VREDOR    <-> "vredor.vs",
  MVV_VREDXOR   <-> "vredxor.vs",
  MVV_VREDMINU  <-> "vredminu.vs",
  MVV_VREDMIN   <-> "vredmin.vs",
  MVV_VREDMAXU  <-> "vredmaxu.vs",
  MVV_VREDMAX   <-> "vredmax.vs"
}

mapping clause assembly = RMVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rmvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)  


/* **************************OPMVV(MVVtype)Widened Multiply-Add******************************** */ 
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2) */

union clause ast = WMVVTYPE : (wmvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wmvvfunct6 : wmvvfunct6 <-> bits(6) = {
  WMVV_VWMACCU   <-> 0b111100,
  WMVV_VWMACC     <-> 0b111101,
  WMVV_VWMACCSU  <-> 0b111111
}

mapping clause encdec =  WMVVTYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> encdec_wmvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b010 @ vd_or_rd @ 0b1010111

val process_wmvv : forall 'n 'm, (8 <= 'm & 'm <= 64) & (0 <= 'n & 'n <= vlen) . (wmvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real ) -> Retired effect {escape, rreg, undef, wreg} 
function process_wmvv(funct6, vm, vs2, vs1, vd_or_rd, num_elem, vsew_bits, lmul) = {
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let double_vsew : int = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  assert(8 <= double_vsew & double_vsew <= 64);
  let 'o = double_vsew;
  let vd_or_rd_val : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd_or_rd);

  result : vector('n, dec, bits('o)) =  undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_or_rd_val, vm_val);

  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result[i] = match funct6 {
        WMVV_VWMACC       => to_bits( double_vsew, signed(vs1_val[i]) * signed(vs2_val[i]) ) + vd_or_rd_val[i],
      /*WMVV_VWMACCU      => double_bit_mul(vsew_bits, vs1_val[i], vs2_val[i]) + vd_or_rd_val[i],*/
        WMVV_VWMACCU      => to_bits( double_vsew, unsigned(vs1_val[i]) * unsigned(vs2_val[i]) ) + vd_or_rd_val[i], 
        WMVV_VWMACCSU     => to_bits( double_vsew, signed(vs1_val[i]) * unsigned(vs2_val[i]) )+ vd_or_rd_val[i]
      }
    }
  };

  write_vreg(num_elem, double_vsew, lmul, vd_or_rd, result);
  RETIRE_SUCCESS
}

function clause execute(WMVVTYPE(funct6, vm, vs2, vs1, vd_or_rd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  //assert(8 <= vsew_bits & vsew_bits <= 32);
  /* assert(vsew_bits >=8 & vsew_bits <= 64); */
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  process_wmvv(funct6, vm, vs2, vs1, vd_or_rd, num_elem, vsew_bits, lmul)
}

mapping wmvvtype_mnemonic : wmvvfunct6 <-> string = {
  WMVV_VWMACCU     <-> "vwmaccu.vv",
  WMVV_VWMACC      <-> "vwmacc.vv",
  WMVV_VWMACCSU    <-> "vwmaccsu.vv"
}

mapping clause assembly = WMVVTYPE(funct6, vm, vs2, vs1, vd_or_rd)
  <-> wmvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)  


/* **************************OPMVX(MVXtype)Widened Multiply-Add******************************** */ 
/* Multiply-Add instructions switch the order of two operands in assembly (vs1 / rs1 before vs2) */

union clause ast =  WMVXTYPE : (wmvxfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_wmvxfunct6 : wmvxfunct6 <-> bits(6) = {
  WMVX_VWMACCU    <-> 0b111100,
  WMVX_VWMACC     <-> 0b111101,
  WMVX_VWMACCUS   <-> 0b111110,
  WMVX_VWMACCSU   <-> 0b111111
}

mapping clause encdec = WMVXTYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> encdec_wmvxfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b110 @ vd_or_rd @ 0b1010111 

function clause execute(WMVXTYPE(funct6, vm, vs2, rs1, vd_or_rd)) = {
  status          : Retired = RETIRE_SUCCESS;
  let vsew_bits  : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let double_vsew : int  = vsew_bits * 2;
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);
  let double_lmul : real = lmul * 2.0;

  assert(8 <= vsew_bits & vsew_bits <= 64);
  /* assert(8 <= double_vsew & double_vsew <= 64);*/
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let 'o = double_vsew;
  assert(8 <= double_vsew & double_vsew <= 64);

  let vm_val : vector('n, dec, bool) = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_or_rd_val  : vector('n, dec, bits('o)) = read_vreg(num_elem, double_vsew, double_lmul, vd_or_rd);
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  result : vector('n, dec, bits('o)) = undefined;
  mask_helper : vector('n, dec, bool) = undefined;

  if vm_val == undefined  
  then {
    status = RETIRE_FAIL;
    //print("status=fail")
  };

  if status == RETIRE_SUCCESS then {
    (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_or_rd_val, vm_val);
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        //print_int("vs1=", signed(vs1_val[i]));
        //print_int("vs1=", signed(vs2_val[i]));
        result[i] = match funct6 {
          WMVX_VWMACCU      => (to_bits( double_vsew, unsigned(rs1_val) * unsigned(vs2_val[i]) )) + vd_or_rd_val[i],
          WMVX_VWMACC       => (to_bits( double_vsew, signed(rs1_val) * signed(vs2_val[i]) )) + vd_or_rd_val[i], 
          WMVX_VWMACCUS     => (to_bits( double_vsew, unsigned(rs1_val) * signed(vs2_val[i]) ))+ vd_or_rd_val[i],
          WMVX_VWMACCSU     => (to_bits( double_vsew, signed(rs1_val) * unsigned(vs2_val[i]) ))+ vd_or_rd_val[i]
        }
      }
    }
  };
  
  write_vreg(num_elem, double_vsew, lmul * 2.0, vd_or_rd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  
  status = vcheck_vsew_lmul(double_vsew, double_lmul);

  if status == RETIRE_FAIL then handle_illegal();
  status
}

mapping wmvxtype_mnemonic : wmvxfunct6 <-> string = {
  WMVX_VWMACCU     <-> "vwmaccu.vx",
  WMVX_VWMACC      <-> "vwmacc.vx",
  WMVX_VWMACCUS    <-> "vwmaccus.vx",
  WMVX_VWMACCSU    <-> "vwmaccsu.vx"
}

mapping clause assembly = WMVXTYPE(funct6, vm, vs2, rs1, vd_or_rd)
  <-> wmvxtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd_or_rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)  


/* **************************OPMVV(Vector Compress Instruction)*************************************** */

union clause ast = MVVCOMPRESS : (regidx, regidx, regidx)

mapping clause encdec = MVVCOMPRESS(vs2, vs1, vd)
  <-> 0b010111 @ 0b1 @ vs2 @ vs1 @ 0b010 @ vd @ 0b1010111

function clause execute(MVVCOMPRESS(vs2, vs1, vd)) = {
  let start_element : int = get_start_element();
  if start_element != 0 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int = get_num_elem(lmul, vsew_bits);

    assert(8 <= vsew_bits & vsew_bits <= 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    assert(vd != vs1 & vd != vs2);
    let 'n = num_elem;
    let 'm = vsew_bits; 

    /* vcompress should always be executed with a vstart of 0 */
    let start_element : int = get_start_element();
    let end_element   : int = get_end_element();
    assert(start_element == 0); 
    assert(end_element < num_elem);

    let vs1_val : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    /* body elements */
    vd_idx : int = 0;
    foreach (i from 0 to end_element) {
      if vs1_val[i] == true then {
        let 'p = vd_idx;
        assert(0 <= 'p & 'p < 'n);
        result['p] = vs2_val[i];
        vd_idx = vd_idx + 1;
      };
    };
    /* tail elements */
    if vd_idx < num_elem then {
      let tail_ag : agtype = get_vtype_vta();
      let 'p = vd_idx;
      if tail_ag == UNDISTURBED then {
        assert('p >= 0);
        foreach (i from 'p to (num_elem - 1)) result[i] = vd_val[i]
      }
      else if tail_ag == AGNOSTIC then {
        assert('p >= 0);
        foreach (i from 'p to (num_elem - 1)) {
          //result[i] = sail_sign_extend(0b1, vsew_bits)
          result[i] = vd_val[i]
        };
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping clause assembly = MVVCOMPRESS(vs2, vs1, vd)
  <-> "vcompress.vm" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)


/* *******************************OPMVV(VWXUNARY0)******************************** */

union clause ast = VMVXS : (regidx, regidx)

mapping clause encdec = VMVXS(vs2, rd)
  <-> 0b010000 @ 0b1 @ vs2 @ 0b00000 @ 0b010 @ rd @ 0b1010111

function clause execute(VMVXS(vs2, rd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 < num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  if sizeof(xlen) < vsew_bits then X(rd) = slice(vs2_val[0], 0, sizeof(xlen))
  else if sizeof(xlen) > vsew_bits then X(rd) = sail_sign_extend(vs2_val[0], sizeof(xlen))
  else X(rd) = vs2_val[0];
  //print("vs2_val[0]=" ^ BitStr(vs2_val[0]));
  //print("rd_val=" ^ BitStr(X(rd)));
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = VMVXS(vs2, rd)
  <-> "vmv.x.s" ^ spc() ^ reg_name(rd) ^ sep() ^ vreg_name(vs2)


/* *******************************OPMVX(VRXUNARY0)******************************** */

union clause ast = VMVSX : (regidx, regidx)

mapping clause encdec = VMVSX(rs1, vd)
  <-> 0b010000 @ 0b1 @ 0b00000 @ rs1 @ 0b110 @ vd @ 0b1010111

function clause execute(VMVSX(rs1, vd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let num_elem   : int  = get_num_elem(1.0, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 < num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let rs1_val = get_scalar(rs1, 'm);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, 1.0, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;

  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, 1.0, vd_val, vm_val);
  
  /* one body element */
  if mask_helper[0] == true then result[0] = rs1_val;

  /* others treated as tail elements */
  let tail_ag : agtype = get_vtype_vta();
  if tail_ag == UNDISTURBED then {
    foreach (i from 1 to (num_elem - 1)) result[i] = vd_val[i]
  }
  else if tail_ag == AGNOSTIC then {
    foreach (i from 1 to (num_elem - 1)) {
      //result[i] = sail_sign_extend(0b1, vsew_bits)
      result[i] = vd_val[i]
    }
  };

  write_vreg(num_elem, vsew_bits, 1.0, vd, result);
  RETIRE_SUCCESS
}

mapping clause assembly = VMVSX(rs1, vd)
  <-> "vmv.s.x" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)


/* **************************Mask instruction(OPIVV)*************************************** */

union clause ast = MASKTYPEV : (regidx, regidx, regidx)

mapping clause encdec = MASKTYPEV (vs2, vs1,  vd)
  <-> 0b010111 @ 0b0 @ vs2 @ vs1 @ 0b000 @ vd @ 0b1010111

val process_maskv : forall 'n 'm, 'm >= 8. (regidx, regidx, regidx, int('n), int('m)) -> Retired effect {escape, rreg, undef, wreg}
function process_maskv(vs2, vs1, vd, total_num_element, vsew_bits) = {
  let vs1_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs1));
  let vs2_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs2));
  let v0_val = V(vreg_id("v0"));

  result : vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (total_num_element - 1)) {
    if slice(v0_val, i, 1) == 0b0 then {
      result[i] = vs1_val[i]
    }
    else {
      result[i] = vs2_val[i]
    }
  };

  V(vd) = join_vreg(total_num_element, vsew_bits, result);

  RETIRE_SUCCESS
}

function clause execute(MASKTYPEV(vs2, vs1, vd)) = {
  let start_element : int = get_start_element();
  let vsew_bits  : int = get_vtype_vsew();
  let total_num_element : int = unsigned (readCSR(csr_name_map("vl")));
  assert(vsew_bits >= 8);
  process_maskv(vs2, vs1, vd, total_num_element, vsew_bits)
}

mapping clause assembly = MASKTYPEV(vs2, vs1, vd)
<-> "vmerge.vvm" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ sep() ^ "v0" 


/* **************************Mask instruction(OPIVX)*************************************** */

union clause ast = MASKTYPEX : (regidx, regidx, regidx)

mapping clause encdec = MASKTYPEX(vs2, rs1, vd)
  <-> 0b010111 @ 0b0 @ vs2 @ rs1 @ 0b100 @ vd @ 0b1010111

val process_maskx : forall 'n 'm, 'm >= 8. (regidx, regidx, regidx, int('n), int('m)) -> Retired effect {escape, rreg, undef, wreg}
function process_maskx(vs2, rs1, vd, total_num_element, vsew_bits) = {
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs2));
  let v0_val = V(vreg_id("v0"));

  result : vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (total_num_element - 1)) {
    if slice(v0_val, i, 1) == 0b0 then {
      result[i] = rs1_val
    }
    else {
      result[i] = vs2_val[i]
    }
  };

  V(vd) = join_vreg(total_num_element, vsew_bits, result);

  RETIRE_SUCCESS
}

function clause execute(MASKTYPEX(vs2, rs1, vd)) = {
  let start_element : int = get_start_element();
  let vsew_bits  : int = get_vtype_vsew();
  let total_num_element : int = unsigned (readCSR(csr_name_map("vl")));
  assert(vsew_bits >= 8);
  process_maskx(vs2, rs1, vd, total_num_element, vsew_bits)
}

mapping clause assembly = MASKTYPEX(vs2, rs1, vd)
  <-> "vmerge.vxm" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0" 


/* **************************Mask instruction(OPIVI)*************************************** */

union clause ast = MASKTYPEI : (regidx, bits(5), regidx)

mapping clause encdec = MASKTYPEI(vs2, simm, vd)
  <-> 0b010111 @ 0b0 @ vs2 @ simm @ 0b011 @ vd @ 0b1010111

val process_maski : forall 'n 'm, 'm >= 8. (regidx, bits(5), regidx, int('n), int('m)) -> Retired effect {escape, rreg, undef, wreg}
function process_maski(vs2, simm, vd, total_num_element, vsew_bits) = {
  let simm = sail_sign_extend(simm, vsew_bits);
  let vs2_val : vector('n, dec, bits('m)) = split_vreg(total_num_element, vsew_bits, V(vs2));
  let v0_val = V(vreg_id("v0"));

  result : vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (total_num_element - 1)) {
    if slice(v0_val, i, 1) == 0b0 then {
      result[i] = simm
    }
    else {
      result[i] = vs2_val[i]
    }
  };

  V(vd) = join_vreg(total_num_element, vsew_bits, result);

  RETIRE_SUCCESS
}

function clause execute(MASKTYPEI(vs2, simm, vd)) = {
  let start_element : int = get_start_element();
  let vsew_bits  : int = get_vtype_vsew();
  let total_num_element : int = unsigned (readCSR(csr_name_map("vl")));
  assert(vsew_bits >= 8);
  process_maski(vs2, simm, vd, total_num_element, vsew_bits)
}

mapping clause assembly = MASKTYPEI(vs2, simm, vd)
  <-> "vmerge.vim" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ hex_bits_5(simm) ^ sep() ^ "v0" 


/* **************************Integer move instruction(OPIVV)*************************************** */

union clause ast = MOVETYPEV : (regidx, regidx)

mapping clause encdec = MOVETYPEV (vs1, vd)
  <-> 0b010111 @ 0b1 @ 0b00000 @ vs1 @ 0b000 @ vd @ 0b1010111

function clause execute(MOVETYPEV(vs1, vd)) = {
  let vsew_bits  : int  = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)){
    if mask_helper[i] == true then{
      result[i] = vs1_val[i]
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEV(vs1, vd)
<-> "vmv.v.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs1)


/* **************************Integer move instruction(OPIVX)*************************************** */

union clause ast = MOVETYPEX : (regidx, regidx)

mapping clause encdec = MOVETYPEX (rs1, vd)
  <-> 0b010111 @ 0b1 @ 0b00000 @ rs1 @ 0b100 @ vd @ 0b1010111

function clause execute(MOVETYPEX(rs1, vd)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);
  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;
  let rs1_val = get_scalar(rs1, vsew_bits);
  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)){
    if mask_helper[i] == true then{
      result[i] = rs1_val
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEX(rs1, vd)
<-> "vmv.v.x" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)   


/* **************************Integer move instruction(OPIVI)*************************************** */

union clause ast = MOVETYPEI : (regidx, bits(5))

mapping clause encdec = MOVETYPEI (vd, simm)
  <-> 0b010111 @ 0b1 @ 0b00000 @ simm @ 0b011 @ vd @ 0b1010111

function clause execute(MOVETYPEI(vd, simm)) = {
  let vsew_bits  : int = get_vtype_vsew();
  let lmul       : real = get_vtype_LMUL();
  let num_elem   : int = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  let 'n = num_elem;
  let 'm = vsew_bits;

  let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
  let imm_val = sail_sign_extend(simm, vsew_bits);
  let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
  result      : vector('n, dec, bits('m)) = undefined;
  mask_helper : vector('n, dec, bool)     = undefined;
  
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
  foreach (i from 0 to (num_elem - 1)){
    if mask_helper[i] == true then{
      result[i] = imm_val
    }
  };

  write_vreg(num_elem, vsew_bits, lmul, vd, result);
  writeCSR(csr_name_map("vstart"), EXTZ(0b0));

  RETIRE_SUCCESS
}

mapping clause assembly = MOVETYPEI(vd, simm)
<-> "vmv.v.i" ^ spc() ^ vreg_name(vd) ^ sep() ^ hex_bits_5(simm)



/* *************************************instructions*********************************************** */
/* *************************************OPFVV(VVtype)********************************************** */

union clause ast = FVVTYPE : (fvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvvfunct6 : fvvfunct6 <-> bits(6) = {
  FVV_VADD       <-> 0b000000,
  FVV_VSUB       <-> 0b000010,
  FVV_VMIN       <-> 0b000100,
  FVV_VMAX       <-> 0b000110,
  FVV_VSGNJ      <-> 0b001000,
  FVV_VSGNJN     <-> 0b001001,
  FVV_VSGNJX     <-> 0b001010,
  FVV_VDIV       <-> 0b100000,
  FVV_VMUL       <-> 0b100100
}

mapping clause encdec = FVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_fvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

function clause execute(FVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);    
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          FVV_VADD     => fp_add(vs2_val[i], vs1_val[i]),
          FVV_VSUB     => fp_sub(vs2_val[i], vs1_val[i]),
          FVV_VMIN     => fp_min(vs2_val[i], vs1_val[i]),
          FVV_VMAX     => fp_max(vs2_val[i], vs1_val[i]),
          FVV_VMUL     => fp_mul(vs2_val[i], vs1_val[i]),
          FVV_VDIV     => fp_div(rm_3b, vs2_val[i], vs1_val[i]),
          FVV_VSGNJ    => vs1_val[i][('m - 1)..('m - 1)] @ vs2_val[i][('m - 2)..0],
          FVV_VSGNJN   => (0b1 ^ vs1_val[i][('m - 1)..('m - 1)]) @ vs2_val[i][('m - 2)..0],
          FVV_VSGNJX   => (vs2_val[i][('m - 1)..('m - 1)] ^ vs1_val[i][('m - 1)..('m - 1)]) @ vs2_val[i][('m - 2)..0]
        }; 
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fvvtype_mnemonic : fvvfunct6 <-> string = {
  FVV_VADD       <-> "vfadd.vv",
  FVV_VSUB       <-> "vfsub.vv",
  FVV_VMIN       <-> "vfmin.vv",
  FVV_VMAX       <-> "vfmax.vv",
  FVV_VSGNJ      <-> "vfsgnj.vv",
  FVV_VSGNJN     <-> "vfsgnjn.vv",
  FVV_VSGNJX     <-> "vfsgnjx.vv",
  FVV_VDIV       <-> "vfdiv.vv",
  FVV_VMUL       <-> "vfmul.vv"
}

mapping clause assembly = FVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> fvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* ***************************OPFVV(VVtype Multiply-Add)****************************** */
/* Multiply-Add instructions switch the order of two operands in assembly */

union clause ast = FVVMATYPE : (fvvmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvvmafunct6 : fvvmafunct6 <-> bits(6) = {
  FVV_VMADD      <-> 0b101000,
  FVV_VNMADD     <-> 0b101001,
  FVV_VMSUB      <-> 0b101010,
  FVV_VNMSUB     <-> 0b101011,
  FVV_VMACC      <-> 0b101100,
  FVV_VNMACC     <-> 0b101101,
  FVV_VMSAC      <-> 0b101110,
  FVV_VNMSAC     <-> 0b101111
}

mapping clause encdec = FVVMATYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_fvvmafunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

function clause execute(FVVMATYPE(funct6, vm, vs2, vs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);    
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          FVV_VMACC    => fp_muladd(vs1_val[i], vs2_val[i], vd_val[i]),
          FVV_VNMACC   => fp_nmulsub(vs1_val[i], vs2_val[i], vd_val[i]),
          FVV_VMSAC    => fp_mulsub(vs1_val[i], vs2_val[i], vd_val[i]),
          FVV_VNMSAC   => fp_nmuladd(vs1_val[i], vs2_val[i], vd_val[i]),
          FVV_VMADD    => fp_muladd(vs1_val[i], vd_val[i], vs2_val[i]),
          FVV_VNMADD   => fp_nmulsub(vs1_val[i], vd_val[i], vs2_val[i]),
          FVV_VMSUB    => fp_mulsub(vs1_val[i], vd_val[i], vs2_val[i]),
          FVV_VNMSUB   => fp_nmuladd(vs1_val[i], vd_val[i], vs2_val[i])
        }; 
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fvvmatype_mnemonic : fvvmafunct6 <-> string = {
  FVV_VMADD      <-> "vfmadd.vv",
  FVV_VNMADD     <-> "vfnmadd.vv",
  FVV_VMSUB      <-> "vfmsub.vv",
  FVV_VNMSUB     <-> "vfnmsub.vv",
  FVV_VMACC      <-> "vfmacc.vv",
  FVV_VNMACC     <-> "vfnmacc.vv",
  FVV_VMSAC      <-> "vfmsac.vv",
  FVV_VNMSAC     <-> "vfnmsac.vv"
}

mapping clause assembly = FVVMATYPE(funct6, vm, vs2, vs1, vd)
  <-> fvvmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* *******************************OPFVV(FVVMtype)******************************** */
/* FVVM instructions' destination is a mask register */

union clause ast = FVVMTYPE : (fvvmfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvvmfunct6 : fvvmfunct6 <-> bits(6) = {
  FVVM_VMFEQ      <-> 0b011000,
  FVVM_VMFLE      <-> 0b011001,
  FVVM_VMFLT      <-> 0b011011,
  FVVM_VMFNE      <-> 0b011100
}

mapping clause encdec = FVVMTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_fvvmfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

function clause execute(FVVMTYPE(funct6, vm, vs2, vs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);    
    result      : vector('n, dec, bool) = undefined;
    mask_helper : vector('n, dec, bool) = undefined;

    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          FVVM_VMFEQ    => fp_eq(vs2_val[i], vs1_val[i]),
          FVVM_VMFNE    => ~(fp_eq(vs2_val[i], vs1_val[i])),
          FVVM_VMFLE    => fp_le(vs2_val[i], vs1_val[i]),
          FVVM_VMFLT    => fp_lt(vs2_val[i], vs1_val[i])
        };
        result[i] = resval
      };
    };

    write_vmask(num_elem, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fvvmtype_mnemonic : fvvmfunct6 <-> string = {
  FVVM_VMFEQ      <-> "vmfeq.vv",
  FVVM_VMFLE      <-> "vmfle.vv",
  FVVM_VMFLT      <-> "vmflt.vv",
  FVVM_VMFNE      <-> "vmfne.vv"
}

mapping clause assembly = FVVMTYPE(funct6, vm, vs2, vs1, vd)
  <-> fvvmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* ****************************OPFVV(FVVtype) Reduction***************************** */

union clause ast = RFVVTYPE : (rfvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_rfvvfunct6 : rfvvfunct6 <-> bits(6) = {
  FVV_VFREDOSUM   <-> 0b000011,
  FVV_VFREDUSUM   <-> 0b000001,
  FVV_VFREDMAX    <-> 0b000111,
  FVV_VFREDMIN    <-> 0b000101,
  FVV_VFWREDOSUM  <-> 0b110011,
  FVV_VFWREDUSUM  <-> 0b110001
}

mapping clause encdec = RFVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_rfvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

val process_rfvv_single: forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rfvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rfvv_single(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  let vd_val   : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd); // only to generate mask_helper
  result       : vector('n, dec, bits('m))     = undefined;
  mask_helper  : vector('n, dec, bool)     = undefined;
  (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);

  vs1_0 : bits('m) = read_single_element(vsew_bits, 0, lmul, vs1);
  assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64 | vsew_bits == 128);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      vs1_0 = match funct6 {
        FVV_VFREDOSUM   => fp_add(vs1_0, vs2_val[i]),
        FVV_VFREDUSUM   => fp_add(vs1_0, vs2_val[i]),
        FVV_VFREDMAX    => fp_max(vs1_0, vs2_val[i]),
        FVV_VFREDMIN    => fp_min(vs1_0, vs2_val[i])
      };
    }
  };
  
  write_single_element(vsew_bits, 0, lmul, vd, vs1_0);
  RETIRE_SUCCESS
}


val process_rfvv_widen: forall 'n 'm, (8 <= 'm <= 64 & 0 <= 'n <= vlen). 
(rfvvfunct6, bits(1), regidx, regidx, regidx, int('n), int('m), real) -> Retired effect {escape, rreg, undef, wreg}
function process_rfvv_widen(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul) = {
  let double_vsew : int  = vsew_bits * 2;
  let double_lmul : real = lmul * 2.0;
  let 'double_vsew = double_vsew;
  let vs2_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
  let vm_val   : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
  assert ( vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64 );
  // assert ( 'double_vsew == 16 | 'double_vsew == 32 |'double_vsew == 64 |'double_vsew == 128 );
  assert ( 'double_vsew == 16 | 'double_vsew == 32 |'double_vsew == 64 );
  let vd_val   : vector('n, dec, bits('double_vsew)) = read_vreg(num_elem, double_vsew, double_lmul, vd); // only to generate mask_helper
  result       : vector('n, dec, bits('double_vsew)) = undefined;
  mask_helper  : vector('n, dec, bool)               = undefined;
  (result, mask_helper) = init_masked_result(num_elem, double_vsew, double_lmul, vd_val, vm_val);

  vs1_0 : bits('double_vsew) = read_single_element(double_vsew, 0, double_lmul, vs1);
  foreach (i from 0 to (num_elem - 1)) {
    if mask_helper[i] == true then {
      result_real : real = undefined;
      /* Currently Ordered/Unordered sum do the same operations */
      (fptype, sign, result_real) = fpreal_add(fp_to_real(vs2_val[i]), fp_to_real(vs1_0));
      vs1_0 = real_to_fp(result_real)
    }
  };
  
  write_single_element(double_vsew, 0, double_lmul, vd, vs1_0);
  RETIRE_SUCCESS
}

function clause execute(RFVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let vsew_bits   : int  = get_vtype_vsew();
  let lmul        : real = get_vtype_LMUL();
  let num_elem    : int  = get_num_elem(lmul, vsew_bits);

  assert(8 <= vsew_bits & vsew_bits <= 64);
  assert(0 <= num_elem & num_elem <= sizeof(vlen));
  if funct6 == FVV_VFWREDOSUM | funct6 == FVV_VFWREDUSUM then 
    process_rfvv_widen(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
  else
    process_rfvv_single(funct6, vm, vs2, vs1, vd, num_elem, vsew_bits, lmul)
}

mapping rfvvtype_mnemonic : rfvvfunct6 <-> string = {
  FVV_VFREDOSUM   <-> "vfredosum.vs",
  FVV_VFREDUSUM   <-> "vfredusum.vs",
  FVV_VFREDMAX    <-> "vfredmax.vs",
  FVV_VFREDMIN    <-> "vfredmin.vs",
  FVV_VFWREDOSUM  <-> "vfwredosum.vs",
  FVV_VFWREDUSUM  <-> "vfwredusum.vs"
}

mapping clause assembly = RFVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> rfvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* ****************************OPFVV(FVVtype)Widened****************************** */

union clause ast = FWVVTYPE : (fwvvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fwvvfunct6 : fwvvfunct6 <-> bits(6) = {
  FWVV_VADD       <-> 0b110000,
  FWVV_VSUB       <-> 0b110010,
  FWVV_VMUL       <-> 0b111000
}

mapping clause encdec = FWVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_fwvvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

function clause execute(FWVVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd);
    result      : vector('n, dec, bits('m * 2)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits * 2, lmul * 2.0, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result_real : real = undefined;
        result[i] = match funct6 {
          FWVV_VADD    => {
                            (fptype, sign, result_real) = fpreal_add(fp_to_real(vs2_val[i]), fp_to_real(vs1_val[i]));
                            real_to_fp(result_real)
                          },
          FWVV_VSUB    => {
                            (fptype, sign, result_real) = fpreal_sub(fp_to_real(vs2_val[i]), fp_to_real(vs1_val[i]));
                            real_to_fp(result_real)
                          },
          FWVV_VMUL    => {
                            (fptype, sign, result_real) = fpreal_mul(fp_to_real(vs2_val[i]), fp_to_real(vs1_val[i]));
                            real_to_fp(result_real)
                          }
        };
      };
    };

    write_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fwvvtype_mnemonic : fwvvfunct6 <-> string = {
  FWVV_VADD       <-> "vfwadd.vv",
  FWVV_VSUB       <-> "vfwsub.vv",
  FWVV_VMUL       <-> "vfwmul.vv"
}

mapping clause assembly = FWVVTYPE(funct6, vm, vs2, vs1, vd)
  <-> fwvvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* *********************OPFVV(FVVtype)Widened Multiply-Add************************* */
/* Multiply-Add instructions switch the order of two operands */

union clause ast = FWVVMATYPE : (fwvvmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fwvvmafunct6 : fwvvmafunct6 <-> bits(6) = {
  FWVV_VMACC      <-> 0b111100,
  FWVV_VNMACC     <-> 0b111101,
  FWVV_VMSAC      <-> 0b111110,
  FWVV_VNMSAC     <-> 0b111111
}

mapping clause encdec = FWVVMATYPE(funct6, vm, vs1, vs2, vd)
  <-> encdec_fwvvmafunct6(funct6) @ vm @ vs1 @ vs2 @ 0b001 @ vd @ 0b1010111

function clause execute(FWVVMATYPE(funct6, vm, vs1, vs2, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;
 
    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd);
    result      : vector('n, dec, bits('m * 2)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits * 2, lmul * 2.0, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result_real : real = undefined;
        result[i] = match funct6 {
          FWVV_VMACC    => {
                             (fptype, sign, result_real) = fpreal_muladd(fp_to_real(vs1_val[i]), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           },
          FWVV_VNMACC   => {
                             (fptype, sign, result_real) = fpreal_nmulsub(fp_to_real(vs1_val[i]), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           },
          FWVV_VMSAC    => {
                             (fptype, sign, result_real) = fpreal_mulsub(fp_to_real(vs1_val[i]), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           },
          FWVV_VNMSAC   => {
                             (fptype, sign, result_real) = fpreal_nmuladd(fp_to_real(vs1_val[i]), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           }
        };
      };
    };

    write_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fwvvmatype_mnemonic : fwvvmafunct6 <-> string = {
  FWVV_VMACC      <-> "vfwmacc.vv",
  FWVV_VNMACC     <-> "vfwnmacc.vv",
  FWVV_VMSAC      <-> "vfwmsac.vv",
  FWVV_VNMSAC     <-> "vfwnmsac.vv"
}

mapping clause assembly = FWVVMATYPE(funct6, vm, vs1, vs2, vd)
  <-> fwvvmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* *******************************FWVTYPE*********************************** */

union clause ast = FWVTYPE : (fwvfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fwvfunct6 : fwvfunct6 <-> bits(6) = {
  FWV_VADD       <-> 0b110100,
  FWV_VSUB       <-> 0b110110
}

mapping clause encdec = FWVTYPE(funct6, vm, vs2, vs1, vd)
  <-> encdec_fwvfunct6(funct6) @ vm @ vs2 @ vs1 @ 0b001 @ vd @ 0b1010111

function clause execute(FWVTYPE(funct6, vm, vs2, vs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    let 'n = num_elem;
    let 'm = vsew_bits;

    assert(vsew_bits == 16 | vsew_bits == 32);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs1_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs1);
    let vs2_val : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vs2);
    let vd_val  : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd);
    result      : vector('n, dec, bits('m * 2)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits * 2, lmul * 2.0, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result_real : real = undefined;
        result[i] = match funct6 {
          FWV_VADD     => {
                            (fptype, sign, result_real) = fpreal_add(fp_to_real(vs2_val[i]), fp_to_real(vs1_val[i]));
                            real_to_fp(result_real)
                          },
          FWV_VSUB     => {
                            (fptype, sign, result_real) = fpreal_sub(fp_to_real(vs2_val[i]), fp_to_real(vs1_val[i]));
                            real_to_fp(result_real)
                          }
        };
      };
    };

    write_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fwvtype_mnemonic : fwvfunct6 <-> string = {
  FWV_VADD       <-> "vfwadd.wv",
  FWV_VSUB       <-> "vfwsub.wv"
}

mapping clause assembly = FWVTYPE(funct6, vm, vs2, vs1, vd)
  <-> fwvtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)


/* *******************************OPFVV(VFUNARY0)******************************** */

union clause ast = VFUNARY0 : (bits(1), regidx, vfunary0, regidx)

mapping encdec_vfunary0_vs1 : vfunary0 <-> bits(5) = {
  FV_CVT_XU_F       <-> 0b00000,
  FV_CVT_X_F        <-> 0b00001,
  FV_CVT_F_XU       <-> 0b00010,
  FV_CVT_F_X        <-> 0b00011,
  FV_CVT_RTZ_XU_F   <-> 0b00110,
  FV_CVT_RTZ_X_F    <-> 0b00111
}

mapping clause encdec = VFUNARY0(vm, vs2, vfunary0, vd)
  <-> 0b010010 @ vm @ vs2 @ encdec_vfunary0_vs1(vfunary0) @ 0b001 @ vd @ 0b1010111

function clause execute(VFUNARY0(vm, vs2, vfunary0, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        fflags : bits_fflags = undefined;
        result_val : bits('m) = undefined;
        result[i] = match vfunary0 {
          FV_CVT_XU_F      => {
                                (fflags, result_val) = match 'm {
                                  32 => riscv_f32ToUi32(rm_3b, vs2_val[i]),
                                  64 => riscv_f64ToUi64(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val                                
                              },
          FV_CVT_X_F       => {
                                (fflags, result_val) = match 'm {
                                  32 => riscv_f32ToI32(rm_3b, vs2_val[i]),
                                  64 => riscv_f64ToI64(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val                                
                              },
          FV_CVT_F_XU      => {
                                (fflags, result_val) = match 'm {
                                  32 => riscv_ui32ToF32(rm_3b, vs2_val[i]),
                                  64 => riscv_ui64ToF64(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FV_CVT_F_X       => {
                                (fflags, result_val) = match 'm {
                                  32 => riscv_i32ToF32(rm_3b, vs2_val[i]),
                                  64 => riscv_i64ToF64(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val                                
                              },
          FV_CVT_RTZ_XU_F  => {
                                (fflags, result_val) = match 'm {
                                  32 => riscv_f32ToUi32(0b001, vs2_val[i]),
                                  64 => riscv_f64ToUi64(0b001, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FV_CVT_RTZ_X_F   => {
                                (fflags, result_val) = match 'm {
                                  32 => riscv_f32ToI32(0b001, vs2_val[i]),
                                  64 => riscv_f64ToI64(0b001, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              }
        };
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping vfunary0_mnemonic : vfunary0 <-> string = {
  FV_CVT_XU_F       <-> "vfcvt.xu.f.v",
  FV_CVT_X_F        <-> "vfcvt.x.f.v",
  FV_CVT_F_XU       <-> "vfcvt.f.xu.v",
  FV_CVT_F_X        <-> "vfcvt.f.x.v",
  FV_CVT_RTZ_XU_F   <-> "vfcvt.rtz.xu.f.v",
  FV_CVT_RTZ_X_F    <-> "vfcvt.rtz.x.f.v"
}

mapping clause assembly = VFUNARY0(vm, vs2, vfunary0, vd)
  <-> vfunary0_mnemonic(vfunary0) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* ****************************OPFVV(VFUNARY0)Widened***************************** */

union clause ast = VFWUNARY0 : (bits(1), regidx, vfwunary0, regidx)

mapping encdec_vfwunary0_vs1 : vfwunary0 <-> bits(5) = {
  FWV_CVT_XU_F      <-> 0b01000,
  FWV_CVT_X_F       <-> 0b01001,
  FWV_CVT_F_XU      <-> 0b01010,
  FWV_CVT_F_X       <-> 0b01011,
  FWV_CVT_F_F       <-> 0b01100,
  FWV_CVT_RTZ_XU_F  <-> 0b01110,
  FWV_CVT_RTZ_X_F   <-> 0b01111
}

mapping clause encdec = VFWUNARY0(vm, vs2, vfwunary0, vd)
  <-> 0b010010 @ vm @ vs2 @ encdec_vfwunary0_vs1(vfwunary0) @ 0b001 @ vd @ 0b1010111

function clause execute(VFWUNARY0(vm, vs2, vfwunary0, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd);
    result      : vector('n, dec, bits('m * 2)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits * 2, lmul * 2.0, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        fflags : bits_fflags = undefined;
        result_val : bits('m * 2) = undefined;
        result[i] = match vfwunary0 {
          FWV_CVT_XU_F     => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_f16ToUi32(rm_3b, vs2_val[i]),
                                  32 => riscv_f32ToUi64(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val                                
                              },
          FWV_CVT_X_F      => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_f16ToI32(rm_3b, vs2_val[i]),
                                  32 => riscv_f32ToI64(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FWV_CVT_F_XU     => {
                                assert('m == 32);
                                (fflags, result_val) = riscv_ui32ToF64(rm_3b, vs2_val[i]);
                                write_fflags(fflags);
                                result_val
                              },
          FWV_CVT_F_X      => {
                                assert('m == 32);
                                (fflags, result_val) = riscv_i32ToF64(rm_3b, vs2_val[i]);
                                write_fflags(fflags);
                                result_val
                              },
          FWV_CVT_F_F      => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_f16ToF32(rm_3b, vs2_val[i]),
                                  32 => riscv_f32ToF64(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FWV_CVT_RTZ_XU_F => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_f16ToUi32(0b001, vs2_val[i]),
                                  32 => riscv_f32ToUi64(0b001, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FWV_CVT_RTZ_X_F  => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_f16ToI32(0b001, vs2_val[i]),
                                  32 => riscv_f32ToI64(0b001, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              }   
        };
      };
    };

    write_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping vfwunary0_mnemonic : vfwunary0 <-> string = {
  FWV_CVT_XU_F      <-> "vfwcvt.xu.f.v",
  FWV_CVT_X_F       <-> "vfwcvt.x.f.v",
  FWV_CVT_F_XU      <-> "vfwcvt.f.xu.v",
  FWV_CVT_F_X       <-> "vfwcvt.f.x.v",
  FWV_CVT_F_F       <-> "vfwcvt.f.f.v",
  FWV_CVT_RTZ_XU_F  <-> "vfwcvt.rtz.xu.f.v",
  FWV_CVT_RTZ_X_F   <-> "vfwcvt.rtz.x.f.v"
}

mapping clause assembly = VFWUNARY0(vm, vs2, vfwunary0, vd)
  <-> vfwunary0_mnemonic(vfwunary0) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* ***************************OPFVV(VFUNARY0)Narrowing**************************** */

union clause ast = VFNUNARY0 : (bits(1), regidx, vfnunary0, regidx)

mapping encdec_vfnunary0_vs1 : vfnunary0 <-> bits(5) = {
  FNV_CVT_XU_F      <-> 0b10000,
  FNV_CVT_X_F       <-> 0b10001,
  FNV_CVT_F_XU      <-> 0b10010,
  FNV_CVT_F_X       <-> 0b10011,
  FNV_CVT_F_F       <-> 0b10100,
  FNV_CVT_ROD_F_F   <-> 0b10101,
  FNV_CVT_RTZ_XU_F  <-> 0b10110,
  FNV_CVT_RTZ_X_F   <-> 0b10111
}

mapping clause encdec = VFNUNARY0(vm, vs2, vfnunary0, vd)
  <-> 0b010010 @ vm @ vs2 @ encdec_vfnunary0_vs1(vfnunary0) @ 0b001 @ vd @ 0b1010111

function clause execute(VFNUNARY0(vm, vs2, vfnunary0, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs2_val : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        fflags : bits_fflags = undefined;
        result_val : bits('m) = undefined;
        result[i] = match vfnunary0 {
          FNV_CVT_XU_F     => {
                                assert('m == 32);
                                (fflags, result_val) = riscv_f64ToUi32(rm_3b, vs2_val[i]);
                                write_fflags(fflags);
                                result_val
                              },
          FNV_CVT_X_F      => {
                                assert('m == 32);
                                (fflags, result_val) = riscv_f64ToI32(rm_3b, vs2_val[i]);
                                write_fflags(fflags);
                                result_val
                              },
          FNV_CVT_F_XU     => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_ui32ToF16(rm_3b, vs2_val[i]),
                                  32 => riscv_ui64ToF32(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FNV_CVT_F_X      => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_i32ToF16(rm_3b, vs2_val[i]),
                                  32 => riscv_i64ToF32(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FNV_CVT_F_F      => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_f32ToF16(rm_3b, vs2_val[i]),
                                  32 => riscv_f64ToF32(rm_3b, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FNV_CVT_ROD_F_F  => {
                                (fflags, result_val) = match 'm {
                                  16 => riscv_f32ToF16(0b110, vs2_val[i]),
                                  32 => riscv_f64ToF32(0b110, vs2_val[i])
                                };
                                write_fflags(fflags);
                                result_val
                              },
          FNV_CVT_RTZ_XU_F => {
                                assert('m == 32);
                                (fflags, result_val) = riscv_f64ToUi32(0b001, vs2_val[i]);
                                write_fflags(fflags);
                                result_val
                              },
          FNV_CVT_RTZ_X_F  => {
                                assert('m == 32);
                                (fflags, result_val) = riscv_f64ToI32(0b001, vs2_val[i]);
                                write_fflags(fflags);
                                result_val
                              } 
        };
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping vfnunary0_mnemonic : vfnunary0 <-> string = {
  FNV_CVT_XU_F      <-> "vfncvt.xu.f.w",
  FNV_CVT_X_F       <-> "vfncvt.x.f.w",
  FNV_CVT_F_XU      <-> "vfncvt.f.xu.w",
  FNV_CVT_F_X       <-> "vfncvt.f.x.w",
  FNV_CVT_F_F       <-> "vfncvt.f.f.w",
  FNV_CVT_ROD_F_F   <-> "vfncvt.rod.f.f.w",
  FNV_CVT_RTZ_XU_F  <-> "vfncvt.rtz.xu.f.w",
  FNV_CVT_RTZ_X_F   <-> "vfncvt.rtz.x.f.w"
}

mapping clause assembly = VFNUNARY0(vm, vs2, vfnunary0, vd)
  <-> vfnunary0_mnemonic(vfnunary0) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* *******************************OPFVV(VFUNARY1)******************************** */

union clause ast = VFUNARY1 : (bits(1), regidx, vfunary1, regidx)

mapping encdec_vfunary1_vs1 : vfunary1 <-> bits(5) = {
  FVV_VSQRT       <-> 0b00000,
  FVV_VRSQRT7     <-> 0b00100,
  FVV_VREC7       <-> 0b00101,
  FVV_VCLASS      <-> 0b10000
}

mapping clause encdec = VFUNARY1(vm, vs2, vfunary1, vd)
  <-> 0b010011 @ vm @ vs2 @ encdec_vfunary1_vs1(vfunary1) @ 0b001 @ vd @ 0b1010111

function clause execute(VFUNARY1(vm, vs2, vfunary1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match vfunary1 {
          FVV_VSQRT      => {
                              fflags : bits_fflags = undefined;
                              result_val : bits('m) = undefined;
                              (fflags, result_val) = match 'm {
                                16  => riscv_f16Sqrt(rm_3b, vs2_val[i]),
                                32  => riscv_f32Sqrt(rm_3b, vs2_val[i]),
                                64  => riscv_f64Sqrt(rm_3b, vs2_val[i])
                              };
                              write_fflags(fflags);
                              result_val
                            },
          FVV_VRSQRT7    => {
                              fflags : bits_fflags = undefined;
                              result_val : bits('m) = undefined;
                              (fflags, result_val) = match 'm {
                                16  => riscv_f16Rsqrte7(rm_3b, vs2_val[i]),
                                32  => riscv_f32Rsqrte7(rm_3b, vs2_val[i]),
                                64  => riscv_f64Rsqrte7(rm_3b, vs2_val[i])
                              };
                              write_fflags(fflags);
                              result_val
                            },
          FVV_VREC7      => {
                              fflags : bits_fflags = undefined;
                              result_val : bits('m) = undefined;
                              (fflags, result_val) = match 'm {
                                16  => riscv_f16Recip7(rm_3b, vs2_val[i]),
                                32  => riscv_f32Recip7(rm_3b, vs2_val[i]),
                                64  => riscv_f64Recip7(rm_3b, vs2_val[i])
                              };
                              write_fflags(fflags);
                              result_val
                            },         
          FVV_VCLASS     => fp_class(vs2_val[i])
        };
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping vfunary1_mnemonic : vfunary1 <-> string = {
  FVV_VSQRT       <-> "vfsqrt.v",
  FVV_VRSQRT7     <-> "vfrsqrt7.v",
  FVV_VREC7       <-> "vfrec7.v",  
  FVV_VCLASS      <-> "vfclass.v"
}

mapping clause assembly = VFUNARY1(vm, vs2, vfunary1, vd)
  <-> vfunary1_mnemonic(vfunary1) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ maybe_vmask(vm)


/* *************************************instructions*********************************************** */
/* *************************************OPFVF(VFtype)********************************************** */

union clause ast = FVFTYPE : (fvffunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvffunct6 : fvffunct6 <-> bits(6) = {
  VF_VADD          <-> 0b000000,
  VF_VSUB          <-> 0b000010,
  VF_VMIN          <-> 0b000100,
  VF_VMAX          <-> 0b000110,
  VF_VSGNJ         <-> 0b001000,
  VF_VSGNJN        <-> 0b001001,
  VF_VSGNJX        <-> 0b001010,
  VF_VSLIDE1UP     <-> 0b001110,
  VF_VSLIDE1DOWN   <-> 0b001111,
  VF_VDIV          <-> 0b100000,
  VF_VRDIV         <-> 0b100001,
  VF_VMUL          <-> 0b100100,
  VF_VRSUB         <-> 0b100111
}

mapping clause encdec = FVFTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_fvffunct6(funct6) @ vm @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(FVFTYPE(funct6, vm, vs2, rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VF_VADD          => fp_add(vs2_val[i], rs1_val),
          VF_VSUB          => fp_sub(vs2_val[i], rs1_val),
          VF_VRSUB         => fp_sub(rs1_val, vs2_val[i]),
          VF_VMIN          => fp_min(vs2_val[i], rs1_val),
          VF_VMAX          => fp_max(vs2_val[i], rs1_val),
          VF_VMUL          => fp_mul(vs2_val[i], rs1_val),
          VF_VDIV          => fp_div(rm_3b, vs2_val[i], rs1_val),
          VF_VRDIV         => fp_div(rm_3b, rs1_val, vs2_val[i]),
          VF_VSGNJ         => rs1_val[('m - 1)..('m - 1)] @ vs2_val[i][('m - 2)..0],
          VF_VSGNJN        => (0b1 ^ rs1_val[('m - 1)..('m - 1)]) @ vs2_val[i][('m - 2)..0],
          VF_VSGNJX        => (vs2_val[i][('m - 1)..('m - 1)] ^ rs1_val[('m - 1)..('m - 1)]) @ vs2_val[i][('m - 2)..0],
          VF_VSLIDE1UP     => {
                                assert(vs2 != vd);
                                if i == 0 then rs1_val else vs2_val[i - 1]
                              },
          VF_VSLIDE1DOWN   => {
                                assert(vs2 != vd);
                                let last_elem = get_end_element();
                                assert(last_elem < num_elem);
                                if i < last_elem then vs2_val[i + 1] else rs1_val
                              }
        }
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fvftype_mnemonic : fvffunct6 <-> string = {
  VF_VADD          <-> "vfadd.vf",
  VF_VSUB          <-> "vfsub.vf",
  VF_VMIN          <-> "vfmin.vf",
  VF_VMAX          <-> "vfmax.vf",
  VF_VSGNJ         <-> "vfsgnj.vf",
  VF_VSGNJN        <-> "vfsgnjn.vf",
  VF_VSGNJX        <-> "vfsgnjx.vf",
  VF_VSLIDE1UP     <-> "vfslide1up.vf",
  VF_VSLIDE1DOWN   <-> "vfslide1down.vf",
  VF_VDIV          <-> "vfdiv.vf",
  VF_VRDIV         <-> "vfrdiv.vf",
  VF_VMUL          <-> "vfmul.vf",
  VF_VRSUB         <-> "vfrsub.vf"
}

mapping clause assembly = FVFTYPE(funct6, vm, vs2, rs1, vd)
  <-> fvftype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* *******************************OPFVF(VFtype Multiply-Add)**************************************** */
/* Multiply-Add instructions switch the order of two operands in assembly */

union clause ast = FVFMATYPE : (fvfmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvfmafunct6 : fvfmafunct6 <-> bits(6) = {
  VF_VMADD      <-> 0b101000,
  VF_VNMADD     <-> 0b101001,
  VF_VMSUB      <-> 0b101010,
  VF_VNMSUB     <-> 0b101011,
  VF_VMACC      <-> 0b101100,
  VF_VNMACC     <-> 0b101101,
  VF_VMSAC      <-> 0b101110,
  VF_VNMSAC     <-> 0b101111
}

mapping clause encdec = FVFMATYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_fvfmafunct6(funct6) @ vm @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(FVFMATYPE(funct6, vm, vs2, rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result[i] = match funct6 {
          VF_VMACC    => fp_muladd(rs1_val, vs2_val[i], vd_val[i]),
          VF_VNMACC   => fp_nmulsub(rs1_val, vs2_val[i], vd_val[i]),
          VF_VMSAC    => fp_mulsub(rs1_val, vs2_val[i], vd_val[i]),
          VF_VNMSAC   => fp_nmuladd(rs1_val, vs2_val[i], vd_val[i]),
          VF_VMADD    => fp_muladd(rs1_val, vd_val[i], vs2_val[i]),
          VF_VNMADD   => fp_nmulsub(rs1_val, vd_val[i], vs2_val[i]),
          VF_VMSUB    => fp_mulsub(rs1_val, vd_val[i], vs2_val[i]),
          VF_VNMSUB   => fp_nmuladd(rs1_val, vd_val[i], vs2_val[i])
        };
      };
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fvfmatype_mnemonic : fvfmafunct6 <-> string = {
  VF_VMADD      <-> "vfmadd.vf",
  VF_VNMADD     <-> "vfnmadd.vf",
  VF_VMSUB      <-> "vfmsub.vf",
  VF_VNMSUB     <-> "vfnmsub.vf",
  VF_VMACC      <-> "vfmacc.vf",
  VF_VNMACC     <-> "vfnmacc.vf",
  VF_VMSAC      <-> "vfmsac.vf",
  VF_VNMSAC     <-> "vfnmsac.vf"
}

mapping clause assembly = FVFMATYPE(funct6, vm, vs2, rs1, vd)
  <-> fvfmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* *******************************OPFVF(VFMtype)******************************** */
/* VFM instructions' destination is a mask register */

union clause ast = FVFMTYPE : (fvfmfunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fvfmfunct6 : fvfmfunct6 <-> bits(6) = {
  VFM_VMFEQ      <-> 0b011000,
  VFM_VMFLE      <-> 0b011001,
  VFM_VMFLT      <-> 0b011011,
  VFM_VMFNE      <-> 0b011100,
  VFM_VMFGT      <-> 0b011101,
  VFM_VMFGE      <-> 0b011111
}

mapping clause encdec = FVFMTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_fvfmfunct6(funct6) @ vm @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(FVFMTYPE(funct6, vm, vs2, rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bool) = read_vmask(num_elem, 0b0, vd);    
    result      : vector('n, dec, bool) = undefined;
    mask_helper : vector('n, dec, bool) = undefined;

    (result, mask_helper) = init_masked_result_cmp(num_elem, vsew_bits, lmul, vd_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        let resval : bool = match funct6 {
          VFM_VMFEQ    => fp_eq(vs2_val[i], rs1_val),
          VFM_VMFNE    => ~(fp_eq(vs2_val[i], rs1_val)),
          VFM_VMFLE    => fp_le(vs2_val[i], rs1_val),
          VFM_VMFLT    => fp_lt(vs2_val[i], rs1_val),
          VFM_VMFGE    => fp_ge(vs2_val[i], rs1_val),
          VFM_VMFGT    => fp_gt(vs2_val[i], rs1_val)
        };
        result[i] = resval
      };
    };

    write_vmask(num_elem, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fvfmtype_mnemonic : fvfmfunct6 <-> string = {
  VFM_VMFEQ      <-> "vmfeq.vf",
  VFM_VMFLE      <-> "vmfle.vf",
  VFM_VMFLT      <-> "vmflt.vf",
  VFM_VMFNE      <-> "vmfne.vf",
  VFM_VMFGT      <-> "vmfgt.vf",
  VFM_VMFGE      <-> "vmfge.vf"
}

mapping clause assembly = FVFMTYPE(funct6, vm, vs2, rs1, vd)
  <-> fvfmtype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* ****************************OPFVF(FVFtype)Widened****************************** */

union clause ast = FWVFTYPE : (fwvffunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fwvffunct6 : fwvffunct6 <-> bits(6) = {
  FWVF_VADD       <-> 0b110000,
  FWVF_VSUB       <-> 0b110010,
  FWVF_VMUL       <-> 0b111000
}

mapping clause encdec = FWVFTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_fwvffunct6(funct6) @ vm @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(FWVFTYPE(funct6, vm, vs2, rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32);

    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd);
    result      : vector('n, dec, bits('m * 2)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits * 2, lmul * 2.0, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result_real : real = undefined;
        result[i] = match funct6 {
          FWVF_VADD    => {
                            (fptype, sign, result_real) = fpreal_add(fp_to_real(vs2_val[i]), fp_to_real(rs1_val));
                            real_to_fp(result_real)
                          },
          FWVF_VSUB    => {
                            (fptype, sign, result_real) = fpreal_sub(fp_to_real(vs2_val[i]), fp_to_real(rs1_val));
                            real_to_fp(result_real)
                          },
          FWVF_VMUL    => {
                             (fptype, sign, result_real) = fpreal_mul(fp_to_real(vs2_val[i]), fp_to_real(rs1_val));
                             real_to_fp(result_real)
                          }
        };
      };
    };

    write_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fwvftype_mnemonic : fwvffunct6 <-> string = {
  FWVF_VADD       <-> "vfwadd.vf",
  FWVF_VSUB       <-> "vfwsub.vf",
  FWVF_VMUL       <-> "vfwmul.vf"
}

mapping clause assembly = FWVFTYPE(funct6, vm, vs2, rs1, vd)
  <-> fwvftype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* *********************OPFVF(FVFtype)Widened Multiply-Add*********************** */
/* Multiply-Add instructions switch the order of two operands */

union clause ast = FWVFMATYPE : (fwvfmafunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fwvfmafunct6 : fwvfmafunct6 <-> bits(6) = {
  FWVF_VMACC      <-> 0b111100,
  FWVF_VNMACC     <-> 0b111101,
  FWVF_VMSAC      <-> 0b111110,
  FWVF_VNMSAC     <-> 0b111111
}

mapping clause encdec = FWVFMATYPE(funct6, vm, rs1, vs2, vd)
  <-> encdec_fwvfmafunct6(funct6) @ vm @ rs1 @ vs2 @ 0b101 @ vd @ 0b1010111

function clause execute(FWVFMATYPE(funct6, vm, rs1, vs2, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd);
    result      : vector('n, dec, bits('m * 2)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits * 2, lmul * 2.0, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result_real : real = undefined;
        result[i] = match funct6 {
          FWVF_VMACC    => {
                             (fptype, sign, result_real) = fpreal_muladd(fp_to_real(rs1_val), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           },
          FWVF_VNMACC   => {
                             (fptype, sign, result_real) = fpreal_nmulsub(fp_to_real(rs1_val), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           },
          FWVF_VMSAC    => {
                             (fptype, sign, result_real) = fpreal_mulsub(fp_to_real(rs1_val), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           },
          FWVF_VNMSAC   => {
                             (fptype, sign, result_real) = fpreal_nmuladd(fp_to_real(rs1_val), fp_to_real(vs2_val[i]), fp_to_real(vd_val[i]));
                             real_to_fp(result_real)
                           }
        };
      };
    };

    write_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fwvfmatype_mnemonic : fwvfmafunct6 <-> string = {
  FWVF_VMACC      <-> "vfwmacc.vf",
  FWVF_VNMACC     <-> "vfwnmacc.vf",
  FWVF_VMSAC      <-> "vfwmsac.vf",
  FWVF_VNMSAC     <-> "vfwnmsac.vf"
}

mapping clause assembly = FWVFMATYPE(funct6, vm, rs1, vs2, vd)
  <-> fwvfmatype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)


/* *******************************FWFTYPE*********************************** */

union clause ast = FWFTYPE : (fwffunct6, bits(1), regidx, regidx, regidx)

mapping encdec_fwffunct6 : fwffunct6 <-> bits(6) = {
  FWF_VADD       <-> 0b110100,
  FWF_VSUB       <-> 0b110110
}

mapping clause encdec = FWFTYPE(funct6, vm, vs2, rs1, vd)
  <-> encdec_fwffunct6(funct6) @ vm @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(FWFTYPE(funct6, vm, vs2, rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, vm, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vs2);
    let vd_val  : vector('n, dec, bits('m * 2)) = read_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd);
    result      : vector('n, dec, bits('m * 2)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits * 2, lmul * 2.0, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then {
        result_real : real = undefined;
        result[i] = match funct6 {
          FWF_VADD     => {
                            (fptype, sign, result_real) = fpreal_add(fp_to_real(vs2_val[i]), fp_to_real(rs1_val));
                            real_to_fp(result_real)
                          },
          FWF_VSUB     => {
                            (fptype, sign, result_real) = fpreal_sub(fp_to_real(vs2_val[i]), fp_to_real(rs1_val));
                            real_to_fp(result_real)
                          }
        };
      };
    };

    write_vreg(num_elem, vsew_bits * 2, lmul * 2.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping fwftype_mnemonic : fwffunct6 <-> string = {
  FWF_VADD       <-> "vfwadd.wf",
  FWF_VSUB       <-> "vfwsub.wf"
}

mapping clause assembly = FWFTYPE(funct6, vm, vs2, rs1, vd)
  <-> fwftype_mnemonic(funct6) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ maybe_vmask(vm)


/* *******************************OPFVF(Merge Instruction)******************************** */
/* This instruction operates on all body elements regardless of mask value */

union clause ast = VFMERGE : (regidx, regidx, regidx)

mapping clause encdec = VFMERGE(vs2, rs1, vd)
  <-> 0b010111 @ 0b0 @ vs2 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(VFMERGE(vs2, rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b0, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vs2);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;

    let tail_ag    : agtype = get_vtype_vta();
    /* actual number of elements */
    var real_num_elem : int = undefined;
    if lmul >= 1.0 then real_num_elem = num_elem
    else real_num_elem = floor(lmul * to_real(num_elem));

    foreach (i from 0 to (num_elem - 1)) {
      if i < get_start_element() then result[i] = vd_val[i]
      else if i > get_end_element() | i >= real_num_elem then {
        /* Tail elements */
        if tail_ag == UNDISTURBED then {
          result[i] = vd_val[i]
        }
        else if tail_ag == AGNOSTIC then {
          //result[i] = sail_sign_extend(0b1, vsew_bits)
          result[i] = vd_val[i]
        };
      }
      else if vm_val[i] == false then result[i] = vs2_val[i] /* vs2[i] for inactive elements */
      else result[i] = rs1_val;
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping clause assembly = VFMERGE(vs2, rs1, vd)
  <-> "vfmerge.vfm" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ reg_name(rs1) ^ sep() ^ "v0"


/* *******************************OPFVF(Move Instruction)******************************** */
/* This instruction shares the encoding with vfmerge.vfm, but with vm=1 and vs2=v0 */

union clause ast = VFMV : (regidx, regidx)

mapping clause encdec = VFMV(rs1, vd)
  <-> 0b010111 @ 0b1 @ 0b00000 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(VFMV(rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let lmul       : real = get_vtype_LMUL();
    let num_elem   : int  = get_num_elem(lmul, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 <= num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, lmul, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val);
    
    foreach (i from 0 to (num_elem - 1)) {
      if mask_helper[i] == true then result[i] = rs1_val
    };

    write_vreg(num_elem, vsew_bits, lmul, vd, result);
    RETIRE_SUCCESS
  };
}

mapping clause assembly = VFMV(rs1, vd)
  <-> "vfmv.v.f" ^ spc() ^ vreg_name(vd) ^ sep() ^ reg_name(rs1)


/* *******************************OPFVV(VWFUNARY0)******************************** */

union clause ast = VFMVFS : (regidx, regidx)

mapping clause encdec = VFMVFS(vs2, rd)
  <-> 0b010000 @ 0b1 @ vs2 @ 0b00000 @ 0b001 @ rd @ 0b1010111

function clause execute(VFMVFS(vs2, rd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } else {
    let vsew_bits  : int  = get_vtype_vsew();
    let num_elem   : int  = get_num_elem(1.0, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(sizeof(flen) >= vsew_bits);
    assert(0 < num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vs2_val : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, 1.0, vs2);
    if sizeof(xlen) == 'm then F(rd) = vs2_val[0]
    else F(rd) = nan_box_new(vs2_val[0]);

    RETIRE_SUCCESS
  };
}

mapping clause assembly = VFMVFS(vs2, rd)
  <-> "vfmv.f.s" ^ spc() ^ freg_name(rd) ^ sep() ^ vreg_name(vs2)


/* *******************************OPFVF(VRFUNARY0)******************************** */

union clause ast = VFMVSF : (regidx, regidx)

mapping clause encdec = VFMVSF(rs1, vd)
  <-> 0b010000 @ 0b1 @ 0b00000 @ rs1 @ 0b101 @ vd @ 0b1010111

function clause execute(VFMVSF(rs1, vd)) = {
  let rm_3b   = encdec_rounding_mode (select_instr_or_fcsr_rm (RM_DYN));
  if rm_3b == 0b101 | rm_3b == 0b110 | rm_3b == 0b111 then {
    handle_illegal();
    RETIRE_FAIL
  } 
  else {
    let vsew_bits  : int  = get_vtype_vsew();
    let num_elem   : int  = get_num_elem(1.0, vsew_bits);

    assert(vsew_bits == 16 | vsew_bits == 32 | vsew_bits == 64);
    assert(0 < num_elem & num_elem <= sizeof(vlen));
    let 'n = num_elem;
    let 'm = vsew_bits;

    let vm_val  : vector('n, dec, bool)     = read_vmask(num_elem, 0b1, vreg_name("v0"));
    let rs1_val = get_scalar_fp(rs1, 'm);
    let vd_val  : vector('n, dec, bits('m)) = read_vreg(num_elem, vsew_bits, 1.0, vd);
    result      : vector('n, dec, bits('m)) = undefined;
    mask_helper : vector('n, dec, bool)     = undefined;

    (result, mask_helper) = init_masked_result(num_elem, vsew_bits, 1.0, vd_val, vm_val);
    
    if mask_helper[0] == true then result[0] = rs1_val;

    let tail_ag : agtype = get_vtype_vta();
    foreach (i from 1 to (num_elem - 1)) {
      /* treated as tail elements */
      if tail_ag == UNDISTURBED then {
        result[i] = vd_val[i]
      }
      else if tail_ag == AGNOSTIC then {
        //result[i] = sail_sign_extend(0b1, vsew_bits)
        result[i] = vd_val[i]
      };
    };

    write_vreg(num_elem, vsew_bits, 1.0, vd, result);
    RETIRE_SUCCESS
  };
}

mapping clause assembly = VFMVSF(rs1, vd)
  <-> "vfmv.s.f" ^ spc() ^ vreg_name(vd) ^ sep() ^ freg_name(rs1)
