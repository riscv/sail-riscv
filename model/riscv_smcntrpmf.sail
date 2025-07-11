function clause currentlyEnabled(Ext_Smcntrpmf) = hartSupports(Ext_Smcntrpmf) & currentlyEnabled(Ext_Zicntr)

bitfield CountSmcntrpmf : bits(64) = {
  MINH  : 62,
  SINH  : 61,
  UINH  : 60,
  VSINH : 59,
  VUINH : 58,
}

function legalize_smcntrpmf(c : CountSmcntrpmf, value : bits(64)) -> CountSmcntrpmf = {
  let v = Mk_CountSmcntrpmf(value);
  // For each bit in 61:58, if the associated privilege mode is not implemented, the bit is read-only zero.
  [ c with
    MINH  = v[MINH],
    SINH  = if currentlyEnabled(Ext_S) then v[SINH] else 0b0,
    UINH  = if currentlyEnabled(Ext_U) then v[UINH] else 0b0,
    // VSINH = v[VSINH],
    // VUINH = v[VUINH],
  ]
}

register mcyclecfg : CountSmcntrpmf
register minstretcfg : CountSmcntrpmf

mapping clause csr_name_map = 0x321  <-> "mcyclecfg"
mapping clause csr_name_map = 0x721  <-> "mcyclecfgh"
mapping clause csr_name_map = 0x322  <-> "minstretcfg"
mapping clause csr_name_map = 0x722  <-> "minstretcfgh"

function clause is_CSR_accessible(0x321, _, _) = currentlyEnabled(Ext_Smcntrpmf) // mcyclecfg
function clause is_CSR_accessible(0x721, _, _) = currentlyEnabled(Ext_Smcntrpmf) & xlen == 32 // mcyclecfgh
function clause is_CSR_accessible(0x322, _, _) = currentlyEnabled(Ext_Smcntrpmf) // minstretcfg
function clause is_CSR_accessible(0x722, _, _) = currentlyEnabled(Ext_Smcntrpmf) & xlen == 32 // minstretcfgh

function clause read_CSR(0x321) = mcyclecfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x721 if xlen == 32) = mcyclecfg.bits[63 .. 32]
function clause read_CSR(0x322) = minstretcfg.bits[xlen - 1 .. 0]
function clause read_CSR(0x722 if xlen == 32) = minstretcfg.bits[63 .. 32]

function clause write_CSR((0x321, value) if xlen == 64) = { mcyclecfg = legalize_smcntrpmf(mcyclecfg, value); Ok(mcyclecfg.bits) }
function clause write_CSR((0x321, value) if xlen == 32) = { mcyclecfg = legalize_smcntrpmf(mcyclecfg, mcyclecfg.bits[63 .. 32] @ value); Ok(mcyclecfg.bits[xlen - 1 .. 0]) }
function clause write_CSR((0x721, value) if xlen == 32) = { mcyclecfg = legalize_smcntrpmf(mcyclecfg, value @ mcyclecfg.bits[31 .. 0]); Ok(mcyclecfg.bits[63 .. 32]) }
function clause write_CSR((0x322, value) if xlen == 64) = { minstretcfg = legalize_smcntrpmf(minstretcfg, value); Ok(minstretcfg.bits[xlen - 1 .. 0]) }
function clause write_CSR((0x322, value) if xlen == 32) = { minstretcfg = legalize_smcntrpmf(minstretcfg, minstretcfg.bits[63 .. 32] @ value); Ok(minstretcfg.bits[xlen - 1 .. 0]) }
function clause write_CSR((0x722, value) if xlen == 32) = { minstretcfg = legalize_smcntrpmf(minstretcfg, value @ minstretcfg.bits[31 .. 0]); Ok(minstretcfg.bits[63 .. 32]) }

function counter_priv_filter_bit(reg : CountSmcntrpmf, priv : Privilege) -> bits(1) =
  // When all xINH bits are zero, event counting is enabled in all modes.
  match priv {
    Machine    => reg[MINH],
    Supervisor => reg[SINH],
    User       => reg[UINH],
    // TODO: VSINH, VUINH when those modes are defined
  }
