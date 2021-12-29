default Order dec

$include <smt.sail>
$include <option.sail>
$include <arith.sail>
$include <string.sail>
$include <vector_dec.sail>
$include <regfp.sail>

val string_startswith = "string_startswith" : (string, string) -> bool
val string_drop = "string_drop" : (string, nat) -> string
val string_take = "string_take" : (string, nat) -> string
val string_length = "string_length" : string -> nat
val string_append = {c: "concat_str", _: "string_append"} : (string, string) -> string

val eq_anything = {ocaml: "(fun (x, y) -> x = y)", interpreter: "eq_anything", lem: "eq", coq: "generic_eq", c: "eq_anything"} : forall ('a : Type). ('a, 'a) -> bool

overload operator == = {eq_string, eq_anything}

val "reg_deref" : forall ('a : Type). register('a) -> 'a effect {rreg}
/* sneaky deref with no effect necessary for bitfield writes */
val _reg_deref = "reg_deref" : forall ('a : Type). register('a) -> 'a

val any_vector_update = {ocaml: "update", lem: "update_list_dec", coq: "vector_update"} : forall 'n ('a : Type).
  (vector('n, dec, 'a), int, 'a) -> vector('n, dec, 'a)

overload vector_update = {any_vector_update}

val update_subrange = {ocaml: "update_subrange", interpreter: "update_subrange", lem: "update_subrange_vec_dec", coq: "update_subrange_vec_dec"} : forall 'n 'm 'o.
  (bits('n), atom('m), atom('o), bits('m - ('o - 1))) -> bits('n)

val vector_concat = {ocaml: "append", lem: "append_list", coq: "vec_concat"} : forall ('n : Int) ('m : Int) ('a : Type).
  (vector('n, dec, 'a), vector('m, dec, 'a)) -> vector('n + 'm, dec, 'a)

overload append = {vector_concat}

overload ~ = {not_bool, not_vec}

val neq_vec = {lem: "neq"} : forall 'n. (bits('n), bits('n)) -> bool

function neq_vec (x, y) = not_bool(eq_bits(x, y))

val neq_anything = {lem: "neq", coq: "generic_neq"} : forall ('a : Type). ('a, 'a) -> bool

function neq_anything (x, y) = not_bool(x == y)

overload operator != = {neq_vec, neq_anything}

overload operator & = {and_vec}

overload operator | = {or_vec}

val string_of_int = {c: "string_of_int", ocaml: "string_of_int", interpreter: "string_of_int", lem: "stringFromInteger", coq: "string_of_int"} : int -> string

val "string_of_bits" : forall 'n. bits('n) -> string

function string_of_bit(b: bit) -> string =
  match b {
    bitzero => "0b0",
    bitone => "0b1"
  }

overload BitStr = {string_of_bits, string_of_bit}

val xor_vec = {c: "xor_bits", _: "xor_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val int_power = {ocaml: "int_power", interpreter: "int_power", lem: "pow", coq: "pow", c: "pow_int"} : (int, int) -> int

overload operator ^ = {xor_vec, int_power, concat_str}

val sub_vec = {c: "sub_bits", _: "sub_vec"} : forall 'n. (bits('n), bits('n)) -> bits('n)

val sub_vec_int = {c: "sub_bits_int", _: "sub_vec_int"} : forall 'n. (bits('n), int) -> bits('n)

overload operator - = {sub_vec, sub_vec_int}

val quot_round_zero = {ocaml: "quot_round_zero", interpreter: "quot_round_zero", lem: "hardware_quot", c: "tdiv_int", coq: "Z.quot"} : (int, int) -> int
val rem_round_zero = {ocaml: "rem_round_zero", interpreter: "rem_round_zero", lem: "hardware_mod", c: "tmod_int", coq: "Z.rem"} : (int, int) -> int

/* The following should get us euclidean modulus, and is compatible with pre and post 0.9 versions of sail */
overload operator % = {emod_int, mod}

val min_nat = {ocaml: "min_int", interpreter: "min_int", lem: "min", coq: "min_nat", c: "min_int"} : (nat, nat) -> nat

val min_int = {ocaml: "min_int", interpreter: "min_int", lem: "min", coq: "Z.min", c: "min_int"} : (int, int) -> int

val max_nat = {ocaml: "max_int", interpreter: "max_int", lem: "max", coq: "max_nat", c: "max_int"} : (nat, nat) -> nat

val max_int = {ocaml: "max_int", interpreter: "max_int", lem: "max", coq: "Z.max", c: "max_int"} : (int, int) -> int

overload min = {min_nat, min_int}

overload max = {max_nat, max_int}

val pow2 = "pow2" : forall 'n. atom('n) -> atom(2 ^ 'n)

val print = "print_endline" : string -> unit
val print_string = "print_string" : (string, string) -> unit

val print_instr    = {ocaml: "Platform.print_instr", interpreter: "print_endline", c: "print_instr", lem: "print_dbg", _: "print_endline"} : string -> unit
val print_reg      = {ocaml: "Platform.print_reg", interpreter: "print_endline", c: "print_reg", lem: "print_dbg", _: "print_endline"} : string -> unit
val print_mem      = {ocaml: "Platform.print_mem_access", interpreter: "print_endline", c: "print_mem_access", lem: "print_dbg", _: "print_endline"} : string -> unit
val print_platform = {ocaml: "Platform.print_platform", interpreter: "print_endline", c: "print_platform", lem: "print_dbg", _: "print_endline"} : string -> unit

val get_config_print_instr = {ocaml: "Platform.get_config_print_instr", c:"get_config_print_instr"} : unit -> bool
val get_config_print_reg = {ocaml: "Platform.get_config_print_reg", c:"get_config_print_reg"} : unit -> bool
val get_config_print_mem = {ocaml: "Platform.get_config_print_mem", c:"get_config_print_mem"} : unit -> bool

val get_config_print_platform = {ocaml: "Platform.get_config_print_platform", c:"get_config_print_platform"} : unit -> bool
// defaults for other backends
function get_config_print_instr () = false
function get_config_print_reg () = false
function get_config_print_mem () = false
function get_config_print_platform () = false

val EXTS : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)
val EXTZ : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function EXTS(m, v) = sail_sign_extend(v, m)
function EXTZ(m, v) = sail_zero_extend(v, m)

val zeros_implicit : forall 'n, 'n >= 0 . implicit('n) -> bits('n)
function zeros_implicit (n) = sail_zeros(n)
overload zeros = {zeros_implicit}

val ones : forall 'n, 'n >= 0 . implicit('n) -> bits('n)
function ones (n) = sail_ones (n)

val bool_to_bits : bool -> bits(1)
function bool_to_bits x = if x then 0b1 else 0b0

val bit_to_bool : bit -> bool
function bit_to_bool b = match b {
  bitone  => true,
  bitzero => false
}

val to_bits : forall 'l, 'l >= 0.(atom('l), int) -> bits('l)
function to_bits (l, n) = get_slice_int(l, n, 0)

infix 4 <_s
infix 4 >=_s
infix 4 <_u
infix 4 >=_u
infix 4 <=_u

val operator <_s  : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator >=_s : forall 'n, 'n > 0. (bits('n), bits('n)) -> bool
val operator <_u  : forall 'n. (bits('n), bits('n)) -> bool
val operator >=_u : forall 'n. (bits('n), bits('n)) -> bool
val operator <=_u : forall 'n. (bits('n), bits('n)) -> bool

function operator <_s  (x, y) = signed(x) < signed(y)
function operator >=_s (x, y) = signed(x) >= signed(y)
function operator <_u  (x, y) = unsigned(x) < unsigned(y)
function operator >=_u (x, y) = unsigned(x) >= unsigned(y)
function operator <=_u (x, y) = unsigned(x) <= unsigned(y)

infix 7 >>
infix 7 <<

val "shift_bits_right" : forall 'n 'm. (bits('n), bits('m)) -> bits('n)
val "shift_bits_left"  : forall 'n 'm. (bits('n), bits('m)) -> bits('n)

val "shiftl" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)
val "shiftr" : forall 'm 'n, 'n >= 0. (bits('m), atom('n)) -> bits('m)

overload operator >> = {shift_bits_right, shiftr}
overload operator << = {shift_bits_left, shiftl}

/* Ideally these would be sail builtin */

function shift_right_arith64 (v : bits(64), shift : bits(6)) -> bits(64) =
    let v128 : bits(128) = EXTS(v) in
    (v128 >> shift)[63..0]

function shift_right_arith32 (v : bits(32), shift : bits(5)) -> bits(32) =
    let v64 : bits(64) = EXTS(v) in
    (v64 >> shift)[31..0]

val "decimal_string_of_bits" : forall 'n. bits('n) -> string
val hex_bits : forall 'n . (atom('n), bits('n)) <-> string

/* Define the XLEN value for the architecture. */

type xlen       : Int = 64
type xlen_bytes : Int = 8
type xlenbits         = bits(xlen)
/* The default metadata carries no information, and is implemented
 * using a unit type.
 */

type mem_meta = unit

let default_meta : mem_meta = ()

val __WriteRAM_Meta : forall 'n. (xlenbits, atom('n), mem_meta) -> unit effect {wmvt}
function __WriteRAM_Meta(addr, width, meta) = ()

val __ReadRAM_Meta  : forall 'n. (xlenbits, atom('n)) -> mem_meta effect {rmem}
function __ReadRAM_Meta(addr, width) = ()
/* These functions define the primitives for physical memory access.
 * They depend on the XLEN of the architecture.
 *
 * They also depend on the type of metadata that is read and written
 * to physical memory.  For models that do not require this metadata,
 * a unit type can be used.
 *
 * The underlying __read_mem and __write_mem functions are from the
 * Sail library.  The metadata primitives __{Read,Write}RAM_Meta are
 * in prelude_mem_metadata.
 */


/* This is a slightly arbitrary limit on the maximum number of bytes
   in a memory access.  It helps to generate slightly better C code
   because it means width argument can be fast native integer. It
   would be even better if it could be <= 8 bytes so that data can
   also be a 64-bit int but CHERI needs 128-bit accesses for
   capabilities and SIMD / vector instructions will also need more. */
type max_mem_access : Int = 16

val write_ram = {lem: "write_ram", coq: "write_ram"} : forall 'n, 0 < 'n <= max_mem_access . (write_kind, xlenbits, atom('n), bits(8 * 'n), mem_meta) -> bool effect {wmv, wmvt}

val write_ram_ea : forall 'n, 0 < 'n <= max_mem_access . (write_kind, xlenbits, atom('n)) -> unit effect {eamem}
function write_ram_ea(wk, addr, width) =
  __write_mem_ea(wk, sizeof(xlen), addr, width)

val read_ram = {lem: "read_ram", coq: "read_ram"} : forall 'n, 0 < 'n <= max_mem_access .  (read_kind, xlenbits, atom('n), bool) -> (bits(8 * 'n), mem_meta) effect {rmem, rmemt}
function read_ram(rk, addr, width, read_meta) =
  let meta = if read_meta then __ReadRAM_Meta(addr, width) else default_meta in
  (__read_mem(rk, sizeof(xlen), addr, width), meta)


/* Basic type and function definitions used pervasively in the model. */

/* this value is only defined for the runtime platform for ELF loading
 * checks, and not used in the model.
 */
let xlen_val = sizeof(xlen)

let xlen_max_unsigned = 2 ^ sizeof(xlen) - 1
let xlen_max_signed = 2 ^ (sizeof(xlen) - 1) - 1
let xlen_min_signed = 0 - 2 ^ (sizeof(xlen) - 1)

type half = bits(16)
type word = bits(32)

/* register identifiers */

type regidx  = bits(5)
type cregidx = bits(3)    /* identifiers in RVC instructions */
type csreg   = bits(12)   /* CSR addressing */

/* register file indexing */

type regno ('n : Int), 0 <= 'n < 32 = atom('n)

val regidx_to_regno : bits(5) -> {'n, 0 <= 'n < 32. regno('n)}
function regidx_to_regno b = let 'r = unsigned(b) in r

/* mapping RVC register indices into normal indices */
val creg2reg_idx : cregidx -> regidx
function creg2reg_idx(creg) = 0b01 @ creg

/* some architecture and ABI relevant register identifiers */
let zreg : regidx = 0b00000  /* x0, zero register  */
let ra   : regidx = 0b00001  /* x1, return address */
let sp   : regidx = 0b00010  /* x2, stack pointer  */

/* instruction fields */

type opcode = bits(7)
type imm12  = bits(12)
type imm20  = bits(20)
type amo    = bits(1)  /* amo opcode flags */

/* base architecture definitions */

enum Architecture = {RV32, RV64, RV128}
type arch_xlen = bits(2)
function architecture(a : arch_xlen) -> option(Architecture) =
  match (a) {
    0b01 => Some(RV32),
    0b10 => Some(RV64),
    0b11 => Some(RV128),
    _    => None()
  }

function arch_to_bits(a : Architecture) -> arch_xlen =
  match (a) {
    RV32  => 0b01,
    RV64  => 0b10,
    RV128 => 0b11
  }

/* enum denoting whether an executed instruction retires */

enum Retired = {RETIRE_SUCCESS, RETIRE_FAIL}

/* memory access types */

union AccessType ('a : Type) = {
  Read      : 'a,
  Write     : 'a,
  ReadWrite : ('a, 'a),
  Execute   : unit
}

enum word_width = {BYTE, HALF, WORD, DOUBLE}
/* model-internal exceptions */

union exception = {
  Error_not_implemented : string,
  Error_internal_error  : unit
}

val not_implemented : forall ('a : Type). string -> 'a effect {escape}
function not_implemented message = throw(Error_not_implemented(message))

val internal_error : forall ('a : Type). string -> 'a effect {escape}
function internal_error(s) = {
    assert (false, s);
    throw Error_internal_error()
}

/* instruction opcode grouping */
enum bop = {RISCV_BEQ, RISCV_BNE, RISCV_BLT,
            RISCV_BGE, RISCV_BLTU, RISCV_BGEU}    /* branch ops */
enum iop = {RISCV_ADDI, RISCV_SLTI, RISCV_SLTIU,
            RISCV_XORI, RISCV_ORI, RISCV_ANDI}    /* immediate ops */

mapping bool_bits : bool <-> bits(1) = {
  true   <-> 0b1,
  false  <-> 0b0
}

mapping bool_not_bits : bool <-> bits(1) = {
  true   <-> 0b0,
  false  <-> 0b1
}

mapping size_bits : word_width <-> bits(2) = {
  BYTE   <-> 0b00,
  HALF   <-> 0b01,
  WORD   <-> 0b10,
  DOUBLE <-> 0b11
}

val word_width_bytes : word_width -> {'s, 's == 1 | 's == 2 | 's == 4 | 's == 8 . atom('s)}
function word_width_bytes width = match width {
  BYTE   => 1,
  HALF   => 2,
  WORD   => 4,
  DOUBLE => 8
}
// Extensions for memory Accesstype.

type ext_access_type = unit

let Data  : ext_access_type = ()

let default_write_acc : ext_access_type = Data

val accessType_to_str : AccessType(ext_access_type) -> string
function accessType_to_str (a) =
  match (a) {
    Read(Data)            => "R",
    Write(Data)           => "W",
    ReadWrite(Data, Data) => "RW",
    Execute()             => "X"
  }

overload to_str = {accessType_to_str}
/* default register type */
type regtype = xlenbits

/* default zero register */
let zero_reg : regtype = EXTZ(0x0)

/* default register printer */
val RegStr : regtype -> string
function RegStr(r) = BitStr(r)

/* conversions */

val regval_from_reg : regtype -> xlenbits
function regval_from_reg(r) = r

val regval_into_reg : xlenbits -> regtype
function regval_into_reg(v) = v
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

val rX : forall 'n, 0 <= 'n < 32. regno('n) -> xlenbits effect {rreg, escape}
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
      31 => x31,
      _  => {assert(false, "invalid register number"); zero_reg}
    };
  regval_from_reg(v)
}

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
    31 => x31 = v,
    _  => assert(false, "invalid register number")
  };
  if (r != 0) then {
     if   get_config_print_reg()
     then print_reg("x" ^ string_of_int(r) ^ " <- " ^ RegStr(v));
  }
}

function rX_bits(i: bits(5)) -> xlenbits = rX(unsigned(i))

function wX_bits(i: bits(5), data: xlenbits) -> unit = {
  wX(unsigned(i)) = data
}

overload X = {rX_bits, wX_bits, rX, wX}

val init_base_regs : unit -> unit effect {wreg}
function init_base_regs () = {
  x1  = zero_reg;
  x2  = zero_reg;
  x3  = zero_reg;
  x4  = zero_reg;
  x5  = zero_reg;
  x6  = zero_reg;
  x7  = zero_reg;
  x8  = zero_reg;
  x9  = zero_reg;
  x10 = zero_reg;
  x11 = zero_reg;
  x12 = zero_reg;
  x13 = zero_reg;
  x14 = zero_reg;
  x15 = zero_reg;
  x16 = zero_reg;
  x17 = zero_reg;
  x18 = zero_reg;
  x19 = zero_reg;
  x20 = zero_reg;
  x21 = zero_reg;
  x22 = zero_reg;
  x23 = zero_reg;
  x24 = zero_reg;
  x25 = zero_reg;
  x26 = zero_reg;
  x27 = zero_reg;
  x28 = zero_reg;
  x29 = zero_reg;
  x30 = zero_reg;
  x31 = zero_reg
}
/* accessors for default architectural addresses, for use from within instructions */

/*!
  Retrieves the architectural PC value. This is not necessarily the value
  found in the PC register as extensions may choose to override this function.
  The value in the PC register is the absolute virtual address of the instruction
  to fetch.
 */
val get_arch_pc : unit -> xlenbits effect {rreg}
function get_arch_pc() = PC

val get_next_pc : unit -> xlenbits effect {rreg}
function get_next_pc() = nextPC

val set_next_pc : xlenbits -> unit effect {wreg}
function set_next_pc(pc) = {
  nextPC = pc
}

val tick_pc : unit -> unit effect {rreg, wreg}
function tick_pc() = {
  PC = nextPC
}

/* Extensions may wish to interpose on fetch, control transfer, and data
 * addresses used to access memory and perhaps modify them.  This file
 * defines the return values used by functions that perform this interposition.
 *
 * The model defines defaults for these functions in riscv_addr_checks.sail;
 * extensions would need to define their own functions to override them.
 */

union Ext_FetchAddr_Check ('a : Type) = {
  Ext_FetchAddr_OK  : xlenbits,  /* PC value to use for the actual fetch */
  Ext_FetchAddr_Error : 'a
}

union Ext_ControlAddr_Check ('a : Type) = {
  Ext_ControlAddr_OK : xlenbits, /* PC value to use for the target of the control operation */
  Ext_ControlAddr_Error : 'a
}

union Ext_DataAddr_Check ('a : Type) = {
  Ext_DataAddr_OK : xlenbits,    /* Address to use for the data access */
  Ext_DataAddr_Error : 'a
}
/* default fetch address checks */

type ext_fetch_addr_error = unit

/* Since fetch is done in granules, the check function gets two arguments:
 * start_pc: the PC at the start of the current fetch sequence
 * pc:       the PC for the current granule
 *
 * returns:  the *virtual* memory address to use for the fetch.
 *           any address translation errors are reported for pc, not the returned value.
 */
function ext_fetch_check_pc(start_pc : xlenbits, pc : xlenbits) -> Ext_FetchAddr_Check(ext_fetch_addr_error) =
  Ext_FetchAddr_OK(pc)

function ext_handle_fetch_check_error(err : ext_fetch_addr_error) -> unit =
  ()

/* default control address checks */

type ext_control_addr_error = unit

/* these functions return the address to use as the target for
 * the control transfer.  any address translation or other errors
 * are reported for the original value, not the returned value.
 *
 * NOTE: the input value does *not* have bit[0] set to 0, to enable
 * more accurate bounds checking.  There is no constraint on the output
 * value, which will have bit[0] cleared by the caller if needed.
 */

/* the control address is derived from a non-PC register, e.g. in JALR */
function ext_control_check_addr(pc : xlenbits) -> Ext_ControlAddr_Check(ext_control_addr_error) =
  Ext_ControlAddr_OK(pc)

/* the control address is derived from the PC register, e.g. in JAL */
function ext_control_check_pc(pc : xlenbits) -> Ext_ControlAddr_Check(ext_control_addr_error) =
  Ext_ControlAddr_OK(pc)

function ext_handle_control_check_error(err : ext_control_addr_error) -> unit =
  ()


/* The default data address function does not perform any checks so
   just uses unit for error type. */
type ext_data_addr_error = unit

/* Default data addr is just base register + immediate offset (may be zero).
   Extensions might override and add additional checks. */
function ext_data_get_addr(base : regidx, offset : xlenbits, acc : AccessType(ext_access_type), width : word_width)
         -> Ext_DataAddr_Check(ext_data_addr_error) =
  let addr = X(base) + offset in
  Ext_DataAddr_OK(addr)

/* Machine-mode and supervisor-mode functionality. */

union ExceptionType = {
 E_Fetch_Addr_Align   : unit,
 E_Fetch_Access_Fault : unit,
 E_Illegal_Instr      : unit,
 E_Breakpoint         : unit,
 E_Load_Addr_Align    : unit,
 E_Load_Access_Fault  : unit,
 E_SAMO_Addr_Align    : unit,
 E_SAMO_Access_Fault  : unit,
 E_U_EnvCall          : unit,
 E_S_EnvCall          : unit,
 E_Reserved_10        : unit,
 E_M_EnvCall          : unit,
 E_Fetch_Page_Fault   : unit,
 E_Load_Page_Fault    : unit,
 E_Reserved_14        : unit,
 E_SAMO_Page_Fault    : unit,
}

function handle_mem_exception(addr : xlenbits, e : ExceptionType) -> unit = {
  assert(false);
}


/* memory access exceptions, defined here for use by the platform model. */

union MemoryOpResult ('a : Type) = {
  MemValue     : 'a,
  MemException : ExceptionType
}

val MemoryOpResult_add_meta : forall ('t : Type). (MemoryOpResult('t), mem_meta) -> MemoryOpResult(('t, mem_meta))
function MemoryOpResult_add_meta(r, m) = match r {
  MemValue(v)     => MemValue(v, m),
  MemException(e) => MemException(e)
}

val MemoryOpResult_drop_meta : forall ('t : Type). MemoryOpResult(('t, mem_meta)) -> MemoryOpResult('t)
function MemoryOpResult_drop_meta(r) = match r {
  MemValue(v, m)  => MemValue(v),
  MemException(e) => MemException(e)
}

/* whether the platform supports misaligned accesses without trapping to M-mode. if false,
 * misaligned loads/stores are trapped to Machine mode.
 */
function plat_enable_misaligned_access ()  : unit -> bool = true

/* Platform-specific handling of instruction faults */

function handle_illegal() -> unit = {
  assert(false);
}

/* Physical memory model.
 *
 * This assumes that the platform memory map has been defined, so that accesses
 * to MMIO regions can be dispatched.
 *
 * The implementation below supports the reading and writing of memory
 * metadata in addition to raw memory data.
 *
 * The external API for this module is
 *   {mem_read, mem_read_meta, mem_write_ea, mem_write_value_meta, mem_write_value}
 * where mem_write_value is a special case of mem_write_value_meta that uses
 * a default value of the metadata.
 *
 * The internal implementation first performs a PMP check (if PMP is
 * enabled), and then dispatches to MMIO regions or physical memory as
 * per the platform memory map.
 */

function is_aligned_addr forall 'n. (addr : xlenbits, width : atom('n)) -> bool =
  unsigned(addr) % width == 0

function read_kind_of_flags (aq : bool, rl : bool, res : bool) -> option(read_kind) =
  match (aq, rl, res) {
    (false, false, false) => Some(Read_plain),
    (true, false, false)  => Some(Read_RISCV_acquire),
    (true, true, false)   => Some(Read_RISCV_strong_acquire),
    (false, false, true)  => Some(Read_RISCV_reserved),
    (true, false, true)   => Some(Read_RISCV_reserved_acquire),
    (true, true, true)    => Some(Read_RISCV_reserved_strong_acquire),
    (false, true, false)  => None(), /* should these be instead throwing error_not_implemented as below? */
    (false, true, true)   => None()
  }

// only used for actual memory regions, to avoid MMIO effects
function phys_mem_read forall 'n, 0 < 'n <= max_mem_access . (t : AccessType(ext_access_type), paddr : xlenbits, width : atom('n), aq : bool, rl: bool, res : bool, meta : bool) -> MemoryOpResult((bits(8 * 'n), mem_meta)) = {
  let result = (match read_kind_of_flags(aq, rl, res) {
    Some(rk) => Some(read_ram(rk, paddr, width, meta)),
    None()   => None()
  }) : option((bits(8 * 'n), mem_meta));
  match (t, result) {
    (Execute(),  None()) => MemException(E_Fetch_Access_Fault()),
    (Read(Data), None()) => MemException(E_Load_Access_Fault()),
    (_,          None()) => MemException(E_SAMO_Access_Fault()),
    (_,      Some(v, m)) => { MemValue(v, m) }
  }
}

val mem_read      : forall 'n, 0 < 'n <= max_mem_access . (AccessType(ext_access_type), xlenbits, atom('n), bool, bool, bool) -> MemoryOpResult(bits(8 * 'n))             effect {rmem, rmemt, rreg, escape}

function mem_read (typ, paddr, width, aq, rl, res) = {
 let result : MemoryOpResult(bits(8 * 'n)) =
  if (aq | res) & (~ (is_aligned_addr(paddr, width)))
  then MemException(E_Load_Addr_Align())
  else match (aq, rl, res) {
    (false, true,  false) => throw(Error_not_implemented("load.rl")),
    (false, true,  true)  => throw(Error_not_implemented("lr.rl")),
    (_, _, _)             => MemoryOpResult_drop_meta(phys_mem_read(typ, paddr, width, aq, rl, res, false))
  };
 result
}

val mem_write_ea : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, atom('n), bool, bool, bool) -> MemoryOpResult(unit) effect {eamem, escape}

function mem_write_ea (addr, width, aq, rl, con) = {
  if (rl | con) & (~ (is_aligned_addr(addr, width)))
  then MemException(E_SAMO_Addr_Align())
  else match (aq, rl, con) {
    (false, false, false) => MemValue(write_ram_ea(Write_plain, addr, width)),
    (false, true,  false) => MemValue(write_ram_ea(Write_RISCV_release, addr, width)),
    (false, false, true)  => MemValue(write_ram_ea(Write_RISCV_conditional, addr, width)),
    (false, true , true)  => MemValue(write_ram_ea(Write_RISCV_conditional_release, addr, width)),
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  true,  false) => MemValue(write_ram_ea(Write_RISCV_strong_release, addr, width)),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq")),
    (true,  true , true)  => MemValue(write_ram_ea(Write_RISCV_conditional_strong_release, addr, width))
  }
}

// only used for actual memory regions, to avoid MMIO effects
function phys_mem_write forall 'n, 0 < 'n <= max_mem_access . (wk : write_kind, paddr : xlenbits, width : atom('n), data : bits(8 * 'n), meta : mem_meta) -> MemoryOpResult(bool) = {
  let result = MemValue(write_ram(wk, paddr, width, data, meta));
  result
}

/* Atomic accesses can be done to MMIO regions, e.g. in kernel access to device registers. */

/* Memory write with an explicit metadata value.  Metadata writes are
 * currently assumed to have the same alignment constraints as their
 * data.
 * NOTE: The wreg effect is due to MMIO, the rreg is due to checking mtime.
 */
val mem_write_value_meta : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, atom('n), bits(8 * 'n), ext_access_type, mem_meta, bool, bool, bool) -> MemoryOpResult(bool) effect {wmv, wmvt, rreg, wreg, escape}
function mem_write_value_meta (paddr, width, value, ext_acc, meta, aq, rl, con) = {
  if (rl | con) & (~ (is_aligned_addr(paddr, width)))
  then MemException(E_SAMO_Addr_Align())
  else match (aq, rl, con) {
    (false, false, false) => phys_mem_write(Write_plain, paddr, width, value, meta),
    (false, true,  false) => phys_mem_write(Write_RISCV_release, paddr, width, value, meta),
    (false, false, true)  => phys_mem_write(Write_RISCV_conditional, paddr, width, value, meta),
    (false, true , true)  => phys_mem_write(Write_RISCV_conditional_release, paddr, width, value, meta),
    (true,  true,  false) => phys_mem_write(Write_RISCV_strong_release, paddr, width, value, meta),
    (true,  true , true)  => phys_mem_write(Write_RISCV_conditional_strong_release, paddr, width, value, meta),
    // throw an illegal instruction here?
    (true,  false, false) => throw(Error_not_implemented("store.aq")),
    (true,  false, true)  => throw(Error_not_implemented("sc.aq"))
  }
}

/* Memory write with a default metadata value. */
val mem_write_value : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, atom('n), bits(8 * 'n), bool, bool, bool) -> MemoryOpResult(bool) effect {wmv, wmvt, rreg, wreg, escape}
function mem_write_value (paddr, width, value, aq, rl, con) =
  mem_write_value_meta(paddr, width, value, default_write_acc, default_meta, aq, rl, con)

/* Result of address translation */

type ext_ptw = unit

union TR_Result('paddr : Type, 'failure : Type) = {
  TR_Address : ('paddr, ext_ptw),
  TR_Failure : ('failure, ext_ptw)
}

val translateAddr : (xlenbits, AccessType(ext_access_type)) -> TR_Result(xlenbits, ExceptionType) effect {escape, rmem, rmemt, rreg, wmv, wmvt, wreg}
function translateAddr(vAddr, ac) = {
  TR_Address(vAddr, ());
}

/* Instruction definitions.
 *
 * This includes decoding, execution, and assembly parsing and printing.
 */

scattered union ast

/* returns whether an instruction was retired, used for computing minstret */
val execute : ast -> Retired effect {escape, wreg, rreg, wmv, wmvt, eamem, rmem, rmemt, barr, exmem, undef}
scattered function execute

val encdec : ast <-> bits(32)
scattered mapping encdec

///* see riscv_jalr_seq.sail or riscv_jalr_rmem.sail for the execute clause. */
//
///* *****************************************************************
//union clause ast = BTYPE : (bits(13), regidx, regidx, bop)
//
//mapping encdec_bop : bop <-> bits(3) = {
//  RISCV_BEQ  <-> 0b000,
//  RISCV_BNE  <-> 0b001,
//  RISCV_BLT  <-> 0b100,
//  RISCV_BGE  <-> 0b101,
//  RISCV_BLTU <-> 0b110,
//  RISCV_BGEU <-> 0b111
//}
//
//mapping clause encdec = BTYPE(imm7_6 @ imm5_0 @ imm7_5_0 @ imm5_4_1 @ 0b0, rs2, rs1, op)
//  <-> imm7_6 : bits(1) @ imm7_5_0 : bits(6) @ rs2 @ rs1 @ encdec_bop(op) @ imm5_4_1 : bits(4) @ imm5_0 : bits(1) @ 0b1100011
//
//function clause execute (BTYPE(imm, rs2, rs1, op)) = {
//  let rs1_val = X(rs1);
//  let rs2_val = X(rs2);
//  let taken : bool = match op {
//    RISCV_BEQ  => rs1_val == rs2_val,
//    RISCV_BNE  => rs1_val != rs2_val,
//    RISCV_BLT  => rs1_val <_s rs2_val,
//    RISCV_BGE  => rs1_val >=_s rs2_val,
//    RISCV_BLTU => rs1_val <_u rs2_val,
//    RISCV_BGEU => rs1_val >=_u rs2_val
//  };
//  let t : xlenbits = PC + EXTS(imm);
//  if taken then {
//    /* Extensions get the first checks on the prospective target address. */
//    match ext_control_check_pc(t) {
//      Ext_ControlAddr_Error(e) => {
//        assert(false);
//        RETIRE_FAIL
//      },
//      Ext_ControlAddr_OK(target) => {
//        if bit_to_bool(target[1]) & (~ (haveRVC())) then {
//          handle_mem_exception(target, E_Fetch_Addr_Align());
//          RETIRE_FAIL;
//        } else {
//          set_next_pc(target);
//          RETIRE_SUCCESS
//        }
//      }
//    }
//  } else RETIRE_SUCCESS
//}

/* ****************************************************************** */
union clause ast = ITYPE : (bits(12), regidx, regidx, iop)

mapping encdec_iop : iop <-> bits(3) = {
  RISCV_ADDI  <-> 0b000,
  RISCV_SLTI  <-> 0b010,
  RISCV_SLTIU <-> 0b011,
  RISCV_ANDI  <-> 0b111,
  RISCV_ORI   <-> 0b110,
  RISCV_XORI  <-> 0b100
}

mapping clause encdec = ITYPE(imm, rs1, rd, op)
  <-> imm @ rs1 @ encdec_iop(op) @ rd @ 0b0010011

function clause execute (ITYPE (imm, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let immext : xlenbits = EXTS(imm);
  let result : xlenbits = match op {
    RISCV_ADDI  => rs1_val + immext,
    RISCV_SLTI  => EXTZ(bool_to_bits(rs1_val <_s immext)),
    RISCV_SLTIU => EXTZ(bool_to_bits(rs1_val <_u immext)),
    RISCV_ANDI  => rs1_val & immext,
    RISCV_ORI   => rs1_val | immext,
    RISCV_XORI  => rs1_val ^ immext
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

mapping itype_mnemonic : iop <-> string = {
  RISCV_ADDI  <-> "addi",
  RISCV_SLTI  <-> "slti",
  RISCV_SLTIU <-> "sltiu",
  RISCV_XORI  <-> "xori",
  RISCV_ORI   <-> "ori",
  RISCV_ANDI  <-> "andi"
}

/* ****************************************************************** */
union clause ast = LOAD : (bits(12), regidx, regidx, bool, word_width, bool, bool)

/* unsigned loads are only present for widths strictly less than xlen,
   signed loads also present for widths equal to xlen */
mapping clause encdec = LOAD(imm, rs1, rd, is_unsigned, size, false, false) if (word_width_bytes(size) < sizeof(xlen_bytes)) | (not_bool(is_unsigned) & word_width_bytes(size) <= sizeof(xlen_bytes))
  <-> imm @ rs1 @ bool_bits(is_unsigned) @ size_bits(size) @ rd @ 0b0000011 if (word_width_bytes(size) < sizeof(xlen_bytes)) | (not_bool(is_unsigned) & word_width_bytes(size) <= sizeof(xlen_bytes))

val extend_value : forall 'n, 0 < 'n <= xlen_bytes. (bool, MemoryOpResult(bits(8 * 'n))) -> MemoryOpResult(xlenbits)
function extend_value(is_unsigned, value) = match (value) {
  MemValue(v)     => MemValue(if is_unsigned then EXTZ(v) else EXTS(v) : xlenbits),
  MemException(e) => MemException(e)
}

val process_load : forall 'n, 0 < 'n <= xlen_bytes. (regidx, xlenbits, MemoryOpResult(bits(8 * 'n)), bool) -> Retired effect {escape, rreg, wreg}
function process_load(rd, addr, value, is_unsigned) =
  match extend_value(is_unsigned, value) {
    MemValue(result) => { X(rd) = result; RETIRE_SUCCESS },
    MemException(e)  => { handle_mem_exception(addr, e); RETIRE_FAIL }
  }

function check_misaligned(vaddr : xlenbits, width : word_width) -> bool =
  if   plat_enable_misaligned_access() then false
  else match width {
         BYTE   => false,
         HALF   => vaddr[0] == bitone,
         WORD   => vaddr[0] == bitone | vaddr[1] == bitone,
         DOUBLE => vaddr[0] == bitone | vaddr[1] == bitone | vaddr[2] == bitone
       }

function clause execute(LOAD(imm, rs1, rd, is_unsigned, width, aq, rl)) = {
  let offset : xlenbits = EXTS(imm);
  /* Get the address, X(rs1) + offset.
     Some extensions perform additional checks on address validity. */
  match ext_data_get_addr(rs1, offset, Read(Data), width) {
    Ext_DataAddr_Error(e)  => { assert(false); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      if   check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); RETIRE_FAIL }
      else match translateAddr(vaddr, Read(Data)) {
        TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) =>
          match (width, sizeof(xlen)) {
            (BYTE, _)   =>
               process_load(rd, vaddr, mem_read(Read(Data), addr, 1, aq, rl, false), is_unsigned),
            (HALF, _)   =>
               process_load(rd, vaddr, mem_read(Read(Data), addr, 2, aq, rl, false), is_unsigned),
            (WORD, _)   =>
               process_load(rd, vaddr, mem_read(Read(Data), addr, 4, aq, rl, false), is_unsigned),
            (DOUBLE, 64) =>
               process_load(rd, vaddr, mem_read(Read(Data), addr, 8, aq, rl, false), is_unsigned)
          }
      }
  }
}

/* ****************************************************************** */
union clause ast = STORE : (bits(12), regidx, regidx, word_width, bool, bool)

mapping clause encdec = STORE(imm7 @ imm5, rs2, rs1, size, false, false)              if word_width_bytes(size) <= sizeof(xlen_bytes)
  <-> imm7 : bits(7) @ rs2 @ rs1 @ 0b0 @ size_bits(size) @ imm5 : bits(5) @ 0b0100011 if word_width_bytes(size) <= sizeof(xlen_bytes)

/* NOTE: Currently, we only EA if address translation is successful.
   This may need revisiting. */
function clause execute (STORE(imm, rs2, rs1, width, aq, rl)) = {
  let offset : xlenbits = EXTS(imm);
  /* Get the address, X(rs1) + offset.
     Some extensions perform additional checks on address validity. */
  match ext_data_get_addr(rs1, offset, Write(Data), width) {
    Ext_DataAddr_Error(e)  => { assert (false); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      if   check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
      else match translateAddr(vaddr, Write(Data)) {
        TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) => {
          let eares : MemoryOpResult(unit) = match width {
            BYTE   => mem_write_ea(addr, 1, aq, rl, false),
            HALF   => mem_write_ea(addr, 2, aq, rl, false),
            WORD   => mem_write_ea(addr, 4, aq, rl, false),
            DOUBLE => mem_write_ea(addr, 8, aq, rl, false)
          };
          match (eares) {
            MemException(e) => { handle_mem_exception(addr, e); RETIRE_FAIL },
            MemValue(_) => {
              let rs2_val = X(rs2);
              let res : MemoryOpResult(bool) = match (width, sizeof(xlen)) {
                (BYTE, _)    => mem_write_value(addr, 1, rs2_val[7..0],  aq, rl, false),
                (HALF, _)    => mem_write_value(addr, 2, rs2_val[15..0], aq, rl, false),
                (WORD, _)    => mem_write_value(addr, 4, rs2_val[31..0], aq, rl, false),
                (DOUBLE, 64) => mem_write_value(addr, 8, rs2_val,        aq, rl, false)
              };
              match (res) {
                MemValue(true)  => RETIRE_SUCCESS,
                MemValue(false) => internal_error("store got false from mem_write_value"),
                MemException(e) => { handle_mem_exception(addr, e); RETIRE_FAIL }
              }
            }
          }
        }
      }
  }
}

/* Put the illegal instructions last to use their wildcard match. */

/* ****************************************************************** */

union clause ast = ILLEGAL : word

mapping clause encdec = ILLEGAL(s) <-> s

function clause execute (ILLEGAL(s)) = { handle_illegal(); RETIRE_FAIL }

/* ****************************************************************** */

/* End definitions */
end ast
end execute
end encdec
end encdec_compressed

val decode : bits(32) -> ast effect pure
function decode bv = encdec(bv)

/* The result of a fetch, which includes any possible error
 * from an extension that interposes on the fetch operation.
 */

union FetchResult = {
  F_Ext_Error : ext_fetch_addr_error,      /* For extensions */
  F_Base      : word,                      /* Base ISA */
  F_RVC       : half,                      /* Compressed ISA */
  F_Error     : (ExceptionType, xlenbits)  /* standard exception and PC */
}
/* The default implementation of hooks for the step() and main() functions. */

function ext_init() -> unit = ()

function ext_fetch_hook(f : FetchResult) -> FetchResult = f

function ext_pre_step_hook()  -> unit = ()
function ext_post_step_hook() -> unit = ()
/* Extensions may wish to interpose and transform decoded instructions,
 * based on other machine state.  This is supported via a post-decode
 * instruction hook, the default implementation of which is provided below.
 */

val ext_post_decode_hook : ast -> ast effect {rreg}
function ext_post_decode_hook(x) = x

val fetch : unit -> FetchResult effect {escape, rmem, rmemt, rreg, wmv, wmvt, wreg}
function fetch() -> FetchResult =
  /* fetch PC check for extensions: extensions return a transformed PC to fetch,
   * but any exceptions use the untransformed PC.
   */
  match ext_fetch_check_pc(PC, PC) {
    Ext_FetchAddr_Error(e)   => F_Ext_Error(e),
    Ext_FetchAddr_OK(use_pc) => {
      if   (use_pc[0] != bitzero | (use_pc[1] != bitzero))
      then F_Error(E_Fetch_Addr_Align(), PC)
      else match translateAddr(use_pc, Execute()) {
        TR_Failure(e, _)     => F_Error(e, PC),
        TR_Address(ppc, _) => {
          match mem_read(Execute(), ppc, 4, false, false, false) {
            MemException(e) => F_Error(e, PC),
            MemValue(ibits)   => F_Base(ibits)
            }
          }
        }
      }
    }
    
/* The emulator fetch-execute-interrupt dispatch loop. */

/* returns whether to increment the step count in the trace */
function step(step_no : int) -> bool = {
  /* for step extensions */
  ext_pre_step_hook();

  let (retired, stepped) : (Retired, bool) =
      /* the extension hook interposes on the fetch result */
      let f : FetchResult = ext_fetch_hook(fetch()) in
      match f {
        /* extension error */
        F_Ext_Error(e)   => {
          ext_handle_fetch_check_error(e);
          (RETIRE_FAIL, false)
        },
        /* standard error */
        F_Error(e, addr) => {
          handle_mem_exception(addr, e);
          (RETIRE_FAIL, false)
        },
        F_Base(w) => {
          let ast = decode(w);
          nextPC = PC + 4;
          (execute(ext_post_decode_hook(ast)), true)
        }
      };

  tick_pc();

  /* for step extensions */
  ext_post_step_hook();

  stepped
}

function loop () : unit -> unit = {
  step_no : int = 0;
  while (true) do {
    let stepped = step(step_no);
    if stepped then step_no = step_no + 1;
  }
}


function main () : unit -> unit = {
  // PC = __GetSlice_int(64, elf_entry(), 0);
  PC = sail_zero_extend(0x1000, sizeof(xlen));
  print_bits("PC = ", PC);

  try {
    loop()
  } catch {
    Error_not_implemented(s) => print_string("Error: Not implemented: ", s),
    Error_internal_error() => print("Error: internal error")
  }
}
