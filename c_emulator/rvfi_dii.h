#pragma once

#include "sail.h"

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

private:
  void get_and_send_packet(packet_reader_fn reader, bool config_print);

  unsigned trace_version = 1;
  int dii_port = -1;
  int dii_sock = -1;
};
