
import THE_MODULE_NAME.Sail.Sail

open Sail

def print_endline (_ : String) : Unit := ()
def prerr_endline (_: String) : Unit := ()
def prerr_string (_: String) : Unit := ()
def putchar {T} (_: T ) : Unit := ()
def string_of_int (z : Int) := s!"{z}"

axiom sys_enable_writable_misa : Unit -> Bool
axiom sys_enable_rvc : Unit -> Bool
axiom sys_enable_fdext : Unit -> Bool
axiom sys_enable_svinval : Unit -> Bool
axiom sys_enable_zcb : Unit -> Bool
axiom sys_enable_zfinx : Unit -> Bool
axiom sys_enable_writable_fiom : Unit -> Bool
axiom sys_enable_vext : Unit -> Bool
axiom sys_enable_bext : Unit -> Bool
axiom sys_enable_zicbom : Unit -> Bool
axiom sys_enable_zicboz : Unit -> Bool
axiom sys_enable_sstc : Unit -> Bool
axiom sys_writable_hpm_counters : Unit -> BitVec 32

axiom sys_vext_vl_use_ceil : Unit -> Bool
axiom sys_vector_elen_exp : Unit -> Nat
axiom sys_vector_vlen_exp : Unit -> Nat

axiom sys_pmp_count : Unit -> Nat
axiom sys_pmp_count_ok : 0 ≤ sys_pmp_count () ∧ sys_pmp_count () ≤ 64
axiom sys_pmp_grain : Unit -> Nat
axiom sys_pmp_grain_ok : 0 ≤ sys_pmp_grain () ∧ sys_pmp_grain () ≤ 63

section defs

variable [Arch]

-- Platform definitions
axiom plat_ram_base : Unit → Arch.pa
axiom plat_ram_size : Unit → Arch.pa
axiom elf_tohost : Unit → Int
axiom elf_entry : Unit → Int
axiom plat_enable_dirty_update : Unit → Bool
axiom plat_enable_misaligned_access : Unit → Bool
axiom plat_mtval_has_illegal_inst_bits  : Unit → Bool
axiom plat_rom_base : Unit → Arch.pa
axiom plat_rom_size : Unit → Arch.pa
axiom plat_htif_tohost : Unit → Arch.pa
axiom plat_clint_base : Unit → Arch.pa
axiom plat_clint_size : Unit → Arch.pa
axiom plat_insns_per_tick : Unit → Int

-- TODO import Sail module
axiom plat_term_write {α β} : α → β
axiom plat_term_read {α} : Unit → α
