
import THE_MODULE_NAME.Sail.Sail

open Sail

def print_endline (_ : String) : Unit := ()
def prerr_endline (_: String) : Unit := ()
def prerr_string (_: String) : Unit := ()
def putchar {T} (_: T ) : Unit := ()
def string_of_int (z : Int) := s!"{z}"

axiom sys_enable_writable_misa : Unit → Bool
axiom sys_enable_rvc : Unit → Bool
axiom sys_enable_fdext : Unit → Bool
axiom sys_enable_svinval : Unit → Bool
axiom sys_enable_zcb : Unit → Bool
axiom sys_enable_zfinx : Unit → Bool
axiom sys_enable_writable_fiom : Unit → Bool
axiom sys_enable_vext : Unit → Bool
axiom sys_enable_bext : Unit → Bool
axiom sys_enable_zicbom : Unit → Bool
axiom sys_enable_zicboz : Unit → Bool
axiom sys_enable_sstc : Unit → Bool
axiom sys_writable_hpm_counters : Unit → BitVec 32

axiom sys_vext_vl_use_ceil : Unit → Bool
axiom sys_vector_elen_exp : Unit → Nat
axiom sys_vector_vlen_exp : Unit → Nat

axiom sys_pmp_count : Unit → Nat
axiom sys_pmp_count_ok : 0 ≤ sys_pmp_count () ∧ sys_pmp_count () ≤ 64
axiom sys_pmp_grain : Unit → Nat
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

-- Floats
abbrev bits_rm := BitVec 3  -- Rounding mode
abbrev bits_fflags := BitVec 5  -- Accrued exceptions: NV,DZ,OF,UF,NX
abbrev bits_H := BitVec 16  -- Half-precision float value
abbrev bits_S := BitVec 32  -- Single-precision float value
abbrev bits_D := BitVec 64  -- Double-precision float value

abbrev bits_W := BitVec 32  -- Signed integer
abbrev bits_WU := BitVec 32  -- Unsigned integer

abbrev bits_L := BitVec 64  -- Signed integer
abbrev bits_LU := BitVec 64  -- Unsigned integer

axiom extern_f16Add : bits_rm → bits_H → bits_H → Unit
axiom extern_f16Sub : bits_rm → bits_H → bits_H → Unit
axiom extern_f16Mul : bits_rm → bits_H → bits_H → Unit
axiom extern_f16Div : bits_rm → bits_H → bits_H → Unit
axiom extern_f32Add : bits_rm → bits_S → bits_S → Unit
axiom extern_f32Sub : bits_rm → bits_S → bits_S → Unit
axiom extern_f32Mul : bits_rm → bits_S → bits_S → Unit
axiom extern_f32Div : bits_rm → bits_S → bits_S → Unit
axiom extern_f64Add : bits_rm → bits_D → bits_D → Unit
axiom extern_f64Sub : bits_rm → bits_D → bits_D → Unit
axiom extern_f64Mul : bits_rm → bits_D → bits_D → Unit
axiom extern_f64Div : bits_rm → bits_D → bits_D → Unit
axiom extern_f16MulAdd : bits_rm → bits_H → bits_H → bits_H → Unit
axiom extern_f32MulAdd : bits_rm → bits_S → bits_S → bits_S → Unit
axiom extern_f64MulAdd : bits_rm → bits_D → bits_D → bits_D → Unit
axiom extern_f16Sqrt : bits_rm → bits_H → Unit
axiom extern_f32Sqrt : bits_rm → bits_S → Unit
axiom extern_f64Sqrt : bits_rm → bits_D → Unit
axiom extern_f16ToI32 : bits_rm → bits_H → Unit
axiom extern_f16ToUi32 : bits_rm → bits_H → Unit
axiom extern_i32ToF16 : bits_rm → bits_W → Unit
axiom extern_ui32ToF16 : bits_rm → bits_WU → Unit
axiom extern_f16ToI64 : bits_rm → bits_H → Unit
axiom extern_f16ToUi64 : bits_rm → bits_H → Unit
axiom extern_i64ToF16 : bits_rm → bits_L → Unit
axiom extern_ui64ToF16 : bits_rm → bits_L → Unit
axiom extern_f32ToI32 : bits_rm → bits_S → Unit
axiom extern_f32ToUi32 : bits_rm → bits_S → Unit
axiom extern_i32ToF32 : bits_rm → bits_W → Unit
axiom extern_ui32ToF32 : bits_rm → bits_WU → Unit
axiom extern_f32ToI64 : bits_rm → bits_S → Unit
axiom extern_f32ToUi64 : bits_rm → bits_S → Unit
axiom extern_i64ToF32 : bits_rm → bits_L → Unit
axiom extern_ui64ToF32 : bits_rm → bits_L → Unit
axiom extern_f64ToI32 : bits_rm → bits_D → Unit
axiom extern_f64ToUi32 : bits_rm → bits_D → Unit
axiom extern_i32ToF64 : bits_rm → bits_W → Unit
axiom extern_ui32ToF64 : bits_rm → bits_WU → Unit
axiom extern_f64ToI64 : bits_rm → bits_D → Unit
axiom extern_f64ToUi64 : bits_rm → bits_D → Unit
axiom extern_i64ToF64 : bits_rm → bits_L → Unit
axiom extern_ui64ToF64 : bits_rm → bits_LU → Unit
axiom extern_f16ToF32 : bits_rm → bits_H → Unit
axiom extern_f16ToF64 : bits_rm → bits_H → Unit
axiom extern_f32ToF64 : bits_rm → bits_S → Unit
axiom extern_f32ToF16 : bits_rm → bits_S → Unit
axiom extern_f64ToF16 : bits_rm → bits_D → Unit
axiom extern_f64ToF32 : bits_rm → bits_D → Unit
axiom extern_f16Lt : bits_H → bits_H → Unit
axiom extern_f16Lt_quiet : bits_H → bits_H → Unit
axiom extern_f16Le : bits_H → bits_H → Unit
axiom extern_f16Le_quiet : bits_H → bits_H → Unit
axiom extern_f16Eq : bits_H → bits_H → Unit
axiom extern_f32Lt : bits_S → bits_S → Unit
axiom extern_f32Lt_quiet : bits_S → bits_S → Unit
axiom extern_f32Le : bits_S → bits_S → Unit
axiom extern_f32Le_quiet : bits_S → bits_S → Unit
axiom extern_f32Eq : bits_S → bits_S → Unit
axiom extern_f64Lt : bits_D → bits_D → Unit
axiom extern_f64Lt_quiet : bits_D → bits_D → Unit
axiom extern_f64Le : bits_D → bits_D → Unit
axiom extern_f64Le_quiet : bits_D → bits_D → Unit
axiom extern_f64Eq : bits_D → bits_D → Unit
axiom extern_f16roundToInt : bits_rm → bits_H → Bool → Unit
axiom extern_f32roundToInt : bits_rm → bits_S → Bool → Unit
axiom extern_f64roundToInt : bits_rm → bits_D → Bool → Unit
