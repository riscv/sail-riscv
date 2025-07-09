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

#include "jtag_dtm.h"
#include "remote_bitbang.h"

remote_bitbang_t::remote_bitbang_t(uint16_t port, jtag_dtm_t *tap,
                                   int socket_fd)
    : port(port)
    , tap(tap)
    , socket_fd(socket_fd)
{
}

std::shared_ptr<remote_bitbang_t> remote_bitbang_t::make(uint16_t port,
                                                         jtag_dtm_t *tap)
{
  if (!tap)
    throw std::invalid_argument("tap cannot be null");

  // Create socket
  int socket_fd = socket(AF_INET, SOCK_STREAM, 0);
  if (socket_fd == -1) {
    throw std::runtime_error("remote_bitbang failed to create socket: "
                             + std::string(strerror(errno)) + " ("
                             + std::to_string(errno) + ")");
  }

  // Set non-blocking
  if (fcntl(socket_fd, F_SETFL, O_NONBLOCK) == -1) {
    close(socket_fd);
    throw std::runtime_error("remote_bitbang failed to set non-blocking: "
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

  return std::shared_ptr<remote_bitbang_t>(
      new remote_bitbang_t(port, tap, socket_fd));
}

remote_bitbang_t::~remote_bitbang_t()
{
  if (socket_fd != -1)
    close(socket_fd);
  if (client_fd != -1)
    close(client_fd);
}

void remote_bitbang_t::accept_connection()
{
  client_fd = accept(socket_fd, NULL, NULL);
  if (client_fd == -1) {
    if (errno == EAGAIN) {
      // No client waiting to connect right now.
    } else {
      fprintf(stderr, "failed to accept on socket: %s (%d)\n", strerror(errno),
              errno);
      exit(EXIT_FAILURE);
    }
  } else {
    fcntl(client_fd, F_SETFL, O_NONBLOCK);
  }
}

void remote_bitbang_t::tick()
{
  if (client_fd > 0) {
    execute_commands();
  } else {
    this->accept_connection();
  }
}

void remote_bitbang_t::execute_commands()
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
