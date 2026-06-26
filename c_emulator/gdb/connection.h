#pragma once

#include "protocol_handler.h"

#include <asio.hpp>
#include <deque>
#include <memory>

struct gdb_run_info;
class ModelImpl;

class connection : public std::enable_shared_from_this<connection> {
public:
  explicit connection(
    asio::ip::tcp::acceptor &acceptor,
    asio::ip::tcp::socket socket,
    ModelImpl &model,
    gdb_run_info &info
  );

  void send_data(const std::string &data);
  void read();

  ~connection();

private:
  void write();
  void handle_socket_error();

  asio::ip::tcp::acceptor &m_acceptor;
  asio::ip::tcp::socket m_socket;
  std::string m_recv_data;
  std::deque<std::string> m_send_queue;
  std::shared_ptr<protocol_handler> m_handler;

  bool m_in_shutdown = false;
};
