/* address ranges */

// TODO: handle PMP grain > 4 (i.e. G > 0).
// TODO: handle the 34-bit paddr32 on RV32

/* [min, max) of the matching range. */
type pmp_addr_range = option((xlenbits, xlenbits))

function pmpAddrRange(cfg: Pmpcfg_ent, pmpaddr: xlenbits, prev_pmpaddr: xlenbits) -> pmp_addr_range = {
  match pmpAddrMatchType_of_bits(cfg.A()) {
    OFF   => None(),
    TOR   => { Some ((prev_pmpaddr << 2, pmpaddr << 2)) },
    NA4   => { // TODO: I find the spec unclear for entries marked NA4 and G = 1.
               // (for G >= 2, it is the same as NAPOT). In particular, it affects
               // whether pmpaddr[0] is always read as 0.
               let lo = pmpaddr << 2;
               Some((lo, lo + 4))
             },
    NAPOT => { let mask = pmpaddr ^ (pmpaddr + 1);  // generate 1s in signifying bits
               let lo   = pmpaddr & (~ (mask));
               let len  = mask + 1;
               Some((lo << 2, (lo + len) << 2))
             }
  }
}

/* permission checks */

val pmpCheckRWX: (Pmpcfg_ent, AccessType) -> bool
function pmpCheckRWX(ent, acc) = {
  match acc {
    Read      => ent.R() == true,
    Write     => ent.W() == true,
    ReadWrite => ent.R() == true & ent.W() == true,
    Execute   => ent.X() == true
  }
}

// this needs to be called with the effective current privilege.
val pmpCheckPerms: (Pmpcfg_ent, AccessType, Privilege) -> bool
function pmpCheckPerms(ent, acc, priv) = {
  match priv {
    Machine => if   ent.L() == true
               then pmpCheckRWX(ent, acc)
               else true,
    _       => pmpCheckRWX(ent, acc)
  }
}

/* matching logic */

enum pmpAddrMatch = {PMP_NoMatch, PMP_PartialMatch, PMP_Match}

function pmpMatchAddr(addr: xlenbits, width: xlenbits, rng: pmp_addr_range) -> pmpAddrMatch = {
  match rng {
    None()         => PMP_NoMatch,
    Some((lo, hi)) => if   hi <_u lo   /* to handle mis-configuration */
                      then PMP_NoMatch
                      else {
                        if      (addr + width <_u lo) | (hi <_u addr)
                        then    PMP_NoMatch
                        else if (lo <=_u addr) & (addr + width <=_u hi)
                        then    PMP_Match
                        else    PMP_PartialMatch
                      }
  }
}

enum pmpMatch = {PMP_Success, PMP_Continue, PMP_Fail}

function pmpMatchEntry(addr: xlenbits, width: xlenbits, acc: AccessType, priv: Privilege,
                       ent: Pmpcfg_ent, pmpaddr: xlenbits, prev_pmpaddr: xlenbits) -> pmpMatch = {
  let rng = pmpAddrRange(ent, pmpaddr, prev_pmpaddr);
  match pmpMatchAddr(addr, width, rng) {
    PMP_NoMatch      => PMP_Continue,
    PMP_PartialMatch => PMP_Fail,
    PMP_Match        => if   pmpCheckPerms(ent, acc, priv)
                        then PMP_Success
                        else PMP_Fail
  }
}

/* priority checks */

function pmpCheck(addr: xlenbits, width: xlenbits, acc: AccessType, priv: Privilege,
                  ent: Pmpcfg_ent, pmpaddr: xlenbits, prev_pmpaddr: xlenbits)
                  -> option(ExceptionType) = {
  let check : bool =
  match pmpMatchEntry(addr, width, acc, priv, pmp0cfg, pmpaddr0, zeros()) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp1cfg, pmpaddr1, pmpaddr0) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp2cfg, pmpaddr2, pmpaddr1) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp3cfg, pmpaddr3, pmpaddr2) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp4cfg, pmpaddr4, pmpaddr3) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp5cfg, pmpaddr5, pmpaddr4) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp6cfg, pmpaddr6, pmpaddr5) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp7cfg, pmpaddr7, pmpaddr6) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp8cfg, pmpaddr8, pmpaddr7) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp9cfg, pmpaddr9, pmpaddr8) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp10cfg, pmpaddr10, pmpaddr9) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp11cfg, pmpaddr11, pmpaddr10) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp12cfg, pmpaddr12, pmpaddr11) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp13cfg, pmpaddr13, pmpaddr12) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp14cfg, pmpaddr14, pmpaddr13) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue =>
  match pmpMatchEntry(addr, width, acc, priv, pmp15cfg, pmpaddr15, pmpaddr14) {
    PMP_Success  => true,
    PMP_Fail     => false,
    PMP_Continue => false
  }}}}}}}}}}}}}}}};

  if   check
  then None()
  else match acc {
    Read      => Some(E_Load_Access_Fault),
    Write     => Some(E_SAMO_Access_Fault),
    ReadWrite => Some(E_SAMO_Access_Fault),
    Execute   => Some(E_Fetch_Access_Fault)
  }
}
