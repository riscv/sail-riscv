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
union clause ast = RISCV_ZICBOZ : (regidx)

mapping clause encdec = RISCV_ZICBOZ(rs1) if haveZicboz()
  <-> 0b000000000100 @ rs1 @ 0b010 @ 0b00000 @ 0b0001111 if haveZicboz()

mapping clause assembly = RISCV_ZICBOZ(rs1)
  <-> "cbo.zero" ^ spc()  ^ "(" ^ reg_name(rs1) ^ ")"

function get_envcfg_cbze(p : Privilege) -> bool =
  ~((p != Machine & menvcfg.CBZE() == 0b0) | (p == User & senvcfg.CBZE() == 0b0))

val process_cbo_zero : (regidx) -> Retired effect {eamem, escape, rmem, rmemt, rreg, wmv, wmvt, wreg}
function process_cbo_zero(rs1) = {
  let rs1_val = X(rs1);
  let cache_block_size = plat_cache_block_size();
  let begin_addr = rs1_val & ~(cache_block_size - EXTZ(0b1));
  let offset = begin_addr - rs1_val;
  index : xlenbits = zeros();
  failed : bool = false;
  match ext_data_get_addr(rs1, offset, Write(Data), cache_block_size) {
    Ext_DataAddr_Error(e) => { ext_handle_data_check_error(e); failed = true },
    Ext_DataAddr_OK(vaddr) =>
      while (index <_u cache_block_size) & (failed == false) do {
        let addr = vaddr + index;
        match translateAddr(addr, Write(Data)) {
          TR_Failure(e, _) => { handle_mem_exception(vaddr, e); failed = true },
          TR_Address(paddr, _) => {
            let eares : MemoryOpResult(unit) = mem_write_ea(paddr, 1, false, false, false);
            match (eares) {
              MemException(e) => { handle_mem_exception(vaddr, e); failed = true },
              MemValue(_) => {
                let res : MemoryOpResult(bool) = mem_write_value(paddr, 1, zeros(), false, false, false);
                match (res) {
                  MemValue(true) => index = index + EXTZ(0b1),
                  MemValue(false) => internal_error(__FILE__, __LINE__, "store got false from mem_write_value"),
                  MemException(e) => { handle_mem_exception(vaddr, e); failed = true }
                }
              }
            }
          }
        }
    }
  };
  if failed then RETIRE_FAIL
  else RETIRE_SUCCESS
}

function clause execute(RISCV_ZICBOZ(rs1)) = {
  if get_envcfg_cbze(cur_privilege) then
    process_cbo_zero(rs1)
  else {
    handle_illegal();
    RETIRE_FAIL
  }
}
