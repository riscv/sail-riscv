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
  let VLEN_pow      : int  = get_vlen_pow();
  let LMUL_pow_ori  : int  = get_lmul_pow();
  let SEW_pow_ori   : int  = get_sew_pow(); 
  let ratio_pow_ori : int  = SEW_pow_ori - LMUL_pow_ori;

  /* set vtype and calculate VLMAX */
  match op {
    VSETVLI => {
      vtype->bits() = 0b0 @ zeros(sizeof(xlen) - 9) @ ma @ ta @ sew @ lmul
    },
    VSETVL  => {
      let rs2 : regidx = sew[1 .. 0] @ lmul;
      vtype->bits() = X(rs2)
    }
  };
  print_reg("CSR vtype <- " ^ BitStr(vtype.bits()));
  let LMUL_pow_new : int = get_lmul_pow();
  let SEW_pow_new  : int = get_sew_pow();
  let VLMAX        : int = int_power(2, VLEN_pow + LMUL_pow_new - SEW_pow_new);

  /* set vl according to VLMAX and AVL */
  if (rs1 != 0b00000) then { /* normal stripmining */
    let rs1_val = X(rs1);
    let AVL = unsigned(rs1_val);
    vl = if AVL <= VLMAX then to_bits(sizeof(xlen), AVL)
         else if AVL < 2 * VLMAX then to_bits(sizeof(xlen), (AVL + 1) / 2) /* ceil(AVL / 2) ≤ vl ≤ VLMAX */
         else to_bits(sizeof(xlen), VLMAX);
    X(rd) = vl;
    print_reg("CSR vl <- " ^ BitStr(vl))
  } else if (rd != 0b00000) then { /* set vl to VLMAX */
    let AVL = unsigned(ones(sizeof(xlen)));
    vl = to_bits(sizeof(xlen), VLMAX);
    X(rd) = vl;
    print_reg("CSR vl <- " ^ BitStr(vl))
  } else { /* keep existing vl */
    let AVL = unsigned(vl);
    let ratio_pow_new : int = SEW_pow_new - LMUL_pow_new;
    if (ratio_pow_new != ratio_pow_ori) then { 
      vtype->bits() = 0b1 @ zeros(sizeof(xlen) - 1); /* set vtype.vill */
      print_reg("CSR vtype <- " ^ BitStr(vtype.bits()));
    }
  };

  /* reset vstart to 0 */
  vstart = EXTZ(0b0);
  print_reg("CSR vstart <- " ^ BitStr(vstart));

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
  let VLEN_pow      : int  = get_vlen_pow();
  let LMUL_pow_ori  : int  = get_lmul_pow();
  let SEW_pow_ori   : int  = get_sew_pow(); 
  let ratio_pow_ori : int  = SEW_pow_ori - LMUL_pow_ori;

  /* set vtype and calculate VLMAX */
  vtype->bits() = 0b0 @ zeros(sizeof(xlen) - 9) @ ma @ ta @ sew @ lmul;
  print_reg("CSR vtype <- " ^ BitStr(vtype.bits()));

  let LMUL_pow_new : int = get_lmul_pow();
  let SEW_pow_new  : int = get_sew_pow();
  let VLMAX        : int = int_power(2, VLEN_pow + LMUL_pow_new - SEW_pow_new);
  let AVL          : int = unsigned(uimm); /* AVL is encoded as 5-bit zero-extended imm in the rs1 field */

  /* set vl according to VLMAX and AVL */
  vl = if AVL <= VLMAX then to_bits(sizeof(xlen), AVL)
       else if AVL < 2 * VLMAX then to_bits(sizeof(xlen), (AVL + 1) / 2) /* ceil(AVL / 2) ≤ vl ≤ VLMAX */
       else to_bits(sizeof(xlen), VLMAX);
  X(rd) = vl;
  print_reg("CSR vl <- " ^ BitStr(vl));

  /* reset vstart to 0 */
  vstart = EXTZ(0b0);
  print_reg("CSR vstart <- " ^ BitStr(vstart));

  RETIRE_SUCCESS
}

mapping clause assembly = VSETI_TYPE(ma, ta, sew, lmul, uimm, rd) 
  <-> "vsetivli" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(uimm) ^ sep() ^ sew_flag(sew) ^ maybe_lmul_flag(lmul) ^ maybe_ta_flag(ta) ^ maybe_ma_flag(ma)
