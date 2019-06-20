/* PMP configuration entries */

enum PmpAddrMatchType = {OFF, TOR, NA4, NAPOT}

val cast pmpAddrMatchType_of_bits : bits(2) -> PmpAddrMatchType
function pmpAddrMatchType_of_bits(bs) = {
  match bs {
    0b00 => OFF,
    0b01 => TOR,
    0b10 => NA4,
    0b11 => NAPOT
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

register pmpcfg0 : xlenbits // fixme
//register pmpcfg0 : Pmpcfg_reg
register pmpcfg1  : Pmpcfg_ent
register pmpcfg2  : Pmpcfg_ent
register pmpcfg3  : Pmpcfg_ent
register pmpcfg4  : Pmpcfg_ent
register pmpcfg5  : Pmpcfg_ent
register pmpcfg6  : Pmpcfg_ent
register pmpcfg7  : Pmpcfg_ent
register pmpcfg8  : Pmpcfg_ent
register pmpcfg9  : Pmpcfg_ent
register pmpcfg10 : Pmpcfg_ent
register pmpcfg11 : Pmpcfg_ent
register pmpcfg12 : Pmpcfg_ent
register pmpcfg13 : Pmpcfg_ent
register pmpcfg14 : Pmpcfg_ent
register pmpcfg15 : Pmpcfg_ent

bitfield Pmp_addr_64 : bits(64) = {
  addr : 53 .. 0
}

bitfield Pmp_addr_32 : bits(32) = {
  addr : 31 .. 0
}

/* PMP address configuration */

register pmpaddr0  : xlenbits
register pmpaddr1  : xlenbits
register pmpaddr2  : xlenbits
register pmpaddr3  : xlenbits
register pmpaddr4  : xlenbits
register pmpaddr5  : xlenbits
register pmpaddr6  : xlenbits
register pmpaddr7  : xlenbits
register pmpaddr8  : xlenbits
register pmpaddr9  : xlenbits
register pmpaddr10 : xlenbits
register pmpaddr11 : xlenbits
register pmpaddr12 : xlenbits
register pmpaddr13 : xlenbits
register pmpaddr14 : xlenbits
register pmpaddr15 : xlenbits

val pmpReadReg : forall 'n, 0 <= 'n < 16 . (atom('n), PmpAddrMatchType) -> xlenbits
function pmpReadReg(n, amt) = {
  let r : xlenbits =
    match n {
      0  => pmpaddr0,
      1  => pmpaddr1,
      2  => pmpaddr2,
      3  => pmpaddr3,
      4  => pmpaddr4,
      5  => pmpaddr5,
      6  => pmpaddr6,
      7  => pmpaddr7,
      8  => pmpaddr8,
      9  => pmpaddr9,
      10 => pmpaddr10,
      11 => pmpaddr11,
      12 => pmpaddr12,
      13 => pmpaddr13,
      14 => pmpaddr14,
      15 => pmpaddr15
    };
  r
}
