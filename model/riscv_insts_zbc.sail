/* ****************************************************************** */
/* This file specifies the instructions in the BitManip Zbc extension */
  
/* ****************************************************************** */
union clause ast = ZBC_RTYPE : (regidx, regidx, regidx, brop)

mapping clause encdec = ZBC_RTYPE(rs2, rs1, rd, RISCV_CLMUL) if haveZbc()
  <-> 0b0000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011

mapping clause encdec = ZBC_RTYPE(rs2, rs1, rd, RISCV_CLMULH) if haveZbc()
  <-> 0b0000101 @ rs2 @ rs1 @ 0b011 @ rd @ 0b0110011

mapping clause encdec = ZBC_RTYPE(rs2, rs1, rd, RISCV_CLMULR) if haveZbc()
  <-> 0b0000101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b0110011

mapping zbc_rtype_mnemonic : brop <-> string = {
  RISCV_CLMUL  <-> "clmul",
  RISCV_CLMULH <-> "clmulh",
  RISCV_CLMULR <-> "clmulr"
}

mapping clause assembly = ZBC_RTYPE(rs2, rs1, rd, op)
  <-> zbc_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBC_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  result : xlenbits = EXTZ(0x0);
  foreach (i from 0 to (xlen_val - 1) by 1) {
    result = match op {
      RISCV_CLMUL  => if ((rs2_val >> i)[0] == bitone)
                        then result ^ (rs1_val << i)
                        else result,
      RISCV_CLMULH => if ((rs2_val >> i)[0] == bitone)
                        then result ^ (rs1_val >> (xlen_val - i))
                        else result,
      RISCV_CLMULR => if ((rs2_val >> i)[0] == bitone)
                        then result ^ (rs1_val >> (xlen_val - i - 1))
                        else result
    };
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
