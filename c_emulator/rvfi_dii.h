#pragma once

#include "sail.h"
#include "string.h"

// "RISC-V Formal Interface - Direct Instruction Injection" support
// For use with https://github.com/CTSRD-CHERI/TestRIG

// ****************************************************************************

struct RVFI_DII_Instruction_Packet {
  // 31 ..  0, Instruction word: 32-bit instruction or command.
  // The lower 16-bits may decode to a 16-bit compressed instruction.
  uint32_t rvfi_insn = 0;
  // 47 .. 32, Time to inject token.
  // The difference between this and the previous instruction time gives a delay
  // before injecting this instruction. This can be ignored for models but gives
  // repeatability for implementations while shortening counterexamples.
  uint16_t rvfi_time = 0;
  // 55 .. 48, This token is a trace command.
  // For example, reset device under test.
  uint8_t rvfi_cmd = 0;
  // 63 .. 56
  uint8_t padding = 0;

  static RVFI_DII_Instruction_Packet from_u64(uint64_t value);
};

struct RVFI_DII_Execution_Packet_InstMetadata {
  // 63 .. 0, The rvfi_order field must be set to the instruction index. No
  // indices must be used twice and there must be no gaps. Instructions may be
  // retired in a reordered fashion, as long as causality is preserved
  // (register and memory write operations must be retired before the read
  // operations that depend on them).
  uint64_t rvfi_order = 0;
  // 127 .. 64, rvfi_insn is the instruction word for the retired instruction.
  // In case of an instruction with fewer than ILEN bits, the upper bits of this
  // output must be all zero. For compressed instructions the compressed
  // instruction word must be output on this port. For fused instructions the
  // complete fused instruction sequence must be output.
  uint64_t rvfi_insn = 0;
  // 135 .. 128, rvfi_trap must be set for an instruction that cannot be
  // decoded as a legal instruction, such as 0x00000000. In addition, rvfi_trap
  // must be set for a misaligned memory read or write in PMAs that don't allow
  // misaligned access, or other memory access violations. rvfi_trap must also
  // be set for a jump instruction that jumps to a misaligned instruction.
  uint8_t rvfi_trap = 0;
  // 143 .. 136, The signal rvfi_halt must be set when the instruction is the
  // last instruction that the core retires before halting execution. It should
  // not be set for an instruction that triggers a trap condition if the CPU
  // reacts to the trap by executing a trap handler. This signal enables
  // verification of liveness properties.
  uint8_t rvfi_halt = 0;
  // 151 .. 144, rvfi_intr must be set for the first instruction that is part
  // of a trap handler, i.e. an instruction that has a rvfi_pc_rdata that does
  // not match the rvfi_pc_wdata of the previous instruction.
  uint8_t rvfi_intr = 0;
  // 159 .. 152, rvfi_mode must be set to the current privilege level, using
  // the following encoding: 0=U-Mode, 1=S-Mode, 2=Reserved, 3=M-Mode
  uint8_t rvfi_mode = 0;
  // 167 .. 160, rvfi_ixl must be set to the value of MXL/SXL/UXL in the
  // current privilege level, using the following encoding: 1=32, 2=64
  uint8_t rvfi_ixl = 0;
  // 175 .. 168, When the core retires an instruction, it asserts the
  // rvfi_valid signal and uses the signals described below to output the
  // details of the retired instruction. The signals below are only valid during
  // such a cycle and can be driven to arbitrary values in a cycle in which
  // rvfi_valid is not asserted.
  uint8_t rvfi_valid = 0;
  // 191 .. 176, Note: since we only send these packets in the valid state, we
  // could omit the valid signal, but we need 3 bytes of padding after ixl
  // anyway so we might as well include it.
  uint16_t padding = 0;
};

typedef struct {
  // This is the program counter (pc) before (rvfi_pc_rdata) and after
  // (rvfi_pc_wdata) execution of this instruction. I.e. this is the address
  // of the retired instruction and the address of the next instruction.
  uint64_t rvfi_pc_rdata = 0; // 63 .. 0
  uint64_t rvfi_pc_wdata = 0; // 127 .. 64
} RVFI_DII_Execution_Packet_PC;

#define MAGIC_INT_DATA {'i', 'n', 't', '-', 'd', 'a', 't', 'a'}

struct RVFI_DII_Execution_Packet_Ext_Integer {
  // 63 .. 0, must be "int-data"
  // rvfi_rd_wdata is the value of the x register addressed by rd after
  // execution of this instruction. This output must be zero when rd is zero.
  char magic[8] = MAGIC_INT_DATA;
  // 127 ..  64
  uint64_t rvfi_rd_wdata = 0;
  // rvfi_rs1_rdata/rvfi_rs2_rdata is the value of the x register addressed
  // by rs1/rs2 before execution of this instruction. This output must be
  // zero when rs1/rs2 is zero.
  uint64_t rvfi_rs1_rdata = 0; // 191 .. 128
  uint64_t rvfi_rs2_rdata = 0; // 255 .. 192
  // 263 .. 256, rvfi_rd_addr is the decoded rd register address for the retired
  // instruction. For an instruction that writes no rd register, this output
  // must always be zero.
  uint8_t rvfi_rd_addr = 0;
  // rvfi_rs1_addr and rvfi_rs2_addr are the decoded rs1 and rs1 register
  // addresses for the retired instruction.
  // For an instruction that reads no rs1/rs2 register, this output can have an
  // arbitrary value. However, if this output is nonzero then rvfi_rs1_rdata
  // must carry the value stored in that register in the pre-state.
  uint8_t rvfi_rs1_addr = 0; // 271 .. 264
  uint8_t rvfi_rs2_addr = 0; // 279 .. 272
  uint8_t padding[5] = {};
};

#define MAGIC_MEM_DATA {'m', 'e', 'm', '-', 'd', 'a', 't', 'a'}

struct RVFI_DII_Execution_Packet_Ext_MemAccess {
  // 63 .. 0, magic must be "mem-data"
  char magic[8] = MAGIC_MEM_DATA;
  // 319 ..  64
  // rvfi_mem_rdata is the pre-state data read from rvfi_mem_addr.
  // rvfi_mem_rmask specifies which bytes are valid.
  // CHERI-extension: widened to 32 bytes to allow reporting 129 bits
  uint64_t rvfi_mem_rdata[4] = {};
  // 575 .. 320
  // rvfi_mem_wdata is the post-state data written to rvfi_mem_addr.
  // rvfi_mem_wmask specifies which bytes are valid.
  // CHERI-extension: widened to 32 bytes to allow reporting 129 bits
  uint64_t rvfi_mem_wdata[4] = {};
  // 607 .. 576
  // rvfi_mem_rmask is a bitmask that specifies which bytes in rvfi_mem_rdata
  // contain valid read data from rvfi_mem_addr.
  // CHERI-extension: we extend rmask+wmask to 32 bits to allow reporting the
  // mask for CHERI/RV128 accesses here.
  uint32_t rvfi_mem_rmask = 0;
  // 639 .. 608
  // rvfi_mem_wmask is a bitmask that specifies which bytes in rvfi_mem_wdata
  // contain valid data that is written to rvfi_mem_addr.
  // CHERI-extension: widened to 32 bits
  uint32_t rvfi_mem_wmask = 0;
  // 703 .. 640
  // For memory operations (rvfi_mem_rmask and/or rvfi_mem_wmask are non-zero),
  // rvfi_mem_addr holds the accessed memory location.
  uint64_t rvfi_mem_addr = 0;

  void clear_rdata()
  {
    memset(rvfi_mem_rdata, 0, sizeof(rvfi_mem_rdata));
  }

  void clear_wdata()
  {
    memset(rvfi_mem_wdata, 0, sizeof(rvfi_mem_wdata));
  }
};

// ****************************************************************************

struct RVFI_DII_Execution_Packet_V1 {
  // [00 - 07] Instruction number: INSTRET value after completion.
  uint64_t rvfi_order = 0;
  // [08 - 15] PC before instr: PC for current instruction.
  uint64_t rvfi_pc_rdata = 0;
  // [16 - 23] PC after instr: Following PC - either PC + 4 or
  // jump/trap target.
  uint64_t rvfi_pc_wdata = 0;
  // [24 - 31] Instruction word: 32-bit command value.
  uint64_t rvfi_insn = 0;
  // [32 - 39] Read register values: Values as read from registers named.
  uint64_t rvfi_rs1_data = 0;
  // [40 - 47] above. Must be 0 if register ID is 0. 0 if unused.
  uint64_t rvfi_rs2_data = 0;
  // [48 - 55] Write register value: MUST be 0 if rd_ is 0.
  uint64_t rvfi_rd_wdata = 0;
  // [56 - 63] Memory access addr: Points to byte address (aligned if define.
  uint64_t rvfi_mem_addr = 0;
  // [64 - 71] Read data: Data read from mem_addr (i.e. before write).
  uint64_t rvfi_mem_rdata = 0;
  // [72 - 79] Write data: Data written to memory by this command.
  uint64_t rvfi_mem_wdata = 0;
  // [80] Read mask: Indicates valid bytes read. 0 if unused.
  uint8_t rvfi_mem_rmask = 0;
  // [81] Write mask: Indicates valid bytes written. 0 if unused.
  uint8_t rvfi_mem_wmask = 0;
  // [82] Read register addresses: Can be arbitrary when not used.
  uint8_t rvfi_rs1_addr = 0;
  // [83] otherwise set as decoded.
  uint8_t rvfi_rs2_addr = 0;
  // [84] Write register address: MUST be 0 if not used.
  uint8_t rvfi_rd_addr = 0;
  // [85] Trap indicator: Invalid decode, misaligned access or  misaligned
  // address.
  uint8_t rvfi_trap = 0;
  // [86] Halt indicator: Marks the last instruction retired before halting
  // execution.
  uint8_t rvfi_halt = 0;
  // [87] Trap handler: Set for first instruction in trap handler.
  uint8_t rvfi_intr = 0;

  static RVFI_DII_Execution_Packet_V1 rvfi_get_v2_support_packet();
};

#define MAGIC_TRACE_V2 {'t', 'r', 'a', 'c', 'e', '-', 'v', '2'}

struct RVFI_DII_Execution_Packet_V2 {
  // 63 .. 0, must be set to 'trace-v2'
  char magic[8] = MAGIC_TRACE_V2;
  // 127 .. 64, total size of the trace packet + extensions
  uint64_t trace_size = 0;
  // 319 .. 128
  RVFI_DII_Execution_Packet_InstMetadata basic_data = {};
  // 447 .. 320
  RVFI_DII_Execution_Packet_PC pc_data = {};
  // 511 .. 448
  uint64_t available_fields = 0;
  // 448, Followed by RVFI_DII_Execution_Packet_Ext_Integer if set
  // integer_data_available
  // 449, Followed by RVFI_DII_Execution_Packet_Ext_MemAccess if set
  // memory_access_data_available
  // 450, Followed by RVFI_DII_Execution_Packet_Ext_FP if set
  // TODO: floating_point_data_available
  // 451, Followed by RVFI_DII_Execution_Packet_Ext_CSR if set
  // TODO: csr_read_write_data_available
  // 452, Followed by RVFI_DII_Execution_Packet_Ext_CHERI if set
  // TODO: cheri_data_available
  // 453, Followed by RVFI_DII_Execution_Packet_Ext_CHERI_SCR if set
  // TODO: cheri_scr_read_write_data_available
  // 454, Followed by RVFI_DII_Execution_Packet_Ext_Trap if set
  // TODO: trap_data_available
  // 511 .. 455, To be used for additional RVFI_DII_Execution_Packet_Ext_*
  // structs unused_data_available_fields
};

enum RVFI_DII_Execution_Available_Field {
  RVFI_INST_DATA = 0, // Must always be present
  RVFI_PC_DATA = 0,   // Must always be present
  RVFI_INTEGER_DATA = 1 << 0,
  RVFI_MEM_DATA = 1 << 1,
  RVFI_FP_DATA = 1 << 2,
  RVFI_CSR_DATA = 1 << 3,
  RVFI_CHERI_DATA = 1 << 4,
  RVFI_CHERI_SCR_DATA = 1 << 5,
  RVFI_CHERI_TRAP_DATA = 1 << 6,
};

// ****************************************************************************

enum rvfi_prestep_t {
  RVFI_prestep_continue,  // continue loop
  RVFI_prestep_eof,       // Got EOF, delete rvfi and return
  RVFI_prestep_end_trace, // Got EndOfTrace
  RVFI_prestep_ok,        // Ready for step
};

typedef void (*packet_reader_fn)(lbits *rop, unit);

class rvfi_handler {
public:
  explicit rvfi_handler(int port);

  bool setup_socket(bool config_print);
  uint64_t get_entry();
  void send_trace(bool config_print);
  rvfi_prestep_t pre_step(bool config_print);

  // Callback API
  static void rvfi_write(uint64_t paddr, uint64_t width, lbits value);
  static void rvfi_read(uint64_t paddr, uint64_t width, lbits value);
  static void rvfi_mem_exception(uint64_t paddr);
  static void rvfi_wX(unsigned r, uint64_t v);
  static void rvfi_trap();

  // Sail API
  static uint64_t rvfi_get_insn();
  static void rvfi_set_pc_data_rdata(uint64_t data);
  static void rvfi_set_pc_data_wdata(uint64_t data);
  static void rvfi_set_inst_data_insn(uint64_t insn);
  static void rvfi_set_inst_data_order(uint64_t);
  static void rvfi_set_inst_data_mode(uint8_t);
  static void rvfi_set_inst_data_ixl(uint8_t);

private:
  void get_and_send_packet(packet_reader_fn reader, bool config_print);
  template <typename T> void send_packet_raw(const T *data, bool config_print);

  RVFI_DII_Execution_Packet_V1 rvfi_get_exec_packet_v1();
  uint64_t rvfi_get_v2_trace_size();
  RVFI_DII_Execution_Packet_V2 rvfi_get_exec_packet_v2();
  void rvfi_zero_exec_packet();
  void rvfi_halt_exec_packet();
  void print_rvfi_exec();

  int dii_port = -1;
  int dii_sock = -1;

  // Trace States
  unsigned trace_version = 1;

  static RVFI_DII_Instruction_Packet rvfi_instruction;
  static RVFI_DII_Execution_Packet_PC rvfi_pc_data;
  static RVFI_DII_Execution_Packet_InstMetadata rvfi_inst_data;
  static RVFI_DII_Execution_Packet_Ext_Integer rvfi_int_data;
  static RVFI_DII_Execution_Packet_Ext_MemAccess rvfi_mem_data;
  static bool rvfi_mem_data_present;
  static bool rvfi_int_data_present;
};

void print_instr_packet(RVFI_DII_Instruction_Packet p);
