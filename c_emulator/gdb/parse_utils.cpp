#include "parse_utils.h"

#include <charconv>
#include <deque>
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

std::optional<uint64_t> string_to_opt_uint64t_regdata(const std::string &str) {
  // The string should have two digits for each byte.
  if (str.size() % 2 != 0) {
    return std::nullopt;
  }
  // The string has bytes in little-endian order.
  // TODO: handle big-endian RISC-V.
  std::deque<char> dq;
  auto it = str.cbegin();
  while (it != str.end()) {
    auto hi = *it++;
    auto lo = *it++;
    dq.push_front(lo);
    dq.push_front(hi);
  }
  auto little_endian = std::string(dq.cbegin(), dq.cend());
  return string_to_opt_uint64t(little_endian);
}
