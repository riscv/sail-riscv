#include "mem.h"

void Memory::read_bytes(uint64_t addr, uint64_t addr_size, uint8_t *data, std::size_t len) const {
  const uint64_t addr_mask = addr_size >= 64 ? ~0ull : ~((~0ull) << addr_size);
  while (len > 0) {
    addr = addr & addr_mask;
    auto block_data = block_read(addr / BLOCK_SIZE);
    do {
      *data = block_data != nullptr ? (*block_data)[addr % BLOCK_SIZE] : m_uninitialized_value_func(addr);
      ++addr;
      ++data;
      --len;
    } while (len > 0 && (addr % BLOCK_SIZE) != 0);
  }
}

// Write an array of bytes efficiently. Wraps end of memory.
void Memory::write_bytes(uint64_t addr, uint64_t addr_size, const uint8_t *data, std::size_t len) {
  const uint64_t addr_mask = addr_size >= 64 ? ~0ull : ~((~0ull) << addr_size);
  while (len > 0) {
    addr = addr & addr_mask;
    auto &block_data = block_write(addr / BLOCK_SIZE);
    do {
      block_data[addr % BLOCK_SIZE] = *data;
      ++addr;
      ++data;
      --len;
    } while (len > 0 && (addr % BLOCK_SIZE) != 0);
  }
}

void Memory::set_uninitialized_value(std::function<uint8_t(uint64_t)> func) {
  m_uninitialized_value_func = func;
}

std::array<uint8_t, Memory::BLOCK_SIZE> &Memory::block_write(uint64_t block_addr) {
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

const std::array<uint8_t, Memory::BLOCK_SIZE> *Memory::block_read(uint64_t block_addr) const {
  auto it = m_blocks.find(block_addr);
  if (it == m_blocks.end()) {
    return nullptr;
  }
  return &it->second;
}
