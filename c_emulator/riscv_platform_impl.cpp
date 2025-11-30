#include "riscv_platform_impl.h"
#include <unistd.h>
#include <stdio.h>
#include <random>

static std::optional<uint64_t> rng_seed;

// Must be called before rv_16_random_bits().
void rv_set_rng_seed(std::optional<uint64_t> seed)
{
  rng_seed = seed;
}

// Provides entropy for the scalar cryptography extension.
uint64_t rv_16_random_bits(void)
{
  static std::mt19937_64 rng(rng_seed.has_value() ? *rng_seed
                                                  : std::random_device {}());
  return static_cast<uint16_t>(rng());
}

bool rv_enable_experimental_extensions = false;
uint64_t reservation_set_size_exp = 0;
uint64_t reservation_set_addr_mask = 0;
bool config_print_reservation = false;

int term_fd = 1; // set during startup
void plat_term_write_impl(char c)
{
  if (write(term_fd, &c, sizeof(c)) < 0) {
    fprintf(stderr, "Unable to write to terminal!\n");
  }
}
