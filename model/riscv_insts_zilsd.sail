/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause extensionEnabled(Ext_Zilsd) = sys_enable_zilsd() & xlen == 32

/* ****************************************************************** */
union clause ast = ZILSD_LD : (bits(12), regidx, regidx)

mapping clause encdec = ZILSD_LD(imm, rs1, rd)
  <-> imm @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0000011
  when extensionEnabled(Ext_Zilsd) & not(bit_to_bool(encdec_reg(rd)[0]))

function load_imm(imm : bits(12), base_val : xlenbits, rd : regidx, width : word_width) -> Retired = {
  let offset : xlenbits = sign_extend(imm);
  let width_bytes = size_bytes(width);
  assert(width_bytes <= xlen_bytes);

  let vaddr = Virtaddr(base_val + offset);
  if   check_misaligned(vaddr, width)
  then { handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL }
  else match translateAddr(vaddr, Read(Data)) {
    TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
    TR_Address(paddr, _) => {
      match mem_read(Read(Data), paddr, width_bytes, false, false, false) {
        Ok(result) => { X(rd) = extend_value(false, result); RETIRE_SUCCESS },
        Err(e)     => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
      }
  },
  }
}

function clause execute ZILSD_LD(imm, rs1, rd) = {
  if rd != zreg then {
    let base_val = X(rs1);
    let _ = load_imm(imm, base_val, rd, WORD);
    load_imm(imm+4, base_val, rd+1, WORD)
  } else {
    RETIRE_SUCCESS
  }
}
mapping clause assembly = ZILSD_LD(imm, rs1, rd) <-> "ld" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_12(imm) ^ "(" ^ reg_name(rs1) ^ ")"


/* ****************************************************************** */
union clause ast = ZILSD_SD : (bits(12), regidx, regidx)

mapping clause encdec = ZILSD_SD(imm7 @ imm5, rs2, rs1)
  <-> imm7 : bits(7) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ imm5 : bits(5) @ 0b0100011
  when extensionEnabled(Ext_Zilsd) & not(bit_to_bool(encdec_reg(rs2)[0]))

function store_imm(imm : bits(12), rs2_val : xlenbits, base_val : xlenbits, width : word_width) -> Retired = {
  let offset : xlenbits = sign_extend(imm);
  let width_bytes = size_bytes(width);
  assert(width_bytes <= xlen_bytes);

  let vaddr = Virtaddr(base_val + offset);
  if   check_misaligned(vaddr, width)
  then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
  else match translateAddr(vaddr, Write(Data)) {
    TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
    TR_Address(paddr, _) => {
      match mem_write_ea(paddr, width_bytes, false, false, false) {
        Err(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        Ok(_)  => {
          match mem_write_value(paddr, width_bytes, rs2_val[width_bytes * 8 - 1 .. 0], false, false, false) {
            Ok(true)  => RETIRE_SUCCESS,
            Ok(false) => internal_error(__FILE__, __LINE__, "store got false from mem_write_value"),
            Err(e)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
          }
        }
      }
    }
  }
}

function clause execute ZILSD_SD(imm, rs2, rs1) = {
  let base_val = X(rs1);
  let rs2_val = X(rs2);
  let rs2_pair_val = if rs2 != zreg then X(rs2+1) else rs2_val;
  let _ = store_imm(imm, rs2_val, base_val, WORD);
  store_imm(imm+4, rs2_pair_val, base_val, WORD)
}

mapping clause assembly = ZILSD_SD(offset, rs2, rs1) <-> "sd" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_signed_12(offset) ^ "(" ^ reg_name(rs1) ^ ")"
