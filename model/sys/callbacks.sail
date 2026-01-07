// Page table walk callbacks

// We have to pass Privilege inside a tuple so that it gets generated as a
// struct in C++ rather than an unscoped enum which cannot be forward-declared.
// If we didn't do this then we end up with a circular dependency due to the
// dependency chain
//
// hart::Model ---derives from---> PlatformInterface ---uses---> hart::zPrivilege.
//
// This chain is circular, but `hart::Model` and `hart::zPrivilege` are in the same
// header file, so we have a circular dependency of header files.
//
// A better fix would be to modify the Sail compiler so that it outputs
// the types (hart::zPrivilege etc.) in a separate header to hart::Model.
// See https://github.com/rems-project/sail/issues/1560

val ptw_start_callback = pure {cpp: "ptw_start_callback"} : (/* vpn */ bits(64), /* access type */ MemoryAccessType(mem_payload), /* privilege */ (Privilege, unit)) -> unit
function ptw_start_callback(_) = ()

val ptw_step_callback = pure {cpp: "ptw_step_callback"} : (/* level */ range(0, 4), /* pte_addr */ physaddrbits, /* pte */ bits(64)) -> unit
function ptw_step_callback(_) = ()

val ptw_success_callback = pure {cpp: "ptw_success_callback"} : (/* final_ppn */ bits(64), /* level */ range(0, 4)) -> unit
function ptw_success_callback(_) = ()

val ptw_fail_callback = pure {cpp: "ptw_fail_callback"} : (/* error_type */ PTW_Error, /* level */ range(0, 4), /* pte_addr */ physaddrbits) -> unit
function ptw_fail_callback(_) = ()
