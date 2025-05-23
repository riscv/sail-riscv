/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Implementation of Physical Memory Attributes. These describe
// how memory accesses to different regions of memory behave.
// Very little is specified about PMAs, and there is no standard
// interface to query or control them. This implementation only
// provides static PMAs (dynamic PMAs are possible) and there
// is no way to query them (this information would normally be
// available in Device Tree, ACPI, or just "known").
//
// Since they are mostly implementation-defined, we try to
// provide a range of useful options that are likely to cover
// most implementations.

enum AtomicSupport = { AMONone, AMOSwap, AMOLogical, AMOArithmetic }

mapping atomic_support_str : AtomicSupport <-> string = {
  AMONone       <-> "AMONone",
  AMOSwap       <-> "AMOSwap",
  AMOLogical    <-> "AMOLogical",
  AMOArithmetic <-> "AMOArithmetic",
}
overload to_str = {atomic_support_str}

enum Reservability = { RsrvNone, RsrvNonEventual, RsrvEventual }

mapping reservability_str : Reservability <-> string = {
  RsrvNone        <-> "RsrvNone",
  RsrvNonEventual <-> "RsrvNonEventual",
  RsrvEventual    <-> "RsrvEventual",
}
overload to_str = {reservability_str}

// Do misaligned accesses (of any kind) to this region cause
// a fault, and if so which kind. This is for regions that
// only support aligned accesses.
enum MisalignedFault = { NoFault, AccessFault, AlignmentFault }

mapping misaligned_fault_str : MisalignedFault <-> string = {
  NoFault        <-> "NoFault",
  AccessFault    <-> "AccessFault",
  AlignmentFault <-> "AlignmentFault",
}
overload to_str = {misaligned_fault_str}

// Physical Memory Attributes for a region.
struct PMA = {
  // These have no effect on the model currently but they are affected
  // by PBMT so they need to be here if the resulting PMA is verified.
  cacheable       : bool,
  coherent        : bool,
  // If false then attempting to access this PMA during instruction fetch
  // will cause a fetch access fault.
  executable      : bool,
  // If false when reading/writing for data access then this will cause
  // an access fault.
  readable        : bool,
  writable        : bool,
  readIdempotent  : bool,
  writeIdempotent : bool,
  // Optionally cause an access/alignment fault on misaligned access.
  misalignedFault : MisalignedFault,
  atomicSupport   : AtomicSupport,
  reservability   : Reservability,
  // Flags whether this memory supports CBO.zero. Note that main memory regions must
  // have this set.
  supportsCboZero : bool,
}

// A region of memory and its Physical Memory Attributes.
struct PMA_Region = {
  base       : physaddrbits,
  size       : physaddrbits,
  attributes : PMA,
}

// Get the first PMA that matches a given address range.
function matching_pma(pmas : list(PMA_Region), addr : physaddr, width : mem_access_width) -> option(PMA_Region) = {
  match pmas {
    [||] => None(),
    pma :: rest => {
      if range_subset(bits_of(addr), bits_of(addr) + width, pma.base, pma.base + pma.size)
      then Some(pma)
      else matching_pma(rest, addr, width)
    },
  }
}

function pma_attributes_to_str(attr : PMA) -> string =
  (if attr.cacheable then " cacheable" else "") ^
  (if attr.coherent then " coherent" else "") ^
  (if attr.executable then " executable" else "") ^
  (if attr.readable then " readable" else "") ^
  (if attr.writable then " writable" else "") ^
  (if attr.readIdempotent then " read-idempotent" else "") ^
  (if attr.writeIdempotent then " write-idempotent" else "") ^
  " MisalignedFault:" ^ to_str(attr.misalignedFault) ^
  " " ^ to_str(attr.atomicSupport) ^
  " " ^ to_str(attr.reservability) ^
  (if attr.supportsCboZero then " supportsCboZero" else "")

function pma_region_to_str(region : PMA_Region) -> string =
  "base: " ^ bits_str(region.base) ^ " size: " ^ bits_str(region.size)
    ^ pma_attributes_to_str(region.attributes)

overload to_str = {pma_attributes_to_str, pma_region_to_str}

// The list of PMAs. The behaviour is undefined if these overlap.
register pma_regions : list(PMA_Region) = config memory.regions

function accessFaultFromAccessType(accTy : AccessType(ext_access_type)) -> ExceptionType =
  match accTy {
    InstructionFetch() => E_Fetch_Access_Fault(),
    Read(Data)         => E_Load_Access_Fault(),
    _                  => E_SAMO_Access_Fault(),
  }

function alignmentFaultFromAccessType(accTy : AccessType(ext_access_type)) -> ExceptionType =
  match accTy {
    InstructionFetch() => E_Fetch_Addr_Align(),
    Read(Data)         => E_Load_Addr_Align(),
    _                  => E_SAMO_Addr_Align(),
  }
