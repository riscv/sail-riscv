#include <asio.hpp>
#include <iostream>
#include <memory>
#include <system_error>

#include "connection.h"
#include "gdbserver.h"

namespace {

struct acceptor_state {
  std::weak_ptr<connection> current_connection;
};

void accept(asio::ip::tcp::acceptor &acceptor, acceptor_state &ast, ModelImpl &model, gdb_run_info &info) {
  acceptor.async_accept([&acceptor, &ast, &model, &info](asio::error_code ec, asio::ip::tcp::socket socket) {
    if (ec) {
      // Don't log an error message if the accept was cancelled due to a connection being closed.
      if (ec.value() != static_cast<int>(std::errc::operation_canceled)) {
        std::cerr << "Error on accept: " << ec << ": " << ec.value() << " " << ec.message() << std::endl;
      }
      return;
    }

    if (!ast.current_connection.expired()) {
      std::cerr << "A gdb session is live, rejecting connection." << std::endl;
      socket.close();
    } else {
      auto conn = std::make_shared<connection>(acceptor, std::move(socket), model, info);
      ast.current_connection = conn;
      conn->read();
    }

    // Queue the next accept.
    accept(acceptor, ast, model, info);
  });
}

} // namespace

void run_gdbserver(ModelImpl &model, gdb_run_info &info, unsigned port) {
  asio::io_context context;
  asio::ip::tcp::acceptor acceptor{context, asio::ip::tcp::endpoint(asio::ip::tcp::v4(), port)};
  acceptor_state ast = {
    .current_connection = {},
  };
  accept(acceptor, ast, model, info);
  std::cout << "Listening on port " << port << " for GDB ..." << std::endl;
  context.run();
}
