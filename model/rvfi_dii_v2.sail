/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

bitfield RVFI_DII_Execution_PacketV2 : bits(512) = {
  magic : 63 .. 0,         // must be set to 'trace-v2'
  trace_size : 127 .. 64,  // total size of the trace packet + extensions
  basic_data : 319 .. 128, // RVFI_DII_Execution_Packet_InstMetaData
  pc_data : 447 .. 320,    // RVFI_DII_Execution_Packet_PC
  // available_fields : 511 .. 448,
  integer_data_available: 448, // Followed by RVFI_DII_Execution_Packet_Ext_Integer if set
  memory_access_data_available: 449, // Followed by R VFI_DII_Execution_Packet_Ext_MemAccess if set
  floating_point_data_available: 450, // TODO: Followed by RVFI_DII_Execution_Packet_Ext_FP if set
  csr_read_write_data_available: 451, // TODO: Followed by RVFI_DII_Execution_Packet_Ext_CSR if set
  cheri_data_available: 452, // TODO: Followed by RVFI_DII_Execution_Packet_Ext_CHERI if set
  cheri_scr_read_write_data_available: 453, // TODO: Followed by RVFI_DII_Execution_Packet_Ext_CHERI_SCR if set
  trap_data_available: 454, // TODO: Followed by RVFI_DII_Execution_Packet_Ext_Trap if set
  unused_data_available_fields : 511 .. 455, // To be used for additional RVFI_DII_Execution_Packet_Ext_* structs
}

val rvfi_get_v2_support_packet : unit -> bits(704)
function rvfi_get_v2_support_packet () = {
  let rvfi_exec = Mk_RVFI_DII_Execution_Packet_V1(zeros());
  // Returning 0x3 (using the unused high bits) in halt instead of 0x1 means
  // that we support the version 2 wire format. This is required to keep
  // backwards compatibility with old implementations that do not support
  // the new trace format.
  let rvfi_exec = update_rvfi_halt(rvfi_exec, 0x03);
  return rvfi_exec.bits;
}

val rvfi_get_v2_trace_size : unit -> bits(64)
function rvfi_get_v2_trace_size () = {
  let trace_size : bits(64) = to_bits(512);
  let trace_size = if (rvfi_int_data_present) then trace_size + 320 else trace_size;
  let trace_size = if (rvfi_mem_data_present) then trace_size + 704 else trace_size;
  return trace_size >> 3; // we have to return bytes not bits
}

val rvfi_get_exec_packet_v2 : unit -> bits(512)
function rvfi_get_exec_packet_v2 () = {
  // TODO: add the other data
  // TODO: find a way to return a variable-length bitvector
  let packet = Mk_RVFI_DII_Execution_PacketV2(zeros());
  let packet = update_magic(packet, 0x32762d6563617274); // ASCII "trace-v2" (BE)
  let packet = update_basic_data(packet, rvfi_inst_data.bits);
  let packet = update_pc_data(packet, rvfi_pc_data.bits);
  let packet = update_integer_data_available(packet, bool_to_bits(rvfi_int_data_present));
  let packet = update_memory_access_data_available(packet, bool_to_bits(rvfi_mem_data_present));
  // To simplify the implementation (so that we can return a fixed-size vector)
  // we always return a max-size packet from this function, and the C emulator
  // ensures that only trace_size bits are sent over the socket.
  let packet = update_trace_size(packet, rvfi_get_v2_trace_size());
  return packet.bits;
}
