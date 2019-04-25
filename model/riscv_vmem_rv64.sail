/* RV64 Supervisor-mode address translation and page-table walks. */

/* Define the architectural satp and its legalizer. */

register satp : xlenbits

function legalize_satp(a : Architecture, o : xlenbits, v : xlenbits) -> xlenbits =
  legalize_satp64(a, o, v)

/* Compute the address translation mode. */

val translationMode : (Privilege) -> SATPMode effect {rreg, escape}
function translationMode(priv) = {
  if priv == Machine then Sbare
  else {
    let arch = architecture(get_mstatus_SXL(mstatus));
    match arch {
      Some(RV64) => {
        let mbits : satp_mode = Mk_Satp64(satp).Mode();
        match satp64Mode_of_bits(RV64, mbits) {
          Some(m) => m,
          None()  => internal_error("invalid RV64 translation mode in satp")
        }
      },
      Some(RV32) => {
        let s = Mk_Satp32(satp[31..0]);
        if s.Mode() == false then Sbare else Sv32
      },
      _    => internal_error("unsupported address translation arch")
    }
  }
}

/* Top-level address translation dispatcher */

val translateAddr : (xlenbits, AccessType, ReadType) -> TR_Result(xlenbits, ExceptionType) effect {escape, rmem, rreg, wmv, wmvt, wreg}
function translateAddr(vAddr, ac, rt) = {
  let effPriv : Privilege = match rt {
    Instruction => cur_privilege,
    Data        => if   mstatus.MPRV() == true
                   then privLevel_of_bits(mstatus.MPP())
                   else cur_privilege
  };
  let mxr    : bool   = mstatus.MXR() == true;
  let do_sum : bool   = mstatus.SUM() == true;
  let mode : SATPMode = translationMode(effPriv);

  let asid = curAsid64(satp);
  let ptb  = curPTB64(satp);

  match mode {
    Sbare => TR_Address(vAddr),
    Sv39  => match translate39(asid, ptb, vAddr[38 .. 0], ac, effPriv, mxr, do_sum, SV39_LEVELS - 1) {
               TR_Address(pa) => TR_Address(EXTZ(pa)),
               TR_Failure(f)  => TR_Failure(translationException(ac, f))
             },
    Sv48  => match translate48(asid, ptb, vAddr[47 .. 0], ac, effPriv, mxr, do_sum, SV48_LEVELS - 1) {
               TR_Address(pa) => TR_Address(EXTZ(pa)),
               TR_Failure(f)  => TR_Failure(translationException(ac, f))
             },
    _     => internal_error("unsupported address translation scheme")
  }
}

val flush_TLB : (option(xlenbits), option(xlenbits)) -> unit effect {rreg, wreg}
function flush_TLB(asid_xlen, addr_xlen) -> unit = {
  /* Flush both Sv39 and Sv48 TLBs. */
  let (addr39, addr48) : (option(vaddr39), option(vaddr48)) =
    match addr_xlen {
      None()  => (None(), None()),
      Some(a) => (Some(a[38 .. 0]), Some(a[47 .. 0]))
    };
  let asid : option(asid64) =
    match asid_xlen {
      None()  => None(),
      Some(a) => Some(a[15 .. 0])
  };
  flush_TLB39(asid, addr39);
  flush_TLB48(asid, addr48)
}

function init_vmem() -> unit = {
  init_vmem_sv39();
  init_vmem_sv48()
}
