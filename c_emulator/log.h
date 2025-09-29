#pragma once

#include <cstdio>
#include <cstdarg>

#define PRINTF_IF(condition, format, ...)                                      \
  if (condition) {                                                             \
    printf(format, ##__VA_ARGS__);                                             \
  }

#define EXIT_FAILURE_WITH(format, ...)                                         \
  do {                                                                         \
    printf(format, ##__VA_ARGS__);                                             \
    exit(EXIT_FAILURE);                                                        \
  } while (0)
