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
private union PTW_Error = {
  PTW_Invalid_Addr     : unit,          // invalid source address
  PTW_No_Access        : unit,          // physical memory access error for a PTE
  PTW_Invalid_PTE      : unit,
  PTW_No_Permission    : unit,
  PTW_Misaligned       : unit,          // misaligned superpage
  PTW_PTE_Needs_Update : unit,          // PTE update needed but not enabled
  PTW_Ext_Error        : ext_ptw_error  // parameterized for errors from extensions
}

private function ptw_error_to_str(e : PTW_Error) -> string = {
  match e {
    PTW_Invalid_Addr()     => "invalid-source-addr",
    PTW_No_Access()        => "mem-access-error",
    PTW_Invalid_PTE()      => "invalid-pte",
    PTW_No_Permission()    => "no-permission",
    PTW_Misaligned()       => "misaligned-superpage",
    PTW_PTE_Needs_Update() => "pte-update-needed",
    PTW_Ext_Error(_)       => "extension-error"
  }
}

overload to_str = {ptw_error_to_str}

// hook for (non-standard) extensions to customize errors reported by page-table
// walks during address translation; it typically works in conjunction
// with any customization to check_PTE_permission().

private function ext_get_ptw_error(failure : pte_check_failure) -> PTW_Error =
  match failure {
    PTE_No_Permission() => PTW_No_Permission(),
    PTE_Ext_Failure(_)  => PTW_No_Permission(),
    // TODO: Zicfiss will map PTE_No_Access to PTW_Access
  }

// Convert translation/PTW failures into architectural exceptions
function translationException(
  access : MemoryAccessType(mem_payload),
  err : PTW_Error
) -> ExceptionType = {
  match (access, err) {
    (_, PTW_Ext_Error(e)) => E_Extension(ext_translate_exception(e)),
    (t, e) => {
      let t = AccessType_to_AccessException(t);
      match e {
        PTW_No_Access() => AccessException_to_E_Access_Fault(t),
        _               => AccessException_to_E_Page_Fault(t),
      }
    }
  };
}
