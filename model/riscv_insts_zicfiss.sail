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
  then menvcfg.SSE() == 0b1
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
function sspush( rs2 : regidx ) -> Retired = {
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
function sspopchk( rs1 : regidx ) -> Retired = {
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

/* ****************************************************************** */
/* SSRDP operation: X(rd) = (xSSE == 1) ? ssp : 0 */
function ssrdp( rd : regidx ) -> Retired = {
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

function ssamoswap_width_valid(size : word_width) -> bool = {
  match(size) {
    WORD   => true,
    DOUBLE => sizeof(xlen) >= 64,
    _      => false
  }
}

union clause ast = SSAMOSWAP : (bool, bool, regidx, regidx, word_width, regidx)
mapping clause encdec = SSAMOSWAP(aq, rl, rs2, rs1, size, rd) if ssamoswap_width_valid(size)
  <-> 0b01001 @ bool_bits(aq) @ bool_bits(rl) @ rs2 @ rs1 @ 0b0 @ size_bits(size) @ rd @ 0b0101111 if ssamoswap_width_valid(size)

function clause execute (SSAMOSWAP(aq, rl, rs2, rs1, width, rd)) = {
  if   cur_privilege != Machine & menvcfg.SSE() == 0b1
  then { handle_illegal(); RETIRE_FAIL }
  else if not(haveSupMode())
  then { handle_illegal(); RETIRE_FAIL }
  else if cur_privilege == User & senvcfg.SSE() == 0b1
  then { handle_illegal(); RETIRE_FAIL }
  else {
    match ext_data_get_addr(rs1, zeros(), SSReadWrite(Data, Data), width) {
      Ext_DataAddr_Error(e)  => { ext_handle_data_check_error(e); RETIRE_FAIL },
      Ext_DataAddr_OK(vaddr) => {
        match translateAddr(vaddr, SSReadWrite(Data, Data)) {
          TR_Failure(e, _) => { handle_mem_exception(vaddr, e); RETIRE_FAIL },
          TR_Address(addr, _) => {
            let eares : MemoryOpResult(unit) = match (width, sizeof(xlen)) {
              (WORD, _)    => mem_write_ea(addr, 4, aq & rl, rl, true),
              (DOUBLE, 64) => mem_write_ea(addr, 8, aq & rl, rl, true),
              _            => internal_error(__FILE__, __LINE__, "Unexpected AMOSSWAP width")
            };
            let swap : xlenbits = match width {
              WORD   => zero_extend(X(rs2)),
              DOUBLE => X(rs2),
              _      => internal_error(__FILE__, __LINE__, "Unexpected AMOSSWAP width")
            };
            match (eares) {
              MemException(e) => { handle_mem_exception(addr, e); RETIRE_FAIL },
              MemValue(_) => {
                let mval : MemoryOpResult(xlenbits) = match sizeof(xlen) {
                  32 => extend_value(false, mem_read(SSReadWrite(Data, Data), addr, 4, true, true, true)),
                  64 => extend_value(false, mem_read(SSReadWrite(Data, Data), addr, 8, true, true, true)),
                  _  => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
                };
                match (mval) {
                  MemException(e)  => { handle_mem_exception(addr, e); RETIRE_FAIL },
                  MemValue(loaded) => {
                    let wval   : MemoryOpResult(bool) = match sizeof(xlen) {
                      32 => mem_write_value(addr, 4, swap, true, true, true),
                      64 => mem_write_value(addr, 8, swap, true, true, true),
                      _  => internal_error(__FILE__, __LINE__, "Unexpected xlen width")
                    };
                    match (wval) {
                      MemValue(true)  => { X(rd) = loaded; RETIRE_SUCCESS },
                      MemValue(false) => { internal_error(__FILE__, __LINE__, "SSAMOSWAP got false from mem_write_value") },
                      MemException(e) => { handle_mem_exception(addr, e); RETIRE_FAIL }
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

mapping clause assembly = SSAMOSWAP(aq, rl, rs2, rs1, width, rd)
  <-> "ssamoswap" ^ "." ^ size_mnemonic(width) ^ maybe_aq(aq) ^ maybe_rl(rl) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs2) ^ sep() ^ "(" ^ reg_name(rs1) ^ ")"
