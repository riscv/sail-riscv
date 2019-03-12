/* Functional specification for the 'N' user-level interrupts standard extension. */

function is_UExt_CSR_defined(csr : bits(12), p : Privilege) -> bool =
  match (csr) {
    0x000 => haveUsrMode(),                  // ustatus
    0x004 => haveUsrMode(),                  // uie
    0x005 => haveUsrMode(),                  // utvec
    0x040 => haveUsrMode(),                  // uscratch
    0x041 => haveUsrMode(),                  // uepc
    0x042 => haveUsrMode(),                  // ucause
    0x043 => haveUsrMode(),                  // utval
    0x044 => haveUsrMode(),                  // uip
    _     => false
  }

function read_UExt_CSR csr : csreg -> option(xlenbits) = {
  let res : option(xlenbits) =
  match csr {
    0x000 => Some(lower_sstatus(lower_mstatus(mstatus)).bits()),
    0x004 => Some(lower_sie(lower_mie(mie, mideleg), sideleg).bits()),
    0x005 => Some(getCapOffsetBits(UTCC)),
    0x040 => Some(uscratch),
    0x041 => Some(getCapOffsetBits(UEPCC) & pc_alignment_mask()),
    0x042 => Some(ucause.bits()),
    0x043 => Some(utval),
    0x044 => Some(lower_sip(lower_mip(mip, mideleg), sideleg).bits()),
    _     => None()
  };
  res
}

function write_UExt_CSR(csr : csreg, value : xlenbits) -> bool = {
  let res : option(xlenbits) =
  match csr {
    0x000 => { mstatus = legalize_ustatus(mstatus, value); Some(mstatus.bits()) },
    0x004 => { let sie = legalize_uie(lower_mie(mie, mideleg), sideleg, value);
               mie = lift_sie(mie, mideleg, sie);
               Some(mie.bits()) },
    0x005 => { let utvec = legalize_tvec(Mk_Mtvec(getCapOffsetBits(UTCC)), value);
               UTCC = setCapOffsetOrNull(UTCC, utvec.bits());
               Some(utvec.bits()) },
    0x040 => { uscratch = value; Some(uscratch) },
    0x041 => {let uepc = legalize_xepc(value);
              UEPCC = setCapOffsetOrNull(UEPCC, uepc);
              Some(uepc) },
    0x042 => { ucause->bits() = value; Some(ucause.bits()) },
    0x043 => { utval = value; Some(utval) },
    0x044 => { let sip = legalize_uip(lower_mip(mip, mideleg), sideleg, value);
               mip = lift_sip(mip, mideleg, sip);
               Some(mip.bits()) },
    _     => None()
  };
  match res {
    Some(v) => { print_reg("CSR " ^ csr ^ " <- " ^ BitStr(v) ^ " (input: " ^ BitStr(value) ^ ")");
                 true },
    None()  => false
  }
}
