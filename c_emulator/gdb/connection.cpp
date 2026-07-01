#include "connection.h"
#include "gdb_run_info.h"
#include <iostream>

namespace {

// Use a match condition that just consumes all the data.  This should
// suffice for this request-response protocol and our incremental
// protocol parser.
using iterator = asio::buffers_iterator<asio::const_buffer>;
std::pair<iterator, bool> consume_all_matcher(iterator begin, iterator end) {
  // Ensure that the buffer has some data.  Returning true for an
  // empty buffer will prevent issuing an actual read on the socket.
  return std::make_pair(end, begin != end);
}

} // namespace

connection::connection(asio::ip::tcp::socket socket, ModelImpl &model, gdb_run_info &info) :
    m_socket{std::move(socket)},
    m_handler{std::make_shared<protocol_handler>(m_socket.get_executor(), *this, model, info)} {

  // This cannot be done in the handler's constructor due to the
  // restrictions of `std::enable_shared_from_this`.
  m_handler->attach_callbacks();
}

void connection::read() {
  auto self(shared_from_this());
  async_read_until(
    m_socket,
    asio::dynamic_buffer(m_recv_data),
    consume_all_matcher,
    [this, self](asio::error_code ec, std::size_t) {
      if (ec) {
        if (!m_in_shutdown) {
          std::cerr << "read error: " << ec << " (" << ec.message() << ")" << std::endl;
          handle_socket_error();
        }
        return;
      }

      m_handler->receive_data(m_recv_data);
      m_recv_data.clear();
      read();
    }
  );
}

void connection::send_data(const std::string &data) {
  bool write_in_progress = !m_send_queue.empty();
  m_send_queue.push_back(data);
  if (!write_in_progress) {
    write();
  };
}

void connection::write() {
  auto self(shared_from_this());
  async_write(m_socket, asio::buffer(m_send_queue.front()), [this, self](asio::error_code ec, std::size_t) {
    if (ec) {
      if (!m_in_shutdown) {
        std::cerr << "write error: " << ec << ":" << ec.message() << std::endl;
        handle_socket_error();
      }
      return;
    }

    m_send_queue.pop_front();
    if (!m_send_queue.empty()) {
      write();
    }
  });
}

void connection::handle_socket_error() {
  // The connection is going to be shutdown, but cleaning up involves
  // calling functions that might throw, which is not recommended in a
  // destructor.  So this function does the cleanup instead, outside a
  // destructor.

  m_handler->detach_callbacks();

  // Shutdown the socket.  This may result in some spurious errors in
  // pending callbacks, so set a flag that they can check.
  m_in_shutdown = true;
  m_socket.cancel();
  m_socket.close();
}

connection::~connection() {
  std::cerr << "closing connection." << std::endl;
}
