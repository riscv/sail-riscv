#include "file_utils.h"
#include <cstdint>
#include <fstream>
#include <sstream>
#include <stdexcept>

std::string read_file_to_string(const std::string &file_path) {
  std::ifstream instream(file_path);
  if (!instream) {
    throw std::runtime_error("Failed to open file: " + file_path);
  }

  std::ostringstream ss;
  ss << instream.rdbuf();
  return ss.str();
}

std::vector<uint8_t> read_file(const std::string &file_path) {
  std::ifstream instream(file_path, std::ios::in | std::ios::binary);
  if (!instream) {
    throw std::runtime_error("Failed to open file: " + file_path);
  }

  std::vector<uint8_t> data{std::istreambuf_iterator<char>(instream), std::istreambuf_iterator<char>()};
  return data;
}
