// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// ****************************************************************
// PTW exceptions

// 'ext_ptw' supports (non-standard) extensions to the default addr-translation and PTW.
// See types_ext.sail for definitions.

// Failure modes for address-translation/page-table-walks
// Note: Ideally we could use 'PTW_Implicit : (PTW_Error, ...)' in 'PTW_Error' but recursive types are not supported by sail
private union PTW_Implicit_Error = {
  PTW_I_Invalid_Addr  : unit,         // invalid source address
  PTW_I_No_Access     : unit,         // physical memory access error for a PTE
  PTW_I_Invalid_PTE   : unit,         // invalid page table entry or ptr PTE when level = 0
  PTW_I_No_Permission : unit,         // insufficient page permissions
  PTW_I_Misaligned    : unit,         // misaligned superpage
  PTW_I_PTE_Update    : unit,         // PTE update needed but not enabled
  PTW_I_Ext_Error     : ext_ptw_error // parameterized for errors from extensions
}
union PTW_Error = {
  PTW_Invalid_Addr     : unit,          // invalid source address
  PTW_No_Access        : unit,          // physical memory access error for a PTE
  PTW_Invalid_PTE      : unit,
  PTW_No_Permission    : unit,
  PTW_Misaligned       : unit,          // misaligned superpage
  PTW_PTE_Needs_Update : unit,          // PTE update needed but not enabled
  PTW_Ext_Error        : ext_ptw_error, // parameterized for errors from extensions

  PTW_Implicit         : (PTW_Implicit_Error,                 // error during implicit access/page-walk
                          bits(64),                           // faulting address of implicit access/page-walk
                          MemoryAccessType(ext_access_type)), // access type of implicit
}

// Convert PTW_Error to PTW_Implicit_Error
function ptw_implicit_error(f : PTW_Error) -> PTW_Implicit_Error = {
  match f {
    PTW_Invalid_Addr()     => PTW_I_Invalid_Addr(),
    PTW_No_Access()        => PTW_I_No_Access(),
    PTW_Invalid_PTE()      => PTW_I_Invalid_PTE(),
    PTW_No_Permission()    => PTW_I_No_Permission(),
    PTW_Misaligned()       => PTW_I_Misaligned(),
    PTW_PTE_Needs_Update() => PTW_I_PTE_Update(),
    PTW_Ext_Error()        => PTW_I_Ext_Error(),
    PTW_Implicit(_, _, _)  => internal_error(__FILE__, __LINE__, "cannot convert implicit PTW error")
  }
}

// PRIVATE: only 'to_str' overload is public
function ptw_error_to_str(e : PTW_Error) -> string = {
  match e {
    PTW_Invalid_Addr()     => "invalid-source-addr",
    PTW_No_Access()        => "mem-access-error",
    PTW_Invalid_PTE()      => "invalid-pte",
    PTW_No_Permission()    => "no-permission",
    PTW_Misaligned()       => "misaligned-superpage",
    PTW_PTE_Needs_Update() => "pte-update-needed",
    PTW_Ext_Error(_)       => "extension-error",
    PTW_Implicit(_, _, _)  => "implicit-access-error",
  }
}

// PUBLIC
overload to_str = {ptw_error_to_str}

// hook for (non-standard) extensions to customize errors reported by page-table
// walks during address translation; it typically works in conjunction
// with any customization to check_PTE_permission().

// PRIVATE
function ext_get_ptw_error(failure : pte_check_failure) -> PTW_Error =
  match failure {
    PTE_No_Permission() => PTW_No_Permission(),
    PTE_Ext_Failure(_)  => PTW_No_Permission(),
    // TODO: Zicfiss will map PTE_No_Access to PTW_Access
  }

// Convert translation/PTW failures into architectural exceptions
function translationException(a : MemoryAccessType(ext_access_type),
                              s : AddressTranslationStage,
                              e : PTW_Error)
                             -> ExceptionType = {
  let e : ExceptionType = match (a, e) {
    (_, PTW_Ext_Error(e))       => E_Extension(ext_translate_exception(e)),
    (_, PTW_Implicit(fi, _, _)) => match (a, fi) { // Report exception for the original access type (of explicit page-walk)
      (_, PTW_I_Ext_Error(e))                 => E_Extension(ext_translate_exception(e)),
      (LoadStore(_), PTW_I_No_Access())       => E_SAMO_Access_Fault(),
      (LoadStore(_), _)                       => E_SAMO_GPage_Fault(),
      (Load(_), PTW_I_No_Access())            => E_Load_Access_Fault(),
      (Load(_), _)                            => E_Load_GPage_Fault(),
      (Store(_), PTW_I_No_Access())           => E_SAMO_Access_Fault(),
      (Store(_), _)                           => E_SAMO_GPage_Fault(),
      (InstructionFetch(), PTW_I_No_Access()) => E_Fetch_Access_Fault(),
      (InstructionFetch(), _)                 => E_Fetch_GPage_Fault()
    },
    (LoadStore(_), PTW_No_Access())       => E_SAMO_Access_Fault(),
    (LoadStore(_), _)                     => E_SAMO_Page_Fault(),
    (Load(_), PTW_No_Access())            => E_Load_Access_Fault(),
    (Load(_), _)                          => E_Load_Page_Fault(),
    (Store(_), PTW_No_Access())           => E_SAMO_Access_Fault(),
    (Store(_), _)                         => E_SAMO_Page_Fault(),
    (InstructionFetch(), PTW_No_Access()) => E_Fetch_Access_Fault(),
    (InstructionFetch(), _)               => E_Fetch_Page_Fault()
  };

  // Convert exceptions resulting from G-stage page walks to the correct architectural exception:
  //   - Guest-page-fault exceptions are raised instead of regular page-walk exceptions
  //   - Any exception is always reported for the original access type
  if s == Stage_G then
    match exceptionType_update_AccessType(e, a) {
      E_Fetch_Page_Fault() => E_Fetch_GPage_Fault(),
      E_Load_Page_Fault()  => E_Load_GPage_Fault(),
      E_SAMO_Page_Fault()  => E_SAMO_GPage_Fault(),

      // Other exceptions should not be converted
      _ => e
    }
  else e
}

// Build a pseudoinstruction encoding for a given access type and architecture
private function pseudoinst(ac : MemoryAccessType(ext_access_type), arch : Architecture) -> bits(32) = {
  match (arch, ac) {
    (RV32, Load(_))  => 0x00002000,
    (RV32, Store(_)) => 0x00002020,
    (RV64, Load(_))  => 0x00003000,
    (RV64, Store(_)) => 0x00003020,
    (_, _) => internal_error(__FILE__, __LINE__, "Illegal pseudoinst architecture/access type")
  }
}

// Build architectural exception context for translation/PTW failures
private function translationExcContext(e     : PTW_Error,
                               vaddr : bits(64),
                               gva   : bool)
                               -> ExceptionContext = {
  match e {
    PTW_Ext_Error(e)            => ext_exception_context(e),
    PTW_Implicit(e, gpaddr, ac) => {
      let pinst : option(xlenbits) = match e {
        PTW_I_No_Access()  => None(),
        PTW_I_Ext_Error(_) => None(),
        _                  => Some(zero_extend(pseudoinst(ac, architecture(cur_privilege)))),
      };
      vmem_exception_context(truncate(vaddr, xlen), true, Some(truncate(gpaddr >> 2, xlen)), pinst)
    },
    _ => vmem_exception_context(truncate(vaddr, xlen), gva, None(), None()),
  }
}
