#include <string>
#include <iostream>

#include "sail_config.h"
#include "config_utils.h"

uint64_t get_config_uint64(const std::vector<const char *> &keypath)
{
  sail_config_json json = sail_config_get(keypath.size(), keypath.data());

  if (!json) {
    std::cerr << "Failed to find configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "'.\n";
    exit(1);
  }

  sail_int big_n;
  uint64_t n;

  if (!sail_config_is_int(json)) {
    std::cerr << "Configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "' could not be parsed as an integer.\n";
    exit(1);
  }

  CREATE(sail_int)(&big_n);
  sail_config_unwrap_int(&big_n, json);
  n = sail_int_get_ui(big_n);
  KILL(sail_int)(&big_n);
  return n;
}
