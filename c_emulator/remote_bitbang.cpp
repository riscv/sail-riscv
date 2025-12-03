/* This file is derived from Spike (https://github.com/riscv/riscv-isa-sim)
 * and has the following license:
 *
 * Copyright (c) 2010-2017, The Regents of the University of California
 * (Regents).  All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Regents nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * IN NO EVENT SHALL REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
 * SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS,
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
 * REGENTS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  REGENTS SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE. THE SOFTWARE AND ACCOMPANYING DOCUMENTATION, IF ANY, PROVIDED
 * HEREUNDER IS PROVIDED "AS IS". REGENTS HAS NO OBLIGATION TO PROVIDE
 * MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#include <cstdio>
#include <memory>
#include <stdexcept>
#include <string>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <arpa/inet.h>
#ifndef AF_INET
#include <sys/socket.h>
#endif
#ifndef INADDR_ANY
#include <netinet/in.h>
#endif

#include "sail_riscv_model.h"
#include "riscv_model_impl.h"
#include "jtag_dtm.h"
#include "remote_bitbang.h"
#include "config_utils.h"

remote_bitbang_t::remote_bitbang_t(uint16_t port, jtag_dtm_t *tap,
                                   int socket_fd)
    : port(port)
    , tap(tap)
    , socket_fd(socket_fd)
{
}

std::unique_ptr<remote_bitbang_t>
remote_bitbang_t::make(uint16_t port, uint64_t required_rti_cycles,
                       ModelImpl *model)
{
  // Create socket
  int socket_fd = socket(AF_INET, SOCK_STREAM, 0);
  if (socket_fd == -1) {
    throw std::runtime_error("remote_bitbang failed to create socket: "
                             + std::string(strerror(errno)) + " ("
                             + std::to_string(errno) + ")");
  }

  // Set reuse address
  int reuseaddr = 1;
  if (setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(int))
      == -1) {
    close(socket_fd);
    throw std::runtime_error("remote_bitbang failed setsockopt: "
                             + std::string(strerror(errno)) + " ("
                             + std::to_string(errno) + ")");
  }

  // Bind and listen
  sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons(port);

  if (bind(socket_fd, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
    close(socket_fd);
    throw std::runtime_error("remote_bitbang failed to bind socket: "
                             + std::string(strerror(errno)) + " ("
                             + std::to_string(errno) + ")");
  }

  if (listen(socket_fd, 1) == -1) {
    close(socket_fd);
    throw std::runtime_error("remote_bitbang failed to listen on socket: "
                             + std::string(strerror(errno)) + " ("
                             + std::to_string(errno) + ")");
  }

  // Get actual port
  socklen_t addrlen = sizeof(addr);
  if (getsockname(socket_fd, (struct sockaddr *)&addr, &addrlen) == -1) {
    close(socket_fd);
    throw std::runtime_error("remote_bitbang getsockname failed: "
                             + std::string(strerror(errno)) + " ("
                             + std::to_string(errno) + ")");
  }

  printf("Listening for remote bitbang connection on port %d.\n",
         ntohs(addr.sin_port));
  fflush(stdout);

  jtag_dtm_t *tap = new jtag_dtm_t(required_rti_cycles, model);
  return std::unique_ptr<remote_bitbang_t>(
      new remote_bitbang_t(port, tap, socket_fd));
}

void remote_bitbang_t::close_sockets()
{
  if (socket_fd != -1) {
    close(socket_fd);
  }
  if (client_fd != -1) {
    close(client_fd);
  }
}

remote_bitbang_t::~remote_bitbang_t()
{
  close_sockets();
  delete tap;
}

void remote_bitbang_t::accept_connection()
{
  client_fd = accept(socket_fd, NULL, NULL);
  if (client_fd == -1) {
    fprintf(stderr, "failed to accept on socket: %s (%d)\n", strerror(errno),
            errno);
    exit(EXIT_FAILURE);
  } else {
    fcntl(client_fd, F_SETFL, O_NONBLOCK);
  }
}

void remote_bitbang_t::tick()
{
  unsigned total_processed = 0;
  bool quit = false;
  bool in_rti = tap->state() == JtagState::RunTestIdle;
  bool entered_rti = false;
  while (1) {
    if (recv_start < recv_end) {
      unsigned send_offset = 0;
      while (recv_start < recv_end) {
        uint8_t command = recv_buf[recv_start];
        switch (command) {
        case 'B':
          break;
        case 'b':
          break;
        case 'r':
          tap->reset();
          break;
        case '0':
          tap->set_pins(0, 0, 0);
          break;
        case '1':
          tap->set_pins(0, 0, 1);
          break;
        case '2':
          tap->set_pins(0, 1, 0);
          break;
        case '3':
          tap->set_pins(0, 1, 1);
          break;
        case '4':
          tap->set_pins(1, 0, 0);
          break;
        case '5':
          tap->set_pins(1, 0, 1);
          break;
        case '6':
          tap->set_pins(1, 1, 0);
          break;
        case '7':
          tap->set_pins(1, 1, 1);
          break;
        case 'R':
          send_buf[send_offset++] = tap->tdo() ? '1' : '0';
          break;
        case 'Q':
          quit = true;
          break;
        default:
          fprintf(stderr, "remote_bitbang got unsupported command '%c'\n",
                  command);
        }
        recv_start++;
        total_processed++;
        if (!in_rti && tap->state() == JtagState::RunTestIdle) {
          entered_rti = true;
          break;
        }
        in_rti = false;
      }
      unsigned sent = 0;
      while (sent < send_offset) {
        ssize_t bytes = write(client_fd, send_buf.data() + sent, send_offset);
        if (bytes == -1) {
          fprintf(stderr, "failed to write to socket: %s (%d)\n",
                  strerror(errno), errno);
          exit(EXIT_FAILURE);
        }
        sent += bytes;
      }
    }

    if (total_processed > buf_size || quit || entered_rti) {
      // Don't go forever, because that could starve the main simulation.
      break;
    }

    recv_start = 0;
    recv_end = read(client_fd, recv_buf.data(), buf_size);

    if (recv_end == -1) {
      if (errno == EAGAIN) {
        break;
      } else {
        fprintf(stderr, "remote_bitbang failed to read on socket: %s (%d)\n",
                strerror(errno), errno);
        exit(EXIT_FAILURE);
      }
    }

    if (quit) {
      fprintf(stderr, "Remote Bitbang received 'Q'\n");
    }

    if (recv_end == 0 || quit) {
      // The remote disconnected.
      fprintf(stderr, "Received nothing. Quitting.\n");
      close(client_fd);
      client_fd = -1;
      break;
    }
  }
}

// This is called with an initialized Sail model for a reset hart with
// PC pointing at the ELF entry.
void remote_bitbang_t::run(uint64_t insn_limit)
{
  // Wait for OpenOCD to connect
  accept_connection();
  fprintf(stdout, "Accepted debug connection.\n");

  // TODO: Uncomment once Sdext is available
  // struct zstep_result step_result = {false, false, false, false};
  bool is_waiting = false;
  // bool exit_wait = true;

  // initialize the step number
  mach_int step_no = 0;
  uint64_t insn_cnt = 0;
  uint64_t total_insns = 0;

  uint64_t insns_per_tick
      = get_config_uint64({"platform", "instructions_per_tick"});
  uint64_t max_ticks_jtag
      = get_config_uint64({"platform", "debug_module", "max_ticks_jtag"});
  uint64_t max_ticks_sail
      = get_config_uint64({"platform", "debug_module", "max_ticks_sail"});
  // Run until either HTIF signals completion, the instruction limit
  // is reached, or the debugger closed the connection.
  while (!model->zhtif_done && (insn_limit == 0 || total_insns < insn_limit)
         && (client_fd > 0)) {
    // Advances the bit banging protocol and sends
    // data to the debugger (over OpenOCD) or reads from it
    {
      // Since OpenOCD could disconnect anytime in the loop,
      // ensure the socket is valid before calling `tick()`.
      for (int i = 0; i < max_ticks_jtag && client_fd > 0; i++) {
        tick();
      }
    }

    model->call_pre_step_callbacks(is_waiting);

    // run a Sail step
    {
      // NOTE: As it turned out, it can be quite beneficial to test different
      // frequency ratios between the JTAG module and the Sail model. The
      // default setting used to be 100 JTAG cycles per single Sail cycle, but
      // with that configuration, some interesting edge cases showed up, for
      // example, timeouts or burst read/write operations failing because
      // OpenOCD didn’t check between writes whether they actually succeeded. By
      // allowing users to adjust the relative speed of these two components,
      // different timing scenarios can be explored. The new default is 1:4, one
      // JTAG cycle followed by two Sail cycles, which is more realistic since
      // a real core would typically run faster than the JTAG module.
      // TODO: Changing these parameters can affect the outcome of certain
      // tests. The riscv-tests repository includes interrupt-based tests (such
      // as InterruptTest) that may fail if the hart runs too slowly compared to
      // the JTAG module.
      for (int i = 0; i < max_ticks_sail; i++) {
        sail_int sail_step;
        CREATE(sail_int)(&sail_step);
        CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
        // TODO: Uncomment once Sdext is available
        // step_result = ztry_step(sail_step, exit_wait);
        KILL(sail_int)(&sail_step);
        // Check for Sail-internal exception.
        if (model->have_exception) {
          fprintf(stderr, "Sail exception!");
          break;
        }
      }
    }

    model->call_post_step_callbacks(is_waiting);

    // TODO: Uncomment once Sdext is available
    // Dont increment the variables when hart halted
    // if (!step_result.zin_wait) {
    step_no++;
    insn_cnt++;
    total_insns++;
    // }

    // Check for exit
    if (model->zhtif_done) {
      /* check exit code */
      if (model->zhtif_exit_code == 0) {
        fprintf(stdout, "SUCCESS\n");
      } else {
        fprintf(stdout, "FAILURE: %" PRIi64 "\n", model->zhtif_exit_code);
        exit(EXIT_FAILURE);
      }
    }
    // Tick clock
    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      model->ztick_clock(UNIT);
    }
  }

  // This function needs to return to inner_main, where the model will
  // be cleaned up.
}
