#pragma once

#include <vector>
#include "sail.h"
#include "sail_config.h"

uint64_t get_config_uint64(std::vector<const char *> keypath);
