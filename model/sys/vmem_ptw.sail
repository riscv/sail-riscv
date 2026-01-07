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
function translationException(access : MemoryAccessType(mem_payload),
                              err : PTW_Error)
                             -> ExceptionType = {
  match (access, err) {
    (_, PTW_Ext_Error(e))                     => E_Extension(ext_translate_exception(e)),
    (Atomic(_), PTW_No_Access())              => E_SAMO_Access_Fault(),
    (Atomic(_), _)                            => E_SAMO_Page_Fault(),
    (Load(_), PTW_No_Access())                => E_Load_Access_Fault(),
    (LoadReserved(_), PTW_No_Access())        => E_Load_Access_Fault(),
    (Load(_), _)                              => E_Load_Page_Fault(),
    (LoadReserved(_), _)                      => E_Load_Page_Fault(),
    (Store(_), PTW_No_Access())               => E_SAMO_Access_Fault(),
    (StoreConditional(_), PTW_No_Access())    => E_SAMO_Access_Fault(),
    (Store(_), _)                             => E_SAMO_Page_Fault(),
    (StoreConditional(_), _)                  => E_SAMO_Page_Fault(),
    (InstructionFetch(), PTW_No_Access())     => E_Fetch_Access_Fault(),
    (InstructionFetch(), _)                   => E_Fetch_Page_Fault(),
    (CacheAccess(CB_manage()), _)             => E_SAMO_Page_Fault(),
    (CacheAccess(CB_zero()), PTW_No_Access()) => E_SAMO_Access_Fault(),
    (CacheAccess(CB_zero()), _)               => E_SAMO_Page_Fault(),
    // Though prefetches don't raise exceptions, we return a nominal
    // exception here to propagate the failed address translation to
    // the execute of the calling instruction so that it can decide
    // whether to actually proceed with a prefetch.
    (CacheAccess(CB_prefetch(_)), _)          => E_Load_Access_Fault(),
  }
}
