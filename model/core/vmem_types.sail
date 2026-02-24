// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Type constraint that checks if 'v is a valid virtual memory mode size.
type is_sv_mode('v) -> Bool = 'v in {32, 39, 48, 57}
type is_svx4_mode('v) -> Bool = 'v in {34, 41, 50, 59}
type is_sv_or_svx4_mode('v : Int) -> Bool = is_sv_mode('v) | is_svx4_mode('v)
type is_sv32_mode('v : Int) -> Bool = 'v == 32 | 'v == 34

// Index of the root page table level, depending on the virtual mode.
type root_level('v : Int), is_sv_or_svx4_mode('v) =
  if      'v == 32 | 'v == 34 then 1
  else if 'v == 39 | 'v == 41 then 2
  else if 'v == 48 | 'v == 50 then 3
  else 4

val get_root_level : forall 'v, is_sv_or_svx4_mode('v). int('v) -> int(root_level('v))
function get_root_level(sv_width) = sizeof(root_level('v))

// Range of possible page levels depending on the virtual memory mode:
//
//   Sv32/Sv32x4 = range(0, 1)
//   Sv39/Sv39x4 = range(0, 2)
//   Sv48/Sv48x4 = range(0, 3)
//   Sv57/Sv57x4 = range(0, 4)
//
type level_range('v : Int), is_sv_or_svx4_mode('v) = range(0, root_level('v))

// Log2 of the PTE size in bytes, depending on the virtual mode.
type log_pte_size_bytes('v : Int), is_sv_or_svx4_mode('v) = if is_sv32_mode('v) then 2 else 3

// Number of VPN bits per page table level, depending on the virtual mode.
// This is the size for regular levels only. The root level for G-stage
// modes has 2 extra bits.
type vpn_level_size('v : Int), is_sv_or_svx4_mode('v) = pagesize_bits - log_pte_size_bytes('v)

val get_vpn_level_size : forall 'v, is_sv_or_svx4_mode('v). int('v) -> int(vpn_level_size('v))
function get_vpn_level_size(sv_width) = sizeof(vpn_level_size('v))

// Size of a Page Table Entry, depending on the virtual memory mode.
type pte_bits('v), is_sv_or_svx4_mode('v) = bits(if is_sv32_mode('v) then 32 else 64)

// Number of Physical Page Number bits, depending on the virtual memory mode.
type ppn_bits('v), is_sv_or_svx4_mode('v) = bits(if is_sv32_mode('v) then 22 else 44)

// Number of Virtual Page Number bits, depending on the virtual memory mode.
type vpn_bits('v), is_sv_or_svx4_mode('v) = bits('v - pagesize_bits)

// TODO: For Zicfiss, this enum will be extended with ShadowStack, and
// for CHERI, this enum can be extended with Cap/Tagged.  This assumes
// that capabilities cannot be stored to the ShadowStack; this is
// implied by CHERI and Zicfiss currently being incompatible.
//
// If, instead, CHERI and Zicfiss are made compatible, this could perhaps be
// handled by adding ShadowStack{Load,Store,Atomic} variants to
// MemoryAccessType and removing the ShadowStack variant here.

enum mem_payload = { Data }

mapping mem_payload_str : mem_payload <-> string = {
  Data <-> "",
}

let default_write_acc : mem_payload = Data

function accessType_to_str(access : MemoryAccessType(mem_payload)) -> string =
  match access {
    Load(p)             => "R" ^ mem_payload_str(p),
    LoadReserved(p)     => "R" ^ mem_payload_str(p),
    Store(p)            => "W" ^ mem_payload_str(p),
    StoreConditional(p) => "W" ^ mem_payload_str(p),
    Atomic(_, lp, sp)   => "R" ^ mem_payload_str(lp) ^ "W" ^ mem_payload_str(sp),
    InstructionFetch()  => "X",
    CacheAccess(_)      => "C",
  }

overload to_str = {accessType_to_str}

// Stage of Address Translation

enum TranslationStage = {S_Stage, VS_Stage, G_Stage}
