#pragma once

#include <cstdint>
#include <optional>
#include <string>

std::optional<uint64_t> string_to_opt_uint64t(const std::string &str);

// Convert register data.
std::optional<uint64_t> string_to_opt_uint64t_regdata(const std::string &str);
