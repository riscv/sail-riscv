/* ****************************************************************** */
/* This file specifies the instructions in the BitManip Zbs extension */


/* ****************************************************************** */
union clause ast = ZBS_IOP : (bits(6), regidx, regidx, biop)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BCLRI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b010010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BEXTI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b010010 @ shamt @ rs1 @ 0b101 @ rd @ 0b0010011

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BINVI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b011010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BSETI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b001010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011

mapping zbs_iop_mnemonic : biop <-> string = {
  RISCV_BCLRI <-> "bclri",
  RISCV_BEXTI <-> "bexti",
  RISCV_BINVI <-> "binvi",
  RISCV_BSETI <-> "bseti"
}

mapping clause assembly = ZBS_IOP(shamt, rs1, rd, op)
  <-> zbs_iop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (ZBS_IOP(shamt, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let result : xlenbits = match op {
    RISCV_BCLRI => if sizeof(xlen) == 32
                     then rs1_val & ( ~ (EXTZ(0b1) << shamt[4..0]))
                     else rs1_val & ( ~ (EXTZ(0b1) << shamt[5..0])),
    RISCV_BEXTI => if sizeof(xlen) == 32
                     then (rs1_val >> shamt[4..0]) & EXTZ(0x1)
                     else (rs1_val >> shamt[5..0]) & EXTZ(0x1),
    RISCV_BINVI => if sizeof(xlen) == 32
                     then rs1_val ^ (EXTZ(0b1) << shamt[4..0])
                     else rs1_val ^ (EXTZ(0b1) << shamt[5..0]),
    RISCV_BSETI => if sizeof(xlen) == 32
                     then rs1_val | (EXTZ(0b1) << shamt[4..0])
                     else rs1_val | (EXTZ(0b1) << shamt[5..0])
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBS_RTYPE : (regidx, regidx, regidx, brop)

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BCLR) if haveZbs()
  <-> 0b0100100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BEXT) if haveZbs()
  <-> 0b0100100 @ rs2 @ rs1 @ 0b101 @ rd @ 0b0110011

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BINV) if haveZbs()
  <-> 0b0110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BSET) if haveZbs()
  <-> 0b0010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011

mapping zbs_rtype_mnemonic : brop <-> string = {
  RISCV_BCLR    <-> "bclr",
  RISCV_BEXT    <-> "bext",
  RISCV_BINV    <-> "binv",
  RISCV_BSET    <-> "bset"
}

mapping clause assembly = ZBS_RTYPE(rs2, rs1, rd, op)
  <-> zbs_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBS_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let result : xlenbits = match op {
    RISCV_BCLR => if sizeof(xlen) == 32
                    then rs1_val & ( ~ (EXTZ(0b1) << rs2_val[4..0]))
                    else rs1_val & ( ~ (EXTZ(0b1) << rs2_val[5..0])),
    RISCV_BEXT => if sizeof(xlen) == 32
                    then (rs1_val >> rs2_val[4..0]) & EXTZ(0x1)
                    else (rs1_val >> rs2_val[5..0]) & EXTZ(0x1),
    RISCV_BINV => if sizeof(xlen) == 32
                    then rs1_val ^ (EXTZ(0b1) << rs2_val[4..0])
                    else rs1_val ^ (EXTZ(0b1) << rs2_val[5..0]),
    RISCV_BSET => if sizeof(xlen) == 32
                    then rs1_val | (EXTZ(0b1) << rs2_val[4..0])
                    else rs1_val | (EXTZ(0b1) << rs2_val[5..0])
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
