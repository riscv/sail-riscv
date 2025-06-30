#pragma once

#include <string>

struct version_info {
  static const std::string release_version;
  static const std::string git_version;
  static const std::string sail_version;
  static const std::string cxx_compiler_version;
};
