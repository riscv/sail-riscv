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

// TODO: According to the spec, an implementation can generate a
// misaligned trap when performing these instructions at 4B-aligned
// but not 8B-aligned addresses.  The implementation below does not
// model this, since it always performs word accesses.

/* ****************************************************************** */
union clause instruction = ZILSD_LD : (bits(12), regidx, regidx)

$[wavedrom "offset[11:5] base width=D dest LOAD"]
mapping clause encdec = ZILSD_LD(imm, rs1, rd)
  <-> imm @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0000011
  when currentlyEnabled(Ext_Zilsd) & validZilsdReg(rd)

function clause execute ZILSD_LD(imm, rs1, rd) = {
  assert(xlen == 32);
  let access = Load(Data);
  match vmem_read(rs1, sign_extend(imm), 4, access, false, false, false) {
    Ok(lo) => {
      match vmem_read(rs1, sign_extend(imm + 4), 4, access, false, false, false) {
        Ok(hi) => { X_pair(rd) = hi @ lo; RETIRE_SUCCESS },
        Err(e) => e,
      }
    },
    Err(e) => e,
  }
}
mapping clause assembly = ZILSD_LD(imm, rs1, rd) <-> "ld" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_12(imm) ^ "(" ^ reg_name(rs1) ^ ")"


/* ****************************************************************** */
union clause instruction = ZILSD_SD : (bits(12), regidx, regidx)

$[wavedrom "offset[11:5] src base width=D offset[4:0] STORE"]
mapping clause encdec = ZILSD_SD(imm, rs2, rs1)
  <-> imm[11 .. 5] @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ imm[4 .. 0] @ 0b0100011
  when currentlyEnabled(Ext_Zilsd) & validZilsdReg(rs2)

function clause execute ZILSD_SD(imm, rs2, rs1) = {
  assert(xlen == 32);
  let value = X_pair(rs2);
  let access = Store(Data);
  match vmem_write(rs1, sign_extend(imm), 4, value[31 .. 0], access, false, false, false) {
    Ok(_)  => {
      match vmem_write(rs1, sign_extend(imm + 4), 4, value[63 .. 32], access, false, false, false) {
        Ok(_)  => RETIRE_SUCCESS,
        Err(e) => e,
      }
    },
    Err(e) => e,
  }
}

mapping clause assembly = ZILSD_SD(offset, rs2, rs1) <-> "sd" ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_signed_12(offset) ^ "(" ^ reg_name(rs1) ^ ")"
