/* CSR access control */

function csrAccess(csr : csreg) -> csrRW = csr[11..10]
function csrPriv(csr : csreg) -> priv_level = csr[9..8]

function is_CSR_defined (csr : csreg, p : Privilege) -> bool =
  match (csr) {
    /* machine mode: informational */
    0xf11 => p == Machine, // mvendorid
    0xf12 => p == Machine, // marchdid
    0xf13 => p == Machine, // mimpid
    0xf14 => p == Machine, // mhartid
    /* machine mode: trap setup */
    0x300 => p == Machine, // mstatus
    0x301 => p == Machine, // misa
    0x302 => p == Machine & (haveSupMode() | haveNExt()), // medeleg
    0x303 => p == Machine & (haveSupMode() | haveNExt()), // mideleg
    0x304 => p == Machine, // mie
    0x305 => p == Machine, // mtvec
    0x306 => p == Machine & haveUsrMode(), // mcounteren
    0x30A => p == Machine & haveUsrMode(), // menvcfg
    0x310 => p == Machine & (sizeof(xlen) == 32), // mstatush
    0x31A => p == Machine & haveUsrMode() & (sizeof(xlen) == 32), // menvcfgh
    0x320 => p == Machine, // mcountinhibit
    /* machine mode: trap handling */
    0x340 => p == Machine, // mscratch
    0x341 => p == Machine, // mepc
    0x342 => p == Machine, // mcause
    0x343 => p == Machine, // mtval
    0x344 => p == Machine, // mip

    0x3A0 => p == Machine,                        // pmpcfg0
    0x3A1 => p == Machine & (sizeof(xlen) == 32), // pmpcfg1
    0x3A2 => p == Machine,                        // pmpcfg2
    0x3A3 => p == Machine & (sizeof(xlen) == 32), // pmpcfg3

    0x3B0 => p == Machine, // pmpaddr0
    0x3B1 => p == Machine, // pmpaddr1
    0x3B2 => p == Machine, // pmpaddr2
    0x3B3 => p == Machine, // pmpaddr3
    0x3B4 => p == Machine, // pmpaddr4
    0x3B5 => p == Machine, // pmpaddr5
    0x3B6 => p == Machine, // pmpaddr6
    0x3B7 => p == Machine, // pmpaddr7
    0x3B8 => p == Machine, // pmpaddr8
    0x3B9 => p == Machine, // pmpaddr9
    0x3BA => p == Machine, // pmpaddrA
    0x3BB => p == Machine, // pmpaddrB
    0x3BC => p == Machine, // pmpaddrC
    0x3BD => p == Machine, // pmpaddrD
    0x3BE => p == Machine, // pmpaddrE
    0x3BF => p == Machine, // pmpaddrF

    /* counters */
    0xB00 => p == Machine, // mcycle
    0xB02 => p == Machine, // minstret

    0xB80 => p == Machine & (sizeof(xlen) == 32), // mcycleh
    0xB82 => p == Machine & (sizeof(xlen) == 32), // minstreth

    /* disabled trigger/debug module */
    0x7a0 => p == Machine,

    /* supervisor mode: trap setup */
    0x100 => haveSupMode() & (p == Machine | p == Supervisor), // sstatus
    0x102 => haveSupMode() & haveNExt() & (p == Machine | p == Supervisor), // sedeleg
    0x103 => haveSupMode() & haveNExt() & (p == Machine | p == Supervisor), // sideleg
    0x104 => haveSupMode() & (p == Machine | p == Supervisor), // sie
    0x105 => haveSupMode() & (p == Machine | p == Supervisor), // stvec
    0x106 => haveSupMode() & (p == Machine | p == Supervisor), // scounteren
    0x10A => haveSupMode() & (p == Machine | p == Supervisor), // senvcfg

    /* supervisor mode: trap handling */
    0x140 => haveSupMode() & (p == Machine | p == Supervisor), // sscratch
    0x141 => haveSupMode() & (p == Machine | p == Supervisor), // sepc
    0x142 => haveSupMode() & (p == Machine | p == Supervisor), // scause
    0x143 => haveSupMode() & (p == Machine | p == Supervisor), // stval
    0x144 => haveSupMode() & (p == Machine | p == Supervisor), // sip

    /* supervisor mode: address translation */
    0x180 => haveSupMode() & (p == Machine | p == Supervisor), // satp

    /* user mode: counters */
    0xC00 => haveUsrMode(),    // cycle
    0xC01 => haveUsrMode(),    // time
    0xC02 => haveUsrMode(),    // instret

    0xC80 => haveUsrMode() & (sizeof(xlen) == 32),     // cycleh
    0xC81 => haveUsrMode() & (sizeof(xlen) == 32),     // timeh
    0xC82 => haveUsrMode() & (sizeof(xlen) == 32),     // instreth

    /* user mode: Zkr */
    0x015 => haveZkr(),

    /* check extensions */
    _     => ext_is_CSR_defined(csr, p)
  }

val check_CSR_access : (csrRW, priv_level, Privilege, Virtualization, bool) -> bool
function check_CSR_access(csrrw, csrpr, p, v, isWrite) = {
  let check_priv: bool = match p { /* privilege */
    Machine => (privLevel_to_bits(Machine) >=_u csrpr),
    Supervisor => match v {
      V0 => (0b10>=_u csrpr), /* hypervisor CSRs (0b10) are accessible in HS-mode */
      V1 => (privLevel_to_bits(Supervisor) >=_u csrpr)},
    User => (privLevel_to_bits(User) >=_u csrpr),
  };
  let check_RW = not(isWrite == true & csrrw == 0b11);  /* read/write */
  check_priv & check_RW
}

function check_TVM_SATP(csr : csreg, p : Privilege, v: Virtualization) -> bool =
  match (p, v) {
    (Supervisor, V0) => not(csr == 0x180 & mstatus.TVM() == 0b1),
    (Supervisor, V1) => not(csr == 0x180 & hstatus.VTVM() == 0b1),
    (_, _)           => true
  }

function check_Counteren(csr : csreg, p : Privilege, v : Virtualization) -> bool =
  match(csr, p, v) {
    (0xC00, Supervisor, V0) => mcounteren.CY() == 0b1,
    (0xC01, Supervisor, V0) => mcounteren.TM() == 0b1,
    (0xC02, Supervisor, V0) => mcounteren.IR() == 0b1,

    (0xC00, Supervisor, V1) => mcounteren.CY() == 0b1 & hcounteren.CY() == 0b1,
    (0xC01, Supervisor, V1) => mcounteren.TM() == 0b1 & hcounteren.TM() == 0b1,
    (0xC02, Supervisor, V1) => mcounteren.IR() == 0b1 & hcounteren.IR() == 0b1,

    (0xC00, User, VO) => mcounteren.CY() == 0b1 & (not(haveSupMode()) | scounteren.CY() == 0b1),
    (0xC01, User, VO) => mcounteren.TM() == 0b1 & (not(haveSupMode()) | scounteren.TM() == 0b1),
    (0xC02, User, VO) => mcounteren.IR() == 0b1 & (not(haveSupMode()) | scounteren.IR() == 0b1),

    // Note: S-mode is always present when H-ext is implemented
    (0xC00, User, V1) => mcounteren.CY() == 0b1 & hcounteren.CY() == 0b1 & scounteren.CY() == 0b1,
    (0xC01, User, V1) => mcounteren.TM() == 0b1 & hcounteren.TM() == 0b1 & scounteren.TM() == 0b1,
    (0xC02, User, V1) => mcounteren.IR() == 0b1 & hcounteren.IR() == 0b1 & scounteren.IR() == 0b1,

    /* no HPM counters for now */
    (_, _, _) => // Note: would be more elegant if matching on ranges was supported
              if   0xC03 <=_u csr & csr <=_u 0xC1F
              then false
              else true
  }


/* Seed may only be accessed if we are doing a write, and access has been
 * allowed in the current priv mode
 */
function check_seed_CSR (csr : csreg, p : Privilege, isWrite : bool) -> bool = {
  if not(csr == 0x015) then {
    true
  } else if not(isWrite) then {
    /* Read-only access to the seed CSR is not allowed */
    false
  } else {
    match (p) {
      Machine => true,
      Supervisor => false, /* TODO: base this on mseccfg */
      User => false, /* TODO: base this on mseccfg */
    }
  }
}

function check_CSR(csr : csreg, p : Privilege, v: Virtualization, isWrite : bool) -> bool =
    is_CSR_defined(csr, p)
  & check_CSR_access(csrAccess(csr), csrPriv(csr), p, v, isWrite)
  & check_TVM_SATP(csr, p, v)
  & check_Counteren(csr, p, v)
  & check_seed_CSR(csr, p, isWrite)
