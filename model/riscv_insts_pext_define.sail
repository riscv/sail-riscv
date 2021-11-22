/* *****************************************************************/
/* This file specifies the instruction added by the 'P' extension. */
/* *****************************************************************/

union clause ast = PEXT_ADD : (regidx, regidx, regidx, word_width)
mapping clause encdec = PEXT_ADD (rs2, rs1, rd, BYTE) <->
  0b0100100 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_ADD (rs2, rs1, rd, HALF) <->
  0b0100000 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_ADD (rs2, rs1, rd, WORD) <->
  0b0100000 @ rs2 @ rs1 @ 0b010 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_ADD (rs2, rs1, rd, DOUBLE) <->
  0b0110000 @ rs2 @ rs1 @ 0b010 @ rd @ PEXT_SIG

mapping clause assembly = PEXT_ADD (rs2, rs1, rd, width)
  <-> "ADD" ^ pext_width_mnemonic(width) ^ spc() ^
      reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)



union clause ast = PEXT_AVE : (regidx, regidx, regidx)
mapping clause encdec = PEXT_AVE (rs2, rs1, rd) <->
  0b1110000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_AVE (rs2, rs1, rd)
  <-> "AVE" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

union clause ast = PEXT_BITREV : (regidx, regidx, regidx)
mapping clause encdec = PEXT_BITREV (rs2, rs1, rd) <->
  0b1110011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_BITREV (rs2, rs1, rd)
  <-> "BITREV" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_BITREVI : (bits(6), regidx, regidx)
mapping clause encdec = PEXT_BITREVI (imm6, rs1, rd) <->
  0b111010 @ imm6 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_BITREVI (imm6, rs1, rd)
  <-> "BITREVI" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(imm6)


union clause ast = PEXT_BPICK : (regidx, regidx, regidx, regidx)
mapping clause encdec = PEXT_BPICK (rs3, rs2, rs1, rd) <->
  rs3 @ 0b00 @ rs2 @ rs1 @ 0b011 @ rd @ 0b1110111

mapping clause assembly = PEXT_BPICK (rs3, rs2, rs1, rd)
  <-> "BPICK" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ reg_name(rs3)


union clause ast = PEXT_CLRS8 : (regidx, regidx)
mapping clause encdec = PEXT_CLRS8 (rs1, rd) <->
  0b1010111 @ 0b00000 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLRS8 (rs1, rd)
  <-> "CLRS8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLRS16 : (regidx, regidx)
mapping clause encdec = PEXT_CLRS16 (rs1, rd) <->
  0b1010111 @ 0b01000 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLRS16 (rs1, rd)
  <-> "CLRS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLRS32 : (regidx, regidx)
mapping clause encdec = PEXT_CLRS32 (rs1, rd) <->
  0b1010111 @ 0b11000 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLRS32 (rs1, rd)
  <-> "CLRS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLO8 : (regidx, regidx)
mapping clause encdec = PEXT_CLO8 (rs1, rd) <->
  0b1010111 @ 0b00011 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLO8 (rs1, rd)
  <-> "CLO8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLO16 : (regidx, regidx)
mapping clause encdec = PEXT_CLO16 (rs1, rd) <->
  0b1010111 @ 0b01011 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLO16 (rs1, rd)
  <-> "CLO16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLO32 : (regidx, regidx)
mapping clause encdec = PEXT_CLO32 (rs1, rd) <->
  0b1010111 @ 0b11011 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLO32 (rs1, rd)
  <-> "CLO32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLZ8 : (regidx, regidx)
mapping clause encdec = PEXT_CLZ8 (rs1, rd) <->
  0b1010111 @ 0b00001 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLZ8 (rs1, rd)
  <-> "CLZ8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLZ16 : (regidx, regidx)
mapping clause encdec = PEXT_CLZ16 (rs1, rd) <->
  0b1010111 @ 0b01001 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLZ16 (rs1, rd)
  <-> "CLZ16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CLZ32 : (regidx, regidx)
mapping clause encdec = PEXT_CLZ32 (rs1, rd) <->
  0b1010111 @ 0b11001 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CLZ32 (rs1, rd)
  <-> "CLZ32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_CMPEQ8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_CMPEQ8 (rs2, rs1, rd) <->
  0b0100111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CMPEQ8 (rs2, rs1, rd)
  <-> "CMPEQ8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_CMPEQ16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_CMPEQ16 (rs2, rs1, rd) <->
  0b0100110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CMPEQ16 (rs2, rs1, rd)
  <-> "CMPEQ16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_CRAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_CRAS16 (rs2, rs1, rd) <->
  0b0100010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CRAS16 (rs2, rs1, rd)
  <-> "CRAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_CRSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_CRSA16 (rs2, rs1, rd) <->
  0b0100011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_CRSA16 (rs2, rs1, rd)
  <-> "CRSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_INSB : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_INSB (imm3, rs1, rd) <->
  0b1010110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_INSB (imm3, rs1, rd)
  <-> "INSB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_KABS8 : (regidx, regidx)
mapping clause encdec = PEXT_KABS8 (rs1, rd) <->
  0b1010110 @ 0b10000 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KABS8 (rs1, rd)
  <-> "KABS8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_KABS16 : (regidx, regidx)
mapping clause encdec = PEXT_KABS16 (rs1, rd) <->
  0b1010110 @ 0b10001 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KABS16 (rs1, rd)
  <-> "KABS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_KABSW : (regidx, regidx)
mapping clause encdec = PEXT_KABSW (rs1, rd) <->
  0b1010110 @ 0b10100 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KABSW (rs1, rd)
  <-> "KABSW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_KADD : (regidx, regidx, regidx, word_width)
mapping clause encdec = PEXT_KADD (rs2, rs1, rd, BYTE) <->
  0b0001100 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_KADD (rs2, rs1, rd, HALF) <->
  0b0001000 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_KADD (rs2, rs1, rd, WORD) <->
  0b0001000 @ rs2 @ rs1 @ 0b010 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_KADD (rs2, rs1, rd, DOUBLE) <->
  0b1001000 @ rs2 @ rs1 @ 0b001 @ rd @ PEXT_SIG

mapping clause assembly = PEXT_KADD (rs2, rs1, rd, width)
  <-> "KADD" ^ pext_width_mnemonic(width) ^ spc() ^
      reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)



union clause ast = PEXT_KADDH : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KADDH (rs2, rs1, rd) <->
  0b0000010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KADDH (rs2, rs1, rd)
  <-> "KADDH" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KADDW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KADDW (rs2, rs1, rd) <->
  0b0000000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KADDW (rs2, rs1, rd)
  <-> "KADDW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KCRAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KCRAS16 (rs2, rs1, rd) <->
  0b0001010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KCRAS16 (rs2, rs1, rd)
  <-> "KCRAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KCRSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KCRSA16 (rs2, rs1, rd) <->
  0b0001011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KCRSA16 (rs2, rs1, rd)
  <-> "KCRSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMBB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMBB (rs2, rs1, rd) <->
  0b0000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMBB (rs2, rs1, rd)
  <-> "KDMBB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMBT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMBT (rs2, rs1, rd) <->
  0b0001101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMBT (rs2, rs1, rd)
  <-> "KDMBT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMTT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMTT (rs2, rs1, rd) <->
  0b0010101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMTT (rs2, rs1, rd)
  <-> "KDMTT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMABB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMABB (rs2, rs1, rd) <->
  0b1101001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMABB (rs2, rs1, rd)
  <-> "KDMABB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMABT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMABT (rs2, rs1, rd) <->
  0b1110001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMABT (rs2, rs1, rd)
  <-> "KDMABT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMATT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMATT (rs2, rs1, rd) <->
  0b1111001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMATT (rs2, rs1, rd)
  <-> "KDMATT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHM8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHM8 (rs2, rs1, rd) <->
  0b1000111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHM8 (rs2, rs1, rd)
  <-> "KHM8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMX8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMX8 (rs2, rs1, rd) <->
  0b1001111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMX8 (rs2, rs1, rd)
  <-> "KHMX8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHM16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHM16 (rs2, rs1, rd) <->
  0b1000011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHM16 (rs2, rs1, rd)
  <-> "KHM16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMX16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMX16 (rs2, rs1, rd) <->
  0b1001011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMX16 (rs2, rs1, rd)
  <-> "KHMX16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMBB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMBB (rs2, rs1, rd) <->
  0b0000110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMBB (rs2, rs1, rd)
  <-> "KHMBB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMBT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMBT (rs2, rs1, rd) <->
  0b0001110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMBT (rs2, rs1, rd)
  <-> "KHMBT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMTT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMTT (rs2, rs1, rd) <->
  0b0010110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMTT (rs2, rs1, rd)
  <-> "KHMTT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMABB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMABB (rs2, rs1, rd) <->
  0b0101101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMABB (rs2, rs1, rd)
  <-> "KMABB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMABT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMABT (rs2, rs1, rd) <->
  0b0110101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMABT (rs2, rs1, rd)
  <-> "KMABT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMATT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMATT (rs2, rs1, rd) <->
  0b0111101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMATT (rs2, rs1, rd)
  <-> "KMATT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMADA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMADA (rs2, rs1, rd) <->
  0b0100100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMADA (rs2, rs1, rd)
  <-> "KMADA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMAXDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMAXDA (rs2, rs1, rd) <->
  0b0100101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMAXDA (rs2, rs1, rd)
  <-> "KMAXDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMADS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMADS (rs2, rs1, rd) <->
  0b0101110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMADS (rs2, rs1, rd)
  <-> "KMADS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMADRS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMADRS (rs2, rs1, rd) <->
  0b0110110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMADRS (rs2, rs1, rd)
  <-> "KMADRS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMAXDS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMAXDS (rs2, rs1, rd) <->
  0b0111110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMAXDS (rs2, rs1, rd)
  <-> "KMAXDS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMAR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMAR64 (rs2, rs1, rd) <->
  0b1001010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMAR64 (rs2, rs1, rd)
  <-> "KMAR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMDA (rs2, rs1, rd) <->
  0b0011100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMDA (rs2, rs1, rd)
  <-> "KMDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMXDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMXDA (rs2, rs1, rd) <->
  0b0011101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMXDA (rs2, rs1, rd)
  <-> "KMXDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAC : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAC (rs2, rs1, rd) <->
  0b0110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAC (rs2, rs1, rd)
  <-> "KMMAC" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAC_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAC_U (rs2, rs1, rd) <->
  0b0111000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAC_U (rs2, rs1, rd)
  <-> "KMMAC_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWB (rs2, rs1, rd) <->
  0b0100011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWB (rs2, rs1, rd)
  <-> "KMMAWB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWB_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWB_U (rs2, rs1, rd) <->
  0b0101011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWB_U (rs2, rs1, rd)
  <-> "KMMAWB_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWB2 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWB2 (rs2, rs1, rd) <->
  0b1100111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWB2 (rs2, rs1, rd)
  <-> "KMMAWB2" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWB2_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWB2_U (rs2, rs1, rd) <->
  0b1101111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWB2_U (rs2, rs1, rd)
  <-> "KMMAWB2_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWT (rs2, rs1, rd) <->
  0b0110011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWT (rs2, rs1, rd)
  <-> "KMMAWT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWT_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWT_U (rs2, rs1, rd) <->
  0b0111011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWT_U (rs2, rs1, rd)
  <-> "KMMAWT_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWT2 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWT2 (rs2, rs1, rd) <->
  0b1110111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWT2 (rs2, rs1, rd)
  <-> "KMMAWT2" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMAWT2_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMAWT2_U (rs2, rs1, rd) <->
  0b1111111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMAWT2_U (rs2, rs1, rd)
  <-> "KMMAWT2_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMSB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMSB (rs2, rs1, rd) <->
  0b0100001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMSB (rs2, rs1, rd)
  <-> "KMMSB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMSB_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMSB_U (rs2, rs1, rd) <->
  0b0101001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMSB_U (rs2, rs1, rd)
  <-> "KMMSB_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMWB2 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMWB2 (rs2, rs1, rd) <->
  0b1000111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMWB2 (rs2, rs1, rd)
  <-> "KMMWB2" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMWB2_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMWB2_U (rs2, rs1, rd) <->
  0b1001111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMWB2_U (rs2, rs1, rd)
  <-> "KMMWB2_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMWT2 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMWT2 (rs2, rs1, rd) <->
  0b1010111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMWT2 (rs2, rs1, rd)
  <-> "KMMWT2" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMMWT2_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMMWT2_U (rs2, rs1, rd) <->
  0b1011111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMMWT2_U (rs2, rs1, rd)
  <-> "KMMWT2_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMSDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMSDA (rs2, rs1, rd) <->
  0b0100110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMSDA (rs2, rs1, rd)
  <-> "KMSDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMSXDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMSXDA (rs2, rs1, rd) <->
  0b0100111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMSXDA (rs2, rs1, rd)
  <-> "KMSXDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMSR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMSR64 (rs2, rs1, rd) <->
  0b1001011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMSR64 (rs2, rs1, rd)
  <-> "KMSR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLLW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLLW (rs2, rs1, rd) <->
  0b0010011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLLW (rs2, rs1, rd)
  <-> "KSLLW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLLIW : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_KSLLIW (imm5, rs1, rd) <->
  0b0011011 @ imm5 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLLIW (imm5, rs1, rd)
  <-> "KSLLIW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_KSLL8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLL8 (rs2, rs1, rd) <->
  0b0110110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLL8 (rs2, rs1, rd)
  <-> "KSLL8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLLI8 : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_KSLLI8 (imm3, rs1, rd) <->
  0b0111110 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLLI8 (imm3, rs1, rd)
  <-> "KSLLI8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_KSLL16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLL16 (rs2, rs1, rd) <->
  0b0110010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLL16 (rs2, rs1, rd)
  <-> "KSLL16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLLI16 : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_KSLLI16 (imm4, rs1, rd) <->
  0b0111010 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLLI16 (imm4, rs1, rd)
  <-> "KSLLI16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_KSLRA8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRA8 (rs2, rs1, rd) <->
  0b0101111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRA8 (rs2, rs1, rd)
  <-> "KSLRA8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLRA8_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRA8_U (rs2, rs1, rd) <->
  0b0110111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRA8_U (rs2, rs1, rd)
  <-> "KSLRA8_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLRA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRA16 (rs2, rs1, rd) <->
  0b0101011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRA16 (rs2, rs1, rd)
  <-> "KSLRA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLRA16_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRA16_U (rs2, rs1, rd) <->
  0b0110011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRA16_U (rs2, rs1, rd)
  <-> "KSLRA16_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLRAW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRAW (rs2, rs1, rd) <->
  0b0110111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRAW (rs2, rs1, rd)
  <-> "KSLRAW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLRAW_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRAW_U (rs2, rs1, rd) <->
  0b0111111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRAW_U (rs2, rs1, rd)
  <-> "KSLRAW_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSTAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSTAS16 (rs2, rs1, rd) <->
  0b1100010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSTAS16 (rs2, rs1, rd)
  <-> "KSTAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSTSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSTSA16 (rs2, rs1, rd) <->
  0b1100011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSTSA16 (rs2, rs1, rd)
  <-> "KSTSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSUB8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSUB8 (rs2, rs1, rd) <->
  0b0001101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSUB8 (rs2, rs1, rd)
  <-> "KSUB8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSUB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSUB16 (rs2, rs1, rd) <->
  0b0001001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSUB16 (rs2, rs1, rd)
  <-> "KSUB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSUB64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSUB64 (rs2, rs1, rd) <->
  0b1001001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSUB64 (rs2, rs1, rd)
  <-> "KSUB64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSUBH : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSUBH (rs2, rs1, rd) <->
  0b0000011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSUBH (rs2, rs1, rd)
  <-> "KSUBH" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSUBW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSUBW (rs2, rs1, rd) <->
  0b0000001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSUBW (rs2, rs1, rd)
  <-> "KSUBW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KWMMUL : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KWMMUL (rs2, rs1, rd) <->
  0b0110001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KWMMUL (rs2, rs1, rd)
  <-> "KWMMUL" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KWMMUL_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KWMMUL_U (rs2, rs1, rd) <->
  0b0111001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KWMMUL_U (rs2, rs1, rd)
  <-> "KWMMUL_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_MADDR32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_MADDR32 (rs2, rs1, rd) <->
  0b1100010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_MADDR32 (rs2, rs1, rd)
  <-> "MADDR32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_MAXW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_MAXW (rs2, rs1, rd) <->
  0b1111001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_MAXW (rs2, rs1, rd)
  <-> "MAXW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_MINW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_MINW (rs2, rs1, rd) <->
  0b1111000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_MINW (rs2, rs1, rd)
  <-> "MINW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_MSUBR32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_MSUBR32 (rs2, rs1, rd) <->
  0b1100011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_MSUBR32 (rs2, rs1, rd)
  <-> "MSUBR32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_MULR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_MULR64 (rs2, rs1, rd) <->
  0b1111000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_MULR64 (rs2, rs1, rd)
  <-> "MULR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_MULSR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_MULSR64 (rs2, rs1, rd) <->
  0b1110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_MULSR64 (rs2, rs1, rd)
  <-> "MULSR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PBSAD : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PBSAD (rs2, rs1, rd) <->
  0b1111110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_PBSAD (rs2, rs1, rd)
  <-> "PBSAD" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PBSADA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PBSADA (rs2, rs1, rd) <->
  0b1111111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_PBSADA (rs2, rs1, rd)
  <-> "PBSADA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKBB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKBB16 (rs2, rs1, rd) <->
  0b0000111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKBB16 (rs2, rs1, rd)
  <-> "PKBB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKBT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKBT16 (rs2, rs1, rd) <->
  0b0001111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKBT16 (rs2, rs1, rd)
  <-> "PKBT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKTT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKTT16 (rs2, rs1, rd) <->
  0b0010111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKTT16 (rs2, rs1, rd)
  <-> "PKTT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKTB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKTB16 (rs2, rs1, rd) <->
  0b0011111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKTB16 (rs2, rs1, rd)
  <-> "PKTB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RADD : (regidx, regidx, regidx, word_width)
mapping clause encdec = PEXT_RADD (rs2, rs1, rd, BYTE) <->
  0b0000100 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_RADD (rs2, rs1, rd, HALF) <->
  0b0000000 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_RADD (rs2, rs1, rd, WORD) <->
  0b0000000 @ rs2 @ rs1 @ 0b010 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_RADD (rs2, rs1, rd, DOUBLE) <->
  0b1000000 @ rs2 @ rs1 @ 0b001 @ rd @ PEXT_SIG

mapping clause assembly = PEXT_RADD (rs2, rs1, rd, width)
  <-> "RADD" ^ pext_width_mnemonic(width) ^ spc() ^
      reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)



union clause ast = PEXT_RADDW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RADDW (rs2, rs1, rd) <->
  0b0010000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_RADDW (rs2, rs1, rd)
  <-> "RADDW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RCRAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RCRAS16 (rs2, rs1, rd) <->
  0b0000010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_RCRAS16 (rs2, rs1, rd)
  <-> "RCRAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RCRSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RCRSA16 (rs2, rs1, rd) <->
  0b0000011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_RCRSA16 (rs2, rs1, rd)
  <-> "RCRSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSTAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSTAS16 (rs2, rs1, rd) <->
  0b1011010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSTAS16 (rs2, rs1, rd)
  <-> "RSTAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSTSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSTSA16 (rs2, rs1, rd) <->
  0b1011011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSTSA16 (rs2, rs1, rd)
  <-> "RSTSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSUB8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSUB8 (rs2, rs1, rd) <->
  0b0000101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSUB8 (rs2, rs1, rd)
  <-> "RSUB8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSUB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSUB16 (rs2, rs1, rd) <->
  0b0000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSUB16 (rs2, rs1, rd)
  <-> "RSUB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSUB64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSUB64 (rs2, rs1, rd) <->
  0b1000001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSUB64 (rs2, rs1, rd)
  <-> "RSUB64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSUBW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSUBW (rs2, rs1, rd) <->
  0b0010001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSUBW (rs2, rs1, rd)
  <-> "RSUBW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SCLIP8 : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_SCLIP8 (imm3, rs1, rd) <->
  0b1000110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SCLIP8 (imm3, rs1, rd)
  <-> "SCLIP8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_SCLIP16 : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_SCLIP16 (imm4, rs1, rd) <->
  0b1000010 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SCLIP16 (imm4, rs1, rd)
  <-> "SCLIP16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_SCLIP32 : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_SCLIP32 (imm5, rs1, rd) <->
  0b1110010 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SCLIP32 (imm5, rs1, rd)
  <-> "SCLIP32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_SCMPLE8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SCMPLE8 (rs2, rs1, rd) <->
  0b0001111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SCMPLE8 (rs2, rs1, rd)
  <-> "SCMPLE8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SCMPLE16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SCMPLE16 (rs2, rs1, rd) <->
  0b0001110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SCMPLE16 (rs2, rs1, rd)
  <-> "SCMPLE16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SCMPLT8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SCMPLT8 (rs2, rs1, rd) <->
  0b0000111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SCMPLT8 (rs2, rs1, rd)
  <-> "SCMPLT8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SCMPLT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SCMPLT16 (rs2, rs1, rd) <->
  0b0000110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SCMPLT16 (rs2, rs1, rd)
  <-> "SCMPLT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SLL8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SLL8 (rs2, rs1, rd) <->
  0b0101110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SLL8 (rs2, rs1, rd)
  <-> "SLL8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SLLI8 : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_SLLI8 (imm3, rs1, rd) <->
  0b0111110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SLLI8 (imm3, rs1, rd)
  <-> "SLLI8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_SLL16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SLL16 (rs2, rs1, rd) <->
  0b0101010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SLL16 (rs2, rs1, rd)
  <-> "SLL16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SLLI16 : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_SLLI16 (imm4, rs1, rd) <->
  0b0111010 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SLLI16 (imm4, rs1, rd)
  <-> "SLLI16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_SMAL : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMAL (rs2, rs1, rd) <->
  0b0101111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMAL (rs2, rs1, rd)
  <-> "SMAL" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALBB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALBB (rs2, rs1, rd) <->
  0b1000100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALBB (rs2, rs1, rd)
  <-> "SMALBB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALBT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALBT (rs2, rs1, rd) <->
  0b1001100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALBT (rs2, rs1, rd)
  <-> "SMALBT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALTT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALTT (rs2, rs1, rd) <->
  0b1010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALTT (rs2, rs1, rd)
  <-> "SMALTT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALDA (rs2, rs1, rd) <->
  0b1000110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALDA (rs2, rs1, rd)
  <-> "SMALDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALXDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALXDA (rs2, rs1, rd) <->
  0b1001110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALXDA (rs2, rs1, rd)
  <-> "SMALXDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALDS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALDS (rs2, rs1, rd) <->
  0b1000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALDS (rs2, rs1, rd)
  <-> "SMALDS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALDRS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALDRS (rs2, rs1, rd) <->
  0b1001101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALDRS (rs2, rs1, rd)
  <-> "SMALDRS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMALXDS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMALXDS (rs2, rs1, rd) <->
  0b1010101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMALXDS (rs2, rs1, rd)
  <-> "SMALXDS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMAR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMAR64 (rs2, rs1, rd) <->
  0b1000010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMAR64 (rs2, rs1, rd)
  <-> "SMAR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMAQA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMAQA (rs2, rs1, rd) <->
  0b1100100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMAQA (rs2, rs1, rd)
  <-> "SMAQA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMAQA_SU : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMAQA_SU (rs2, rs1, rd) <->
  0b1100101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMAQA_SU (rs2, rs1, rd)
  <-> "SMAQA_SU" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMAX8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMAX8 (rs2, rs1, rd) <->
  0b1000101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMAX8 (rs2, rs1, rd)
  <-> "SMAX8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMAX16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMAX16 (rs2, rs1, rd) <->
  0b1000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMAX16 (rs2, rs1, rd)
  <-> "SMAX16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMBB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMBB16 (rs2, rs1, rd) <->
  0b0000100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMBB16 (rs2, rs1, rd)
  <-> "SMBB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMBT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMBT16 (rs2, rs1, rd) <->
  0b0001100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMBT16 (rs2, rs1, rd)
  <-> "SMBT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMTT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMTT16 (rs2, rs1, rd) <->
  0b0010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMTT16 (rs2, rs1, rd)
  <-> "SMTT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMDS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMDS (rs2, rs1, rd) <->
  0b0101100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMDS (rs2, rs1, rd)
  <-> "SMDS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMDRS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMDRS (rs2, rs1, rd) <->
  0b0110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMDRS (rs2, rs1, rd)
  <-> "SMDRS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMXDS : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMXDS (rs2, rs1, rd) <->
  0b0111100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMXDS (rs2, rs1, rd)
  <-> "SMXDS" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMIN8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMIN8 (rs2, rs1, rd) <->
  0b1000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMIN8 (rs2, rs1, rd)
  <-> "SMIN8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMIN16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMIN16 (rs2, rs1, rd) <->
  0b1000000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMIN16 (rs2, rs1, rd)
  <-> "SMIN16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMMUL : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMMUL (rs2, rs1, rd) <->
  0b0100000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMMUL (rs2, rs1, rd)
  <-> "SMMUL" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMMUL_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMMUL_U (rs2, rs1, rd) <->
  0b0101000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMMUL_U (rs2, rs1, rd)
  <-> "SMMUL_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMMWB : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMMWB (rs2, rs1, rd) <->
  0b0100010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMMWB (rs2, rs1, rd)
  <-> "SMMWB" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMMWB_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMMWB_U (rs2, rs1, rd) <->
  0b0101010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMMWB_U (rs2, rs1, rd)
  <-> "SMMWB_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMMWT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMMWT (rs2, rs1, rd) <->
  0b0110010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMMWT (rs2, rs1, rd)
  <-> "SMMWT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMMWT_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMMWT_U (rs2, rs1, rd) <->
  0b0111010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMMWT_U (rs2, rs1, rd)
  <-> "SMMWT_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMSLDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMSLDA (rs2, rs1, rd) <->
  0b1010110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMSLDA (rs2, rs1, rd)
  <-> "SMSLDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMSLXDA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMSLXDA (rs2, rs1, rd) <->
  0b1011110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMSLXDA (rs2, rs1, rd)
  <-> "SMSLXDA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMSR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMSR64 (rs2, rs1, rd) <->
  0b1000011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMSR64 (rs2, rs1, rd)
  <-> "SMSR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMUL8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMUL8 (rs2, rs1, rd) <->
  0b1010100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMUL8 (rs2, rs1, rd)
  <-> "SMUL8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMULX8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMULX8 (rs2, rs1, rd) <->
  0b1010101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMULX8 (rs2, rs1, rd)
  <-> "SMULX8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMUL16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMUL16 (rs2, rs1, rd) <->
  0b1010000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMUL16 (rs2, rs1, rd)
  <-> "SMUL16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMULX16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMULX16 (rs2, rs1, rd) <->
  0b1010001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMULX16 (rs2, rs1, rd)
  <-> "SMULX16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRA_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRA_U (rs2, rs1, rd) <->
  0b0010010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRA_U (rs2, rs1, rd)
  <-> "SRA_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRAI_U : (bits(6), regidx, regidx)
mapping clause encdec = PEXT_SRAI_U (imm6, rs1, rd) <->
  0b110101 @ imm6 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAI_U (imm6, rs1, rd)
  <-> "SRAI_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(imm6)


union clause ast = PEXT_SRA8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRA8 (rs2, rs1, rd) <->
  0b0101100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRA8 (rs2, rs1, rd)
  <-> "SRA8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRA8_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRA8_U (rs2, rs1, rd) <->
  0b0110100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRA8_U (rs2, rs1, rd)
  <-> "SRA8_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRAI8 : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_SRAI8 (imm3, rs1, rd) <->
  0b0111100 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAI8 (imm3, rs1, rd)
  <-> "SRAI8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_SRAI8_U : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_SRAI8_U (imm3, rs1, rd) <->
  0b0111100 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAI8_U (imm3, rs1, rd)
  <-> "SRAI8_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_SRA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRA16 (rs2, rs1, rd) <->
  0b0101000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRA16 (rs2, rs1, rd)
  <-> "SRA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRA16_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRA16_U (rs2, rs1, rd) <->
  0b0110000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRA16_U (rs2, rs1, rd)
  <-> "SRA16_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRAI16 : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_SRAI16 (imm4, rs1, rd) <->
  0b0111000 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAI16 (imm4, rs1, rd)
  <-> "SRAI16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_SRAI16_U : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_SRAI16_U (imm4, rs1, rd) <->
  0b0111000 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAI16_U (imm4, rs1, rd)
  <-> "SRAI16_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_SRL8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRL8 (rs2, rs1, rd) <->
  0b0101101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRL8 (rs2, rs1, rd)
  <-> "SRL8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRL8_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRL8_U (rs2, rs1, rd) <->
  0b0110101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRL8_U (rs2, rs1, rd)
  <-> "SRL8_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRLI8 : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_SRLI8 (imm3, rs1, rd) <->
  0b0111101 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRLI8 (imm3, rs1, rd)
  <-> "SRLI8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_SRLI8_U : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_SRLI8_U (imm3, rs1, rd) <->
  0b0111101 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRLI8_U (imm3, rs1, rd)
  <-> "SRLI8_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_SRL16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRL16 (rs2, rs1, rd) <->
  0b0101001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRL16 (rs2, rs1, rd)
  <-> "SRL16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRL16_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRL16_U (rs2, rs1, rd) <->
  0b0110001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRL16_U (rs2, rs1, rd)
  <-> "SRL16_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRLI16 : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_SRLI16 (imm4, rs1, rd) <->
  0b0111001 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRLI16 (imm4, rs1, rd)
  <-> "SRLI16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_SRLI16_U : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_SRLI16_U (imm4, rs1, rd) <->
  0b0111001 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRLI16_U (imm4, rs1, rd)
  <-> "SRLI16_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_STAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_STAS16 (rs2, rs1, rd) <->
  0b1111010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_STAS16 (rs2, rs1, rd)
  <-> "STAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_STSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_STSA16 (rs2, rs1, rd) <->
  0b1111011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_STSA16 (rs2, rs1, rd)
  <-> "STSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SUB8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SUB8 (rs2, rs1, rd) <->
  0b0100101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUB8 (rs2, rs1, rd)
  <-> "SUB8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SUB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SUB16 (rs2, rs1, rd) <->
  0b0100001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUB16 (rs2, rs1, rd)
  <-> "SUB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SUB64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SUB64 (rs2, rs1, rd) <->
  0b1100001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUB64 (rs2, rs1, rd)
  <-> "SUB64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SUNPKD810 : (regidx, regidx)
mapping clause encdec = PEXT_SUNPKD810 (rs1, rd) <->
  0b1010110 @ 0b01000 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUNPKD810 (rs1, rd)
  <-> "SUNPKD810" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_SUNPKD820 : (regidx, regidx)
mapping clause encdec = PEXT_SUNPKD820 (rs1, rd) <->
  0b1010110 @ 0b01001 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUNPKD820 (rs1, rd)
  <-> "SUNPKD820" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_SUNPKD830 : (regidx, regidx)
mapping clause encdec = PEXT_SUNPKD830 (rs1, rd) <->
  0b1010110 @ 0b01010 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUNPKD830 (rs1, rd)
  <-> "SUNPKD830" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_SUNPKD831 : (regidx, regidx)
mapping clause encdec = PEXT_SUNPKD831 (rs1, rd) <->
  0b1010110 @ 0b01011 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUNPKD831 (rs1, rd)
  <-> "SUNPKD831" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_SUNPKD832 : (regidx, regidx)
mapping clause encdec = PEXT_SUNPKD832 (rs1, rd) <->
  0b1010110 @ 0b10011 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUNPKD832 (rs1, rd)
  <-> "SUNPKD832" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_SWAP8 : (regidx, regidx)
mapping clause encdec = PEXT_SWAP8 (rs1, rd) <->
  0b1010110 @ 0b11000 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SWAP8 (rs1, rd)
  <-> "SWAP8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_SWAP16 : (regidx, regidx)
mapping clause encdec = PEXT_SWAP16 (rs1, rd) <->
  0b1010110 @ 0b11001 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_SWAP16 (rs1, rd)
  <-> "SWAP16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_UCLIP8 : (bits(3), regidx, regidx)
mapping clause encdec = PEXT_UCLIP8 (imm3, rs1, rd) <->
  0b1000110 @ 0b10 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UCLIP8 (imm3, rs1, rd)
  <-> "UCLIP8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)


union clause ast = PEXT_UCLIP16 : (bits(4), regidx, regidx)
mapping clause encdec = PEXT_UCLIP16 (imm4, rs1, rd) <->
  0b1000010 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UCLIP16 (imm4, rs1, rd)
  <-> "UCLIP16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)


union clause ast = PEXT_UCLIP32 : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_UCLIP32 (imm5, rs1, rd) <->
  0b1111010 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UCLIP32 (imm5, rs1, rd)
  <-> "UCLIP32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_UCMPLE8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UCMPLE8 (rs2, rs1, rd) <->
  0b0011111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UCMPLE8 (rs2, rs1, rd)
  <-> "UCMPLE8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UCMPLE16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UCMPLE16 (rs2, rs1, rd) <->
  0b0011110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UCMPLE16 (rs2, rs1, rd)
  <-> "UCMPLE16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UCMPLT8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UCMPLT8 (rs2, rs1, rd) <->
  0b0010111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UCMPLT8 (rs2, rs1, rd)
  <-> "UCMPLT8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UCMPLT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UCMPLT16 (rs2, rs1, rd) <->
  0b0010110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UCMPLT16 (rs2, rs1, rd)
  <-> "UCMPLT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKADD : (regidx, regidx, regidx, word_width)
mapping clause encdec = PEXT_UKADD (rs2, rs1, rd, BYTE) <->
  0b0011100 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_UKADD (rs2, rs1, rd, HALF) <->
  0b0011000 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_UKADD (rs2, rs1, rd, WORD) <->
  0b0011000 @ rs2 @ rs1 @ 0b010 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_UKADD (rs2, rs1, rd, DOUBLE) <->
  0b1011000 @ rs2 @ rs1 @ 0b001 @ rd @ PEXT_SIG

mapping clause assembly = PEXT_UKADD (rs2, rs1, rd, width)
  <-> "UKADD" ^ pext_width_mnemonic(width) ^ spc() ^
      reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)



union clause ast = PEXT_UKADDH : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKADDH (rs2, rs1, rd) <->
  0b0001010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKADDH (rs2, rs1, rd)
  <-> "UKADDH" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKADDW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKADDW (rs2, rs1, rd) <->
  0b0001000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKADDW (rs2, rs1, rd)
  <-> "UKADDW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKCRAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKCRAS16 (rs2, rs1, rd) <->
  0b0011010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKCRAS16 (rs2, rs1, rd)
  <-> "UKCRAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKCRSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKCRSA16 (rs2, rs1, rd) <->
  0b0011011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKCRSA16 (rs2, rs1, rd)
  <-> "UKCRSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKMAR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKMAR64 (rs2, rs1, rd) <->
  0b1011010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKMAR64 (rs2, rs1, rd)
  <-> "UKMAR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKMSR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKMSR64 (rs2, rs1, rd) <->
  0b1011011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKMSR64 (rs2, rs1, rd)
  <-> "UKMSR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSTAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSTAS16 (rs2, rs1, rd) <->
  0b1110010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSTAS16 (rs2, rs1, rd)
  <-> "UKSTAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSTSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSTSA16 (rs2, rs1, rd) <->
  0b1110011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSTSA16 (rs2, rs1, rd)
  <-> "UKSTSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSUB8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSUB8 (rs2, rs1, rd) <->
  0b0011101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSUB8 (rs2, rs1, rd)
  <-> "UKSUB8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSUB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSUB16 (rs2, rs1, rd) <->
  0b0011001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSUB16 (rs2, rs1, rd)
  <-> "UKSUB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSUB64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSUB64 (rs2, rs1, rd) <->
  0b1011001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSUB64 (rs2, rs1, rd)
  <-> "UKSUB64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSUBH : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSUBH (rs2, rs1, rd) <->
  0b0001011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSUBH (rs2, rs1, rd)
  <-> "UKSUBH" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSUBW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSUBW (rs2, rs1, rd) <->
  0b0001001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSUBW (rs2, rs1, rd)
  <-> "UKSUBW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMAR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMAR64 (rs2, rs1, rd) <->
  0b1010010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMAR64 (rs2, rs1, rd)
  <-> "UMAR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMAQA : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMAQA (rs2, rs1, rd) <->
  0b1100110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMAQA (rs2, rs1, rd)
  <-> "UMAQA" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMAX8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMAX8 (rs2, rs1, rd) <->
  0b1001101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMAX8 (rs2, rs1, rd)
  <-> "UMAX8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMAX16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMAX16 (rs2, rs1, rd) <->
  0b1001001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMAX16 (rs2, rs1, rd)
  <-> "UMAX16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMIN8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMIN8 (rs2, rs1, rd) <->
  0b1001100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMIN8 (rs2, rs1, rd)
  <-> "UMIN8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMIN16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMIN16 (rs2, rs1, rd) <->
  0b1001000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMIN16 (rs2, rs1, rd)
  <-> "UMIN16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMSR64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMSR64 (rs2, rs1, rd) <->
  0b1010011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMSR64 (rs2, rs1, rd)
  <-> "UMSR64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMUL8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMUL8 (rs2, rs1, rd) <->
  0b1011100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMUL8 (rs2, rs1, rd)
  <-> "UMUL8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMULX8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMULX8 (rs2, rs1, rd) <->
  0b1011101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMULX8 (rs2, rs1, rd)
  <-> "UMULX8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMUL16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMUL16 (rs2, rs1, rd) <->
  0b1011000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMUL16 (rs2, rs1, rd)
  <-> "UMUL16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMULX16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMULX16 (rs2, rs1, rd) <->
  0b1011001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMULX16 (rs2, rs1, rd)
  <-> "UMULX16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URADD : (regidx, regidx, regidx, word_width)
mapping clause encdec = PEXT_URADD (rs2, rs1, rd, BYTE) <->
  0b0010100 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_URADD (rs2, rs1, rd, HALF) <->
  0b0010000 @ rs2 @ rs1 @ 0b000 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_URADD (rs2, rs1, rd, WORD) <->
  0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ PEXT_SIG
mapping clause encdec = PEXT_URADD (rs2, rs1, rd, DOUBLE) <->
  0b1010000 @ rs2 @ rs1 @ 0b001 @ rd @ PEXT_SIG

mapping clause assembly = PEXT_URADD (rs2, rs1, rd, width)
  <-> "URADD" ^ pext_width_mnemonic(width) ^ spc() ^
      reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URADDW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URADDW (rs2, rs1, rd) <->
  0b0011000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_URADDW (rs2, rs1, rd)
  <-> "URADDW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URCRAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URCRAS16 (rs2, rs1, rd) <->
  0b0010010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_URCRAS16 (rs2, rs1, rd)
  <-> "URCRAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URCRSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URCRSA16 (rs2, rs1, rd) <->
  0b0010011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_URCRSA16 (rs2, rs1, rd)
  <-> "URCRSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSTAS16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSTAS16 (rs2, rs1, rd) <->
  0b1101010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSTAS16 (rs2, rs1, rd)
  <-> "URSTAS16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSTSA16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSTSA16 (rs2, rs1, rd) <->
  0b1101011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSTSA16 (rs2, rs1, rd)
  <-> "URSTSA16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSUB8 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSUB8 (rs2, rs1, rd) <->
  0b0010101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSUB8 (rs2, rs1, rd)
  <-> "URSUB8" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSUB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSUB16 (rs2, rs1, rd) <->
  0b0010001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSUB16 (rs2, rs1, rd)
  <-> "URSUB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSUB64 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSUB64 (rs2, rs1, rd) <->
  0b1010001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSUB64 (rs2, rs1, rd)
  <-> "URSUB64" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSUBW : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSUBW (rs2, rs1, rd) <->
  0b0011001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSUBW (rs2, rs1, rd)
  <-> "URSUBW" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_WEXTI : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_WEXTI (imm5, rs1, rd) <->
  0b1101111 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_WEXTI (imm5, rs1, rd)
  <-> "WEXTI" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_WEXT : (regidx, regidx, regidx)
mapping clause encdec = PEXT_WEXT (rs2, rs1, rd) <->
  0b1100111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_WEXT (rs2, rs1, rd)
  <-> "WEXT" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_ZUNPKD810 : (regidx, regidx)
mapping clause encdec = PEXT_ZUNPKD810 (rs1, rd) <->
  0b1010110 @ 0b01100 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_ZUNPKD810 (rs1, rd)
  <-> "ZUNPKD810" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_ZUNPKD820 : (regidx, regidx)
mapping clause encdec = PEXT_ZUNPKD820 (rs1, rd) <->
  0b1010110 @ 0b01101 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_ZUNPKD820 (rs1, rd)
  <-> "ZUNPKD820" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_ZUNPKD830 : (regidx, regidx)
mapping clause encdec = PEXT_ZUNPKD830 (rs1, rd) <->
  0b1010110 @ 0b01110 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_ZUNPKD830 (rs1, rd)
  <-> "ZUNPKD830" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_ZUNPKD831 : (regidx, regidx)
mapping clause encdec = PEXT_ZUNPKD831 (rs1, rd) <->
  0b1010110 @ 0b01111 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_ZUNPKD831 (rs1, rd)
  <-> "ZUNPKD831" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_ZUNPKD832 : (regidx, regidx)
mapping clause encdec = PEXT_ZUNPKD832 (rs1, rd) <->
  0b1010110 @ 0b10111 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_ZUNPKD832 (rs1, rd)
  <-> "ZUNPKD832" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)



union clause ast = PEXT_CRAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_CRAS32 (rs2, rs1, rd) <->
  0b0100010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_CRAS32 (rs2, rs1, rd)
  <-> "CRAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_CRSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_CRSA32 (rs2, rs1, rd) <->
  0b0100011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_CRSA32 (rs2, rs1, rd)
  <-> "CRSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KABS32 : (regidx, regidx)
mapping clause encdec = PEXT_KABS32 (rs1, rd) <->
  0b1010110 @ 0b10010 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = PEXT_KABS32 (rs1, rd)
  <-> "KABS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)


union clause ast = PEXT_KCRAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KCRAS32 (rs2, rs1, rd) <->
  0b0001010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KCRAS32 (rs2, rs1, rd)
  <-> "KCRAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KCRSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KCRSA32 (rs2, rs1, rd) <->
  0b0001011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KCRSA32 (rs2, rs1, rd)
  <-> "KCRSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMBB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMBB16 (rs2, rs1, rd) <->
  0b1101101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMBB16 (rs2, rs1, rd)
  <-> "KDMBB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMBT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMBT16 (rs2, rs1, rd) <->
  0b1110101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMBT16 (rs2, rs1, rd)
  <-> "KDMBT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMTT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMTT16 (rs2, rs1, rd) <->
  0b1111101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMTT16 (rs2, rs1, rd)
  <-> "KDMTT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMABB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMABB16 (rs2, rs1, rd) <->
  0b1101100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMABB16 (rs2, rs1, rd)
  <-> "KDMABB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMABT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMABT16 (rs2, rs1, rd) <->
  0b1110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMABT16 (rs2, rs1, rd)
  <-> "KDMABT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KDMATT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KDMATT16 (rs2, rs1, rd) <->
  0b1111100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KDMATT16 (rs2, rs1, rd)
  <-> "KDMATT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMBB16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMBB16 (rs2, rs1, rd) <->
  0b1101110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMBB16 (rs2, rs1, rd)
  <-> "KHMBB16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMBT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMBT16 (rs2, rs1, rd) <->
  0b1110110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMBT16 (rs2, rs1, rd)
  <-> "KHMBT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KHMTT16 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KHMTT16 (rs2, rs1, rd) <->
  0b1111110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_KHMTT16 (rs2, rs1, rd)
  <-> "KHMTT16" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMABB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMABB32 (rs2, rs1, rd) <->
  0b0101101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMABB32 (rs2, rs1, rd)
  <-> "KMABB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMABT32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMABT32 (rs2, rs1, rd) <->
  0b0110101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMABT32 (rs2, rs1, rd)
  <-> "KMABT32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMATT32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMATT32 (rs2, rs1, rd) <->
  0b0111101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMATT32 (rs2, rs1, rd)
  <-> "KMATT32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMAXDA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMAXDA32 (rs2, rs1, rd) <->
  0b0100101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMAXDA32 (rs2, rs1, rd)
  <-> "KMAXDA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMDA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMDA32 (rs2, rs1, rd) <->
  0b0011100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMDA32 (rs2, rs1, rd)
  <-> "KMDA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMXDA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMXDA32 (rs2, rs1, rd) <->
  0b0011101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMXDA32 (rs2, rs1, rd)
  <-> "KMXDA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMADS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMADS32 (rs2, rs1, rd) <->
  0b0101110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMADS32 (rs2, rs1, rd)
  <-> "KMADS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMADRS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMADRS32 (rs2, rs1, rd) <->
  0b0110110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMADRS32 (rs2, rs1, rd)
  <-> "KMADRS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMAXDS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMAXDS32 (rs2, rs1, rd) <->
  0b0111110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMAXDS32 (rs2, rs1, rd)
  <-> "KMAXDS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMSDA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMSDA32 (rs2, rs1, rd) <->
  0b0100110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMSDA32 (rs2, rs1, rd)
  <-> "KMSDA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KMSXDA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KMSXDA32 (rs2, rs1, rd) <->
  0b0100111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KMSXDA32 (rs2, rs1, rd)
  <-> "KMSXDA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLL32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLL32 (rs2, rs1, rd) <->
  0b0110010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLL32 (rs2, rs1, rd)
  <-> "KSLL32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLLI32 : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_KSLLI32 (imm5, rs1, rd) <->
  0b1000010 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLLI32 (imm5, rs1, rd)
  <-> "KSLLI32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_KSLRA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRA32 (rs2, rs1, rd) <->
  0b0101011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRA32 (rs2, rs1, rd)
  <-> "KSLRA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSLRA32_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSLRA32_U (rs2, rs1, rd) <->
  0b0110011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSLRA32_U (rs2, rs1, rd)
  <-> "KSLRA32_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSTAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSTAS32 (rs2, rs1, rd) <->
  0b1100000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSTAS32 (rs2, rs1, rd)
  <-> "KSTAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSTSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSTSA32 (rs2, rs1, rd) <->
  0b1100001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSTSA32 (rs2, rs1, rd)
  <-> "KSTSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_KSUB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_KSUB32 (rs2, rs1, rd) <->
  0b0001001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_KSUB32 (rs2, rs1, rd)
  <-> "KSUB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKBB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKBB32 (rs2, rs1, rd) <->
  0b0000111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKBB32 (rs2, rs1, rd)
  <-> "PKBB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKBT32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKBT32 (rs2, rs1, rd) <->
  0b0001111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKBT32 (rs2, rs1, rd)
  <-> "PKBT32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKTT32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKTT32 (rs2, rs1, rd) <->
  0b0010111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKTT32 (rs2, rs1, rd)
  <-> "PKTT32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_PKTB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_PKTB32 (rs2, rs1, rd) <->
  0b0011111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_PKTB32 (rs2, rs1, rd)
  <-> "PKTB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RCRAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RCRAS32 (rs2, rs1, rd) <->
  0b0000010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_RCRAS32 (rs2, rs1, rd)
  <-> "RCRAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RCRSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RCRSA32 (rs2, rs1, rd) <->
  0b0000011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_RCRSA32 (rs2, rs1, rd)
  <-> "RCRSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSTAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSTAS32 (rs2, rs1, rd) <->
  0b1011000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSTAS32 (rs2, rs1, rd)
  <-> "RSTAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSTSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSTSA32 (rs2, rs1, rd) <->
  0b1011001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSTSA32 (rs2, rs1, rd)
  <-> "RSTSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_RSUB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_RSUB32 (rs2, rs1, rd) <->
  0b0000001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_RSUB32 (rs2, rs1, rd)
  <-> "RSUB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SLL32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SLL32 (rs2, rs1, rd) <->
  0b0101010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SLL32 (rs2, rs1, rd)
  <-> "SLL32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SLLI32 : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_SLLI32 (imm5, rs1, rd) <->
  0b0111010 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SLLI32 (imm5, rs1, rd)
  <-> "SLLI32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_SMAX32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMAX32 (rs2, rs1, rd) <->
  0b1001001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMAX32 (rs2, rs1, rd)
  <-> "SMAX32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMBT32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMBT32 (rs2, rs1, rd) <->
  0b0001100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMBT32 (rs2, rs1, rd)
  <-> "SMBT32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMTT32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMTT32 (rs2, rs1, rd) <->
  0b0010100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMTT32 (rs2, rs1, rd)
  <-> "SMTT32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMDS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMDS32 (rs2, rs1, rd) <->
  0b0101100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMDS32 (rs2, rs1, rd)
  <-> "SMDS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMDRS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMDRS32 (rs2, rs1, rd) <->
  0b0110100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMDRS32 (rs2, rs1, rd)
  <-> "SMDRS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMXDS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMXDS32 (rs2, rs1, rd) <->
  0b0111100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMXDS32 (rs2, rs1, rd)
  <-> "SMXDS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SMIN32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SMIN32 (rs2, rs1, rd) <->
  0b1001000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SMIN32 (rs2, rs1, rd)
  <-> "SMIN32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRA32 (rs2, rs1, rd) <->
  0b0101000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRA32 (rs2, rs1, rd)
  <-> "SRA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRA32_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRA32_U (rs2, rs1, rd) <->
  0b0110000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRA32_U (rs2, rs1, rd)
  <-> "SRA32_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRAI32 : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_SRAI32 (imm5, rs1, rd) <->
  0b0111000 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAI32 (imm5, rs1, rd)
  <-> "SRAI32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_SRAI32_U : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_SRAI32_U (imm5, rs1, rd) <->
  0b1000000 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAI32_U (imm5, rs1, rd)
  <-> "SRAI32_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_SRAIW_U : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_SRAIW_U (imm5, rs1, rd) <->
  0b0011010 @ imm5 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRAIW_U (imm5, rs1, rd)
  <-> "SRAIW_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_SRL32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRL32 (rs2, rs1, rd) <->
  0b0101001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRL32 (rs2, rs1, rd)
  <-> "SRL32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRL32_U : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SRL32_U (rs2, rs1, rd) <->
  0b0110001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRL32_U (rs2, rs1, rd)
  <-> "SRL32_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SRLI32 : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_SRLI32 (imm5, rs1, rd) <->
  0b0111001 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRLI32 (imm5, rs1, rd)
  <-> "SRLI32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_SRLI32_U : (bits(5), regidx, regidx)
mapping clause encdec = PEXT_SRLI32_U (imm5, rs1, rd) <->
  0b1000001 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SRLI32_U (imm5, rs1, rd)
  <-> "SRLI32_U" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)


union clause ast = PEXT_STAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_STAS32 (rs2, rs1, rd) <->
  0b1111000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_STAS32 (rs2, rs1, rd)
  <-> "STAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_STSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_STSA32 (rs2, rs1, rd) <->
  0b1111001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_STSA32 (rs2, rs1, rd)
  <-> "STSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_SUB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_SUB32 (rs2, rs1, rd) <->
  0b0100001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_SUB32 (rs2, rs1, rd)
  <-> "SUB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKCRAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKCRAS32 (rs2, rs1, rd) <->
  0b0011010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKCRAS32 (rs2, rs1, rd)
  <-> "UKCRAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKCRSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKCRSA32 (rs2, rs1, rd) <->
  0b0011011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKCRSA32 (rs2, rs1, rd)
  <-> "UKCRSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSTAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSTAS32 (rs2, rs1, rd) <->
  0b1110000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSTAS32 (rs2, rs1, rd)
  <-> "UKSTAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSTSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSTSA32 (rs2, rs1, rd) <->
  0b1110001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSTSA32 (rs2, rs1, rd)
  <-> "UKSTSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UKSUB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UKSUB32 (rs2, rs1, rd) <->
  0b0011001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UKSUB32 (rs2, rs1, rd)
  <-> "UKSUB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMAX32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMAX32 (rs2, rs1, rd) <->
  0b1010001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMAX32 (rs2, rs1, rd)
  <-> "UMAX32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_UMIN32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_UMIN32 (rs2, rs1, rd) <->
  0b1010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_UMIN32 (rs2, rs1, rd)
  <-> "UMIN32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URCRAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URCRAS32 (rs2, rs1, rd) <->
  0b0010010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_URCRAS32 (rs2, rs1, rd)
  <-> "URCRAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URCRSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URCRSA32 (rs2, rs1, rd) <->
  0b0010011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_URCRSA32 (rs2, rs1, rd)
  <-> "URCRSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSTAS32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSTAS32 (rs2, rs1, rd) <->
  0b1101000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSTAS32 (rs2, rs1, rd)
  <-> "URSTAS32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSTSA32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSTSA32 (rs2, rs1, rd) <->
  0b1101001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSTSA32 (rs2, rs1, rd)
  <-> "URSTSA32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)


union clause ast = PEXT_URSUB32 : (regidx, regidx, regidx)
mapping clause encdec = PEXT_URSUB32 (rs2, rs1, rd) <->
  0b0010001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = PEXT_URSUB32 (rs2, rs1, rd)
  <-> "URSUB32" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)