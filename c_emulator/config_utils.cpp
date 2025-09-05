#include <stdlib.h>
#include <string>
#include <iostream>

#include "sail_config.h"
#include "sail_riscv_model.h"
#include "config_utils.h"

// These should eventually be part of compiler-generated `model_init()`,
// but are consolidated here pending compiler support.
void init_sail_configured_types()
{
  sail_set_abstract_xlen();
  sail_set_abstract_vlen_exp();
  sail_set_abstract_ext_d_supported();
  sail_set_abstract_elen_exp();
  sail_set_abstract_base_E_enabled();
}

uint64_t get_config_uint64(const std::vector<const char *> &keypath)
{
  sail_config_json json = sail_config_get(keypath.size(), keypath.data());

  if (!json) {
    std::cerr << "Failed to find configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "'.\n";
    exit(EXIT_FAILURE);
  }

  sail_int big_n;
  uint64_t n;

  if (!sail_config_is_int(json)) {
    std::cerr << "Configuration option '";
    for (auto part : keypath) {
      std::cerr << "." << part;
    }
    std::cerr << "' could not be parsed as an integer.\n";
    exit(EXIT_FAILURE);
  }

  CREATE(sail_int)(&big_n);
  sail_config_unwrap_int(&big_n, json);
  n = sail_int_get_ui(big_n);
  KILL(sail_int)(&big_n);
  return n;
}
