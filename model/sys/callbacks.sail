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

val ptw_start_callback = pure {cpp: "ptw_start_callback"} : (TranslationStage, /* level */ range(0, 4), /* vpn */ bits(64), /* access type */ MemoryAccessType(mem_payload), /* privilege */ Privilege) -> unit
function ptw_start_callback(_) = ()

val ptw_step_callback = pure {cpp: "ptw_step_callback"} : (TranslationStage, /* level */ range(0, 4), /* pte_addr */ physaddrbits, /* pte */ bits(64)) -> unit
function ptw_step_callback(_) = ()

val ptw_success_callback = pure {cpp: "ptw_success_callback"} : (TranslationStage, /* level */ range(0, 4), /* final_ppn */ bits(64)) -> unit
function ptw_success_callback(_) = ()

val ptw_fail_callback = pure {cpp: "ptw_fail_callback"} : (TranslationStage, /* level */ range(0, 4), /* error_type */ PTW_Error, /* pte_addr */ physaddrbits) -> unit
function ptw_fail_callback(_) = ()

// In the address translation callbacks, the virtual address `vaddr`
// is specified in `physaddrbits` since it could be a guest physical
// address in a G-stage translation; the `paddr` is the result of the
// translation for the `access` of `width` bytes.
//
// For two-stage translation, the start callback can be followed by
// upto two associated address-translated callbacks, one for each
// stage.  There may also be zero such callbacks; in this case, there
// would be an associated `trap_callback`.
//
// M-mode `Bare` "address translation completions" are reported as
// S-stage translations; these can be disambiguated by an M-mode
// privilege in the start callback and zero associated
// `ptw_start_callback`s.

val address_translation_start_callback = pure {cpp: "address_translation_start_callback"} : forall 'n, 0 < 'n <= max_mem_access . (TranslationStage, Privilege, /* vaddr */ physaddrbits, /* access */ MemoryAccessType(mem_payload), /* width */ int('n)) -> unit
val address_translated_callback = pure {cpp: "address_translated_callback"} : forall 'n, 0 < 'n <= max_mem_access . (TranslationStage, /* vaddr */ physaddrbits, /* paddr */ physaddrbits, /* access */ MemoryAccessType(mem_payload), /* width */ int('n)) -> unit
function address_translated_callback(_) = ()

// Instruction retire callback.  This allows tracking retires without using
// minstret, since that is only conditionally incremented on retires.
val instret_callback = pure {cpp: "instret_callback"} : (unit) -> unit
function instret_callback() = ()
