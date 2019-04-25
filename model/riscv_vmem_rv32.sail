/* RV32 Supervisor-mode address translation and page-table walks. */

/* Define the architectural satp and its legalizer. */

register satp : xlenbits

function legalize_satp(a : Architecture, o : xlenbits, v : xlenbits) -> xlenbits =
  legalize_satp32(a, o, v)

/* Compute the address translation mode. */

val translationMode : (Privilege) -> SATPMode effect {rreg, escape}
function translationMode(priv) = {
  if priv == Machine then Sbare
  else {
    let arch = architecture(get_mstatus_SXL(mstatus));
    match arch {
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

  let asid = curAsid32(satp);
  let ptb  = curPTB32(satp);

  match mode {
    Sbare => TR_Address(vAddr),
    Sv32  => match translate32(asid, ptb, vAddr, ac, effPriv, mxr, do_sum, SV32_LEVELS - 1) {
               TR_Address(pa) => TR_Address(to_phys_addr(pa)),
               TR_Failure(f)  => TR_Failure(translationException(ac, f))
             },
    _     => internal_error("unsupported address translation scheme")
  }
}

val flush_TLB : (option(xlenbits), option(xlenbits)) -> unit effect {rreg, wreg}
function flush_TLB(asid_xlen, addr_xlen) -> unit = {
  let asid : option(asid32) =
    match (asid_xlen) {
      None()  => None(),
      Some(a) => Some(a[8  .. 0])
    };
  flush_TLB32(asid, addr_xlen)
}

function init_vmem () -> unit = {
  init_vmem_sv32()
}
