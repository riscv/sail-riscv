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

// Number of VPN bits per page table level, depending on the virtual mode.
// This is the size for regular levels only. The root level for G-stage
// modes has 2 extra bits. (log2 of PTE size is 2 for Sv32, 3 otherwise.)
// Inlined rather than via a type function so the Coq backend can print it.
type vpn_level_size('v : Int), is_sv_or_svx4_mode('v) = pagesize_bits - (if is_sv32_mode('v) then 2 else 3)

val get_vpn_level_size : forall 'v, is_sv_or_svx4_mode('v). int('v) -> int(vpn_level_size('v))
function get_vpn_level_size(sv_width) = sizeof(vpn_level_size('v))

// Size of a Page Table Entry, depending on the virtual memory mode.
type pte_bits('v), is_sv_or_svx4_mode('v) = bits(if is_sv32_mode('v) then 32 else 64)

// Number of Physical Page Number bits, depending on the virtual memory mode.
type ppn_bits('v), is_sv_or_svx4_mode('v) = bits(if is_sv32_mode('v) then 22 else 44)

// Number of Virtual Page Number bits, depending on the virtual memory mode.
type vpn_bits('v), is_sv_or_svx4_mode('v) = bits('v - pagesize_bits)

// TODO: For CHERI, this enum can be extended with Cap/Tagged.  This assumes
// that capabilities cannot be stored to the ShadowStack; this is
// implied by CHERI and Zicfiss currently being incompatible.
//
// If, instead, CHERI and Zicfiss are made compatible, this could perhaps be
// handled by adding ShadowStack{Load,Store,Atomic} variants to
// MemoryAccessType and removing the ShadowStack variant here.

enum mem_payload = { Data, Vector, PageTableEntry, ShadowStack }

mapping mem_payload_name : mem_payload <-> string = {
  Data           <-> "Data",
  Vector         <-> "Vector",
  PageTableEntry <-> "PageTableEntry",
  ShadowStack    <-> "ShadowStack",
}

mapping mem_payload_str : mem_payload <-> string = {
  Data            <-> "",
  Vector          <-> "",
  PageTableEntry  <-> "",
  ShadowStack     <-> ".ss",
}

function accessType_to_str(access : MemoryAccessType(mem_payload)) -> string =
  match access {
    Load(p)                   => "R" ^ mem_payload_str(p),
    LoadReserved(_, _, p)     => "R" ^ mem_payload_str(p),
    Store(p)                  => "W" ^ mem_payload_str(p),
    StoreConditional(_, _, p) => "W" ^ mem_payload_str(p),
    Atomic(_, _, _, lp, sp)   => "R" ^ mem_payload_str(lp) ^ "W" ^ mem_payload_str(sp),
    InstructionFetch()        => "X",
    LoadExecute(p)            => "RX" ^ mem_payload_str(p),
    CacheAccess(_)            => "C",
  }

overload to_str = {accessType_to_str}

function is_shadow_stack_access(access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Load(ShadowStack)                   => true,
    Store(ShadowStack)                  => true,

    Atomic(_, _, _, ShadowStack, ShadowStack) => true,

    InstructionFetch()                  => false,
    Load(Data)                          => false,
    Load(Vector)                        => false,
    Load(PageTableEntry)                => false,
    LoadExecute(Data)                   => false,
    LoadReserved(_, _, Data)            => false,
    Store(Data)                         => false,
    Store(Vector)                       => false,
    Store(PageTableEntry)               => false,
    StoreConditional(_, _, Data)        => false,
    Atomic(_, _, _, Data, Data)         => false,
    CacheAccess(_)                      => false,


    LoadExecute(p)                      => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for LoadExecute."),
    LoadReserved(_, _, p)               => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for LoadReserved."),
    StoreConditional(_, _, p)           => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for StoreConditional."),
    Atomic(_, _, _, rp, wp)             => internal_error(__FILE__, __LINE__, "Invalid payloads (" ^ mem_payload_name(rp) ^ ", " ^ mem_payload_name(wp) ^ ") for Atomic."),
  }

function is_amo_access(access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Atomic(_) => true,
    _         => false,
  }

function is_shadow_stack_amo(access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Atomic(_, _, _, ShadowStack, ShadowStack) => true,
    _                                         => false,
  }

function is_vector_access(access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Load(Vector)  => true,
    Store(Vector) => true,
    _             => false,
  }

// Memory attributes for Page-based Memory Types

enum page_based_mem_type = { PBMT_PMA, PBMT_NC, PBMT_IO }

mapping page_based_mem_type : bits(2) <-> page_based_mem_type = {
  0b00 <-> PBMT_PMA,
  0b01 <-> PBMT_NC,
  0b10 <-> PBMT_IO,
}

// Stage of Address Translation
enum TranslationStage = {S_Stage, VS_Stage, G_Stage}
