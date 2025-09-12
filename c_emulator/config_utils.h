#pragma once

#include <cstdint>
#include <vector>

// Get a uint64_t from the JSON config file. This works with integers and
// non-abstract bit vectors. Bit vectors over 64 bits throw an exception.
// Integers over 64 bits are currently silently truncated, and the sign
// is ignored (-3 will be read as 3).
uint64_t get_config_uint64(const std::vector<const char *> &keypath);
