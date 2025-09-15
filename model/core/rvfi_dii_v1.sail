// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

bitfield RVFI_DII_Execution_Packet_V1 : bits(704) = {
   rvfi_intr      : 703 .. 696, // [87] Trap handler:            Set for first instruction in trap handler.
   rvfi_halt      : 695 .. 688, // [86] Halt indicator:          Marks the last instruction retired
                                //                                      before halting execution.
   rvfi_trap      : 687 .. 680, // [85] Trap indicator:          Invalid decode, misaligned access or
                                //                                      jump command to misaligned address.
   rvfi_rd_addr   : 679 .. 672, // [84]      Write register address:  MUST be 0 if not used.
   rvfi_rs2_addr  : 671 .. 664, // [83]                          otherwise set as decoded.
   rvfi_rs1_addr  : 663 .. 656, // [82]      Read register addresses: Can be arbitrary when not used,
   rvfi_mem_wmask : 655 .. 648, // [81]      Write mask:              Indicates valid bytes written. 0 if unused.
   rvfi_mem_rmask : 647 .. 640, // [80]      Read mask:               Indicates valid bytes read. 0 if unused.
   rvfi_mem_wdata : 639 .. 576, // [72 - 79] Write data:              Data written to memory by this command.
   rvfi_mem_rdata : 575 .. 512, // [64 - 71] Read data:               Data read from mem_addr (i.e. before write)
   rvfi_mem_addr  : 511 .. 448, // [56 - 63] Memory access addr:      Points to byte address (aligned if define
                                //                                      is set). *Should* be straightforward.
                                //                                      0 if unused.
   rvfi_rd_wdata  : 447 .. 384, // [48 - 55] Write register value:    MUST be 0 if rd_ is 0.
   rvfi_rs2_data  : 383 .. 320, // [40 - 47]                          above. Must be 0 if register ID is 0.
   rvfi_rs1_data  : 319 .. 256, // [32 - 39] Read register values:    Values as read from registers named
   rvfi_insn      : 255 .. 192, // [24 - 31] Instruction word:        32-bit command value.
   rvfi_pc_wdata  : 191 .. 128, // [16 - 23] PC after instr:          Following PC - either PC + 4 or jump/trap target.
   rvfi_pc_rdata  : 127 ..  64, // [08 - 15] PC before instr:         PC for current instruction
   rvfi_order     :  63 ..   0, // [00 - 07] Instruction number:      INSTRET value after completion.
}

val rvfi_get_exec_packet_v1 : unit -> bits(704)
function rvfi_get_exec_packet_v1 () = {
  let v1_packet = Mk_RVFI_DII_Execution_Packet_V1(zeros());
  // Convert the v2 packet to a v1 packet
  let v1_packet = update_rvfi_intr(v1_packet, rvfi_inst_data[rvfi_intr]);
  let v1_packet = update_rvfi_halt(v1_packet, rvfi_inst_data[rvfi_halt]);
  let v1_packet = update_rvfi_trap(v1_packet, rvfi_inst_data[rvfi_trap]);
  let v1_packet = update_rvfi_insn(v1_packet, rvfi_inst_data[rvfi_insn]);
  let v1_packet = update_rvfi_order(v1_packet, rvfi_inst_data[rvfi_order]);

  let v1_packet = update_rvfi_pc_wdata(v1_packet, rvfi_pc_data[rvfi_pc_wdata]);
  let v1_packet = update_rvfi_pc_rdata(v1_packet, rvfi_pc_data[rvfi_pc_rdata]);

  let v1_packet = update_rvfi_rd_addr(v1_packet, rvfi_int_data[rvfi_rd_addr]);
  let v1_packet = update_rvfi_rs2_addr(v1_packet, rvfi_int_data[rvfi_rs2_addr]);
  let v1_packet = update_rvfi_rs1_addr(v1_packet, rvfi_int_data[rvfi_rs1_addr]);
  let v1_packet = update_rvfi_rd_wdata(v1_packet, rvfi_int_data[rvfi_rd_wdata]);
  let v1_packet = update_rvfi_rs2_data(v1_packet, rvfi_int_data[rvfi_rs2_rdata]);
  let v1_packet = update_rvfi_rs1_data(v1_packet, rvfi_int_data[rvfi_rs1_rdata]);

  let v1_packet = update_rvfi_mem_wmask(v1_packet, truncate(rvfi_mem_data[rvfi_mem_wmask], 8));
  let v1_packet = update_rvfi_mem_rmask(v1_packet, truncate(rvfi_mem_data[rvfi_mem_rmask], 8));
  let v1_packet = update_rvfi_mem_wdata(v1_packet, truncate(rvfi_mem_data[rvfi_mem_wdata], 64));
  let v1_packet = update_rvfi_mem_rdata(v1_packet, truncate(rvfi_mem_data[rvfi_mem_rdata], 64));
  let v1_packet = update_rvfi_mem_addr(v1_packet, rvfi_mem_data[rvfi_mem_addr]);

  return v1_packet.bits;
}
