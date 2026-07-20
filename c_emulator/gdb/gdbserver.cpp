#include <asio.hpp>
#include <iostream>
#include <memory>
#include <system_error>

#include "connection.h"
#include "gdbserver.h"

namespace {

void accept(asio::ip::tcp::acceptor &acceptor, ModelImpl &model, gdb_run_info &info) {
  acceptor.async_accept([&model, &info](asio::error_code ec, asio::ip::tcp::socket socket) {
    if (ec) {
      std::cerr << "Error on accept: " << ec << ": " << ec.value() << " " << ec.message() << std::endl;
      return;
    }

    auto conn = std::make_shared<connection>(std::move(socket), model, info);
    conn->read();
  });
}

} // namespace

void run_gdbserver(ModelImpl &model, gdb_run_info &info, unsigned port) {
  asio::io_context context;
  asio::ip::tcp::acceptor acceptor{context, asio::ip::tcp::endpoint(asio::ip::tcp::v4(), port)};

  accept(acceptor, model, info);
  std::cout << "Listening on port " << port << " for debugger client ..." << std::endl;
  context.run();
}
