/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* The definition for the sequential model. */

function clause execute (JALR(imm, rs1, rd)) = {
  // For the sequential model, the memory-model definition doesn't work directly
  // if rs1 = rd. We would effectively have to keep a regfile for reads and another for
  // writes, and swap on instruction completion. This could perhaps be optimized in
  // some manner, but for now, we just keep a reordered definition to improve simulator
  // performance.
  let link_address = get_next_pc();
  let target = X(rs1) + sign_extend(imm);
  match jump_to([target with 0 = bitzero]) {
    Retire_Success() => { X(rd) = link_address; Retire_Success() },
    failure => failure,
  }
}
