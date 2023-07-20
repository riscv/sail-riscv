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
/*    PLCT, for contributions by its employees                                           */
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
union clause ast = RISCV_ZICBOM : (cbop_zicbom, regidx)

mapping encdec_cbop : cbop_zicbom <-> bits(12) = {
  CBO_CLEAN <-> 0b000000000001,
  CBO_FLUSH <-> 0b000000000010,
  CBO_INVAL <-> 0b000000000000
}

mapping clause encdec = RISCV_ZICBOM(cbop, rs1) if haveZicbom()
  <-> encdec_cbop(cbop) @ rs1 @ 0b010 @ 0b00000 @ 0b0001111 if haveZicbom()

mapping cbop_mnemonic : cbop_zicbom <-> string = {
  CBO_CLEAN <-> "cbo.clean",
  CBO_FLUSH <-> "cbo.flush",
  CBO_INVAL <-> "cbo.inval"
}

mapping clause assembly = RISCV_ZICBOM(cbop, rs1)
  <-> cbop_mnemonic(cbop) ^ spc() ^ "(" ^ reg_name(rs1) ^ ")"

val process_clean_inval : (regidx, cbop_zicbom) -> Retired effect {escape, rmem, rmemt, rreg, wmv, wmvt, wreg}
function process_clean_inval(rs1, cbop) = {
  let rs1_val = X(rs1);
  let cache_block_size = plat_cache_block_size();
  let begin_addr = rs1_val & ~(cache_block_size - EXTZ(0b1));
  let offset = begin_addr - rs1_val;
  match ext_data_get_addr(rs1, offset, Read(Data), cache_block_size) {
    Ext_DataAddr_Error(e) => { ext_handle_data_check_error(e); RETIRE_FAIL },
    Ext_DataAddr_OK(vaddr) => {
      let res: option(ExceptionType) = match translateAddr(vaddr, Read(Data)) {
        TR_Address(paddr, _) => {
          match mem_read(Read(Data), paddr, 1, false, false, false) {
            MemValue(_) => None(),
            MemException(e)  => Some(e)
          }
        },
        TR_Failure(e, _) => Some(e)
      };
      match res {
        None() => RETIRE_SUCCESS,  // do nothing for cbop currently
        Some(e) => {
          match (e) {
            E_Load_Access_Fault() => { handle_mem_exception(vaddr, E_SAMO_Access_Fault()); RETIRE_FAIL },
            E_Load_Page_Fault() => { handle_mem_exception(vaddr, E_SAMO_Page_Fault()); RETIRE_FAIL }
          }
        }
      }
    }
  }
}

function cbo_clean_flush_enable(p : Privilege) -> bool =
   ~((p != Machine & menvcfg.CBCFE() == 0b0) | (p == User & senvcfg.CBCFE() == 0b0))

function cbop_for_cbo_inval(p : Privilege) -> option(cbop_zicbom) = {
  let illegal = ((p != Machine) & (menvcfg.CBIE() == 0b00)) |
                ((p == User) & (senvcfg.CBIE() == 0b00));
  let flush = ((p != Machine) & (menvcfg.CBIE() == 0b01)) |
              ((p == User) & (senvcfg.CBIE() == 0b01));
  if illegal then None()
  else if flush then Some(CBO_FLUSH)
  else Some(CBO_INVAL)
}

function clause execute(RISCV_ZICBOM(cbop, rs1)) = {
  let cbcfe = cbo_clean_flush_enable(cur_privilege);
  let final_op : option(cbop_zicbom) = match (cbop, cbcfe) {
    (CBO_CLEAN, true) => Some(CBO_CLEAN),
    (CBO_CLEAN, false) => None(),
    (CBO_FLUSH, true) => Some(CBO_FLUSH),
    (CBO_FLUSH, false) => None(),
    (CBO_INVAL, _) => cbop_for_cbo_inval(cur_privilege)
  };
  match final_op {
    None() => { handle_illegal(); RETIRE_FAIL },
    Some(cbop) => process_clean_inval(rs1, cbop)
  }
}
