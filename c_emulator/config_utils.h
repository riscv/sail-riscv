#pragma once

#include <vector>
#include "sail.h"

void init_sail_configured_types();

uint64_t get_config_uint64(const std::vector<const char *> &keypath);
