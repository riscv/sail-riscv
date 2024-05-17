/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* PMP configuration entries */

enum PmpAddrMatchType = {OFF, TOR, NA4, NAPOT}

val pmpAddrMatchType_of_bits : bits(2) -> PmpAddrMatchType
function pmpAddrMatchType_of_bits(bs) = {
  match bs {
    0b00 => OFF,
    0b01 => TOR,
    0b10 => NA4,
    0b11 => NAPOT
  }
}

val pmpAddrMatchType_to_bits : PmpAddrMatchType -> bits(2)
function pmpAddrMatchType_to_bits(bs) = {
  match bs {
    OFF   => 0b00,
    TOR   => 0b01,
    NA4   => 0b10,
    NAPOT => 0b11
  }
}

bitfield Pmpcfg_ent : bits(8) = {
  L : 7,        /* locking */
  A : 4 .. 3,   /* address match type, encoded as above */

  /* permissions */
  X : 2,        /* execute */
  W : 1,        /* write */
  R : 0         /* read */
}

register pmpcfg_n : vector(64, Pmpcfg_ent)
register pmpaddr_n : vector(64, xlenbits)

bitfield Mseccfg_ent : xlenbits = {
  RLB  : 2,       /* Rule Locking Bypass */
  MMWP : 1,       /* Machine Mode Whitelist Policy */
  MML  : 0        /* Machine Mode Lockdown */
}

register mseccfg  : Mseccfg_ent
register mseccfgh : bits(32)

/* Packing and unpacking pmpcfg regs for xlen-width accesses */

function pmpReadCfgReg(n : range(0, 15)) -> xlenbits = {
  if xlen == 32
  then {
    pmpcfg_n[n*4 + 3].bits @
    pmpcfg_n[n*4 + 2].bits @
    pmpcfg_n[n*4 + 1].bits @
    pmpcfg_n[n*4 + 0].bits
  }
  else {
    assert(n % 2 == 0, "Unexpected pmp config reg read");
    pmpcfg_n[n*4 + 7].bits @
    pmpcfg_n[n*4 + 6].bits @
    pmpcfg_n[n*4 + 5].bits @
    pmpcfg_n[n*4 + 4].bits @
    pmpcfg_n[n*4 + 3].bits @
    pmpcfg_n[n*4 + 2].bits @
    pmpcfg_n[n*4 + 1].bits @
    pmpcfg_n[n*4 + 0].bits
  }
}

function pmpReadAddrReg(n : range(0, 63)) -> xlenbits = {
  let G = sys_pmp_grain();
  let match_type = pmpcfg_n[n][A];
  let addr = pmpaddr_n[n];

  match match_type[1] {
    bitone if G >= 2 => {
      // [G-2..0] read as all ones to form mask, therefore we need G-1 bits.
      let mask : xlenbits = zero_extend(ones(min(G - 1, xlen)));
      addr | mask
    },

    bitzero if G >= 1 => {
      // [G-1..0] read as all zeros to form mask, therefore we need G bits.
      let mask : xlenbits = zero_extend(ones(min(G , xlen)));
      addr & ~(mask)
    },

    _ => addr,
  }
}

/* Helpers to handle locked entries */
function pmpLockBit(cfg: Pmpcfg_ent) -> bool = cfg[L] == 0b1

function pmpLocked(cfg: Pmpcfg_ent) -> bool = (cfg[L] == 0b1) & (mseccfg[RLB] == 0b0)

function pmpTORLocked(cfg: Pmpcfg_ent) -> bool = pmpLocked(cfg) & (pmpAddrMatchType_of_bits(cfg[A]) == TOR)

function pmpWriteCfg(n: range(0, 63), cfg: Pmpcfg_ent, v: bits(8)) -> Pmpcfg_ent = {
  /* If locked then configuration is unchanged */
  if pmpLocked(cfg)
  then cfg
  /* To prevent adding a rule with execution privileges if MML is enabled unless RLB is set */
  else {
    /* Constructing legal Pmpcfg_ent by making bit 5 and 6 zero */
    let legal_v : Pmpcfg_ent = Mk_Pmpcfg_ent(v & 0x9f);
    // "The R, W, and X fields form a collective WARL field for which the combinations with R=0 and W=1 are reserved."
    // In this implementation if R=0 and W=1 then R, W and X are all set to 0.
    // This is the least risky option from a security perspective.
    let legal_v : Pmpcfg_ent = match (mseccfg[MML], legal_v[R], legal_v[W]) {
      (0b0, 0b0, 0b1) => [legal_v with W = 0b0],
      (_, _, _)       => legal_v
    };

    let legal_v : Pmpcfg_ent = if (mseccfg[MML] == 0b1 & mseccfg[RLB] == 0b0 & legal_v[L] == 0b1)
    then {
      match (legal_v[R], legal_v[W], legal_v[X]) {
        (0b0, 0b0, 0b1) => cfg,
        (0b0, 0b1, 0b0) => cfg,
        (0b0, 0b1, 0b1) => cfg,
        (0b1, 0b0, 0b1) => cfg,
        (_, _, _)       => legal_v
      }
    } else legal_v;

    // "When G >= 1, the NA4 mode is not selectable."
    // In this implementation we set it to OFF if NA4 is selected.
    // This is the least risky option from a security perspective.
    let legal_v = if (sys_pmp_grain() >= 1 & pmpAddrMatchType_of_bits(legal_v[A]) == NA4)
              then [legal_v with A = pmpAddrMatchType_to_bits(OFF)]
              else legal_v;
    legal_v
  }
}

function pmpWriteCfgReg(n : range(0, 15), v : xlenbits) -> unit = {
  if xlen == 32
  then {
    foreach (i from 0 to 3) {
      let idx = n*4 + i;
      pmpcfg_n[idx]  = pmpWriteCfg(idx,  pmpcfg_n[idx],  v[8*i+7 .. 8*i]);
    }
  }
  else {
    assert(n % 2 == 0, "Unexpected pmp config reg write");
    foreach (i from 0 to 7) {
      let idx = n*4 + i;
      pmpcfg_n[idx]  = pmpWriteCfg(idx,  pmpcfg_n[idx],  v[8*i+7 .. 8*i]);
    }
  }
}

function pmpWriteAddr(locked: bool, tor_locked: bool, reg: xlenbits, v: xlenbits) -> xlenbits =
  if   xlen == 32
  then { if (locked | tor_locked) then reg else v }
  else { if (locked | tor_locked) then reg else zero_extend(v[53..0]) }

function pmpWriteAddrReg(n : range(0, 63), v : xlenbits) -> unit = {
  pmpaddr_n[n] = pmpWriteAddr(
    pmpLocked(pmpcfg_n[n]),
    if n + 1 < 64 then pmpTORLocked(pmpcfg_n[n + 1]) else false,
    pmpaddr_n[n],
    v,
  );
}

function checkPmpNcfgL(n : range(0, 63)) -> bool = {
  if n == 0
  then pmpcfg_n[0][L] == 0b1
  else checkPmpNcfgL(n - 1) | (pmpcfg_n[n][L] == 0b1)
}

function mseccfgWrite(reg: Mseccfg_ent, v: xlenbits) -> Mseccfg_ent = {
  let legal_v : Mseccfg_ent = Mk_Mseccfg_ent(zero_extend(v[2 .. 0]));
  let reg : Mseccfg_ent = match (reg[RLB], legal_v[RLB]) {                   /* to set RLB, need to check PMPCFG_L */
    (0b0, 0b1) =>
      if (checkPmpNcfgL(63))
      then reg
      else update_RLB(reg, legal_v[RLB]),
    (_, _)     => update_RLB(reg, legal_v[RLB])
  };
  let reg : Mseccfg_ent = match (reg[MML], reg[MMWP]) {                      /* Implements stickiness of MML bit, if once set remains set */
    (0b0, 0b0) => [reg with MMWP = legal_v[MMWP], MML = legal_v[MML]],
    (0b0, 0b1) => [reg with MML = legal_v[MML]],
    (0b1, 0b0) => [reg with MMWP = legal_v[MMWP]],
    (0b1, 0b1) => reg
  };
  reg
}
