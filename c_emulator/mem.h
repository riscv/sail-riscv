#include <cstddef>
#include "inttypes.h"
#include "sail.h"

typedef uint64_t reg_t;
typedef int64_t sreg_t;
typedef reg_t addr_t;

class mem {
public:
  static void read(addr_t addr, size_t nbytes, void *bytes);
  static void write(addr_t addr, size_t nbytes, const void *bytes);
  static void clear(addr_t taddr, size_t nbytes);
};
