// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// "RISC-V Formal Interface - Direct Instruction Injection" support
// For use with https://github.com/CTSRD-CHERI/TestRIG

bitfield RVFI_DII_Instruction_Packet : bits(64) = {
   padding   : 63 .. 56, // [7]
   rvfi_cmd  : 55 .. 48, // [6] This token is a trace command.  For example, reset device under test.
   rvfi_time : 47 .. 32, // [5 - 4] Time to inject token.  The difference between this and the previous
                         // instruction time gives a delay before injecting this instruction.
                         // This can be ignored for models but gives repeatability for implementations
                         // while shortening counterexamples.
   rvfi_insn : 31 ..  0, // [0 - 3] Instruction word: 32-bit instruction or command. The lower 16-bits
                         // may decode to a 16-bit compressed instruction.
}

register rvfi_instruction : RVFI_DII_Instruction_Packet

val rvfi_set_instr_packet : bits(64) -> unit

function rvfi_set_instr_packet(p) =
  rvfi_instruction = Mk_RVFI_DII_Instruction_Packet(p)

val rvfi_get_cmd : unit -> bits(8)

function rvfi_get_cmd () = rvfi_instruction[rvfi_cmd]

val rvfi_get_insn : unit -> bits(32)

function rvfi_get_insn () = rvfi_instruction[rvfi_insn]

val print_instr_packet : bits(64) -> unit

function print_instr_packet(bs) = {
  let p = Mk_RVFI_DII_Instruction_Packet(bs);
  print_bits("command ", p[rvfi_cmd]);
  print_bits("instruction ", p[rvfi_insn])
}


bitfield RVFI_DII_Execution_Packet_InstMetaData : bits(192) = {
  // The rvfi_order field must be set to the instruction index. No indices
  // must be used twice and there must be no gaps. Instructions may be
  // retired in a reordered fashion, as long as causality is preserved
  // (register and memory write operations must be retired before the read
  // operations that depend on them).
  rvfi_order  : 63 .. 0,
  // rvfi_insn is the instruction word for the retired instruction. In case
  // of an instruction with fewer than ILEN bits, the upper bits of this
  // output must be all zero. For compressed instructions the compressed
  // instruction word must be output on this port. For fused instructions the
  // complete fused instruction sequence must be output.
  rvfi_insn  : 127 ..  64,
  // rvfi_trap must be set for an instruction that cannot be decoded as a
  // legal instruction, such as 0x00000000.
  // In addition, rvfi_trap must be set for a misaligned memory read or
  // write in PMAs that don't allow misaligned access, or other memory
  // access violations. rvfi_trap must also be set for a jump instruction
  // that jumps to a misaligned instruction.
  rvfi_trap  : 135 ..  128,
  // The signal rvfi_halt must be set when the instruction is the last
  // instruction that the core retires before halting execution. It should not
  // be set for an instruction that triggers a trap condition if the CPU
  // reacts to the trap by executing a trap handler. This signal enables
  // verification of liveness properties.
  rvfi_halt  : 143 ..  136,
  // rvfi_intr must be set for the first instruction that is part of a trap
  // handler, i.e. an instruction that has a rvfi_pc_rdata that does not
  // match the rvfi_pc_wdata of the previous instruction.
  rvfi_intr  : 151 ..  144,
  // rvfi_mode must be set to the current privilege level, using the following
  // encoding: 0=U-Mode, 1=S-Mode, 2=Reserved, 3=M-Mode
  rvfi_mode  : 159 ..  152,
  // rvfi_ixl must be set to the value of MXL/SXL/UXL in the current privilege level,
  // using the following encoding: 1=32, 2=64
  rvfi_ixl  : 167 ..  160,

  // When the core retires an instruction, it asserts the rvfi_valid signal
  // and uses the signals described below to output the details of the
  // retired instruction. The signals below are only valid during such a
  // cycle and can be driven to arbitrary values in a cycle in which
  // rvfi_valid is not asserted.
  rvfi_valid  : 175 ..  168,
  // Note: since we only send these packets in the valid state, we could
  // omit the valid signal, but we need 3 bytes of padding after ixl anyway
  // so we might as well include it
  padding  : 191 ..  176,
}

bitfield RVFI_DII_Execution_Packet_PC : bits(128) = {
  // This is the program counter (pc) before (rvfi_pc_rdata) and after
  // (rvfi_pc_wdata) execution of this instruction. I.e. this is the address
  // of the retired instruction and the address of the next instruction.
  rvfi_pc_rdata  : 63 .. 0,
  rvfi_pc_wdata  : 127 ..  64,
}

bitfield RVFI_DII_Execution_Packet_Ext_Integer : bits(320) = {
  magic : 63 .. 0, // must be "int-data"
  // rvfi_rd_wdata is the value of the x register addressed by rd after
  // execution of this instruction. This output must be zero when rd is zero.
  rvfi_rd_wdata  : 127 ..  64,
  // rvfi_rs1_rdata/rvfi_rs2_rdata is the value of the x register addressed
  // by rs1/rs2 before execution of this instruction. This output must be
  // zero when rs1/rs2 is zero.
  rvfi_rs1_rdata  : 191 .. 128,
  rvfi_rs2_rdata  : 255 .. 192,
  // rvfi_rd_addr is the decoded rd register address for the retired
  // instruction. For an instruction that writes no rd register, this output
  // must always be zero.
  rvfi_rd_addr      : 263 .. 256,
  // rvfi_rs1_addr and rvfi_rs2_addr are the decoded rs1 and rs1 register
  // addresses for the retired instruction. For an instruction that reads no
  // rs1/rs2 register, this output can have an arbitrary value. However, if
  // this output is nonzero then rvfi_rs1_rdata must carry the value stored
  // in that register in the pre-state.
  rvfi_rs1_addr  : 271 .. 264,
  rvfi_rs2_addr  : 279 .. 272,
  padding  : 319 .. 280,
}

bitfield RVFI_DII_Execution_Packet_Ext_MemAccess : bits(704) = {
  magic : 63 .. 0, // must be "mem-data"
  // rvfi_mem_rdata is the pre-state data read from rvfi_mem_addr.
  // rvfi_mem_rmask specifies which bytes are valid.
  // CHERI-extension: widened to 32 bytes to allow reporting 129 bits
  rvfi_mem_rdata : 319 ..  64,
  // rvfi_mem_wdata is the post-state data written to rvfi_mem_addr.
  // rvfi_mem_wmask specifies which bytes are valid.
  // CHERI-extension: widened to 32 bytes to allow reporting 129 bits
  rvfi_mem_wdata : 575 .. 320,
  // rvfi_mem_rmask is a bitmask that specifies which bytes in rvfi_mem_rdata
  // contain valid read data from rvfi_mem_addr.
  // CHERI-extension: we extend rmask+wmask to 32 bits to allow reporting the
  // mask for CHERI/RV128 accesses here.
  rvfi_mem_rmask      : 607 .. 576,
  // rvfi_mem_wmask is a bitmask that specifies which bytes in rvfi_mem_wdata
  // contain valid data that is written to rvfi_mem_addr.
  // CHERI-extension: widened to 32 bits
  rvfi_mem_wmask      : 639 .. 608,
  // For memory operations (rvfi_mem_rmask and/or rvfi_mem_wmask are
  // non-zero), rvfi_mem_addr holds the accessed memory location.
  rvfi_mem_addr : 703 .. 640,
}

register rvfi_inst_data : RVFI_DII_Execution_Packet_InstMetaData
register rvfi_pc_data : RVFI_DII_Execution_Packet_PC
register rvfi_int_data : RVFI_DII_Execution_Packet_Ext_Integer
register rvfi_int_data_present : bool
register rvfi_mem_data : RVFI_DII_Execution_Packet_Ext_MemAccess
register rvfi_mem_data_present : bool

// Reset the trace
val rvfi_zero_exec_packet : unit -> unit

function rvfi_zero_exec_packet () = {
  rvfi_inst_data = Mk_RVFI_DII_Execution_Packet_InstMetaData(zeros());
  rvfi_pc_data = Mk_RVFI_DII_Execution_Packet_PC(zeros());
  rvfi_int_data = Mk_RVFI_DII_Execution_Packet_Ext_Integer(zeros());
  // magic = "int-data" -> 0x617461642d746e69 (big-endian)
  rvfi_int_data = update_magic(rvfi_int_data, 0x617461642d746e69);
  rvfi_int_data_present = false;
  rvfi_mem_data = Mk_RVFI_DII_Execution_Packet_Ext_MemAccess(zeros());
  // magic = "mem-data" -> 0x617461642d6d656d (big-endian)
  rvfi_mem_data = update_magic(rvfi_mem_data, 0x617461642d6d656d);
  rvfi_mem_data_present = false;
}

// FIXME: most of these will no longer be necessary once we use the c2 sail backend.

val rvfi_halt_exec_packet : unit -> unit

function rvfi_halt_exec_packet () =
  rvfi_inst_data[rvfi_halt] = 0x01

val rvfi_get_int_data : unit -> bits(320)
function rvfi_get_int_data () = {
  assert(rvfi_int_data_present, "reading uninitialized data");
  return rvfi_int_data.bits;
}

val rvfi_get_mem_data : unit -> bits(704)
function rvfi_get_mem_data () = {
  assert(rvfi_mem_data_present, "reading uninitialized data");
  return rvfi_mem_data.bits;
}

val rvfi_encode_width_mask : forall 'n, 0 < 'n <= 32. int('n) -> bits(32)

function rvfi_encode_width_mask(width) =
  (0xFFFFFFFF >> (32 - width))

val print_rvfi_exec : unit -> unit

function print_rvfi_exec () = {
  print_bits("rvfi_intr     : ", rvfi_inst_data[rvfi_intr]);
  print_bits("rvfi_halt     : ", rvfi_inst_data[rvfi_halt]);
  print_bits("rvfi_trap     : ", rvfi_inst_data[rvfi_trap]);
  print_bits("rvfi_rd_addr  : ", rvfi_int_data[rvfi_rd_addr]);
  print_bits("rvfi_rs2_addr : ", rvfi_int_data[rvfi_rs2_addr]);
  print_bits("rvfi_rs1_addr : ", rvfi_int_data[rvfi_rs1_addr]);
  print_bits("rvfi_mem_wmask: ", rvfi_mem_data[rvfi_mem_wmask]);
  print_bits("rvfi_mem_rmask: ", rvfi_mem_data[rvfi_mem_rmask]);
  print_bits("rvfi_mem_wdata: ", rvfi_mem_data[rvfi_mem_wdata]);
  print_bits("rvfi_mem_rdata: ", rvfi_mem_data[rvfi_mem_rdata]);
  print_bits("rvfi_mem_addr : ", rvfi_mem_data[rvfi_mem_addr]);
  print_bits("rvfi_rd_wdata : ", rvfi_int_data[rvfi_rd_wdata]);
  print_bits("rvfi_rs2_data : ", rvfi_int_data[rvfi_rs2_rdata]);
  print_bits("rvfi_rs1_data : ", rvfi_int_data[rvfi_rs1_rdata]);
  print_bits("rvfi_insn     : ", rvfi_inst_data[rvfi_insn]);
  print_bits("rvfi_pc_wdata : ", rvfi_pc_data[rvfi_pc_wdata]);
  print_bits("rvfi_pc_rdata : ", rvfi_pc_data[rvfi_pc_rdata]);
  print_bits("rvfi_order    : ", rvfi_inst_data[rvfi_order]);
}

// RVFI records
val rvfi_write : forall 'n, 0 < 'n <= max_mem_access . (xlenbits, int('n), bits(8 * 'n)) -> unit
function rvfi_write (paddr, width, value) = {
  rvfi_mem_data[rvfi_mem_addr] = zero_extend(paddr);
  rvfi_mem_data_present = true;
  if width <= 16 then {
    // TODO: report tag bit for capability writes and extend mask by one bit.
    rvfi_mem_data[rvfi_mem_wdata] = sail_zero_extend(value, 256);
    rvfi_mem_data[rvfi_mem_wmask] = rvfi_encode_width_mask(width);
  } else {
    internal_error(__FILE__, __LINE__, "Expected at most 16 bytes here!");
  };
}

val rvfi_read : forall 'n, 'n > 0. (xlenbits, int('n), bits(8 * 'n)) -> unit
function rvfi_read (paddr, width, value) = {
  rvfi_mem_data[rvfi_mem_addr] = zero_extend(paddr);
  rvfi_mem_data_present = true;
  if width <= 16 then {
    // TODO: report tag bit for capability writes and extend mask by one bit.
    rvfi_mem_data[rvfi_mem_rdata] = sail_zero_extend(value, 256);
    rvfi_mem_data[rvfi_mem_rmask] = rvfi_encode_width_mask(width)
  } else {
    internal_error(__FILE__, __LINE__, "Expected at most 16 bytes here!")
  };
}

val rvfi_mem_exception : xlenbits -> unit
function rvfi_mem_exception (paddr) = {
  // Log only the memory address (without the value) if the write fails.
  rvfi_mem_data[rvfi_mem_addr] = zero_extend(paddr);
  rvfi_mem_data_present = true;
}

val rvfi_wX : forall 'n, 0 <= 'n < 32. (int('n), xlenbits) -> unit
function rvfi_wX (r,v) = {
  rvfi_int_data[rvfi_rd_wdata] = zero_extend(v);
  rvfi_int_data[rvfi_rd_addr] = to_bits(8, r);
  rvfi_int_data_present = true;
}

val rvfi_trap : unit -> unit
function rvfi_trap () =
  rvfi_inst_data[rvfi_trap] = 0x01
