// Not yet in LLVM. See:
//
// * https://reviews.llvm.org/D154706
// * https://github.com/riscv-non-isa/riscv-c-api-doc/pull/14

/*===------ riscv_intrinsic.h - RISC-V  ------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===-----------------------------------------------------------------------===
 */

#pragma once

#include <stdint.h>

#if __riscv_xlen == 32
typedef int32_t __riscv_int_xlen_t;
typedef uint32_t __riscv_uint_xlen_t;

#define __RISCV_INT_XLEN_MIN INT32_MIN
#define __RISCV_INT_XLEN_MAX INT32_MAX
#define __RISCV_UINT_XLEN_MAX UINT32_MAX

#define __RISCV_PRIdXLEN PRId32
#define __RISCV_PRIiXLEN PRIi32
#define __RISCV_PRIoXLEN PRIo32
#define __RISCV_PRIuXLEN PRIu32
#define __RISCV_PRIxXLEN PRIx32
#define __RISCV_PRIXXLEN PRIX32

#define __RISCV_SCNdXLEN SCNd32
#define __RISCV_SCNiXLEN SCNi32
#define __RISCV_SCNoXLEN SCNo32
#define __RISCV_SCNuXLEN SCNu32
#define __RISCV_SCNxXLEN SCNx32

#elif __riscv_xlen == 64
typedef int64_t __riscv_int_xlen_t;
typedef uint64_t __riscv_uint_xlen_t;

#define __RISCV_INT_XLEN_MIN INT64_MIN
#define __RISCV_INT_XLEN_MAX INT64_MAX
#define __RISCV_UINT_XLEN_MAX UINT64_MAX

#define __RISCV_PRIdXLEN PRId64
#define __RISCV_PRIiXLEN PRIi64
#define __RISCV_PRIoXLEN PRIo64
#define __RISCV_PRIuXLEN PRIu64
#define __RISCV_PRIxXLEN PRIx64
#define __RISCV_PRIXXLEN PRIX64

#define __RISCV_SCNdXLEN SCNd64
#define __RISCV_SCNiXLEN SCNi64
#define __RISCV_SCNoXLEN SCNo64
#define __RISCV_SCNuXLEN SCNu64
#define __RISCV_SCNxXLEN SCNx64

#else
#error "Unknown XLEN"
#endif
