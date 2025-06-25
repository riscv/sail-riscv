#include "sail_utils.h"

lbits convert_u8s_to_lbits(const uint8_t *arr, unsigned int num_bits)
{
  lbits result;
  result.len = num_bits;
  result.bits = (mpz_t *)malloc(sizeof(mpz_t));
  mpz_init(*result.bits);
  mpz_import(*result.bits, num_bits, -1, 1, 0, 0, arr);
  return result;
}

void convert_lbits_to_u8s(lbits val, uint8_t *arr, size_t len)
{
  if (len * 8 < val.len) {
    fprintf(stderr, "Not enough space to convert lbits to u8s!\n");
    exit(EXIT_FAILURE);
  }
  mpz_export(arr, NULL, -1, 1, 0, 0, *val.bits);
}
