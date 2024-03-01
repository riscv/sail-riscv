/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

/* Functional specification for the 'Smclic' fast interrupts extension. */
val vector_table_fetch : xlenbits -> VectorTableFetchResult
scattered function vector_table_fetch

val handle_mem_exception : (xlenbits, ExceptionType) -> unit
scattered function handle_mem_exception

/* masking for reads to xepc */
function inhv_pc_alignment_mask() -> xlenbits =
  ~(zero_extend(if (sizeof(xlen) == 32) then 0b11 else 0b111))

function isClicInterruptPending() -> (bool) = {
  var effective_pending : bits(1) = 0b0;
  foreach (i from 0 to (4096 - 1)) {
    effective_pending = effective_pending | (clicintip[i] & clicintie[i]);
  };  
  if effective_pending == 0b0 then false else true;
}

/* Interrupts are prioritized in privilege order, level */
function findClicPendingInterrupt() -> exc_code = {

  var top_ip_code : exc_code = zero_extend(0b0);
  var top_ip_priority : bits(10) = zero_extend(0b0);

  var ip_valid    : bits(1)  = zero_extend(0b0);
  var ip_priority : bits(10) = zero_extend(0b0);
  var ip_attr     : clicintattr_layout = undefined;
  var ip_trig     : bits(2)  = zero_extend(0b0);
  var ip_priv     : bits(2)  = zero_extend(0b0);
  var ip_level    : bits(8)  = zero_extend(0b0);
  var ip_code     : exc_code = zero_extend(0b0);

  foreach (i from 0 to (4096 - 1)) {
    ip_attr = clicintattr[i];
    ip_trig = zero_extend(ip_attr[TRIG]);
    match ip_trig {
    0b00 => if (clicintip_raw[i] == 0b1) then clicintip[i] = 0b1 else clicintip[i] = 0b0,          /* 00 - active high */
    0b10 => if (clicintip_raw[i] == 0b1) then clicintip[i] = 0b0 else clicintip[i] = 0b1,          /* 10 - active low  */
    0b01 => if (clicintip_raw[i] == 0b1) & (clicintip_raw_prev[i] == 0b0) then clicintip[i] = 0b1, /* 01 - posedge triggered */
    0b11 => if (clicintip_raw[i] == 0b0) & (clicintip_raw_prev[i] == 0b1) then clicintip[i] = 0b1  /* 11 - negedge triggered */
    };
    clicintip_raw_prev[i] = clicintip_raw[i];

    ip_valid    = clicintip[i] & clicintie[i];
    ip_priv     = zero_extend(ip_attr[MODE]);
    ip_level    = zero_extend(clicintctl[i]);
    ip_priority[9..8] = zero_extend(ip_priv); 
    ip_priority[7..0] = zero_extend(ip_level);
    ip_code     = zero_extend(to_bits(8,i));
    if (ip_valid == 0b1) then {
      /* if   get_config_print_platform()
       * then print_platform("pending and enabled interrupt ip_priority " ^BitStr(ip_priority) ^ " ip_code " ^ BitStr(ip_code));
       */
      if (unsigned(ip_priority) >= unsigned(top_ip_priority)) then {
        top_ip_priority = ip_priority;
        top_ip_code     = ip_code;
        /* if   get_config_print_platform()
         * then print_platform("new top_ip_priority " ^BitStr(ip_priority) ^ " ip_code " ^ BitStr(top_ip_code) ^ " mil " ^ BitStr(mil));
         */
      };
    }; 
  };
  top_ip_code;
}

/* Given the current privilege level, iterate over privileges to get a
 * pending set for an enabled privilege. This is only called for M/U or
 * M/S/U systems.
 */
function dispatchClicInterrupt(priv : Privilege) -> option((exc_code, Privilege)) = {
  assert(haveUsrMode(), "no user mode: M/U or M/S/U system required");

  var top_ip_code  : exc_code = undefined;
  var top_ip_attr  : clicintattr_layout = undefined;
  var top_ip_priv  : Privilege = undefined;
  var top_ip_level : ilbits = undefined;

  top_ip_code  = findClicPendingInterrupt();
  top_ip_attr  = clicintattr[unsigned(top_ip_code)];
  top_ip_priv  = privLevel_of_bits(top_ip_attr[MODE]);
  top_ip_level = clicintctl[unsigned(top_ip_code)];

  if isClicInterruptPending() == false then None() /* fast path */
  else {
    /* if   get_config_print_platform()
     * then print_platform("ClicInterruptPending ip_code " ^ BitStr(top_ip_code) ^ "top_ip_level " ^BitStr(top_ip_level));
     */

    /* Higher privileges than the current one are implicitly enabled,
     * while lower privileges are blocked.  An unsupported privilege is
     * considered blocked.
     */
    let mIE = priv != Machine | 
              (priv == Machine    & mstatus[MIE] == 0b1 & (unsigned(top_ip_level) > unsigned(mintthresh)));
    let sIE = haveSupMode() & (priv == User | 
              (priv == Supervisor & mstatus[SIE] == 0b1 & (unsigned(top_ip_level) > unsigned(sintthresh))));
    let uIE = haveNExt() & 
              (priv == User       & mstatus[UIE] == 0b1 & (unsigned(top_ip_level) > unsigned(uintthresh)));

    if      (uIE & (top_ip_priv == User)       & (unsigned(top_ip_level) > unsigned(uil))) then 
      let r = (top_ip_code, User)       in Some(r)
    else if (sIE & (top_ip_priv == Supervisor) & (unsigned(top_ip_level) > unsigned(sil))) then 
      let r = (top_ip_code, Supervisor) in Some(r) 
    else if (mIE & (top_ip_priv == Machine)    & (unsigned(top_ip_level) > unsigned(mil))) then     
      let r = (top_ip_code, Machine)    in Some(r) 
    else None()
  }
}

function prepare_shv_clic_trap_vector(p : Privilege, c : exc_code) -> xlenbits = {
  var tbase : xlenbits = mtvt;

  match (p) {
    Machine    => tbase = mtvt,
    Supervisor => tbase = stvt,
    User       => tbase = utvt
  };

  var table_entry_addr : xlenbits = undefined;
  table_entry_addr = if sizeof(xlen) == 32 then {tbase + 4*unsigned(c)} else {tbase + 8*unsigned(c)};

  match vector_table_fetch(table_entry_addr) {
    F_TableError(e, table_addr) => {inhv = 0b1; handle_mem_exception(table_entry_addr, e); table_entry_addr}, 
    F_TableEntry(table_entry)   => {
      clicintip[unsigned(c)] = 0b0; /* clear clicintip if edge_triggered */
      table_entry
    }
  }
}

function init_clicintregs() -> unit = {
  inhv             = zero_extend(0b0);
  mil              = zero_extend(0b0);
  mpil             = zero_extend(0b0);
  minhv            = zero_extend(0b0);
  sil              = zero_extend(0b0);
  spil             = zero_extend(0b0);
  sinhv            = zero_extend(0b0);
  uil              = zero_extend(0b0);
  spil             = zero_extend(0b0);
  sinhv            = zero_extend(0b0);

  foreach (i from 0 to (4096 - 1)) {
    clicintip_raw[i] = 0b0;
    clicintip_raw_prev[i] = 0b0;
    clicintip[i]   = 0b0;
    clicintie[i]   = 0b0;
    clicintctl[i]  = zero_extend(0b0); 
    clicintattr[i] = [clicintattr[i] with MODE = 0b11, TRIG = 0b00, SHV = 0b0];
  };
}

val access_nxti_CSR : (csreg, xlenbits, bitvector(5), bool, csrop, bool, Privilege) -> option(xlenbits)
function access_nxti_CSR(csr, rs1_val, rd, is_imm, op, isWrite, priv) -> option(xlenbits) = {
  /* nxti only valid for CSRR, CSRRSI, CSRRCI, CSRRS */
  let imm_nxti_writeCSR   : bool = isWrite & ((op == CSRRS) | (op == CSRRC)) & is_imm == true; /* CSRRSI, CSRRCI */
  let csrrs_nxti_writeCSR : bool = isWrite & (op == CSRRS) & is_imm == false;                  /* CSRRS */

  var pil : ilbits = mpil;
  pil = match priv {
    Machine    => mpil,
    Supervisor => spil,
    User       => upil
  };

  var csr_val : xlenbits = undefined;
  csr_val = if (op == CSRRS) then (mstatus.bits & zero_extend(0b11111)) |   zero_extend(rs1_val[4..0]) else 
                                  (mstatus.bits & zero_extend(0b11111)) & ~(zero_extend(rs1_val[4..0]));

  if (imm_nxti_writeCSR) then csr_val[23..16] = pil else csr_val[23..16] = rs1_val[23..16];
  
  if (isWrite == false) then {
    ext_read_CSR(csr);
  } else if (imm_nxti_writeCSR | csrrs_nxti_writeCSR) then {
    ext_write_CSR(csr, csr_val)       
  } else {
    None()
  }
}

/* Smclic CSRs */

function clause ext_is_CSR_defined(0x307, _) = haveSmclic() // mtvt
function clause ext_is_CSR_defined(0x345, _) = haveSmclic() // mnxti
function clause ext_is_CSR_defined(0xFB1, _) = haveSmclic() // mintstatus
function clause ext_is_CSR_defined(0x347, _) = haveSmclic() // mintthresh
function clause ext_is_CSR_defined(0x348, _) = haveSmclic() // mscratchcsw
function clause ext_is_CSR_defined(0x349, _) = haveSmclic() // mscratchcswl

function clause ext_read_CSR(0x307) = Some(mtvt)
function clause ext_read_CSR(0x345) = 
  if (isClicInterruptPending() == true & haveSmclic()) then {
    var top_ip_code  : exc_code = undefined;
    var top_ip_attr  : clicintattr_layout = undefined;
    var top_ip_priv  : Privilege = undefined;
    var top_ip_level : ilbits = undefined;
    var level_filter : ilbits = undefined;

    top_ip_code  = findClicPendingInterrupt();
    top_ip_attr  = clicintattr[unsigned(top_ip_code)];
    top_ip_priv  = privLevel_of_bits(top_ip_attr[MODE]);
    top_ip_level = clicintctl[unsigned(top_ip_code)];
    level_filter = if (unsigned(mpil) > unsigned(mintthresh)) then mpil else mintthresh;

    /* if   get_config_print_platform()
     * then print_platform("mnxti rd ip_code " ^BitStr(top_ip_code) ^ " ip_level " ^ BitStr(top_ip_level) ^ " level_filter " ^ BitStr(level_filter));
     */

    if ((top_ip_priv == Machine) & (unsigned(top_ip_level) > unsigned(level_filter))) then {
      let tbase : xlenbits = mtvt;
      var table_entry_addr : xlenbits = undefined;
      table_entry_addr = if sizeof(xlen) == 32 then {tbase + 4*unsigned(top_ip_code)} else {tbase + 8*unsigned(top_ip_code)};
      Some(table_entry_addr)
    } else {
      Some(zero_extend(0b0))      
    }     
  } else {
    Some(zero_extend(0b0))
  }

function clause ext_read_CSR(0xFB1) = {
  mintstatus.bits = zero_extend(0b0);
  mintstatus[mil] = mil;
  mintstatus[sil] = sil;
  mintstatus[uil] = uil;
  Some(mintstatus.bits);
}
function clause ext_read_CSR(0x347) = Some(zero_extend(mintthresh))
function clause ext_read_CSR(0x348) = None() /* accessing with rs1 set to x0 is reserved */  
function clause ext_read_CSR(0x349) = None() /* accessing with rs1 set to x0 is reserved */   

function clause ext_write_CSR(0x307, value) = { mtvt = value; Some(mtvt) }
function clause ext_write_CSR(0x345, value) = {

  /* In CLINT mode, reads of xnxti return 0, updates to xstatus proceed as in CLIC mode, but updates to
   * xintstatus and xcause do not take effect. */
  /*if (haveSmclic()) then { */
  /* Performed regardless of interrupt readiness */
  clicmstatus.bits = value;
  mstatus[MIE]  = clicmstatus[MIE];
  mstatus[SIE]  = clicmstatus[SIE];
  mstatus[UIE]  = clicmstatus[UIE];
  /* }; */

  if (isClicInterruptPending() == true & haveSmclic()) then {
    var top_ip_code  : exc_code = undefined;
    var top_ip_attr  : clicintattr_layout = undefined;
    var top_ip_priv  : Privilege = undefined;
    var top_ip_level : ilbits = undefined;
    var level_filter : ilbits = undefined;
    var value_or_pil : ilbits = undefined;

    top_ip_code = findClicPendingInterrupt();
    top_ip_attr = clicintattr[unsigned(top_ip_code)];
    top_ip_priv = privLevel_of_bits(top_ip_attr[MODE]);
    top_ip_level = clicintctl[unsigned(top_ip_code)];
    value_or_pil = value[23..16]; /* Note: access_nxti_CSR passes pil in value[23..16] for CSRRSI/CSRRCI, but rs1[23..16] for CSRRS */
    level_filter = if (unsigned(value_or_pil) > unsigned(mintthresh)) then value_or_pil else mintthresh;
    

    /* if   get_config_print_platform()
     * then print_platform("mnxti wr ip_code " ^BitStr(top_ip_code) ^ " ip_level " ^ BitStr(top_ip_level) ^ " level_filter " ^ BitStr(level_filter) ^ " value_or_pil " ^ BitStr(value_or_pil) ^ " mpil " ^ BitStr(mpil));
     */
    if ((top_ip_priv == Machine) & (unsigned(top_ip_level) > unsigned(level_filter)) ) then {
      if (value[4..0] != 0b00000) then {
        mil = top_ip_level;

        mcause[Cause]       = zero_extend(top_ip_code);
        mcause[IsInterrupt] = 0b1;
        clicintip[unsigned(top_ip_code)] = 0b0; /* clear clicintip if edge_triggered */
      }; 
      let tbase : xlenbits = mtvt;
      var table_entry_addr : xlenbits = undefined;
      table_entry_addr = if sizeof(xlen) == 32 then {tbase + 4*unsigned(top_ip_code)} else {tbase + 8*unsigned(top_ip_code)};
      Some(table_entry_addr)
    } else {
      Some(zero_extend(0b0))      
    }     
  } else {
    Some(zero_extend(0b0))
  }
}

function clause ext_write_CSR(0x347, value) = { mintthresh = value[7..0]; Some(zero_extend(mintthresh)) }
function clause ext_write_CSR(0x348, value) = {
  var rd_value : xlenbits = zero_extend(0b0); 
  if (privLevel_of_bits(mstatus[MPP]) == Machine) then {
    Some(value)
  } else {
    rd_value = mscratch;
    mscratch = value; 
    Some(rd_value)
  }
} 
function clause ext_write_CSR(0x349, value) = {
  var rd_value : xlenbits = zero_extend(0b0); 
  if ((mpil==zero_extend(0b0)) != (mil == zero_extend(0b0))) then {
    rd_value = mscratch;
    mscratch = value; 
    Some(rd_value)
  } else {
    Some(value)
  }
} 

/* Ssclic CSRs */

function clause ext_is_CSR_defined(0x107, _) = haveSmclic() & haveSupMode() // stvt
function clause ext_is_CSR_defined(0x145, _) = haveSmclic() & haveSupMode() // snxti
function clause ext_is_CSR_defined(0xDB1, _) = haveSmclic() & haveSupMode() // sintstatus
function clause ext_is_CSR_defined(0x147, _) = haveSmclic() & haveSupMode() // sintthresh
function clause ext_is_CSR_defined(0x148, _) = haveSmclic() & haveSupMode() // sscratchcsw
function clause ext_is_CSR_defined(0x149, _) = haveSmclic() & haveSupMode() // sscratchcswl

function clause ext_read_CSR(0x107) = Some(stvt)
function clause ext_read_CSR(0x145) = 
  if (isClicInterruptPending() == true & haveSmclic()) then {
    var top_ip_code  : exc_code = undefined;
    var top_ip_attr  : clicintattr_layout = undefined;
    var top_ip_priv  : Privilege = undefined;
    var top_ip_level : ilbits = undefined;
    var level_filter : ilbits = undefined;

    top_ip_code  = findClicPendingInterrupt();
    top_ip_attr  = clicintattr[unsigned(top_ip_code)];
    top_ip_priv  = privLevel_of_bits(top_ip_attr[MODE]);
    top_ip_level = clicintctl[unsigned(top_ip_code)];
    level_filter = if (unsigned(spil) > unsigned(sintthresh)) then spil else sintthresh;

    if ((top_ip_priv == Supervisor) & (unsigned(top_ip_level) > unsigned(level_filter))) then {
      let tbase : xlenbits = stvt;
      var table_entry_addr : xlenbits = undefined;
      table_entry_addr = if sizeof(xlen) == 32 then {tbase + 4*unsigned(top_ip_code)} else {tbase + 8*unsigned(top_ip_code)};
      Some(table_entry_addr)
    } else {
      Some(zero_extend(0b0))      
    }     
  } else {
    Some(zero_extend(0b0))
  }

function clause ext_read_CSR(0xDB1) = {
  mintstatus.bits = zero_extend(0b0);
  mintstatus[sil] = sil;
  mintstatus[uil] = uil;
  Some(mintstatus.bits);
}
function clause ext_read_CSR(0x147) = Some(zero_extend(sintthresh))
function clause ext_read_CSR(0x148) = None() /* accessing with rs1 set to x0 is reserved */ 
function clause ext_read_CSR(0x149) = None() /* accessing with rs1 set to x0 is reserved */  

function clause ext_write_CSR(0x107, value) = { stvt = value; Some(stvt) }
function clause ext_write_CSR(0x145, value) = { 
 /* In CLINT mode, reads of xnxti return 0, updates to xstatus proceed as in CLIC mode, but updates to
   * xintstatus and xcause do not take effect. */
  /*if (haveSmclic()) then { */
  /* Performed regardless of interrupt readiness */
  clicmstatus.bits = value;
  mstatus[SIE]  = clicmstatus[SIE];
  mstatus[UIE]  = clicmstatus[UIE];
  /* }; */

  if (isClicInterruptPending() == true & haveSmclic()) then {
    var top_ip_code  : exc_code = undefined;
    var top_ip_attr  : clicintattr_layout = undefined;
    var top_ip_priv  : Privilege = undefined;
    var top_ip_level : ilbits = undefined;
    var level_filter : ilbits = undefined;

    top_ip_code = findClicPendingInterrupt();
    top_ip_attr = clicintattr[unsigned(top_ip_code)];
    top_ip_priv = privLevel_of_bits(top_ip_attr[MODE]);
    top_ip_level = clicintctl[unsigned(top_ip_code)];
    level_filter = if (unsigned(value[23..16]) > unsigned(sintthresh)) then value[23..16] else sintthresh;
    /* Note: value[23..16] is pil for CSRRSI/CSRRCI, it is rs1[23..16] for CSRRS */

    /* if   get_config_print_platform()
     * then print_platform("snxti wr ip_code " ^BitStr(top_ip_code) ^ " ip_level " ^ BitStr(top_ip_level) ^ " level_filter " ^ BitStr(level_filter));
     */
    if ((top_ip_priv == Supervisor) & (unsigned(top_ip_level) > unsigned(level_filter)) ) then {
      if (value[4..0] != 0b00000) then {
        sil = top_ip_level;

        scause[Cause]       = zero_extend(top_ip_code);
        scause[IsInterrupt] = 0b1;
        clicintip[unsigned(top_ip_code)] = 0b0; /* clear clicintip if edge_triggered */
      }; 
      let tbase : xlenbits = stvt;
      var table_entry_addr : xlenbits = undefined;
      table_entry_addr = if sizeof(xlen) == 32 then {tbase + 4*unsigned(top_ip_code)} else {tbase + 8*unsigned(top_ip_code)};
      Some(table_entry_addr)
    } else {
      Some(zero_extend(0b0))      
    }     
  } else {
    Some(zero_extend(0b0))
  }
}

function clause ext_write_CSR(0x147, value) = { sintthresh = value[7..0]; Some(zero_extend(sintthresh)) }
function clause ext_write_CSR(0x148, value) = { 
  var rd_value : xlenbits = zero_extend(0b0); 
  if ((cur_privilege == Supervisor) & (privLevel_of_bits(mstatus[MPP]) == Supervisor)) then {
    Some(value)
  } else {
    rd_value = sscratch;
    sscratch = value; 
    Some(rd_value)
  }
} 
function clause ext_write_CSR(0x149, value) = { 
  var rd_value : xlenbits = zero_extend(0b0); 
  if ((spil==zero_extend(0b0)) != (sil == zero_extend(0b0))) then {
    rd_value = sscratch;
    sscratch = value; 
    Some(rd_value)
  } else {
    Some(value)
  }
} 

/* Suclic CSRs */

function clause ext_is_CSR_defined(0x007, _) = haveSmclic() & haveNExt() // utvt
function clause ext_is_CSR_defined(0x045, _) = haveSmclic() & haveNExt() // unxti
function clause ext_is_CSR_defined(0xCB1, _) = haveSmclic() & haveNExt() // uintstatus
function clause ext_is_CSR_defined(0x047, _) = haveSmclic() & haveNExt() // uintthresh
function clause ext_is_CSR_defined(0x049, _) = haveSmclic() & haveNExt() // uscratchcswl

function clause ext_read_CSR(0x007) = Some(utvt)
function clause ext_read_CSR(0x045) = 
  if (isClicInterruptPending() == true & haveSmclic()) then {
    var top_ip_code  : exc_code = undefined;
    var top_ip_attr  : clicintattr_layout = undefined;
    var top_ip_priv  : Privilege = undefined;
    var top_ip_level : ilbits = undefined;
    var level_filter : ilbits = undefined;

    top_ip_code  = findClicPendingInterrupt();
    top_ip_attr  = clicintattr[unsigned(top_ip_code)];
    top_ip_priv  = privLevel_of_bits(top_ip_attr[MODE]);
    top_ip_level = clicintctl[unsigned(top_ip_code)];
    level_filter = if (unsigned(upil) > unsigned(uintthresh)) then upil else uintthresh;

    if ((top_ip_priv == User) & (unsigned(top_ip_level) > unsigned(level_filter))) then {
      let tbase : xlenbits = utvt;
      var table_entry_addr : xlenbits = undefined;
      table_entry_addr = if sizeof(xlen) == 32 then {tbase + 4*unsigned(top_ip_code)} else {tbase + 8*unsigned(top_ip_code)};
      Some(table_entry_addr)
    } else {
      Some(zero_extend(0b0))      
    }     
  } else {
    Some(zero_extend(0b0))
  }

function clause ext_read_CSR(0xCB1) = {
  mintstatus.bits = zero_extend(0b0);
  mintstatus[uil] = uil;
  Some(mintstatus.bits);
}
function clause ext_read_CSR(0x047) = Some(zero_extend(uintthresh))
function clause ext_read_CSR(0x049) = None() /* accessing with rs1 set to x0 is reserved */   

function clause ext_write_CSR(0x007, value) = { utvt = value; Some(utvt) }
function clause ext_write_CSR(0x045, value) = { 
/* In CLINT mode, reads of xnxti return 0, updates to xstatus proceed as in CLIC mode, but updates to
   * xintstatus and xcause do not take effect. */
  /*if (haveSmclic()) then { */
  /* Performed regardless of interrupt readiness */
  clicmstatus.bits = value;
  mstatus[UIE]  = clicmstatus[UIE];
  /* }; */

  if (isClicInterruptPending() == true & haveSmclic()) then {
    var top_ip_code  : exc_code = undefined;
    var top_ip_attr  : clicintattr_layout = undefined;
    var top_ip_priv  : Privilege = undefined;
    var top_ip_level : ilbits = undefined;
    var level_filter : ilbits = undefined;

    top_ip_code = findClicPendingInterrupt();
    top_ip_attr = clicintattr[unsigned(top_ip_code)];
    top_ip_priv = privLevel_of_bits(top_ip_attr[MODE]);
    top_ip_level = clicintctl[unsigned(top_ip_code)];
    level_filter = if (unsigned(value[23..16]) > unsigned(uintthresh)) then value[23..16] else uintthresh;
    /* Note: value[23..16] is pil for CSRRSI/CSRRCI, it is rs1[23..16] for CSRRS */

    if ((top_ip_priv == User) & (unsigned(top_ip_level) > unsigned(level_filter)) ) then {
      if (value[4..0] != 0b00000) then {
        uil = top_ip_level;

        ucause[Cause]       = zero_extend(top_ip_code);
        ucause[IsInterrupt] = 0b1;
        clicintip[unsigned(top_ip_code)] = 0b0; /* clear clicintip if edge_triggered */
      }; 
      let tbase : xlenbits = utvt;
      var table_entry_addr : xlenbits = undefined;
      table_entry_addr = if sizeof(xlen) == 32 then {tbase + 4*unsigned(top_ip_code)} else {tbase + 8*unsigned(top_ip_code)};
      Some(table_entry_addr)
    } else {
      Some(zero_extend(0b0))      
    }     
  } else {
    Some(zero_extend(0b0))
  }
}

function clause ext_write_CSR(0x047, value) = { uintthresh = value[7..0]; Some(zero_extend(uintthresh)) }
function clause ext_write_CSR(0x049, value) = { 
  var rd_value : xlenbits = zero_extend(0b0); 
  if ((upil==zero_extend(0b0)) != (uil == zero_extend(0b0))) then {
    rd_value = uscratch;
    uscratch = value; 
    Some(rd_value)
  } else {
    Some(value)
  }
} 
