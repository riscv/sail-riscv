#pragma once

#include <string_view>

namespace schema_file_info {

// Absolute location.
extern const std::string_view build_location;

// Path relative to the INSTALL_PREFIX
extern const std::string_view relative_install_location;

};
