// See LICENSE for license details.

#include "mem.h"
#include "syscall.h"
#include "riscv_syscall.h"

syscall_t syscall;

unit dispatch_syscall(uint64_t payload)
{
  syscall.dispatch(payload);
  return UNIT;
}

syscall_t::syscall_t()
    : table(2048)
{
}

syscall_t::~syscall_t() { }

void syscall_t::dispatch(addr_t addr)
{
  reg_t magicmem[8];
  mem::read(addr, sizeof(magicmem) / 8, &magicmem);

  reg_t n = magicmem[0];

  if (n >= table.size() || !table[n]) {
    fprintf(stderr, "bad syscall #%ld\n", n);
    exit(EXIT_FAILURE);
  }

  magicmem[0]
      = (this->table[n])(magicmem[1], magicmem[2], magicmem[3], magicmem[4],
                         magicmem[5], magicmem[6], magicmem[7]);

  mem::write(addr, sizeof(magicmem) / 8, &magicmem);
}
