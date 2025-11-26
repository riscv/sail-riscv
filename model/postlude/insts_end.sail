// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Put the illegal instructions last to use their wildcard match.

// *****************************************************************

mapping clause encdec = ILLEGAL(s) <-> s

function clause execute ILLEGAL(_s) = Illegal_Instruction()

mapping clause assembly = ILLEGAL(s) <-> "illegal" ^ spc() ^ hex_bits_32(s)

// *****************************************************************

mapping clause encdec_compressed = C_ILLEGAL(s) <-> s

function clause execute C_ILLEGAL(_s) = Illegal_Instruction()

mapping clause assembly = C_ILLEGAL(s) <-> "c.illegal" ^ spc() ^ hex_bits_16(s)

// *****************************************************************

// End definitions
end extension
end extensionName
end hartSupports
end currentlyEnabled
end instruction
end execute
end assembly
end encdec
end encdec_compressed

function print_insn(insn : instruction) -> string = assembly(insn)

overload to_str = {print_insn}
