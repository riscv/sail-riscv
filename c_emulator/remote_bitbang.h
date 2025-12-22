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

#pragma once

#include <array>
#include <cstdint>
#include <memory>

class jtag_dtm_t;

class remote_bitbang_t {
public:
  static std::unique_ptr<remote_bitbang_t>
  make(uint16_t port, uint64_t required_rti_cycles, ModelImpl *model);

  ~remote_bitbang_t();

  remote_bitbang_t(const remote_bitbang_t &) = delete;
  remote_bitbang_t &operator=(const remote_bitbang_t &) = delete;

  void run(uint64_t insn_limit);

private:
  ModelImpl *model = nullptr;
  uint16_t port = 0;
  jtag_dtm_t *tap = nullptr;
  int socket_fd = -1;
  int client_fd = -1;
  static const ssize_t buf_size = 64 * 1024;
  std::array<char, buf_size> send_buf {};
  std::array<char, buf_size> recv_buf {};
  ssize_t recv_start = 0;
  ssize_t recv_end = 0;

  remote_bitbang_t(uint16_t port, jtag_dtm_t *tap, int socked_fd);

  // Check for a client connecting, and accept if there is one.
  void accept_connection();
  void close_sockets();

  // Execute any commands the client has for us.
  void tick();
};
