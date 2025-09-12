// =======================================================================================
// This Sail RISC-V architecture model, comprising all files and
// directories except where otherwise noted is subject the BSD
// two-clause license in the LICENSE file.
//
// SPDX-License-Identifier: BSD-2-Clause
// =======================================================================================


// permission checks

val pmpCheckRWX: (Pmpcfg_ent, AccessType(ext_access_type)) -> bool
function pmpCheckRWX(ent, acc) =
  match acc {
    Read(_)      => ent[R] == 0b1,
    Write(_)     => ent[W] == 0b1,
    ReadWrite(_) => ent[R] == 0b1 & ent[W] == 0b1,
    InstructionFetch() => ent[X] == 0b1,
  }


// matching logic

enum pmpAddrMatch = {PMP_NoMatch, PMP_PartialMatch, PMP_Match}

// Given a right-open interval [begin, end_), return whether [addr, addr+width)
// is contained fully within it (PMP_Match), doesn't overlap at all (PMP_NoMatch)
// or partially intersects it (PMP_PartialMatch).
function pmpRangeMatch(
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

function pmpMatchAddr(
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

function accessToFault(acc : AccessType(ext_access_type)) -> ExceptionType =
  match acc {
    Read(_)      => E_Load_Access_Fault(),
    Write(_)     => E_SAMO_Access_Fault(),
    ReadWrite(_) => E_SAMO_Access_Fault(),
    InstructionFetch() => E_Fetch_Access_Fault(),
  }

function pmpCheck forall 'n, 0 < 'n <= max_mem_access . (
  addr : physaddr,
  width : int('n),
  acc : AccessType(ext_access_type),
  priv : Privilege,
) -> option(ExceptionType) = {

  let width : xlenbits = to_bits(width);

  foreach (i from 0 to 63) {
    let prev_pmpaddr = if i > 0 then pmpReadAddrReg(i - 1) else zeros();
    let cfg = pmpcfg_n[i];

    match pmpMatchAddr(addr, width, cfg, pmpReadAddrReg(i), prev_pmpaddr) {
      PMP_NoMatch      => (),
      PMP_PartialMatch => return Some(accessToFault(acc)),
      PMP_Match        => return (
        if pmpCheckRWX(cfg, acc) | (priv == Machine & not(pmpLocked(cfg)))
        then None()
        else Some(accessToFault(acc))
      ),
    };
  };
  if priv == Machine then None() else Some(accessToFault(acc))
}

function reset_pmp() -> unit = {
  foreach (i from 0 to 63) {
    // On reset the PMP register's A and L bits are set to 0 unless the platform
    // mandates a different value.
    pmpcfg_n[i] = [pmpcfg_n[i] with A = pmpAddrMatchType_encdec(OFF), L = 0b0];
  };
}
