/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

union clause ast = HFENCE_VVMA : (regidx, regidx)

mapping clause encdec = HFENCE_VVMA(rs1, rs2)
  <-> 0b0010001 @ rs2 @ rs1 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute HFENCE_VVMA(rs1, rs2) = {
  let addr : option(xlenbits) = if rs1 == 0b00000 then None() else Some(X(rs1));
  let asid : option(xlenbits) = if rs2 == 0b00000 then None() else Some(X(rs2));
  match (cur_privilege, cur_virtualization) {
    (User, V1)       => { handle_virtual_instr(); RETIRE_FAIL },
    (User, V0)       => { handle_illegal(); RETIRE_FAIL },
    (Supervisor, V1) => { handle_virtual_instr(); RETIRE_FAIL },
    (Supervisor, V0) => { flush_TLB(asid, Stage_VS, addr); RETIRE_SUCCESS },
    (Machine, _)     => { flush_TLB(asid, Stage_VS, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_VVMA(rs1, rs2)
  <-> "hfence.vvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)

/* ****************************************************************** */

union clause ast = HFENCE_GVMA : (regidx, regidx)

mapping clause encdec = HFENCE_GVMA(rs1, rs2)
  <-> 0b0110001 @ rs2 @ rs1 @ 0b000 @ 0b00000 @ 0b1110011

function clause execute HFENCE_GVMA(rs1, rs2) = {
  let addr : option(xlenbits) = if rs1 == 0b00000 then None() else Some(X(rs1));
  let vmid : option(xlenbits) = if rs2 == 0b00000 then None() else Some(X(rs2));
  match (cur_privilege, cur_virtualization) {
    (User, V1)       => { handle_virtual_instr(); RETIRE_FAIL },
    (User, V0)       => { handle_illegal(); RETIRE_FAIL },
    (Supervisor, V1) => { handle_virtual_instr(); RETIRE_FAIL },
    (Supervisor, V0) => match mstatus[TVM] {
                            0b1 => { handle_illegal(); RETIRE_FAIL },
                            0b0 => { flush_TLB(vmid, Stage_G, addr); RETIRE_SUCCESS }
                        },
    (Machine, _)    => { flush_TLB(vmid, Stage_G, addr); RETIRE_SUCCESS }
  }
}

mapping clause assembly = HFENCE_GVMA(rs1, rs2)
  <-> "hfence.gvma" ^ spc() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
