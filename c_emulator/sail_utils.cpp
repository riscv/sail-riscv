#include <stdio.h>
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
    exit(1);
  }
  mpz_export(arr, NULL, -1, 1, 0, 0, *val.bits);
}

void fprint_bits_sbits(const char *pre, const sbits op, const char *post,
                       FILE *stream)
{
  fputs(pre, stream);
  if (op.len == 0) {
  } else if (op.len % 4 == 0) {
    fputs("0x", stream);
    int num_hex_digits = op.len / 4;
    for (int i = num_hex_digits - 1; i >= 0; --i) {
      unsigned nibble = (op.bits >> (i * 4)) & 0xF;
      char hex_char
          = (nibble < 10) ? (char)(nibble + '0') : (char)(nibble - 10 + 'a');
      fputc(hex_char, stream);
    }
  } else {
    fputs("0b", stream);
    for (int i = op.len - 1; i >= 0; --i) {
      fputc(((op.bits >> i) & 1) + '0', stream);
    }
  }
  fputs(post, stream);
}

unit print_sbits(const_sail_string str, const sbits op)
{
  fprint_bits_sbits(str, op, "\n", stdout);
  return UNIT;
}

unit prerr_sbits(const_sail_string str, const sbits op)
{
  fprint_bits_sbits(str, op, "\n", stderr);
  return UNIT;
}
