/* **************************************************************** */
/* Floating point register file and accessors for F, D extensions   */
/* Floating point CSR and accessors                                 */
/* **************************************************************** */

/* Original version written by Rishiyur S. Nikhil, Sept-Oct 2019    */

/* **************************************************************** */
/* Floating point register file                                     */

register fs : vector(32, dec, fregtype)

register f0  : fregtype
register f1  : fregtype
register f2  : fregtype
register f3  : fregtype
register f4  : fregtype
register f5  : fregtype
register f6  : fregtype
register f7  : fregtype
register f8  : fregtype
register f9  : fregtype
register f10 : fregtype
register f11 : fregtype
register f12 : fregtype
register f13 : fregtype
register f14 : fregtype
register f15 : fregtype
register f16 : fregtype
register f17 : fregtype
register f18 : fregtype
register f19 : fregtype
register f20 : fregtype
register f21 : fregtype
register f22 : fregtype
register f23 : fregtype
register f24 : fregtype
register f25 : fregtype
register f26 : fregtype
register f27 : fregtype
register f28 : fregtype
register f29 : fregtype
register f30 : fregtype
register f31 : fregtype

function dirty_fd_context() -> unit = {
  mstatus->FS() = extStatus_to_bits(Dirty);
  mstatus->SD() = 0b1
}

val rF : forall 'n, 0 <= 'n < 32. regno('n) -> flenbits effect {rreg, escape}
function rF r = {
  let v : fregtype =
    match r {
      0 => f0,
      1 => f1,
      2 => f2,
      3 => f3,
      4 => f4,
      5 => f5,
      6 => f6,
      7 => f7,
      8 => f8,
      9 => f9,
      10 => f10,
      11 => f11,
      12 => f12,
      13 => f13,
      14 => f14,
      15 => f15,
      16 => f16,
      17 => f17,
      18 => f18,
      19 => f19,
      20 => f20,
      21 => f21,
      22 => f22,
      23 => f23,
      24 => f24,
      25 => f25,
      26 => f26,
      27 => f27,
      28 => f28,
      29 => f29,
      30 => f30,
      31 => f31,
      _  => {assert(false, "invalid floating point register number"); zero_freg}
    };
  fregval_from_freg(v)
}

val wF : forall 'n, 0 <= 'n < 32. (regno('n), flenbits) -> unit effect {wreg, escape}
function wF (r, in_v) = {
  let v = fregval_into_freg(in_v);
  match r {
    0  => f0 = v,
    1  => f1 = v,
    2  => f2 = v,
    3  => f3 = v,
    4  => f4 = v,
    5  => f5 = v,
    6  => f6 = v,
    7  => f7 = v,
    8  => f8 = v,
    9  => f9 = v,
    10 => f10 = v,
    11 => f11 = v,
    12 => f12 = v,
    13 => f13 = v,
    14 => f14 = v,
    15 => f15 = v,
    16 => f16 = v,
    17 => f17 = v,
    18 => f18 = v,
    19 => f19 = v,
    20 => f20 = v,
    21 => f21 = v,
    22 => f22 = v,
    23 => f23 = v,
    24 => f24 = v,
    25 => f25 = v,
    26 => f26 = v,
    27 => f27 = v,
    28 => f28 = v,
    29 => f29 = v,
    30 => f30 = v,
    31 => f31 = v,
    _  => assert(false, "invalid floating point register number")
  };

  dirty_fd_context();

  if   get_config_print_reg()
  then
      /* TODO: will only print bits; should we print in floating point format? */
      print_reg("f" ^ string_of_int(r) ^ " <- " ^ FRegStr(v));
}

function rF_bits(i: bits(5)) -> flenbits = rF(unsigned(i))

function wF_bits(i: bits(5), data: flenbits) -> unit = {
  wF(unsigned(i)) = data
}

overload F = {rF_bits, wF_bits, rF, wF}

/* register names */

val freg_name_abi : regidx <-> string

mapping freg_name_abi = {
    0b00000 <-> "ft0",
    0b00001 <-> "ft1",
    0b00010 <-> "ft2",
    0b00011 <-> "ft3",
    0b00100 <-> "ft4",
    0b00101 <-> "ft5",
    0b00110 <-> "ft6",
    0b00111 <-> "ft7",
    0b01000 <-> "fs0",
    0b01001 <-> "fs1",
    0b01010 <-> "fa0",
    0b01011 <-> "fa1",
    0b01100 <-> "fa2",
    0b01101 <-> "fa3",
    0b01110 <-> "fa4",
    0b01111 <-> "fa5",
    0b10000 <-> "fa6",
    0b10001 <-> "fa7",
    0b10010 <-> "fs2",
    0b10011 <-> "fs3",
    0b10100 <-> "fs4",
    0b10101 <-> "fs5",
    0b10110 <-> "fs6",
    0b10111 <-> "fs7",
    0b11000 <-> "fs8",
    0b11001 <-> "fs9",
    0b11010 <-> "fs10",
    0b11011 <-> "fs11",
    0b11100 <-> "ft8",
    0b11101 <-> "ft9",
    0b11110 <-> "ft10",
    0b11111 <-> "ft11"
}

overload to_str = {freg_name_abi}

/* mappings for assembly */

val freg_name : bits(5) <-> string
mapping freg_name = {
    0b00000 <-> "ft0",
    0b00001 <-> "ft1",
    0b00010 <-> "ft2",
    0b00011 <-> "ft3",
    0b00100 <-> "ft4",
    0b00101 <-> "ft5",
    0b00110 <-> "ft6",
    0b00111 <-> "ft7",
    0b01000 <-> "fs0",
    0b01001 <-> "fs1",
    0b01010 <-> "fa0",
    0b01011 <-> "fa1",
    0b01100 <-> "fa2",
    0b01101 <-> "fa3",
    0b01110 <-> "fa4",
    0b01111 <-> "fa5",
    0b10000 <-> "fa6",
    0b10001 <-> "fa7",
    0b10010 <-> "fs2",
    0b10011 <-> "fs3",
    0b10100 <-> "fs4",
    0b10101 <-> "fs5",
    0b10110 <-> "fs6",
    0b10111 <-> "fs7",
    0b11000 <-> "fs8",
    0b11001 <-> "fs9",
    0b11010 <-> "fs10",
    0b11011 <-> "fs11",
    0b11100 <-> "ft8",
    0b11101 <-> "ft9",
    0b11110 <-> "ft10",
    0b11111 <-> "ft11"
}

val init_fdext_regs : unit -> unit effect {wreg}
function init_fdext_regs () = {
  f0  = zero_freg;
  f1  = zero_freg;
  f2  = zero_freg;
  f3  = zero_freg;
  f4  = zero_freg;
  f5  = zero_freg;
  f6  = zero_freg;
  f7  = zero_freg;
  f8  = zero_freg;
  f9  = zero_freg;
  f10 = zero_freg;
  f11 = zero_freg;
  f12 = zero_freg;
  f13 = zero_freg;
  f14 = zero_freg;
  f15 = zero_freg;
  f16 = zero_freg;
  f17 = zero_freg;
  f18 = zero_freg;
  f19 = zero_freg;
  f20 = zero_freg;
  f21 = zero_freg;
  f22 = zero_freg;
  f23 = zero_freg;
  f24 = zero_freg;
  f25 = zero_freg;
  f26 = zero_freg;
  f27 = zero_freg;
  f28 = zero_freg;
  f29 = zero_freg;
  f30 = zero_freg;
  f31 = zero_freg
}

/* **************************************************************** */
/* Floating Point CSR                                               */
/*     fflags    address 0x001    same as fcrs [4..0]               */
/*     frm       address 0x002    same as fcrs [7..5]               */
/*     fcsr      address 0x003                                      */


bitfield Fcsr : bits(32) = {
  FRM    : 7 .. 5,
  FFLAGS : 4 .. 0,
}

register fcsr : Fcsr

val ext_write_fcsr : (bits(3), bits(5)) -> unit effect {rreg, wreg}
function ext_write_fcsr (frm, fflags) = {
  fcsr->FRM()    = frm;      /* Note: frm can be an illegal value, 101, 110, 111 */
  fcsr->FFLAGS() = fflags;
  update_softfloat_fflags(fflags);
  dirty_fd_context();
}

/* called for softfloat paths (softfloat flags are consistent) */
val write_fflags : (bits(5)) -> unit effect {rreg, wreg}
function write_fflags(fflags) = {
  if   fcsr.FFLAGS() != fflags
  then dirty_fd_context();
  fcsr->FFLAGS() = fflags;
}

/* called for non-softfloat paths (softfloat flags need updating) */
val accrue_fflags : (bits(5)) -> unit effect {rreg, wreg}
function accrue_fflags(flags) = {
  let f = fcsr.FFLAGS() | flags;
  if  fcsr.FFLAGS() != f
  then {
    fcsr->FFLAGS() = f;
    update_softfloat_fflags(f);
    dirty_fd_context();
  }
}
