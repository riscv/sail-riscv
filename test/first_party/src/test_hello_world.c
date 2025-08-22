// Simple hello world example.

#include "common/runtime.h"

int main()
{
  printf("Hello %s%c %d %u %f\n", "worl", 'd', 1, 2, // codespell:ignore worl
         3.f);
  return 0;
}
