/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2021                                                              */
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

/* **************************************************************** */
/* This file specifies the instructions in the F extension          */
/* (single precision floating point).                               */

/* RISC-V follows IEEE 754-2008 floating point arithmetic standard. */

/* Original version written by Rishiyur S. Nikhil, Sept-Oct 2019    */

/* **************************************************************** */
/* IMPORTANT!                                                       */
/* The files 'riscv_insts_fext.sail', 'riscv_insts_dext.sail' and   */
/* 'riscv_insts_zfh.sail' define the F, D and Zfh extensions,       */
/* respectively.                                                    */
/* The texts follow each other very closely; please try to maintain */
/* this correspondence as the files are maintained for bug-fixes,   */
/* improvements, and version updates.                               */

/* **************************************************************** */

/* **************************************************************** */
/* S and D value structure (sign, exponent, mantissa)               */

/* TODO: this should be a 'mapping' */
/*
val      fsplit_S : bits(32) -> (bits(1), bits(8), bits(23))
function fsplit_S   x32 = (x32[31..31], x32[30..23], x32[22..0])

val      fmake_S  : (bits(1), bits(8), bits(23)) -> bits(32)
function fmake_S (sign, exp, mant) = sign @ exp @ mant
*/


/* **************************************************************** */
/* Helper functions for 'encdec()'                                  */


/* ****************************************************************** */
/* Floating-point loads                                               */

/* not sure about the bits repr, thus extract here TODO : check the repr */
let Q_word_width_repr = 0b100

/* AST */
/* FLH, FLW and FLD; H/W/D is encoded in 'word_width' */

union clause ast = LOAD_FP_Q : (bits(12), regidx, regidx)

/* AST <-> Binary encoding ================================ */

mapping clause encdec = LOAD_FP_Q(imm, rs1, rd)                          if haveQExt()
                    <-> imm @ rs1 @ Q_word_width_repr @ rd @ 0b000_0111  if haveQExt()

/* Execution semantics ==================================== */

val      read_mem_quad_helper : (xlenbits, regidx) -> option(bits(64)) effect  {escape, rmem, rmemt, rreg, wmv, wmvt, wreg}
function read_mem_quad_helper(offset : xlenbits, rs1 : regidx) = {
  match ext_data_get_addr(rs1, offset, Read(Data), DOUBLE) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); None() },
    Ext_DataAddr_OK(vaddr) =>
      if   check_misaligned(vaddr, DOUBLE)
      then { handle_mem_exception(vaddr, E_Load_Addr_Align()); None() }
      else match translateAddr(vaddr, Read(Data)) {
        TR_Failure(e, _) => { handle_mem_exception(vaddr, e); None() },
        TR_Address(addr, _) => {
          let (aq, rl, res) = (false, false, false);
          match mem_read(Read(Data), addr, 8, aq, rl, res) {
            MemValue(result) => { Some(result) },
            MemException(e) => { handle_mem_exception(addr, e); None() }
          }
        }
      }
  } 
}

function clause execute(LOAD_FP_Q(imm, rs1, rd)) = {
  /* because ext_data_get_addr requires a word width as input, and Quad is not defined
     currently implement this in two memory reads */
  /* the problem is that in error handling, it might report offset read error or 
     offset + 8 read error, I don't know if this is the expected behavior */
  let offset1 : xlenbits = EXTS(imm);
  let offset2 : xlenbits = offset1 + 8;
  match read_mem_quad_helper(offset1, rs1) {
    None()        => { RETIRE_FAIL },
    Some(result1) => { 
      match read_mem_quad_helper(offset2, rs1) {
        None()        => { RETIRE_FAIL },
        Some(result2) => { F(rd) = result1 @ result2; RETIRE_SUCCESS }
      }
    }
  }
}

/* AST -> Assembly notation ================================ */

mapping clause assembly = LOAD_FP_Q(imm, rs1, rd)
                      <-> "flq"
                          ^ spc() ^ freg_or_reg_name(rd)
                          ^ sep() ^ hex_bits_12(imm)
                          ^ opt_spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"

/* ****************************************************************** */
/* Floating-point stores                                              */

/* AST */
/* FSH, FSW and FSD; H/W/D is encoded in 'word_width' */

/*
union clause ast = STORE_FP_Q : (bits(12), regidx, regidx)


mapping clause encdec = STORE_FP_Q(imm7 @ imm5, rs2, rs1)                                 if haveQExt()
                    <-> imm7 : bits(7) @ rs2 @ rs1 @ Q_word_width_repr @ imm5 : bits(5) @ 0b010_0111  if haveQExt()


val process_fstore : (xlenbits, MemoryOpResult(bool)) -> Retired effect {escape, rreg, wreg}
function process_fstore(vaddr, value) =
  match value {
    MemValue(true)  => { RETIRE_SUCCESS },
    MemValue(false) => { internal_error("store got false from mem_write_value") },
    MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
  }

function clause execute (STORE_FP_Q(imm, rs2, rs1)) = {
  let offset : xlenbits = EXTS(imm);
  let (aq, rl, con) = (false, false, false);
  match ext_data_get_addr(rs1, offset, Write(Data), width) {
    Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) =>
      if   check_misaligned(vaddr, width)
      then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
      else match translateAddr(vaddr, Write(Data)) {
        TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) => {
          let eares : MemoryOpResult(unit) = mem_write_ea(addr, 16m, aq, rl, false);
          match (eares) {
            MemException(e) => { handle_mem_exception(addr, e); RETIRE_FAIL },
            MemValue(_) => {
              let rs2_val = F(rs2);
              match mem_write_value(addr, 16, rs2_val, aq, rl, con) {
                MemValue(true)  => { RETIRE_SUCCESS },
                MemValue(false) => { internal_error("store got false from mem_write_value") },
                MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
              }
            }
          }
        }
      }
  }
}


mapping clause assembly = STORE_FP_Q(imm, rs2, rs1, width)
                      <-> "fsq"
                          ^ spc() ^ freg_name(rs2)
                          ^ sep() ^ hex_bits_12(imm)
                          ^ opt_spc() ^ "(" ^ opt_spc() ^ reg_name(rs1) ^ opt_spc() ^ ")"
*/
