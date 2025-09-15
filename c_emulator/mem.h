#include <cstddef>
#include <string>
#include "inttypes.h"
#include "sail.h"
#include "rts.h"

class mem {
public:
  static void read(uint64_t addr, void *dst, size_t nbytes);

  template <typename Type> static void read(uint64_t addr, void *dst)
  {
    size_t size = sizeof(Type);
    uint8_t *dest_bytes = static_cast<uint8_t *>(dst);
    for (size_t i = 0; i < size; i++)
      dest_bytes[i] = read_mem(uint64_t(addr + i));
  }
  template <typename Type> static Type read(uint64_t addr)
  {
    uint8_t buffer[sizeof(Type)];
    for (size_t i = 0; i < sizeof(Type); i++)
      buffer[i] = read_mem(addr + i);
    return *reinterpret_cast<Type *>(buffer);
  }

  static void write(uint64_t addr, const void *src, size_t nbytes);
  template <typename Type> void write(uint64_t addr, const Type *src)
  {
    size_t size = sizeof(Type);
    const uint8_t *src_bytes = static_cast<const uint8_t *>(src);
    for (size_t i = 0; i < size; i++)
      write_mem(addr + i, src_bytes[i]);
  }
  template <typename Type> void write(uint64_t addr, Type data)
  {
    const uint8_t *src_bytes = reinterpret_cast<const uint8_t *>(&data);
    for (size_t i = 0; i < sizeof(Type); i++)
      write_mem(addr + i, src_bytes[i]);
  }

  static void clear(uint64_t taddr, size_t nbytes);
  template <typename Type> void clear(uint64_t taddr)
  {
    size_t size = sizeof(Type);
    for (size_t i = 0; i < size; i += size)
      write<Type>(taddr + i, 0);
  }

  static std::string read_string(const char *buf);
  static std::string read_string(const char *buf, size_t nbytes);
};
