#pragma once

#include <stdint.h>

int printf(const char *fmt, ...);

// XLEN integer types.
// Based on https://github.com/riscv-non-isa/riscv-c-api-doc/pull/14

#if __riscv_xlen == 32
typedef int32_t int_xlen_t;
typedef uint32_t uint_xlen_t;

#define INT_XLEN_MIN INT32_MIN
#define INT_XLEN_MAX INT32_MAX
#define UINT_XLEN_MAX UINT32_MAX

#define PRIdXLEN PRId32
#define PRIiXLEN PRIi32
#define PRIoXLEN PRIo32
#define PRIuXLEN PRIu32
#define PRIxXLEN PRIx32
#define PRIXXLEN PRIX32

#define SCNdXLEN SCNd32
#define SCNiXLEN SCNi32
#define SCNoXLEN SCNo32
#define SCNuXLEN SCNu32
#define SCNxXLEN SCNx32

#elif __riscv_xlen == 64
typedef int64_t int_xlen_t;
typedef uint64_t uint_xlen_t;

#define INT_XLEN_MIN INT64_MIN
#define INT_XLEN_MAX INT64_MAX
#define UINT_XLEN_MAX UINT64_MAX

#define PRIdXLEN PRId64
#define PRIiXLEN PRIi64
#define PRIoXLEN PRIo64
#define PRIuXLEN PRIu64
#define PRIxXLEN PRIx64
#define PRIXXLEN PRIX64

#define SCNdXLEN SCNd64
#define SCNiXLEN SCNi64
#define SCNoXLEN SCNo64
#define SCNuXLEN SCNu64
#define SCNxXLEN SCNx64

#else
#error "Unknown XLEN"
#endif
