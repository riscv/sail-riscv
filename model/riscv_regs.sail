/* program counter */

register PC       : xlenbits
register nextPC   : xlenbits

/* internal state to hold instruction bits for faulting instructions */
register instbits : xlenbits

/* register file and accessors */

register Xs : vector(32, dec, regtype)

register x1  : regtype
register x2  : regtype
register x3  : regtype
register x4  : regtype
register x5  : regtype
register x6  : regtype
register x7  : regtype
register x8  : regtype
register x9  : regtype
register x10 : regtype
register x11 : regtype
register x12 : regtype
register x13 : regtype
register x14 : regtype
register x15 : regtype
register x16 : regtype
register x17 : regtype
register x18 : regtype
register x19 : regtype
register x20 : regtype
register x21 : regtype
register x22 : regtype
register x23 : regtype
register x24 : regtype
register x25 : regtype
register x26 : regtype
register x27 : regtype
register x28 : regtype
register x29 : regtype
register x30 : regtype
register x31 : regtype

val rX : forall 'n, 0 <= 'n < 32. regno('n) -> xlenbits effect {rreg}
/*function rX 0 = 0x0000000000000000
and rX (r if r > 0) = Xs[r]*/
function rX r = {
  let v : regtype =
    match r {
      0 => zero_reg,
      1 => x1,
      2 => x2,
      3 => x3,
      4 => x4,
      5 => x5,
      6 => x6,
      7 => x7,
      8 => x8,
      9 => x9,
      10 => x10,
      11 => x11,
      12 => x12,
      13 => x13,
      14 => x14,
      15 => x15,
      16 => x16,
      17 => x17,
      18 => x18,
      19 => x19,
      20 => x20,
      21 => x21,
      22 => x22,
      23 => x23,
      24 => x24,
      25 => x25,
      26 => x26,
      27 => x27,
      28 => x28,
      29 => x29,
      30 => x30,
      31 => x31
    };
  regval_from_reg(v)
}

$ifdef RVFI_DII
val rvfi_wX : forall 'n, 0 <= 'n < 32. (regno('n), xlenbits) -> unit effect {wreg}
function rvfi_wX (r,v) = {
  rvfi_exec->rvfi_rd_wdata() = v;
  rvfi_exec->rvfi_rd_addr() = to_bits(8,r);
}
$else
val rvfi_wX : forall 'n, 0 <= 'n < 32. (regno('n), xlenbits) -> unit
function rvfi_wX (r,v) = ()
$endif

val wX : forall 'n, 0 <= 'n < 32. (regno('n), xlenbits) -> unit effect {wreg, escape}
function wX (r, in_v) = {
  let v = regval_into_reg(in_v);
  match r {
    0  => (),
    1  => x1 = v,
    2  => x2 = v,
    3  => x3 = v,
    4  => x4 = v,
    5  => x5 = v,
    6  => x6 = v,
    7  => x7 = v,
    8  => x8 = v,
    9  => x9 = v,
    10 => x10 = v,
    11 => x11 = v,
    12 => x12 = v,
    13 => x13 = v,
    14 => x14 = v,
    15 => x15 = v,
    16 => x16 = v,
    17 => x17 = v,
    18 => x18 = v,
    19 => x19 = v,
    20 => x20 = v,
    21 => x21 = v,
    22 => x22 = v,
    23 => x23 = v,
    24 => x24 = v,
    25 => x25 = v,
    26 => x26 = v,
    27 => x27 = v,
    28 => x28 = v,
    29 => x29 = v,
    30 => x30 = v,
    31 => x31 = v
  };
  if (r != 0) then {
     rvfi_wX(r, in_v);
     // Xs[r] = v;
     print_reg("x" ^ string_of_int(r) ^ " <- " ^ RegStr(v));
  }
}

overload X = {rX, wX}

/* register names */

val cast reg_name_abi : regbits -> string

function reg_name_abi(r) = {
  match (r) {
    0b00000 => "zero",
    0b00001 => "ra",
    0b00010 => "sp",
    0b00011 => "gp",
    0b00100 => "tp",
    0b00101 => "t0",
    0b00110 => "t1",
    0b00111 => "t2",
    0b01000 => "fp",
    0b01001 => "s1",
    0b01010 => "a0",
    0b01011 => "a1",
    0b01100 => "a2",
    0b01101 => "a3",
    0b01110 => "a4",
    0b01111 => "a5",
    0b10000 => "a6",
    0b10001 => "a7",
    0b10010 => "s2",
    0b10011 => "s3",
    0b10100 => "s4",
    0b10101 => "s5",
    0b10110 => "s6",
    0b10111 => "s7",
    0b11000 => "s8",
    0b11001 => "s9",
    0b11010 => "s10",
    0b11011 => "s11",
    0b11100 => "t3",
    0b11101 => "t4",
    0b11110 => "t5",
    0b11111 => "t6"
  }
}

/* mappings for assembly */

val reg_name : bits(5) <-> string
mapping reg_name = {
    0b00000 <-> "zero",
    0b00001 <-> "ra",
    0b00010 <-> "sp",
    0b00011 <-> "gp",
    0b00100 <-> "tp",
    0b00101 <-> "t0",
    0b00110 <-> "t1",
    0b00111 <-> "t2",
    0b01000 <-> "fp",
    0b01001 <-> "s1",
    0b01010 <-> "a0",
    0b01011 <-> "a1",
    0b01100 <-> "a2",
    0b01101 <-> "a3",
    0b01110 <-> "a4",
    0b01111 <-> "a5",
    0b10000 <-> "a6",
    0b10001 <-> "a7",
    0b10010 <-> "s2",
    0b10011 <-> "s3",
    0b10100 <-> "s4",
    0b10101 <-> "s5",
    0b10110 <-> "s6",
    0b10111 <-> "s7",
    0b11000 <-> "s8",
    0b11001 <-> "s9",
    0b11010 <-> "s10",
    0b11011 <-> "s11",
    0b11100 <-> "t3",
    0b11101 <-> "t4",
    0b11110 <-> "t5",
    0b11111 <-> "t6"
}

mapping creg_name : bits(3) <-> string = {
  0b000 <-> "s0",
  0b001 <-> "s1",
  0b010 <-> "a0",
  0b011 <-> "a1",
  0b100 <-> "a2",
  0b101 <-> "a3",
  0b110 <-> "a4",
  0b111 <-> "a5"
}
