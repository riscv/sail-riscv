#include "riscv_platform_impl.h"
#include <unistd.h>
#include <stdio.h>
#include <random>

// Provides entropy for the scalar cryptography extension.
uint64_t rv_16_random_bits(void)
{
  static std::mt19937_64 rng(0);
  return static_cast<uint16_t>(rng());
}

uint64_t rv_htif_tohost = UINT64_C(0x80001000);
bool rv_enable_htif = true;

bool rv_enable_experimental_extensions = false;

int term_fd = 1; // set during startup
void plat_term_write_impl(char c)
{
  if (write(term_fd, &c, sizeof(c)) < 0) {
    fprintf(stderr, "Unable to write to terminal!\n");
  }
}
