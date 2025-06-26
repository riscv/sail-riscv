#include <sail.h>

void convert_lbits_to_u8s(lbits val, uint8_t *arr);
lbits convert_u8s_to_lbits(const uint8_t *arr, unsigned int num_bits);

unit print_sbits(const_sail_string str, const sbits op);
unit prerr_sbits(const_sail_string str, const sbits op);
