/* ************************************************************************ */
/* This file implements part of the vector extension.                       */
/* Chapter 7: vector loads and stores                                       */

/* ************************************************************************ */

val write_single_element : forall 'm 'x, 8 <= 'm <= 128. (int('m), int('x), real, regidx, bits('m)) -> unit  effect {escape, rreg, undef, wreg}
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
    if mask_helper[i] == true then{
      let elem_offset = i * load_width_bytes ; // int
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr)  => 
          if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
            { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                MemValue(result) => total[i] = result,
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
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

val process_vse : forall 'b 'n, (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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
      match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
        Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
        Ext_DataAddr_OK(vaddr)  => 
          if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
            { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
          else match translateAddr(vaddr, Read(Data)) {
            TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
            TR_Address(paddr, _) => {
              match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                MemValue(result) => total[i] = result,
                MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
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
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);

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

val process_vsse : forall 'b 'n, (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('b), regidx, regidx, real, int('n)) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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

val process_vsxei : forall 'ib 'db 'n, (0 < 'ib & 'ib <= 8) & (0 < 'db & 'db <= 8) & (0 <= 'n & 'n <= vlen) . (bits(1), regidx, int('ib), int('db), regidx, regidx, int('n), int) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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

  foreach(a from 0 to (nf - 1)) {
    if vd_t == vd_a & a != 0 then vd_t = vd_t + 1; // emul < 1
    let vd_t_val : vector('n, dec, bits('b * 8)) = read_vreg(num_elem, load_width_bytes * 8, emul, vd_t);
    total : vector('n, dec, bits('b * 8)) = undefined;
    mask_helper : vector('n, dec, bool) = undefined;
    (total, mask_helper) = init_masked_result(num_elem, load_width_bytes * 8, emul, vd_t_val, vm_val);

    foreach (i from 0 to (num_elem - 1)) {
      if (mask_helper[i] == true) then {
        let elem_offset = load_width_bytes * (a + i * nf); //int
        match ext_data_get_addr(rs1, to_bits(sizeof(xlen), elem_offset), Read(Data), width_type) {
          Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e) ; status = RETIRE_FAIL },
          Ext_DataAddr_OK(vaddr)  => 
              if vcheck_misaligned(vaddr, width_type) then /* vaddr is the address,  when it is true, it's misaligned */
                { handle_mem_exception(vaddr, E_Load_Addr_Align()); status = RETIRE_FAIL }
              else match translateAddr(vaddr, Read(Data)) {
                TR_Failure(e, _) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL },
                TR_Address(paddr, _) => {
                  match mem_read(Read(Data), paddr, load_width_bytes, false, false, false) {
                    MemValue(result) => total[i] = result,
                    MemException(e) => { handle_mem_exception(vaddr, e); status = RETIRE_FAIL }
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
  let vsew_bits : int = get_vtype_vsew();
  let lmul : real = get_vtype_LMUL();
  let emul : real = ( to_real(veew_bits) / to_real(vsew_bits) ) * lmul;
  let num_elem : int  = get_num_elem(emul, veew_bits);// # of element of each register group
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

val process_vsseg : forall 'f 'b 'n, (0 < 'f & 'f <= 8) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('b), regidx, real, int('n)) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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

val process_vssseg : forall 'f 'b 'n, (0 < 'f & 'f <= 8) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('b), regidx, regidx, real, int('n)) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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

val process_vlxseg : forall 'f 'ib 'db 'n, (0 < 'f & 'f <= 8) & (0 < 'ib & 'ib <= 8) & (0 < 'db & 'db <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('ib), int('db), regidx, regidx, int('n), int) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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

val process_vsxseg : forall 'f 'ib 'db 'n, (0 < 'f & 'f <= 8) & (0 < 'ib & 'ib <= 8) & (0 < 'db & 'db <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), bits(1), regidx, int('ib), int('db), regidx, regidx, int('n), int) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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

val process_vsre : forall 'f 'b 'n, ('f in {1, 2, 4, 8}) & (0 < 'b & 'b <= 8) & (0 <= 'n & 'n <= vlen) . (int('f), int('b), regidx, regidx, int('n)) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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

val process_vm : forall 'n, (0 <= 'n & 'n <= vlen) . (regidx, regidx, real, int('n), vmlsop) -> Retired effect {eamem, escape, rmem, rmemt, rreg, undef, wmv, wmvt, wreg}
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
