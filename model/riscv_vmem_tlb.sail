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

type xxidbits = bits(16)

// PRIVATE
struct TLB_Entry = {
  xxid       : xxidbits,  // address-space id / virtual-machine id
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
register tlb_S : vector(num_tlb_entries, option(TLB_Entry)) = [
  None(), None(), None(), None(), None(), None(), None(), None(),
  None(), None(), None(), None(), None(), None(), None(), None(),
  None(), None(), None(), None(), None(), None(), None(), None(),
  None(), None(), None(), None(), None(), None(), None(), None(),
  None(), None(), None(), None(), None(), None(), None(), None(),
  None(), None(), None(), None(), None(), None(), None(), None(),
  None(), None(), None(), None(), None(), None(), None(), None(),
  None(), None(), None(), None(), None(), None(), None(), None(),
]

// Indexed by the lowest bits of the VPN.
function tlb_hash(vaddr : bits(64)) -> tlb_index_range =
  unsigned(vaddr[17 .. 12])

// PUBLIC: invoked in init_vmem() [riscv_vmem.sail]
function init_TLB() -> unit = {
  foreach (i from 0 to (length(tlb_S) - 1)) {
    tlb_S[i] = None();
  }
}

// PUBLIC: invoked in translate_TLB_hit() [riscv_vmem.sail]
function write_TLB(index : tlb_index_range, ent : TLB_Entry, stage : AddressTranslationStage) -> unit =
  // TODO: Update stage specific TLB
  tlb_S[index] = Some(ent)

// PRIVATE
function match_TLB_Entry(ent   : TLB_Entry,
                         xxid  : xxidbits,
                         vaddr : bits(64)) -> bool = false
  // FIXME: TLBs are not yet stage specific, never match is a temporary fix
  // (ent.global | (ent.xxid == xxid))
  // & (ent.vAddr == (ent.vMatchMask & vaddr))

// PRIVATE
function flush_TLB_Entry(e    : TLB_Entry,
                         xxid : option(xxidbits),
                         addr : option(bits(64))) -> bool = {
  match (xxid, addr) {
    ( None(),  None()) => true,
    ( None(), Some(a)) => e.vAddr == (e.vMatchMask & a),
    (Some(i),  None()) => (e.xxid == i) & not(e.global),
    (Some(i), Some(a)) => (  (e.xxid == i) & (e.vAddr == (a & e.vMatchMask))
                           & not(e.global))
  }
}

// PUBLIC: invoked in translate() [riscv_vmem.sail]
function lookup_TLB (xxid : xxidbits, stage : AddressTranslationStage, vaddr : bits(64)) -> option((tlb_index_range, TLB_Entry)) = {
  // TODO: Look in stage specific TLB
  let index = tlb_hash(vaddr);
  match tlb_S[index] {
    None() => None(),
    Some(entry) => if match_TLB_Entry(entry, xxid, vaddr) then Some((index, entry)) else None(),
  }
}

// PRIVATE
function add_to_TLB(xxid          : xxidbits,
                    stage         : AddressTranslationStage,
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

  let entry : TLB_Entry = struct{xxid       = xxid,
                                 global     = global,
                                 pte        = pte,
                                 pteAddr    = pteAddr,
                                 vAddrMask  = vAddrMask,
                                 vMatchMask = vMatchMask,
                                 vAddr      = vAddr & vMatchMask,
                                 pAddr      = pAddr & vMatchMask,
                                 age        = mcycle};

  // TODO: Add to stage specific TLB
  // Add the TLB entry. Note that this may be a super-page, but we still want
  // to add it to the index corresponding to the page because that is how
  // lookup_TLB looks it up. For superpages will just end up with the same
  // TLB entry in multiple slots.
  let index = tlb_hash(vAddr);
  tlb_S[index] = Some(entry);
}

// Top-level TLB flush function
// PUBLIC: invoked from exec SFENCE_VMA, HFENCE_VVMA and HFENCE_GVMA
function flush_TLB(asid_xlen : option(xlenbits),
                   stage     : AddressTranslationStage,
                   addr_xlen : option(xlenbits)) -> unit = {
  let xxid : option(xxidbits) =
    match asid_xlen {
      None()  => None(),
      Some(a) => Some(a[15 .. 0])
    };
  let addr_64b : option(bits(64)) =
    match addr_xlen {
      None()  => None(),
      Some(a) => Some(zero_extend(a))
    };
  // TODO: Flush from stage specific TLB
  foreach (i from 0 to (length(tlb_S) - 1)) {
    match tlb_S[i] {
      Some(e) => if flush_TLB_Entry(e, xxid, addr_64b) then { tlb_S[i] = None(); },
      None()  => (),
    }
  }
}
