/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

val rvfi_get_insn = impure "rvfi_get_insn" : unit -> bits(32)
function rvfi_get_insn() = zeros()

val rvfi_set_inst_data_insn = impure "rvfi_set_inst_data_insn" : bits(64) -> unit
function rvfi_set_inst_data_insn(_) = ()

val rvfi_set_inst_data_order = impure "rvfi_set_inst_data_order" : bits(64) -> unit
function rvfi_set_inst_data_order(_) = ()

val rvfi_set_inst_data_mode = impure "rvfi_set_inst_data_mode" : bits(8) -> unit
function rvfi_set_inst_data_mode(_) = ()

val rvfi_set_inst_data_ixl = impure "rvfi_set_inst_data_ixl" : bits(8) -> unit
function rvfi_set_inst_data_ixl(_) = ()

val rvfi_set_pc_data_rdata = impure "rvfi_set_pc_data_rdata" : bits(64) -> unit
function rvfi_set_pc_data_rdata(_) = ()

val rvfi_set_pc_data_wdata = impure "rvfi_set_pc_data_wdata" : bits(64) -> unit
function rvfi_set_pc_data_wdata(_) = ()
