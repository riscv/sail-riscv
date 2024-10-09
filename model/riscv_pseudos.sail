/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

$ifdef _PSEUDOINSTRUCTIONS

/* ******************************************* */
/* This file specifies the pseudoinstructions. */

scattered union pseudo

val pseudo_execute : pseudo -> Retired
scattered function pseudo_execute

val pseudo_assembly : pseudo <-> string
scattered mapping pseudo_assembly

val pseudo_of : pseudo -> list(string)
scattered function pseudo_of

/* ******************************************* */
union clause pseudo = LA : (regidx, bits(32))

mapping clause pseudo_assembly = LA(rd, imm)
  <-> "la" ^ spc() ^ reg_name(rd) ^sep() ^ hex_bits_32(imm)

function clause pseudo_of(LA(rd, imm)) = [|
  assembly(UTYPE(imm[31..12],rd,RISCV_AUIPC)),
  assembly(ITYPE(imm[11..0],reg_name("x0"),rd,RISCV_ADDI))
|]

function clause pseudo_execute LA(rd, imm) = {
  if execute(UTYPE(imm[31..12],rd,RISCV_AUIPC)) == RETIRE_SUCCESS &
     execute(ITYPE(imm[11..0],reg_name("x0"),rd,RISCV_ADDI)) == RETIRE_SUCCESS then
      RETIRE_SUCCESS
  else
      RETIRE_FAIL
}

/* ******************************************* */
union clause pseudo = VNEG : (regidx, regidx)

mapping clause pseudo_assembly = VNEG(vs, vd)
  <-> "vneg.v" ^ spc() ^ vreg_name(vd) ^ sep() ^ vreg_name(vs)

function clause pseudo_of(VNEG(vs, vd)) = [|
  assembly(VXTYPE(VX_VRSUB, 0b1, vs, reg_name("x0"), vd))
|]

function clause pseudo_execute VNEG(vs, vd) =
  execute(VXTYPE(VX_VRSUB, 0b1, vs, 0b00000, vd))

/* ******************************************* */

end pseudo_of
end pseudo_assembly
end pseudo_execute
end pseudo

$endif _PSEUDOINSTRUCTIONS
