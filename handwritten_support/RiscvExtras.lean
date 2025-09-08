-- =======================================================================================
--   This Sail RISC-V architecture model, comprising all files and
--   directories except where otherwise noted is subject the BSD
--   two-clause license in the LICENSE file.
--
--   SPDX-License-Identifier: BSD-2-Clause
-- =======================================================================================

import THE_MODULE_NAME.Sail.Sail
import THE_MODULE_NAME.Defs

open Sail

def print_bits (_ : String) (_ : BitVec n) : Unit := ()
def print_string (_ : String) (_ : String) : Unit := ()
def prerr_string (_: String) : Unit := ()
def putchar {T} (_: T ) : Unit := ()
def string_of_int (z : Int) := s!"{z}"

section defs

variable [Arch]

-- Platform definitions
section Effectful

variable {Register : Type} {RegisterType : Register → Type} [DecidableEq Register] [Hashable Register]

axiom plat_term_write {α} : α → SailM Unit
axiom plat_term_read : Unit → SailM String

-- Reservations
axiom load_reservation : Arch.pa → SailM Unit
axiom match_reservation : Arch.pa → Bool
axiom cancel_reservation : Unit → SailM Unit
axiom valid_reservation : Unit → Bool

axiom get_16_random_bits : Unit → SailM (BitVec 16)

end Effectful

-- Floats
axiom extern_f16Add : BitVec 3 → BitVec 16 → BitVec 16 → Unit
axiom extern_f16Sub : BitVec 3 → BitVec 16 → BitVec 16 → Unit
axiom extern_f16Mul : BitVec 3 → BitVec 16 → BitVec 16 → Unit
axiom extern_f16Div : BitVec 3 → BitVec 16 → BitVec 16 → Unit
axiom extern_f32Add : BitVec 3 → BitVec 32 → BitVec 32 → Unit
axiom extern_f32Sub : BitVec 3 → BitVec 32 → BitVec 32 → Unit
axiom extern_f32Mul : BitVec 3 → BitVec 32 → BitVec 32 → Unit
axiom extern_f32Div : BitVec 3 → BitVec 32 → BitVec 32 → Unit
axiom extern_f64Add : BitVec 3 → BitVec 64 → BitVec 64 → Unit
axiom extern_f64Sub : BitVec 3 → BitVec 64 → BitVec 64 → Unit
axiom extern_f64Mul : BitVec 3 → BitVec 64 → BitVec 64 → Unit
axiom extern_f64Div : BitVec 3 → BitVec 64 → BitVec 64 → Unit
axiom extern_f16MulAdd : BitVec 3 → BitVec 16 → BitVec 16 → BitVec 16 → Unit
axiom extern_f32MulAdd : BitVec 3 → BitVec 32 → BitVec 32 → BitVec 32 → Unit
axiom extern_f64MulAdd : BitVec 3 → BitVec 64 → BitVec 64 → BitVec 64 → Unit
axiom extern_f16Sqrt : BitVec 3 → BitVec 16 → Unit
axiom extern_f32Sqrt : BitVec 3 → BitVec 32 → Unit
axiom extern_f64Sqrt : BitVec 3 → BitVec 64 → Unit
axiom extern_f16ToI32 : BitVec 3 → BitVec 16 → Unit
axiom extern_f16ToUi32 : BitVec 3 → BitVec 16 → Unit
axiom extern_i32ToF16 : BitVec 3 → BitVec 32 → Unit
axiom extern_ui32ToF16 : BitVec 3 → BitVec 32 → Unit
axiom extern_f16ToI64 : BitVec 3 → BitVec 16 → Unit
axiom extern_f16ToUi64 : BitVec 3 → BitVec 16 → Unit
axiom extern_i64ToF16 : BitVec 3 → BitVec 64 → Unit
axiom extern_ui64ToF16 : BitVec 3 → BitVec 64 → Unit
axiom extern_f32ToI32 : BitVec 3 → BitVec 32 → Unit
axiom extern_f32ToUi32 : BitVec 3 → BitVec 32 → Unit
axiom extern_i32ToF32 : BitVec 3 → BitVec 32 → Unit
axiom extern_ui32ToF32 : BitVec 3 → BitVec 32 → Unit
axiom extern_f32ToI64 : BitVec 3 → BitVec 32 → Unit
axiom extern_f32ToUi64 : BitVec 3 → BitVec 32 → Unit
axiom extern_i64ToF32 : BitVec 3 → BitVec 64 → Unit
axiom extern_ui64ToF32 : BitVec 3 → BitVec 64 → Unit
axiom extern_f64ToI32 : BitVec 3 → BitVec 64 → Unit
axiom extern_f64ToUi32 : BitVec 3 → BitVec 64 → Unit
axiom extern_i32ToF64 : BitVec 3 → BitVec 32 → Unit
axiom extern_ui32ToF64 : BitVec 3 → BitVec 32 → Unit
axiom extern_f64ToI64 : BitVec 3 → BitVec 64 → Unit
axiom extern_f64ToUi64 : BitVec 3 → BitVec 64 → Unit
axiom extern_i64ToF64 : BitVec 3 → BitVec 64 → Unit
axiom extern_ui64ToF64 : BitVec 3 → BitVec 64 → Unit
axiom extern_f16ToF32 : BitVec 3 → BitVec 16 → Unit
axiom extern_f16ToF64 : BitVec 3 → BitVec 16 → Unit
axiom extern_f32ToF64 : BitVec 3 → BitVec 32 → Unit
axiom extern_f32ToF16 : BitVec 3 → BitVec 32 → Unit
axiom extern_f64ToF16 : BitVec 3 → BitVec 64 → Unit
axiom extern_f64ToF32 : BitVec 3 → BitVec 64 → Unit
axiom extern_f16Lt : BitVec 16 → BitVec 16 → Unit
axiom extern_f16Lt_quiet : BitVec 16 → BitVec 16 → Unit
axiom extern_f16Le : BitVec 16 → BitVec 16 → Unit
axiom extern_f16Le_quiet : BitVec 16 → BitVec 16 → Unit
axiom extern_f16Eq : BitVec 16 → BitVec 16 → Unit
axiom extern_f32Lt : BitVec 32 → BitVec 32 → Unit
axiom extern_f32Lt_quiet : BitVec 32 → BitVec 32 → Unit
axiom extern_f32Le : BitVec 32 → BitVec 32 → Unit
axiom extern_f32Le_quiet : BitVec 32 → BitVec 32 → Unit
axiom extern_f32Eq : BitVec 32 → BitVec 32 → Unit
axiom extern_f64Lt : BitVec 64 → BitVec 64 → Unit
axiom extern_f64Lt_quiet : BitVec 64 → BitVec 64 → Unit
axiom extern_f64Le : BitVec 64 → BitVec 64 → Unit
axiom extern_f64Le_quiet : BitVec 64 → BitVec 64 → Unit
axiom extern_f64Eq : BitVec 64 → BitVec 64 → Unit
axiom extern_f16roundToInt : BitVec 3 → BitVec 16 → Bool → Unit
axiom extern_f32roundToInt : BitVec 3 → BitVec 32 → Bool → Unit
axiom extern_f64roundToInt : BitVec 3 → BitVec 64 → Bool → Unit

-- Termination of currentlyEnabled
instance : SizeOf extension where
  sizeOf := extension.toCtorIdx

macro_rules | `(tactic| decreasing_trivial) => `(tactic| decide)
