/* Put the illegal instructions last to use their wildcard match. */

/* ****************************************************************** */

union clause ast = ILLEGAL : word

mapping clause encdec = ILLEGAL(s) <-> s

function clause execute (ILLEGAL(s)) = { handle_illegal(); false }

mapping clause assembly = ILLEGAL(s) <-> "illegal" ^ spc() ^ hex_bits_32(s)

/* ****************************************************************** */

union clause ast = C_ILLEGAL : half

mapping clause encdec_compressed = C_ILLEGAL(s) <-> s

function clause execute C_ILLEGAL(s) = { handle_illegal(); false }

mapping clause assembly = C_ILLEGAL(s) <-> "c.illegal" ^ spc() ^ hex_bits_16(s)

/* ****************************************************************** */

/* End definitions */
end ast
end execute
end assembly
end encdec
end encdec_compressed

val cast print_insn : ast -> string
function print_insn insn = assembly(insn)

val decode : bits(32) -> ast effect pure
function decode bv = encdec(bv)

val decodeCompressed : bits(16) -> ast effect pure
function decodeCompressed bv = encdec_compressed(bv)
