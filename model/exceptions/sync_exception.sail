// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Model context for synchronous exceptions
struct ExceptionContext = {
  // Faulting address or instruction
  excinfo     : option(xlenbits),

  // H-extension: true if excinfo holds guest-virtual-address
  // "Field GVA (Guest Virtual Address) is written by the implementation whenever a trap is taken into HS-mode.
  //  For any trap (breakpoint, address misaligned, access fault, page fault, or guest-page fault) that
  //  writes a guest virtual address to stval, GVA is set to 1. For any other trap into HS-mode, GVA is set to 0."
  info_is_gva : bool,
  // H-extension: faulting guest-physical address
  excinfo2    : option(xlenbits),
  // H-extension: transformed instruction or pseudoinstruction
  excinst     : option(xlenbits),

  // For out-of-tree extensions
  ext         : option(ext_exception)
}

// Create contexts for various exception classes

function empty_exception_context() -> ExceptionContext =
  struct {
    excinfo     = None(),
    info_is_gva = false,
    excinfo2    = None(),
    excinst     = None(),
    ext         = None(),
  }

function mem_exception_context(vaddr : xlenbits, is_gva : bool) -> ExceptionContext =
  struct {
    excinfo     = Some(vaddr),
    info_is_gva = is_gva,
    excinfo2    = None(),
    excinst     = None(),
    ext         = None(),
  }

function vmem_exception_context(vaddr : xlenbits, is_gva : bool, gpaddr : option(xlenbits), pseudoinst : option(xlenbits)) -> ExceptionContext =
  struct {
    excinfo     = Some(vaddr),
    info_is_gva = is_gva,
    excinfo2    = gpaddr,
    excinst     = pseudoinst,
    ext         = None(),
  }

function instr_exception_context(inst : xlenbits, tval_has_ill_inst_bits : bool) -> ExceptionContext =
  struct {
    excinfo     = if tval_has_ill_inst_bits then Some(inst) else None(),
    info_is_gva = false,
    excinfo2    = None(),
    excinst     = None(),
    ext         = None(),
  }

// For out-of-tree extensions
val ext_exception_context : forall ('ext : Type) . ('ext) -> ExceptionContext
function ext_exception_context(ext) =
  struct {
    excinfo     = None(),
    info_is_gva = false,
    excinfo2    = None(),
    excinst     = None(),
    ext         = None(),
  }
