/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Model context for synchronous exceptions, parameterized for out-of-tree extensions */

struct ExceptionContext = {
  excinfo     : option(xlenbits),        /* Faulting address or instruction */
  info_is_gva : bool,                    /* H-extension: true if excinfo holds guest-virtual-address */
  excinfo2    : option(xlenbits),        /* H-extension: faulting guest-physical address */
  excinst     : option(xlenbits),        /* H-extension: transformed instruction or pseudoinstruction */
  ext         : option(ext_exception)    /* For out-of-tree extensions */
}

/* Create contexts for various exception classes */

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
