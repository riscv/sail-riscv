/* Vector mask mapping */
mapping maybe_vmask : string <-> bits(1) = {
  ""              <-> 0b1, /* unmasked by default */
  sep() ^ "v0.t"  <-> 0b0
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

val init_masked_result : forall 'n 'm, 8 <= 'm <= 128. (int('n), int('m), real, vector('n, dec, bits('m)), vector('n, dec, bool)) -> (vector('n, dec, bits('m)), vector('n, dec, bool)) effect {escape, rreg, undef, wreg}
function init_masked_result(num_elem, vsew_bits, lmul, vd_val, vm_val) = {
  let start_element : int                       = get_start_element();
  let end_element   : int                       = get_end_element(); // unsigned(vl) - 1
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
      else if i > (end_element + start_element) then {
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

/**vsetvli&vsetvl**/
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
  <-> "vsetili" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)


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

/* Fixed point signed saturation */
val signed_saturation : forall ('m 'n: Int), ('n >= 'm > 0). (int('m), bits('n)) -> bits('m) effect {escape, rreg, undef, wreg}
function signed_saturation(len, elem) = {
  elem_sat : bits('m) = undefined;
  if signed(elem) > signed(EXTZ('m, ones('m - 1))) then {
    elem_sat = EXTZ('m, ones('m - 1));
    writeCSR(csr_name_map("vxsat"), EXTZ(0b1))
  }
  else if signed(elem) < signed(0b1 << ('m - 1)) then {
    elem_sat = to_bits('m, signed(0b1 << ('m - 1)));
    writeCSR(csr_name_map("vxsat"), EXTZ(0b1))
  }
  else {
    elem_sat = slice(elem, 0, 'm);
    writeCSR(csr_name_map("vxsat"), EXTZ(0b0))
  };
  elem_sat
}

/* Fixed point unsigned saturation */
val unsigned_saturation : forall ('m 'n: Int), ('n >= 'm > 0). (int('m), bits('n)) -> bits('m) effect {escape, rreg, undef, wreg}
function unsigned_saturation(len, elem) = {
  elem_sat : bits('m) = undefined;
  if unsigned(elem) > unsigned(ones('m - 1)) then {
    elem_sat = EXTZ('m, ones('m - 1));
    writeCSR(csr_name_map("vxsat"), EXTZ(0b1))
  }
  else {
    elem_sat = slice(elem, 0, 'm);
    writeCSR(csr_name_map("vxsat"), EXTZ(0b0))
  };
  elem_sat
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

/* Check for vstart value */
val assert_vstart : int -> Retired
function assert_vstart(i) = {
  if unsigned(readCSR(csr_name_map("vstart"))) != i then {
    print("vstar is not 0");
    RETIRE_FAIL
  }
  else {
    RETIRE_SUCCESS
  }
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

mapping encdec_vlewidth : vlewidth <-> bits(3) = {
  VLE8      <-> 0b000,
  VLE16     <-> 0b101,
  VLE32     <-> 0b110,
  VLE64     <-> 0b111
}

mapping bytes_wordwidth : int <-> word_width = {
  1 <-> BYTE,
  2 <-> HALF,
  4 <-> WORD,
  8 <-> DOUBLE
}

mapping vlewidth_bytesnumber : vlewidth <-> int = {
  VLE8      <-> 1,
  VLE16     <-> 2,
  VLE32     <-> 4,
  VLE64     <-> 8
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

