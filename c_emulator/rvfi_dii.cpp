#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <fcntl.h>
#include <string.h>
#include <vector>

#include "sail.h"
#include "rvfi_dii.h"
#include "sail_utils.h"

// ****************************************************************************
// Struct Member Functions

RVFI_DII_Instruction_Packet
RVFI_DII_Instruction_Packet::from_u64(uint64_t value)
{
  return RVFI_DII_Instruction_Packet {
      .rvfi_insn = static_cast<uint32_t>(value),
      .rvfi_time = static_cast<uint16_t>(value >> 32),
      .rvfi_cmd = static_cast<uint8_t>(value >> 48),
      .padding = static_cast<uint8_t>(value >> 56),
  };
}

RVFI_DII_Execution_Packet_V1
RVFI_DII_Execution_Packet_V1::rvfi_get_v2_support_packet()
{
  // Returning 0x3 (using the unused high bits) in halt instead of 0x1 means
  // that we support the version 2 wire format. This is required to keep
  // backwards compatibility with old implementations that do not support
  // the new trace format.
  return RVFI_DII_Execution_Packet_V1 {
      .rvfi_halt = 0x03,
  };
}

// ****************************************************************************
// RVFI Handler Implementation

RVFI_DII_Execution_Packet_V1 rvfi_handler::rvfi_get_exec_packet_v1()
{
  return RVFI_DII_Execution_Packet_V1 {
      .rvfi_order = rvfi_inst_data.rvfi_order,
      .rvfi_pc_rdata = rvfi_pc_data.rvfi_pc_rdata,
      .rvfi_pc_wdata = rvfi_pc_data.rvfi_pc_wdata,
      .rvfi_insn = rvfi_inst_data.rvfi_insn,

      .rvfi_rs1_data = rvfi_int_data.rvfi_rs1_rdata,
      .rvfi_rs2_data = rvfi_int_data.rvfi_rs2_rdata,
      .rvfi_rd_wdata = rvfi_int_data.rvfi_rd_wdata,

      .rvfi_mem_addr = rvfi_mem_data.rvfi_mem_addr,
      .rvfi_mem_rdata = rvfi_mem_data.rvfi_mem_rdata[0],
      .rvfi_mem_wdata = rvfi_mem_data.rvfi_mem_wdata[0],
      .rvfi_mem_rmask = uint8_t(rvfi_mem_data.rvfi_mem_rmask),
      .rvfi_mem_wmask = uint8_t(rvfi_mem_data.rvfi_mem_wmask),

      .rvfi_rs1_addr = rvfi_int_data.rvfi_rs1_addr,
      .rvfi_rs2_addr = rvfi_int_data.rvfi_rs2_addr,
      .rvfi_rd_addr = rvfi_int_data.rvfi_rd_addr,

      .rvfi_trap = rvfi_inst_data.rvfi_trap,
      .rvfi_halt = rvfi_inst_data.rvfi_halt,
      .rvfi_intr = rvfi_inst_data.rvfi_intr,
  };
}

uint64_t rvfi_handler::rvfi_get_v2_trace_size()
{
  uint64_t trace_size = sizeof(RVFI_DII_Execution_Packet_V2);
  if (rvfi_int_data_present) {
    trace_size += sizeof(RVFI_DII_Execution_Packet_Ext_Integer);
  }
  if (rvfi_mem_data_present) {
    trace_size += sizeof(RVFI_DII_Execution_Packet_Ext_MemAccess);
  }
  return trace_size;
}

RVFI_DII_Execution_Packet_V2 rvfi_handler::rvfi_get_exec_packet_v2()
{
  uint64_t available_fields = 0;
  if (rvfi_int_data_present) {
    available_fields |= RVFI_INTEGER_DATA;
  }
  if (rvfi_mem_data_present) {
    available_fields |= RVFI_MEM_DATA;
  }
  return RVFI_DII_Execution_Packet_V2 {
      .trace_size = rvfi_get_v2_trace_size(),
      .basic_data = rvfi_inst_data,
      .pc_data = rvfi_pc_data,
      .available_fields = available_fields,
  };
}

void rvfi_handler::rvfi_zero_exec_packet()
{
  rvfi_inst_data = {};
  rvfi_pc_data = {};
  rvfi_int_data = {};
  rvfi_mem_data = {};
  rvfi_int_data_present = false;
  rvfi_mem_data_present = false;
}

void rvfi_handler::rvfi_halt_exec_packet()
{
  rvfi_inst_data.rvfi_halt = 0x01;
}

void rvfi_handler::print_rvfi_exec()
{
  printf("rvfi_intr      : 0x%" PRIX8 "\n", rvfi_inst_data.rvfi_intr);
  printf("rvfi_halt      : 0x%" PRIX8 "\n", rvfi_inst_data.rvfi_halt);
  printf("rvfi_trap      : 0x%" PRIX8 "\n", rvfi_inst_data.rvfi_trap);
  printf("rvfi_rd_addr   : 0x%" PRIX8 "\n", rvfi_int_data.rvfi_rd_addr);
  printf("rvfi_rs2_addr  : 0x%" PRIX8 "\n", rvfi_int_data.rvfi_rs2_addr);
  printf("rvfi_rs1_addr  : 0x%" PRIX8 "\n", rvfi_int_data.rvfi_rs1_addr);
  printf("rvfi_mem_wmask : 0x%" PRIX32 "\n", rvfi_mem_data.rvfi_mem_wmask);
  printf("rvfi_mem_rmask : 0x%" PRIX32 "\n", rvfi_mem_data.rvfi_mem_rmask);
  print_bits("rvfi_mem_wdata 0x: ", make_lbits(rvfi_mem_data.rvfi_mem_wdata));
  print_bits("rvfi_mem_rdata 0x: ", make_lbits(rvfi_mem_data.rvfi_mem_rdata));
  printf("rvfi_mem_addr  : 0x%" PRIX64 "\n", rvfi_mem_data.rvfi_mem_addr);
  printf("rvfi_rd_wdata  : 0x%" PRIX64 "\n", rvfi_int_data.rvfi_rd_wdata);
  printf("rvfi_rs2_data  : 0x%" PRIX64 "\n", rvfi_int_data.rvfi_rs2_rdata);
  printf("rvfi_rs1_data  : 0x%" PRIX64 "\n", rvfi_int_data.rvfi_rs1_rdata);
  printf("rvfi_insn      : 0x%" PRIX64 "\n", rvfi_inst_data.rvfi_insn);
  printf("rvfi_pc_wdata  : 0x%" PRIX64 "\n", rvfi_pc_data.rvfi_pc_wdata);
  printf("rvfi_pc_rdata  : 0x%" PRIX64 "\n", rvfi_pc_data.rvfi_pc_rdata);
  printf("rvfi_order     : 0x%" PRIX64 "\n", rvfi_inst_data.rvfi_order);
}

void print_instr_packet(RVFI_DII_Instruction_Packet p)
{
  printf("command        : 0x%" PRIX8 "\n", p.rvfi_cmd);
  printf("instruction    : 0x%" PRIX32 "\n", p.rvfi_insn);
}

// ****************************************************************************
// RVFI Handler

#define UNUSED(var) (void)(var)

rvfi_handler::rvfi_handler(int port)
    : dii_port(port)
{
  fprintf(stderr, "using %d as RVFI port.\n", port);
}

uint64_t rvfi_handler::get_entry()
{
  return 0x80000000;
}

// returns zero on success
bool rvfi_handler::setup_socket(bool config_print)
{
  int listen_sock = socket(AF_INET, SOCK_STREAM, 0);
  if (listen_sock == -1) {
    fprintf(stderr, "Unable to create socket: %s\n", strerror(errno));
    return false;
  }
  int reuseaddr = 1;
  if (setsockopt(listen_sock, SOL_SOCKET, SO_REUSEADDR, &reuseaddr,
                 sizeof(reuseaddr))
      == -1) {
    fprintf(stderr, "Unable to set reuseaddr on socket: %s\n", strerror(errno));
    return false;
  }
  struct sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  addr.sin_port = htons(dii_port);
  if (bind(listen_sock, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
    fprintf(stderr, "Unable to set bind socket: %s\n", strerror(errno));
    return false;
  }
  if (listen(listen_sock, 1) == -1) {
    fprintf(stderr, "Unable to listen on socket: %s\n", strerror(errno));
    return false;
  }
  socklen_t addrlen = sizeof(addr);
  if (getsockname(listen_sock, (struct sockaddr *)&addr, &addrlen) == -1) {
    fprintf(stderr, "Unable to getsockname() on socket: %s\n", strerror(errno));
    return false;
  }
  printf("Waiting for connection on port %d.\n", ntohs(addr.sin_port));
  dii_sock = accept(listen_sock, nullptr, nullptr);
  if (dii_sock == -1) {
    fprintf(stderr, "Unable to accept connection on socket: %s\n",
            strerror(errno));
    return false;
  }
  close(listen_sock);
  // Ensure that the socket is blocking
  int fd_flags = fcntl(dii_sock, F_GETFL);
  if (fd_flags == -1) {
    fprintf(stderr, "Failed to get file descriptor flags for socket!\n");
    return false;
  }
  if (config_print) {
    fprintf(stderr, "RVFI socket fd flags=%d, nonblocking=%d\n", fd_flags,
            (fd_flags & O_NONBLOCK) != 0);
  }
  if (fd_flags & O_NONBLOCK) {
    fprintf(stderr, "Socket was non-blocking, this will not work!\n");
    return false;
  }
  printf("Connected\n");
  return true;
}

template <typename T>
void rvfi_handler::send_packet(const T &data, bool config_print)
{
  const size_t send_size = sizeof(T);
  if (config_print) {
    print_raw_as_hex("packet = ", data);
    fprintf(stderr, "Sending packet with length %zd... ", send_size);
  }
  if (send_size > 4096) {
    fprintf(stderr, "Unexpected large packet size (> 4KB): %zd\n", send_size);
    exit(EXIT_FAILURE);
  }
  if (write(dii_sock, &data, send_size) != send_size) {
    fprintf(stderr, "Writing RVFI DII trace failed: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }
  if (config_print) {
    fprintf(stderr, "Wrote %zd byte response to socket.\n", send_size);
  }
}

void rvfi_handler::send_trace(bool config_print)
{
  if (config_print) {
    fprintf(stderr, "Sending v%d trace response...\n", trace_version);
  }
  if (trace_version == 1) {
    send_packet(rvfi_get_exec_packet_v1(), config_print);
  } else if (trace_version == 2) {
    send_packet(rvfi_get_exec_packet_v2(), config_print);
    if (rvfi_int_data_present) {
      send_packet(rvfi_int_data, config_print);
    }
    if (rvfi_mem_data_present) {
      send_packet(rvfi_mem_data, config_print);
    }
  } else {
    fprintf(stderr, "Sending v%d packets not implemented yet!\n",
            trace_version);
    abort();
  }
}

rvfi_prestep_t rvfi_handler::pre_step(bool config_print)
{
  mach_bits instr_bits;
  if (config_print) {
    fprintf(stderr, "Waiting for cmd packet... ");
  }
  int res = read(dii_sock, &instr_bits, sizeof(instr_bits));
  rvfi_instruction = RVFI_DII_Instruction_Packet::from_u64(instr_bits);
  if (config_print) {
    fprintf(stderr, "Read cmd packet: %016jx\n", (intmax_t)instr_bits);
    print_instr_packet(rvfi_instruction);
  }
  if (res == 0) {
    if (config_print) {
      fprintf(stderr, "Got EOF, exiting... ");
    }
    return RVFI_prestep_eof;
  }
  if (res == -1) {
    fprintf(stderr, "Reading RVFI DII command failed: %s", strerror(errno));
    exit(EXIT_FAILURE);
  }
  if (res < sizeof(instr_bits)) {
    fprintf(stderr, "Reading RVFI DII command failed: insufficient input");
    exit(EXIT_FAILURE);
  }
  rvfi_zero_exec_packet();
  mach_bits cmd = rvfi_instruction.rvfi_cmd;
  switch (cmd) {
  case 0: { /* EndOfTrace */
    if (config_print) {
      fprintf(stderr, "Got EndOfTrace packet.\n");
    }
    mach_bits insn = rvfi_instruction.rvfi_insn;
    if (insn == (('V' << 24) | ('E' << 16) | ('R' << 8) | 'S')) {
      /*
       * Reset with insn set to 'VERS' is a version negotiation request
       * and not a actual reset request. Respond with a message say that
       * we support version 2.
       */
      if (config_print) {
        fprintf(stderr,
                "EndOfTrace was actually a version negotiation packet.\n");
      }
      send_packet(RVFI_DII_Execution_Packet_V1::rvfi_get_v2_support_packet(),
                  config_print);
      return RVFI_prestep_continue;
    } else {
      rvfi_halt_exec_packet();
      send_trace(trace_version);
      return RVFI_prestep_end_trace;
    }
  }
  case 1: /* Instruction */
    break;
  case 'v': { /* Set wire format version */
    mach_bits insn = rvfi_instruction.rvfi_insn;
    if (config_print) {
      fprintf(stderr, "Got request for v%jd trace format!\n", (intmax_t)insn);
    }
    if (insn == 1) {
      fprintf(stderr, "Requested trace in legacy format!\n");
    } else if (insn == 2) {
      fprintf(stderr, "Requested trace in v2 format!\n");
    } else {
      fprintf(stderr, "Requested trace in unsupported format %jd!\n",
              (intmax_t)insn);
      exit(EXIT_FAILURE);
    }
    // From now on send traces in the requested format
    trace_version = insn;
    struct {
      char msg[8];
      uint64_t version;
    } version_response = {
        {'v', 'e', 'r', 's', 'i', 'o', 'n', '='},
        trace_version
    };
    if (write(dii_sock, &version_response, sizeof(version_response))
        != sizeof(version_response)) {
      fprintf(stderr, "Sending version response failed: %s\n", strerror(errno));
      exit(EXIT_FAILURE);
    }
    return RVFI_prestep_continue;
  }
  default:
    fprintf(stderr, "Unknown RVFI-DII command: %#02x\n", (int)cmd);
    exit(EXIT_FAILURE);
  }
  return RVFI_prestep_ok;
}

// ***************************************************************************
// Callbacks API

uint32_t rvfi_encode_width_mask(uint8_t width)
{
  return (0xFFFFFFFF >> (32 - width));
}

void rvfi_handler::mem_write_callback(const char *, sbits paddr, uint64_t width,
                                      lbits value)
{
  rvfi_mem_data.rvfi_mem_addr = paddr.bits;
  rvfi_mem_data_present = true;
  if (width <= 16) {
    // TODO: report tag bit for capability writes and extend mask by one bit.
    // */
    rvfi_mem_data.clear_wdata();
    convert_lbits_to_u8s(value, rvfi_mem_data.rvfi_mem_wdata,
                         sizeof(rvfi_mem_data.rvfi_mem_wdata));
    rvfi_mem_data.rvfi_mem_wmask = rvfi_encode_width_mask(width);
  } else {
    fprintf(stderr, "Expected at most 16 bytes here!\n");
    exit(EXIT_FAILURE);
  }
}

void rvfi_handler::mem_read_callback(const char *, sbits paddr, uint64_t width,
                                     lbits value)
{
  rvfi_mem_data.rvfi_mem_addr = paddr.bits;
  rvfi_mem_data_present = true;
  if (width <= 16) {
    // TODO: report tag bit for capability writes and extend mask by one bit.
    rvfi_mem_data.clear_rdata();
    convert_lbits_to_u8s(value, rvfi_mem_data.rvfi_mem_rdata,
                         sizeof(rvfi_mem_data.rvfi_mem_rdata));
    rvfi_mem_data.rvfi_mem_rmask = rvfi_encode_width_mask(width);
  } else {
    fprintf(stderr, "Expected at most 16 bytes here!\n");
    exit(EXIT_FAILURE);
  }
}

void rvfi_handler::mem_exception_callback(sbits paddr, uint64_t)
{
  /* Log only the memory address (without the value) if the write fails. */
  rvfi_mem_data.rvfi_mem_addr = paddr.bits;
  rvfi_mem_data_present = true;
}

void rvfi_handler::xreg_full_write_callback(const_sail_string, sbits reg,
                                            sbits value)
{
  rvfi_int_data.rvfi_rd_wdata = value.bits;
  rvfi_int_data.rvfi_rd_addr = reg.bits;
  rvfi_int_data_present = true;
}

void rvfi_handler::freg_write_callback(unsigned, sbits) { }

void rvfi_handler::csr_full_write_callback(const_sail_string, unsigned, sbits)
{
}

void rvfi_handler::csr_full_read_callback(const_sail_string, unsigned, sbits) {
}

void rvfi_handler::vreg_write_callback(unsigned, lbits) { }

void rvfi_handler::pc_write_callback(sbits) { }

void rvfi_handler::trap_callback()
{
  rvfi_inst_data.rvfi_trap = 0x01;
}

// ***************************************************************************
// Sail API

void rvfi_handler::rvfi_set_inst_data_insn(uint64_t insn)
{
  rvfi_inst_data.rvfi_insn = insn;
}

void rvfi_handler::rvfi_set_inst_data_order(uint64_t order)
{
  rvfi_inst_data.rvfi_order = order;
}

void rvfi_handler::rvfi_set_inst_data_mode(uint8_t mode)
{
  rvfi_inst_data.rvfi_mode = mode;
}

void rvfi_handler::rvfi_set_inst_data_ixl(uint8_t ixl)
{
  rvfi_inst_data.rvfi_ixl = ixl;
}

uint32_t rvfi_handler::rvfi_get_insn()
{
  return rvfi_instruction.rvfi_insn;
}

void rvfi_handler::rvfi_set_pc_data_rdata(uint64_t rdata)
{
  rvfi_pc_data.rvfi_pc_rdata = rdata;
}

void rvfi_handler::rvfi_set_pc_data_wdata(uint64_t wdata)
{
  rvfi_pc_data.rvfi_pc_wdata = wdata;
}
