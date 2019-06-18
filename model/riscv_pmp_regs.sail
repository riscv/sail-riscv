enum PmpAddrmatchType = {OFF, TOR, NA4, NAPOT}

bitfield Pmpcfg_ent : bits(8) = {
  L : 7,        /* locking */
  A : 4 .. 3,   /* address matching */
  // permissions:
  X : 2,        /* execute */
  W : 1,        /* write */
  R : 0         /* read */
}

type Pmpcfg_reg = vector(xlen_bytes, dec, Pmpcfg_ent)

register Pmpcfg0 : Pmpcfg_reg
register Pmpcfg1 : Pmpcfg_reg
register Pmpcfg2 : Pmpcfg_reg
register Pmpcfg3 : Pmpcfg_reg

bitfield Pmp_addr_64 : bits(64) = {
  addr : 53 .. 0
}

bitfield Pmp_addr_32 : bits(64) = {
  addr : 31 .. 0
}
