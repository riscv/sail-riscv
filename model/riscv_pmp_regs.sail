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

register pmp0cfg  : Pmpcfg_ent
register pmp1cfg  : Pmpcfg_ent
register pmp2cfg  : Pmpcfg_ent
register pmp3cfg  : Pmpcfg_ent
register pmp4cfg  : Pmpcfg_ent
register pmp5cfg  : Pmpcfg_ent
register pmp6cfg  : Pmpcfg_ent
register pmp7cfg  : Pmpcfg_ent
register pmp8cfg  : Pmpcfg_ent
register pmp9cfg  : Pmpcfg_ent
register pmp10cfg : Pmpcfg_ent
register pmp11cfg : Pmpcfg_ent
register pmp12cfg : Pmpcfg_ent
register pmp13cfg : Pmpcfg_ent
register pmp14cfg : Pmpcfg_ent
register pmp15cfg : Pmpcfg_ent

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

/* Packing and unpacking pmpcfg regs for xlen-width accesses */

val pmpReadCfgReg_RV32 : forall 'n, 0 <= 'n < 4 & xlen == 32 . (atom('n)) -> xlenbits effect {rreg}
function pmpReadCfgReg_RV32(n) = {
  match n {
    0 => append(pmp3cfg.bits(),  append(pmp2cfg.bits(),  append(pmp1cfg.bits(),  pmp0cfg.bits()))),
    1 => append(pmp7cfg.bits(),  append(pmp6cfg.bits(),  append(pmp5cfg.bits(),  pmp4cfg.bits()))),
    2 => append(pmp11cfg.bits(), append(pmp10cfg.bits(), append(pmp9cfg.bits(),  pmp8cfg.bits()))),
    3 => append(pmp15cfg.bits(), append(pmp14cfg.bits(), append(pmp13cfg.bits(), pmp12cfg.bits())))
  }
}

val pmpReadCfgReg_RV64 : forall 'n, 0 <= 'n < 2 & xlen == 64 . (atom('n)) -> xlenbits effect {rreg}
function pmpReadCfgReg_RV64(n) = {
  match n {
    0 => append(pmp7cfg.bits(),  append(pmp6cfg.bits(),  append(pmp5cfg.bits(),  append(pmp4cfg.bits(),  append(pmp3cfg.bits(),  append(pmp2cfg.bits(),  append(pmp1cfg.bits(),  pmp0cfg.bits()))))))),
    1 => append(pmp15cfg.bits(), append(pmp14cfg.bits(), append(pmp13cfg.bits(), append(pmp12cfg.bits(), append(pmp11cfg.bits(), append(pmp10cfg.bits(), append(pmp9cfg.bits(),  pmp8cfg.bits())))))))
  }
}

// FIXME: handle locked
val pmpWriteCfgReg_RV32 : forall 'n, 0 <= 'n < 4 & xlen == 32 . (atom('n), xlenbits) -> unit effect {wreg}
function pmpWriteCfgReg_RV32(n, v) = {
  match n {
    0 => { pmp0cfg  = Mk_Pmpcfg_ent(v[7 ..0]);
           pmp1cfg  = Mk_Pmpcfg_ent(v[15..8]);
           pmp2cfg  = Mk_Pmpcfg_ent(v[23..16]);
           pmp3cfg  = Mk_Pmpcfg_ent(v[31..24])
         },
    1 => { pmp4cfg  = Mk_Pmpcfg_ent(v[7 ..0]);
           pmp5cfg  = Mk_Pmpcfg_ent(v[15..8]);
           pmp6cfg  = Mk_Pmpcfg_ent(v[23..16]);
           pmp7cfg  = Mk_Pmpcfg_ent(v[31..24])
         },
    2 => { pmp8cfg8 = Mk_Pmpcfg_ent(v[7 ..0]);
           pmp9cfg9 = Mk_Pmpcfg_ent(v[15..8]);
           pmp10cfg = Mk_Pmpcfg_ent(v[23..16]);
           pmp11cfg = Mk_Pmpcfg_ent(v[31..24])
         },
    3 => { pmp12cfg = Mk_Pmpcfg_ent(v[7 ..0]);
           pmp13cfg = Mk_Pmpcfg_ent(v[15..8]);
           pmp14cfg = Mk_Pmpcfg_ent(v[23..16]);
           pmp15cfg = Mk_Pmpcfg_ent(v[31..24])
         }
  }
}

// FIXME: handle locked
val pmpWriteCfgReg_RV64 : forall 'n, 0 <= 'n < 2 & xlen == 64 . (atom('n), xlenbits) -> unit effect {wreg}
function pmpWriteCfgReg_RV64(n, v) = {
  match n {
    0 => { pmp0cfg  = Mk_Pmpcfg_ent(v[7 ..0]);
           pmp1cfg  = Mk_Pmpcfg_ent(v[15..8]);
           pmp2cfg  = Mk_Pmpcfg_ent(v[23..16]);
           pmp3cfg  = Mk_Pmpcfg_ent(v[31..24]);
           pmp4cfg  = Mk_Pmpcfg_ent(v[39..32]);
           pmp5cfg  = Mk_Pmpcfg_ent(v[47..40]);
           pmp6cfg  = Mk_Pmpcfg_ent(v[55..48]);
           pmp7cfg  = Mk_Pmpcfg_ent(v[63..56])
         },
    1 => { pmp8cfg8 = Mk_Pmpcfg_ent(v[7 ..0]);
           pmp9cfg9 = Mk_Pmpcfg_ent(v[15..8]);
           pmp10cfg = Mk_Pmpcfg_ent(v[23..16]);
           pmp11cfg = Mk_Pmpcfg_ent(v[31..24]);
           pmp12cfg = Mk_Pmpcfg_ent(v[39..32]);
           pmp13cfg = Mk_Pmpcfg_ent(v[47..40]);
           pmp14cfg = Mk_Pmpcfg_ent(v[55..48]);
           pmp15cfg = Mk_Pmpcfg_ent(v[63..56])
         }
  }
}
