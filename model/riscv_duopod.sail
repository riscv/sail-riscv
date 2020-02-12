
$include "prelude.sail"
$include "riscv_xlen64.sail"

type regbits = bits(5)

val zeros : forall 'n, 'n >= 0. atom('n) -> bits('n)
function zeros n = replicate_bits(0b0, n)

/* Architectural state */

register PC : xlenbits
register nextPC : xlenbits

register Xs : vector(32, dec, xlenbits)

/* Getters and setters for X registers (special case for zeros register, x0) */
val rX : regbits -> xlenbits effect {rreg}

function rX(r) =
  match r {
    0b00000 => EXTZ(0x0),
    _ => Xs[unsigned(r)]
  }

val wX : (regbits, xlenbits) -> unit effect {wreg}

function wX(r, v) =
  if r != 0b00000 then {
     Xs[unsigned(r)] = v;
  }

overload X = {rX, wX}

/* Accessors for memory */
val MEMr = { lem: "MEMr", coq: "MEMr", _ : "read_ram" } : forall 'n 'm, 'n >= 0.
   (atom('m), int('n), bits('m), bits('m)) -> bits(8 * 'n) effect {rmem}

val read_mem : forall 'n, 'n >= 0. (xlenbits, int('n)) -> bits(8 * 'n) effect {rmem}
function read_mem(addr, width) =
    MEMr(sizeof(xlen), width, EXTZ(0x0), addr)

/* Instruction decode and execute */
enum iop = {RISCV_ADDI, RISCV_SLTI, RISCV_SLTIU, RISCV_XORI, RISCV_ORI, RISCV_ANDI}
scattered union ast

val decode : bits(32) -> option(ast) effect pure

val execute : ast -> unit effect {rmem, rreg, wreg}

/* ****************************************************************** */

/* ADDI */

union clause ast = ITYPE : (bits(12), regbits, regbits, iop)

function clause decode imm : bits(12) @ rs1 : regbits @ 0b000 @ rd : regbits @ 0b0010011
  = Some(ITYPE(imm, rs1, rd, RISCV_ADDI))

function clause execute (ITYPE (imm, rs1, rd, RISCV_ADDI)) =
  let rs1_val = X(rs1) in
  let imm_ext : xlenbits = EXTS(imm) in
  let result = rs1_val + imm_ext in
  X(rd) = result

/* ****************************************************************** */

/* Load double */
union clause ast = LOAD : (bits(12), regbits, regbits)

function clause decode imm : bits(12) @ rs1 : regbits @ 0b011 @ rd : regbits @ 0b0000011
  = Some(LOAD(imm, rs1, rd))

function clause execute(LOAD(imm, rs1, rd)) =
    let addr : xlenbits = X(rs1) + EXTS(imm) in
    let result : xlenbits = read_mem(addr, sizeof(xlen_bytes)) in
    X(rd) = result

/* ****************************************************************** */

function clause decode _ = None()

