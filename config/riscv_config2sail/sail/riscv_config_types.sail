$include <string.sail>

enum WARL_range_mode = {
  WARL_Unchanged,
  WARL_Nextup,
  WARL_Nextdown,
  WARL_Nearup,
  WARL_Neardown,
  WARL_Largest,
  WARL_Smallest,
  WARL_Addr
}

union WARL_range_entry = {
  WARL_range_value : nat,
  WARL_range_interval : (nat, nat)
}

struct WARL_range = {
  rangelist : list(WARL_range_entry),
  mode : WARL_range_mode
}

struct WARL_bitmask = {
  mask : nat, /* XXX consider using bits('n) */
  default_val : nat
}

union WARL_either = {
  WARL_range : WARL_range,
  WARL_bitmask : WARL_bitmask
}

struct misa_config = {
  implemented : bool,
  MXL         : WARL_range,
  Extensions  : WARL_bitmask
}

struct id_reg_config = {
  implemented : bool,
  id          : nat
}

struct hardwired_config = {
  is_hardwired : bool,
  hardwired_val: nat
}

struct XXL_config = {
  rnge : WARL_range,
  is_hardwired : bool,
  hardwired_mxl : bool
}

struct mstatus_config = {
  XS  : hardwired_config,
  FS  : WARL_range,
  MPP : WARL_range,
  SXL : XXL_config,
  UXL : XXL_config,
  TSR_is_hardwired  : bool,
  TW_is_hardwired   : bool,
  TVM_is_hardwired  : bool,
  MXR_is_hardwired  : bool,
  SUM_is_hardwired  : bool,
  SPP_is_hardwired  : bool,
  MPRV_is_hardwired : bool,
  SPIE_is_hardwired : bool,
  UPIE_is_hardwired : bool,
  SIE_is_hardwired  : bool,
  UIE_is_hardwired  : bool
}

struct tvec_config = {
  base : WARL_range,
  mode : WARL_range
}

struct bitmask_hardwired_config = { /* Should be union? */
  mask : WARL_bitmask,
  is_hardwired : bool,
  hardwired_val : nat
}

struct mhpmcounter_config = {
  is_hardwired : bool,
  hardwired_val : nat
}

struct satp_config = {
  mode : WARL_range,
  asid : WARL_either,
  ppn  : WARL_either
}

struct isa_config = {
  I : bool, /* The base integer ISA (always true because E is not implemented yet) */
  M : bool, /* mul / div*/
  F : bool, /* floating point */
  A : bool, /* atomic memory */
  D : bool, /* double floating point */
  C : bool, /* compressed instructions */
  S : bool, /* supervisor mode */
  U : bool, /* user mode */
  Zicsr : bool, /* control and status registers */
  Zifencei : bool /* instruction fetch fence */
}

struct riscv_isa_config = {
  ISA    : isa_config,
  hw_data_misaligned_support : bool,
  xlen : nat, /* XXX 32, 64, 128 */
  misa : misa_config,
  mvendorid : id_reg_config,
  marchid   : id_reg_config,
  mimpid    : id_reg_config,
  mhartid   : nat,
  mstatus   : mstatus_config,
  mtvec     : tvec_config,
  mideleg   : WARL_bitmask,
  medeleg   : WARL_bitmask,
  mip       : WARL_bitmask,
  mie       : WARL_bitmask,
  mepc      : WARL_either,
  mcountinhibit : WARL_bitmask,
  mcounteren    : bitmask_hardwired_config,
  mcycle        : mhpmcounter_config,
  minstret      : mhpmcounter_config,
  mhpmcounter3  : mhpmcounter_config,
  mhpmcounter4  : mhpmcounter_config,
  mhpmcounter5  : mhpmcounter_config,
  mhpmcounter6  : mhpmcounter_config,
  mhpmcounter7  : mhpmcounter_config,
  mhpmcounter8  : mhpmcounter_config,
  mhpmcounter9  : mhpmcounter_config,
  mhpmcounter10 : mhpmcounter_config,
  mhpmcounter11 : mhpmcounter_config,
  mhpmcounter12 : mhpmcounter_config,
  mhpmcounter13 : mhpmcounter_config,
  mhpmcounter14 : mhpmcounter_config,
  mhpmcounter15 : mhpmcounter_config,
  mhpmcounter16 : mhpmcounter_config,
  mhpmcounter17 : mhpmcounter_config,
  mhpmcounter18 : mhpmcounter_config,
  mhpmcounter19 : mhpmcounter_config,
  mhpmcounter20 : mhpmcounter_config,
  mhpmcounter21 : mhpmcounter_config,
  mhpmcounter22 : mhpmcounter_config,
  mhpmcounter23 : mhpmcounter_config,
  mhpmcounter24 : mhpmcounter_config,
  mhpmcounter25 : mhpmcounter_config,
  mhpmcounter26 : mhpmcounter_config,
  mhpmcounter27 : mhpmcounter_config,
  mhpmcounter28 : mhpmcounter_config,
  mhpmcounter29 : mhpmcounter_config,
  mhpmcounter30 : mhpmcounter_config,
  mhpmcounter31 : mhpmcounter_config,
  stvec         : tvec_config,
  sip           : WARL_bitmask,
  sie           : WARL_bitmask,
  scounteren    : bitmask_hardwired_config,
  sepc          : WARL_either,
  satp          : satp_config
}

union label_address_config = {
  LA_Label : string,
  LA_Address : nat
}

struct address_implemented_config = {
  address : nat,
  implemented : bool
}

struct cause_config = {
  implemented : bool,
  values : list(nat)
}

struct riscv_platform_config = {
  reset : label_address_config,
  nmi   : label_address_config,
  mtime : address_implemented_config,
  mtimecmp : address_implemented_config,
  mcause : cause_config,
  scause : cause_config,
  mhpmevent3  : WARL_either,
  mhpmevent4  : WARL_either,
  mhpmevent5  : WARL_either,
  mhpmevent6  : WARL_either,
  mhpmevent7  : WARL_either,
  mhpmevent8  : WARL_either,
  mhpmevent9  : WARL_either,
  mhpmevent10 : WARL_either,
  mhpmevent11 : WARL_either,
  mhpmevent12 : WARL_either,
  mhpmevent13 : WARL_either,
  mhpmevent14 : WARL_either,
  mhpmevent15 : WARL_either,
  mhpmevent16 : WARL_either,
  mhpmevent17 : WARL_either,
  mhpmevent18 : WARL_either,
  mhpmevent19 : WARL_either,
  mhpmevent20 : WARL_either,
  mhpmevent21 : WARL_either,
  mhpmevent22 : WARL_either,
  mhpmevent23 : WARL_either,
  mhpmevent24 : WARL_either,
  mhpmevent25 : WARL_either,
  mhpmevent26 : WARL_either,
  mhpmevent27 : WARL_either,
  mhpmevent28 : WARL_either,
  mhpmevent29 : WARL_either,
  mhpmevent30 : WARL_either,
  mhpmevent31 : WARL_either
}
