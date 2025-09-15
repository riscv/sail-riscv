#pragma once

#include <cstdio>
#include <cstdarg>

void log_handler(const char *level, const char *format, ...)
{
  std::printf("[%s] ", level);

  va_list args;
  va_start(args, format);
  std::vprintf(format, args);
  va_end(args);

  std::printf("\n");
}

#define INFO(format, ...) log_handler("INFO", format, ##__VA_ARGS__)

#define WARN(format, ...) log_handler("WARN", format, ##__VA_ARGS__)

#define PANIC(format, ...)                                                     \
  do {                                                                         \
    log_handler("PANIC", format, ##__VA_ARGS__);                               \
    abort();                                                                   \
  } while (0)

#define INFO_IF(condition, format, ...)                                        \
  if (condition) {                                                             \
    INFO(format, ##__VA_ARGS__);                                               \
  }

#define WARN_IF(condition, format, ...)                                        \
  if (condition) {                                                             \
    WARN(format, ##__VA_ARGS__);                                               \
  }

#define PANIC_IF(condition, format, ...)                                       \
  if (condition) {                                                             \
    PANIC(format, ##__VA_ARGS__);                                              \
  }
