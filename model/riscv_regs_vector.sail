/* vector registers */
register vr0 : vregtype
register vr1 : vregtype
register vr2 : vregtype
register vr3 : vregtype
register vr4 : vregtype
register vr5 : vregtype
register vr6 : vregtype
register vr7 : vregtype
register vr8 : vregtype
register vr9 : vregtype
register vr10 : vregtype
register vr11 : vregtype
register vr12 : vregtype
register vr13 : vregtype
register vr14 : vregtype
register vr15 : vregtype
register vr16 : vregtype
register vr17 : vregtype
register vr18 : vregtype
register vr19 : vregtype
register vr20 : vregtype
register vr21 : vregtype
register vr22 : vregtype
register vr23 : vregtype
register vr24 : vregtype
register vr25 : vregtype
register vr26 : vregtype
register vr27 : vregtype
register vr28 : vregtype
register vr29 : vregtype
register vr30 : vregtype
register vr31 : vregtype

val vreg_name : bits(5) <-> string
mapping vreg_name = {
    0b00000 <-> "v0",
    0b00001 <-> "v1",
    0b00010 <-> "v2",
    0b00011 <-> "v3",
    0b00100 <-> "v4",
    0b00101 <-> "v5",
    0b00110 <-> "v6",
    0b00111 <-> "v7",
    0b01000 <-> "v8",
    0b01001 <-> "v9",
    0b01010 <-> "v10",
    0b01011 <-> "v11",
    0b01100 <-> "v12",
    0b01101 <-> "v13",
    0b01110 <-> "v14",
    0b01111 <-> "v15",
    0b10000 <-> "v16",
    0b10001 <-> "v17",
    0b10010 <-> "v18",
    0b10011 <-> "v19",
    0b10100 <-> "v20",
    0b10101 <-> "v21",
    0b10110 <-> "v22",
    0b10111 <-> "v23",
    0b11000 <-> "v24",
    0b11001 <-> "v25",
    0b11010 <-> "v26",
    0b11011 <-> "v27",
    0b11100 <-> "v28",
    0b11101 <-> "v29",
    0b11110 <-> "v30",
    0b11111 <-> "v31"
}

val vreg_id : string <-> bits(5)
mapping vreg_id = {
    "v0"	<->  0b00000,
    "v1"	<->  0b00001,
    "v2"	<->  0b00010,
    "v3"	<->  0b00011,
    "v4"	<->  0b00100,
    "v5"	<->  0b00101,
    "v6"	<->  0b00110,
    "v7"	<->  0b00111,
    "v8"	<->  0b01000,
    "v9"	<->  0b01001,
    "v10"	<->  0b01010,
    "v11"	<->  0b01011,
    "v12"	<->  0b01100,
    "v13"	<->  0b01101,
    "v14"	<->  0b01110,
    "v15"	<->  0b01111,
    "v16"	<->  0b10000,
    "v17"	<->  0b10001,
    "v18"	<->  0b10010,
    "v19"	<->  0b10011,
    "v20"	<->  0b10100,
    "v21"	<->  0b10101,
    "v22"	<->  0b10110,
    "v23"	<->  0b10111,
    "v24"	<->  0b11000,
    "v25"	<->  0b11001,
    "v26"	<->  0b11010,
    "v27"	<->  0b11011,
    "v28"	<->  0b11100,
    "v29"	<->  0b11101,
    "v30"	<->  0b11110,
    "v31"	<->  0b11111 	
}

val rV : forall 'n, 0 <= 'n < 32. regno('n) -> vregtype effect {rreg, escape}
function rV r = {
  let zero_vreg : vregtype = EXTZ(0x0);
  let v : vregtype =
    match r {
      0 => vr0,
      1 => vr1,
      2 => vr2,
      3 => vr3,
      4 => vr4,
      5 => vr5,
      6 => vr6,
      7 => vr7,
      8 => vr8,
      9 => vr9,
      10 => vr10,
      11 => vr11,
      12 => vr12,
      13 => vr13,
      14 => vr14,
      15 => vr15,
      16 => vr16,
      17 => vr17,
      18 => vr18,
      19 => vr19,
      20 => vr20,
      21 => vr21,
      22 => vr22,
      23 => vr23,
      24 => vr24,
      25 => vr25,
      26 => vr26,
      27 => vr27,
      28 => vr28,
      29 => vr29,
      30 => vr30,
      31 => vr31,
      _  => {assert(false, "invalid vector register number"); zero_vreg}
    };
    v
}

val wV : forall 'n, 0 <= 'n < 32. (regno('n), vregtype) -> unit effect {rreg, wreg, escape}
function wV (r, in_v) = {
  let v = in_v;
  match r {
    0 => vr0 = v,
    1 => vr1 = v,
    2 => vr2 = v,
    3 => vr3 = v,
    4 => vr4 = v,
    5 => vr5 = v,
    6 => vr6 = v,
    7 => vr7 = v,
    8 => vr8 = v,
    9 => vr9 = v,
    10 => vr10 = v,
    11 => vr11 = v,
    12 => vr12 = v,
    13 => vr13 = v,
    14 => vr14 = v,
    15 => vr15 = v,
    16 => vr16 = v,
    17 => vr17 = v,
    18 => vr18 = v,
    19 => vr19 = v,
    20 => vr20 = v,
    21 => vr21 = v,
    22 => vr22 = v,
    23 => vr23 = v,
    24 => vr24 = v,
    25 => vr25 = v,
    26 => vr26 = v,
    27 => vr27 = v,
    28 => vr28 = v,
    29 => vr29 = v,
    30 => vr30 = v,
    31 => vr31 = v,
    _ => assert(false, "invalid vector register number")
  };

  if   get_config_print_reg()
  then {
    print_reg("v" ^ string_of_int(r) ^ " <- " ^ VRegStr(v));
  }
}

function rV_bits(i: bits(5)) -> vregtype = rV(unsigned(i))

function wV_bits(i: bits(5), data: vregtype) -> unit = {
  wV(unsigned(i)) = data
}

overload V = {rV_bits, wV_bits, rV, wV}

val init_vregs : unit -> unit effect {wreg}
function init_vregs () = {
  let zero_vreg : vregtype = EXTZ(0x0);
  vr0  = zero_vreg;
  vr1  = zero_vreg;
  vr2  = zero_vreg;
  vr3  = zero_vreg;
  vr4  = zero_vreg;
  vr5  = zero_vreg;
  vr6  = zero_vreg;
  vr7  = zero_vreg;
  vr8  = zero_vreg;
  vr9  = zero_vreg;
  vr10 = zero_vreg;
  vr11 = zero_vreg;
  vr12 = zero_vreg;
  vr13 = zero_vreg;
  vr14 = zero_vreg;
  vr15 = zero_vreg;
  vr16 = zero_vreg;
  vr17 = zero_vreg;
  vr18 = zero_vreg;
  vr19 = zero_vreg;
  vr20 = zero_vreg;
  vr21 = zero_vreg;
  vr22 = zero_vreg;
  vr23 = zero_vreg;
  vr24 = zero_vreg;
  vr25 = zero_vreg;
  vr26 = zero_vreg;
  vr27 = zero_vreg;
  vr28 = zero_vreg;
  vr29 = zero_vreg;
  vr30 = zero_vreg;
  vr31 = zero_vreg
}

/* **************************************************************** */
/* Vector CSR                                               */   

bitfield Vcsr : bits(3) = {
  vxrm : 2 .. 1,
  vxsat     : 0
}
register vcsr : Vcsr

val ext_write_vcsr : (bits(2), bits(1)) -> unit effect {rreg, wreg}
function ext_write_vcsr (vxrm_val, vxsat_val) = {
  vcsr->vxrm()    = vxrm_val;      /* Note: frm can be an illegal value, 101, 110, 111 */
  vcsr->vxsat() = vxsat_val;
}

/* n = vreg number of elements, m = vreg width in bits (# of an element's bits) */
val split_vreg : forall 'n 'm, 'm >= 8. (int('n), int('m), vregtype) -> vector('n, dec, bits('m)) effect {escape, undef}
function split_vreg(n, m, bv) = {
  assert(sizeof(vlen) >= ('m));
  var result: vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (n - 1)) {
    let start_index : int = i * m;
    /* slice params: bitvector, start index, length */
    result[i] = result[i] | slice(bv, start_index, m);
  };

  result
}

val join_vreg : forall 'n 'm, 'm >= 8. (int('n), int('m), vector('n, dec, bits('m))) -> vregtype  effect {escape}
function join_vreg(n, m, v) = {
  assert(sizeof(vlen) >= ('m));
  r : vregtype = zeros(sizeof(vreglen));

  foreach (i from (n - 1) downto 0) {
    r = r << (m);
    r = r | sail_zero_extend(v[i], length(r));
  };

  r
}


/* n = vreg number of elements, m = vreg width in bits (# of one element's bits) */
val read_single_vreg : forall 'n 'm, 1 <= 'm <= 128. (int('n), int('m), regidx) -> vector('n, dec, bits('m)) effect {escape, rreg, undef}
function read_single_vreg(n, m, vrid) = {
  let bv     : vregtype                  = V(vrid);
  var result : vector('n, dec, bits('m)) = undefined;

  foreach (i from 0 to (n - 1)) {
    let start_index : int = i * m;
    /* slice params: bitvector, start index, length */
    result[i] = slice(bv, start_index, m);
  };

  result
}

val write_single_vreg : forall 'n 'm, 8 <= 'm <= 128. (int('n), int('m), regidx, vector('n, dec, bits('m))) -> unit  effect {escape, rreg, wreg}
function write_single_vreg(n, m, vrid, v) = {
  r : vregtype = zeros(sizeof(vreglen));

  foreach (i from (n - 1) downto 0) {
    r = r << (m);
    r = r | sail_zero_extend(v[i], length(r));
  };

  V(vrid) = r
}

/* Reads multiple vregs into a single element */
val read_mult_vreg : forall 'n 'm, 'n >= 0 & 'm >= vlen. (int('n), int('m), regidx) -> bits('m) effect {escape, rreg}
function read_mult_vreg(num_vreg, num_bits, vrid) = {
  var result : bits('m) = zeros(num_bits);

  foreach (i from (num_vreg - 1) downto 0) {
    let vrid_lmul : regidx   = vrid + to_bits(5, i);
    let bv        : vregtype = V(vrid_lmul);

    result = result << sizeof(vlen);
    result = result | sail_zero_extend(bv, num_bits);
  };

  result
}

val write_mult_vreg : forall 'n 'm, 'n >= 0 & 'm >= vlen. (int('n), int('m), regidx, bits('m)) -> unit effect {escape, rreg, wreg}
function write_mult_vreg(num_vreg, num_bits, vrid, bv) = {
  foreach (i from (num_vreg - 1) downto 0) {
    let vrid_lmul : regidx   = vrid + to_bits(5, i);
    let single_bv : vregtype = slice(bv >> (sizeof(vlen) * i), 0, sizeof(vlen));
    V(vrid_lmul) = single_bv
  }
}

/* num_elem should have LMUL taken into account: num_elem = lmul * vlen/vsew */
val read_vreg : forall 'n 'm, 8 <= 'm <= 64. (int('n), int('m), real, regidx) -> vector('n, dec, bits('m)) effect {escape, rreg, undef}
function read_vreg(num_elem, vsew_bits, lmul, vrid) = {
  var result : vector('n, dec, bits('m)) = undefined;

  let adjusted_lmul    : real = if lmul < 1.0 then 1.0 else lmul;
  let num_elem_single  : int = floor(to_real(num_elem) / adjusted_lmul);
  let 'num_elem_single : int = num_elem_single;
  let lmul_int         : int = floor(adjusted_lmul);

  /* Check for valid vrid */
  if lmul > 1.0 & (unsigned(vrid) + floor(lmul)) > 31 then {
    /* vrid would read past largest vreg (v31) */
    result = undefined
  }
  else if lmul > 1.0 & (unsigned(vrid) % floor(lmul) != 0) then {
    /* vrid must be a multiple of lmul */
    result = undefined
  }
  else if (vsew_bits > sizeof(vlen)) & (vsew_bits % sizeof(vlen) != 0) then {
    /* vsew_bits must be a multiple of vlen */
    result = undefined
  }
  else {
    if vsew_bits > sizeof(vlen) then {
      /* Multiple vregs per element */
      //let num_reg_per_elem : int = vsew_bits / sizeof(vlen);
      let num_reg_per_elem : int = lmul_int;
      
      foreach (i from 0 to (num_elem - 1)) {
        let vrid_lmul : regidx = vrid + to_bits(5, i * num_reg_per_elem);
        result[i] = read_mult_vreg(num_reg_per_elem, vsew_bits, vrid_lmul)
      }
    }
    else {
      foreach (i_lmul from 0 to (lmul_int - 1)) {
        let r_start_i : int = i_lmul * num_elem_single;
        let r_end_i   : int = r_start_i + num_elem_single - 1;
        let vrid_lmul     : regidx = vrid + to_bits(5, i_lmul);
        let single_result : vector('num_elem_single, dec, bits('m)) = read_single_vreg(num_elem_single, vsew_bits, vrid_lmul);
        foreach (r_i from r_start_i to r_end_i) {
          let s_i : int = r_i - r_start_i;
          assert(0 <= r_i & r_i < num_elem);
          assert(0 <= s_i & s_i < num_elem_single);
          result[r_i] = single_result[s_i];
        }
      }
    }
  };

  result
}

/* =after read_vreg then do slice */
val read_single_element : forall 'm 'x, 8 <= 'm <= 64. (int('m), int('x), real, regidx) -> bits('m)  effect {escape, rreg, undef}
function read_single_element(elem_width_bits, index, emul, vrid) = {
  real_vrid : regidx = vrid;
  real_index : int = index;
  let elem_per_reg : int = sizeof(vlen) / elem_width_bits;
  let 'elem_per_reg = elem_per_reg;
  if emul > 1.0 then {
    real_vrid = vrid + to_bits(5, floor(to_real(index) / to_real(elem_per_reg)));
    real_index = index % elem_per_reg;
  };
  let vrid_val : vector('elem_per_reg, dec, bits('m)) = read_single_vreg(elem_per_reg, elem_width_bits, real_vrid);

  let 'real_index = real_index;
  assert( 0 <= 'real_index & 'real_index < 'elem_per_reg );
  vrid_val['real_index]
}

/* num_elem should have LMUL taken into account: num_elem = lmul * vlen/vsew */
val write_vreg : forall 'n 'm, 8 <= 'm <= 128. (int('n), int('m), real, regidx, vector('n, dec, bits('m))) -> unit effect {escape, rreg, undef, wreg} 
function write_vreg(num_elem, vsew_bits, lmul, vrid, vec) = {
  let adjusted_lmul    : real = if lmul < 1.0 then 1.0 else lmul;
  let num_elem_single  : int = floor(to_real(num_elem) / adjusted_lmul);
  let 'num_elem_single : int = num_elem_single;
  let lmul_int         : int = floor(adjusted_lmul);

  if vsew_bits > sizeof(vlen) then {
    /* Multiple vregs per element */
    let num_reg_per_elem : int = lmul_int;

    foreach (i from 0 to (num_elem - 1)) {
      let vrid_lmul : regidx = vrid + to_bits(5, i * num_reg_per_elem);
      write_mult_vreg(num_reg_per_elem, vsew_bits, vrid_lmul, vec[i])
    }
  }
  else {
    foreach (i_lmul from 0 to (lmul_int - 1)) {
      var single_vec  : vector('num_elem_single, dec, bits('m)) = undefined;
      let vrid_lmul   : regidx = vrid + to_bits(5, i_lmul);
      let r_start_i   : int = i_lmul * num_elem_single;
      let r_end_i     : int = r_start_i + num_elem_single - 1;
      foreach (r_i from r_start_i to r_end_i) {
        let s_i : int = r_i - r_start_i;
        assert(0 <= r_i & r_i < num_elem);
        assert(0 <= s_i & s_i < num_elem_single);
        single_vec[s_i] = vec[r_i]
      };
      write_single_vreg(num_elem_single, vsew_bits, vrid_lmul, single_vec)
    }
  }
}

/* This function multiplies lmul by the base number of elements */
val get_num_elem : (real, int) -> int effect {undef}
function get_num_elem(lmul, vsew_bits) = {
  var num_elem : int = undefined;
  if lmul >= 1.0 then {
    num_elem = floor(lmul * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
  }
  else {
    /* Ignore lmul < 1 so that the entire vreg is read, allowing all masking to
     * be handled in init_masked_result */
    num_elem = floor(1.0 * (to_real(sizeof(vlen)) / to_real(vsew_bits)));
  };
  
  num_elem
}

/* n = vreg number of elements, m = vreg width in bits (# of an element's bits)*/
/* n should have LMUL taken into account: num_elem = lmul * vlen/vsew */
val read_vmask : forall 'n, 0 <= 'n <= vlen. (int('n), bits(1), regidx) -> vector('n, dec, bool) effect {escape, rreg, undef}
function read_vmask(n, vm, vrid) = {
  let vreg_val : vregtype = V(vrid);
  var result   : vector('n, dec, bool) = undefined;

  foreach (i from 0 to (n - 1)) {
    if vm == 0b1 then {
      result[i] = true
    }
    else {
      result[i] = bit_to_bool(vreg_val[i])
    }
  };

  result
}

/* This is a special version of read_vmask for carry/borrow instructions, where vm=1 means no carry */
/* n = vreg number of elements, m = vreg width in bits (# of an element's bits)*/
/* n should have LMUL taken into account: num_elem = lmul * vlen/vsew */
val read_vmask_carry : forall 'n, 0 <= 'n <= vlen. (int('n), bits(1), regidx) -> vector('n, dec, bool) effect {escape, rreg, undef}
function read_vmask_carry(n, vm, vrid) = {
  let vreg_val : vregtype = V(vrid);
  var result   : vector('n, dec, bool) = undefined;

  foreach (i from 0 to (n - 1)) {
    if vm == 0b1 then {
      result[i] = false
    }
    else {
      result[i] = bit_to_bool(vreg_val[i])
    }
  };

  result
}

/* n should have LMUL taken into account: num_elem = lmul * vlen/vsew */
val write_vmask : forall 'n, 0 <= 'n <= vlen. (int('n), regidx, vector('n, dec, bool)) -> unit effect {escape, rreg, undef, wreg}
function write_vmask(n, vrid, v) = {
  let vreg_val : vregtype = V(vrid);
  var result   : vregtype = undefined;

  foreach (i from 0 to (n - 1)) {
    result[i] = bool_to_bit(v[i])
  };
  foreach (i from n to (sizeof(vlen) - 1)) {
    /* Mask tail is always agnostic */
    //result[i] = bitone
    result[i] = vreg_val[i]
  };

  V(vrid) = result
}



/* end vector register */
