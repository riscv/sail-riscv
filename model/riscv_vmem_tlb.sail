/* idealized TLB to model fence.vm and also speed up simulation. */

/* This could be made generic using polymorphic structs; however,
 * the simulator backends don't support them.
 */

struct TLB39_Entry = {
  asid : asid64,
  global : bool,
  vAddr : vaddr39,      /* VPN */
  pAddr : paddr64,      /* PPN */
  vMatchMask : vaddr39, /* matching mask for superpages */
  vAddrMask : vaddr39,  /* selection mask for superpages */
  pte : SV39_PTE,       /* permissions */
  pteAddr : paddr64,    /* for dirty writeback */
  age : bits(64)
}

/* the rreg effect is an artifact of using the cycle counter to provide the age */
val make_TLB39_Entry : (asid64, bool, vaddr39, paddr64, SV39_PTE, nat, paddr64) -> TLB39_Entry effect {rreg}

function make_TLB39_Entry(asid, global, vAddr, pAddr, pte, level, pteAddr) = {
  let shift : nat = PAGESIZE_BITS + (level * SV39_LEVEL_BITS);
  /* fixme hack: use a better idiom for masks */
  let vAddrMask : vaddr39 = shiftl(vAddr ^ vAddr ^ EXTZ(0b1), shift) - 1;
  let vMatchMask : vaddr39 = ~ (vAddrMask);
  struct {
    asid = asid,
    global = global,
    pte = pte,
    pteAddr = pteAddr,
    vAddrMask = vAddrMask,
    vMatchMask = vMatchMask,
    vAddr = vAddr & vMatchMask,
    pAddr = shiftl(shiftr(pAddr, shift), shift),
    age = mcycle
  }
}

/* TODO: make this a vector or array of entries */
register tlb39 : option(TLB39_Entry)

val lookupTLB39 : (asid64, vaddr39) -> option((int, TLB39_Entry)) effect {rreg}
function lookupTLB39(asid, vaddr) = {
  match tlb39 {
    None()  => None(),
    Some(e) => if  (e.global | (e.asid == asid))
                 & (e.vAddr == (e.vMatchMask & vaddr))
               then Some((0, e))
               else None()
  }
}

val addToTLB39 : (asid64, vaddr39, paddr64, SV39_PTE, paddr64, nat, bool) -> unit effect {wreg, rreg}
function addToTLB39(asid, vAddr, pAddr, pte, pteAddr, level, global) = {
  let ent = make_TLB39_Entry(asid, global, vAddr, pAddr, pte, level, pteAddr);
  tlb39   = Some(ent)
}

function writeTLB39(idx : int, ent : TLB39_Entry) -> unit =
  tlb39 = Some(ent)

val flushTLB : (option(asid64), option(vaddr39)) -> unit effect {rreg, wreg}
function flushTLB(asid, addr) = {
  let ent : option(TLB39_Entry) =
    match (tlb39, asid, addr) {
      (None(),       _,      _)   => None(),
      (Some(e), None(), None())   => None(),
      (Some(e), None(), Some(a))  => if e.vAddr == (e.vMatchMask & a)
                                     then None() else Some(e),
      (Some(e), Some(i), None())  => if (e.asid == i) & (~ (e.global))
                                     then None() else Some(e),
      (Some(e), Some(i), Some(a)) => if (e.asid == i) & (e.vAddr == (a & e.vMatchMask))
                                        & (~ (e.global))
                                     then None() else Some(e)
    };
  tlb39 = ent
}
