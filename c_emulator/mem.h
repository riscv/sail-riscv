#pragma once

#include <array>
#include <cassert>
#include <cstdint>
#include <functional>
#include <map>

// Memory model based on std::map storing 16-byte blocks. Larger block sizes
// did not give any performance improvement.
//
// std::map is used rather than std::unordered_map so the written bytes can
// be iterated through in order in `for_each_byte`.
//
// This supports pseudo-random initialisation of the memory via a callback
// function.
//
// Addresses are always 64 bit but you can just use 32-bit values on RV32.
class Memory {
public:
  static constexpr std::size_t BLOCK_SIZE = 16;

  // Read an array of bytes efficiently. Wraps end of memory.
  void read_bytes(uint64_t addr, uint64_t addr_size, uint8_t *data, std::size_t len) const;

  // Write an array of bytes efficiently. Wraps end of memory.
  void write_bytes(uint64_t addr, uint64_t addr_size, const uint8_t *data, std::size_t len);

  // Call a function for each byte in memory that has been written. Note
  // that we only track BLOCK_SIZE chunks of memory so if you ever write one byte
  // in a block this will be called for all of them.
  //
  // If skip_if_equal_uninitialized is true, skip bytes that are equal to the
  // default uninitialized value (e.g., 0).
  template <typename F> void for_each_byte(F func, bool skip_if_equal_uninitialized) const {
    for (const auto &[block_addr, block_data] : m_blocks) {
      uint64_t addr = block_addr * BLOCK_SIZE;
      for (std::size_t i = 0; i < BLOCK_SIZE; i++) {
        if (!skip_if_equal_uninitialized || block_data[i] != m_uninitialized_value_func(addr)) {
          func(addr, block_data[i]);
        }
        ++addr;
      }
    }
  }

  // Set the function to generate uninitialized values based on the address.
  // Defaults to 0. This can be used to pseudorandomise memory or set
  // recognisable patterns for debugging e.g. 0xCACACACA.
  void set_uninitialized_value(std::function<uint8_t(uint64_t)> func);

private:
  // Get a block of memory, creating it if necessary.
  std::array<uint8_t, BLOCK_SIZE> &block_write(uint64_t block_addr);
  // Read a block of memory, returns nullptr if there isn't one at this address.
  const std::array<uint8_t, BLOCK_SIZE> *block_read(uint64_t block_addr) const;

  std::map<uint64_t, std::array<uint8_t, BLOCK_SIZE>> m_blocks;

  std::function<uint8_t(uint64_t)> m_uninitialized_value_func = [](uint64_t) { return 0; };
};
