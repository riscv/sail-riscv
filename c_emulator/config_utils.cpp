#include "config_utils.h"

#include <stdexcept>

#include "sail.h"
#include "sail_config.h"
#include "sail_riscv_model.h"

std::string keypath_to_str(const std::vector<const char *> &keypath)
{
  std::string s;
  if (keypath.empty()) {
    return s;
  }
  for (auto part : keypath) {
    s += part;
    s += ".";
  }
  s.pop_back();
  return s;
}

uint64_t get_config_uint64(const std::vector<const char *> &keypath)
{
  sail_config_json json = sail_config_get(keypath.size(), keypath.data());

  if (json == nullptr) {
    throw std::runtime_error("Failed to find configuration option '"
                             + keypath_to_str(keypath) + "'.");
  }

  if (sail_config_is_int(json)) {
    sail_int big_n;
    CREATE(sail_int)(&big_n);
    sail_config_unwrap_int(&big_n, json);
    // TODO: This truncates and ignores the sign.
    uint64_t n = sail_int_get_ui(big_n);
    KILL(sail_int)(&big_n);
    return n;
  }

  if (sail_config_is_bits(json)) {
    lbits big_bits;
    CREATE(lbits)(&big_bits);
    sail_config_unwrap_bits(&big_bits, json);
    if (big_bits.len > 64) {
      KILL(lbits)(&big_bits);
      throw std::runtime_error("Couldn't read " + std::to_string(big_bits.len)
                               + "-bit value '" + keypath_to_str(keypath)
                               + "' into uint64_t.");
    }
    // Second parameter is unused; see
    // https://github.com/rems-project/sail/issues/1429
    fbits bits = CONVERT_OF(fbits, lbits)(big_bits, false);
    KILL(lbits)(&big_bits);
    return bits;
  }

  throw std::runtime_error("Configuration option '" + keypath_to_str(keypath)
                           + "' could not be parsed as an integer.\n");
}
