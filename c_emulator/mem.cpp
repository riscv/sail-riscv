#include <inttypes.h>
#include <cstddef>
#include "mem.h"

void mem::read(uint64_t addr, void *dst, size_t nbytes)
{
  uint8_t *dest_bytes = static_cast<uint8_t *>(dst);
  for (size_t i = 0; i < nbytes; ++i) {
    dest_bytes[i] = read_mem(addr + i);
  }
}

void mem::write(uint64_t addr, const void *src, size_t nbytes)
{
  const uint8_t *src_bytes = static_cast<const uint8_t *>(src);
  for (size_t i = 0; i < nbytes; ++i) {
    write_mem(addr + i, src_bytes[i]);
  }
}

void mem::clear(uint64_t addr, size_t nbytes)
{
  for (size_t i = 0; i < nbytes; ++i) {
    write_mem(addr + i, 0);
  }
}

std::string mem::read_string(const char *buf)
{
  std::string ret;
  uint64_t addr = (uint64_t)buf;
  for (;;) {
    char c = read_mem((uint64_t)addr);
    if (c) {
      ret += c;
      addr++;
    } else {
      break;
    }
  }
  return ret;
}

std::string mem::read_string(const char *buf, size_t nbytes)
{
  std::string ret;
  uint64_t addr = (uint64_t)buf;
  for (size_t i = 0; i < nbytes; ++i) {
    char c = read_mem((uint64_t)addr);
    if (c) {
      ret += c;
      addr++;
    } else {
    }
  }
  return ret;
}
