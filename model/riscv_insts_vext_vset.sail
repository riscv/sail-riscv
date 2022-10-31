/* ************************************************************************ */
/* This file implements part of the vector extension.                       */
/* Chapter 6: configuration setting instructions                            */

/* ************************************************************************ */

/* **************************VSET_TYPE(3)********************************** */
/* **************************VSET_TYPE(2 + 1)****************************** */
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
  let ratio_ori : real = to_real(SEW_ori) / LMUL_ori;
  
  /****** vsetvli part *******/
  if (op == VSETVLI) then{
    let vtype_reserved = zeros(sizeof(xlen) - 9);
    let vtype_val : xlenbits = 0b0 @ vtype_reserved @ ma @ ta @ sew @ lmul;
    writeCSR(csr_name_map("vtype"), vtype_val);
    let LMUL_new : real = get_vtype_LMUL();
    let SEW_new : int = get_vtype_vsew();
    VLMAX = floor (LMUL_new * to_real(sizeof(vlen)) / to_real (SEW_new)) /* VLMAX=LUML*VLEN/SEW */
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
  };

  if (rs1 != 0b00000) then{
    let rs1_val = X(rs1);
    AVL = unsigned(rs1_val);
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
  let ratio_ori : real = to_real(SEW_ori) / LMUL_ori;
 
  let vtype_reserved = zeros(sizeof(xlen) - 9);
  let vtype_val : xlenbits = 0b0 @ vtype_reserved @ ma @ ta @ sew @ lmul;
  /* vtype->vma()   = ma;
  vtype->vta()   = ta;
  vtype->vsew()  = sew;
  vtype->vlmul() = lmul; */
  writeCSR(csr_name_map("vtype"), vtype_val);
  let LMUL_new : real = get_vtype_LMUL();
  let SEW_new : int = get_vtype_vsew();
  VLMAX = floor (LMUL_new * to_real(sizeof(vlen)) / to_real (SEW_new)); /* VLMAX=LUML*VLEN/SEW */
  
  /****** vsetivli part *******/
  AVL = unsigned(sail_zero_extend(uimm,sizeof(xlen))); /*AVL is encoded as 5-bit zero-extended imm in the rs1 field */
  X(rd) = to_bits(sizeof(xlen), AVL); /* ??? */

  if (AVL <= VLMAX) then {
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), AVL))
  };

  /* if ((AVL < 2 * VLMAX) & ((unsigned (readCSR(csr_name_map("vl"))) > VLMAX) | (unsigned (readCSR(csr_name_map("vl"))) < ceil(AVL / 2)) )) then
  handle_illegal () ;*/

  if (AVL >= 2 * VLMAX) then {
    writeCSR(csr_name_map("vl"), to_bits(sizeof(xlen), VLMAX))
  };

  writeCSR(csr_name_map("vstart"), EXTZ(0b0));
  RETIRE_SUCCESS
}

mapping clause assembly = VSETI_TYPE(ma, ta, sew, lmul, uimm, rd) 
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)
