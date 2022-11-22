/* ************************************************************************ */
/* This file implements part of the vector extension.                       */
/* Chapter 6: configuration setting instructions                            */

/* ************************************************************************ */

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

/* ******************** vsetvli & vsetvl *********************** */
union clause ast = VSET_TYPE : (vsetop, bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping encdec_vsetop : vsetop <-> bits(4) ={
  VSETVLI <-> 0b0000,
  VSETVL  <-> 0b1000
}

mapping clause encdec = VSET_TYPE(op, ma, ta, sew, lmul, rs1, rd)  
  <-> encdec_vsetop(op) @ ma @ ta @ sew @ lmul @ rs1 @ 0b111 @ rd @ 0b1010111

function clause execute VSET_TYPE(op, ma, ta, sew, lmul, rs1, rd) = {
  AVL      : int  = undefined;
  VLMAX    : int  = undefined;
  SEW_new  : int  = undefined;
  LMUL_new : real = undefined;

  let LMUL_ori  : real = get_vtype_LMUL();
  let SEW_ori   : int  = get_vtype_vsew();
  let ratio_ori : real = to_real(SEW_ori) / LMUL_ori;
  
  /****** vsetvli part *******/
  if (op == VSETVLI) then{
    let vtype_reserved = zeros(sizeof(xlen) - 9);
    let vtype_val : xlenbits = 0b0 @ vtype_reserved @ ma @ ta @ sew @ lmul;
    writeCSR(csr_name_map("vtype"), vtype_val);
    let LMUL_new  : real = get_vtype_LMUL();
    let SEW_new   : int = get_vtype_vsew();
    VLMAX = floor(LMUL_new * to_real(vlen) / to_real(SEW_new)) /* VLMAX = LUML * VLEN / SEW */
  };

  /****** vsetvl part *******/
  if (op == VSETVL) then {
    let sew_append_lmul : bits(6) = (sail_zero_extend(sew, 6) << 3) | (sail_zero_extend(lmul, 6));
    let rs2 : regidx = slice(sew_append_lmul, 0 , 5);
    let rs2_val = X(rs2);
    writeCSR(csr_name_map("vtype"), rs2_val);
    let LMUL_new : real = get_vtype_LMUL();
    let SEW_new  : int = get_vtype_vsew();
    VLMAX = floor(LMUL_new * to_real(vlen) / to_real(SEW_new)) /* VLMAX = LUML * VLEN / SEW */
  };

  /* set vl according to VLMAX and AVL */
  if (rs1 != 0b00000) then { /* normal stripmining */
    let rs1_val = X(rs1);
    AVL = unsigned(rs1_val);
    X(rd) = rs1_val;
    if (AVL <= VLMAX) then {
      writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), AVL))
    } else if (AVL < 2 * VLMAX) then { /* ceil(AVL / 2) ≤ vl ≤ VLMAX */
      writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), ceil(to_real(AVL) / 2.0)))
    } else {
      writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), VLMAX));
    };
  } else if (rd != 0b00000) then { /* set vl to VLMAX */
    AVL = unsigned(ones(sizeof(xlen)));
    X(rd) = to_bits(sizeof(xlen), VLMAX);
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), VLMAX));
  } else {
    let ratio_new : real = to_real(SEW_new) / LMUL_new;
    if (ratio_new != ratio_ori) then { /* keep existing vl */
      writeCSR(csr_name_map("vtype"), 0b1 @ zeros(sizeof(xlen) - 1))
    } else { 
      AVL = unsigned(readCSR(csr_name_map("vl"))) 
    }
  };

  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  RETIRE_SUCCESS
}

mapping vsettype_mnemonic : vsetop <-> string ={
  VSETVLI <-> "vsetvli",
  VSETVL  <-> "vsetvli"
}

mapping clause assembly = VSET_TYPE(op, ma, ta, sew, lmul, rs1, rd) 
  <-> vsettype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)


/* ******************** vsetivli *********************** */
union clause ast = VSETI_TYPE : ( bits(1), bits(1), bits(3), bits(3), regidx, regidx)

mapping clause encdec = VSETI_TYPE(ma, ta, sew, lmul, uimm, rd)  
  <-> 0b1100 @ ma @ ta @ sew @ lmul @ uimm @ 0b111 @ rd @ 0b1010111

function clause execute VSETI_TYPE(ma, ta, sew, lmul, uimm, rd) = {
  AVL   : int = undefined;
  VLMAX : int = undefined; 

  let LMUL_ori  : real = get_vtype_LMUL();
  let SEW_ori   : int  = get_vtype_vsew();
  let ratio_ori : real = to_real(SEW_ori) / LMUL_ori;

  let vtype_reserved = zeros(sizeof(xlen) - 9);
  let vtype_val : xlenbits = 0b0 @ vtype_reserved @ ma @ ta @ sew @ lmul;

  writeCSR(csr_name_map("vtype"), vtype_val);
  let LMUL_new  : real = get_vtype_LMUL();
  let SEW_new   : int = get_vtype_vsew();
  VLMAX = floor(LMUL_new * to_real(vlen) / to_real(SEW_new)); /* VLMAX = LUML * VLEN / SEW */
  
  /****** vsetivli part *******/
  AVL = unsigned(sail_zero_extend(uimm, sizeof(xlen))); /* AVL is encoded as 5-bit zero-extended imm in the rs1 field */

  if (AVL <= VLMAX) then {
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), AVL));
    X(rd) = to_bits(sizeof(xlen), AVL)
  } else if (AVL < 2 * VLMAX) then { /* ceil(AVL / 2) ≤ vl ≤ VLMAX */
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), ceil(to_real(AVL) / 2.0)));
    X(rd) = to_bits(sizeof(xlen), ceil(to_real(AVL) / 2.0))
  } else {
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), VLMAX));
    X(rd) = to_bits(sizeof(xlen), VLMAX)
  };

  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  RETIRE_SUCCESS
}

mapping clause assembly = VSETI_TYPE(ma, ta, sew, lmul, uimm, rd) 
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)
