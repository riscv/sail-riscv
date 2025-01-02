/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Although a TLB is not part of the RISC-V Architecture
// specification, we model a simple TLB so that
// (1) we can meaningfully test SFENCE.VMA which would be a no-op wihout a TLB;
// (2) we can greatly speed up simulation speed (for Linux boot, can
//     reduce elapsed time from 10s of minutes to few minutes).

type asidbits = bits(16)

// PRIVATE
struct TLB_Entry = {
  asid       : asidbits,  // address-space id
  global     : bool,      // global translation
  vAddr      : bits(64),  // VPN
  pAddr      : bits(64),  // ppn
  vMatchMask : bits(64),  // matching mask for superpages
  vAddrMask  : bits(64),  // selection mask for superpages
  pte        : bits(64),  // PTE
  pteAddr    : bits(64),  // for dirty writeback
  age        : bits(64)   // for replacement policy?
}

// 64 entries is based on benchmarks of Linux boots and is where you stop
// seeing performance improvements.
type num_tlb_entries : Int = 64
type tlb_index_range = range(0, num_tlb_entries - 1)

// PRIVATE
register tlb : vector(num_tlb_entries, option(TLB_Entry)) = vector_init(None())

// Indexed by the lowest bits of the VPN.
function tlb_hash(vaddr : bits(64)) -> tlb_index_range =
  unsigned(vaddr[17 .. 12])

// PUBLIC: invoked in init_vmem() [riscv_vmem.sail]
function init_TLB() -> unit = {
  foreach (i from 0 to (length(tlb) - 1)) {
    tlb[i] = None();
  }
}

// PUBLIC: invoked in translate_TLB_hit() [riscv_vmem.sail]
function write_TLB(index : tlb_index_range, ent : TLB_Entry) -> unit =
  tlb[index] = Some(ent)

// PRIVATE
function match_TLB_Entry(ent   : TLB_Entry,
                         asid  : asidbits,
                         vaddr : bits(64)) -> bool =
  (ent.global | (ent.asid == asid))
  & (ent.vAddr == (ent.vMatchMask & vaddr))

// PRIVATE
function flush_TLB_Entry(e    : TLB_Entry,
                         asid : option(asidbits),
                         addr : option(bits(64))) -> bool = {
  match (asid, addr) {
    ( None(),  None()) => true,
    ( None(), Some(a)) => e.vAddr == (e.vMatchMask & a),
    (Some(i),  None()) => (e.asid == i) & not(e.global),
    (Some(i), Some(a)) => (  (e.asid == i) & (e.vAddr == (a & e.vMatchMask))
                           & not(e.global))
  }
}

// PUBLIC: invoked in translate() [riscv_vmem.sail]
function lookup_TLB (asid : asidbits, vaddr : bits(64)) -> option((tlb_index_range, TLB_Entry)) = {
  let index = tlb_hash(vaddr);
  match tlb[index] {
    None() => None(),
    Some(entry) => if match_TLB_Entry(entry, asid, vaddr) then Some((index, entry)) else None(),
  }
}

// PRIVATE
function add_to_TLB(asid          : asidbits,
                    vAddr         : bits(64),
                    pAddr         : bits(64),
                    pte           : bits(64),
                    pteAddr       : bits(64),
                    level         : nat,
                    global        : bool,
                    levelBitSize  : nat,
                    pagesize_bits : nat) -> unit = {
  let shift = pagesize_bits + (level * levelBitSize);
  assert(shift <= 64);
  let vAddrMask  : bits(64)  = zero_extend(ones(shift));
  let vMatchMask : bits(64)  = ~ (vAddrMask);

  let entry : TLB_Entry = struct{asid       = asid,
                                 global     = global,
                                 pte        = pte,
                                 pteAddr    = pteAddr,
                                 vAddrMask  = vAddrMask,
                                 vMatchMask = vMatchMask,
                                 vAddr      = vAddr & vMatchMask,
                                 pAddr      = pAddr & vMatchMask,
                                 age        = mcycle};

  // Add the TLB entry. Note that this may be a super-page, but we still want
  // to add it to the index corresponding to the page because that is how
  // lookup_TLB looks it up. For superpages will just end up with the same
  // TLB entry in multiple slots.
  let index = tlb_hash(vAddr);
  tlb[index] = Some(entry);
}

// Top-level TLB flush function
// PUBLIC: invoked from exec SFENCE_VMA
function flush_TLB(asid_xlen : option(xlenbits),
                   addr_xlen : option(xlenbits)) -> unit = {
  let asid : option(asidbits) =
    match asid_xlen {
      None()  => None(),
      Some(a) => Some(a[15 .. 0])
    };
  let addr_64b : option(bits(64)) =
    match addr_xlen {
      None()  => None(),
      Some(a) => Some(zero_extend(a))
    };
  foreach (i from 0 to (length(tlb) - 1)) {
    match tlb[i] {
      Some(e) => if flush_TLB_Entry(e, asid, addr_64b) then { tlb[i] = None(); },
      None()  => (),
    }
  }
}
