// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

function clause currentlyEnabled(Ext_Zvdot4a8i) = hartSupports(Ext_Zvdot4a8i) & currentlyEnabled(Ext_Zve32x)


union clause instruction = VDOT4A_VV : (vvd_funct6, bits(1), vregidx, vregidx, vregidx)

mapping encdec_vvd_funct6 : vvd_funct6 <-> bits(6) = {
  VVD_VDOT4A      <-> 0b101100,
  VVD_VDOT4AU     <-> 0b101000,
  VVD_VDOT4SU     <-> 0b101010,
}

mapping encdec_vxd_funct6 : vxd_funct6 <-> bits(6) = {
  VXD_VDOT4A      <-> 0b101100,
  VXD_VDOT4AU     <-> 0b101000,
  VXD_VDOT4SU     <-> 0b101010,
  VXD_VDOT4US     <-> 0b101110,
}


mapping clause encdec = VDOT4A_VV(funct6, vm, vs2, vs1, vd)
  <-> encdec_vvd_funct6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
   when currentlyEnabled(Ext_Zvdot4a8i) & get_sew() == 32

function clause execute VDOT4A_VV(funct6, vm, vs2, vs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_normal(vd, vm) then return Illegal_Instruction();

  let 'n = num_elem;
  let 'm = SEW;
  let 'p = num_elem*4;
  let 'q = 8; // SEW/4;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let vs1_val : vector('p, bits('q)) = read_vreg('p, 'q, LMUL_pow, vs1);
  let vs2_val : vector('p, bits('q)) = read_vreg('p, 'q, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VVD_VDOT4A   => {
                          let result_p0 = signed(vs2_val[i*4]) * signed(vs1_val[i*4]);
                          let result_p1 = signed(vs2_val[i*4 + 1]) * signed(vs1_val[i*4 + 1]);
                          let result_p2 = signed(vs2_val[i*4 + 2]) * signed(vs1_val[i*4 + 2]);
                          let result_p3 = signed(vs2_val[i*4 + 3]) * signed(vs1_val[i*4 + 3]);
                          let result_add : bits('m) = to_bits_truncate(SEW, result_p0 + result_p1 + result_p2 + result_p3 + signed(vd_val[i]));
                          result_add
                        },
        VVD_VDOT4AU  => {
                          let result_p0 = unsigned(vs2_val[i*4]) * unsigned(vs1_val[i*4]);
                          let result_p1 = unsigned(vs2_val[i*4 + 1]) * unsigned(vs1_val[i*4 + 1]);
                          let result_p2 = unsigned(vs2_val[i*4 + 2]) * unsigned(vs1_val[i*4 + 2]);
                          let result_p3 = unsigned(vs2_val[i*4 + 3]) * unsigned(vs1_val[i*4 + 3]);
                          let result_add = result_p0 + result_p1 + result_p2 + result_p3 + unsigned(vd_val[i]);
                          to_bits_truncate('m, result_add)
                        },
        VVD_VDOT4SU  => {
                          let result_p0 = signed(vs2_val[i*4]) * unsigned(vs1_val[i*4]);
                          let result_p1 = signed(vs2_val[i*4 + 1]) * unsigned(vs1_val[i*4 + 1]);
                          let result_p2 = signed(vs2_val[i*4 + 2]) * unsigned(vs1_val[i*4 + 2]);
                          let result_p3 = signed(vs2_val[i*4 + 3]) * unsigned(vs1_val[i*4 + 3]);
                          let result_add = result_p0 + result_p1 + result_p2 + result_p3 + signed(vd_val[i]);
                          to_bits_truncate('m, result_add)
                        }
      }
    }
  };
  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}

union clause instruction = VDOT4A_VX : (vxd_funct6, bits(1), vregidx, regidx, vregidx)

mapping clause encdec = VDOT4A_VX(funct6, vm, vs2, rs1, vd)
  <-> encdec_vxd_funct6(funct6) @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ 0b110 @ encdec_vreg(vd) @ 0b1010111
   when currentlyEnabled(Ext_Zvdot4a8i) & get_sew() == 32

function clause execute VDOT4A_VX(funct6, vm, vs2, rs1, vd) = {
  let SEW      = get_sew();
  let LMUL_pow = get_lmul_pow();
  let num_elem = get_num_elem(LMUL_pow, SEW);

  if illegal_normal(vd, vm) then return Illegal_Instruction();

  assert(SEW >= 32);

  let 'n = num_elem;
  let 'm = SEW;
  let 'p = num_elem*4;
  let 'q = 8; // SEW/4;

  let vm_val  : bits('n)             = read_vmask(num_elem, vm, zvreg);
  let rs1_val : bits('m)             = get_scalar(rs1, SEW);
  let vs2_val : vector('p, bits('q)) = read_vreg('p, 'q, LMUL_pow, vs2);
  let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

  let rs1_vector : vector(4, bits('q)) = [
      rs1_val['q-1 .. 0],
      rs1_val['q*2-1 .. 'q],
      rs1_val['q*3-1 .. 'q*2],
      rs1_val['q*4-1 .. 'q*3]
  ];

  let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  var result = initial_result;

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == 0b1 then {
      result[i] = match funct6 {
        VXD_VDOT4A   => {
                        let result_p0 = signed(vs2_val[i*4]) * signed(rs1_vector[0]);
                        let result_p1 = signed(vs2_val[i*4 + 1]) * signed(rs1_vector[1]);
                        let result_p2 = signed(vs2_val[i*4 + 2]) * signed(rs1_vector[2]);
                        let result_p3 = signed(vs2_val[i*4 + 3]) * signed(rs1_vector[3]);
                        let result_add = result_p0 + result_p1 + result_p2 + result_p3 + signed(vd_val[i]);
                        to_bits_truncate('m, result_add)
                      },
        VXD_VDOT4AU  => {
                        let result_p0 = unsigned(vs2_val[i*4]) * unsigned(rs1_vector[0]);
                        let result_p1 = unsigned(vs2_val[i*4 + 1]) * unsigned(rs1_vector[1]);
                        let result_p2 = unsigned(vs2_val[i*4 + 2]) * unsigned(rs1_vector[2]);
                        let result_p3 = unsigned(vs2_val[i*4 + 3]) * unsigned(rs1_vector[3]);
                        let result_add = result_p0 + result_p1 + result_p2 + result_p3 + unsigned(vd_val[i]);
                        to_bits_truncate('m, result_add)
                      },
        VXD_VDOT4SU  => {
                        let result_p0 = signed(vs2_val[i*4]) * unsigned(rs1_vector[0]);
                        let result_p1 = signed(vs2_val[i*4 + 1]) * unsigned(rs1_vector[1]);
                        let result_p2 = signed(vs2_val[i*4 + 2]) * unsigned(rs1_vector[2]);
                        let result_p3 = signed(vs2_val[i*4 + 3]) * unsigned(rs1_vector[3]);
                        let result_add = result_p0 + result_p1 + result_p2 + result_p3 + signed(vd_val[i]);
                        to_bits_truncate('m, result_add)
                      },
        VXD_VDOT4US  => {
                        let result_p0 = unsigned(vs2_val[i*4]) * signed(rs1_vector[0]);
                        let result_p1 = unsigned(vs2_val[i*4 + 1]) * signed(rs1_vector[1]);
                        let result_p2 = unsigned(vs2_val[i*4 + 2]) * signed(rs1_vector[2]);
                        let result_p3 = unsigned(vs2_val[i*4 + 3]) * signed(rs1_vector[3]);
                        let result_add = result_p0 + result_p1 + result_p2 + result_p3 + signed(vd_val[i]);
                        to_bits_truncate('m, result_add)
                      }
      }
    }
  };

  write_vreg(num_elem, SEW, LMUL_pow, vd, result);
  set_vstart(zeros());
  RETIRE_SUCCESS
}
