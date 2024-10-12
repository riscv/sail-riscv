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
function pmpLocked(cfg: Pmpcfg_ent) -> bool =
   cfg[L] == 0b1

function pmpTORLocked(cfg: Pmpcfg_ent) -> bool =
   (cfg[L] == 0b1) & (pmpAddrMatchType_of_bits(cfg[A]) == TOR)

function pmpWriteCfg(n: range(0, 63), cfg: Pmpcfg_ent, v: bits(8)) -> Pmpcfg_ent =
  if pmpLocked(cfg) then cfg
  else {
    // Bits 5 and 6 are zero.
    let cfg = Mk_Pmpcfg_ent(v & 0x9f);

    // "The R, W, and X fields form a collective WARL field for which the combinations with R=0 and W=1 are reserved."
    // In this implementation if R=0 and W=1 then R, W and X are all set to 0.
    // This is the least risky option from a security perspective.
    let cfg = if cfg[W] == 0b1 & cfg[R] == 0b0 then [cfg with X = 0b0, W = 0b0, R = 0b0] else cfg;

    // "When G >= 1, the NA4 mode is not selectable."
    // In this implementation we set it to OFF if NA4 is selected.
    // This is the least risky option from a security perspective.
    let cfg = if sys_pmp_grain() >= 1 & pmpAddrMatchType_of_bits(cfg[A]) == NA4
              then [cfg with A = pmpAddrMatchType_to_bits(OFF)]
              else cfg;

    cfg
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

/* PMP CSRs */
mapping clause csr_name_map = 0x3A0  <-> "pmpcfg0"
mapping clause csr_name_map = 0x3A1  <-> "pmpcfg1"
mapping clause csr_name_map = 0x3A2  <-> "pmpcfg2"
mapping clause csr_name_map = 0x3A3  <-> "pmpcfg3"
mapping clause csr_name_map = 0x3A4  <-> "pmpcfg4"
mapping clause csr_name_map = 0x3A5  <-> "pmpcfg5"
mapping clause csr_name_map = 0x3A6  <-> "pmpcfg6"
mapping clause csr_name_map = 0x3A7  <-> "pmpcfg7"
mapping clause csr_name_map = 0x3A8  <-> "pmpcfg8"
mapping clause csr_name_map = 0x3A9  <-> "pmpcfg9"
mapping clause csr_name_map = 0x3AA  <-> "pmpcfg10"
mapping clause csr_name_map = 0x3AB  <-> "pmpcfg11"
mapping clause csr_name_map = 0x3AC  <-> "pmpcfg12"
mapping clause csr_name_map = 0x3AD  <-> "pmpcfg13"
mapping clause csr_name_map = 0x3AE  <-> "pmpcfg14"
mapping clause csr_name_map = 0x3AF  <-> "pmpcfg15"

mapping clause csr_name_map = 0x3B0  <-> "pmpaddr0"
mapping clause csr_name_map = 0x3B1  <-> "pmpaddr1"
mapping clause csr_name_map = 0x3B2  <-> "pmpaddr2"
mapping clause csr_name_map = 0x3B3  <-> "pmpaddr3"
mapping clause csr_name_map = 0x3B4  <-> "pmpaddr4"
mapping clause csr_name_map = 0x3B5  <-> "pmpaddr5"
mapping clause csr_name_map = 0x3B6  <-> "pmpaddr6"
mapping clause csr_name_map = 0x3B7  <-> "pmpaddr7"
mapping clause csr_name_map = 0x3B8  <-> "pmpaddr8"
mapping clause csr_name_map = 0x3B9  <-> "pmpaddr9"
mapping clause csr_name_map = 0x3BA  <-> "pmpaddr10"
mapping clause csr_name_map = 0x3BB  <-> "pmpaddr11"
mapping clause csr_name_map = 0x3BC  <-> "pmpaddr12"
mapping clause csr_name_map = 0x3BD  <-> "pmpaddr13"
mapping clause csr_name_map = 0x3BE  <-> "pmpaddr14"
mapping clause csr_name_map = 0x3BF  <-> "pmpaddr15"
mapping clause csr_name_map = 0x3C0  <-> "pmpaddr16"
mapping clause csr_name_map = 0x3C1  <-> "pmpaddr17"
mapping clause csr_name_map = 0x3C2  <-> "pmpaddr18"
mapping clause csr_name_map = 0x3C3  <-> "pmpaddr19"
mapping clause csr_name_map = 0x3C4  <-> "pmpaddr20"
mapping clause csr_name_map = 0x3C5  <-> "pmpaddr21"
mapping clause csr_name_map = 0x3C6  <-> "pmpaddr22"
mapping clause csr_name_map = 0x3C7  <-> "pmpaddr23"
mapping clause csr_name_map = 0x3C8  <-> "pmpaddr24"
mapping clause csr_name_map = 0x3C9  <-> "pmpaddr25"
mapping clause csr_name_map = 0x3CA  <-> "pmpaddr26"
mapping clause csr_name_map = 0x3CB  <-> "pmpaddr27"
mapping clause csr_name_map = 0x3CC  <-> "pmpaddr28"
mapping clause csr_name_map = 0x3CD  <-> "pmpaddr29"
mapping clause csr_name_map = 0x3CE  <-> "pmpaddr30"
mapping clause csr_name_map = 0x3CF  <-> "pmpaddr31"
mapping clause csr_name_map = 0x3D0  <-> "pmpaddr32"
mapping clause csr_name_map = 0x3D1  <-> "pmpaddr33"
mapping clause csr_name_map = 0x3D2  <-> "pmpaddr34"
mapping clause csr_name_map = 0x3D3  <-> "pmpaddr35"
mapping clause csr_name_map = 0x3D4  <-> "pmpaddr36"
mapping clause csr_name_map = 0x3D5  <-> "pmpaddr37"
mapping clause csr_name_map = 0x3D6  <-> "pmpaddr38"
mapping clause csr_name_map = 0x3D7  <-> "pmpaddr39"
mapping clause csr_name_map = 0x3D8  <-> "pmpaddr40"
mapping clause csr_name_map = 0x3D9  <-> "pmpaddr41"
mapping clause csr_name_map = 0x3DA  <-> "pmpaddr42"
mapping clause csr_name_map = 0x3DB  <-> "pmpaddr43"
mapping clause csr_name_map = 0x3DC  <-> "pmpaddr44"
mapping clause csr_name_map = 0x3DD  <-> "pmpaddr45"
mapping clause csr_name_map = 0x3DE  <-> "pmpaddr46"
mapping clause csr_name_map = 0x3DF  <-> "pmpaddr47"
mapping clause csr_name_map = 0x3E0  <-> "pmpaddr48"
mapping clause csr_name_map = 0x3E1  <-> "pmpaddr49"
mapping clause csr_name_map = 0x3E2  <-> "pmpaddr50"
mapping clause csr_name_map = 0x3E3  <-> "pmpaddr51"
mapping clause csr_name_map = 0x3E4  <-> "pmpaddr52"
mapping clause csr_name_map = 0x3E5  <-> "pmpaddr53"
mapping clause csr_name_map = 0x3E6  <-> "pmpaddr54"
mapping clause csr_name_map = 0x3E7  <-> "pmpaddr55"
mapping clause csr_name_map = 0x3E8  <-> "pmpaddr56"
mapping clause csr_name_map = 0x3E9  <-> "pmpaddr57"
mapping clause csr_name_map = 0x3EA  <-> "pmpaddr58"
mapping clause csr_name_map = 0x3EB  <-> "pmpaddr59"
mapping clause csr_name_map = 0x3EC  <-> "pmpaddr60"
mapping clause csr_name_map = 0x3ED  <-> "pmpaddr61"
mapping clause csr_name_map = 0x3EE  <-> "pmpaddr62"
mapping clause csr_name_map = 0x3EF  <-> "pmpaddr63"

// pmpcfgN
function clause is_CSR_defined(0x3A) @ idx : bits(4) = sys_pmp_count() > unsigned(idx) & (idx[0] == bitzero | xlen == 32)
function clause read_CSR(0x3A @ idx : bits(4) if idx[0] == bitzero | xlen == 32) = pmpReadCfgReg(unsigned(idx))
function clause write_CSR((0x3A @ idx : bits(4), value) if idx[0] == bitzero | xlen == 32) = {
  let idx = unsigned(idx);
  pmpWriteCfgReg(idx, value);
  pmpReadCfgReg(idx)
}

// pmpaddrN. Unfortunately the PMP index does not nicely align with the CSR index bits.
function clause is_CSR_defined(0x3B) @ idx : bits(4) = sys_pmp_count() > unsigned(0b00 @ idx)
function clause is_CSR_defined(0x3C) @ idx : bits(4) = sys_pmp_count() > unsigned(0b01 @ idx)
function clause is_CSR_defined(0x3D) @ idx : bits(4) = sys_pmp_count() > unsigned(0b10 @ idx)
function clause is_CSR_defined(0x3E) @ idx : bits(4) = sys_pmp_count() > unsigned(0b11 @ idx)

function clause read_CSR(0x3B @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b00 @ idx))
function clause read_CSR(0x3C @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b01 @ idx))
function clause read_CSR(0x3D @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b10 @ idx))
function clause read_CSR(0x3E @ idx : bits(4)) = pmpReadAddrReg(unsigned(0b11 @ idx))

function clause write_CSR(0x3B @ idx : bits(4), value) = { let idx = unsigned(0b00 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }
function clause write_CSR(0x3C @ idx : bits(4), value) = { let idx = unsigned(0b01 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }
function clause write_CSR(0x3D @ idx : bits(4), value) = { let idx = unsigned(0b10 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }
function clause write_CSR(0x3E @ idx : bits(4), value) = { let idx = unsigned(0b11 @ idx); pmpWriteAddrReg(idx, value); pmpReadAddrReg(idx) }
