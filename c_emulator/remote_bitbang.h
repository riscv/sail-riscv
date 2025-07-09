#pragma once

#include <array>
#include <cstdint>
#include <memory>

class jtag_dtm_t;

class remote_bitbang_t {
public:
  static std::shared_ptr<remote_bitbang_t> make(uint16_t port, jtag_dtm_t *tap);

  ~remote_bitbang_t();

  remote_bitbang_t(const remote_bitbang_t &) = delete;
  remote_bitbang_t &operator=(const remote_bitbang_t &) = delete;

  void tick();

private:
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

  // Execute any commands the client has for us.
  void execute_commands();
};
