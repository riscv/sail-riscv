#include "inttypes.h"
#include "cstddef"
#include "mem.h"
#include "rts.h"

typedef uint64_t reg_t;
typedef uint64_t addr_t;

void mem::read(addr_t addr, size_t nbytes, void *dst)
{
  uint8_t *dest_bytes = static_cast<uint8_t *>(dst);
  for (size_t i = 0; i < nbytes; ++i) {
    dest_bytes[i] = read_mem(addr + i);
  }
}

void mem::write(addr_t addr, size_t nbytes, const void *src)
{
  const uint8_t *src_bytes = static_cast<const uint8_t *>(src);
  for (size_t i = 0; i < nbytes; ++i) {
    write_mem(addr + i, src_bytes[i]);
  }
}

void mem::clear(addr_t addr, size_t nbytes)
{
  for (size_t i = 0; i < nbytes; ++i) {
    write_mem(addr + i, 0);
  }
}
