#include "config_utils.h"

#include <fstream>
#include <jsoncons/json.hpp>
#include <jsoncons_ext/jsonschema/jsonschema.hpp>
#include <stdexcept>

#include "config_schema.h"
#include "default_config.h"
#include "sail.h"
#include "sail_config.h"
#include "sail_riscv_model.h"
#include <algorithm>
#include <gmp.h>

std::string keypath_to_str(const std::vector<const char *> &keypath) {
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

uint64_t get_config_uint64(const std::vector<const char *> &keypath) {
  sail_config_json json = sail_config_get(keypath.size(), keypath.data());

  if (json == nullptr) {
    throw std::runtime_error("Failed to find configuration option '" + keypath_to_str(keypath) + "'.");
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
      throw std::runtime_error(
        "Couldn't read " + std::to_string(big_bits.len) + "-bit value '" + keypath_to_str(keypath) + "' into uint64_t."
      );
    }
    // Second parameter is unused; see
    // https://github.com/rems-project/sail/issues/1429
    fbits bits = CONVERT_OF(fbits, lbits)(big_bits, false);
    KILL(lbits)(&big_bits);
    return bits;
  }

  throw std::runtime_error(
    "Configuration option '" + keypath_to_str(keypath) + "' could not be parsed as an integer.\n"
  );
}

const char *get_default_config() {
  return DEFAULT_JSON;
}

const char *get_config_schema() {
  return CONFIG_SCHEMA;
}

void validate_config_schema(const std::string &conf_file) {
  using jsoncons::json;
  namespace jsonschema = jsoncons::jsonschema;

  // Compile the schema.
  json schema = json::parse(get_config_schema());
  auto options = jsonschema::evaluation_options{}.default_version(jsonschema::schema_version::draft202012());
  // Throws schema_error if compilation fails.
  jsonschema::json_schema<json> compiled = jsonschema::make_json_schema(std::move(schema), options);

  std::string source = conf_file.empty() ? "default configuration" : "configuration in " + conf_file;

  // Parse the config.
  json config;
  try {
    if (conf_file.empty()) {
      config = json::parse(get_default_config());
    } else {
      std::ifstream is(conf_file);
      config = json::parse(is);
    }
  } catch (const std::exception &ex) {
    throw std::runtime_error("Cannot parse " + source + ": " + ex.what() + ".");
  }

  // Validate.
  bool is_valid = true;
  auto report = [&is_valid](const jsonschema::validation_message &msg) -> jsonschema::walk_result {
    is_valid = false;
    std::cerr << msg.instance_location().string() << ": " << msg.message() << std::endl;
    return jsonschema::walk_result::advance;
  };
  compiled.validate(config, report);
  if (!is_valid) {
    throw std::runtime_error("Schema conformance check failed for the " + source + ".");
  }
}

uint64_t config_get_u64_default(const std::vector<const char *> &keypath, uint64_t def) {
  sail_config_json j = sail_config_get(keypath.size(), keypath.data());
  if (j == nullptr || !sail_config_is_int(j)) return def;

  sail_int n;
  CREATE(sail_int)(&n);
  auto cleanup = [&]() { KILL(sail_int)(&n); };

  sail_config_unwrap_int(&n, j);

  uint64_t out = def;
  if (mpz_sgn(n) >= 0 && mpz_fits_ulong_p(n)) out = (uint64_t)mpz_get_ui(n);

  cleanup();
  return out;
}

