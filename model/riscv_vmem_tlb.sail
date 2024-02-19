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

// Single-entry TLB (could enlarge this in future for better simulation speed)
// PRIVATE
register tlb : option(TLB_Entry) = None()

// PUBLIC: invoked in init_vmem() [riscv_vmem.sail]
function init_TLB() -> unit =
  tlb = None()

// PUBLIC: invoked in translate_TLB_hit() [riscv_vmem.sail]
function write_TLB(idx : nat, ent : TLB_Entry) -> unit =
  tlb = Some(ent)

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
function lookup_TLB (asid : asidbits, vaddr : bits(64)) -> option((nat, TLB_Entry)) =
  match tlb {
    None()  => None(),
    Some(e) => if match_TLB_Entry(e, asid, vaddr) then Some((0, e)) else None()
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
                    PAGESIZE_BITS : nat)     -> unit = {
  let shift = PAGESIZE_BITS + (level * levelBitSize);
  assert(shift <= 64);
  let vAddrMask  : bits(64)  = zero_extend(ones(shift));
  let vMatchMask : bits(64)  = ~ (vAddrMask);
  let entry      : TLB_Entry = struct{asid       = asid,
                                      global     = global,
                                      pte        = pte,
                                      pteAddr    = pteAddr,
                                      vAddrMask  = vAddrMask,
                                      vMatchMask = vMatchMask,
                                      vAddr      = vAddr & vMatchMask,
                                      pAddr      = shiftl(shiftr(pAddr, shift), shift),
                                      age        = mcycle};
  tlb = Some(entry)
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
  match tlb {
    None()  => (),
    Some(e) => if flush_TLB_Entry(e, asid, addr_64b)
               then tlb = None()
               else ()
  }
}
