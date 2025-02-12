/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* End scattered definitions and default to illegal instructions if no match */

end ast

function clause extensionEnabled(_) = false
end extensionEnabled
end extension

mapping clause encdec = ILLEGAL(s) <-> s
end encdec

mapping clause encdec_compressed = C_ILLEGAL(s) <-> s
end encdec_compressed

function clause execute ILLEGAL(s) = { handle_illegal(); RETIRE_FAIL }
function clause execute C_ILLEGAL(s) = { handle_illegal(); RETIRE_FAIL }
end execute

mapping clause assembly = ILLEGAL(s) <-> "illegal" ^ spc() ^ hex_bits_32(s)
mapping clause assembly = C_ILLEGAL(s) <-> "c.illegal" ^ spc() ^ hex_bits_16(s)
end assembly

val print_insn : ast -> string
function print_insn insn = assembly(insn)

overload to_str = {print_insn}
