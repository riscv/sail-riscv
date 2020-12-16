/* ****************************************************************** */
/* This file specifies the instructions in the 'Zicsr' extension.     */

/* ****************************************************************** */
union clause ast = CSR  : (bits(12), regidx, regidx, bool, csrop)

mapping encdec_csrop : csrop <-> bits(2) = {
  CSRRW <-> 0b01,
  CSRRS <-> 0b10,
  CSRRC <-> 0b11
}

mapping clause encdec = CSR(csr, rs1, rd, is_imm, op)
  <-> csr @ rs1 @ bool_bits(is_imm) @ encdec_csrop(op) @ rd @ 0b1110011

function readCSR csr : csreg -> xlenbits = {
  let res : xlenbits =
  match (csr, sizeof(xlen)) {
    /* machine mode */
    (0xF11,  _) => EXTZ(mvendorid),
    (0xF12,  _) => marchid,
    (0xF13,  _) => mimpid,
    (0xF14,  _) => mhartid,
    (0x300,  _) => mstatus.bits(),
    (0x301,  _) => misa.bits(),
    (0x302,  _) => medeleg.bits(),
    (0x303,  _) => mideleg.bits(),
    (0x304,  _) => mie.bits(),
    (0x305,  _) => get_mtvec(),
    (0x306,  _) => EXTZ(mcounteren.bits()),
    (0x310, 32) => mstatush.bits(),
    (0x320,  _) => EXTZ(mcountinhibit.bits()),

    (0x323,  _) => mhpmevents[0],
    (0x324,  _) => mhpmevents[1],
    (0x325,  _) => mhpmevents[2],
    (0x326,  _) => mhpmevents[3],
    (0x327,  _) => mhpmevents[4],
    (0x328,  _) => mhpmevents[5],
    (0x329,  _) => mhpmevents[6],
    (0x32A,  _) => mhpmevents[7],
    (0x32B,  _) => mhpmevents[8],
    (0x32C,  _) => mhpmevents[9],
    (0x32D,  _) => mhpmevents[10],
    (0x32E,  _) => mhpmevents[11],
    (0x32F,  _) => mhpmevents[12],
    (0x330,  _) => mhpmevents[13],
    (0x331,  _) => mhpmevents[14],
    (0x332,  _) => mhpmevents[15],
    (0x333,  _) => mhpmevents[16],
    (0x334,  _) => mhpmevents[17],
    (0x335,  _) => mhpmevents[18],
    (0x336,  _) => mhpmevents[19],
    (0x337,  _) => mhpmevents[20],
    (0x338,  _) => mhpmevents[21],
    (0x339,  _) => mhpmevents[22],
    (0x33A,  _) => mhpmevents[23],
    (0x33B,  _) => mhpmevents[24],
    (0x33C,  _) => mhpmevents[25],
    (0x33D,  _) => mhpmevents[26],
    (0x33E,  _) => mhpmevents[27],
    (0x33F,  _) => mhpmevents[28],

    (0x340,  _) => mscratch,
    (0x341,  _) => get_xret_target(Machine) & pc_alignment_mask(),
    (0x342,  _) => mcause.bits(),
    (0x343,  _) => mtval,
    (0x344,  _) => mip.bits(),

    (0x3A0,  _) => pmpReadCfgReg(0),           // pmpcfg0
    (0x3A1, 32) => pmpReadCfgReg(1),           // pmpcfg1
    (0x3A2,  _) => pmpReadCfgReg(2),           // pmpcfg2
    (0x3A3, 32) => pmpReadCfgReg(3),           // pmpcfg3

    (0x3B0,  _) => pmpaddr0,
    (0x3B1,  _) => pmpaddr1,
    (0x3B2,  _) => pmpaddr2,
    (0x3B3,  _) => pmpaddr3,
    (0x3B4,  _) => pmpaddr4,
    (0x3B5,  _) => pmpaddr5,
    (0x3B6,  _) => pmpaddr6,
    (0x3B7,  _) => pmpaddr7,
    (0x3B8,  _) => pmpaddr8,
    (0x3B9,  _) => pmpaddr9,
    (0x3BA,  _) => pmpaddr10,
    (0x3BB,  _) => pmpaddr11,
    (0x3BC,  _) => pmpaddr12,
    (0x3BD,  _) => pmpaddr13,
    (0x3BE,  _) => pmpaddr14,
    (0x3BF,  _) => pmpaddr15,

    /* machine mode counters */
    (0xB00,  _) => mcycle[(sizeof(xlen) - 1) .. 0],
    (0xB02,  _) => minstret[(sizeof(xlen) - 1) .. 0],
    (0xB03,  _) => mhpmcounters[0][(sizeof(xlen) - 1) .. 0],
    (0xB04,  _) => mhpmcounters[1][(sizeof(xlen) - 1) .. 0],
    (0xB05,  _) => mhpmcounters[2][(sizeof(xlen) - 1) .. 0],
    (0xB06,  _) => mhpmcounters[3][(sizeof(xlen) - 1) .. 0],
    (0xB07,  _) => mhpmcounters[4][(sizeof(xlen) - 1) .. 0],
    (0xB08,  _) => mhpmcounters[5][(sizeof(xlen) - 1) .. 0],
    (0xB09,  _) => mhpmcounters[6][(sizeof(xlen) - 1) .. 0],
    (0xB0A,  _) => mhpmcounters[7][(sizeof(xlen) - 1) .. 0],
    (0xB0B,  _) => mhpmcounters[8][(sizeof(xlen) - 1) .. 0],
    (0xB0C,  _) => mhpmcounters[9][(sizeof(xlen) - 1) .. 0],
    (0xB0D,  _) => mhpmcounters[10][(sizeof(xlen) - 1) .. 0],
    (0xB0E,  _) => mhpmcounters[11][(sizeof(xlen) - 1) .. 0],
    (0xB0F,  _) => mhpmcounters[12][(sizeof(xlen) - 1) .. 0],
    (0xB10,  _) => mhpmcounters[13][(sizeof(xlen) - 1) .. 0],
    (0xB11,  _) => mhpmcounters[14][(sizeof(xlen) - 1) .. 0],
    (0xB12,  _) => mhpmcounters[15][(sizeof(xlen) - 1) .. 0],
    (0xB13,  _) => mhpmcounters[16][(sizeof(xlen) - 1) .. 0],
    (0xB14,  _) => mhpmcounters[17][(sizeof(xlen) - 1) .. 0],
    (0xB15,  _) => mhpmcounters[18][(sizeof(xlen) - 1) .. 0],
    (0xB16,  _) => mhpmcounters[19][(sizeof(xlen) - 1) .. 0],
    (0xB17,  _) => mhpmcounters[20][(sizeof(xlen) - 1) .. 0],
    (0xB18,  _) => mhpmcounters[21][(sizeof(xlen) - 1) .. 0],
    (0xB19,  _) => mhpmcounters[22][(sizeof(xlen) - 1) .. 0],
    (0xB1A,  _) => mhpmcounters[23][(sizeof(xlen) - 1) .. 0],
    (0xB1B,  _) => mhpmcounters[24][(sizeof(xlen) - 1) .. 0],
    (0xB1C,  _) => mhpmcounters[25][(sizeof(xlen) - 1) .. 0],
    (0xB1D,  _) => mhpmcounters[26][(sizeof(xlen) - 1) .. 0],
    (0xB1E,  _) => mhpmcounters[27][(sizeof(xlen) - 1) .. 0],
    (0xB1F,  _) => mhpmcounters[28][(sizeof(xlen) - 1) .. 0],

    (0xB80, 32) => mcycle[63 .. 32],
    (0xB82, 32) => minstret[63 .. 32],
    (0xB83, 32) => mhpmcounters[0][63 .. 32],
    (0xB84, 32) => mhpmcounters[1][63 .. 32],
    (0xB85, 32) => mhpmcounters[2][63 .. 32],
    (0xB86, 32) => mhpmcounters[3][63 .. 32],
    (0xB87, 32) => mhpmcounters[4][63 .. 32],
    (0xB88, 32) => mhpmcounters[5][63 .. 32],
    (0xB89, 32) => mhpmcounters[6][63 .. 32],
    (0xB8A, 32) => mhpmcounters[7][63 .. 32],
    (0xB8B, 32) => mhpmcounters[8][63 .. 32],
    (0xB8C, 32) => mhpmcounters[9][63 .. 32],
    (0xB8D, 32) => mhpmcounters[10][63 .. 32],
    (0xB8E, 32) => mhpmcounters[11][63 .. 32],
    (0xB8F, 32) => mhpmcounters[12][63 .. 32],
    (0xB90, 32) => mhpmcounters[13][63 .. 32],
    (0xB91, 32) => mhpmcounters[14][63 .. 32],
    (0xB92, 32) => mhpmcounters[15][63 .. 32],
    (0xB93, 32) => mhpmcounters[16][63 .. 32],
    (0xB94, 32) => mhpmcounters[17][63 .. 32],
    (0xB95, 32) => mhpmcounters[18][63 .. 32],
    (0xB96, 32) => mhpmcounters[19][63 .. 32],
    (0xB97, 32) => mhpmcounters[20][63 .. 32],
    (0xB98, 32) => mhpmcounters[21][63 .. 32],
    (0xB99, 32) => mhpmcounters[22][63 .. 32],
    (0xB9A, 32) => mhpmcounters[23][63 .. 32],
    (0xB9B, 32) => mhpmcounters[24][63 .. 32],
    (0xB9C, 32) => mhpmcounters[25][63 .. 32],
    (0xB9D, 32) => mhpmcounters[26][63 .. 32],
    (0xB9E, 32) => mhpmcounters[27][63 .. 32],
    (0xB9F, 32) => mhpmcounters[28][63 .. 32],

    /* trigger/debug */
    (0x7a0,  _) => ~(tselect),  /* this indicates we don't have any trigger support */

    /* supervisor mode */
    (0x100,  _) => lower_mstatus(mstatus).bits(),
    (0x102,  _) => sedeleg.bits(),
    (0x103,  _) => sideleg.bits(),
    (0x104,  _) => lower_mie(mie, mideleg).bits(),
    (0x105,  _) => get_stvec(),
    (0x106,  _) => EXTZ(scounteren.bits()),
    (0x140,  _) => sscratch,
    (0x141,  _) => get_xret_target(Supervisor) & pc_alignment_mask(),
    (0x142,  _) => scause.bits(),
    (0x143,  _) => stval,
    (0x144,  _) => lower_mip(mip, mideleg).bits(),
    (0x180,  _) => satp,

    /* user mode counters */
    (0xC00,  _) => mcycle[(sizeof(xlen) - 1) .. 0],
    (0xC01,  _) => mtime[(sizeof(xlen) - 1) .. 0],
    (0xC02,  _) => minstret[(sizeof(xlen) - 1) .. 0],
    (0xC03,  _) => mhpmcounters[0][(sizeof(xlen) - 1) .. 0],
    (0xC04,  _) => mhpmcounters[1][(sizeof(xlen) - 1) .. 0],
    (0xC05,  _) => mhpmcounters[2][(sizeof(xlen) - 1) .. 0],
    (0xC06,  _) => mhpmcounters[3][(sizeof(xlen) - 1) .. 0],
    (0xC07,  _) => mhpmcounters[4][(sizeof(xlen) - 1) .. 0],
    (0xC08,  _) => mhpmcounters[5][(sizeof(xlen) - 1) .. 0],
    (0xC09,  _) => mhpmcounters[6][(sizeof(xlen) - 1) .. 0],
    (0xC0A,  _) => mhpmcounters[7][(sizeof(xlen) - 1) .. 0],
    (0xC0B,  _) => mhpmcounters[8][(sizeof(xlen) - 1) .. 0],
    (0xC0C,  _) => mhpmcounters[9][(sizeof(xlen) - 1) .. 0],
    (0xC0D,  _) => mhpmcounters[10][(sizeof(xlen) - 1) .. 0],
    (0xC0E,  _) => mhpmcounters[11][(sizeof(xlen) - 1) .. 0],
    (0xC0F,  _) => mhpmcounters[12][(sizeof(xlen) - 1) .. 0],
    (0xC10,  _) => mhpmcounters[13][(sizeof(xlen) - 1) .. 0],
    (0xC11,  _) => mhpmcounters[14][(sizeof(xlen) - 1) .. 0],
    (0xC12,  _) => mhpmcounters[15][(sizeof(xlen) - 1) .. 0],
    (0xC13,  _) => mhpmcounters[16][(sizeof(xlen) - 1) .. 0],
    (0xC14,  _) => mhpmcounters[17][(sizeof(xlen) - 1) .. 0],
    (0xC15,  _) => mhpmcounters[18][(sizeof(xlen) - 1) .. 0],
    (0xC16,  _) => mhpmcounters[19][(sizeof(xlen) - 1) .. 0],
    (0xC17,  _) => mhpmcounters[20][(sizeof(xlen) - 1) .. 0],
    (0xC18,  _) => mhpmcounters[21][(sizeof(xlen) - 1) .. 0],
    (0xC19,  _) => mhpmcounters[22][(sizeof(xlen) - 1) .. 0],
    (0xC1A,  _) => mhpmcounters[23][(sizeof(xlen) - 1) .. 0],
    (0xC1B,  _) => mhpmcounters[24][(sizeof(xlen) - 1) .. 0],
    (0xC1C,  _) => mhpmcounters[25][(sizeof(xlen) - 1) .. 0],
    (0xC1D,  _) => mhpmcounters[26][(sizeof(xlen) - 1) .. 0],
    (0xC1E,  _) => mhpmcounters[27][(sizeof(xlen) - 1) .. 0],
    (0xC1F,  _) => mhpmcounters[28][(sizeof(xlen) - 1) .. 0],

    (0xC80, 32) => mcycle[63 .. 32],
    (0xC81, 32) => mtime[63 .. 32],
    (0xC82, 32) => minstret[63 .. 32],
    (0xC83, 32) => mhpmcounters[0][63 .. 32],
    (0xC84, 32) => mhpmcounters[1][63 .. 32],
    (0xC85, 32) => mhpmcounters[2][63 .. 32],
    (0xC86, 32) => mhpmcounters[3][63 .. 32],
    (0xC87, 32) => mhpmcounters[4][63 .. 32],
    (0xC88, 32) => mhpmcounters[5][63 .. 32],
    (0xC89, 32) => mhpmcounters[6][63 .. 32],
    (0xC8A, 32) => mhpmcounters[7][63 .. 32],
    (0xC8B, 32) => mhpmcounters[8][63 .. 32],
    (0xC8C, 32) => mhpmcounters[9][63 .. 32],
    (0xC8D, 32) => mhpmcounters[10][63 .. 32],
    (0xC8E, 32) => mhpmcounters[11][63 .. 32],
    (0xC8F, 32) => mhpmcounters[12][63 .. 32],
    (0xC90, 32) => mhpmcounters[13][63 .. 32],
    (0xC91, 32) => mhpmcounters[14][63 .. 32],
    (0xC92, 32) => mhpmcounters[15][63 .. 32],
    (0xC93, 32) => mhpmcounters[16][63 .. 32],
    (0xC94, 32) => mhpmcounters[17][63 .. 32],
    (0xC95, 32) => mhpmcounters[18][63 .. 32],
    (0xC96, 32) => mhpmcounters[19][63 .. 32],
    (0xC97, 32) => mhpmcounters[20][63 .. 32],
    (0xC98, 32) => mhpmcounters[21][63 .. 32],
    (0xC99, 32) => mhpmcounters[22][63 .. 32],
    (0xC9A, 32) => mhpmcounters[23][63 .. 32],
    (0xC9B, 32) => mhpmcounters[24][63 .. 32],
    (0xC9C, 32) => mhpmcounters[25][63 .. 32],
    (0xC9D, 32) => mhpmcounters[26][63 .. 32],
    (0xC9E, 32) => mhpmcounters[27][63 .. 32],
    (0xC9F, 32) => mhpmcounters[28][63 .. 32],

    _           => /* check extensions */
                   match ext_read_CSR(csr) {
                     Some(res) => res,
                     None()    => { print_bits("unhandled read to CSR ", csr);
                                    EXTZ(0x0) }
                   }
  };
  if   get_config_print_reg()
  then print_reg("CSR " ^ to_str(csr) ^ " -> " ^ BitStr(res));
  res
}

function writeCSR (csr : csreg, value : xlenbits) -> unit = {
  let res : option(xlenbits) =
  match (csr, sizeof(xlen)) {
    /* machine mode */
    (0x300,  _) => { mstatus = legalize_mstatus(mstatus, value); Some(mstatus.bits()) },
    (0x301,  _) => { misa = legalize_misa(misa, value); Some(misa.bits()) },
    (0x302,  _) => { medeleg = legalize_medeleg(medeleg, value); Some(medeleg.bits()) },
    (0x303,  _) => { mideleg = legalize_mideleg(mideleg, value); Some(mideleg.bits()) },
    (0x304,  _) => { mie = legalize_mie(mie, value); Some(mie.bits()) },
    (0x305,  _) => { Some(set_mtvec(value)) },
    (0x306,  _) => { mcounteren = legalize_mcounteren(mcounteren, value); Some(EXTZ(mcounteren.bits())) },
    (0x310, 32) => { Some(mstatush.bits()) }, // ignore writes for now
    (0x320,  _) => { mcountinhibit = legalize_mcountinhibit(mcountinhibit, value); Some(EXTZ(mcountinhibit.bits())) },
    (0x323,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 0), value, mhpmevents[0]); mhpmevents[0] = value; Some(value) },
    (0x324,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 1), value, mhpmevents[1]); mhpmevents[1] = value; Some(value) },
    (0x325,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 2), value, mhpmevents[2]); mhpmevents[2] = value; Some(value) },
    (0x326,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 3), value, mhpmevents[3]); mhpmevents[3] = value; Some(value) },
    (0x327,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 4), value, mhpmevents[4]); mhpmevents[4] = value; Some(value) },
    (0x328,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 5), value, mhpmevents[5]); mhpmevents[5] = value; Some(value) },
    (0x329,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 6), value, mhpmevents[6]); mhpmevents[6] = value; Some(value) },
    (0x32A,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 7), value, mhpmevents[7]); mhpmevents[7] = value; Some(value) },
    (0x32B,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 8), value, mhpmevents[8]); mhpmevents[8] = value; Some(value) },
    (0x32C,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 9), value, mhpmevents[9]); mhpmevents[9] = value; Some(value) },
    (0x32D,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 10), value, mhpmevents[10]); mhpmevents[10] = value; Some(value) },
    (0x32E,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 11), value, mhpmevents[11]); mhpmevents[11] = value; Some(value) },
    (0x32F,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 12), value, mhpmevents[12]); mhpmevents[12] = value; Some(value) },
    (0x330,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 13), value, mhpmevents[13]); mhpmevents[13] = value; Some(value) },
    (0x331,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 14), value, mhpmevents[14]); mhpmevents[14] = value; Some(value) },
    (0x332,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 15), value, mhpmevents[15]); mhpmevents[15] = value; Some(value) },
    (0x333,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 16), value, mhpmevents[16]); mhpmevents[16] = value; Some(value) },
    (0x334,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 17), value, mhpmevents[17]); mhpmevents[17] = value; Some(value) },
    (0x335,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 18), value, mhpmevents[18]); mhpmevents[18] = value; Some(value) },
    (0x336,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 19), value, mhpmevents[19]); mhpmevents[19] = value; Some(value) },
    (0x337,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 20), value, mhpmevents[10]); mhpmevents[20] = value; Some(value) },
    (0x338,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 21), value, mhpmevents[21]); mhpmevents[21] = value; Some(value) },
    (0x339,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 22), value, mhpmevents[22]); mhpmevents[22] = value; Some(value) },
    (0x33A,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 23), value, mhpmevents[23]); mhpmevents[23] = value; Some(value) },
    (0x33B,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 24), value, mhpmevents[24]); mhpmevents[24] = value; Some(value) },
    (0x33C,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 25), value, mhpmevents[25]); mhpmevents[25] = value; Some(value) },
    (0x33D,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 26), value, mhpmevents[26]); mhpmevents[26] = value; Some(value) },
    (0x33E,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 27), value, mhpmevents[27]); mhpmevents[27] = value; Some(value) },
    (0x33F,  _) => { plat_write_mhpmevent(to_bits(sizeof(xlen), 28), value, mhpmevents[28]); mhpmevents[28] = value; Some(value) },

    (0x340,  _) => { mscratch = value; Some(mscratch) },
    (0x341,  _) => { Some(set_xret_target(Machine, value)) },
    (0x342,  _) => { mcause->bits() = value; Some(mcause.bits()) },
    (0x343,  _) => { mtval = value; Some(mtval) },
    (0x344,  _) => { mip = legalize_mip(mip, value); Some(mip.bits()) },

    // Note: Some(value) returned below is not the legalized value due to locked entries
    (0x3A0,  _) => { pmpWriteCfgReg(0, value); Some(pmpReadCfgReg(0)) },  // pmpcfg0
    (0x3A1, 32) => { pmpWriteCfgReg(1, value); Some(pmpReadCfgReg(1)) },  // pmpcfg1
    (0x3A2,  _) => { pmpWriteCfgReg(2, value); Some(pmpReadCfgReg(2)) },  // pmpcfg2
    (0x3A3, 32) => { pmpWriteCfgReg(3, value); Some(pmpReadCfgReg(3)) },  // pmpcfg3

    (0x3B0,  _) => { pmpaddr0  = pmpWriteAddr(pmpLocked(pmp0cfg),  pmpTORLocked(pmp1cfg),  pmpaddr0,  value); Some(pmpaddr0) },
    (0x3B1,  _) => { pmpaddr1  = pmpWriteAddr(pmpLocked(pmp1cfg),  pmpTORLocked(pmp2cfg),  pmpaddr1,  value); Some(pmpaddr1) },
    (0x3B2,  _) => { pmpaddr2  = pmpWriteAddr(pmpLocked(pmp2cfg),  pmpTORLocked(pmp3cfg),  pmpaddr2,  value); Some(pmpaddr2) },
    (0x3B3,  _) => { pmpaddr3  = pmpWriteAddr(pmpLocked(pmp3cfg),  pmpTORLocked(pmp4cfg),  pmpaddr3,  value); Some(pmpaddr3) },
    (0x3B4,  _) => { pmpaddr4  = pmpWriteAddr(pmpLocked(pmp4cfg),  pmpTORLocked(pmp5cfg),  pmpaddr4,  value); Some(pmpaddr4) },
    (0x3B5,  _) => { pmpaddr5  = pmpWriteAddr(pmpLocked(pmp5cfg),  pmpTORLocked(pmp6cfg),  pmpaddr5,  value); Some(pmpaddr5) },
    (0x3B6,  _) => { pmpaddr6  = pmpWriteAddr(pmpLocked(pmp6cfg),  pmpTORLocked(pmp7cfg),  pmpaddr6,  value); Some(pmpaddr6) },
    (0x3B7,  _) => { pmpaddr7  = pmpWriteAddr(pmpLocked(pmp7cfg),  pmpTORLocked(pmp8cfg),  pmpaddr7,  value); Some(pmpaddr7) },
    (0x3B8,  _) => { pmpaddr8  = pmpWriteAddr(pmpLocked(pmp8cfg),  pmpTORLocked(pmp9cfg),  pmpaddr8,  value); Some(pmpaddr8) },
    (0x3B9,  _) => { pmpaddr9  = pmpWriteAddr(pmpLocked(pmp9cfg),  pmpTORLocked(pmp10cfg), pmpaddr9,  value); Some(pmpaddr9) },
    (0x3BA,  _) => { pmpaddr10 = pmpWriteAddr(pmpLocked(pmp10cfg), pmpTORLocked(pmp11cfg), pmpaddr10, value); Some(pmpaddr10) },
    (0x3BB,  _) => { pmpaddr11 = pmpWriteAddr(pmpLocked(pmp11cfg), pmpTORLocked(pmp12cfg), pmpaddr11, value); Some(pmpaddr11) },
    (0x3BC,  _) => { pmpaddr12 = pmpWriteAddr(pmpLocked(pmp12cfg), pmpTORLocked(pmp13cfg), pmpaddr12, value); Some(pmpaddr12) },
    (0x3BD,  _) => { pmpaddr13 = pmpWriteAddr(pmpLocked(pmp13cfg), pmpTORLocked(pmp14cfg), pmpaddr13, value); Some(pmpaddr13) },
    (0x3BE,  _) => { pmpaddr14 = pmpWriteAddr(pmpLocked(pmp14cfg), pmpTORLocked(pmp15cfg), pmpaddr14, value); Some(pmpaddr14) },
    (0x3BF,  _) => { pmpaddr15 = pmpWriteAddr(pmpLocked(pmp15cfg), false,                  pmpaddr15, value); Some(pmpaddr15) },

    /* machine mode counters */
    (0xB00,  _) => { mcycle[(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB02,  _) => { minstret[(sizeof(xlen) - 1) .. 0] = value; minstret_written = true; Some(value) },
    (0xB03,  _) => { mhpmcounters[0][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB04,  _) => { mhpmcounters[1][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB05,  _) => { mhpmcounters[2][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB06,  _) => { mhpmcounters[3][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB07,  _) => { mhpmcounters[4][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB08,  _) => { mhpmcounters[5][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB09,  _) => { mhpmcounters[6][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0A,  _) => { mhpmcounters[7][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0B,  _) => { mhpmcounters[8][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0C,  _) => { mhpmcounters[9][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0D,  _) => { mhpmcounters[10][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0E,  _) => { mhpmcounters[11][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB0F,  _) => { mhpmcounters[12][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB10,  _) => { mhpmcounters[13][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB11,  _) => { mhpmcounters[14][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB12,  _) => { mhpmcounters[15][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB13,  _) => { mhpmcounters[16][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB14,  _) => { mhpmcounters[17][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB15,  _) => { mhpmcounters[18][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB16,  _) => { mhpmcounters[19][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB17,  _) => { mhpmcounters[20][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB18,  _) => { mhpmcounters[21][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB19,  _) => { mhpmcounters[22][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1A,  _) => { mhpmcounters[23][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1B,  _) => { mhpmcounters[24][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1C,  _) => { mhpmcounters[25][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1D,  _) => { mhpmcounters[26][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1E,  _) => { mhpmcounters[27][(sizeof(xlen) - 1) .. 0] = value; Some(value) },
    (0xB1F,  _) => { mhpmcounters[28][(sizeof(xlen) - 1) .. 0] = value; Some(value) },

    (0xB80, 32) => { mcycle[63 .. 32] = value; Some(value) },
    (0xB82, 32) => { minstret[63 .. 32] = value; minstret_written = true; Some(value) },
    (0xB83, 32) => { mhpmcounters[0][63 .. 32] = value; Some(value) },
    (0xB84, 32) => { mhpmcounters[1][63 .. 32] = value; Some(value) },
    (0xB85, 32) => { mhpmcounters[2][63 .. 32] = value; Some(value) },
    (0xB86, 32) => { mhpmcounters[3][63 .. 32] = value; Some(value) },
    (0xB87, 32) => { mhpmcounters[4][63 .. 32] = value; Some(value) },
    (0xB88, 32) => { mhpmcounters[5][63 .. 32] = value; Some(value) },
    (0xB89, 32) => { mhpmcounters[6][63 .. 32] = value; Some(value) },
    (0xB8A, 32) => { mhpmcounters[7][63 .. 32] = value; Some(value) },
    (0xB8B, 32) => { mhpmcounters[8][63 .. 32] = value; Some(value) },
    (0xB8C, 32) => { mhpmcounters[9][63 .. 32] = value; Some(value) },
    (0xB8D, 32) => { mhpmcounters[10][63 .. 32] = value; Some(value) },
    (0xB8E, 32) => { mhpmcounters[11][63 .. 32] = value; Some(value) },
    (0xB8F, 32) => { mhpmcounters[12][63 .. 32] = value; Some(value) },
    (0xB90, 32) => { mhpmcounters[13][63 .. 32] = value; Some(value) },
    (0xB91, 32) => { mhpmcounters[14][63 .. 32] = value; Some(value) },
    (0xB92, 32) => { mhpmcounters[15][63 .. 32] = value; Some(value) },
    (0xB93, 32) => { mhpmcounters[16][63 .. 32] = value; Some(value) },
    (0xB94, 32) => { mhpmcounters[17][63 .. 32] = value; Some(value) },
    (0xB95, 32) => { mhpmcounters[18][63 .. 32] = value; Some(value) },
    (0xB96, 32) => { mhpmcounters[19][63 .. 32] = value; Some(value) },
    (0xB97, 32) => { mhpmcounters[20][63 .. 32] = value; Some(value) },
    (0xB98, 32) => { mhpmcounters[21][63 .. 32] = value; Some(value) },
    (0xB99, 32) => { mhpmcounters[22][63 .. 32] = value; Some(value) },
    (0xB9A, 32) => { mhpmcounters[23][63 .. 32] = value; Some(value) },
    (0xB9B, 32) => { mhpmcounters[24][63 .. 32] = value; Some(value) },
    (0xB9C, 32) => { mhpmcounters[25][63 .. 32] = value; Some(value) },
    (0xB9D, 32) => { mhpmcounters[26][63 .. 32] = value; Some(value) },
    (0xB9E, 32) => { mhpmcounters[27][63 .. 32] = value; Some(value) },
    (0xB9F, 32) => { mhpmcounters[28][63 .. 32] = value; Some(value) },

    /* trigger/debug */
    (0x7a0,  _) => { tselect = value; Some(tselect) },

    /* supervisor mode */
    (0x100,  _) => { mstatus = legalize_sstatus(mstatus, value); Some(mstatus.bits()) },
    (0x102,  _) => { sedeleg = legalize_sedeleg(sedeleg, value); Some(sedeleg.bits()) },
    (0x103,  _) => { sideleg->bits() = value; Some(sideleg.bits()) }, /* TODO: does this need legalization? */
    (0x104,  _) => { mie = legalize_sie(mie, mideleg, value); Some(mie.bits()) },
    (0x105,  _) => { Some(set_stvec(value)) },
    (0x106,  _) => { scounteren = legalize_scounteren(scounteren, value); Some(EXTZ(scounteren.bits())) },
    (0x140,  _) => { sscratch = value; Some(sscratch) },
    (0x141,  _) => { Some(set_xret_target(Supervisor, value)) },
    (0x142,  _) => { scause->bits() = value; Some(scause.bits()) },
    (0x143,  _) => { stval = value; Some(stval) },
    (0x144,  _) => { mip = legalize_sip(mip, mideleg, value); Some(mip.bits()) },
    (0x180,  _) => { satp = legalize_satp(cur_Architecture(), satp, value); Some(satp) },

    _           => ext_write_CSR(csr, value)
  };
  match res {
    Some(v) => if   get_config_print_reg()
               then print_reg("CSR " ^ to_str(csr) ^ " <- " ^ BitStr(v) ^ " (input: " ^ BitStr(value) ^ ")"),
    None()  => print_bits("unhandled write to CSR ", csr)
  }
}

function clause execute CSR(csr, rs1, rd, is_imm, op) = {
  let rs1_val : xlenbits = if is_imm then EXTZ(rs1) else X(rs1);
  let isWrite : bool = match op {
    CSRRW  => true,
    _      => if is_imm then unsigned(rs1_val) != 0 else unsigned(rs1) != 0
  };
  if ~ (check_CSR(csr, cur_privilege, isWrite))
  then { handle_illegal(); RETIRE_FAIL }
  else if ~ (ext_check_CSR(csr, cur_privilege, isWrite))
  then { ext_check_CSR_fail(); RETIRE_FAIL }
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
    RETIRE_SUCCESS
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
  <-> csr_mnemonic(op) ^ "i" ^ spc() ^ reg_name(rd)  ^ sep() ^ csr_name_map(csr) ^ sep() ^ hex_bits_5(rs1)
mapping clause assembly = CSR(csr, rs1, rd, false, op)
  <-> csr_mnemonic(op) ^ spc() ^ reg_name(rd) ^ sep() ^ csr_name_map(csr) ^ sep() ^ reg_name(rs1)
