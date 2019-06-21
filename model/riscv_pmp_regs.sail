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

/* Packing and unpacking pmpcfg regs for xlen-width accesses */

val pmpReadCfgReg_RV32 : forall 'n, 0 <= 'n < 4 & xlen == 32 . (atom('n)) -> xlenbits
function pmpReadCfgReg_RV32(n) = {
  match n {
         // fixme cfg0
    0 => append(pmpcfg3.bits(),  append(pmpcfg2.bits(),  append(pmpcfg1.bits(),  pmpcfg1.bits()))),
    1 => append(pmpcfg7.bits(),  append(pmpcfg6.bits(),  append(pmpcfg5.bits(),  pmpcfg4.bits()))),
    2 => append(pmpcfg11.bits(), append(pmpcfg10.bits(), append(pmpcfg9.bits(),  pmpcfg8.bits()))),
    3 => append(pmpcfg15.bits(), append(pmpcfg14.bits(), append(pmpcfg13.bits(), pmpcfg12.bits())))
  }
}

val pmpReadCfgReg_RV64 : forall 'n, 0 <= 'n < 2 & xlen == 64 . (atom('n)) -> xlenbits
function pmpReadCfgReg_RV64(n) = {
  match n {
         // fixme cfg0
    0 => append(pmpcfg7.bits(),  append(pmpcfg6.bits(),  append(pmpcfg5.bits(),  append(pmpcfg4.bits(),  append(pmpcfg3.bits(),  append(pmpcfg2.bits(),  append(pmpcfg1.bits(),  pmpcfg1.bits()))))))),
    1 => append(pmpcfg15.bits(), append(pmpcfg14.bits(), append(pmpcfg13.bits(), append(pmpcfg12.bits(), append(pmpcfg11.bits(), append(pmpcfg10.bits(), append(pmpcfg9.bits(),  pmpcfg8.bits())))))))
  }
}

val pmpWriteCfgReg_RV32 : forall 'n, 0 <= 'n < 4 & xlen == 32 . (atom('n), xlenbits) -> unit
function pmpWriteCfgReg_RV32(n, v) = {
  match n {
    0 => { pmpcfg1  = Mk_Pmpcfg_ent(v[7 ..0]);  // fixme
           pmpcfg1  = Mk_Pmpcfg_ent(v[15..8]);
           pmpcfg2  = Mk_Pmpcfg_ent(v[23..16]);
           pmpcfg3  = Mk_Pmpcfg_ent(v[31..24]);
           ()
         },
    1 => { pmpcfg4  = Mk_Pmpcfg_ent(v[7 ..0]);
           pmpcfg5  = Mk_Pmpcfg_ent(v[15..8]);
           pmpcfg6  = Mk_Pmpcfg_ent(v[23..16]);
           pmpcfg7  = Mk_Pmpcfg_ent(v[31..24]);
           ()
         },
    2 => { pmpcfg8  = Mk_Pmpcfg_ent(v[7 ..0]);
           pmpcfg9  = Mk_Pmpcfg_ent(v[15..8]);
           pmpcfg10 = Mk_Pmpcfg_ent(v[23..16]);
           pmpcfg11 = Mk_Pmpcfg_ent(v[31..24]);
           ()
         },
    3 => { pmpcfg12 = Mk_Pmpcfg_ent(v[7 ..0]);
           pmpcfg13 = Mk_Pmpcfg_ent(v[15..8]);
           pmpcfg14 = Mk_Pmpcfg_ent(v[23..16]);
           pmpcfg15 = Mk_Pmpcfg_ent(v[31..24]);
           ()
         }
  }
}

val pmpWriteCfgReg_RV64 : forall 'n, 0 <= 'n < 2 & xlen == 64 . (atom('n), xlenbits) -> unit
function pmpWriteCfgReg_RV64(n, v) = {
  match n {
    0 => { pmpcfg1  = Mk_Pmpcfg_ent(v[7 ..0]);  // fixme
           pmpcfg1  = Mk_Pmpcfg_ent(v[15..8]);
           pmpcfg2  = Mk_Pmpcfg_ent(v[23..16]);
           pmpcfg3  = Mk_Pmpcfg_ent(v[31..24]);
           pmpcfg4  = Mk_Pmpcfg_ent(v[39..32]);
           pmpcfg5  = Mk_Pmpcfg_ent(v[47..40]);
           pmpcfg6  = Mk_Pmpcfg_ent(v[55..48]);
           pmpcfg7  = Mk_Pmpcfg_ent(v[63..56]);
           ()
         },
    1 => { pmpcfg8  = Mk_Pmpcfg_ent(v[7 ..0]);
           pmpcfg9  = Mk_Pmpcfg_ent(v[15..8]);
           pmpcfg10 = Mk_Pmpcfg_ent(v[23..16]);
           pmpcfg11 = Mk_Pmpcfg_ent(v[31..24]);
           pmpcfg12 = Mk_Pmpcfg_ent(v[39..32]);
           pmpcfg13 = Mk_Pmpcfg_ent(v[47..40]);
           pmpcfg14 = Mk_Pmpcfg_ent(v[55..48]);
           pmpcfg15 = Mk_Pmpcfg_ent(v[63..56]);
           ()
         }
  }
}
