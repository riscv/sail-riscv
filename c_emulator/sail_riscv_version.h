#pragma once

#include <string_view>

namespace version_info {

const std::string_view release_version();
const std::string_view git_version();
const std::string_view sail_version();
const std::string_view cxx_compiler_version();

}; // namespace version_info
