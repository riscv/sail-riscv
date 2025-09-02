#pragma once

#include <vector>
#include <string>
#include <sail.h>

typedef uint64_t reg_t;

typedef reg_t (*syscall_func_t)(reg_t, reg_t, reg_t, reg_t, reg_t, reg_t,
                                reg_t);

class syscall_t {
public:
  syscall_t();
  ~syscall_t();

  void dispatch(addr_t addr);

private:
  std::vector<syscall_func_t> table;
};
