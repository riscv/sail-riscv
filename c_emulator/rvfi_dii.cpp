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

rvfi_handler::rvfi_handler(int port, model::Model &model)
    : dii_port(port)
    , m_model(model)
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
  dii_sock = accept(listen_sock, NULL, NULL);
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

void rvfi_handler::get_and_send_packet(packet_reader_fn reader,
                                       bool config_print)
{
  lbits packet;
  CREATE(lbits)(&packet);
  (m_model.*reader)(&packet, UNIT);
  /* Note: packet.len is the size in bits, not bytes. */
  if (packet.len % 8 != 0) {
    fprintf(stderr, "RVFI-DII trace packet not byte aligned: %d\n",
            (int)packet.len);
    exit(EXIT_FAILURE);
  }
  const size_t send_size = packet.len / 8;
  if (config_print) {
    print_bits("packet = ", packet);
    fprintf(stderr, "Sending packet with length %zd... ", send_size);
  }
  if (send_size > 4096) {
    fprintf(stderr, "Unexpected large packet size (> 4KB): %zd\n", send_size);
    exit(EXIT_FAILURE);
  }
  /* mpz_export might not write all of the null bytes */
  std::vector<unsigned char> bytes(send_size, 0);
  mpz_export(bytes.data(), NULL, -1, 1, 0, 0, *(packet.bits));
  /* Ensure that we can send a full packet */
  if (write(dii_sock, bytes.data(), send_size) != send_size) {
    fprintf(stderr, "Writing RVFI DII trace failed: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
  }
  if (config_print) {
    fprintf(stderr, "Wrote %zd byte response to socket.\n", send_size);
  }
  KILL(lbits)(&packet);
}

void rvfi_handler::send_trace(bool config_print)
{
  if (config_print) {
    fprintf(stderr, "Sending v%d trace response...\n", trace_version);
  }
  if (trace_version == 1) {
    get_and_send_packet(&model::Model::zrvfi_get_exec_packet_v1, config_print);
  } else if (trace_version == 2) {
    get_and_send_packet(&model::Model::zrvfi_get_exec_packet_v2, config_print);
    if (m_model.zrvfi_int_data_present)
      get_and_send_packet(&model::Model::zrvfi_get_int_data, config_print);
    if (m_model.zrvfi_mem_data_present)
      get_and_send_packet(&model::Model::zrvfi_get_mem_data, config_print);
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
  if (config_print) {
    fprintf(stderr, "Read cmd packet: %016jx\n", (intmax_t)instr_bits);
    m_model.zprint_instr_packet(instr_bits);
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
  m_model.zrvfi_set_instr_packet(instr_bits);
  m_model.zrvfi_zzero_exec_packet(UNIT);
  mach_bits cmd = m_model.zrvfi_get_cmd(UNIT);
  switch (cmd) {
  case 0: { /* EndOfTrace */
    if (config_print) {
      fprintf(stderr, "Got EndOfTrace packet.\n");
    }
    mach_bits insn = m_model.zrvfi_get_insn(UNIT);
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
      get_and_send_packet(&model::Model::zrvfi_get_v2_support_packet,
                          config_print);
      return RVFI_prestep_continue;
    } else {
      m_model.zrvfi_halt_exec_packet(UNIT);
      send_trace(trace_version);
      return RVFI_prestep_end_trace;
    }
  }
  case 1: /* Instruction */
    break;
  case 'v': { /* Set wire format version */
    mach_bits insn = m_model.zrvfi_get_insn(UNIT);
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
