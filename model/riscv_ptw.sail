/* failure modes for address-translation/page-table-walks */
enum PTW_Error = {
  PTW_Access,       /* physical memory access error for a PTE */
  PTW_Invalid_PTE,
  PTW_No_Permission,
  PTW_Misaligned,   /* misaligned superpage */
  PTW_PTE_Update    /* PTE update needed but not enabled */
}
val ptw_error_to_str : PTW_Error -> string
function ptw_error_to_str(e) =
  match (e) {
    PTW_Access        => "mem-access-error",
    PTW_Invalid_PTE   => "invalid-pte",
    PTW_No_Permission => "no-permission",
    PTW_Misaligned    => "misaligned-superpage",
    PTW_PTE_Update    => "pte-update-needed"
  }

overload to_str = {ptw_error_to_str}

/* conversion of these translation/PTW failures into architectural exceptions */
function translationException(a : AccessType(ext_access_type), f : PTW_Error) -> ExceptionType = {
  let e : ExceptionType =
  match (a, f) {
    (ReadWrite(Data), PTW_Access) => E_SAMO_Access_Fault,
    (ReadWrite(Data), _)          => E_SAMO_Page_Fault,
    (Read(Data), PTW_Access)      => E_Load_Access_Fault,
    (Read(Data), _)               => E_Load_Page_Fault,
    (Write(Data), PTW_Access)     => E_SAMO_Access_Fault,
    (Write(Data), _)              => E_SAMO_Page_Fault,
    (Execute(), PTW_Access)       => E_Fetch_Access_Fault,
    (Execute(), _)                => E_Fetch_Page_Fault
  } in {
/*  print_mem("translationException(" ^ a ^ ", " ^ f ^ ") -> " ^ e); */
    e
  }
}
