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

function pma_atomicity_support_gt(x : AtomicSupport, y : AtomicSupport) -> bool = num_of_AtomicSupport(x) > num_of_AtomicSupport(y)
function pma_atomicity_support_lt(x : AtomicSupport, y : AtomicSupport) -> bool = num_of_AtomicSupport(x) < num_of_AtomicSupport(y)
function pma_atomicity_support_ge(x : AtomicSupport, y : AtomicSupport) -> bool = num_of_AtomicSupport(x) >= num_of_AtomicSupport(y)
function pma_atomicity_support_le(x : AtomicSupport, y : AtomicSupport) -> bool = num_of_AtomicSupport(x) <= num_of_AtomicSupport(y)

overload operator > = {pma_atomicity_support_gt}
overload operator < = {pma_atomicity_support_lt}
overload operator >= = {pma_atomicity_support_ge}
overload operator <= = {pma_atomicity_support_le}

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

function pma_allows_atomic_op forall 'n, 0 < 'n <= max_mem_access . (pma : AtomicSupport, op : amoop, width : int('n)) -> bool =
  match pma {
    AMONone       => false,
    AMOSwap       => op == AMOSWAP,
    AMOLogical    => op == AMOSWAP | op == AMOAND | op == AMOOR | op == AMOXOR,
    AMOArithmetic => op != AMOCAS,
    AMOCASW       => op != AMOCAS | width <= 4,
    AMOCASD       => op != AMOCAS | width <= 8,
    AMOCASQ       => op != AMOCAS | width <= 16,
  }

enum Reservability = { RsrvNone, RsrvNonEventual, RsrvEventual }

mapping reservability_str : Reservability <-> string = {
  RsrvNone        <-> "RsrvNone",
  RsrvNonEventual <-> "RsrvNonEventual",
  RsrvEventual    <-> "RsrvEventual",
}
overload to_str = {reservability_str}

enum MemoryRegionType = { MainMemory, IOMemory }
mapping memory_region_type_str : MemoryRegionType <-> string = {
  MainMemory <-> "main memory",
  IOMemory   <-> "IO memory",
}
overload to_str = {memory_region_type_str}

// PMA misalignment handling.  Misalignment for LR/SC is handled
// before address-translation.
struct PMAMisalignedExceptions = {
  load_store : option(misaligned_exception),
  vector     : option(misaligned_exception),
  amo        : misaligned_exception,
}

// The MAG size is restricted by the page size.
type mag_size_exp = range(0, pagesize_bits)

// Physical Memory Attributes for a region.
struct PMA = {
  mem_type         : MemoryRegionType,
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
  // Misaligned handling for various accesses.
  misaligned_exceptions : PMAMisalignedExceptions,
  atomic_support   : AtomicSupport,
  reservability    : Reservability,
  // Flags whether this memory supports CBO.zero. Note that main memory regions must
  // have this set.
  supports_cbo_zero : bool,
  // Flags whether this memory supports hardware page table reads.
  supports_pte_read : bool,
  // Flags whether this memory supports hardware page table writes.
  supports_pte_write : bool,
  // The size of the optional misaligned atomicity granule is 2^misaligned_atomicity_granule_exp.
  // The value of 0 is used to indicate the attribute is absent.
  misaligned_atomicity_granule_size_exp : mag_size_exp,
  // TODO: Memory Ordering PMA
}

// A PMA can be overridden by page-based memory types.
// TODO: specify alignment for IO regions.
function override_PMA(pma : PMA, pbmt : page_based_mem_type) -> PMA =
  match pbmt {
    PBMT_PMA => pma,
    // TODO: return a weakly-ordered PMA
    PBMT_NC  => {pma with mem_type = MainMemory,
                          cacheable = false,
                          read_idempotent = true,
                          write_idempotent = true},
    // TODO: return a strongly ordered PMA
    PBMT_IO  => {pma with mem_type = IOMemory,
                          cacheable = false,
                          read_idempotent = false,
                          write_idempotent = false},
  }

// Provide the misaligned treatment for a misaligned access.
function pma_misaligned_exception(pma : PMA, access : MemoryAccessType(mem_payload)) -> option(misaligned_exception) = {
  let exceptions = pma.misaligned_exceptions;
  match access {
    Load(Data)             => exceptions.load_store,
    Load(PageTableEntry)   => exceptions.load_store,
    Load(ShadowStack)      => exceptions.load_store,
    Store(Data)            => exceptions.load_store,
    Store(PageTableEntry)  => exceptions.load_store,
    Store(ShadowStack)     => exceptions.load_store,
    Load(Vector)           => exceptions.vector,
    Store(Vector)          => exceptions.vector,
    Atomic(_, _, _)        => Some(exceptions.amo),

    // These access types should not be misaligned at the PMA level.
    InstructionFetch()     => internal_error(__FILE__, __LINE__, "PMA: Invalid misaligned instruction fetch."),
    LoadReserved(p)        => internal_error(__FILE__, __LINE__, "PMA: Invalid misaligned load-reserved (" ^ mem_payload_name(p) ^ ")."),
    StoreConditional(p)    => internal_error(__FILE__, __LINE__, "PMA: Invalid misaligned store-conditional (" ^ mem_payload_name(p) ^ ")."),
    CacheAccess(_)         => internal_error(__FILE__, __LINE__, "PMA: Invalid misaligned cache-access."),
  }
}

private function is_mag_applicable_access(access : MemoryAccessType(mem_payload), width : nat) -> bool =
  match access {
    // loads/stores need to be XLEN bits or less
    Load(Data)                          => width <= xlen_bytes,
    Store(Data)                         => width <= xlen_bytes,
    Load(Vector)                        => false,
    Store(Vector)                       => false,
    // not applicable to implicit accesses
    Load(PageTableEntry)                => false,
    Store(PageTableEntry)               => false,
    // not in the base ISA
    Load(ShadowStack)                   => false,
    Store(ShadowStack)                  => false,
    // AMOs
    Atomic(_, Data, Data)               => true,
    // treat like an AMO
    Atomic(_, ShadowStack, ShadowStack) => true,

    // other not applicable
    InstructionFetch()                  => false,
    LoadReserved(Data)                  => false,
    StoreConditional(Data)              => false,
    CacheAccess(_)                      => false,

    Atomic(_, rp, wp)                   => internal_error(__FILE__, __LINE__, "Invalid payloads (" ^ mem_payload_name(rp) ^ ", " ^ mem_payload_name(wp) ^ ") for Atomic."),
    LoadReserved(p)                     => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for LoadReserved."),
    StoreConditional(p)                 => internal_error(__FILE__, __LINE__, "Invalid payload (" ^ mem_payload_name(p) ^ ") for StoreConditional."),
  }

// Check whether an access location is within a misaligned atomicity granule, if present.
function within_pma_mag forall 'n, 0 < 'n <= max_mem_access. (pma : PMA, Physaddr(addr) : physaddr, width : int('n)) -> bool = {
  let mag : mag_size_exp = pma.misaligned_atomicity_granule_size_exp;
  // no MAG present
  if mag == 0 then return false;
  // PMAs are restricted to page boundaries, so we can use the lowest xlen bits of the address.
  allowed_misaligned(addr[xlen - 1 .. 0], width, mag)
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
function matching_pma_region_bits_range(regions : list(PMA_Region), base : bits(64), size : bits(64)) -> option(PMA_Region) = {
  match regions {
    [||] => None(),
    region :: rest => {
      if range_subset(base, size, region.base, region.size)
      then Some(region)
      else matching_pma_region_bits_range(rest, base, size)
    }
  }
}

// Get the first PMA region that matches a given address range.
// Delegate to matching_pma_region_bits_range to avoid duplicating the range logic.
function matching_pma_region(regions : list(PMA_Region), addr : physaddr, width : mem_access_width) -> option(PMA_Region) = {
  matching_pma_region_bits_range(regions, zero_extend(bits_of(addr)), to_bits(width))
}

function pma_misaligned_to_str(m : PMAMisalignedExceptions) -> string =
  "misaligned-load-store:" ^ optional_misaligned_exception_str(m.load_store) ^
  " misaligned-amo:" ^ misaligned_exception_str(m.amo) ^
  " misaligned-vector:" ^ optional_misaligned_exception_str(m.vector)

overload to_str = {pma_misaligned_to_str}

function pma_attributes_to_str(attr : PMA) -> string =
  (match attr.mem_type { MainMemory => " main-memory", IOMemory => " io-memory", }) ^
  (if attr.cacheable then " cacheable" else "") ^
  (if attr.coherent then " coherent" else "") ^
  (if attr.executable then " executable" else "") ^
  (if attr.readable then " readable" else "") ^
  (if attr.writable then " writable" else "") ^
  (if attr.read_idempotent then " read-idempotent" else "") ^
  (if attr.write_idempotent then " write-idempotent" else "") ^
  " " ^ to_str(attr.misaligned_exceptions) ^
  " " ^ to_str(attr.atomic_support) ^
  " misaligned_atomicity_granule_size_exp=" ^ dec_str(attr.misaligned_atomicity_granule_size_exp) ^
  " " ^ to_str(attr.reservability) ^
  (if attr.supports_cbo_zero then " supports-cbo-zero" else "") ^
  (if attr.supports_pte_read then " supports-pte-read" else "") ^
  (if attr.supports_pte_write then " supports-pte-write" else "") ^
  " "

function pma_region_to_str(region : PMA_Region) -> string =
  "base: " ^ bits_str(region.base) ^ " size: " ^ bits_str(region.size)
    ^ pma_attributes_to_str(region.attributes)

overload to_str = {pma_attributes_to_str, pma_region_to_str}

// The list of PMA regions. These must be sorted and cannot overlap.
register pma_regions : list(PMA_Region) = config memory.regions
