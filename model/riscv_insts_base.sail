/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* ****************************************************************** */
/* This file specifies the instructions in the base integer set.      */

function clause currentlyEnabled(Ext_C) = hartSupports(Ext_C) & misa[C] == 0b1
function clause currentlyEnabled(Ext_Zca) = hartSupports(Ext_Zca) & (currentlyEnabled(Ext_C) | not(hartSupports(Ext_C)))

/* ****************************************************************** */
union clause instruction = UTYPE : (bits(20), regidx, uop)

mapping encdec_uop : uop <-> bits(7) = {
  LUI   <-> 0b0110111,
  AUIPC <-> 0b0010111
}

mapping clause encdec = UTYPE(imm, rd, op)
  <-> imm @ encdec_reg(rd) @ encdec_uop(op)

function clause execute (UTYPE(imm, rd, op)) = {
  let off : xlenbits = sign_extend(imm @ 0x000);
  X(rd) = match op {
    LUI   => off,
    AUIPC => get_arch_pc() + off
  };
  RETIRE_SUCCESS
}

mapping utype_mnemonic : uop <-> string = {
  LUI   <-> "lui",
  AUIPC <-> "auipc"
}

mapping clause assembly = UTYPE(imm, rd, op)
  <-> utype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_20(imm)

/* ****************************************************************** */

// Jump execution to a specified target address. This can fail
// due to the target not being 4-byte aligned, or due to extension checks.
// Callers must ensure that the target address is 2-byte aligned.
function jump_to(target : xlenbits) -> ExecutionResult = {
  // Extensions get the first checks on the prospective target address.
  match ext_control_check_pc(target) {
    Ext_ControlAddr_Error(e) => Ext_ControlAddr_Check_Failure(e),
    Ext_ControlAddr_OK(target) => {
      // Perform standard alignment check.
      let target_bits = bits_of(target);
      // Check target is at least 2-byte aligned (callers must ensure
      // this so it can be an assertion).
      assert(target_bits[0] == bitzero);
      // If it is not 4-byte aligned an compressed instructions are
      // not enabled then raise an alignment exception.
      if bit_to_bool(target_bits[1]) & not(currentlyEnabled(Ext_Zca)) then {
        Memory_Exception(target, E_Fetch_Addr_Align())
      } else {
        set_next_pc(target_bits);
        RETIRE_SUCCESS
      }
    }
  }
}

/* ****************************************************************** */
union clause instruction = JAL : (bits(21), regidx)

mapping clause encdec = JAL(imm_19 @ imm_7_0 @ imm_8 @ imm_18_13 @ imm_12_9 @ 0b0, rd)
  <-> imm_19 : bits(1) @ imm_18_13 : bits(6) @ imm_12_9 : bits(4) @ imm_8 : bits(1) @ imm_7_0 : bits(8) @ encdec_reg(rd) @ 0b1101111

function clause execute (JAL(imm, rd)) = {
  let link_address = get_next_pc();
  match jump_to(PC + sign_extend(imm)) {
    Retire_Success() => { X(rd) = link_address; Retire_Success() },
    failure => failure,
  }
}

/* TODO: handle 2-byte-alignment in mappings */

mapping clause assembly = JAL(imm, rd)
  <-> "jal" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_21(imm)

/* ****************************************************************** */
union clause instruction = JALR : (bits(12), regidx, regidx)

mapping clause encdec = JALR(imm, rs1, rd)
  <-> imm @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b1100111

mapping clause assembly = JALR(imm, rs1, rd)
  <-> "jalr" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_12(imm) ^ "(" ^ reg_name(rs1) ^ ")"

/* see riscv_jalr_seq.sail or riscv_jalr_rmem.sail for the execute clause. */

/* ****************************************************************** */
union clause instruction = BTYPE : (bits(13), regidx, regidx, bop)

mapping encdec_bop : bop <-> bits(3) = {
  BEQ  <-> 0b000,
  BNE  <-> 0b001,
  BLT  <-> 0b100,
  BGE  <-> 0b101,
  BLTU <-> 0b110,
  BGEU <-> 0b111
}

mapping clause encdec = BTYPE(imm7_6 @ imm5_0 @ imm7_5_0 @ imm5_4_1 @ 0b0, rs2, rs1, op)
  <-> imm7_6 : bits(1) @ imm7_5_0 : bits(6) @ encdec_reg(rs2) @ encdec_reg(rs1) @ encdec_bop(op) @ imm5_4_1 : bits(4) @ imm5_0 : bits(1) @ 0b1100011

function clause execute (BTYPE(imm, rs2, rs1, op)) = {
  let taken : bool = match op {
    BEQ  => X(rs1) == X(rs2),
    BNE  => X(rs1) != X(rs2),
    BLT  => X(rs1) <_s X(rs2),
    BGE  => X(rs1) >=_s X(rs2),
    BLTU => X(rs1) <_u X(rs2),
    BGEU => X(rs1) >=_u X(rs2)
  };
  if taken
  then jump_to(PC + sign_extend(imm))
  else RETIRE_SUCCESS
}

mapping btype_mnemonic : bop <-> string = {
  BEQ  <-> "beq",
  BNE  <-> "bne",
  BLT  <-> "blt",
  BGE  <-> "bge",
  BLTU <-> "bltu",
  BGEU <-> "bgeu"
}

mapping clause assembly = BTYPE(imm, rs2, rs1, op)
  <-> btype_mnemonic(op) ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ hex_bits_signed_13(imm)

/* ****************************************************************** */
union clause instruction = ITYPE : (bits(12), regidx, regidx, iop)

mapping encdec_iop : iop <-> bits(3) = {
  ADDI  <-> 0b000,
  SLTI  <-> 0b010,
  SLTIU <-> 0b011,
  ANDI  <-> 0b111,
  ORI   <-> 0b110,
  XORI  <-> 0b100
}

mapping clause encdec = ITYPE(imm, rs1, rd, op)
  <-> imm @ encdec_reg(rs1) @ encdec_iop(op) @ encdec_reg(rd) @ 0b0010011

function clause execute (ITYPE (imm, rs1, rd, op)) = {
  let immext : xlenbits = sign_extend(imm);
  X(rd) = match op {
    ADDI  => X(rs1) + immext,
    SLTI  => zero_extend(bool_to_bits(X(rs1) <_s immext)),
    SLTIU => zero_extend(bool_to_bits(X(rs1) <_u immext)),
    ANDI  => X(rs1) & immext,
    ORI   => X(rs1) | immext,
    XORI  => X(rs1) ^ immext
  };
  RETIRE_SUCCESS
}

mapping itype_mnemonic : iop <-> string = {
  ADDI  <-> "addi",
  SLTI  <-> "slti",
  SLTIU <-> "sltiu",
  XORI  <-> "xori",
  ORI   <-> "ori",
  ANDI  <-> "andi"
}

mapping clause assembly = ITYPE(imm, rs1, rd, op)
  <-> itype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_signed_12(imm)

/* ****************************************************************** */
union clause instruction = SHIFTIOP : (bits(6), regidx, regidx, sop)

mapping encdec_sop : sop <-> bits(3) = {
  SLLI <-> 0b001,
  SRLI <-> 0b101,
  SRAI <-> 0b101
}

mapping clause encdec = SHIFTIOP(shamt, rs1, rd, SLLI)
  <-> 0b000000 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0010011
  when xlen == 64 | shamt[5] == bitzero
mapping clause encdec = SHIFTIOP(shamt, rs1, rd, SRLI)
  <-> 0b000000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when xlen == 64 | shamt[5] == bitzero
mapping clause encdec = SHIFTIOP(shamt, rs1, rd, SRAI)
  <-> 0b010000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0010011
  when xlen == 64 | shamt[5] == bitzero

function clause execute (SHIFTIOP(shamt, rs1, rd, op)) = {
  let shamt = shamt[log2_xlen - 1 .. 0];
  X(rd) = match op {
    SLLI => X(rs1) << shamt,
    SRLI => X(rs1) >> shamt,
    SRAI => shift_bits_right_arith(X(rs1), shamt),
  };
  RETIRE_SUCCESS
}

mapping shiftiop_mnemonic : sop <-> string = {
  SLLI <-> "slli",
  SRLI <-> "srli",
  SRAI <-> "srai"
}

mapping clause assembly = SHIFTIOP(shamt, rs1, rd, op)
  <-> shiftiop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

/* ****************************************************************** */
union clause instruction = RTYPE : (regidx, regidx, regidx, rop)

mapping clause encdec = RTYPE(rs2, rs1, rd, ADD)  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, SLT)  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b010 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, SLTU) <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b011 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, AND)  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b111 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, OR)   <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b110 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, XOR)  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b100 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, SLL)  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, SRL)  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, SUB)  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0110011
mapping clause encdec = RTYPE(rs2, rs1, rd, SRA)  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0110011

function clause execute (RTYPE(rs2, rs1, rd, op)) = {
  X(rd) = match op {
    ADD  => X(rs1) + X(rs2),
    SLT  => zero_extend(bool_to_bits(X(rs1) <_s X(rs2))),
    SLTU => zero_extend(bool_to_bits(X(rs1) <_u X(rs2))),
    AND  => X(rs1) & X(rs2),
    OR   => X(rs1) | X(rs2),
    XOR  => X(rs1) ^ X(rs2),
    SLL  => X(rs1) << X(rs2)[log2_xlen - 1 .. 0],
    SRL  => X(rs1) >> X(rs2)[log2_xlen - 1 .. 0],
    SUB  => X(rs1) - X(rs2),
    SRA  => shift_bits_right_arith(X(rs1), X(rs2)[log2_xlen - 1 .. 0]),
  };
  RETIRE_SUCCESS
}

mapping rtype_mnemonic : rop <-> string = {
  ADD  <-> "add",
  SLT  <-> "slt",
  SLTU <-> "sltu",
  AND  <-> "and",
  OR   <-> "or",
  XOR  <-> "xor",
  SLL  <-> "sll",
  SRL  <-> "srl",
  SUB  <-> "sub",
  SRA  <-> "sra"
}

mapping clause assembly = RTYPE(rs2, rs1, rd, op)
  <-> rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause instruction = LOAD : (bits(12), regidx, regidx, bool, word_width)

/* unsigned loads are only present for widths strictly less than xlen,
   signed loads also present for widths equal to xlen */
function valid_load_encdec(width : word_width, is_unsigned : bool) -> bool =
  (width < xlen_bytes) | (not(is_unsigned) & width <= xlen_bytes)

val extend_value : forall 'n, 0 < 'n <= xlen. (bool, bits('n)) -> xlenbits
function extend_value(is_unsigned, value) = if is_unsigned then zero_extend(value) else sign_extend(value)

mapping clause encdec = LOAD(imm, rs1, rd, is_unsigned, width)
  <-> imm @ encdec_reg(rs1) @ bool_bits(is_unsigned) @ width_enc(width) @ encdec_reg(rd) @ 0b0000011
  when valid_load_encdec(width, is_unsigned)

function clause execute (LOAD(imm, rs1, rd, is_unsigned, width)) = {
  let offset : xlenbits = sign_extend(imm);

  // This is checked during decoding.
  assert(width <= xlen_bytes);

  match vmem_read(rs1, offset, width, Read(Data), false, false, false) {
    Ok(data) => {
      X(rd) = extend_value(is_unsigned, data);
      RETIRE_SUCCESS
    },
    Err(e) => e,
  }
}

mapping maybe_u : bool <-> string = {
  true  <-> "u",
  false <-> ""
}

mapping clause assembly = LOAD(imm, rs1, rd, is_unsigned, width)
  <-> "l" ^ width_mnemonic(width) ^ maybe_u(is_unsigned) ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_signed_12(imm) ^ "(" ^ reg_name(rs1) ^ ")"

/* ****************************************************************** */
union clause instruction = STORE : (bits(12), regidx, regidx, word_width)

mapping clause encdec = STORE(imm7 @ imm5, rs2, rs1, width)
  <-> imm7 : bits(7) @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b0 @ width_enc(width) @ imm5 : bits(5) @ 0b0100011
  when width <= xlen_bytes

function clause execute (STORE(imm, rs2, rs1, width)) = {
  let offset : xlenbits = sign_extend(imm);

  // This is checked during decoding.
  assert(width <= xlen_bytes);

  let data = X(rs2)[width * 8 - 1 .. 0];
  match vmem_write(rs1, offset, width, data, Write(Data), false, false, false) {
    Ok(_) => RETIRE_SUCCESS,
    Err(e) => e,
  }
}

mapping clause assembly = STORE(imm, rs2, rs1, width)
  <-> "s" ^ width_mnemonic(width) ^ spc() ^ reg_name(rs2) ^ sep() ^ hex_bits_signed_12(imm) ^ opt_spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

/* ****************************************************************** */
union clause instruction = ADDIW : (bits(12), regidx, regidx)

mapping clause encdec = ADDIW(imm, rs1, rd)
  <-> imm @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64

function clause execute (ADDIW(imm, rs1, rd)) = {
  let result = X(rs1) + sign_extend(imm);
  X(rd) = sign_extend(result[31..0]);
  RETIRE_SUCCESS
}

mapping clause assembly = ADDIW(imm, rs1, rd)
  <-> "addiw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_signed_12(imm)
  when xlen == 64

/* ****************************************************************** */
union clause instruction = RTYPEW : (regidx, regidx, regidx, ropw)

mapping clause encdec = RTYPEW(rs2, rs1, rd, ADDW)
  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SUBW)
  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SLLW)
  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SRLW)
  <-> 0b0000000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64
mapping clause encdec = RTYPEW(rs2, rs1, rd, SRAW)
  <-> 0b0100000 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0111011
  when xlen == 64

function clause execute (RTYPEW(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1)[31..0];
  let rs2_val = X(rs2)[31..0];
  let result : bits(32) = match op {
    ADDW => rs1_val + rs2_val,
    SUBW => rs1_val - rs2_val,
    SLLW => rs1_val << rs2_val[4..0],
    SRLW => rs1_val >> rs2_val[4..0],
    SRAW => shift_bits_right_arith(rs1_val, rs2_val[4..0]),
  };
  X(rd) = sign_extend(result);
  RETIRE_SUCCESS
}

mapping rtypew_mnemonic : ropw <-> string = {
  ADDW <-> "addw",
  SUBW <-> "subw",
  SLLW <-> "sllw",
  SRLW <-> "srlw",
  SRAW <-> "sraw"
}

mapping clause assembly = RTYPEW(rs2, rs1, rd, op)
  <-> rtypew_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
  when xlen == 64

/* ****************************************************************** */
union clause instruction = SHIFTIWOP : (bits(5), regidx, regidx, sopw)

mapping clause encdec = SHIFTIWOP(shamt, rs1, rd, SLLIW)
  <-> 0b0000000 @ shamt @ encdec_reg(rs1) @ 0b001 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64
mapping clause encdec = SHIFTIWOP(shamt, rs1, rd, SRLIW)
  <-> 0b0000000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64
mapping clause encdec = SHIFTIWOP(shamt, rs1, rd, SRAIW)
  <-> 0b0100000 @ shamt @ encdec_reg(rs1) @ 0b101 @ encdec_reg(rd) @ 0b0011011
  when xlen == 64

function clause execute (SHIFTIWOP(shamt, rs1, rd, op)) = {
  let rs1_val = X(rs1)[31..0];
  let result : bits(32) = match op {
    SLLIW => rs1_val << shamt,
    SRLIW => rs1_val >> shamt,
    SRAIW => shift_bits_right_arith(rs1_val, shamt),
  };
  X(rd) = sign_extend(result);
  RETIRE_SUCCESS
}

mapping shiftiwop_mnemonic : sopw <-> string = {
  SLLIW <-> "slliw",
  SRLIW <-> "srliw",
  SRAIW <-> "sraiw"
}

mapping clause assembly = SHIFTIWOP(shamt, rs1, rd, op)
  <-> shiftiwop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(shamt)
  when xlen == 64

/* ****************************************************************** */
union clause instruction = FENCE : (bits(4), bits(4))

mapping clause encdec = FENCE(pred, succ)
  <-> 0b0000 @ pred @ succ @ 0b00000 @ 0b000 @ 0b00000 @ 0b0001111

function effective_fence_set(set : bits(4), fiom : bool) -> bits(4) = {
  // The bits are IORW. If FIOM is set then I implies R and O implies W.
  if fiom then {
    set[3 .. 2] @ (set[1 .. 0] | set[3 .. 2])
  } else set
}

function clause execute (FENCE(pred, succ)) = {
  // If the FIOM bit in menvcfg/senvcfg is set then the I/O bits can imply R/W.
  let fiom = is_fiom_active();
  let pred = effective_fence_set(pred, fiom);
  let succ = effective_fence_set(succ, fiom);

  match (pred, succ) {
    (_ : bits(2) @ 0b11, _ : bits(2) @ 0b11) => sail_barrier(Barrier_RISCV_rw_rw),
    (_ : bits(2) @ 0b10, _ : bits(2) @ 0b11) => sail_barrier(Barrier_RISCV_r_rw),
    (_ : bits(2) @ 0b10, _ : bits(2) @ 0b10) => sail_barrier(Barrier_RISCV_r_r),
    (_ : bits(2) @ 0b11, _ : bits(2) @ 0b01) => sail_barrier(Barrier_RISCV_rw_w),
    (_ : bits(2) @ 0b01, _ : bits(2) @ 0b01) => sail_barrier(Barrier_RISCV_w_w),
    (_ : bits(2) @ 0b01, _ : bits(2) @ 0b11) => sail_barrier(Barrier_RISCV_w_rw),
    (_ : bits(2) @ 0b11, _ : bits(2) @ 0b10) => sail_barrier(Barrier_RISCV_rw_r),
    (_ : bits(2) @ 0b10, _ : bits(2) @ 0b01) => sail_barrier(Barrier_RISCV_r_w),
    (_ : bits(2) @ 0b01, _ : bits(2) @ 0b10) => sail_barrier(Barrier_RISCV_w_r),

    (_ : bits(4)       , _ : bits(2) @ 0b00) => (),
    (_ : bits(2) @ 0b00, _ : bits(4)       ) => (),

    _ => { print("FIXME: unsupported fence");
           () }
  };
  RETIRE_SUCCESS
}

mapping bit_maybe_r : bits(1) <-> string = {
  0b1 <-> "r",
  0b0 <-> ""
}

mapping bit_maybe_w : bits(1) <-> string = {
  0b1 <-> "w",
  0b0 <-> ""
}

mapping bit_maybe_i : bits(1) <-> string = {
  0b1 <-> "i",
  0b0 <-> ""
}

mapping bit_maybe_o : bits(1) <-> string = {
  0b1 <-> "o",
  0b0 <-> ""
}

mapping fence_bits : bits(4) <-> string = {
  // Fences with empty predecessor or successor sets are nops.
  // Clang/LLVM's assembly supports using `0` for these.
  // Binutils/GAS does not so you would have to use `.insn` to encode these.
  0b0000 <-> "0",
  i : bits(1) @ o : bits(1) @ r : bits(1) @ w : bits(1) <-> bit_maybe_i(i) ^ bit_maybe_o(o) ^ bit_maybe_r(r) ^ bit_maybe_w(w),
}

mapping clause assembly = FENCE(pred, succ)
  <-> "fence" ^ spc() ^ fence_bits(pred) ^ sep() ^ fence_bits(succ)

/* ****************************************************************** */
union clause instruction = FENCE_TSO : unit

mapping clause encdec = FENCE_TSO()
  <-> 0b1000 @ 0b0011 @ 0b0011 @ 0b00000 @ 0b000 @ 0b00000 @ 0b0001111

function clause execute (FENCE_TSO()) = {
  sail_barrier(Barrier_RISCV_tso);
  RETIRE_SUCCESS
}

mapping clause assembly = FENCE_TSO()
  <-> "fence.tso"

/* ****************************************************************** */
union clause instruction = ECALL : unit

mapping clause encdec = ECALL()
  <-> 0b000000000000 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute ECALL() = {
  let t : sync_exception =
    struct { trap = match (cur_privilege) {
                      User       => E_U_EnvCall(),
                      Supervisor => E_S_EnvCall(),
                      Machine    => E_M_EnvCall()
                    },
             excinfo = (None() : option(xlenbits)),
             ext     = None() };
  Trap(cur_privilege, CTL_TRAP(t), PC)
}

mapping clause assembly = ECALL() <-> "ecall"

/* ****************************************************************** */
union clause instruction = MRET : unit

mapping clause encdec = MRET()
  <-> 0b0011000 @ 0b00010 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute MRET() = {
  if   cur_privilege != Machine
  then Illegal_Instruction()
  else if not(ext_check_xret_priv(Machine))
  then Ext_XRET_Priv_Failure()
  else {
    set_next_pc(exception_handler(cur_privilege, CTL_MRET(), PC));
    RETIRE_SUCCESS
  }
}

mapping clause assembly = MRET() <-> "mret"

/* ****************************************************************** */
union clause instruction = SRET : unit

mapping clause encdec = SRET()
  <-> 0b0001000 @ 0b00010 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute SRET() = {
  let sret_illegal : bool = match cur_privilege {
    User       => true,
    Supervisor => not(currentlyEnabled(Ext_S)) | mstatus[TSR] == 0b1,
    Machine    => not(currentlyEnabled(Ext_S))
  };
  if   sret_illegal
  then Illegal_Instruction()
  else if not(ext_check_xret_priv (Supervisor))
  then Ext_XRET_Priv_Failure()
  else {
    set_next_pc(exception_handler(cur_privilege, CTL_SRET(), PC));
    RETIRE_SUCCESS
  }
}

mapping clause assembly = SRET() <-> "sret"

/* ****************************************************************** */
union clause instruction = EBREAK : unit

mapping clause encdec = EBREAK()
  <-> 0b000000000001 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute EBREAK() =
  Memory_Exception(Virtaddr(PC), E_Breakpoint())

mapping clause assembly = EBREAK() <-> "ebreak"

/* ****************************************************************** */
union clause instruction = WFI : unit

mapping clause encdec = WFI()
  <-> 0b000100000101 @ 0b00000 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute WFI() =
  match cur_privilege {
    Machine    => Enter_Wait(WAIT_WFI),
    Supervisor => if   mstatus[TW] == 0b1
                  then Illegal_Instruction()
                  else Enter_Wait(WAIT_WFI),
    User       => Illegal_Instruction()
  }

mapping clause assembly = WFI() <-> "wfi"

/* ****************************************************************** */
union clause instruction = SFENCE_VMA : (regidx, regidx)

mapping clause encdec = SFENCE_VMA(rs1, rs2)
  <-> 0b0001001 @ encdec_reg(rs2) @ encdec_reg(rs1) @ 0b000 @ 0b00000 @ 0b1110011
  when virtual_memory_supported() | not(config extensions.Svbare.sfence_vma_illegal_if_svbare_only : bool)

function clause execute SFENCE_VMA(rs1, rs2) = {
  let addr = if rs1 != zreg then Some(X(rs1)) else None();
  // Note, the Sail model does not currently support Sv32 & SXLEN=32 on RV64.
  // In that case this asidlen would be incorrect because the maximum asidlen
  // is 9 but we always set it to 16 for RV64.
  let asid = if rs2 != zreg then Some(X(rs2)[asidlen - 1 .. 0]) else None();
  match cur_privilege {
    User       => Illegal_Instruction(),
    Supervisor => match mstatus[TVM] {
                    0b1 => Illegal_Instruction(),
                    0b0 => { flush_TLB(asid, addr); RETIRE_SUCCESS },
                  },
    Machine    => { flush_TLB(asid, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = SFENCE_VMA(rs1, rs2)
  <-> "sfence.vma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
