// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

// Type constraint that checks if 'v is a valid virtual memory mode size.
type is_sv_mode('v) -> Bool = 'v in {32, 39, 48, 57}

// Range of possible page levels depending on the virtual memory mode:
//
//   Sv32 = range(0, 1)
//   Sv39 = range(0, 2)
//   Sv48 = range(0, 3)
//   Sv57 = range(0, 4)
//
type level_range('v), is_sv_mode('v) =
  range(0, (if 'v == 32 then 1 else (if 'v == 39 then 2 else (if 'v == 48 then 3 else 4))))

// Size of a Page Table Entry, depending on the virtual memory mode.
type pte_bits('v), is_sv_mode('v) = bits(if 'v == 32 then 32 else 64)

// Number of Physical Page Number bits, depending on the virtual memory mode.
type ppn_bits('v), is_sv_mode('v) = bits(if 'v == 32 then 22 else 44)

// Number of Virtual Page Number bits, depending on the virtual memory mode.
type vpn_bits('v), is_sv_mode('v) = bits('v - pagesize_bits)

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
    Load(p)             => "R" ^ mem_payload_str(p),
    LoadReserved(p)     => "R" ^ mem_payload_str(p),
    Store(p)            => "W" ^ mem_payload_str(p),
    StoreConditional(p) => "W" ^ mem_payload_str(p),
    Atomic(_, lp, sp)   => "R" ^ mem_payload_str(lp) ^ "W" ^ mem_payload_str(sp),
    InstructionFetch()  => "X",
    CacheAccess(_)      => "C",
  }

overload to_str = {accessType_to_str}

function is_shadow_stack_access(access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Load(ShadowStack)                   => true,
    Store(ShadowStack)                  => true,
    Atomic(_, ShadowStack, ShadowStack) => true,

    InstructionFetch()                  => false,
    Load(Data)                          => false,
    Load(Vector)                        => false,
    Load(PageTableEntry)                => false,
    LoadReserved(Data)                  => false,
    Store(Data)                         => false,
    Store(Vector)                       => false,
    Store(PageTableEntry)               => false,
    StoreConditional(Data)              => false,
    Atomic(_, Data, Data)               => false,
    CacheAccess(_)                      => false,

    LoadReserved(p)                     => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for LoadReserved."),
    StoreConditional(p)                 => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for StoreConditional."),
    Atomic(_, rp, wp)                   => internal_error(__FILE__, __LINE__, "Invalid payloads (" ^ mem_payload_name(rp) ^ ", " ^ mem_payload_name(wp) ^ ") for Atomic."),
  }

function is_amo_access(access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Atomic(_) => true,
    _         => false,
  }

function is_shadow_stack_amo(access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Atomic(_, ShadowStack, ShadowStack) => true,
    _                                   => false,
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
