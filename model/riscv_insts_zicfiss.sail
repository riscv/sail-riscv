/*=======================================================================================*/
/*  RISCV Sail Model                                                                     */
/*                                                                                       */
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except for the snapshots of the Lem and Sail libraries                   */
/*  in the prover_snapshots directory (which include copies of their                     */
/*  licences), is subject to the BSD two-clause licence below.                           */
/*                                                                                       */
/*  Copyright (c) 2017-2023                                                              */
/*    Ved Shanbhogue                                                                     */
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
/* This file specifies the instructions in the 'Zicfiss' extension.   */
/* ****************************************************************** */
/* Backward-edge CFI: Shadow stack */

/* Sail does not yet support H extension - this needs to be updated to
   support henvcfg for VS when H extension support is included        */
function zicfiss_xSSE(priv : Privilege) -> bool = {
  /* When S-mode is implemented
   *   Priv      xSSE
   *   M         0
   *   S/HS      menvcfg.SSE
   *   VS        henvcfg.SSE
   *   U/VU      senvcfg.SSE
   * When S-mode is not implemented xSSE is 0
   */
  if   priv == Machine
  then false
  else if priv == Supervisor
  then menvcfg[SSE] == 0b1
  else if haveSupMode()
  then senvcfg.SSE() == 0b1
  else false
}

function is_shadow_stack_PTE_enable() -> bool =
  zicfiss_xSSE(effectivePrivilege(SSWrite(Data), mstatus, cur_privilege))

/* ****************************************************************** */
/* SSPUSH and C.SSPUSH operation
 *   if (xSSE == 1)
 *     mem[ssp - (XLEN/8)] = X(src)
 *     ssp = ssp - (XLEN/8)
 *   endif
 */
/* ****************************************************************** */
union clause ast = SSPUSH     : (regidx)
mapping clause encdec = SSPUSH(rs2)
      if haveZicfiss() & (rs2 == 0b00001 | rs2 == 0b00101)
  <-> 0b1100111 @ rs2 @ 0b00000 @ 0b100 @ 0b00000 @ 0b1110011
      if haveZicfiss() & (rs2 == 0b00001 | rs2 == 0b00101)
mapping clause assembly = SSPUSH(rs2)
      if haveZicfiss() & (rs2 == 0b00001 | rs2 == 0b00101)
  <-> "sspush" ^ spc() ^ reg_name(rs2)
      if haveZicfiss() & (rs2 == 0b00001 | rs2 == 0b00101)
union clause ast = C_SSPUSH   : (regidx)
mapping clause encdec_compressed = C_SSPUSH(0b00001) if haveZicfiss()
  <-> 0b0110000010000001 if haveZicfiss()
mapping clause assembly = C_SSPUSH(rs2)
      if haveZicfiss()
  <-> "c.sspush" ^ spc() ^ reg_name(rs2)
      if haveZicfiss()
/* ****************************************************************** */
function clause execute SSPUSH(rs2) = {
  let width : word_width = match sizeof(xlen) {
    32 => WORD,
    64 => DOUBLE,
    _  => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
    };

  if not(zicfiss_xSSE(cur_privilege))
  then {RETIRE_SUCCESS}
  else {
    let vaddr : xlenbits = match sizeof(xlen) {
      32 => ssp - 4,
      64 => ssp - 8,
      _  => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
      };
    let aligned : bool = match width {
      WORD   => vaddr[1..0] == 0b00,
      DOUBLE => vaddr[2..0] == 0b000,
      _      => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
      };
    if not(aligned)
    then { handle_mem_exception(vaddr, E_SAMO_Access_Fault()); RETIRE_FAIL }
    else {
      match translateAddr(vaddr, SSWrite(Data)) {
        TR_Failure(e, _)    => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
        TR_Address(addr, _) => {
          let eares : MemoryOpResult(unit) = match width {
            WORD   => mem_write_ea(addr, 4, false, false, false),
            DOUBLE => mem_write_ea(addr, 8, false, false, false),
            _      => internal_error(__FILE__, __LINE__, "unexpected width")
          };
          match (eares) {
            MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
            MemValue(_) => {
              rs2_val = X(rs2);
              let res : MemoryOpResult(bool) = match sizeof(xlen) {
                32 => mem_write_value(addr, 4, rs2_val, false, false, false),
                64 => mem_write_value(addr, 8, rs2_val, false, false, false),
                _  => internal_error(__FILE__, __LINE__, "unexpected width")
              };
              match res {
                MemValue(true)  => { ssp = vaddr; RETIRE_SUCCESS },
                MemValue(false) => internal_error(__FILE__, __LINE__, "sspush got false from mem_write_value"),
                MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
              };
            }
          }
        }
      }
    }
  }
}
function clause execute (C_SSPUSH(rs2)) = execute(SSPUSH(rs2))

/* ****************************************************************** */
/* SSPOPCHK and C.SSPOPCHK operation
 *   if (xSSE == 1)
 *     temp = mem[ssp]
 *     if temp != X(src) then software-check exception
 *     else ssp = ssp + (XLEN/8)
 *   endif
 * SSPOPCHK requires write permission as shadow stacks are encoded as
 * pte.xwr = 010b
 */
/* ****************************************************************** */
union clause ast = SSPOPCHK   : (regidx)
mapping clause encdec = SSPOPCHK(rs1)
      if haveZicfiss() & (rs1 == 0b00001 | rs1 == 0b00101)
  <-> 0b110011011100 @ rs1 @ 0b100 @ 0b00000 @ 0b1110011
      if haveZicfiss() & (rs1 == 0b00001 | rs1 == 0b00101)
mapping clause assembly = SSPOPCHK(rs1)
      if haveZicfiss() & (rs1 == 0b00001 | rs1 == 0b00101)
  <-> "sspopchk" ^ spc() ^ reg_name(rs1)
      if haveZicfiss() & (rs1 == 0b00001 | rs1 == 0b00101)
union clause ast = C_SSPOPCHK : (regidx)
mapping clause encdec_compressed = C_SSPOPCHK(0b00101)
      if haveZicfiss()
  <-> 0b0110001010000001
      if haveZicfiss()
mapping clause assembly = C_SSPOPCHK(rs1)
      if haveZicfiss()
  <-> "c.sspopchk" ^ spc() ^ reg_name(rs1)
      if haveZicfiss()
/* ****************************************************************** */
function clause execute SSPOPCHK(rs1) = {
  let width : word_width = match sizeof(xlen) {
    32 => WORD,
    64 => DOUBLE,
    _  => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
    };
  let new_ssp : xlenbits = match sizeof(xlen) {
    32 => ssp + 4,
    64 => ssp + 8,
    _  => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
    };
  if not(zicfiss_xSSE(cur_privilege))
  then {RETIRE_SUCCESS}
  else {
    let vaddr : xlenbits = ssp;
    let aligned : bool = match width {
      WORD   => vaddr[1..0] == 0b00,
      DOUBLE => vaddr[2..0] == 0b000,
      _      => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
      };
    if not(aligned)
    then { handle_mem_exception(vaddr, E_SAMO_Access_Fault()); RETIRE_FAIL }
    else match translateAddr(vaddr, SSWrite(Data)) {
      TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
      TR_Address(addr, _) => {
        let mval : MemoryOpResult(xlenbits) = match sizeof(xlen) {
          32 => mem_read(SSRead(Data), addr, 4, false, false, false),
          64 => mem_read(SSRead(Data), addr, 8, false, false, false),
          _  => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
          };
        match (mval) {
          MemException(e)  => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
          MemValue(loaded) => {
            if X(rs1) != loaded
            then { handle_sw_check_exception(SHADOW_STACK_FAULT); RETIRE_FAIL }
            else { ssp = new_ssp; RETIRE_SUCCESS }
          }
        }
      }
    }
  }
}
function clause execute (C_SSPOPCHK(rs1)) = execute(SSPOPCHK(rs1))

/* ****************************************************************** */
/* SSRDP operation:
 * X(rd) = (xSSE == 1) ? ssp : 0
 */
/* ****************************************************************** */
union clause ast = SSRDP      : (regidx)
mapping clause encdec = SSRDP(rd)
      if haveZicfiss() & rd != zreg
  <-> 0b110011011100 @ 0b00000 @ 0b100 @ rd @ 0b1110011
      if haveZicfiss() & rd != zreg
mapping clause assembly = SSRDP(rd)
      if haveZicfiss() & rd != zreg
  <-> "ssrdp" ^ spc() ^ reg_name(rd)
      if haveZicfiss() & rd != zreg
/* ****************************************************************** */
function clause execute SSRDP(rd) = {
  if zicfiss_xSSE(cur_privilege)
  then { X(rd) = ssp  }
  else { X(rd) = X(0) };
  RETIRE_SUCCESS
}
/* ****************************************************************** */
/* SSAMOSWAP operation:
 *   if privilege_mode != M && menvcfg.SSE == 0
 *     raise illegal-instruction exception
 *   if S-mode is not implemented
 *     raise illegal-instruction exception
 *   else if privilege_mode == U && senvcfg.SSE == 0
 *     raise illegal-instruction exception
 *   else if privilege_mode == VS && henvcfg.SSE == 0
 *     raise virtual instruction exception
 *   else if privilege_mode == VU && senvcfg.SSE == 0
 *     raise virtual instruction exception
 *   else
 *     X(rd) = mem[X(rs1)]
 *     mem[X(rs1)] = X(rs2)
 *   endif
 *
 *   The model does not presently support H extension. The
 *   parts of algorithm dealing with VS and VU should be
 *   introduced when H extension is introduced.
 */
/* ****************************************************************** */
function ssamoswap_width_valid(size : word_width) -> bool = {
  match(size) {
    WORD   => true,
    DOUBLE => sizeof(xlen) >= 64,
    _      => false
  }
}
union clause ast = SSAMOSWAP : (bool, bool, regidx, regidx, word_width, regidx)
mapping clause encdec = SSAMOSWAP(aq, rl, rs2, rs1, size, rd)
      if haveZicfiss() & ssamoswap_width_valid(size)
  <-> 0b01001 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_enc(size) @ rd @ 0b0101111
      if haveZicfiss() & ssamoswap_width_valid(size)
mapping clause assembly = SSAMOSWAP(aq, rl, rs2, rs1, size, rd)
      if haveZicfiss() & ssamoswap_width_valid(size)
  <-> "ssamoswap" ^ "." ^ size_mnemonic(size) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc()
                  ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
      if haveZicfiss() & ssamoswap_width_valid(size)
/* ****************************************************************** */
function clause execute (SSAMOSWAP(aq, rl, rs2, rs1, width, rd)) = {
  let width_bytes = size_bytes(width);

  assert(width_bytes <= sizeof(xlen_bytes));

  if   cur_privilege != Machine & menvcfg[SSE] == 0b0
  then { handle_illegal(); RETIRE_FAIL }
  else if not(haveSupMode())
  then { handle_illegal(); RETIRE_FAIL }
  else if cur_privilege == User & senvcfg[SSE] == 0b0
  then { handle_illegal(); RETIRE_FAIL }
  else {
    match ext_data_get_addr(rs1, zeros(), SSReadWrite(Data, Data), width_bytes) {
      Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
      Ext_DataAddr_OK(vaddr) => {
        if not(is_aligned(vaddr, width))
        then { handle_mem_exception(vaddr, E_SAMO_Addr_Align()); RETIRE_FAIL }
        else match translateAddr(vaddr, SSReadWrite(Data, Data)) {
          TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
          TR_Address(addr, _) => {
            let eares = mem_write_ea(addr, width_bytes, aq & rl, rl, true);
            let rs2_val = X(rs2)[width_bytes * 8 - 1 .. 0];
            match (eares) {
              MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
              MemValue(_) => {
                match mem_read(SSReadWrite(Data, Data), addr, width_bytes, aq, aq & rl, true) {
                  MemException(e)  => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
                  MemValue(loaded) => {
                    match mem_write_value(addr, width_bytes, sign_extend(rs2_val), aq & rl, rl, true) {
                      MemValue(true)  => { X(rd) = sign_extend(loaded); RETIRE_SUCCESS },
                      MemValue(false) => { internal_error(__FILE__, __LINE__, "SSAMOSWAP got false from mem_write_value") },
                      MemException(e) => { handle_mem_exception(vaddr, e); RETIRE_FAIL }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
