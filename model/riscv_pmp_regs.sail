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

type Pmpcfg_reg = vector(xlen_bytes, dec, Pmpcfg_ent)

register Pmpcfg0 : Pmpcfg_reg
register Pmpcfg1 : Pmpcfg_reg
register Pmpcfg2 : Pmpcfg_reg
register Pmpcfg3 : Pmpcfg_reg

bitfield Pmp_addr_64 : bits(64) = {
  addr : 53 .. 0
}

bitfield Pmp_addr_32 : bits(32) = {
  addr : 31 .. 0
}

val pmpCheckRWX: (Pmpcfg_ent, AccessType) -> option(ExceptionType)
function pmpCheckRWX(ent, acc) = {
  match acc {
    Read      => if   ent.R() == true
                 then None()
                 else Some(E_Load_Access_Fault),
    Write     => if   ent.W() == true
                 then None()
                 else Some(E_SAMO_Access_Fault),
    ReadWrite => if   ent.R() == true & ent.W() == true
                 then None()
                 else Some(E_SAMO_Access_Fault),
    Execute   => if   ent.X() == true
                 then None()
                 else Some(E_Fetch_Access_Fault)
  }
}

val pmpCheckPerms: (Pmpcfg_ent, AccessType, Privilege) -> option(ExceptionType)
function pmpCheckPerms(ent, acc, priv) = {
  match priv {
    Machine => if   ent.L() == true
               then pmpCheckRWX(ent, acc)
               else None(),
    _       => pmpCheckRWX(ent, acc)
  }
}
