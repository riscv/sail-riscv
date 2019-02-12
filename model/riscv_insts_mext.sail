/* ****************************************************************** */
/* This file specifies the instructions in the 'M' extension.         */

/* ****************************************************************** */
/* FIXME: separate these out into separate ast variants */
union clause ast = MUL : (regbits, regbits, regbits, bool, bool, bool)

mapping encdec_mul_op : (bool, bool, bool) <-> bits(3) = {
  (false, true, true)  <-> 0b000,
  (true, true, true)   <-> 0b001,
  (true, true, false)  <-> 0b010,
  (true, false, false) <-> 0b011
}

/* for some reason the : bits(3) here is still necessary - BUG */
mapping clause encdec = MUL(rs2, rs1, rd, high, signed1, signed2)
  <-> 0b0000001 @ rs2 @ rs1 @ encdec_mul_op(high, signed1, signed2) : bits(3) @ rd @ 0b0110011

function clause execute (MUL(rs2, rs1, rd, high, signed1, signed2)) = {
  if haveMulDiv() then {
    let rs1_val = X(rs1);
    let rs2_val = X(rs2);
    let rs1_int : int = if signed1 then signed(rs1_val) else unsigned(rs1_val);
    let rs2_int : int = if signed2 then signed(rs2_val) else unsigned(rs2_val);
    let result_wide = to_bits(2 * xlen, rs1_int * rs2_int);
    let result = if   high
                 then result_wide[(2 * xlen - 1) .. xlen]
                 else result_wide[(xlen - 1) .. 0];
    X(rd) = result;
    true
  } else {
    handle_illegal();
    false
  }
}

mapping mul_mnemonic : (bool, bool, bool) <-> string = {
  (false, true, true)  <-> "mul",
  (true, true, true)   <-> "mulh",
  (true, true, false)  <-> "mulhsu",
  (true, false, false) <-> "mulhu"
}

mapping clause assembly = MUL(rs2, rs1, rd, high, signed1, signed2)
  <-> mul_mnemonic(high, signed1, signed2) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = DIV : (regbits, regbits, regbits, bool)

mapping clause encdec = DIV(rs2, rs1, rd, s)
  <-> 0b0000001 @ rs2 @ rs1 @ 0b10 @ bool_not_bits(s) @ rd @ 0b0110011

function clause execute (DIV(rs2, rs1, rd, s)) = {
  if haveMulDiv() then {
    let rs1_val = X(rs1);
    let rs2_val = X(rs2);
    let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
    let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
    let q : int = if rs2_int == 0 then -1 else quot_round_zero(rs1_int, rs2_int);
    /* check for signed overflow */
    let q': int = if s & q > xlen_max_signed then xlen_min_signed else q;
    X(rd) = to_bits(xlen, q');
    true
  } else {
    handle_illegal();
    false
  }
}

mapping maybe_not_u : bool <-> string = {
  false <-> "u",
  true  <-> ""
}

mapping clause assembly = DIV(rs2, rs1, rd, s)
  <-> "div" ^ maybe_not_u(s) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = REM : (regbits, regbits, regbits, bool)

mapping clause encdec = REM(rs2, rs1, rd, s)
  <-> 0b0000001 @ rs2 @ rs1 @ 0b11 @ bool_not_bits(s) @ rd @ 0b0110011

function clause execute (REM(rs2, rs1, rd, s)) = {
  if haveMulDiv() then {
    let rs1_val = X(rs1);
    let rs2_val = X(rs2);
    let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
    let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
    let r : int = if rs2_int == 0 then rs1_int else rem_round_zero(rs1_int, rs2_int);
    /* signed overflow case returns zero naturally as required due to -1 divisor */
    X(rd) = to_bits(xlen, r);
    true
  } else {
    handle_illegal();
    false
  }
}

mapping clause assembly = REM(rs2, rs1, rd, s)
  <-> "rem" ^ maybe_not_u(s) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */
union clause ast = MULW : (regbits, regbits, regbits)

mapping clause encdec = MULW(rs2, rs1, rd)
      if xlen == 64
  <-> 0b0000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b0111011
      if xlen == 64

function clause execute (MULW(rs2, rs1, rd)) = {
  if haveMulDiv() then {
    let rs1_val = X(rs1)[31..0];
    let rs2_val = X(rs2)[31..0];
    let rs1_int : int = signed(rs1_val);
    let rs2_int : int = signed(rs2_val);
    /* to_bits requires expansion to 64 bits followed by truncation */
    let result32 = to_bits(64, rs1_int * rs2_int)[31..0];
    let result : xlenbits = EXTS(result32);
    X(rd) = result;
    true
  } else {
    handle_illegal();
    false
  }
}

mapping clause assembly = MULW(rs2, rs1, rd)
      if xlen == 64
  <-> "mulw" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
      if xlen == 64

/* ****************************************************************** */
union clause ast = DIVW : (regbits, regbits, regbits, bool)

mapping clause encdec = DIVW(rs2, rs1, rd, s)
      if xlen == 64
  <-> 0b0000001 @ rs2 @ rs1 @ 0b10 @ bool_not_bits(s) @ rd @ 0b0111011
      if xlen == 64

function clause execute (DIVW(rs2, rs1, rd, s)) = {
  if haveMulDiv() then {
    let rs1_val = X(rs1)[31..0];
    let rs2_val = X(rs2)[31..0];
    let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
    let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
    let q : int = if rs2_int == 0 then -1 else quot_round_zero(rs1_int, rs2_int);
    /* check for signed overflow */
    let q': int = if s & q > (2 ^ 31 - 1) then  (0 - 2^31) else q;
    X(rd) = EXTS(to_bits(32, q'));
    true
  } else {
    handle_illegal();
    false
  }
}

mapping clause assembly = DIVW(rs2, rs1, rd, s)
      if xlen == 64
  <-> "div" ^ maybe_not_u(s) ^ "w" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
      if xlen == 64

/* ****************************************************************** */
union clause ast = REMW : (regbits, regbits, regbits, bool)

mapping clause encdec = REMW(rs2, rs1, rd, s)
      if xlen == 64
  <-> 0b0000001 @ rs2 @ rs1 @ 0b11 @ bool_not_bits(s) @ rd @ 0b0111011
      if xlen == 64

function clause execute (REMW(rs2, rs1, rd, s)) = {
  if haveMulDiv() then {
    let rs1_val = X(rs1)[31..0];
    let rs2_val = X(rs2)[31..0];
    let rs1_int : int = if s then signed(rs1_val) else unsigned(rs1_val);
    let rs2_int : int = if s then signed(rs2_val) else unsigned(rs2_val);
    let r : int = if rs2_int == 0 then rs1_int else rem_round_zero(rs1_int, rs2_int);
    /* signed overflow case returns zero naturally as required due to -1 divisor */
    X(rd) = EXTS(to_bits(32, r));
    true
  } else {
    handle_illegal();
    false
  }
}

mapping clause assembly = REMW(rs2, rs1, rd, s)
      if xlen == 64
  <-> "rem" ^ maybe_not_u(s) ^ "w" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
      if xlen == 64
