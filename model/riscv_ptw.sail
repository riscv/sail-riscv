/* failure modes for address-translation/page-table-walks */

union PTW_Error = {
  PTW_Access        : unit,          /* physical memory access error for a PTE */
  PTW_Invalid_PTE   : unit,
  PTW_No_Permission : unit,
  PTW_Misaligned    : unit,          /* misaligned superpage */
  PTW_PTE_Update    : unit,          /* PTE update needed but not enabled */
  PTW_Ext_Error     : ext_ptw_error  /* parameterized for errors from extensions */
}

val ptw_error_to_str : PTW_Error -> string
function ptw_error_to_str(e) =
  match (e) {
    PTW_Access()         => "mem-access-error",
    PTW_Invalid_PTE()    => "invalid-pte",
    PTW_No_Permission()  => "no-permission",
    PTW_Misaligned()     => "misaligned-superpage",
    PTW_PTE_Update()     => "pte-update-needed",
    PTW_Ext_Error(e)     => "extension-error"
  }

overload to_str = {ptw_error_to_str}

/* conversion of these translation/PTW failures into architectural exceptions */
function translationException(a : AccessType(ext_access_type_r,ext_access_type_w),
                              f : PTW_Error)
                             -> ExceptionType = {
  let e : ExceptionType =
  match (a, f) {
    (_, PTW_Ext_Error(e))           => E_Extension(ext_translate_exception(e)),
    (ReadWrite(Data), PTW_Access()) => E_SAMO_Access_Fault(),
    (ReadWrite(Data), _)            => E_SAMO_Page_Fault(),
    (Read(Data), PTW_Access())      => E_Load_Access_Fault(),
    (Read(Data), _)                 => E_Load_Page_Fault(),
    (Write(Data), PTW_Access())     => E_SAMO_Access_Fault(),
    (Write(Data), _)                => E_SAMO_Page_Fault(),
    (Execute(), PTW_Access())       => E_Fetch_Access_Fault(),
    (Execute(), _)                  => E_Fetch_Page_Fault()
  } in {
/*  print_mem("translationException(" ^ a ^ ", " ^ f ^ ") -> " ^ e); */
    e
  }
}
