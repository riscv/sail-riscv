#pragma once

#include "responses.h"

#include <memory>
#include <optional>
#include <vector>

struct gdb_run_info;

using response_handler_ptr = std::shared_ptr<response::response_handler>;

namespace request {

class request_parser {
public:
  virtual ~request_parser() = default;

  virtual std::optional<response_handler_ptr> parse(const std::string &, gdb_run_info &enable_trace) const {
    return std::nullopt;
  }

protected:
  request_parser() = default;
  request_parser(const request_parser &) = default;
  request_parser(request_parser &&) = default;

  request_parser &operator=(const request_parser &) = delete;
  request_parser &operator=(request_parser &&) = delete;
};

} // namespace request

using request_parser_ptr = std::shared_ptr<request::request_parser>;

class request_parsers {
public:
  request_parsers();
  ~request_parsers() = default;

  const std::vector<request_parser_ptr> &get_parsers() const;

private:
  std::vector<request_parser_ptr> parsers;
};
