/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Although a TLB is not part of the RISC-V Architecture
// specification, we model a simple TLB so that
// (1) we can meaningfully test SFENCE.VMA which would be a no-op without a TLB;
// (2) we can greatly speed up simulation speed (for Linux boot, can
//     reduce elapsed time from 10s of minutes to few minutes).

// Maximum number of Virtual/Physical Page Number bits. The same TLB
// is used for all VM modes so these are the values for Sv57.
type tlb_vpn_bits : Int = 57 - pagesize_bits
let  tlb_vpn_bits = sizeof(tlb_vpn_bits)
type tlb_ppn_bits : Int = 44
let  tlb_ppn_bits = sizeof(tlb_ppn_bits)

// PRIVATE
// We use a single TLB for all virtual memory modes, so it can store up to
// Sv57-sized entries.
struct TLB_Entry = {
  asid       : asidbits,           // address-space id
  global     : bool,               // global translation
  vpn        : bits(tlb_vpn_bits), // Virtual Page Number. SvXX - 12 bits.
  levelMask  : bits(tlb_vpn_bits), // Mask for superpages. The lowest (level * level_bits) bits are 1s.
  ppn        : bits(tlb_ppn_bits), // Physical Page Number, 22 (Sv32), or 44 (Sv39+) bits.
  pte        : bits(64),           // PTE. This is only 32 bits for Sv32 so we zero extend.
  pteAddr    : physaddr,           // Physical address of PTE, for writing dirty/accessed bits.
}

// PTE access functions, for reading flags, and for modifying the dirty and
// accessed bits.
function tlb_get_pte forall 'n, 'n in {4, 8}. (
  pte_size  : int('n),
  ent       : TLB_Entry,
) -> bits('n * 8) = ent.pte[pte_size * 8 - 1 .. 0]

function tlb_set_pte forall 'n, 'n in {4, 8}. (
  ent : TLB_Entry,
  pte : bits('n * 8),
) -> TLB_Entry = { ent with pte=zero_extend(pte) }

function tlb_get_ppn forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  ent      : TLB_Entry,
  vpn      : vpn_bits('v),
) -> ppn_bits('v) = {
  // Sometimes the VPN is longer than the PPN (Sv39) and sometimes it is
  // shorter. This is ok because the most significant component can never be
  // included in the levelMask. To avoid complicated truncation and sign
  // extension we just extend to 64 bits and truncate at the end.
  let vpn : bits(64) = sign_extend(vpn);
  let levelMask : bits(64) = zero_extend(ent.levelMask);
  let ppn : bits(64) = zero_extend(ent.ppn);

  // E.g. if `level = 1` then this is a 2MB superpage. `levelMask` will
  // be zero_extend(ones(9 or 10)). The lowest 9 or 10 bits will
  // be taken from the translated vpn. The bits above that from the
  // cached ppn.
  trunc(ppn | (vpn & levelMask))
}

// 64 entries is based on benchmarks of Linux boots and is where you stop
// seeing performance improvements.
type num_tlb_entries : Int = 64
type tlb_index_range = range(0, num_tlb_entries - 1)

// PRIVATE
register tlb : vector(num_tlb_entries, option(TLB_Entry)) = vector_init(None())

// Indexed by the lowest bits of the VPN.
function tlb_hash forall 'v, is_sv_mode('v) . (
  sv_mode : int('v),
  vpn     : vpn_bits('v),
) -> tlb_index_range =
  unsigned(vpn[5 .. 0])

// PUBLIC: invoked in init_vmem() [riscv_vmem.sail]
function reset_TLB() -> unit = tlb = vector_init(None())

// PUBLIC: invoked in translate_TLB_hit()
function write_TLB(index : tlb_index_range, entry : TLB_Entry) -> unit =
  tlb[index] = Some(entry)

// PRIVATE
function match_TLB_Entry(
  ent  : TLB_Entry,
  asid : asidbits,
  vpn  : bits(tlb_vpn_bits),
) -> bool =
  (ent.global | (ent.asid == asid)) & (ent.vpn == (vpn & ~(ent.levelMask)))

// PRIVATE
function flush_TLB_Entry(ent   : TLB_Entry,
                         asid  : option(asidbits),
                         vaddr : option(xlenbits)) -> bool = {
  let asid_matches : bool = match asid {
    Some(asid) => ent.asid == asid & not(ent.global),
    None() => true,
  };
  let addr_matches : bool = match vaddr {
    Some(vaddr) => {
      let vaddr : bits(64) = sign_extend(vaddr);
      ent.vpn == (vaddr[56 .. pagesize_bits] & ~(ent.levelMask))
    },
    None() => true,
  };
  asid_matches & addr_matches
}

// PUBLIC: invoked in translate()
function lookup_TLB forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  vpn      : vpn_bits('v),
) -> option((tlb_index_range, TLB_Entry)) = {
  let index = tlb_hash('v, vpn);
  match tlb[index] {
    None() => None(),
    Some(entry) => {
      if match_TLB_Entry(entry, asid, sign_extend(vpn)) then Some((index, entry)) else None()
    },
  }
}

// PRIVATE
function add_to_TLB forall 'v, is_sv_mode('v) . (
  sv_width : int('v),
  asid     : asidbits,
  vpn      : vpn_bits('v),
  ppn      : ppn_bits('v),
  pte      : pte_bits('v),
  pteAddr  : physaddr,
  level    : level_range('v),
  global   : bool,
) -> unit = {
  let shift = level * (if 'v == 32 then 10 else 9);
  let levelMask = ones(shift);
  // Clear bits below the level.
  let vpn = vpn & ~(zero_extend(levelMask));
  let ppn = ppn & ~(zero_extend(levelMask));

  let entry : TLB_Entry = struct{asid      = asid,
                                 global    = global,
                                 pte       = zero_extend(pte),
                                 pteAddr   = pteAddr,
                                 levelMask = zero_extend(levelMask),
                                 vpn       = sign_extend(vpn),
                                 ppn       = zero_extend(ppn)};

  // Add the TLB entry. Note that this may be a super-page, but we still want
  // to add it to the index corresponding to the page because that is how
  // lookup_TLB looks it up. For superpages will just end up with the same
  // TLB entry in multiple slots.
  let index = tlb_hash('v, vpn);
  tlb[index] = Some(entry);
}

// Top-level TLB flush function
// PUBLIC: invoked from exec SFENCE_VMA
function flush_TLB(asid : option(asidbits),
                   addr : option(xlenbits)) -> unit = {
  foreach (i from 0 to (length(tlb) - 1)) {
    match tlb[i] {
      None()  => (),
      Some(entry) => if flush_TLB_Entry(entry, asid, addr) then { tlb[i] = None(); },
    }
  }
}
