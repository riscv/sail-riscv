/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
/*    Prashanth Mundkur                                                                  */
/*    Rishiyur S. Nikhil and Bluespec, Inc.                                              */
/*    Jon French                                                                         */
/*    Brian Campbell                                                                     */
/*    Robert Norton-Wright                                                               */
/*    Alasdair Armstrong                                                                 */
/*    Thomas Bauereiss                                                                   */
/*    Shaked Flur                                                                        */
/*    Christopher Pulte                                                                  */
/*    Peter Sewell                                                                       */
/*    Alexander Richardson                                                               */
/*    Hesham Almatary                                                                    */
/*    Jessica Clarke                                                                     */
/*    Microsoft, for contributions by Robert Norton-Wright and Nathaniel Wesley Filardo  */
/*    Peter Rugg                                                                         */
/*    Aril Computer Corp., for contributions by Scott Johnson                            */
/*    Philipp Tomsich                                                                    */
/*    VRULL GmbH, for contributions by its employees                                     */
/*                                                                                       */
/*  All rights reserved.                                                                 */
/*                                                                                       */
/*  This software was developed by the above within the Rigorous                         */
/*  Engineering of Mainstream Systems (REMS) project, partly funded by                   */
/*  EPSRC grant EP/K008528/1, at the Universities of Cambridge and                       */
/*  Edinburgh.                                                                           */
/*                                                                                       */
/*  This software was developed by SRI International and the University of               */
/*  Cambridge Computer Laboratory (Department of Computer Science and                    */
/*  Technology) under DARPA/AFRL contract FA8650-18-C-7809 ("CIFV"), and                 */
/*  under DARPA contract HR0011-18-C-0016 ("ECATS") as part of the DARPA                 */
/*  SSITH research programme.                                                            */
/*                                                                                       */
/*  This project has received funding from the European Research Council                 */
/*  (ERC) under the European Union’s Horizon 2020 research and innovation                */
/*  programme (grant agreement 789108, ELVER).                                           */
/*                                                                                       */
/*                                                                                       */
/*  Redistribution and use in source and binary forms, with or without                   */
/*  modification, are permitted provided that the following conditions                   */
/*  are met:                                                                             */
/*  1. Redistributions of source code must retain the above copyright                    */
/*     notice, this list of conditions and the following disclaimer.                     */
/*  2. Redistributions in binary form must reproduce the above copyright                 */
/*     notice, this list of conditions and the following disclaimer in                   */
/*     the documentation and/or other materials provided with the                        */
/*     distribution.                                                                     */
/*                                                                                       */
/*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''                   */
/*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                    */
/*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A                      */
/*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR                  */
/*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,                         */
/*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT                     */
/*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF                     */
/*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND                  */
/*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,                   */
/*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                   */
/*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF                   */
/*  SUCH DAMAGE.                                                                         */
/*=======================================================================================*/

/* ****************************************************************** */
union clause ast = ZBS_IOP : (bits(6), regidx, regidx, biop_zbs)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BCLRI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b010010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011 if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BEXTI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b010010 @ shamt @ rs1 @ 0b101 @ rd @ 0b0010011 if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BINVI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b011010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011 if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)

mapping clause encdec = ZBS_IOP(shamt, rs1, rd, RISCV_BSETI) if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)
  <-> 0b001010 @ shamt @ rs1 @ 0b001 @ rd @ 0b0010011 if haveZbs() & (sizeof(xlen) == 64 | shamt[5] == bitzero)

mapping zbs_iop_mnemonic : biop_zbs <-> string = {
  RISCV_BCLRI <-> "bclri",
  RISCV_BEXTI <-> "bexti",
  RISCV_BINVI <-> "binvi",
  RISCV_BSETI <-> "bseti"
}

mapping clause assembly = ZBS_IOP(shamt, rs1, rd, op)
  <-> zbs_iop_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ hex_bits_6(shamt)

function clause execute (ZBS_IOP(shamt, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let mask : xlenbits = if sizeof(xlen) == 32
                        then zero_extend(0b1) << shamt[4..0]
                        else zero_extend(0b1) << shamt;
  let result : xlenbits = match op {
    RISCV_BCLRI => rs1_val & ~(mask),
    RISCV_BEXTI => zero_extend(bool_to_bits((rs1_val & mask) != zeros())),
    RISCV_BINVI => rs1_val ^ mask,
    RISCV_BSETI => rs1_val | mask
  };
  X(rd) = result;
  RETIRE_SUCCESS
}

/* ****************************************************************** */
union clause ast = ZBS_RTYPE : (regidx, regidx, regidx, brop_zbs)

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BCLR) if haveZbs()
  <-> 0b0100100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011 if haveZbs()

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BEXT) if haveZbs()
  <-> 0b0100100 @ rs2 @ rs1 @ 0b101 @ rd @ 0b0110011 if haveZbs()

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BINV) if haveZbs()
  <-> 0b0110100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011 if haveZbs()

mapping clause encdec = ZBS_RTYPE(rs2, rs1, rd, RISCV_BSET) if haveZbs()
  <-> 0b0010100 @ rs2 @ rs1 @ 0b001 @ rd @ 0b0110011 if haveZbs()

mapping zbs_rtype_mnemonic : brop_zbs <-> string = {
  RISCV_BCLR    <-> "bclr",
  RISCV_BEXT    <-> "bext",
  RISCV_BINV    <-> "binv",
  RISCV_BSET    <-> "bset"
}

mapping clause assembly = ZBS_RTYPE(rs2, rs1, rd, op)
  <-> zbs_rtype_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

function clause execute (ZBS_RTYPE(rs2, rs1, rd, op)) = {
  let rs1_val = X(rs1);
  let rs2_val = X(rs2);
  let mask : xlenbits = if sizeof(xlen) == 32
                        then zero_extend(0b1) << rs2_val[4..0]
                        else zero_extend(0b1) << rs2_val[5..0];
  let result : xlenbits = match op {
    RISCV_BCLR => rs1_val & ~(mask),
    RISCV_BEXT => zero_extend(bool_to_bits((rs1_val & mask) != zeros())),
    RISCV_BINV => rs1_val ^ mask,
    RISCV_BSET => rs1_val | mask
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
