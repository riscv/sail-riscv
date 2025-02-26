#include "riscv_platform_impl.h"
#include <unistd.h>
#include <stdio.h>

// Provides entropy for the scalar cryptography extension.
uint64_t rv_16_random_bits(void)
{
  // This function can be changed to support deterministic sequences of
  // pseudo-random bytes. This is useful for testing.
  const char *name = "/dev/urandom";
  FILE *f = fopen(name, "rb");
  uint16_t val;
  if (fread(&val, 2, 1, f) != 1) {
    fprintf(stderr, "Unable to read 2 bytes from %s\n", name);
  }
  fclose(f);
  return (uint64_t)val;
}

uint64_t rv_htif_tohost = UINT64_C(0x80001000);

int term_fd = 1; // set during startup
void plat_term_write_impl(char c)
{
  if (write(term_fd, &c, sizeof(c)) < 0) {
    fprintf(stderr, "Unable to write to terminal!\n");
  }
}
