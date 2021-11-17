#include "riscv_platform_impl.h"
#include <unistd.h>
#include <stdio.h>

/* Settings of the platform implementation, with common defaults. */
bool rv_enable_pmp                  = false;
bool rv_enable_rvc                  = true;
bool rv_enable_next                 = false;
bool rv_enable_writable_misa        = true;
bool rv_enable_fdext                = true;

bool rv_enable_dirty_update         = false;
bool rv_enable_misaligned           = false;
bool rv_mtval_has_illegal_inst_bits = false;

uint64_t rv_ram_base = UINT64_C(0x80000000);
uint64_t rv_ram_size = UINT64_C(0x4000000);

uint64_t rv_rom_base = UINT64_C(0x1000);
uint64_t rv_rom_size = UINT64_C(0x100);

// Provides entropy for the scalar cryptography extension.
uint64_t rv_16_random_bits(void) {
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

uint64_t rv_clint_base = UINT64_C(0x2000000);
uint64_t rv_clint_size = UINT64_C(0xc0000);

uint64_t rv_htif_tohost = UINT64_C(0x80001000);
uint64_t rv_insns_per_tick = UINT64_C(100);

int term_fd = 1; // set during startup
void plat_term_write_impl(char c)
{
  if (write(term_fd, &c, sizeof(c)) < 0) {
    fprintf(stderr, "Unable to write to terminal!\n");
  }
}
