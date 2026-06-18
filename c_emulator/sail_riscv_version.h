#pragma once

#include <string_view>

namespace version_info {

std::string_view release_version();
std::string_view git_version();
std::string_view sail_version();
std::string_view cxx_compiler_version();

}; // namespace version_info
