#include "parse_utils.h"

#include <charconv>
#include <system_error>

std::optional<uint64_t> string_to_opt_uint64t(const std::string &str) {
  uint64_t result{};
  const char *end = str.data() + str.size();
  auto [ptr, ec] = std::from_chars(str.data(), end, result, 16);
  if (ec == std::errc() && ptr == end) {
    return result;
  }
  return std::nullopt;
}
