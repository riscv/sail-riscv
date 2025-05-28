#pragma once

#include <vector>
#include "sail.h"

uint64_t get_config_uint64(const std::vector<const char *> &keypath);
bool get_config_bool(const std::vector<const char *> &keypath);
