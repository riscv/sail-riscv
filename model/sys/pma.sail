// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================

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

// Set of atomic instructions supported by memory.
// Each value is a superset of the previous ones.
enum AtomicSupport = {
  AMONone,
  AMOSwap,
  AMOLogical,
  AMOArithmetic,
  // These require Zacas.
  AMOCASW,
  AMOCASD,
  AMOCASQ,
}

mapping atomic_support_str : AtomicSupport <-> string = {
  AMONone       <-> "AMONone",
  AMOSwap       <-> "AMOSwap",
  AMOLogical    <-> "AMOLogical",
  AMOArithmetic <-> "AMOArithmetic",
  AMOCASW       <-> "AMOCASW",
  AMOCASD       <-> "AMOCASD",
  AMOCASQ       <-> "AMOCASQ",
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
enum misaligned_fault = { NoFault, AccessFault, AlignmentFault }

mapping misaligned_fault_str : misaligned_fault <-> string = {
  NoFault        <-> "NoFault",
  AccessFault    <-> "AccessFault",
  AlignmentFault <-> "AlignmentFault",
}
overload to_str = {misaligned_fault_str}

enum MemoryRegionType = { MainMemory, IOMemory }

// Physical Memory Attributes for a region.
struct PMA = {
  // These have no effect on the model currently but they are affected
  // by PBMT so they need to be here if the resulting PMA is verified.
  cacheable        : bool,
  coherent         : bool,
  // If false then attempting to access this PMA during instruction fetch
  // will cause a fetch access fault.
  executable       : bool,
  // If false when reading/writing for data access then this will cause
  // an access fault.
  readable         : bool,
  writable         : bool,
  read_idempotent  : bool,
  write_idempotent : bool,
  // Optionally cause an access/alignment fault on misaligned access.
  misaligned_fault : misaligned_fault,
  // TODO: Atomicity PMA. This is not supported yet because
  // the MemoryAccessType needs to be extended to indicate the AMO type.
  // atomic_support   : AtomicSupport,
  reservability    : Reservability,
  // Flags whether this memory supports CBO.zero. Note that main memory regions must
  // have this set.
  supports_cbo_zero : bool,
  // TODO: Misaligned Atomicity Granule PMA
  // TODO: Memory Ordering PMA
}

// A region of memory and its Physical Memory Attributes.
struct PMA_Region = {
  // TODO: These should be physaddrbits, but currently that doesn't work due to a compiler bug:
  // https://github.com/rems-project/sail/issues/1392
  base       : bits(64),
  size       : bits(64),
  attributes : PMA,
  // If set to `false` this will be excluded from the generated device tree.
  // This doesn't affect Sail's execution at all; it's just a convenience
  // for generating a device tree that matches the PMAs.
  include_in_device_tree : bool,
}

// Get the first PMA region that fully contains a given [base, base+size) range.
function matching_pma_bits_range(pmas : list(PMA_Region), base : bits(64), size : bits(64)) -> option(PMA_Region) = {
  match pmas {
    [||] => None(),
    pma :: rest => {
      if range_subset(base, size, pma.base, pma.size)
      then Some(pma)
      else matching_pma_bits_range(rest, base, size)
    }
  }
}

// Get the first PMA that matches a given address range.
// Delegate to matching_pma_bits_range to avoid duplicating the range logic.
function matching_pma(pmas : list(PMA_Region), addr : physaddr, width : mem_access_width) -> option(PMA_Region) = {
  matching_pma_bits_range(pmas, zero_extend(bits_of(addr)), to_bits(width))
}

// Technically you can have a region that satisfies these properties
// but is still declared as IOMemory but we don't support that yet.
function memory_region_type(pma : PMA) -> MemoryRegionType =
  // TODO: the memory ordering attribute needs to be considered here once it is implemented
  if pma.readable & pma.writable & pma.read_idempotent & pma.write_idempotent
  then MainMemory
  else IOMemory

function pma_attributes_to_str(attr : PMA) -> string =
  (if attr.cacheable then " cacheable" else "") ^
  (if attr.coherent then " coherent" else "") ^
  (if attr.executable then " executable" else "") ^
  (if attr.readable then " readable" else "") ^
  (if attr.writable then " writable" else "") ^
  (if attr.read_idempotent then " read-idempotent" else "") ^
  (if attr.write_idempotent then " write-idempotent" else "") ^
  " misaligned_fault:" ^ to_str(attr.misaligned_fault) ^
  // TODO: Atomicity PMA.
  // " " ^ to_str(attr.atomic_support) ^
  " " ^ to_str(attr.reservability) ^
  (if attr.supports_cbo_zero then " supports_cbo_zero" else "")

function pma_region_to_str(region : PMA_Region) -> string =
  "base: " ^ bits_str(region.base) ^ " size: " ^ bits_str(region.size)
    ^ pma_attributes_to_str(region.attributes)

overload to_str = {pma_attributes_to_str, pma_region_to_str}

// The list of PMAs. These must be sorted and cannot overlap.
register pma_regions : list(PMA_Region) = config memory.regions
