// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// model context for synchronous exceptions, parameterized for extensions

function exception_context(e : ExceptionType, excinfo : xlenbits) -> Exception_Context = {
  struct {
    trap           = e,
    // NOTE/TODO: "Field GVA (Guest Virtual Address) is written by the implementation
    // whenever a trap is taken into HS-mode. For any trap (breakpoint, address misaligned,
    // access fault, page fault, or guest-page fault) that writes a guest virtual address
    // to stval, GVA is set to 1. For any other trap into HS-mode, GVA is set to 0."
    // TODO/NOTE: Check whether all cases are covered
    excinfo_is_gva = inVirtualPrivilege(),
    excinfo        = excinfo,
    excinfo2       = None(),
    excinst        = None(),
    ext            = None()
  }
}

// Wrapper
function make_exception_context(
  trap           : ExceptionType,
  excinfo        : xlenbits,
  excinfo_is_gva : bool,
  excinfo2       : option(xlenbits),
) -> Exception_Context = {
  struct {
    trap           = trap,
    excinfo_is_gva = excinfo_is_gva,
    excinfo        = excinfo,
    excinfo2       = excinfo2,
    excinst        = None(),
    ext            = None(),
  }
}

// Wrapper, for instruction exceptions (illegal, virtual, ecall, ebreak) - excinfo is instruction bits or zero
function make_instr_exception_context(
  trap    : ExceptionType,
  excinfo : xlenbits,  // instruction bits or zeros
) -> Exception_Context = {
  struct {
    trap           = trap,
    excinfo_is_gva = false,
    excinfo        = excinfo,
    excinfo2       = Some(zeros()),
    excinst        = None(),
    ext            = None(),
  }
}
