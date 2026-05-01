#include "parse_utils.h"

std::optional<uint64_t> string_to_opt_uint64t(const std::string &istr) {
  try {
    unsigned long long num = std::stoull(istr, nullptr, 16);
    return static_cast<uint64_t>(num);
  } catch (const std::exception &) {
    return std::nullopt;
  }
}
