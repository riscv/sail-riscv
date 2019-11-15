let isa_config : riscv_isa_config = struct {
  ISA = struct {
    I = true, 
    M = true, 
    F = false, 
    A = true, 
    D = false, 
    C = true, 
    S = true, 
    U = true, 
    Zicsr = true, 
    Zifencei = true
  } : isa_config, 
  hw_data_misaligned_support = false, 
  xlen = 64, 
  misa = struct {
    implemented = true, 
    MXL = struct {
      rangelist = [|WARL_range_value(2)|], 
      mode = WARL_Unchanged
    } : WARL_range, 
    Extensions = struct {
      mask = 4, 
      default_val = 34869505
    } : WARL_bitmask
  } : misa_config, 
  mvendorid = struct {
    implemented = true, 
    id = 5658198
  } : id_reg_config, 
  marchid = struct {
    implemented = true, 
    id = 5675157
  } : id_reg_config, 
  mimpid = struct {
    implemented = true, 
    id = 9991522
  } : id_reg_config, 
  mhartid = 6723988, 
  mstatus = struct {
    XS = struct {
      is_hardwired = false, 
      hardwired_val = 0
    } : hardwired_config, 
    FS = struct {
      rangelist = [|WARL_range_interval((0, 3))|], 
      mode = WARL_Unchanged
    } : WARL_range, 
    MPP = struct {
      rangelist = [|WARL_range_interval((0, 1)), WARL_range_value(3)|], 
      mode = WARL_Nextdown
    } : WARL_range, 
    SXL = struct {
      rnge = struct {
        rangelist = [|WARL_range_interval((1, 2))|], 
        mode = WARL_Unchanged
      } : WARL_range, 
      is_hardwired = false, 
      hardwired_mxl = true
    } : XXL_config, 
    UXL = struct {
      rnge = struct {
        rangelist = [|WARL_range_value(1)|], 
        mode = WARL_Unchanged
      } : WARL_range, 
      is_hardwired = false, 
      hardwired_mxl = true
    } : XXL_config, 
    TSR_is_hardwired = false, 
    TW_is_hardwired = false, 
    TVM_is_hardwired = false, 
    MXR_is_hardwired = false, 
    SUM_is_hardwired = false, 
    SPP_is_hardwired = false, 
    MPRV_is_hardwired = false, 
    SPIE_is_hardwired = false, 
    UPIE_is_hardwired = false, 
    SIE_is_hardwired = false, 
    UIE_is_hardwired = false
  } : mstatus_config, 
  mtvec = struct {
    base = struct {
      rangelist = [|WARL_range_interval((0, 4611686018427387903))|], 
      mode = WARL_Addr
    } : WARL_range, 
    mode = struct {
      rangelist = [|WARL_range_interval((0, 1))|], 
      mode = WARL_Unchanged
    } : WARL_range
  } : tvec_config, 
  mideleg = struct {
    mask = 18442521949058891775, 
    default_val = 0
  } : WARL_bitmask, 
  medeleg = struct {
    mask = 18446744073709549567, 
    default_val = 0
  } : WARL_bitmask, 
  mip = struct {
    mask = 17847765323269275647, 
    default_val = 0
  } : WARL_bitmask, 
  mie = struct {
    mask = 17847765323269275647, 
    default_val = 0
  } : WARL_bitmask, 
  mepc = WARL_range(struct {
    rangelist = [|WARL_range_interval((0, 18446744073709551615))|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mcountinhibit = struct {
    mask = 31, 
    default_val = 0
  } : WARL_bitmask, 
  mcounteren = struct {
    mask = struct {
      mask = 31, 
      default_val = 0
    } : WARL_bitmask, 
    is_hardwired = false, 
    hardwired_val = 0
  } : bitmask_hardwired_config, 
  mcycle = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  minstret = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter3 = struct {
    is_hardwired = false, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter4 = struct {
    is_hardwired = false, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter5 = struct {
    is_hardwired = false, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter6 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter7 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter8 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter9 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter10 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter11 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter12 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter13 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter14 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter15 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter16 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter17 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter18 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter19 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter20 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter21 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter22 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter23 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter24 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter25 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter26 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter27 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter28 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter29 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter30 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  mhpmcounter31 = struct {
    is_hardwired = true, 
    hardwired_val = 0
  } : mhpmcounter_config, 
  stvec = struct {
    base = struct {
      rangelist = [|WARL_range_interval((0, 1073741823))|], 
      mode = WARL_Unchanged
    } : WARL_range, 
    mode = struct {
      rangelist = [|WARL_range_value(0)|], 
      mode = WARL_Unchanged
    } : WARL_range
  } : tvec_config, 
  sip = struct {
    mask = 17847765323269275647, 
    default_val = 0
  } : WARL_bitmask, 
  sie = struct {
    mask = 17847765323269275647, 
    default_val = 0
  } : WARL_bitmask, 
  scounteren = struct {
    mask = struct {
      mask = 31, 
      default_val = 0
    } : WARL_bitmask, 
    is_hardwired = false, 
    hardwired_val = 0
  } : bitmask_hardwired_config, 
  sepc = WARL_range(struct {
    rangelist = [|WARL_range_interval((0, 18446744073709551615))|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  satp = struct {
    mode = struct {
      rangelist = [|WARL_range_value(0), WARL_range_value(8)|], 
      mode = WARL_Unchanged
    } : WARL_range, 
    asid = WARL_bitmask(struct {
      mask = 511, 
      default_val = 0
    } : WARL_bitmask), 
    ppn = WARL_bitmask(struct {
      mask = 17592186044415, 
      default_val = 0
    } : WARL_bitmask)
  } : satp_config
} : riscv_isa_config
let platform_config : riscv_platform_config = struct {
  reset = LA_Address(16384), 
  nmi = LA_Address(12288), 
  mtime = struct {
    address = 20480, 
    implemented = true
  } : address_implemented_config, 
  mtimecmp = struct {
    address = 20488, 
    implemented = true
  } : address_implemented_config, 
  mcause = struct {
    implemented = true, 
    values = [|16, 17, 18, 19, 20, 21|]
  } : cause_config, 
  scause = struct {
    implemented = true, 
    values = [|16, 17, 18, 19, 20, 21|]
  } : cause_config, 
  mhpmevent3 = WARL_bitmask(struct {
    mask = 252, 
    default_val = 0
  } : WARL_bitmask), 
  mhpmevent4 = WARL_range(struct {
    rangelist = [|WARL_range_interval((256, 18446744073709551360))|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent5 = WARL_range(struct {
    rangelist = [|WARL_range_value(0), WARL_range_value(2)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent6 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent7 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent8 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent9 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent10 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent11 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent12 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent13 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent14 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent15 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent16 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent17 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent18 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent19 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent20 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent21 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent22 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent23 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent24 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent25 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent26 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent27 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent28 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent29 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent30 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range), 
  mhpmevent31 = WARL_range(struct {
    rangelist = [|WARL_range_value(0)|], 
    mode = WARL_Unchanged
  } : WARL_range)
} : riscv_platform_config
