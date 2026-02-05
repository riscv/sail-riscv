/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

function clause currentlyEnabled(Ext_Zilsd) = hartSupports(Ext_Zilsd) & xlen == 32

// Zilsd requires even register pairs
function validZilsdReg(reg : regidx) -> bool = {
  if   encdec_reg(reg)[0] == 0b1
  then match rv32load_store_pair_odd_register_reserved_behavior {
    LoadStorePair_Fatal   => reserved_behavior("Zilsd used odd-numbered register " ^ dec_str(unsigned(encdec_reg(reg)))),
    LoadStorePair_Illegal => return false,
  };
  true
}

/* ****************************************************************** */
union clause instruction = ZILSD_LD : (bits(12), regidx, regidx)

$[wavedrom "offset[11:5] src base _ width imm[4:0] STORE"]
mapping clause encdec = ZILSD_LD(imm, rs1, rd)
  <-> imm @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0000011
  when currentlyEnabled(Ext_Zilsd) & validZilsdReg(rd)

private function load_imm forall 'n, 'n in {1, 2, 4, 8}. (vaddr: virtaddr, width : int('n)) -> result(bits(8 * 'n), ExceptionType) = {
  if   check_misaligned(vaddr, width)
  then Err(E_Load_Addr_Align())
  else match translateAddr(vaddr, Load(Data)) {
    Err(e, _)    => Err(e),
    Ok(paddr, _) => {
      match mem_read(Load(Data), paddr, width, false, false, false) {
        Ok(result) => Ok(result),
        Err(e)     => Err(e),
      }
    },
  }
}

function clause execute ZILSD_LD(imm, rs1, rd) = {
  assert(xlen == 32);
  if rd == zreg then {
    return RETIRE_SUCCESS;
  };
  let base_addr = X(rs1);
  let vaddr = Virtaddr(base_addr + sign_extend(imm));
  match load_imm(vaddr, 4) {
    Err(e) => Memory_Exception(vaddr, e),
    Ok(lo) => {
      let vaddr = Virtaddr(base_addr + sign_extend(imm + 4));
      match load_imm(vaddr, 4) {
        Err(e) => Memory_Exception(vaddr, e),
        Ok(hi) => { X_pair(rd) = hi @ lo; RETIRE_SUCCESS },
      }
    }
  }
}
mapping clause assembly = ZILSD_LD(imm, rs1, rd) <-> "ld" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_12(imm) ^ "(" ^ reg_name(rs1) ^ ")"


/* ****************************************************************** */
union clause instruction = ZILSD_SD : (bits(12), regidx, regidx)

$[wavedrom "offset[11:0] base _ width dest LOAD"]
mapping clause encdec = ZILSD_SD(imm7 @ imm5, rs2, rs1)
  <-> imm7 : bits(7) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ imm5 : bits(5) @ 0b0100011
  when currentlyEnabled(Ext_Zilsd) & validZilsdReg(rs2)

private function store_imm forall 'n, 'n in {1, 2, 4, 8}. (vaddr: virtaddr, width : int('n), value : bits(8 * 'n)) -> option(ExceptionType) = {
  if   check_misaligned(vaddr, width)
  then Some(E_SAMO_Addr_Align())
  else match translateAddr(vaddr, Store(Data)) {
    Err(e, _)    => Some(e),
    Ok(paddr, _) => match mem_write_ea(paddr, width, false, false, false) {
      Err(e) => Some(e),
      Ok(_)  => match mem_write_value(paddr, width, value, false, false, false) {
        Ok(true)  => None(),
        Ok(false) => internal_error(__FILE__, __LINE__, "store got false from mem_write_value"),
        Err(e)    => Some(e)
      }
    }
  }
}

function clause execute ZILSD_SD(imm, rs2, rs1) = {
  let base_addr = X(rs1);
  let value = X_pair(rs2);
  let vaddr = Virtaddr(base_addr + sign_extend(imm));
  match store_imm(vaddr, xlen_bytes, value[xlen - 1 .. 0]) {
    Some(e) => Memory_Exception(vaddr, e),
    None()  => {
      let vaddr = Virtaddr(base_addr + sign_extend(imm + 4));
      match store_imm(vaddr, xlen_bytes, value[2 * xlen - 1 .. xlen]) {
        Some(e) => Memory_Exception(vaddr, e),
        None()  => RETIRE_SUCCESS,
      }
    }
  }
}

mapping clause assembly = ZILSD_SD(offset, rs2, rs1) <-> "sd" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_signed_12(offset) ^ "(" ^ reg_name(rs1) ^ ")"
