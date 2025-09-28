#include <cstddef>
#include <string>
#include <optional>
#include "inttypes.h"
#include "sail.h"
#include "rts.h"

class mem {
public:
  // Set target endian, default is little endian
  static void set_target_endian(bool is_little)
  {
    target_is_little_endian = is_little;
  }

  // Read from sail mem, start from addr, len = len
  // This function will read bytes in reverse order if host endian and target
  // endian are different
  static void read(uint64_t addr, void *dst, size_t len);

  // start from addr, len = sizeof(T)
  template <typename T> static T read(uint64_t addr)
  {
    uint8_t buffer[sizeof(T)] = {0};
    read(addr, static_cast<uint8_t *>(buffer), sizeof(T));
    return *reinterpret_cast<T *>(buffer);
  }

  // start from addr, len = min(sizeof(T), size)
  template <typename T> static T read(uint64_t addr, size_t size)
  {
    uint8_t buffer[sizeof(T)] = {0};
    read(addr, static_cast<uint8_t *>(buffer), std::min(sizeof(T), size));
    return *reinterpret_cast<T *>(buffer);
  }

  static void write(uint64_t addr, const void *src, size_t len);

  // start from addr, len = sizeof(T)
  template <typename T> static void write(uint64_t addr, const T *src)
  {
    write(addr, reinterpret_cast<const uint8_t *>(src), sizeof(T));
  }

  // start from addr, len = sizeof(T)
  template <typename T> static void write(uint64_t addr, T src)
  {
    write(addr, reinterpret_cast<const uint8_t *>(&src), sizeof(T));
  }
  static void clear(uint64_t addr, size_t len);

  // start from addr, len = sizeof(T)
  template <typename T> void clear(uint64_t addr)
  {
    clear(addr, sizeof(T));
  }

  // read until '\0'
  static std::string read_string(const char *ptr);

  static std::string read_string(const char *ptr, size_t len);

private:
  static bool target_is_little_endian;
  static bool host_is_little_endian()
  {
    union {
      uint16_t u16;
      uint8_t u8[2];
    } test = {.u16 = 0x0001};
    return test.u8[0] == 0x01;
  }
  static bool same_endian()
  {
    return host_is_little_endian() == target_is_little_endian;
  }
};
