-- =======================================================================================
--   This Sail RISC-V architecture model, comprising all files and
--   directories except where otherwise noted is subject the BSD
--   two-clause license in the LICENSE file.
--
--   SPDX-License-Identifier: BSD-2-Clause
-- =======================================================================================

import Sail.Sail
import THE_MODULE_NAME.Defs

open Sail
open ConcurrencyInterfaceV1

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

def plat_term_write {α} : α → SailM Unit := λ _ => panic "TODO: plat_term_write"
def plat_term_read : Unit → SailM String := λ _ => panic "TODO: plat_term_read"

-- Reservations
def load_reservation : Arch.pa → Nat → SailM Unit := λ _ => panic "TODO: load_reservation"
def match_reservation : Arch.pa → Bool := λ _ => panic "TODO: match_reservation"
def cancel_reservation : Unit → SailM Unit := λ _ => dbg_trace "TODO: cancel_reservation"; return ()
def valid_reservation : Unit → Bool := λ _ => false

def get_16_random_bits : Unit → SailM (BitVec 16) := λ _ => panic "TODO: get_16_random_bits"
def sys_enable_experimental_extensions : Unit → Bool := λ _ => false

end Effectful

-- Floats
def riscv_f16Add : BitVec 3 → BitVec 16 → BitVec 16 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f16Add"
def riscv_f16Sub : BitVec 3 → BitVec 16 → BitVec 16 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f16Sub"
def riscv_f16Mul : BitVec 3 → BitVec 16 → BitVec 16 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f16Mul"
def riscv_f16Div : BitVec 3 → BitVec 16 → BitVec 16 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f16Div"
def riscv_f32Add : BitVec 3 → BitVec 32 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32Add"
def riscv_f32Sub : BitVec 3 → BitVec 32 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32Sub"
def riscv_f32Mul : BitVec 3 → BitVec 32 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32Mul"
def riscv_f32Div : BitVec 3 → BitVec 32 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32Div"
def riscv_f64Add : BitVec 3 → BitVec 64 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64Add"
def riscv_f64Sub : BitVec 3 → BitVec 64 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64Sub"
def riscv_f64Mul : BitVec 3 → BitVec 64 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64Mul"
def riscv_f64Div : BitVec 3 → BitVec 64 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64Div"
def riscv_f16MulAdd : BitVec 3 → BitVec 16 → BitVec 16 → BitVec 16 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f16MulAdd"
def riscv_f32MulAdd : BitVec 3 → BitVec 32 → BitVec 32 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32MulAdd"
def riscv_f64MulAdd : BitVec 3 → BitVec 64 → BitVec 64 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64MulAdd"
def riscv_f16Sqrt : BitVec 3 → BitVec 16 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f16Sqrt"
def riscv_f32Sqrt : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32Sqrt"
def riscv_f64Sqrt : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64Sqrt"
def riscv_f16ToI32 : BitVec 3 → BitVec 16 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f16ToI32"
def riscv_f16ToUi32 : BitVec 3 → BitVec 16 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f16ToUi32"
def riscv_i32ToF16 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_i32ToF16"
def riscv_ui32ToF16 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_ui32ToF16"
def riscv_f16ToI64 : BitVec 3 → BitVec 16 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f16ToI64"
def riscv_f16ToUi64 : BitVec 3 → BitVec 16 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f16ToUi64"
def riscv_i64ToF16 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_i64ToF16"
def riscv_ui64ToF16 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_ui64ToF16"
def riscv_f32ToI32 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32ToI32"
def riscv_f32ToUi32 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32ToUi32"
def riscv_i32ToF32 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_i32ToF32"
def riscv_ui32ToF32 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_ui32ToF32"
def riscv_f32ToI64 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f32ToI64"
def riscv_f32ToUi64 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f32ToUi64"
def riscv_i64ToF32 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_i64ToF32"
def riscv_ui64ToF32 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_ui64ToF32"
def riscv_f64ToI32 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f64ToI32"
def riscv_f64ToUi32 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f64ToUi32"
def riscv_i32ToF64 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_i32ToF64"
def riscv_ui32ToF64 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_ui32ToF64"
def riscv_f64ToI64 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64ToI64"
def riscv_f64ToUi64 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64ToUi64"
def riscv_i64ToF64 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_i64ToF64"
def riscv_ui64ToF64 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_ui64ToF64"
def riscv_f16ToF32 : BitVec 3 → BitVec 16 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f16ToF32"
def riscv_f16ToF64 : BitVec 3 → BitVec 16 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f16ToF64"
def riscv_f32ToF64 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f32ToF64"
def riscv_f32ToF16 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f32ToF16"
def riscv_f64ToF16 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f64ToF16"
def riscv_f64ToF32 : BitVec 3 → BitVec 64 → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f64ToF32"
def riscv_f32ToBF16 : BitVec 3 → BitVec 32 → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f32ToBF16"
def riscv_f16Lt : BitVec 16 → BitVec 16 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f16Lt"
def riscv_f16Lt_quiet : BitVec 16 → BitVec 16 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f16Lt_quiet"
def riscv_f16Le : BitVec 16 → BitVec 16 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f16Le"
def riscv_f16Le_quiet : BitVec 16 → BitVec 16 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f16Le_quiet"
def riscv_f16Eq : BitVec 16 → BitVec 16 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f16Eq"
def riscv_f32Lt : BitVec 32 → BitVec 32 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f32Lt"
def riscv_f32Lt_quiet : BitVec 32 → BitVec 32 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f32Lt_quiet"
def riscv_f32Le : BitVec 32 → BitVec 32 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f32Le"
def riscv_f32Le_quiet : BitVec 32 → BitVec 32 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f32Le_quiet"
def riscv_f32Eq : BitVec 32 → BitVec 32 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f32Eq"
def riscv_f64Lt : BitVec 64 → BitVec 64 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f64Lt"
def riscv_f64Lt_quiet : BitVec 64 → BitVec 64 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f64Lt_quiet"
def riscv_f64Le : BitVec 64 → BitVec 64 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f64Le"
def riscv_f64Le_quiet : BitVec 64 → BitVec 64 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f64Le_quiet"
def riscv_f64Eq : BitVec 64 → BitVec 64 → (BitVec 5 × Bool) := λ _ => panic "TODO: riscv_f64Eq"
def riscv_f16roundToInt : BitVec 3 → BitVec 16 → Bool → (BitVec 5 × BitVec 16) := λ _ => panic "TODO: riscv_f16roundToInt"
def riscv_f32roundToInt : BitVec 3 → BitVec 32 → Bool → (BitVec 5 × BitVec 32) := λ _ => panic "TODO: riscv_f32roundToInt"
def riscv_f64roundToInt : BitVec 3 → BitVec 64 → Bool → (BitVec 5 × BitVec 64) := λ _ => panic "TODO: riscv_f64roundToInt"

-- Termination of extensionEnabled
instance : SizeOf extension where
  sizeOf := extension.ctorIdx

macro_rules | `(tactic| decreasing_trivial) => `(tactic| decide)
