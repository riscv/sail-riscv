#include <inttypes.h>
#include <cstddef>
#include "mem.h"

bool mem::target_is_little_endian = true;

void mem::read(uint64_t addr, void *dst, size_t len)
{
  uint8_t *dest_bytes = static_cast<uint8_t *>(dst);
  if (same_endian()) {
    for (size_t i = 0; i < len; i++) {
      dest_bytes[i] = read_mem(addr + i);
    }
  } else {
    for (size_t i = 0; i < len; i++) {
      dest_bytes[i] = read_mem(addr + (len - 1 - i));
    }
  }
}

void mem::write(uint64_t addr, const void *src, size_t len)
{
  const uint8_t *src_bytes = static_cast<const uint8_t *>(src);
  if (same_endian()) {
    for (size_t i = 0; i < len; i++) {
      write_mem(addr + i, src_bytes[i]);
    }
  } else {
    for (size_t i = 0; i < len; i++) {
      write_mem(addr + (len - 1 - i), src_bytes[i]);
    }
  }
}

void mem::clear(uint64_t addr, size_t len)
{
  for (size_t i = 0; i < len; i++) {
    write_mem(addr + i, 0);
  }
}

std::string mem::read_string(const char *ptr)
{
  std::string ret;
  uint64_t addr = (uint64_t)ptr;
  for (;;) {
    char c = read_mem((uint64_t)addr);
    if (c) {
      ret += c;
      addr += 1;
    } else {
      break;
    }
  }
  return ret;
}

std::string mem::read_string(const char *ptr, size_t len)
{
  std::string ret;
  uint64_t addr = (uint64_t)ptr;
  for (size_t i = 0; i < len; i += 1) {
    char c = read_mem((uint64_t)addr);
    if (c) {
      ret += c;
      addr += 1;
    }
  }
  return ret;
}
