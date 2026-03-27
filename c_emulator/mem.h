#pragma once

#include <array>
#include <cassert>
#include <cstdint>
#include <functional>
#include <map>

// A is the address type (uint32_t or uint64_t).
class Memory {
public:
  static constexpr std::size_t BLOCK_SIZE = 16;

  // // Set the number of physical address bits. Must be in [4, 64].
  // void set_phys_bits(unsigned n) {
  //   assert(n <= 64);
  //   assert(n >= 4);

  // }

  // void write(uint64_t addr, uint8_t data) {
  //   addr = addr & m_address_mask;
  //   block(addr / BLOCK_SIZE)[addr % BLOCK_SIZE] = data;
  // }

  // uint8_t read(uint64_t addr) const {
  //   addr = addr & m_address_mask;
  //   return block(addr / BLOCK_SIZE)[addr % BLOCK_SIZE];
  // }

  void read_bytes(uint64_t addr, uint64_t addr_size, uint8_t *data, std::size_t len) const {
    const uint64_t addr_mask = addr_size >= 64 ? ~0ull : ~((~0ull) << addr_size);
    while (len > 0) {
      addr = addr & addr_mask;
      auto &block_data = block(addr / BLOCK_SIZE);
      do {
        *data = block_data[addr % BLOCK_SIZE];
        ++addr;
        ++data;
        --len;
      } while (len > 0 && (addr % BLOCK_SIZE) != 0);
    }
  }

  // Write an array of bytes efficiently. Wraps end of memory.
  void write_bytes(uint64_t addr, uint64_t addr_size, const uint8_t *data, std::size_t len) {
    const uint64_t addr_mask = addr_size >= 64 ? ~0ull : ~((~0ull) << addr_size);
    while (len > 0) {
      addr = addr & addr_mask;
      auto &block_data = block(addr / BLOCK_SIZE);
      do {
        block_data[addr % BLOCK_SIZE] = *data;
        ++addr;
        ++data;
        --len;
      } while (len > 0 && (addr % BLOCK_SIZE) != 0);
    }
  }

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
  void set_uninitialized_value(std::function<uint8_t(uint64_t)> func) {
    m_uninitialized_value_func = func;
  }

private:
  std::array<uint8_t, BLOCK_SIZE> &block(uint64_t block_addr) {
    auto it = m_blocks.find(block_addr);
    if (it == m_blocks.end()) {
      // Initialise block with uninitialized values.
      std::array<uint8_t, BLOCK_SIZE> new_block;
      uint64_t base_addr = block_addr * BLOCK_SIZE;
      for (std::size_t i = 0; i < BLOCK_SIZE; ++i) {
        new_block[i] = m_uninitialized_value_func(base_addr + i);
      }
      auto res = m_blocks.insert({block_addr, new_block});
      return res.first->second;
    }
    return it->second;
  }

  const std::array<uint8_t, BLOCK_SIZE> &block(uint64_t block_addr) const {
    return const_cast<Memory *>(this)->block(block_addr);
  }

  mutable std::map<uint64_t, std::array<uint8_t, BLOCK_SIZE>> m_blocks;

  std::function<uint8_t(uint64_t)> m_uninitialized_value_func = [](uint64_t) { return 0; };
};
