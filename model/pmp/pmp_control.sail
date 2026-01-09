// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================


// permission checks

private function pmpCheckRWX(ent : Pmpcfg_ent, access : MemoryAccessType(mem_payload)) -> bool =
  match access {
    Load(_)             => ent[R] == 0b1,
    LoadReserved(_)     => ent[R] == 0b1,
    Store(_)            => ent[W] == 0b1,
    StoreConditional(_) => ent[W] == 0b1,
    Atomic(_)           => ent[R] == 0b1 & ent[W] == 0b1,
    InstructionFetch()  => ent[X] == 0b1,

    CacheAccess(CB_manage())    => bool_bits(ent[R]) | bool_bits(ent[W]),
    CacheAccess(CB_zero())      => bool_bits(ent[W]),
    CacheAccess(CB_prefetch(p)) => match p {
      PREFETCH_I => bool_bits(ent[X]),
      PREFETCH_R => bool_bits(ent[R]),
      PREFETCH_W => bool_bits(ent[W]),
    },
  }


// matching logic

private enum pmpAddrMatch = {PMP_NoMatch, PMP_PartialMatch, PMP_Match}

// Given a right-open interval [begin, end_), return whether [addr, addr+width)
// is contained fully within it (PMP_Match), doesn't overlap at all (PMP_NoMatch)
// or partially intersects it (PMP_PartialMatch).
private function pmpRangeMatch(
  begin : nat,
  end_ : nat,
  addr : nat,
  width : nat,
) -> pmpAddrMatch =
  if      (addr + width <= begin) | (end_ <= addr)
  then    PMP_NoMatch
  else if (begin <= addr) & (addr + width <= end_)
  then    PMP_Match
  else    PMP_PartialMatch

private function pmpMatchAddr(
  Physaddr(addr) : physaddr,
  width : xlenbits,
  ent : Pmpcfg_ent,
  pmpaddr : xlenbits,
  prev_pmpaddr : xlenbits,
) -> pmpAddrMatch = {
  let addr = unsigned(addr);
  let width = unsigned(width);
  match pmpAddrMatchType_encdec(ent[A]) {
    OFF => PMP_NoMatch,
    TOR => {
      // "If PMP entry [i]'s A field is set to TOR, the entry matches
      //  any address y such that pmpaddr[i-1] <= y < pmpaddr[i]"
      // "If pmpaddr[i-1] >= pmpaddr[i] and pmpcfg[i].A=TOR, then PMP entry i matches no addresses."
      if prev_pmpaddr >=_u pmpaddr
      then PMP_NoMatch
      else pmpRangeMatch(unsigned(prev_pmpaddr) * 4, unsigned(pmpaddr) * 4, addr, width)
    },
    NA4 => {
      // NA4 is not selectable when the PMP grain G >= 1. See pmpWriteCfg().
      assert(sys_pmp_grain < 1, "NA4 cannot be selected when PMP grain G >= 1.");
      // Match a 4-byte region.
      let begin = unsigned(pmpaddr) * 4;
      pmpRangeMatch(begin, begin + 4, addr, width)
    },
    NAPOT => {
      // Example pmpaddr: 0b00010101111
      //                          ^--- last 0 dictates region size & alignment
      let mask = pmpaddr ^ (pmpaddr + 1);
      // pmpaddr + 1:     0b00010110000
      // mask:            0b00000011111
      // ~mask:           0b11111100000
      let begin_words = unsigned(pmpaddr & (~(mask)));
      // mask + 1:        0b00000100000
      let end_words = begin_words + unsigned(mask) + 1;
      pmpRangeMatch(begin_words * 4, end_words * 4, addr, width)
    },
  }
}

// priority checks

function pmpCheck forall 'n, 0 < 'n <= max_mem_access . (
  addr : physaddr,
  width : int('n),
  access : MemoryAccessType(mem_payload),
  priv : Privilege,
) -> option(ExceptionType) = {

  if sys_pmp_count == 0 then return None();

  let width : xlenbits = to_bits(width);

  // TODO for accesses of type CacheAccess:
  //
  // The CMO extensions impose the following constraints on the
  // physical addresses in a given cache block: The PMP access control
  // bits shall be the same for all physical addresses in the cache
  // block, and if write permission is granted by the PMP access
  // control bits, read permission shall also be granted.

  foreach (i from 0 to sys_pmp_count - 1) {
    let prev_pmpaddr = if i > 0 then pmpReadAddrReg(i - 1) else zeros();
    let cfg = pmpcfg_n[i];

    match pmpMatchAddr(addr, width, cfg, pmpReadAddrReg(i), prev_pmpaddr) {
      PMP_NoMatch      => (),
      PMP_PartialMatch => return Some(accessFaultFromAccessType(access)),
      PMP_Match        => return (
        if pmpCheckRWX(cfg, access) | (priv == Machine & not(pmpLocked(cfg)))
        then None()
        else Some(accessFaultFromAccessType(access))
      ),
    };
  };
  if priv == Machine then None() else Some(accessFaultFromAccessType(access))
}

function reset_pmp() -> unit = {
  foreach (i from 0 to 63) {
    // On reset the PMP register's A and L bits are set to 0 unless the platform
    // mandates a different value.
    pmpcfg_n[i] = [pmpcfg_n[i] with A = pmpAddrMatchType_encdec(OFF), L = 0b0];
  };
}
