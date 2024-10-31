/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// ****************************************************************
// PTW exceptions

// 'ext_ptw' supports (non-standard) extensions to the default addr-translation and PTW.
// See riscv_types_ext.sail for definitions.

// Note: Ideally we could use 'PTW_Implicit : (PTW_Error, ...)' in 'PTW_Error' but recursive types are not supported by sail

// Failure modes for implicit address-translation/page-table-walks
// PRIVATE
union PTW_Implicit_Error = {
  PTW_I_Invalid_Addr  : unit,                         // invalid source address
  PTW_I_Access        : unit,                         // physical memory access error for a PTE
  PTW_I_Invalid_PTE   : unit,                         // invalid page table entry or ptr PTE when level = 0
  PTW_I_No_Permission : unit,                         // insufficient page permissions
  PTW_I_Misaligned    : unit,                         // misaligned superpage
  PTW_I_PTE_Update    : unit,                         // PTE update needed but not enabled
  PTW_I_Ext_Error     : ext_ptw_error                 // parameterized for errors from extensions
}

// Failure modes for address-translation/page-table-walks
// PRIVATE
union PTW_Error = {
  PTW_Invalid_Addr  : unit,                           // invalid source address
  PTW_Access        : unit,                           // physical memory access error for a PTE
  PTW_Invalid_PTE   : unit,                           // invalid page table entry or ptr PTE when level = 0
  PTW_No_Permission : unit,                           // insufficient page permissions
  PTW_Misaligned    : unit,                           // misaligned superpage
  PTW_PTE_Update    : unit,                           // PTE update needed but not enabled
  PTW_Implicit      : (PTW_Implicit_Error,            // error during implicit access/page-walk
                       bits(64),                      //   faulting address of implicit access/page-walk
                       AccessType(ext_access_type)),  //   access type of implicit access/page-walk
  PTW_Ext_Error     : ext_ptw_error                   // parameterized for errors from extensions
}

// Convert PTW_Error to PTW_Implicit_Error
function ptw_implicit_error(f : PTW_Error) -> PTW_Implicit_Error = {
  match f {
    PTW_Invalid_Addr()    => PTW_I_Invalid_Addr(),
    PTW_Access()          => PTW_I_Access(),
    PTW_Invalid_PTE()     => PTW_I_Invalid_PTE(),
    PTW_No_Permission()   => PTW_I_No_Permission(),
    PTW_Misaligned()      => PTW_I_Misaligned(),
    PTW_PTE_Update()      => PTW_I_PTE_Update(),
    PTW_Ext_Error()       => PTW_I_Ext_Error(),
    PTW_Implicit(_, _, _) => internal_error(__FILE__, __LINE__, "cannot convert implicit PTW error")
  }
}

// PRIVATE: only 'to_str' overload is public
function ptw_error_to_str(e : PTW_Error) -> string = {
  match e {
    PTW_Invalid_Addr()    => "invalid-source-addr",
    PTW_Access()          => "mem-access-error",
    PTW_Invalid_PTE()     => "invalid-pte",
    PTW_No_Permission()   => "no-permission",
    PTW_Misaligned()      => "misaligned-superpage",
    PTW_PTE_Update()      => "pte-update-needed",
    PTW_Implicit(_, _, _) => "implicit-access-error",
    PTW_Ext_Error(e)      => "extension-error"
  }
}

// PUBLIC
overload to_str = {ptw_error_to_str}

// hook for (non-standard) extensions to customize errors reported by page-table
// walks during address translation; it typically works in conjunction
// with any customization to check_PTE_permission().

// PRIVATE
function ext_get_ptw_error(eptwf : ext_ptw_fail) -> PTW_Error =
  PTW_No_Permission()

// PRIVATE
/*! Convert translation/PTW failures into architectural exceptions */
function translationException(a : AccessType(ext_access_type),
                              s : AddressTranslationStage,
                              f : PTW_Error)
                              -> ExceptionType = {
  let e : ExceptionType = match (a, f) {
    (_, PTW_Ext_Error(e))         => E_Extension(ext_translate_exception(e)),
    (_, PTW_Implicit(fi, _, _))   => match (a, fi) { // Report exception for the original access type (of explicit page-walk)
                                       (_, PTW_I_Ext_Error(e))         => E_Extension(ext_translate_exception(e)),
                                       (ReadWrite(_), PTW_I_Access())  => E_SAMO_Access_Fault(),
                                       (ReadWrite(_), _)               => E_SAMO_GPage_Fault(),
                                       (Read(_), PTW_I_Access())       => E_Load_Access_Fault(),
                                       (Read(_), _)                    => E_Load_GPage_Fault(),
                                       (Write(_), PTW_I_Access())      => E_SAMO_Access_Fault(),
                                       (Write(_), _)                   => E_SAMO_GPage_Fault(),
                                       (Execute(), PTW_I_Access())     => E_Fetch_Access_Fault(),
                                       (Execute(), _)                  => E_Fetch_GPage_Fault()},
    (ReadWrite(_), PTW_Access())  => E_SAMO_Access_Fault(),
    (ReadWrite(_), _)             => E_SAMO_Page_Fault(),
    (Read(_), PTW_Access())       => E_Load_Access_Fault(),
    (Read(_), _)                  => E_Load_Page_Fault(),
    (Write(_), PTW_Access())      => E_SAMO_Access_Fault(),
    (Write(_), _)                 => E_SAMO_Page_Fault(),
    (Execute(), PTW_Access())     => E_Fetch_Access_Fault(),
    (Execute(), _)                => E_Fetch_Page_Fault()
  };

  /* Convert exceptions resulting from G-stage page walks to the correct architectural exception:
   *   - Guest-page-fault exceptions are raised instead of regular page-walk exceptions
   *   - Any exception is always reported for the original access type */
  if s == Stage_G then
    match exceptionType_update_AccessType(e, a) {
      E_Fetch_Page_Fault() => E_Fetch_GPage_Fault(),
      E_Load_Page_Fault()  => E_Load_GPage_Fault(),
      E_SAMO_Page_Fault()  => E_SAMO_GPage_Fault(),
      _ => e /* Other exceptions should not be converted */
    }
  else e
}

// PRIVATE
/*! Build a pseudoinstruction encoding for a given access type and architecture */
function pseudoinst(ac : AccessType(ext_access_type), arch : Architecture) -> bits(32) = {
  match (arch, ac) {
    (RV32, Read(_))  => 0x00002000,
    (RV32, Write(_)) => 0x00002020,
    (RV64, Read(_))  => 0x00003000,
    (RV64, Write(_)) => 0x00003020,
    (_, _) => internal_error(__FILE__, __LINE__, "Illegal pseudoinst architecture/access type")
  }
}

// PRIVATE
/*! Build architectural exception context for translation/PTW failures */
function translationExcContext(f     : PTW_Error,
                               vaddr : bits(64),
                               gva   : bool)
                               -> ExceptionContext = {
  match f {
    PTW_Ext_Error(e)            => ext_exception_context(e),
    PTW_Implicit(f, gpaddr, ac) => {
      let pinst : option(xlenbits) = match f {
        PTW_I_Access()     => None(),
        PTW_I_Ext_Error(_) => None(),
        _                  => Some(zero_extend(pseudoinst(ac, cur_Architecture()))),
      } in
      vmem_exception_context(truncate(vaddr, sizeof(xlen)), true, Some(truncate(gpaddr >> 2, sizeof(xlen))), pinst)
    },
    _ => vmem_exception_context(truncate(vaddr, sizeof(xlen)), gva, None(), None()),
  }
}
