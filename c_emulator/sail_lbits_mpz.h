// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
// =======================================================================================

#pragma once

#include "sail.h"

// Read-only GMP value of an lbits. This works with the old Sail runtime,
// where lbits.bits is an mpz_t, and with the new one (SAIL_HAVE_MPZ_VIEW).
#ifdef SAIL_HAVE_MPZ_VIEW
using lbits_mpz_view = sail_mpz_view;

inline mpz_srcptr lbits_mpz(lbits_mpz_view &view, const lbits &value) {
  return sail_lbits_view(&view, value);
}
#else
struct lbits_mpz_view {};

inline mpz_srcptr lbits_mpz(lbits_mpz_view &, const lbits &value) {
  return *value.bits;
}
#endif
