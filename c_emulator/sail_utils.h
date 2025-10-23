#pragma once

#include <sail.h>
#include <sstream>
#include <iomanip>

template <typename T> std::string any_to_hex_string(T &data)
{
  std::stringstream stream;
  stream << "0x";
  const uint8_t *byte_ptr = reinterpret_cast<const uint8_t *>(&data);
  for (size_t i = sizeof(T); i > 0; i--) {
    stream << std::setfill('0') << std::setw(2) << std::hex << std::uppercase
           << static_cast<unsigned int>(byte_ptr[i - 1]);
  }
  return stream.str();
}

template <typename T>
void print_raw_as_hex(const_sail_string str, const T &data)
{
  fprintf(stdout, "%s%s\n", str, any_to_hex_string(data).c_str());
  return;
}

void convert_lbits_to_u8s(lbits val, uint8_t *arr, size_t len);
lbits convert_u8s_to_lbits(const uint8_t *arr, unsigned int num_bits);

template <typename T> sbits make_sbits(T val)
{
  static_assert(sizeof(T) <= sizeof(uint64_t),
                "sbits only accepts types that fit in uint64_t.");
  return {sizeof(T) * 8, static_cast<uint64_t>(val)};
}

template <typename T> lbits make_lbits(T val)
{
  return convert_u8s_to_lbits(static_cast<uint8_t *>(val), sizeof(T) * 8);
}
