/* ****************************************************************** */
/* This file specifies the instructions in the 'Zicsr' extension.     */

/* ****************************************************************** */
union clause ast = CSR  : (bits(12), regbits, regbits, bool, csrop)

mapping encdec_csrop : csrop <-> bits(2) = {
  CSRRW <-> 0b01,
  CSRRS <-> 0b10,
  CSRRC <-> 0b11
}

mapping clause encdec = CSR(csr, rs1, rd, is_imm, op)
  <-> csr @ rs1 @ bool_bits(is_imm) @ encdec_csrop(op) @ rd @ 0b1110011

function readCSR csr : csreg -> xlenbits = {
  let res : xlenbits =
  match csr {
    /* machine mode */
    0xF11 => EXTZ(mvendorid),
    0xF12 => marchid,
    0xF13 => mimpid,
    0xF14 => mhartid,
    0x300 => mstatus.bits(),
    0x301 => misa.bits(),
    0x302 => medeleg.bits(),
    0x303 => mideleg.bits(),
    0x304 => mie.bits(),
    0x305 => mtvec.bits(),
    0x306 => EXTZ(mcounteren.bits()),
    0x340 => mscratch,
    0x341 => mepc & pc_alignment_mask(),
    0x342 => mcause.bits(),
    0x343 => mtval,
    0x344 => mip.bits(),

    0x3A0 => pmpcfg0,
    0x3B0 => pmpaddr0,

    /* supervisor mode */
    0x100 => lower_mstatus(mstatus).bits(),
    0x102 => sedeleg.bits(),
    0x103 => sideleg.bits(),
    0x104 => lower_mie(mie, mideleg).bits(),
    0x105 => stvec.bits(),
    0x106 => EXTZ(scounteren.bits()),
    0x140 => sscratch,
    0x141 => sepc & pc_alignment_mask(),
    0x142 => scause.bits(),
    0x143 => stval,
    0x144 => lower_mip(mip, mideleg).bits(),
    0x180 => satp,

    /* others */
    0xC00 => mcycle,
    0xC01 => mtime,
    0xC02 => minstret,

    /* trigger/debug */
    0x7a0 => ~(tselect),    /* this indicates we don't have any trigger support */

    _     =>  /* check extensions */
              match read_UExt_CSR(csr) {
                Some(res) => res,
                None()    => { print_bits("unhandled read to CSR ", csr);
                               0x0000_0000_0000_0000 }
              }
  };
  print_reg("CSR " ^ csr ^ " -> " ^ BitStr(res));
  res
}

function writeCSR (csr : csreg, value : xlenbits) -> unit = {
  let res : option(xlenbits) =
  match csr {
    /* machine mode */
    0x300 => { mstatus = legalize_mstatus(mstatus, value); Some(mstatus.bits()) },
    0x301 => { misa = legalize_misa(misa, value); Some(misa.bits()) },
    0x302 => { medeleg = legalize_medeleg(medeleg, value); Some(medeleg.bits()) },
    0x303 => { mideleg = legalize_mideleg(mideleg, value); Some(mideleg.bits()) },
    0x304 => { mie = legalize_mie(mie, value); Some(mie.bits()) },
    0x305 => { mtvec = legalize_tvec(mtvec, value); Some(mtvec.bits()) },
    0x306 => { mcounteren = legalize_mcounteren(mcounteren, value); Some(EXTZ(mcounteren.bits())) },
    0x340 => { mscratch = value; Some(mscratch) },
    0x341 => { mepc = legalize_xepc(value); Some(mepc) },
    0x342 => { mcause->bits() = value; Some(mcause.bits()) },
    0x343 => { mtval = value; Some(mtval) },
    0x344 => { mip = legalize_mip(mip, value); Some(mip.bits()) },

    0x3A0 => { pmpcfg0 = value; Some(pmpcfg0) }, /* FIXME: legalize */
    0x3B0 => { pmpaddr0 = value; Some(pmpaddr0) }, /* FIXME: legalize */

    /* supervisor mode */
    0x100 => { mstatus = legalize_sstatus(mstatus, value); Some(mstatus.bits()) },
    0x102 => { sedeleg = legalize_sedeleg(sedeleg, value); Some(sedeleg.bits()) },
    0x103 => { sideleg->bits() = value; Some(sideleg.bits()) }, /* TODO: does this need legalization? */
    0x104 => { mie = legalize_sie(mie, mideleg, value); Some(mie.bits()) },
    0x105 => { stvec = legalize_tvec(stvec, value); Some(stvec.bits()) },
    0x106 => { scounteren = legalize_scounteren(scounteren, value); Some(EXTZ(scounteren.bits())) },
    0x140 => { sscratch = value; Some(sscratch) },
    0x141 => { sepc = legalize_xepc(value); Some(sepc) },
    0x142 => { scause->bits() = value; Some(scause.bits()) },
    0x143 => { stval = value; Some(stval) },
    0x144 => { mip = legalize_sip(mip, mideleg, value); Some(mip.bits()) },
    0x180 => { satp = legalize_satp(cur_Architecture(), satp, value); Some(satp) },

    /* trigger/debug */
    0x7a0 => { tselect = value; Some(tselect) },

    /* counters */
    0xC00 => { mcycle = value; Some(mcycle) },
    /* FIXME: it is not clear whether writable mtime is platform-dependent. */
    0xC02 => { minstret = value; minstret_written = true; Some(minstret) },

    _     => None()
  };
  match res {
    Some(v) => print_reg("CSR " ^ csr ^ " <- " ^ BitStr(v) ^ " (input: " ^ BitStr(value) ^ ")"),
    None()  => { /* check extensions */
                 if write_UExt_CSR(csr, value)
                 then ()
                 else print_bits("unhandled write to CSR ", csr)
               }
  }
}

function clause execute CSR(csr, rs1, rd, is_imm, op) = {
  let rs1_val : xlenbits = if is_imm then EXTZ(rs1) else X(rs1);
  let isWrite : bool = match op {
    CSRRW  => true,
    _      => if is_imm then unsigned(rs1_val) != 0 else unsigned(rs1) != 0
  };
  if ~ (check_CSR(csr, cur_privilege, isWrite))
  then { handle_illegal(); false }
  else {
    let csr_val = readCSR(csr); /* could have side-effects, so technically shouldn't perform for CSRW[I] with rd == 0 */
    if isWrite then {
      let new_val : xlenbits = match op {
        CSRRW => rs1_val,
        CSRRS => csr_val | rs1_val,
        CSRRC => csr_val & ~(rs1_val)
      };
      writeCSR(csr, new_val)
    };
    X(rd) = csr_val;
    true
  }
}

mapping maybe_i : bool <-> string = {
  true  <-> "i",
  false <-> ""
}

mapping csr_mnemonic : csrop <-> string = {
  CSRRW <-> "csrrw",
  CSRRS <-> "csrrs",
  CSRRC <-> "csrrc"
}

mapping clause assembly = CSR(csr, rs1, rd, true, op)
  <-> csr_mnemonic(op) ^ "i" ^ spc() ^ reg_name(rd) ^ sep() ^ hex_bits_5(rs1) ^ sep() ^ csr_name_map(csr)
mapping clause assembly = CSR(csr, rs1, rd, false, op)
  <-> csr_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ csr_name_map(csr)



