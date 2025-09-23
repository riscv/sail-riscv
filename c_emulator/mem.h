#include <cstddef>
#include <string>
#include <optional>
#include "inttypes.h"
#include "sail.h"
#include "rts.h"

class mem {
public:
  static void read(uint64_t addr, void *dst, size_t nbytes);

  template <typename T> static void read(uint64_t addr, void *dst)
  {
    size_t size = sizeof(T);
    uint8_t *dest_bytes = static_cast<uint8_t *>(dst);
    for (size_t i = 0; i < size; i++)
      dest_bytes[i] = read_mem(uint64_t(addr + i));
  }
  template <typename T> static T read(uint64_t addr)
  {
    uint8_t buffer[sizeof(T)];
    for (size_t i = 0; i < sizeof(T); i++)
      buffer[i] = read_mem(addr + i);
    return *reinterpret_cast<T *>(buffer);
  }
  template <typename T> static T read(uint64_t addr, size_t size)
  {
    uint8_t buffer[sizeof(T)];
    for (size_t i = 0; i < std::min(sizeof(T), size); i++)
      buffer[i] = read_mem(addr + i);
    return *reinterpret_cast<T *>(buffer);
  }

  static void write(uint64_t addr, const void *src, size_t len);
  template <typename T> static void write(uint64_t addr, const T *src)
  {
    write(addr, reinterpret_cast<const uint8_t *>(src), sizeof(T));
  }
  template <typename T> static void write(uint64_t addr, T src)
  {
    write(addr, reinterpret_cast<const uint8_t *>(&src), sizeof(T));
  }
  static void clear(uint64_t addr, size_t len);
  template <typename T> void clear(uint64_t addr)
  {
    clear(addr, sizeof(T));
  }

  static std::string read_string(const char *ptr);
  static std::string read_string(const char *ptr, size_t nbytes);
};
