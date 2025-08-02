#pragma once

#include <vector>
#include <string>
#include "sail.h"

uint64_t get_config_uint64(const std::vector<const char *> &keypath);

const char *get_default_config();

void validate_config_schema(std::string schema_file,
                            const std::string &conf_file);
