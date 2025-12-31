// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Integer Vector Absolute Difference Instructions

function clause currentlyEnabled(Ext_Zvabd) = hartSupports(Ext_Zvabd) & currentlyEnabled(Ext_Zve32x)

// vabd.vv, vabdu.vv
union clause instruction = VABD_TYPE : (vabdop, bits(1), vregidx, vregidx, vregidx)

mapping encdec_vabd_vv_op : vabdop <-> bits(6) = {
    VABD_VV  <-> 0b010010,
    VABDU_VV <-> 0b010000
}

mapping clause encdec = VABD_TYPE(op, vm, vs2, vs1, vd)
  <-> encdec_vabd_vv_op(op) @ vm @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b000 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd)

mapping vabd_vv_mnemonic : vabdop <-> string = {
    VABD_VV  <-> "vabd.vv",
    VABDU_VV <-> "vabdu.vv"
}

mapping clause assembly = VABD_TYPE(op, vm, vs2, vs1, vd)
  <-> vabd_vv_mnemonic(op) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1) ^ maybe_vmask(vm)

function clause execute VABD_TYPE(op, vm, vs2, vs1, vd) = {
    let SEW      = get_sew();
    let LMUL_pow = get_lmul_pow();
    let num_elem = get_num_elem(LMUL_pow, SEW);

    if illegal_normal(vd, vm) then return Illegal_Instruction();

    let 'n = num_elem;
    let 'm = SEW;

    let vm_val  : bits('n)     = read_vmask(num_elem, vm, zvreg);
    let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
    let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

    let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
        Ok(v)   => v,
        Err(()) => return Illegal_Instruction()
    };
    var result = initial_result;

    foreach (i from 0 to (num_elem - 1)) {
        if mask[i] == bitone then {
            let elem_val1 = vs1_val[i];
            let elem_val2 = vs2_val[i];
            result[i] = if op == VABD_VV then {
                // signed absolute difference
                let diff = signed(elem_val2) - signed(elem_val1);
                to_bits_unsafe(SEW, if diff < 0 then -diff else diff)
            } else { // VABDU_VV
                // unsigned absolute difference
                if unsigned(elem_val2) > unsigned(elem_val1) then elem_val2 - elem_val1 else elem_val1 - elem_val2
            }
        }
    };

    write_vreg(num_elem, SEW, LMUL_pow, vd, result);
    set_vstart(zeros());
    RETIRE_SUCCESS
}

// vabs.v
union clause instruction = VABS_V_inst : (bits(1), vregidx, vregidx)

mapping clause encdec = VABS_V_inst(vm, vs2, vd)
  <-> 0b010010 @ vm @ encdec_vreg(vs2) @ 0b00000 @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd)

mapping clause assembly = VABS_V_inst(vm, vs2, vd)
  <-> "vabs.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

function clause execute VABS_V_inst(vm, vs2, vd) = {
    let SEW      = get_sew();
    let LMUL_pow = get_lmul_pow();
    let num_elem = get_num_elem(LMUL_pow, SEW);

    if illegal_normal(vd, vm) then return Illegal_Instruction();

    let 'n = num_elem;
    let 'm = SEW;

    let vm_val  : bits('n)     = read_vmask(num_elem, vm, zvreg);
    let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vd_val  : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vd);

    let (initial_result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, SEW, LMUL_pow, vd_val, vm_val) {
        Ok(v)   => v,
        Err(()) => return Illegal_Instruction()
    };
    var result = initial_result;

    foreach (i from 0 to (num_elem - 1)) {
        if mask[i] == bitone then {
            let elem_val = vs2_val[i];
            let s_elem_val = signed(elem_val);
            result[i] = to_bits_unsafe(SEW, if s_elem_val < 0 then -s_elem_val else s_elem_val);
        }
    };
    
    write_vreg(num_elem, SEW, LMUL_pow, vd, result);
    set_vstart(zeros());
    RETIRE_SUCCESS
}

// vwabdacc.vv, vwabdaccu.vv
union clause instruction = VWABDACC_TYPE : (vabdop, vregidx, vregidx, vregidx)

mapping encdec_vwabdacc_op : vabdop <-> bits(6) = {
    VWABDACC_VV  <-> 0b011011,
    VWABDACCU_VV <-> 0b011001
}

mapping clause encdec = VWABDACC_TYPE(op, vs2, vs1, vd)
  <-> encdec_vwabdacc_op(op) @ 0b0 @ encdec_vreg(vs2) @ encdec_vreg(vs1) @ 0b010 @ encdec_vreg(vd) @ 0b1010111
  when currentlyEnabled(Ext_Zvabd)

mapping vwabdacc_mnemonic : vabdop <-> string = {
    VWABDACC_VV  <-> "vwabdacc.vv",
    VWABDACCU_VV <-> "vwabdaccu.vv"
}

mapping clause assembly = VWABDACC_TYPE(op, vs2, vs1, vd)
  <-> vwabdacc_mnemonic(op) ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs2) ^ sep() ^ vreg_name(vs1)

function clause execute VWABDACC_TYPE(op, vs2, vs1, vd) = {
    let SEW            = get_sew();
    let LMUL_pow       = get_lmul_pow();
    let num_elem       = get_num_elem(LMUL_pow, SEW);
    let SEW_widen      = SEW * 2;
    let LMUL_pow_widen = LMUL_pow + 1;

    if  illegal_variable_width(vd, 0b0, SEW_widen, LMUL_pow_widen) |
        not(valid_reg_overlap(vs1, vd, LMUL_pow, LMUL_pow_widen)) |
        not(valid_reg_overlap(vs2, vd, LMUL_pow, LMUL_pow_widen))
    then return Illegal_Instruction();
    
    if unsigned(vstart) != 0 then return Illegal_Instruction();

    assert(SEW_widen <= 64);
    assert(LMUL_pow_widen <= 3);

    let 'n = num_elem;
    let 'm = SEW;
    let 'o = SEW_widen;
    
    let vl_val = unsigned(vl);

    let vs1_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs1);
    let vs2_val : vector('n, bits('m)) = read_vreg(num_elem, SEW, LMUL_pow, vs2);
    let vd_val  : vector('n, bits('o)) = read_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd);
    var result  : vector('n, bits('o)) = vd_val;
    
    foreach (i from 0 to (num_elem - 1)) {
        if i < vl_val then {
            let elem_val1 = vs1_val[i];
            let elem_val2 = vs2_val[i];
            let abs_diff : bits('o) = if op == VWABDACC_VV then {
                // signed absolute difference
                let diff = signed(elem_val2) - signed(elem_val1);
                zero_extend(to_bits_unsafe(SEW, if diff < 0 then -diff else diff))
            } else { // VWABDACCU_VV
                // unsigned absolute difference
                zero_extend(if unsigned(elem_val2) > unsigned(elem_val1) then elem_val2 - elem_val1 else elem_val1 - elem_val2)
            };
            result[i] = vd_val[i] + abs_diff;
        }
    };

    write_vreg(num_elem, SEW_widen, LMUL_pow_widen, vd, result);
    set_vstart(zeros());
    RETIRE_SUCCESS
}