/* Architectural state for the 'N' user-level interrupts standard extension. */

/* ustatus reveals a subset of mstatus */
bitfield Ustatus : xlenbits = {
  UPIE : 4,
  UIE  : 0
}

/* This is a view, so there is no register defined. */
function lower_sstatus(s : Sstatus) -> Ustatus = {
  let u = Mk_Ustatus(EXTZ(0b0));
  let u = update_UPIE(u, s.UPIE());
  let u = update_UIE(u, s.UIE());
  u
}

function lift_ustatus(s : Sstatus, u : Ustatus) -> Sstatus = {
  let s = update_UPIE(s, u.UPIE());
  let s = update_UIE(s, u.UIE());
  s
}

function legalize_ustatus(m : Mstatus, v : xlenbits) -> Mstatus = {
  let u = Mk_Ustatus(v);
  let s = lower_mstatus(m);     // lower current mstatus to sstatus
  let s = lift_ustatus(s, u);   // get updated sstatus
  let m = lift_sstatus(m, s);   // lift it to an updated mstatus
  m
}

bitfield Uinterrupts : xlenbits = {
  UEI : 8,  /* external interrupt */
  UTI : 4,  /* timer interrupt    */
  USI : 0   /* software interrupt */
}

/* Provides the uip read view of sip (s) as delegated by sideleg (d). */
function lower_sip(s : Sinterrupts, d : Sinterrupts) -> Uinterrupts = {
  let u : Uinterrupts = Mk_Uinterrupts(EXTZ(0b0));
  let u = update_UEI(u, s.UEI() & d.UEI());
  let u = update_UTI(u, s.UTI() & d.UTI());
  let u = update_USI(u, s.USI() & d.USI());
  u
}

/* Provides the uie read view of sie as delegated by sideleg. */
function lower_sie(s : Sinterrupts, d : Sinterrupts) -> Uinterrupts = {
  let u : Uinterrupts = Mk_Uinterrupts(EXTZ(0b0));
  let u = update_UEI(u, s.UEI() & d.UEI());
  let u = update_UTI(u, s.UTI() & d.UTI());
  let u = update_USI(u, s.USI() & d.USI());
  u
}

/* Returns the new value of sip from the previous sip (o) and the written uip (u) as delegated by sideleg (d). */
function lift_uip(o : Sinterrupts, d : Sinterrupts, u : Uinterrupts) -> Sinterrupts = {
  let s : Sinterrupts = o;
  let s = if d.USI() == 0b1 then update_USI(s, u.USI()) else s;
  s
}

function legalize_uip(s : Sinterrupts, d : Sinterrupts, v : xlenbits) -> Sinterrupts = {
  lift_uip(s, d, Mk_Uinterrupts(v))
}

/* Returns the new value of sie from the previous sie (o) and the written uie (u) as delegated by sideleg (d). */
function lift_uie(o : Sinterrupts, d : Sinterrupts, u : Uinterrupts) -> Sinterrupts = {
  let s : Sinterrupts = o;
  let s = if d.UEI() == 0b1 then update_UEI(s, u.UEI()) else s;
  let s = if d.UTI() == 0b1 then update_UTI(s, u.UTI()) else s;
  let s = if d.USI() == 0b1 then update_USI(s, u.USI()) else s;
  s
}

function legalize_uie(s : Sinterrupts, d : Sinterrupts, v : xlenbits) -> Sinterrupts = {
  lift_uie(s, d, Mk_Uinterrupts(v))
}

register utvec    : Mtvec
register uscratch : xlenbits
register uepc     : xlenbits
register ucause   : Mcause
register utval    : xlenbits
