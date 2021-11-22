/* Programming Langauge Lab, Department of Computer Science, National Tsing-Hua University, Taiwan */
/* Academia Sinica, Taiwan*/
/* Andes Technology Corporation, Taiwan*/

/* riscv_insts_pext_define.sail */

mapping p_inst_rs2_rs1_rd_mapping : p_inst_rs2_rs1_rd_op <-> string = {
  ADD8 <-> "ADD8",
  ADD16 <-> "ADD16",
  ADD64 <-> "ADD64",
  AVE <-> "AVE",
  BITREV <-> "BITREV",
  CMPEQ8 <-> "CMPEQ8",
  CMPEQ16 <-> "CMPEQ16",
  CRAS16 <-> "CRAS16",
  CRSA16 <-> "CRSA16",
  KADD8 <-> "KADD8",
  KADD16 <-> "KADD16",
  KADD64 <-> "KADD64",
  KADDH <-> "KADDH",
  KADDW <-> "KADDW",
  KCRAS16 <-> "KCRAS16",
  KCRSA16 <-> "KCRSA16",
  KDMBB <-> "KDMBB",
  KDMBT <-> "KDMBT",
  KDMTT <-> "KDMTT",
  KDMABB <-> "KDMABB",
  KDMABT <-> "KDMABT",
  KDMATT <-> "KDMATT",
  KHM8 <-> "KHM8",
  KHMX8 <-> "KHMX8",
  KHM16 <-> "KHM16",
  KHMX16 <-> "KHMX16",
  KHMBB <-> "KHMBB",
  KHMBT <-> "KHMBT",
  KHMTT <-> "KHMTT",
  KMABB <-> "KMABB",
  KMABT <-> "KMABT",
  KMATT <-> "KMATT",
  KMADA <-> "KMADA",
  KMAXDA <-> "KMAXDA",
  KMADS <-> "KMADS",
  KMADRS <-> "KMADRS",
  KMAXDS <-> "KMAXDS",
  KMAR64 <-> "KMAR64",
  KMDA <-> "KMDA",
  KMXDA <-> "KMXDA",
  KMMAC <-> "KMMAC",
  KMMAC_U <-> "KMMAC_U",
  KMMAWB <-> "KMMAWB",
  KMMAWB_U <-> "KMMAWB_U",
  KMMAWB2 <-> "KMMAWB2",
  KMMAWB2_U <-> "KMMAWB2_U",
  KMMAWT <-> "KMMAWT",
  KMMAWT_U <-> "KMMAWT_U",
  KMMAWT2 <-> "KMMAWT2",
  KMMAWT2_U <-> "KMMAWT2_U",
  KMMSB <-> "KMMSB",
  KMMSB_U <-> "KMMSB_U",
  KMMWB2 <-> "KMMWB2",
  KMMWB2_U <-> "KMMWB2_U",
  KMMWT2 <-> "KMMWT2",
  KMMWT2_U <-> "KMMWT2_U",
  KMSDA <-> "KMSDA",
  KMSXDA <-> "KMSXDA",
  KMSR64 <-> "KMSR64",
  KSLLW <-> "KSLLW",
  KSLL8 <-> "KSLL8",
  KSLL16 <-> "KSLL16",
  KSLRA8 <-> "KSLRA8",
  KSLRA8_U <-> "KSLRA8_U",
  KSLRA16 <-> "KSLRA16",
  KSLRA16_U <-> "KSLRA16_U",
  KSLRAW <-> "KSLRAW",
  KSLRAW_U <-> "KSLRAW_U",
  KSTAS16 <-> "KSTAS16",
  KSTSA16 <-> "KSTSA16",
  KSUB8 <-> "KSUB8",
  KSUB16 <-> "KSUB16",
  KSUB64 <-> "KSUB64",
  KSUBH <-> "KSUBH",
  KSUBW <-> "KSUBW",
  KWMMUL <-> "KWMMUL",
  KWMMUL_U <-> "KWMMUL_U",
  MADDR32 <-> "MADDR32",
  MAXW <-> "MAXW",
  MINW <-> "MINW",
  MSUBR32 <-> "MSUBR32",
  MULR64 <-> "MULR64",
  MULSR64 <-> "MULSR64",
  PBSAD <-> "PBSAD",
  PBSADA <-> "PBSADA",
  PKBB16 <-> "PKBB16",
  PKBT16 <-> "PKBT16",
  PKTT16 <-> "PKTT16",
  PKTB16 <-> "PKTB16",
  PKBB32 <-> "PKBB32",
  PKBT32 <-> "PKBT32",
  PKTT32 <-> "PKTT32",
  PKTB32 <-> "PKTB32",
  RADD8 <-> "RADD8",
  RADD16 <-> "RADD16",
  RADD64 <-> "RADD64",
  RADDW <-> "RADDW",
  RCRAS16 <-> "RCRAS16",
  RCRSA16 <-> "RCRSA16",
  RSTAS16 <-> "RSTAS16",
  RSTSA16 <-> "RSTSA16",
  RSUB8 <-> "RSUB8",
  RSUB16 <-> "RSUB16",
  RSUB64 <-> "RSUB64",
  RSUBW <-> "RSUBW",
  SCMPLE8 <-> "SCMPLE8",
  SCMPLE16 <-> "SCMPLE16",
  SCMPLT8 <-> "SCMPLT8",
  SCMPLT16 <-> "SCMPLT16",
  SLL8 <-> "SLL8",
  SLL16 <-> "SLL16",
  SMAL <-> "SMAL",
  SMALBB <-> "SMALBB",
  SMALBT <-> "SMALBT",
  SMALTT <-> "SMALTT",
  SMALDA <-> "SMALDA",
  SMALXDA <-> "SMALXDA",
  SMALDS <-> "SMALDS",
  SMALDRS <-> "SMALDRS",
  SMALXDS <-> "SMALXDS",
  SMAR64 <-> "SMAR64",
  SMAQA <-> "SMAQA",
  SMAQA_SU <-> "SMAQA_SU",
  SMAX8 <-> "SMAX8",
  SMAX16 <-> "SMAX16",
  SMBB16 <-> "SMBB16",
  SMBT16 <-> "SMBT16",
  SMTT16 <-> "SMTT16",
  SMDS <-> "SMDS",
  SMDRS <-> "SMDRS",
  SMXDS <-> "SMXDS",
  SMIN8 <-> "SMIN8",
  SMIN16 <-> "SMIN16",
  SMMUL <-> "SMMUL",
  SMMUL_U <-> "SMMUL_U",
  SMMWB <-> "SMMWB",
  SMMWB_U <-> "SMMWB_U",
  SMMWT <-> "SMMWT",
  SMMWT_U <-> "SMMWT_U",
  SMSLDA <-> "SMSLDA",
  SMSLXDA <-> "SMSLXDA",
  SMSR64 <-> "SMSR64",
  SMUL8 <-> "SMUL8",
  SMULX8 <-> "SMULX8",
  SMUL16 <-> "SMUL16",
  SMULX16 <-> "SMULX16",
  SRA_U <-> "SRA_U",
  SRA8 <-> "SRA8",
  SRA8_U <-> "SRA8_U",
  SRA16 <-> "SRA16",
  SRA16_U <-> "SRA16_U",
  SRL8 <-> "SRL8",
  SRL8_U <-> "SRL8_U",
  SRL16 <-> "SRL16",
  SRL16_U <-> "SRL16_U",
  STAS16 <-> "STAS16",
  STSA16 <-> "STSA16",
  SUB8 <-> "SUB8",
  SUB16 <-> "SUB16",
  SUB64 <-> "SUB64",
  UCMPLE8 <-> "UCMPLE8",
  UCMPLE16 <-> "UCMPLE16",
  UCMPLT8 <-> "UCMPLT8",
  UCMPLT16 <-> "UCMPLT16",
  UKADD8 <-> "UKADD8",
  UKADD16 <-> "UKADD16",
  UKADD64 <-> "UKADD64",
  UKADDH <-> "UKADDH",
  UKADDW <-> "UKADDW",
  UKCRAS16 <-> "UKCRAS16",
  UKCRSA16 <-> "UKCRSA16",
  UKMAR64 <-> "UKMAR64",
  UKMSR64 <-> "UKMSR64",
  UKSTAS16 <-> "UKSTAS16",
  UKSTSA16 <-> "UKSTSA16",
  UKSUB8 <-> "UKSUB8",
  UKSUB16 <-> "UKSUB16",
  UKSUB64 <-> "UKSUB64",
  UKSUBH <-> "UKSUBH",
  UKSUBW <-> "UKSUBW",
  UMAR64 <-> "UMAR64",
  UMAQA <-> "UMAQA",
  UMAX8 <-> "UMAX8",
  UMAX16 <-> "UMAX16",
  UMIN8 <-> "UMIN8",
  UMIN16 <-> "UMIN16",
  UMSR64 <-> "UMSR64",
  UMUL8 <-> "UMUL8",
  UMULX8 <-> "UMULX8",
  UMUL16 <-> "UMUL16",
  UMULX16 <-> "UMULX16",
  URADD8 <-> "URADD8",
  URADD16 <-> "URADD16",
  URADD64 <-> "URADD64",
  URADDW <-> "URADDW",
  URCRAS16 <-> "URCRAS16",
  URCRSA16 <-> "URCRSA16",
  URSTAS16 <-> "URSTAS16",
  URSTSA16 <-> "URSTSA16",
  URSUB8 <-> "URSUB8",
  URSUB16 <-> "URSUB16",
  URSUB64 <-> "URSUB64",
  URSUBW <-> "URSUBW",
  WEXT <-> "WEXT",
  ADD32 <-> "ADD32",
  CRAS32 <-> "CRAS32",
  CRSA32 <-> "CRSA32",
  KADD32 <-> "KADD32",
  KCRAS32 <-> "KCRAS32",
  KCRSA32 <-> "KCRSA32",
  KDMBB16 <-> "KDMBB16",
  KDMBT16 <-> "KDMBT16",
  KDMTT16 <-> "KDMTT16",
  KDMABB16 <-> "KDMABB16",
  KDMABT16 <-> "KDMABT16",
  KDMATT16 <-> "KDMATT16",
  KHMBB16 <-> "KHMBB16",
  KHMBT16 <-> "KHMBT16",
  KHMTT16 <-> "KHMTT16",
  KMABB32 <-> "KMABB32",
  KMABT32 <-> "KMABT32",
  KMATT32 <-> "KMATT32",
  KMAXDA32 <-> "KMAXDA32",
  KMDA32 <-> "KMDA32",
  KMXDA32 <-> "KMXDA32",
  KMADS32 <-> "KMADS32",
  KMADRS32 <-> "KMADRS32",
  KMAXDS32 <-> "KMAXDS32",
  KMSDA32 <-> "KMSDA32",
  KMSXDA32 <-> "KMSXDA32",
  KSLL32 <-> "KSLL32",
  KSLRA32 <-> "KSLRA32",
  KSLRA32_U <-> "KSLRA32_U",
  KSTAS32 <-> "KSTAS32",
  KSTSA32 <-> "KSTSA32",
  KSUB32 <-> "KSUB32",
  RADD32 <-> "RADD32",
  RCRAS32 <-> "RCRAS32",
  RCRSA32 <-> "RCRSA32",
  RSTAS32 <-> "RSTAS32",
  RSTSA32 <-> "RSTSA32",
  RSUB32 <-> "RSUB32",
  SLL32 <-> "SLL32",
  SMAX32 <-> "SMAX32",
  SMBT32 <-> "SMBT32",
  SMTT32 <-> "SMTT32",
  SMDS32 <-> "SMDS32",
  SMDRS32 <-> "SMDRS32",
  SMXDS32 <-> "SMXDS32",
  SMIN32 <-> "SMIN32",
  SRA32 <-> "SRA32",
  SRA32_U <-> "SRA32_U",
  SRL32 <-> "SRL32",
  SRL32_U <-> "SRL32_U",
  STAS32 <-> "STAS32",
  STSA32 <-> "STSA32",
  SUB32 <-> "SUB32",
  UKADD32 <-> "UKADD32",
  UKCRAS32 <-> "UKCRAS32",
  UKCRSA32 <-> "UKCRSA32",
  UKSTAS32 <-> "UKSTAS32",
  UKSTSA32 <-> "UKSTSA32",
  UKSUB32 <-> "UKSUB32",
  UMAX32 <-> "UMAX32",
  UMIN32 <-> "UMIN32",
  URADD32 <-> "URADD32",
  URCRAS32 <-> "URCRAS32",
  URCRSA32 <-> "URCRSA32",
  URSTAS32 <-> "URSTAS32",
  URSTSA32 <-> "URSTSA32",
  URSUB32 <-> "URSUB32"
}

union clause ast = P_INST_RS2_RS1_RD : (regidx, regidx, regidx, p_inst_rs2_rs1_rd_op)
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, ADD8) <->
  0b0100100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, ADD16) <->
  0b0100000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, ADD64) <->
  0b1100000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, AVE) <->
  0b1110000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, BITREV) <->
  0b1110011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, CMPEQ8) <->
  0b0100111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, CMPEQ16) <->
  0b0100110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, CRAS16) <->
  0b0100010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, CRSA16) <->
  0b0100011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KADD8) <->
  0b0001100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KADD16) <->
  0b0001000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KADD64) <->
  0b1001000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KADDH) <->
  0b0000010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KADDW) <->
  0b0000000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KCRAS16) <->
  0b0001010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KCRSA16) <->
  0b0001011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMBB) <->
  0b0000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMBT) <->
  0b0001101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMTT) <->
  0b0010101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMABB) <->
  0b1101001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMABT) <->
  0b1110001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMATT) <->
  0b1111001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHM8) <->
  0b1000111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMX8) <->
  0b1001111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHM16) <->
  0b1000011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMX16) <->
  0b1001011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMBB) <->
  0b0000110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMBT) <->
  0b0001110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMTT) <->
  0b0010110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMABB) <->
  0b0101101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMABT) <->
  0b0110101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMATT) <->
  0b0111101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMADA) <->
  0b0100100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMAXDA) <->
  0b0100101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMADS) <->
  0b0101110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMADRS) <->
  0b0110110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMAXDS) <->
  0b0111110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMAR64) <->
  0b1001010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMDA) <->
  0b0011100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMXDA) <->
  0b0011101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAC) <->
  0b0110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAC_U) <->
  0b0111000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWB) <->
  0b0100011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWB_U) <->
  0b0101011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWB2) <->
  0b1100111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWB2_U) <->
  0b1101111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWT) <->
  0b0110011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWT_U) <->
  0b0111011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWT2) <->
  0b1110111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMAWT2_U) <->
  0b1111111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMSB) <->
  0b0100001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMSB_U) <->
  0b0101001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMWB2) <->
  0b1000111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMWB2_U) <->
  0b1001111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMWT2) <->
  0b1010111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMMWT2_U) <->
  0b1011111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMSDA) <->
  0b0100110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMSXDA) <->
  0b0100111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMSR64) <->
  0b1001011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLLW) <->
  0b0010011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLL8) <->
  0b0110110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLL16) <->
  0b0110010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRA8) <->
  0b0101111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRA8_U) <->
  0b0110111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRA16) <->
  0b0101011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRA16_U) <->
  0b0110011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRAW) <->
  0b0110111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRAW_U) <->
  0b0111111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSTAS16) <->
  0b1100010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSTSA16) <->
  0b1100011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSUB8) <->
  0b0001101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSUB16) <->
  0b0001001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSUB64) <->
  0b1001001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSUBH) <->
  0b0000011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSUBW) <->
  0b0000001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KWMMUL) <->
  0b0110001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KWMMUL_U) <->
  0b0111001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, MADDR32) <->
  0b1100010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, MAXW) <->
  0b1111001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, MINW) <->
  0b1111000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, MSUBR32) <->
  0b1100011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, MULR64) <->
  0b1111000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, MULSR64) <->
  0b1110000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PBSAD) <->
  0b1111110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PBSADA) <->
  0b1111111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKBB16) <->
  0b0000111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKBT16) <->
  0b0001111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKTT16) <->
  0b0010111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKTB16) <->
  0b0011111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKBB32) <->
  0b0000111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKBT32) <->
  0b0001111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKTT32) <->
  0b0010111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, PKTB32) <->
  0b0011111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RADD8) <->
  0b0000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RADD16) <->
  0b0000000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RADD64) <->
  0b1000000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RADDW) <->
  0b0010000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RCRAS16) <->
  0b0000010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RCRSA16) <->
  0b0000011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSTAS16) <->
  0b1011010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSTSA16) <->
  0b1011011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSUB8) <->
  0b0000101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSUB16) <->
  0b0000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSUB64) <->
  0b1000001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSUBW) <->
  0b0010001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SCMPLE8) <->
  0b0001111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SCMPLE16) <->
  0b0001110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SCMPLT8) <->
  0b0000111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SCMPLT16) <->
  0b0000110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SLL8) <->
  0b0101110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SLL16) <->
  0b0101010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMAL) <->
  0b0101111 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALBB) <->
  0b1000100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALBT) <->
  0b1001100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALTT) <->
  0b1010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALDA) <->
  0b1000110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALXDA) <->
  0b1001110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALDS) <->
  0b1000101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALDRS) <->
  0b1001101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMALXDS) <->
  0b1010101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMAR64) <->
  0b1000010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMAQA) <->
  0b1100100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMAQA_SU) <->
  0b1100101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMAX8) <->
  0b1000101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMAX16) <->
  0b1000001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMBB16) <->
  0b0000100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMBT16) <->
  0b0001100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMTT16) <->
  0b0010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMDS) <->
  0b0101100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMDRS) <->
  0b0110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMXDS) <->
  0b0111100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMIN8) <->
  0b1000100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMIN16) <->
  0b1000000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMMUL) <->
  0b0100000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMMUL_U) <->
  0b0101000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMMWB) <->
  0b0100010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMMWB_U) <->
  0b0101010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMMWT) <->
  0b0110010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMMWT_U) <->
  0b0111010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMSLDA) <->
  0b1010110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMSLXDA) <->
  0b1011110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMSR64) <->
  0b1000011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMUL8) <->
  0b1010100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMULX8) <->
  0b1010101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMUL16) <->
  0b1010000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMULX16) <->
  0b1010001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRA_U) <->
  0b0010010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRA8) <->
  0b0101100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRA8_U) <->
  0b0110100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRA16) <->
  0b0101000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRA16_U) <->
  0b0110000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRL8) <->
  0b0101101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRL8_U) <->
  0b0110101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRL16) <->
  0b0101001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRL16_U) <->
  0b0110001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, STAS16) <->
  0b1111010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, STSA16) <->
  0b1111011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SUB8) <->
  0b0100101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SUB16) <->
  0b0100001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SUB64) <->
  0b1100001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UCMPLE8) <->
  0b0011111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UCMPLE16) <->
  0b0011110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UCMPLT8) <->
  0b0010111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UCMPLT16) <->
  0b0010110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKADD8) <->
  0b0011100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKADD16) <->
  0b0011000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKADD64) <->
  0b1011000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKADDH) <->
  0b0001010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKADDW) <->
  0b0001000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKCRAS16) <->
  0b0011010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKCRSA16) <->
  0b0011011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKMAR64) <->
  0b1011010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKMSR64) <->
  0b1011011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSTAS16) <->
  0b1110010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSTSA16) <->
  0b1110011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSUB8) <->
  0b0011101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSUB16) <->
  0b0011001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSUB64) <->
  0b1011001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSUBH) <->
  0b0001011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSUBW) <->
  0b0001001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMAR64) <->
  0b1010010 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMAQA) <->
  0b1100110 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMAX8) <->
  0b1001101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMAX16) <->
  0b1001001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMIN8) <->
  0b1001100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMIN16) <->
  0b1001000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMSR64) <->
  0b1010011 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMUL8) <->
  0b1011100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMULX8) <->
  0b1011101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMUL16) <->
  0b1011000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMULX16) <->
  0b1011001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URADD8) <->
  0b0010100 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URADD16) <->
  0b0010000 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URADD64) <->
  0b1010000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URADDW) <->
  0b0011000 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URCRAS16) <->
  0b0010010 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URCRSA16) <->
  0b0010011 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSTAS16) <->
  0b1101010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSTSA16) <->
  0b1101011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSUB8) <->
  0b0010101 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSUB16) <->
  0b0010001 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSUB64) <->
  0b1010001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSUBW) <->
  0b0011001 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, WEXT) <->
  0b1100111 @ rs2 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, ADD32) <->
  0b0100000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, CRAS32) <->
  0b0100010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, CRSA32) <->
  0b0100011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KADD32) <->
  0b0001000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KCRAS32) <->
  0b0001010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KCRSA32) <->
  0b0001011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMBB16) <->
  0b1101101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMBT16) <->
  0b1110101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMTT16) <->
  0b1111101 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMABB16) <->
  0b1101100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMABT16) <->
  0b1110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KDMATT16) <->
  0b1111100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMBB16) <->
  0b1101110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMBT16) <->
  0b1110110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KHMTT16) <->
  0b1111110 @ rs2 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMABB32) <->
  0b0101101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMABT32) <->
  0b0110101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMATT32) <->
  0b0111101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMAXDA32) <->
  0b0100101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMDA32) <->
  0b0011100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMXDA32) <->
  0b0011101 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMADS32) <->
  0b0101110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMADRS32) <->
  0b0110110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMAXDS32) <->
  0b0111110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMSDA32) <->
  0b0100110 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KMSXDA32) <->
  0b0100111 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLL32) <->
  0b0110010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRA32) <->
  0b0101011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSLRA32_U) <->
  0b0110011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSTAS32) <->
  0b1100000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSTSA32) <->
  0b1100001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, KSUB32) <->
  0b0001001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RADD32) <->
  0b0000000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RCRAS32) <->
  0b0000010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RCRSA32) <->
  0b0000011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSTAS32) <->
  0b1011000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSTSA32) <->
  0b1011001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, RSUB32) <->
  0b0000001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SLL32) <->
  0b0101010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMAX32) <->
  0b1001001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMBT32) <->
  0b0001100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMTT32) <->
  0b0010100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMDS32) <->
  0b0101100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMDRS32) <->
  0b0110100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMXDS32) <->
  0b0111100 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SMIN32) <->
  0b1001000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRA32) <->
  0b0101000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRA32_U) <->
  0b0110000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRL32) <->
  0b0101001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SRL32_U) <->
  0b0110001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, STAS32) <->
  0b1111000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, STSA32) <->
  0b1111001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, SUB32) <->
  0b0100001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKADD32) <->
  0b0011000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKCRAS32) <->
  0b0011010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKCRSA32) <->
  0b0011011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSTAS32) <->
  0b1110000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSTSA32) <->
  0b1110001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UKSUB32) <->
  0b0011001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMAX32) <->
  0b1010001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, UMIN32) <->
  0b1010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URADD32) <->
  0b0010000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URCRAS32) <->
  0b0010010 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URCRSA32) <->
  0b0010011 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSTAS32) <->
  0b1101000 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSTSA32) <->
  0b1101001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS2_RS1_RD(rs2, rs1, rd, URSUB32) <->
  0b0010001 @ rs2 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = P_INST_RS2_RS1_RD(rs2, rs1, rd, p_inst)
  <-> p_inst_rs2_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (P_INST_RS2_RS1_RD(rs2, rs1, rd, p_inst)) = {
  let success : bool = match p_inst {
    ADD8 => PEXT_ADD8(rs2, rs1, rd),
    ADD16 => PEXT_ADD16(rs2, rs1, rd),
    ADD64 => PEXT_ADD64(rs2, rs1, rd),
    AVE => PEXT_AVE(rs2, rs1, rd),
    BITREV => PEXT_BITREV(rs2, rs1, rd),
    CMPEQ8 => PEXT_CMPEQ8(rs2, rs1, rd),
    CMPEQ16 => PEXT_CMPEQ16(rs2, rs1, rd),
    CRAS16 => PEXT_CRAS16(rs2, rs1, rd),
    CRSA16 => PEXT_CRSA16(rs2, rs1, rd),
    KADD8 => PEXT_KADD8(rs2, rs1, rd),
    KADD16 => PEXT_KADD16(rs2, rs1, rd),
    KADD64 => PEXT_KADD64(rs2, rs1, rd),
    KADDH => PEXT_KADDH(rs2, rs1, rd),
    KADDW => PEXT_KADDW(rs2, rs1, rd),
    KCRAS16 => PEXT_KCRAS16(rs2, rs1, rd),
    KCRSA16 => PEXT_KCRSA16(rs2, rs1, rd),
    KDMBB => PEXT_KDMBB(rs2, rs1, rd),
    KDMBT => PEXT_KDMBT(rs2, rs1, rd),
    KDMTT => PEXT_KDMTT(rs2, rs1, rd),
    KDMABB => PEXT_KDMABB(rs2, rs1, rd),
    KDMABT => PEXT_KDMABT(rs2, rs1, rd),
    KDMATT => PEXT_KDMATT(rs2, rs1, rd),
    KHM8 => PEXT_KHM8(rs2, rs1, rd),
    KHMX8 => PEXT_KHMX8(rs2, rs1, rd),
    KHM16 => PEXT_KHM16(rs2, rs1, rd),
    KHMX16 => PEXT_KHMX16(rs2, rs1, rd),
    KHMBB => PEXT_KHMBB(rs2, rs1, rd),
    KHMBT => PEXT_KHMBT(rs2, rs1, rd),
    KHMTT => PEXT_KHMTT(rs2, rs1, rd),
    KMABB => PEXT_KMABB(rs2, rs1, rd),
    KMABT => PEXT_KMABT(rs2, rs1, rd),
    KMATT => PEXT_KMATT(rs2, rs1, rd),
    KMADA => PEXT_KMADA(rs2, rs1, rd),
    KMAXDA => PEXT_KMAXDA(rs2, rs1, rd),
    KMADS => PEXT_KMADS(rs2, rs1, rd),
    KMADRS => PEXT_KMADRS(rs2, rs1, rd),
    KMAXDS => PEXT_KMAXDS(rs2, rs1, rd),
    KMAR64 => PEXT_KMAR64(rs2, rs1, rd),
    KMDA => PEXT_KMDA(rs2, rs1, rd),
    KMXDA => PEXT_KMXDA(rs2, rs1, rd),
    KMMAC => PEXT_KMMAC(rs2, rs1, rd),
    KMMAC_U => PEXT_KMMAC_U(rs2, rs1, rd),
    KMMAWB => PEXT_KMMAWB(rs2, rs1, rd),
    KMMAWB_U => PEXT_KMMAWB_U(rs2, rs1, rd),
    KMMAWB2 => PEXT_KMMAWB2(rs2, rs1, rd),
    KMMAWB2_U => PEXT_KMMAWB2_U(rs2, rs1, rd),
    KMMAWT => PEXT_KMMAWT(rs2, rs1, rd),
    KMMAWT_U => PEXT_KMMAWT_U(rs2, rs1, rd),
    KMMAWT2 => PEXT_KMMAWT2(rs2, rs1, rd),
    KMMAWT2_U => PEXT_KMMAWT2_U(rs2, rs1, rd),
    KMMSB => PEXT_KMMSB(rs2, rs1, rd),
    KMMSB_U => PEXT_KMMSB_U(rs2, rs1, rd),
    KMMWB2 => PEXT_KMMWB2(rs2, rs1, rd),
    KMMWB2_U => PEXT_KMMWB2_U(rs2, rs1, rd),
    KMMWT2 => PEXT_KMMWT2(rs2, rs1, rd),
    KMMWT2_U => PEXT_KMMWT2_U(rs2, rs1, rd),
    KMSDA => PEXT_KMSDA(rs2, rs1, rd),
    KMSXDA => PEXT_KMSXDA(rs2, rs1, rd),
    KMSR64 => PEXT_KMSR64(rs2, rs1, rd),
    KSLLW => PEXT_KSLLW(rs2, rs1, rd),
    KSLL8 => PEXT_KSLL8(rs2, rs1, rd),
    KSLL16 => PEXT_KSLL16(rs2, rs1, rd),
    KSLRA8 => PEXT_KSLRA8(rs2, rs1, rd),
    KSLRA8_U => PEXT_KSLRA8_U(rs2, rs1, rd),
    KSLRA16 => PEXT_KSLRA16(rs2, rs1, rd),
    KSLRA16_U => PEXT_KSLRA16_U(rs2, rs1, rd),
    KSLRAW => PEXT_KSLRAW(rs2, rs1, rd),
    KSLRAW_U => PEXT_KSLRAW_U(rs2, rs1, rd),
    KSTAS16 => PEXT_KSTAS16(rs2, rs1, rd),
    KSTSA16 => PEXT_KSTSA16(rs2, rs1, rd),
    KSUB8 => PEXT_KSUB8(rs2, rs1, rd),
    KSUB16 => PEXT_KSUB16(rs2, rs1, rd),
    KSUB64 => PEXT_KSUB64(rs2, rs1, rd),
    KSUBH => PEXT_KSUBH(rs2, rs1, rd),
    KSUBW => PEXT_KSUBW(rs2, rs1, rd),
    KWMMUL => PEXT_KWMMUL(rs2, rs1, rd),
    KWMMUL_U => PEXT_KWMMUL_U(rs2, rs1, rd),
    MADDR32 => PEXT_MADDR32(rs2, rs1, rd),
    MAXW => PEXT_MAXW(rs2, rs1, rd),
    MINW => PEXT_MINW(rs2, rs1, rd),
    MSUBR32 => PEXT_MSUBR32(rs2, rs1, rd),
    MULR64 => PEXT_MULR64(rs2, rs1, rd),
    MULSR64 => PEXT_MULSR64(rs2, rs1, rd),
    PBSAD => PEXT_PBSAD(rs2, rs1, rd),
    PBSADA => PEXT_PBSADA(rs2, rs1, rd),
    PKBB16 => PEXT_PKBB16(rs2, rs1, rd),
    PKBT16 => PEXT_PKBT16(rs2, rs1, rd),
    PKTT16 => PEXT_PKTT16(rs2, rs1, rd),
    PKTB16 => PEXT_PKTB16(rs2, rs1, rd),
    PKBB32 => PEXT_PKBB32(rs2, rs1, rd),
    PKBT32 => PEXT_PKBT32(rs2, rs1, rd),
    PKTT32 => PEXT_PKTT32(rs2, rs1, rd),
    PKTB32 => PEXT_PKTB32(rs2, rs1, rd),
    RADD8 => PEXT_RADD8(rs2, rs1, rd),
    RADD16 => PEXT_RADD16(rs2, rs1, rd),
    RADD64 => PEXT_RADD64(rs2, rs1, rd),
    RADDW => PEXT_RADDW(rs2, rs1, rd),
    RCRAS16 => PEXT_RCRAS16(rs2, rs1, rd),
    RCRSA16 => PEXT_RCRSA16(rs2, rs1, rd),
    RSTAS16 => PEXT_RSTAS16(rs2, rs1, rd),
    RSTSA16 => PEXT_RSTSA16(rs2, rs1, rd),
    RSUB8 => PEXT_RSUB8(rs2, rs1, rd),
    RSUB16 => PEXT_RSUB16(rs2, rs1, rd),
    RSUB64 => PEXT_RSUB64(rs2, rs1, rd),
    RSUBW => PEXT_RSUBW(rs2, rs1, rd),
    SCMPLE8 => PEXT_SCMPLE8(rs2, rs1, rd),
    SCMPLE16 => PEXT_SCMPLE16(rs2, rs1, rd),
    SCMPLT8 => PEXT_SCMPLT8(rs2, rs1, rd),
    SCMPLT16 => PEXT_SCMPLT16(rs2, rs1, rd),
    SLL8 => PEXT_SLL8(rs2, rs1, rd),
    SLL16 => PEXT_SLL16(rs2, rs1, rd),
    SMAL => PEXT_SMAL(rs2, rs1, rd),
    SMALBB => PEXT_SMALBB(rs2, rs1, rd),
    SMALBT => PEXT_SMALBT(rs2, rs1, rd),
    SMALTT => PEXT_SMALTT(rs2, rs1, rd),
    SMALDA => PEXT_SMALDA(rs2, rs1, rd),
    SMALXDA => PEXT_SMALXDA(rs2, rs1, rd),
    SMALDS => PEXT_SMALDS(rs2, rs1, rd),
    SMALDRS => PEXT_SMALDRS(rs2, rs1, rd),
    SMALXDS => PEXT_SMALXDS(rs2, rs1, rd),
    SMAR64 => PEXT_SMAR64(rs2, rs1, rd),
    SMAQA => PEXT_SMAQA(rs2, rs1, rd),
    SMAQA_SU => PEXT_SMAQA_SU(rs2, rs1, rd),
    SMAX8 => PEXT_SMAX8(rs2, rs1, rd),
    SMAX16 => PEXT_SMAX16(rs2, rs1, rd),
    SMBB16 => PEXT_SMBB16(rs2, rs1, rd),
    SMBT16 => PEXT_SMBT16(rs2, rs1, rd),
    SMTT16 => PEXT_SMTT16(rs2, rs1, rd),
    SMDS => PEXT_SMDS(rs2, rs1, rd),
    SMDRS => PEXT_SMDRS(rs2, rs1, rd),
    SMXDS => PEXT_SMXDS(rs2, rs1, rd),
    SMIN8 => PEXT_SMIN8(rs2, rs1, rd),
    SMIN16 => PEXT_SMIN16(rs2, rs1, rd),
    SMMUL => PEXT_SMMUL(rs2, rs1, rd),
    SMMUL_U => PEXT_SMMUL_U(rs2, rs1, rd),
    SMMWB => PEXT_SMMWB(rs2, rs1, rd),
    SMMWB_U => PEXT_SMMWB_U(rs2, rs1, rd),
    SMMWT => PEXT_SMMWT(rs2, rs1, rd),
    SMMWT_U => PEXT_SMMWT_U(rs2, rs1, rd),
    SMSLDA => PEXT_SMSLDA(rs2, rs1, rd),
    SMSLXDA => PEXT_SMSLXDA(rs2, rs1, rd),
    SMSR64 => PEXT_SMSR64(rs2, rs1, rd),
    SMUL8 => PEXT_SMUL8(rs2, rs1, rd),
    SMULX8 => PEXT_SMULX8(rs2, rs1, rd),
    SMUL16 => PEXT_SMUL16(rs2, rs1, rd),
    SMULX16 => PEXT_SMULX16(rs2, rs1, rd),
    SRA_U => PEXT_SRA_U(rs2, rs1, rd),
    SRA8 => PEXT_SRA8(rs2, rs1, rd),
    SRA8_U => PEXT_SRA8_U(rs2, rs1, rd),
    SRA16 => PEXT_SRA16(rs2, rs1, rd),
    SRA16_U => PEXT_SRA16_U(rs2, rs1, rd),
    SRL8 => PEXT_SRL8(rs2, rs1, rd),
    SRL8_U => PEXT_SRL8_U(rs2, rs1, rd),
    SRL16 => PEXT_SRL16(rs2, rs1, rd),
    SRL16_U => PEXT_SRL16_U(rs2, rs1, rd),
    STAS16 => PEXT_STAS16(rs2, rs1, rd),
    STSA16 => PEXT_STSA16(rs2, rs1, rd),
    SUB8 => PEXT_SUB8(rs2, rs1, rd),
    SUB16 => PEXT_SUB16(rs2, rs1, rd),
    SUB64 => PEXT_SUB64(rs2, rs1, rd),
    UCMPLE8 => PEXT_UCMPLE8(rs2, rs1, rd),
    UCMPLE16 => PEXT_UCMPLE16(rs2, rs1, rd),
    UCMPLT8 => PEXT_UCMPLT8(rs2, rs1, rd),
    UCMPLT16 => PEXT_UCMPLT16(rs2, rs1, rd),
    UKADD8 => PEXT_UKADD8(rs2, rs1, rd),
    UKADD16 => PEXT_UKADD16(rs2, rs1, rd),
    UKADD64 => PEXT_UKADD64(rs2, rs1, rd),
    UKADDH => PEXT_UKADDH(rs2, rs1, rd),
    UKADDW => PEXT_UKADDW(rs2, rs1, rd),
    UKCRAS16 => PEXT_UKCRAS16(rs2, rs1, rd),
    UKCRSA16 => PEXT_UKCRSA16(rs2, rs1, rd),
    UKMAR64 => PEXT_UKMAR64(rs2, rs1, rd),
    UKMSR64 => PEXT_UKMSR64(rs2, rs1, rd),
    UKSTAS16 => PEXT_UKSTAS16(rs2, rs1, rd),
    UKSTSA16 => PEXT_UKSTSA16(rs2, rs1, rd),
    UKSUB8 => PEXT_UKSUB8(rs2, rs1, rd),
    UKSUB16 => PEXT_UKSUB16(rs2, rs1, rd),
    UKSUB64 => PEXT_UKSUB64(rs2, rs1, rd),
    UKSUBH => PEXT_UKSUBH(rs2, rs1, rd),
    UKSUBW => PEXT_UKSUBW(rs2, rs1, rd),
    UMAR64 => PEXT_UMAR64(rs2, rs1, rd),
    UMAQA => PEXT_UMAQA(rs2, rs1, rd),
    UMAX8 => PEXT_UMAX8(rs2, rs1, rd),
    UMAX16 => PEXT_UMAX16(rs2, rs1, rd),
    UMIN8 => PEXT_UMIN8(rs2, rs1, rd),
    UMIN16 => PEXT_UMIN16(rs2, rs1, rd),
    UMSR64 => PEXT_UMSR64(rs2, rs1, rd),
    UMUL8 => PEXT_UMUL8(rs2, rs1, rd),
    UMULX8 => PEXT_UMULX8(rs2, rs1, rd),
    UMUL16 => PEXT_UMUL16(rs2, rs1, rd),
    UMULX16 => PEXT_UMULX16(rs2, rs1, rd),
    URADD8 => PEXT_URADD8(rs2, rs1, rd),
    URADD16 => PEXT_URADD16(rs2, rs1, rd),
    URADD64 => PEXT_URADD64(rs2, rs1, rd),
    URADDW => PEXT_URADDW(rs2, rs1, rd),
    URCRAS16 => PEXT_URCRAS16(rs2, rs1, rd),
    URCRSA16 => PEXT_URCRSA16(rs2, rs1, rd),
    URSTAS16 => PEXT_URSTAS16(rs2, rs1, rd),
    URSTSA16 => PEXT_URSTSA16(rs2, rs1, rd),
    URSUB8 => PEXT_URSUB8(rs2, rs1, rd),
    URSUB16 => PEXT_URSUB16(rs2, rs1, rd),
    URSUB64 => PEXT_URSUB64(rs2, rs1, rd),
    URSUBW => PEXT_URSUBW(rs2, rs1, rd),
    WEXT => PEXT_WEXT(rs2, rs1, rd),
    ADD32 => PEXT_ADD32(rs2, rs1, rd),
    CRAS32 => PEXT_CRAS32(rs2, rs1, rd),
    CRSA32 => PEXT_CRSA32(rs2, rs1, rd),
    KADD32 => PEXT_KADD32(rs2, rs1, rd),
    KCRAS32 => PEXT_KCRAS32(rs2, rs1, rd),
    KCRSA32 => PEXT_KCRSA32(rs2, rs1, rd),
    KDMBB16 => PEXT_KDMBB16(rs2, rs1, rd),
    KDMBT16 => PEXT_KDMBT16(rs2, rs1, rd),
    KDMTT16 => PEXT_KDMTT16(rs2, rs1, rd),
    KDMABB16 => PEXT_KDMABB16(rs2, rs1, rd),
    KDMABT16 => PEXT_KDMABT16(rs2, rs1, rd),
    KDMATT16 => PEXT_KDMATT16(rs2, rs1, rd),
    KHMBB16 => PEXT_KHMBB16(rs2, rs1, rd),
    KHMBT16 => PEXT_KHMBT16(rs2, rs1, rd),
    KHMTT16 => PEXT_KHMTT16(rs2, rs1, rd),
    KMABB32 => PEXT_KMABB32(rs2, rs1, rd),
    KMABT32 => PEXT_KMABT32(rs2, rs1, rd),
    KMATT32 => PEXT_KMATT32(rs2, rs1, rd),
    KMAXDA32 => PEXT_KMAXDA32(rs2, rs1, rd),
    KMDA32 => PEXT_KMDA32(rs2, rs1, rd),
    KMXDA32 => PEXT_KMXDA32(rs2, rs1, rd),
    KMADS32 => PEXT_KMADS32(rs2, rs1, rd),
    KMADRS32 => PEXT_KMADRS32(rs2, rs1, rd),
    KMAXDS32 => PEXT_KMAXDS32(rs2, rs1, rd),
    KMSDA32 => PEXT_KMSDA32(rs2, rs1, rd),
    KMSXDA32 => PEXT_KMSXDA32(rs2, rs1, rd),
    KSLL32 => PEXT_KSLL32(rs2, rs1, rd),
    KSLRA32 => PEXT_KSLRA32(rs2, rs1, rd),
    KSLRA32_U => PEXT_KSLRA32_U(rs2, rs1, rd),
    KSTAS32 => PEXT_KSTAS32(rs2, rs1, rd),
    KSTSA32 => PEXT_KSTSA32(rs2, rs1, rd),
    KSUB32 => PEXT_KSUB32(rs2, rs1, rd),
    RADD32 => PEXT_RADD32(rs2, rs1, rd),
    RCRAS32 => PEXT_RCRAS32(rs2, rs1, rd),
    RCRSA32 => PEXT_RCRSA32(rs2, rs1, rd),
    RSTAS32 => PEXT_RSTAS32(rs2, rs1, rd),
    RSTSA32 => PEXT_RSTSA32(rs2, rs1, rd),
    RSUB32 => PEXT_RSUB32(rs2, rs1, rd),
    SLL32 => PEXT_SLL32(rs2, rs1, rd),
    SMAX32 => PEXT_SMAX32(rs2, rs1, rd),
    SMBT32 => PEXT_SMBT32(rs2, rs1, rd),
    SMTT32 => PEXT_SMTT32(rs2, rs1, rd),
    SMDS32 => PEXT_SMDS32(rs2, rs1, rd),
    SMDRS32 => PEXT_SMDRS32(rs2, rs1, rd),
    SMXDS32 => PEXT_SMXDS32(rs2, rs1, rd),
    SMIN32 => PEXT_SMIN32(rs2, rs1, rd),
    SRA32 => PEXT_SRA32(rs2, rs1, rd),
    SRA32_U => PEXT_SRA32_U(rs2, rs1, rd),
    SRL32 => PEXT_SRL32(rs2, rs1, rd),
    SRL32_U => PEXT_SRL32_U(rs2, rs1, rd),
    STAS32 => PEXT_STAS32(rs2, rs1, rd),
    STSA32 => PEXT_STSA32(rs2, rs1, rd),
    SUB32 => PEXT_SUB32(rs2, rs1, rd),
    UKADD32 => PEXT_UKADD32(rs2, rs1, rd),
    UKCRAS32 => PEXT_UKCRAS32(rs2, rs1, rd),
    UKCRSA32 => PEXT_UKCRSA32(rs2, rs1, rd),
    UKSTAS32 => PEXT_UKSTAS32(rs2, rs1, rd),
    UKSTSA32 => PEXT_UKSTSA32(rs2, rs1, rd),
    UKSUB32 => PEXT_UKSUB32(rs2, rs1, rd),
    UMAX32 => PEXT_UMAX32(rs2, rs1, rd),
    UMIN32 => PEXT_UMIN32(rs2, rs1, rd),
    URADD32 => PEXT_URADD32(rs2, rs1, rd),
    URCRAS32 => PEXT_URCRAS32(rs2, rs1, rd),
    URCRSA32 => PEXT_URCRSA32(rs2, rs1, rd),
    URSTAS32 => PEXT_URSTAS32(rs2, rs1, rd),
//    URSTSA32 => PEXT_URSTSA32(rs2, rs1, rd),
    URSTSA32 => PEXT_URSTSA32(rs2, rs1, rd),
    URSUB32 => PEXT_URSUB32(rs2, rs1, rd)
  };
  if success then
    RETIRE_SUCCESS
  else {
    handle_illegal();
    RETIRE_FAIL
  }
}

mapping p_inst_imm6_rs1_rd_mapping : p_inst_imm6_rs1_rd_op <-> string = {
  BITREVI <-> "BITREVI",
  SRAI_U <-> "SRAI_U"
}

union clause ast = P_INST_IMM6_RS1_RD : (bits(6), regidx, regidx, p_inst_imm6_rs1_rd_op)
mapping clause encdec = P_INST_IMM6_RS1_RD(imm6, rs1, rd, BITREVI) <->
  0b111010 @ imm6 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM6_RS1_RD(imm6, rs1, rd, SRAI_U) <->
  0b110101 @ imm6 @ rs1 @ 0b001 @ rd @ 0b1110111

mapping clause assembly = P_INST_IMM6_RS1_RD(imm6, rs1, rd, p_inst)
  <-> p_inst_imm6_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(imm6)

function clause execute (P_INST_IMM6_RS1_RD(imm6, rs1, rd, p_inst)) = {
  let result : bool = match p_inst {
    BITREVI => PEXT_BITREVI(imm6, rs1, rd),
    SRAI_U => PEXT_SRAI_U(imm6, rs1, rd)
  };
  RETIRE_SUCCESS;
}

mapping p_inst_rs3_rs2_rs1_rd_mapping : p_inst_rs3_rs2_rs1_rd_op <-> string = {
  BPICK <-> "BPICK"
}

union clause ast = P_INST_RS3_RS2_RS1_RD : (regidx, regidx, regidx, regidx, p_inst_rs3_rs2_rs1_rd_op)
mapping clause encdec = P_INST_RS3_RS2_RS1_RD(rs3, rs2, rs1, rd, BPICK) <->
  rs3 @ 0b00 @ rs2 @ rs1 @ 0b011 @ rd @ 0b1110111

mapping clause assembly = P_INST_RS3_RS2_RS1_RD(rs3, rs2, rs1, rd, p_inst)
  <-> p_inst_rs3_rs2_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2) ^ sep() ^ reg_name(rs3)

function clause execute (P_INST_RS3_RS2_RS1_RD(rs3, rs2, rs1, rd, p_inst)) = {
  let result : bool = match p_inst {
    BPICK => PEXT_BPICK(rs3, rs2, rs1, rd)
  };
  RETIRE_SUCCESS;
}

mapping p_inst_rs1_rd_mapping : p_inst_rs1_rd_op <-> string = {
  CLRS8 <-> "CLRS8",
  CLRS16 <-> "CLRS16",
  CLRS32 <-> "CLRS32",
  CLO8 <-> "CLO8",
  CLO16 <-> "CLO16",
  CLO32 <-> "CLO32",
  CLZ8 <-> "CLZ8",
  CLZ16 <-> "CLZ16",
  CLZ32 <-> "CLZ32",
  KABS8 <-> "KABS8",
  KABS16 <-> "KABS16",
  KABSW <-> "KABSW",
  SUNPKD810 <-> "SUNPKD810",
  SUNPKD820 <-> "SUNPKD820",
  SUNPKD830 <-> "SUNPKD830",
  SUNPKD831 <-> "SUNPKD831",
  SUNPKD832 <-> "SUNPKD832",
  SWAP8 <-> "SWAP8",
  ZUNPKD810 <-> "ZUNPKD810",
  ZUNPKD820 <-> "ZUNPKD820",
  ZUNPKD830 <-> "ZUNPKD830",
  ZUNPKD831 <-> "ZUNPKD831",
  ZUNPKD832 <-> "ZUNPKD832",
  KABS32 <-> "KABS32"
}

union clause ast = P_INST_RS1_RD : (regidx, regidx, p_inst_rs1_rd_op)
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLRS8) <->
  0b1010111 @ 0b00000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLRS16) <->
  0b1010111 @ 0b01000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLRS32) <->
  0b1010111 @ 0b11000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLO8) <->
  0b1010111 @ 0b00011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLO16) <->
  0b1010111 @ 0b01011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLO32) <->
  0b1010111 @ 0b11011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLZ8) <->
  0b1010111 @ 0b00001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLZ16) <->
  0b1010111 @ 0b01001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, CLZ32) <->
  0b1010111 @ 0b11001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, KABS8) <->
  0b1010110 @ 0b10000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, KABS16) <->
  0b1010110 @ 0b10001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, KABSW) <->
  0b1010110 @ 0b10100 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, SUNPKD810) <->
  0b1010110 @ 0b01000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, SUNPKD820) <->
  0b1010110 @ 0b01001 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, SUNPKD830) <->
  0b1010110 @ 0b01010 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, SUNPKD831) <->
  0b1010110 @ 0b01011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, SUNPKD832) <->
  0b1010110 @ 0b10011 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, SWAP8) <->
  0b1010110 @ 0b11000 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, ZUNPKD810) <->
  0b1010110 @ 0b01100 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, ZUNPKD820) <->
  0b1010110 @ 0b01101 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, ZUNPKD830) <->
  0b1010110 @ 0b01110 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, ZUNPKD831) <->
  0b1010110 @ 0b01111 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, ZUNPKD832) <->
  0b1010110 @ 0b10111 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_RS1_RD(rs1, rd, KABS32) <->
  0b1010110 @ 0b10010 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = P_INST_RS1_RD(rs1, rd, p_inst)
  <-> p_inst_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1)

function clause execute (P_INST_RS1_RD(rs1, rd, p_inst)) = {
  let result : bool = match p_inst {
    CLRS8 => PEXT_CLRS8(rs1, rd),
    CLRS16 => PEXT_CLRS16(rs1, rd),
    CLRS32 => PEXT_CLRS32(rs1, rd),
    CLO8 => PEXT_CLO8(rs1, rd),
    CLO16 => PEXT_CLO16(rs1, rd),
    CLO32 => PEXT_CLO32(rs1, rd),
    CLZ8 => PEXT_CLZ8(rs1, rd),
    CLZ16 => PEXT_CLZ16(rs1, rd),
    CLZ32 => PEXT_CLZ32(rs1, rd),
    KABS8 => PEXT_KABS8(rs1, rd),
    KABS16 => PEXT_KABS16(rs1, rd),
    KABSW => PEXT_KABSW(rs1, rd),
    SUNPKD810 => PEXT_SUNPKD810(rs1, rd),
    SUNPKD820 => PEXT_SUNPKD820(rs1, rd),
    SUNPKD830 => PEXT_SUNPKD830(rs1, rd),
    SUNPKD831 => PEXT_SUNPKD831(rs1, rd),
    SUNPKD832 => PEXT_SUNPKD832(rs1, rd),
    SWAP8 => PEXT_SWAP8(rs1, rd),
    ZUNPKD810 => PEXT_ZUNPKD810(rs1, rd),
    ZUNPKD820 => PEXT_ZUNPKD820(rs1, rd),
    ZUNPKD830 => PEXT_ZUNPKD830(rs1, rd),
    ZUNPKD831 => PEXT_ZUNPKD831(rs1, rd),
    ZUNPKD832 => PEXT_ZUNPKD832(rs1, rd),
    KABS32 => PEXT_KABS32(rs1, rd)
  };
  RETIRE_SUCCESS;
}

mapping p_inst_imm3_rs1_rd_mapping : p_inst_imm3_rs1_rd_op <-> string = {
  INSB <-> "INSB",
  KSLLI8 <-> "KSLLI8",
  SCLIP8 <-> "SCLIP8",
  SLLI8 <-> "SLLI8",
  SRAI8 <-> "SRAI8",
  SRAI8_U <-> "SRAI8_U",
  SRLI8 <-> "SRLI8",
  SRLI8_U <-> "SRLI8_U",
  UCLIP8 <-> "UCLIP8"
}

union clause ast = P_INST_IMM3_RS1_RD : (bits(3), regidx, regidx, p_inst_imm3_rs1_rd_op)
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, INSB) <->
  0b1010110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, KSLLI8) <->
  0b0111110 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, SCLIP8) <->
  0b1000110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, SLLI8) <->
  0b0111110 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, SRAI8) <->
  0b0111100 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, SRAI8_U) <->
  0b0111100 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, SRLI8) <->
  0b0111101 @ 0b00 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, SRLI8_U) <->
  0b0111101 @ 0b01 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM3_RS1_RD(imm3, rs1, rd, UCLIP8) <->
  0b1000110 @ 0b10 @ imm3 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = P_INST_IMM3_RS1_RD(imm3, rs1, rd, p_inst)
  <-> p_inst_imm3_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_3(imm3)

function clause execute (P_INST_IMM3_RS1_RD(imm3, rs1, rd, p_inst)) = {
  let result : bool = match p_inst {
    INSB => PEXT_INSB(imm3, rs1, rd),
    KSLLI8 => PEXT_KSLLI8(imm3, rs1, rd),
    SCLIP8 => PEXT_SCLIP8(imm3, rs1, rd),
    SLLI8 => PEXT_SLLI8(imm3, rs1, rd),
    SRAI8 => PEXT_SRAI8(imm3, rs1, rd),
    SRAI8_U => PEXT_SRAI8_U(imm3, rs1, rd),
    SRLI8 => PEXT_SRLI8(imm3, rs1, rd),
    SRLI8_U => PEXT_SRLI8_U(imm3, rs1, rd),
    UCLIP8 => PEXT_UCLIP8(imm3, rs1, rd)
  };
  RETIRE_SUCCESS;
}

mapping p_inst_imm5_rs1_rd_mapping : p_inst_imm5_rs1_rd_op <-> string = {
  KSLLIW <-> "KSLLIW",
  SCLIP32 <-> "SCLIP32",
  UCLIP32 <-> "UCLIP32",
  WEXTI <-> "WEXTI",
  KSLLI32 <-> "KSLLI32",
  SLLI32 <-> "SLLI32",
  SRAI32 <-> "SRAI32",
  SRAI32_U <-> "SRAI32_U",
  SRAIW_U <-> "SRAIW_U",
  SRLI32 <-> "SRLI32",
  SRLI32_U <-> "SRLI32_U"
}

union clause ast = P_INST_IMM5_RS1_RD : (bits(5), regidx, regidx, p_inst_imm5_rs1_rd_op)
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, KSLLIW) <->
  0b0011011 @ imm5 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, SCLIP32) <->
  0b1110010 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, UCLIP32) <->
  0b1111010 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, WEXTI) <->
  0b1101111 @ imm5 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, KSLLI32) <->
  0b1000010 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, SLLI32) <->
  0b0111010 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, SRAI32) <->
  0b0111000 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, SRAI32_U) <->
  0b1000000 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, SRAIW_U) <->
  0b0011010 @ imm5 @ rs1 @ 0b001 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, SRLI32) <->
  0b0111001 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM5_RS1_RD(imm5, rs1, rd, SRLI32_U) <->
  0b1000001 @ imm5 @ rs1 @ 0b010 @ rd @ 0b1110111

mapping clause assembly = P_INST_IMM5_RS1_RD(imm5, rs1, rd, p_inst)
  <-> p_inst_imm5_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_5(imm5)

function clause execute (P_INST_IMM5_RS1_RD(imm5, rs1, rd, p_inst)) = {
  let result : bool = match p_inst {
    KSLLIW => PEXT_KSLLIW(imm5, rs1, rd),
    SCLIP32 => PEXT_SCLIP32(imm5, rs1, rd),
    UCLIP32 => PEXT_UCLIP32(imm5, rs1, rd),
    WEXTI => PEXT_WEXTI(imm5, rs1, rd),
    KSLLI32 => PEXT_KSLLI32(imm5, rs1, rd),
    SLLI32 => PEXT_SLLI32(imm5, rs1, rd),
    SRAI32 => PEXT_SRAI32(imm5, rs1, rd),
    SRAI32_U => PEXT_SRAI32_U(imm5, rs1, rd),
    SRAIW_U => PEXT_SRAIW_U(imm5, rs1, rd),
    SRLI32 => PEXT_SRLI32(imm5, rs1, rd),
    SRLI32_U => PEXT_SRLI32_U(imm5, rs1, rd)
  };
  RETIRE_SUCCESS;
}

mapping p_inst_imm4_rs1_rd_mapping : p_inst_imm4_rs1_rd_op <-> string = {
  KSLLI16 <-> "KSLLI16",
  SCLIP16 <-> "SCLIP16",
  SLLI16 <-> "SLLI16",
  SRAI16 <-> "SRAI16",
  SRAI16_U <-> "SRAI16_U",
  SRLI16 <-> "SRLI16",
  SRLI16_U <-> "SRLI16_U",
  UCLIP16 <-> "UCLIP16"
}

union clause ast = P_INST_IMM4_RS1_RD : (bits(4), regidx, regidx, p_inst_imm4_rs1_rd_op)
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, KSLLI16) <->
  0b0111010 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, SCLIP16) <->
  0b1000010 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, SLLI16) <->
  0b0111010 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, SRAI16) <->
  0b0111000 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, SRAI16_U) <->
  0b0111000 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, SRLI16) <->
  0b0111001 @ 0b0 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, SRLI16_U) <->
  0b0111001 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111
mapping clause encdec = P_INST_IMM4_RS1_RD(imm4, rs1, rd, UCLIP16) <->
  0b1000010 @ 0b1 @ imm4 @ rs1 @ 0b000 @ rd @ 0b1110111

mapping clause assembly = P_INST_IMM4_RS1_RD(imm4, rs1, rd, p_inst)
  <-> p_inst_imm4_rs1_rd_mapping(p_inst) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_4(imm4)

function clause execute (P_INST_IMM4_RS1_RD(imm4, rs1, rd, p_inst)) = {
  let result : bool = match p_inst {
    KSLLI16 => PEXT_KSLLI16(imm4, rs1, rd),
    SCLIP16 => PEXT_SCLIP16(imm4, rs1, rd),
    SLLI16 => PEXT_SLLI16(imm4, rs1, rd),
    SRAI16 => PEXT_SRAI16(imm4, rs1, rd),
    SRAI16_U => PEXT_SRAI16_U(imm4, rs1, rd),
    SRLI16 => PEXT_SRLI16(imm4, rs1, rd),
    SRLI16_U => PEXT_SRLI16_U(imm4, rs1, rd),
    UCLIP16 => PEXT_UCLIP16(imm4, rs1, rd)
  };
  RETIRE_SUCCESS;
}
