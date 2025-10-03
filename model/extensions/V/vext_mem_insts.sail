// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ******************************************************************************
// This file implements part of the vector extension.
// Chapter 7: Vector Loads and Stores
// ******************************************************************************

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

mapping vlewidth_pow : vlewidth <-> {3, 4, 5, 6} = {
  VLE8      <-> 3,
  VLE16     <-> 4,
  VLE32     <-> 5,
  VLE64     <-> 6
}

// ******************* Vector Load Unit-Stride Normal & Segment (mop=0b00, lumop=0b00000) *********************
union clause instruction = VLSEGTYPE : (nfields, bits(1), regidx, vlewidth, vregidx)

mapping clause encdec = VLSEGTYPE(nf, vm, rs1, width, vd)
  <-> encdec_nfields(nf) @ 0b0 @ 0b00 @ vm @ 0b00000 @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vd) @ 0b0000111
  when currentlyEnabled(Ext_V)

val process_vlseg : (nfields, bits(1), vregidx, word_width, regidx, int, range(1, vlen)) -> ExecutionResult
function process_vlseg (nf, vm, vd, load_width_bytes, rs1, EMUL_pow, num_elem) = {
  let EMUL_reg = if EMUL_pow <= 0 then 1 else 2 ^ EMUL_pow;
  let vm_val = read_vmask(num_elem, vm, zvreg);
  let vd_seg = read_vreg_seg(num_elem, load_width_bytes * 8, EMUL_pow, nf, vd);

  let 'm = nf * load_width_bytes * 8;
  let 'n = num_elem;
  let (result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, 'm, EMUL_pow, vd_seg, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then { // active segments
      set_vstart(to_bits_unsafe(16, i));
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = (i * nf + j) * load_width_bytes;
        match vmem_read(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, Read(Data), false, false, false) {
          Ok(elem) => write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_reg)), elem),
          Err(e)   => return e,
        }
      }
    } else { // prestart, masked or tail segments
      foreach (j from 0 to (nf - 1)) {
        let skipped_elem = (result[i] >> (j * load_width_bytes * 8))[(load_width_bytes * 8 - 1) .. 0];
        write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_reg)), skipped_elem)
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VLSEGTYPE(nf, vm, rs1, width, vd)) = {
  let EEW_pow = vlewidth_pow(width);
  let load_width_bytes = 2 ^ (EEW_pow - 3);
  let EEW = 2 ^ EEW_pow;
  let SEW_pow = get_sew_pow();
  let LMUL_pow = get_lmul_pow();
  let EMUL_pow = EEW_pow - SEW_pow + LMUL_pow;
  // TODO: The EMUL_pow calculation here is incorrect. See https://github.com/riscv/sail-riscv/issues/1196
  assert(-3 <= EMUL_pow & EMUL_pow <= 3);
  let num_elem = get_num_elem(EMUL_pow, EEW); // # of element of each register group

  assert(num_elem > 0);

  if illegal_load(vd, vm, nf, EEW, EMUL_pow) then return Illegal_Instruction();

  process_vlseg(nf, vm, vd, load_width_bytes, rs1, EMUL_pow, num_elem)
}

mapping clause assembly = VLSEGTYPE(nf, vm, rs1, width, vd)
  <-> "vl" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ maybe_vmask(vm)

// *********** Vector Load Unit-Stride Normal & Segment Fault-Only-First (mop=0b00, lumop=0b10000) ************
union clause instruction = VLSEGFFTYPE : (nfields, bits(1), regidx, vlewidth, vregidx)

mapping clause encdec = VLSEGFFTYPE(nf, vm, rs1, width, vd)
  <-> encdec_nfields(nf) @ 0b0 @ 0b00 @ vm @ 0b10000 @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vd) @ 0b0000111
  when currentlyEnabled(Ext_V)

val process_vlsegff : (nfields, bits(1), vregidx, word_width, regidx, int, range(1, vlen)) -> ExecutionResult
function process_vlsegff (nf, vm, vd, load_width_bytes, rs1, EMUL_pow, num_elem) = {
  let EMUL_reg = if EMUL_pow <= 0 then 1 else 2 ^ EMUL_pow;
  let vm_val = read_vmask(num_elem, vm, zvreg);
  let vd_seg = read_vreg_seg(num_elem, load_width_bytes * 8, EMUL_pow, nf, vd);
  let tail_ag = get_vtype_vta();

  let 'm = nf * load_width_bytes * 8;
  let 'n = num_elem;
  let (result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, nf * load_width_bytes * 8, EMUL_pow, vd_seg, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  var trimmed : bool = false;
  foreach (i from 0 to (num_elem - 1)) {
    if not(trimmed) then {
      if mask[i] == bitone then { // active segments
        foreach (j from 0 to (nf - 1)) {
          let elem_offset = (i * nf + j) * load_width_bytes;
          match vmem_read(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, Read(Data), false, false, false) {
            Ok(elem) => write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_reg)), elem),
            Err(e)   => if i == 0 then return e
                        else {
                          vl = to_bits_unsafe(xlen, i);
                          csr_write_callback("vl", vl);
                          trimmed = true
                        },
          }
        }
      } else { // prestart, masked or tail segments
        foreach (j from 0 to (nf - 1)) {
          let skipped_elem = (result[i] >> (j * load_width_bytes * 8))[(load_width_bytes * 8 - 1) .. 0];
          write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_reg)), skipped_elem)
        }
      }
    } else {
      // if vl is trimmed, elements past the new vl are treated as tail elements
      if tail_ag == AGNOSTIC then {
        foreach (j from 0 to (nf - 1)) {
          let skipped_elem = (vd_seg[i] >> (j * load_width_bytes * 8))[(load_width_bytes * 8 - 1) .. 0];
          write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_reg)), skipped_elem)
        }
        // TODO: configuration support for agnostic behavior
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VLSEGFFTYPE(nf, vm, rs1, width, vd)) = {
  let EEW_pow = vlewidth_pow(width);
  let load_width_bytes = 2 ^ (EEW_pow - 3);
  let EEW = 2 ^ EEW_pow;
  let SEW_pow = get_sew_pow();
  let LMUL_pow = get_lmul_pow();
  let EMUL_pow = EEW_pow - SEW_pow + LMUL_pow;
  // TODO: The EMUL_pow calculation here is incorrect. See https://github.com/riscv/sail-riscv/issues/1196
  assert(-3 <= EMUL_pow & EMUL_pow <= 3);
  let num_elem = get_num_elem(EMUL_pow, EEW);

  assert(num_elem > 0);

  if illegal_load(vd, vm, nf, EEW, EMUL_pow) then return Illegal_Instruction();

  process_vlsegff(nf, vm, vd, load_width_bytes, rs1, EMUL_pow, num_elem)
}

mapping clause assembly = VLSEGFFTYPE(nf, vm, rs1, width, vd)
  <-> "vl" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ "ff.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ maybe_vmask(vm)

// ******************* Vector Store Unit-Stride Normal & Segment (mop=0b00, sumop=0b00000) ********************
union clause instruction = VSSEGTYPE : (nfields, bits(1), regidx, vlewidth, vregidx)

mapping clause encdec = VSSEGTYPE(nf, vm, rs1, width, vs3)
  <-> encdec_nfields(nf) @ 0b0 @ 0b00 @ vm @ 0b00000 @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vs3) @ 0b0100111
  when currentlyEnabled(Ext_V)

val process_vsseg : (nfields, bits(1), vregidx, word_width, regidx, int, range(1, vlen)) -> ExecutionResult
function process_vsseg (nf, vm, vs3, load_width_bytes, rs1, EMUL_pow, num_elem) = {
  let EMUL_reg = if EMUL_pow <= 0 then 1 else 2 ^ EMUL_pow;
  let vm_val = read_vmask(num_elem, vm, zvreg);
  let vs3_seg = read_vreg_seg(num_elem, load_width_bytes * 8, EMUL_pow, nf, vs3);

  let 'n = num_elem;
  let mask : bits('n) = match init_masked_source(num_elem, EMUL_pow, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then { // active segments
      set_vstart(to_bits_unsafe(16, i));
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = (i * nf + j) * load_width_bytes;
        let vs = vregidx_offset(vs3, to_bits_unsafe(5, j * EMUL_reg));
        let data = read_single_element(load_width_bytes * 8, i, vs);
        match vmem_write(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, data, Write(Data), false, false, false) {
          Ok(true)  => (),
          Ok(false) => internal_error(__FILE__, __LINE__, "store got false from vmem_write"),
          Err(e)    => return e,
        }
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VSSEGTYPE(nf, vm, rs1, width, vs3)) = {
  let EEW_pow = vlewidth_pow(width);
  let load_width_bytes = 2 ^ (EEW_pow - 3);
  let EEW = 2 ^ EEW_pow;
  let SEW_pow = get_sew_pow();
  let LMUL_pow = get_lmul_pow();
  let EMUL_pow = EEW_pow - SEW_pow + LMUL_pow;
  // TODO: The EMUL_pow calculation here is incorrect. See https://github.com/riscv/sail-riscv/issues/1196
  assert(-3 <= EMUL_pow & EMUL_pow <= 3);
  let num_elem = get_num_elem(EMUL_pow, EEW);

  assert(num_elem > 0);

  if illegal_store(nf, EEW, EMUL_pow) then return Illegal_Instruction();

  process_vsseg(nf, vm, vs3, load_width_bytes, rs1, EMUL_pow, num_elem)
}

mapping clause assembly = VSSEGTYPE(nf, vm, rs1, width, vs3)
  <-> "vs" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ maybe_vmask(vm)

// ***************************** Vector Load Strided Normal & Segment (mop=0b10) ******************************
union clause instruction = VLSSEGTYPE : (nfields, bits(1), regidx, regidx, vlewidth, vregidx)

mapping clause encdec = VLSSEGTYPE(nf, vm, rs2, rs1, width, vd)
  <-> encdec_nfields(nf) @ 0b0 @ 0b10 @ vm @ encdec_reg(rs2) @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vd) @ 0b0000111
  when currentlyEnabled(Ext_V)

val process_vlsseg : (nfields, bits(1), vregidx, word_width, regidx, regidx, int, range(1, vlen)) -> ExecutionResult
function process_vlsseg (nf, vm, vd, load_width_bytes, rs1, rs2, EMUL_pow, num_elem) = {
  let EMUL_reg = if EMUL_pow <= 0 then 1 else 2 ^ EMUL_pow;
  let vm_val  = read_vmask(num_elem, vm, zvreg);
  let vd_seg  = read_vreg_seg(num_elem, load_width_bytes * 8, EMUL_pow, nf, vd);
  let rs2_val = unsigned(get_scalar(rs2, xlen));

  let 'm = nf * load_width_bytes * 8;
  let 'n = num_elem;
  let (result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, nf * load_width_bytes * 8, EMUL_pow, vd_seg, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then { // active segments
      set_vstart(to_bits_unsafe(16, i));
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = i * rs2_val + j * load_width_bytes;
        match vmem_read(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, Read(Data), false, false, false) {
          Ok(elem) => write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_reg)), elem),
          Err(e)   => return e,
        }
      }
    } else { // prestart, masked or tail segments
      foreach (j from 0 to (nf - 1)) {
        let skipped_elem = (result[i] >> (j * load_width_bytes * 8))[(load_width_bytes * 8 - 1) .. 0];
        write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_reg)), skipped_elem)
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VLSSEGTYPE(nf, vm, rs2, rs1, width, vd)) = {
  let EEW_pow = vlewidth_pow(width);
  let load_width_bytes = 2 ^ (EEW_pow - 3);
  let EEW = 2 ^ EEW_pow;
  let SEW_pow = get_sew_pow();
  let LMUL_pow = get_lmul_pow();
  let EMUL_pow = EEW_pow - SEW_pow + LMUL_pow;
  // TODO: The EMUL_pow calculation here is incorrect. See https://github.com/riscv/sail-riscv/issues/1196
  assert(-3 <= EMUL_pow & EMUL_pow <= 3);
  let num_elem = get_num_elem(EMUL_pow, EEW);

  assert(num_elem > 0);

  if illegal_load(vd, vm, nf, EEW, EMUL_pow) then return Illegal_Instruction();

  process_vlsseg(nf, vm, vd, load_width_bytes, rs1, rs2, EMUL_pow, num_elem)
}

mapping clause assembly = VLSSEGTYPE(nf, vm, rs2, rs1, width, vd)
  <-> "vls" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ sep() ^ reg_name(rs2) ^ maybe_vmask(vm)

// **************************** Vector Store Strided Normal & Segment (mop=0b10) ******************************
union clause instruction = VSSSEGTYPE : (nfields, bits(1), regidx, regidx, vlewidth, vregidx)

mapping clause encdec = VSSSEGTYPE(nf, vm, rs2, rs1, width, vs3)
  <-> encdec_nfields(nf) @ 0b0 @ 0b10 @ vm @ encdec_reg(rs2) @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vs3) @ 0b0100111
  when currentlyEnabled(Ext_V)

val process_vssseg : (nfields, bits(1), vregidx, word_width, regidx, regidx, int, range(1, vlen)) -> ExecutionResult
function process_vssseg (nf, vm, vs3, load_width_bytes, rs1, rs2, EMUL_pow, num_elem) = {
  let EMUL_reg = if EMUL_pow <= 0 then 1 else 2 ^ EMUL_pow;
  let vm_val = read_vmask(num_elem, vm, zvreg);
  let vs3_seg = read_vreg_seg(num_elem, load_width_bytes * 8, EMUL_pow, nf, vs3);
  let rs2_val = unsigned(get_scalar(rs2, xlen));

  let 'n = num_elem;
  let mask : bits('n) = match init_masked_source(num_elem, EMUL_pow, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then { // active segments
      set_vstart(to_bits_unsafe(16, i));
      foreach (j from 0 to (nf - 1)) {
        let elem_offset = i * rs2_val + j * load_width_bytes;
        let vs = vregidx_offset(vs3, to_bits_unsafe(5, j * EMUL_reg));
        let data = read_single_element(load_width_bytes * 8, i, vs);
        match vmem_write(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, data, Write(Data), false, false, false) {
          Ok(true)  => (),
          Ok(false) => internal_error(__FILE__, __LINE__, "store got false from vmem_write"),
          Err(e)    => return e,
        }
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VSSSEGTYPE(nf, vm, rs2, rs1, width, vs3)) = {
  let EEW_pow = vlewidth_pow(width);
  let EEW = 2 ^ EEW_pow;
  let load_width_bytes = 2 ^ (EEW_pow - 3);
  let SEW_pow = get_sew_pow();
  let LMUL_pow = get_lmul_pow();
  let EMUL_pow = EEW_pow - SEW_pow + LMUL_pow;
  // TODO: The EMUL_pow calculation here is incorrect. See https://github.com/riscv/sail-riscv/issues/1196
  assert(-3 <= EMUL_pow & EMUL_pow <= 3);
  let num_elem = get_num_elem(EMUL_pow, EEW);

  assert(num_elem > 0);

  if illegal_store(nf, EEW, EMUL_pow) then return Illegal_Instruction();

  process_vssseg(nf, vm, vs3, load_width_bytes, rs1, rs2, EMUL_pow, num_elem)
}

mapping clause assembly = VSSSEGTYPE(nf, vm, rs2, rs1, width, vs3)
  <-> "vss" ^ nfields_string(nf) ^ "e" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ sep() ^ reg_name(rs2) ^ maybe_vmask(vm)

// ************************ Vector Load Indexed Unordered Normal & Segment (mop=0b01) *************************
union clause instruction = VLUXSEGTYPE : (nfields, bits(1), vregidx, regidx, vlewidth, vregidx)

mapping clause encdec = VLUXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> encdec_nfields(nf) @ 0b0 @ 0b01 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vd) @ 0b0000111
  when currentlyEnabled(Ext_V)

val process_vlxseg : (nfields, bits(1), vregidx, word_width, word_width, int, int, regidx, vregidx, range(1, vlen), int) -> ExecutionResult
function process_vlxseg (nf, vm, vd, EEW_index_bytes, EEW_data_bytes, EMUL_index_pow, EMUL_data_pow, rs1, vs2, num_elem, mop) = {
  let EMUL_data_reg = if EMUL_data_pow <= 0 then 1 else 2 ^ EMUL_data_pow;
  let vm_val = read_vmask(num_elem, vm, zvreg);
  let vd_seg = read_vreg_seg(num_elem, EEW_data_bytes * 8, EMUL_data_pow, nf, vd);
  let vs2_val = read_vreg(num_elem, EEW_index_bytes * 8, EMUL_index_pow, vs2);

  let 'm = nf * EEW_data_bytes * 8;
  let 'n = num_elem;
  let (result, mask) : (vector('n, bits('m)), bits('n)) = match init_masked_result(num_elem, nf * EEW_data_bytes * 8, EMUL_data_pow, vd_seg, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  // currently mop = 1 (unordered) or 3 (ordered) do the same operations
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then { // active segments
      set_vstart(to_bits_unsafe(16, i));
      foreach (j from 0 to (nf - 1)) {
        let elem_offset : int = unsigned(vs2_val[i]) + j * EEW_data_bytes;
        match vmem_read(rs1, to_bits_unsafe(xlen, elem_offset), EEW_data_bytes, Read(Data), false, false, false) {
          Ok(elem) => write_single_element(EEW_data_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_data_reg)), elem),
          Err(e)   => return e,
        }
      }
    } else { // prestart, masked or tail segments
      foreach (j from 0 to (nf - 1)) {
        let skipped_elem = (result[i] >> (j * EEW_data_bytes * 8))[(EEW_data_bytes * 8 - 1) .. 0];
        write_single_element(EEW_data_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j * EMUL_data_reg)), skipped_elem)
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VLUXSEGTYPE(nf, vm, vs2, rs1, width, vd)) = {
  let EEW_index_pow = vlewidth_pow(width);
  let EEW_index_bytes = 2 ^ (EEW_index_pow - 3);
  let EEW_data_pow = get_sew_pow();
  let EEW_data_bytes = get_sew_bytes();
  let EMUL_data_pow = get_lmul_pow();
  let EMUL_index_pow = EEW_index_pow - EEW_data_pow + EMUL_data_pow;
  let num_elem = get_num_elem(EMUL_data_pow, EEW_data_bytes * 8);

  assert(num_elem > 0);

  if illegal_indexed_load(vd, vm, nf, 2 ^ EEW_index_pow, EMUL_index_pow, EMUL_data_pow)
  then return Illegal_Instruction();

  process_vlxseg(nf, vm, vd, EEW_index_bytes, EEW_data_bytes, EMUL_index_pow, EMUL_data_pow, rs1, vs2, num_elem, 1)
}

mapping clause assembly = VLUXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> "vlux" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

// ************************* Vector Load Indexed Ordered Normal & Segment (mop=0b11) **************************
union clause instruction = VLOXSEGTYPE : (nfields, bits(1), vregidx, regidx, vlewidth, vregidx)

mapping clause encdec = VLOXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> encdec_nfields(nf) @ 0b0 @ 0b11 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vd) @ 0b0000111
  when currentlyEnabled(Ext_V)

function clause execute(VLOXSEGTYPE(nf, vm, vs2, rs1, width, vd)) = {
  let EEW_index_pow = vlewidth_pow(width);
  let EEW_index_bytes = 2 ^ (EEW_index_pow - 3);
  let EEW_data_pow = get_sew_pow();
  let EEW_data_bytes = get_sew_bytes();
  let EMUL_data_pow = get_lmul_pow();
  let EMUL_index_pow = EEW_index_pow - EEW_data_pow + EMUL_data_pow;
  let num_elem = get_num_elem(EMUL_data_pow, EEW_data_bytes * 8);

  assert(num_elem > 0);

  if illegal_indexed_load(vd, vm, nf, 2 ^ EEW_index_pow, EMUL_index_pow, EMUL_data_pow)
  then return Illegal_Instruction();

  process_vlxseg(nf, vm, vd, EEW_index_bytes, EEW_data_bytes, EMUL_index_pow, EMUL_data_pow, rs1, vs2, num_elem, 3)
}

mapping clause assembly = VLOXSEGTYPE(nf, vm, vs2, rs1, width, vd)
  <-> "vlox" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

// *********************** Vector Store Indexed Unordered Normal & Segment (mop=0b01) *************************
union clause instruction = VSUXSEGTYPE : (nfields, bits(1), vregidx, regidx, vlewidth, vregidx)

mapping clause encdec = VSUXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> encdec_nfields(nf) @ 0b0 @ 0b01 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vs3) @ 0b0100111
  when currentlyEnabled(Ext_V)

val process_vsxseg : (nfields, bits(1), vregidx, word_width, word_width, int, int, regidx, vregidx, range(1, vlen), int) -> ExecutionResult
function process_vsxseg (nf, vm, vs3, EEW_index_bytes, EEW_data_bytes, EMUL_index_pow, EMUL_data_pow, rs1, vs2, num_elem, mop) = {
  let EMUL_data_reg = if EMUL_data_pow <= 0 then 1 else 2 ^ EMUL_data_pow;
  let vm_val = read_vmask(num_elem, vm, zvreg);
  let vs3_seg = read_vreg_seg(num_elem, EEW_data_bytes * 8, EMUL_data_pow, nf, vs3);
  let vs2_val = read_vreg(num_elem, EEW_index_bytes * 8, EMUL_index_pow, vs2);

  let 'n = num_elem;
  let mask : bits('n) = match init_masked_source(num_elem, EMUL_data_pow, vm_val) {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };

  // currently mop = 1 (unordered) or 3 (ordered) do the same operations
  foreach (i from 0 to (num_elem - 1)) {
    if mask[i] == bitone then { // active segments
      set_vstart(to_bits_unsafe(16, i));
      foreach (j from 0 to (nf - 1)) {
        let elem_offset : int = unsigned(vs2_val[i]) + j * EEW_data_bytes;
        let vs = vregidx_offset(vs3, to_bits_unsafe(5, j * EMUL_data_reg));
        let data = read_single_element(EEW_data_bytes * 8, i, vs);
        match vmem_write(rs1, to_bits_unsafe(xlen, elem_offset), EEW_data_bytes, data, Write(Data), false, false, false) {
          Ok(true)  => (),
          Ok(false) => internal_error(__FILE__, __LINE__, "store got false from vmem_write"),
          Err(e)    => return e,
        }
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VSUXSEGTYPE(nf, vm, vs2, rs1, width, vs3)) = {
  let EEW_index_pow = vlewidth_pow(width);
  let EEW_index_bytes = 2 ^ (EEW_index_pow - 3);
  let EEW_data_pow = get_sew_pow();
  let EEW_data_bytes = get_sew_bytes();
  let EMUL_data_pow = get_lmul_pow();
  let EMUL_index_pow = EEW_index_pow - EEW_data_pow + EMUL_data_pow;
  let num_elem = get_num_elem(EMUL_data_pow, EEW_data_bytes * 8); // number of data and indices are the same

  assert(num_elem > 0);

  if illegal_indexed_store(nf, 2 ^ EEW_index_pow, EMUL_index_pow, EMUL_data_pow)
  then return Illegal_Instruction();

  process_vsxseg(nf, vm, vs3, EEW_index_bytes, EEW_data_bytes, EMUL_index_pow, EMUL_data_pow, rs1, vs2, num_elem, 1)
}

mapping clause assembly = VSUXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> "vsux" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

// ************************ Vector Store Indexed Ordered Normal & Segment (mop=0b11) **************************
union clause instruction = VSOXSEGTYPE : (nfields, bits(1), vregidx, regidx, vlewidth, vregidx)

mapping clause encdec = VSOXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> encdec_nfields(nf) @ 0b0 @ 0b11 @ vm @ encdec_vreg(vs2) @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vs3) @ 0b0100111
  when currentlyEnabled(Ext_V)

function clause execute(VSOXSEGTYPE(nf, vm, vs2, rs1, width, vs3)) = {
  let EEW_index_pow = vlewidth_pow(width);
  let EEW_index_bytes = 2 ^ (EEW_index_pow - 3);
  let EEW_data_pow = get_sew_pow();
  let EEW_data_bytes = get_sew_bytes();
  let EMUL_data_pow = get_lmul_pow();
  let EMUL_index_pow = EEW_index_pow - EEW_data_pow + EMUL_data_pow;
  let num_elem = get_num_elem(EMUL_data_pow, EEW_data_bytes * 8); // number of data and indices are the same

  assert(num_elem > 0);

  if illegal_indexed_store(nf, 2 ^ EEW_index_pow, EMUL_index_pow, EMUL_data_pow)
  then return Illegal_Instruction();

  process_vsxseg(nf, vm, vs3, EEW_index_bytes, EEW_data_bytes, EMUL_index_pow, EMUL_data_pow, rs1, vs2, num_elem, 3)
}

mapping clause assembly = VSOXSEGTYPE(nf, vm, vs2, rs1, width, vs3)
  <-> "vsox" ^ nfields_string(nf) ^ "ei" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")" ^ sep() ^ vreg_name(vs2) ^ maybe_vmask(vm)

// **************** Vector Load Unit-Stride Whole Register (vm=0b1, mop=0b00, lumop=0b01000) ******************
union clause instruction = VLRETYPE : (nfields_pow2, regidx, vlewidth, vregidx)

mapping clause encdec = VLRETYPE(nf, rs1, width, vd)
  <-> encdec_nfields_pow2(nf) @ 0b0 @ 0b00 @ 0b1 @ 0b01000 @ encdec_reg(rs1) @ encdec_vlewidth(width) @ encdec_vreg(vd) @ 0b0000111
  when currentlyEnabled(Ext_V)

val process_vlre : (nfields_pow2, vregidx, word_width, regidx, nat) -> ExecutionResult
function process_vlre (nf, vd, load_width_bytes, rs1, elem_per_reg) = {
  let start_element : nat = match get_start_element() {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  if start_element >= nf * elem_per_reg then return RETIRE_SUCCESS; // no elements are written if vstart >= evl
  let elem_to_align : int = start_element % elem_per_reg;
  var cur_field : int = start_element / elem_per_reg;
  var cur_elem  : int = start_element;

  if elem_to_align > 0 then {
    foreach (i from elem_to_align to (elem_per_reg - 1)) {
      set_vstart(to_bits_unsafe(16, cur_elem));
      let elem_offset = cur_elem * load_width_bytes;
      match vmem_read(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, Read(Data), false, false, false) {
        Ok(elem) => write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, cur_field)), elem),
        Err(e)   => return e,
      };
      cur_elem = cur_elem + 1
    };
    cur_field = cur_field + 1
  };

  foreach (j from cur_field to (nf - 1)) {
    foreach (i from 0 to (elem_per_reg - 1)) {
      set_vstart(to_bits_unsafe(16, cur_elem));
      let elem_offset = cur_elem * load_width_bytes;
      match vmem_read(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, Read(Data), false, false, false) {
        Ok(elem) => write_single_element(load_width_bytes * 8, i, vregidx_offset(vd, to_bits_unsafe(5, j)), elem),
        Err(e)   => return e,
      };
      cur_elem = cur_elem + 1
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VLRETYPE(nf, rs1, width, vd)) = {
  let EEW_pow = vlewidth_pow(width);
  let load_width_bytes = 2 ^ (EEW_pow - 3);
  let EEW = 2 ^ EEW_pow;
  let elem_per_reg = vlen / EEW;

  assert(elem_per_reg >= 0);

  process_vlre(nf, vd, load_width_bytes, rs1, elem_per_reg)
}

mapping clause assembly = VLRETYPE(nf, rs1, width, vd)
  <-> "vl" ^ nfields_pow2_string(nf) ^ "re" ^ vlewidth_bitsnumberstr(width) ^ ".v" ^ spc() ^ vreg_name(vd) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

// **************** Vector Store Unit-Stride Whole Register (vm=0b1, mop=0b00, lumop=0b01000) *****************
union clause instruction = VSRETYPE : (nfields_pow2, regidx, vregidx)

mapping clause encdec = VSRETYPE(nf, rs1, vs3)
  <-> encdec_nfields_pow2(nf) @ 0b0 @ 0b00 @ 0b1 @ 0b01000 @ encdec_reg(rs1) @ 0b000 @ encdec_vreg(vs3) @ 0b0100111
  when currentlyEnabled(Ext_V)

val process_vsre : (nfields_pow2, word_width, regidx, vregidx, nat) -> ExecutionResult
function process_vsre (nf, load_width_bytes, rs1, vs3, elem_per_reg) = {
  let start_element : nat = match get_start_element() {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  if start_element >= nf * elem_per_reg then return RETIRE_SUCCESS; // no elements are written if vstart >= evl
  let elem_to_align : int = start_element % elem_per_reg;
  var cur_field : int = start_element / elem_per_reg;
  var cur_elem  : int = start_element;

  if elem_to_align > 0 then {
    foreach (i from elem_to_align to (elem_per_reg - 1)) {
      set_vstart(to_bits_unsafe(16, cur_elem));
      let elem_offset : int = cur_elem * load_width_bytes;
      let vs = vregidx_offset(vs3, to_bits_unsafe(5, cur_field));
      let data = read_single_element(load_width_bytes * 8, i, vs);
      match vmem_write(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, data, Write(Data), false, false, false) {
        Ok(true)  => (),
        Ok(false) => internal_error(__FILE__, __LINE__, "store got false from vmem_write"),
        Err(e)    => return e,
      };
      cur_elem = cur_elem + 1
    };
    cur_field = cur_field + 1
  };

  foreach (j from cur_field to (nf - 1)) {
    let vs3_val = read_vreg(elem_per_reg, load_width_bytes * 8, 0, vregidx_offset(vs3, to_bits_unsafe(5, j)));
    foreach (i from 0 to (elem_per_reg - 1)) {
      set_vstart(to_bits_unsafe(16, cur_elem));
      let elem_offset = cur_elem * load_width_bytes;
      match vmem_write(rs1, to_bits_unsafe(xlen, elem_offset), load_width_bytes, vs3_val[i], Write(Data), false, false, false) {
        Ok(true)  => (),
        Ok(false) => internal_error(__FILE__, __LINE__, "store got false from vmem_write"),
        Err(e)    => return e,
      };
      cur_elem = cur_elem + 1
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VSRETYPE(nf, rs1, vs3)) = {
  let load_width_bytes = 1;
  let EEW = 8;
  let elem_per_reg = vlen / EEW;

  assert(elem_per_reg >= 0);

  process_vsre(nf, load_width_bytes, rs1, vs3, elem_per_reg)
}

mapping clause assembly = VSRETYPE(nf, rs1, vs3)
  <-> "vs" ^ nfields_pow2_string(nf) ^ "r.v" ^ spc() ^ vreg_name(vs3) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"

// ************* Vector Mask Load/Store Unit-Stride (nf=0b000, mop=0b00, lumop or sumop=0b01011) **************
union clause instruction = VMTYPE : (regidx, vregidx, vmlsop)

mapping encdec_lsop : vmlsop <-> bits(7) = {
  VLM      <-> 0b0000111,
  VSM      <-> 0b0100111
}

mapping clause encdec = VMTYPE(rs1, vd_or_vs3, op)
  <-> 0b000 @ 0b0 @ 0b00 @ 0b1 @ 0b01011 @ encdec_reg(rs1) @ 0b000 @ encdec_vreg(vd_or_vs3) @ encdec_lsop(op)
  when currentlyEnabled(Ext_V)

val process_vm : (vregidx, regidx, nat, nat, vmlsop) -> ExecutionResult
function process_vm(vd_or_vs3, rs1, num_elem, evl, op) = {
  let start_element : nat = match get_start_element() {
    Ok(v)   => v,
    Err(()) => return Illegal_Instruction()
  };
  let 'n = num_elem;
  let vd_or_vs3_val : vector('n, bits(8)) = read_vreg(num_elem, 8, 0, vd_or_vs3);

  foreach (i from start_element to (num_elem - 1)) {
    if i < evl then { // active elements
      set_vstart(to_bits_unsafe(16, i));
      if op == VLM then { // load
        match vmem_read(rs1, to_bits_unsafe(xlen, i), 1, Read(Data), false, false, false) {
          Ok(elem) => write_single_element(8, i, vd_or_vs3, elem),
          Err(e)   => return e,
        }
      } else if op == VSM then { // store
        match vmem_write(rs1, to_bits_unsafe(xlen, i), 1, vd_or_vs3_val[i], Write(Data), false, false, false) {
          Ok(true)  => (),
          Ok(false) => internal_error(__FILE__, __LINE__, "store got false from vmem_write"),
          Err(e)    => return e,
        }
      }
    } else { // tail elements for mask load, always with agnostic policy
      if op == VLM then {
        write_single_element(8, i, vd_or_vs3, vd_or_vs3_val[i])
        // TODO: configuration support for agnostic behavior
      }
    }
  };

  set_vstart(zeros());
  RETIRE_SUCCESS
}

function clause execute(VMTYPE(rs1, vd_or_vs3, op)) = {
  let EEW = 8;
  let EMUL_pow = 0;
  let vl_val = unsigned(vl);
  let evl : int = if vl_val % 8 == 0 then vl_val / 8 else vl_val / 8 + 1; // the effective vector length is evl=ceil(vl/8)
  let num_elem = get_num_elem(EMUL_pow, EEW);

  if illegal_vd_unmasked() then return Illegal_Instruction();

  assert(evl >= 0);
  process_vm(vd_or_vs3, rs1, num_elem, evl, op)
}

mapping vmtype_mnemonic : vmlsop <-> string = {
  VLM      <-> "vlm.v",
  VSM      <-> "vsm.v"
}

mapping clause assembly = VMTYPE(rs1, vd_or_vs3, op)
  <-> vmtype_mnemonic(op) ^ spc() ^ vreg_name(vd_or_vs3) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
