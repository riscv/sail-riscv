// Page table walk callback
val ptw_start_callback = pure {c: "ptw_start_callback"} : (/* vpn */ bits(64), /* access type */ MemoryAccessType(ext_access_type), /* privilege */ Privilege) -> unit
function ptw_start_callback(_) = ()

val ptw_step_callback = pure {c: "ptw_step_callback"} : (/* level */ int, /* pte_addr */ physaddrbits, /* pte */ bits(64)) -> unit
function ptw_step_callback(_) = ()

val ptw_success_callback = pure {c: "ptw_success_callback"} : (/* final_ppn */ bits(64), /* level */ int) -> unit
function ptw_success_callback(_) = ()

val ptw_fail_callback = pure {c: "ptw_fail_callback"} : (/* error_type */ PTW_Error, /* level */ int, /* pte_addr */ physaddrbits) -> unit
function ptw_fail_callback(_) = ()
