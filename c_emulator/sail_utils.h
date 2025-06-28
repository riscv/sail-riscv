#include <sail.h>

template <typename T> inline sbits make_sbits(T val)
{
  static_assert(sizeof(T) <= sizeof(uint64_t),
                "sbits only accepts types that fit in uint64_t.");
  return {sizeof(T) * 8, static_cast<unsigned int>(val)};
}

template <typename T>
void fprint_any_as_hex(const char *pre, const T *data, const char *post,
                       FILE *stream)
{
  fputs(pre, stream);
  const uint8_t *byte_ptr = reinterpret_cast<const uint8_t *>(data);
  size_t size = sizeof(T);
  fputs("0x", stream);
  for (size_t i = size; i > 0; i--) {
    fprintf(stream, "%02x", byte_ptr[i - 1]);
  }
  fputs(post, stream);
}

template <typename T> void print_any(const_sail_string str, const T *data)
{
  fprint_any_as_hex(str, data, "\n", stdout);
  return;
}

void convert_lbits_to_u8s(lbits val, uint8_t *arr);
lbits convert_u8s_to_lbits(const uint8_t *arr, unsigned int num_bits);

unit print_sbits(const_sail_string str, const sbits op);
unit prerr_sbits(const_sail_string str, const sbits op);
