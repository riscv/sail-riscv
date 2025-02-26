#include "nanoprintf.h"

extern void htif_putc(int c, void *ctx);

int printf(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  int rc = npf_pprintf(&htif_putc, NULL, fmt, ap);
  va_end(ap);
  return rc;
}
