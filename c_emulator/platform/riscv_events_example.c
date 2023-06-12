// Written by: Alexandre Joannou

#include "sail.h"
#include "riscv_sail.h"
#include "riscv_hpmevents_impl.h"

void print_newline()
    {
    printf("\n");
    }

riscv_hpm_event platform_events[] =
  {
   // One entry for each event defined in platform_events.enums, with
   // the second element being the value used in software to select
   // the event when written to the mhpmevent registers.
    { E_event_branch,  3 },
    { E_event_jal,     4 },
    { E_event_jalr,    5 },
    { E_event_auipc,   6 },
    { E_event_load,    7 },
    { E_event_store,   8 },
    { E_event_lr,      9 },
    { E_event_sc,     10 },
    { E_event_amo,    11 },
    { E_event_shift,  12 },
    { E_event_mulDiv, 13 },
    { E_event_fp,     14 },
    { E_event_fence,  18 },
   // This should be the last entry.
   { E_last, 0 },
  };

// We process any platform-specific events here.  This file will
// differ on a per-platform basis.
void signal_platform_events() {
  // For example, extract any instruction related events using
  // zinstruction, which contains the executed instruction in the
  // lower bits, and signal them using riscv_signal_event(), e.g:
  //   riscv_signal_event(E_branch_taken);
  // The event id should be defined in platform_events.enums

  uint64_t inst = zinstruction;
  (void) inst;

  printf("%s, %d, %s: \n", __FILE__, __LINE__, __FUNCTION__);

// rs2 test
#define RS2_IDX 20
#define RS2_MASK 0x01f00000
#define RS2_IS(x, i) ((((x) & RS2_MASK) == (i) << RS2_IDX) ? true : false)
// instruction masks
#define             R_TYPE_MASK 0xfe00707f
#define  R_TYPE_ROUND_MODE_MASK 0xfe00007f
#define            R4_TYPE_MASK 0x0600707f
#define R4_TYPE_ROUND_MODE_MASK 0x0600007f
#define           ISB_TYPE_MASK 0x0000707f
#define            UJ_TYPE_MASK 0x0000007f
// RV32/64I
#define       WHEN_IS_BEQ(x, y) if (((x) & ISB_TYPE_MASK) == 0x00000063) y
#define       WHEN_IS_BNE(x, y) if (((x) & ISB_TYPE_MASK) == 0x00001063) y
#define       WHEN_IS_BLT(x, y) if (((x) & ISB_TYPE_MASK) == 0x00004063) y
#define       WHEN_IS_BGE(x, y) if (((x) & ISB_TYPE_MASK) == 0x00005063) y
#define      WHEN_IS_BLTU(x, y) if (((x) & ISB_TYPE_MASK) == 0x00006063) y
#define      WHEN_IS_BGEU(x, y) if (((x) & ISB_TYPE_MASK) == 0x00007063) y
#define       WHEN_IS_JAL(x, y) if (((x) &  UJ_TYPE_MASK) == 0x0000006f) y
#define      WHEN_IS_JALR(x, y) if (((x) & ISB_TYPE_MASK) == 0x00000067) y
#define     WHEN_IS_AUIPC(x, y) if (((x) &  UJ_TYPE_MASK) == 0x00000017) y
#define        WHEN_IS_LB(x, y) if (((x) & ISB_TYPE_MASK) == 0x00000003) y
#define        WHEN_IS_LH(x, y) if (((x) & ISB_TYPE_MASK) == 0x00001003) y
#define        WHEN_IS_LW(x, y) if (((x) & ISB_TYPE_MASK) == 0x00002003) y
#define        WHEN_IS_LD(x, y) if (((x) & ISB_TYPE_MASK) == 0x00003003) y
#define       WHEN_IS_LBU(x, y) if (((x) & ISB_TYPE_MASK) == 0x00004003) y
#define       WHEN_IS_LHU(x, y) if (((x) & ISB_TYPE_MASK) == 0x00005003) y
#define       WHEN_IS_LWU(x, y) if (((x) & ISB_TYPE_MASK) == 0x00006003) y
#define        WHEN_IS_SB(x, y) if (((x) & ISB_TYPE_MASK) == 0x00000023) y
#define        WHEN_IS_SH(x, y) if (((x) & ISB_TYPE_MASK) == 0x00001023) y
#define        WHEN_IS_SW(x, y) if (((x) & ISB_TYPE_MASK) == 0x00002023) y
#define        WHEN_IS_SD(x, y) if (((x) & ISB_TYPE_MASK) == 0x00003023) y
#define      WHEN_IS_SLLI(x, y) if (((x) &   R_TYPE_MASK) == 0x00001013) y
#define      WHEN_IS_SRLI(x, y) if (((x) &   R_TYPE_MASK) == 0x00005013) y
#define      WHEN_IS_SRAI(x, y) if (((x) &   R_TYPE_MASK) == 0x40005013) y
#define       WHEN_IS_SLL(x, y) if (((x) &   R_TYPE_MASK) == 0x00001033) y
#define       WHEN_IS_SRL(x, y) if (((x) &   R_TYPE_MASK) == 0x00005033) y
#define       WHEN_IS_SRA(x, y) if (((x) &   R_TYPE_MASK) == 0x40005033) y
#define     WHEN_IS_FENCE(x, y) if (((x) & ISB_TYPE_MASK) == 0x0000000f) y
// RV32/64 Zifencei
#define   WHEN_IS_FENCE_I(x, y) if (((x) & ISB_TYPE_MASK) == 0x0000100f) y
// RV32M
#define       WHEN_IS_MUL(x, y) if (((x) &   R_TYPE_MASK) == 0x02000033) y
#define      WHEN_IS_MULH(x, y) if (((x) &   R_TYPE_MASK) == 0x02001033) y
#define    WHEN_IS_MULHSU(x, y) if (((x) &   R_TYPE_MASK) == 0x02002033) y
#define     WHEN_IS_MULHU(x, y) if (((x) &   R_TYPE_MASK) == 0x02003033) y
#define       WHEN_IS_DIV(x, y) if (((x) &   R_TYPE_MASK) == 0x02004033) y
#define      WHEN_IS_DIVU(x, y) if (((x) &   R_TYPE_MASK) == 0x02005033) y
#define       WHEN_IS_REM(x, y) if (((x) &   R_TYPE_MASK) == 0x02006033) y
#define      WHEN_IS_REMU(x, y) if (((x) &   R_TYPE_MASK) == 0x02007033) y
// RV64M
#define      WHEN_IS_MULW(x, y) if (((x) &   R_TYPE_MASK) == 0x0200003b) y
#define      WHEN_IS_DIVW(x, y) if (((x) &   R_TYPE_MASK) == 0x0200403b) y
#define     WHEN_IS_DIVUW(x, y) if (((x) &   R_TYPE_MASK) == 0x0200503b) y
#define      WHEN_IS_REMW(x, y) if (((x) &   R_TYPE_MASK) == 0x0200603b) y
#define     WHEN_IS_REMUW(x, y) if (((x) &   R_TYPE_MASK) == 0x0200703b) y
// RV32A
#define      WHEN_IS_LR_W(x, y) if (((x) &   R_TYPE_MASK) == 0x1000202f && RS2_IS(x, 0)) y
#define      WHEN_IS_SC_W(x, y) if (((x) &   R_TYPE_MASK) == 0x1800202f && RS2_IS(x, 0)) y
#define WHEN_IS_AMOSWAP_W(x, y) if (((x) &   R_TYPE_MASK) == 0x0800202f) y
#define  WHEN_IS_AMOADD_W(x, y) if (((x) &   R_TYPE_MASK) == 0x0000202f) y
#define  WHEN_IS_AMOXOR_W(x, y) if (((x) &   R_TYPE_MASK) == 0x2000202f) y
#define  WHEN_IS_AMOAND_W(x, y) if (((x) &   R_TYPE_MASK) == 0x6000202f) y
#define   WHEN_IS_AMOOR_W(x, y) if (((x) &   R_TYPE_MASK) == 0x4000202f) y
#define  WHEN_IS_AMOMIN_W(x, y) if (((x) &   R_TYPE_MASK) == 0x8000202f) y
#define  WHEN_IS_AMOMAX_W(x, y) if (((x) &   R_TYPE_MASK) == 0xa000202f) y
#define WHEN_IS_AMOMINU_W(x, y) if (((x) &   R_TYPE_MASK) == 0xc000202f) y
#define WHEN_IS_AMOMAXU_W(x, y) if (((x) &   R_TYPE_MASK) == 0xe000202f) y
// RV64A
#define      WHEN_IS_LR_D(x, y) if (((x) &   R_TYPE_MASK) == 0x1000302f) y
#define      WHEN_IS_SC_D(x, y) if (((x) &   R_TYPE_MASK) == 0x1800302f) y
#define WHEN_IS_AMOSWAP_D(x, y) if (((x) &   R_TYPE_MASK) == 0x0800302f) y
#define  WHEN_IS_AMOADD_D(x, y) if (((x) &   R_TYPE_MASK) == 0x0000302f) y
#define  WHEN_IS_AMOXOR_D(x, y) if (((x) &   R_TYPE_MASK) == 0x2000302f) y
#define  WHEN_IS_AMOAND_D(x, y) if (((x) &   R_TYPE_MASK) == 0x6000302f) y
#define   WHEN_IS_AMOOR_D(x, y) if (((x) &   R_TYPE_MASK) == 0x4000302f) y
#define  WHEN_IS_AMOMIN_D(x, y) if (((x) &   R_TYPE_MASK) == 0x8000302f) y
#define  WHEN_IS_AMOMAX_D(x, y) if (((x) &   R_TYPE_MASK) == 0xa000302f) y
#define WHEN_IS_AMOMINU_D(x, y) if (((x) &   R_TYPE_MASK) == 0xc000302f) y
#define WHEN_IS_AMOMAXU_D(x, y) if (((x) &   R_TYPE_MASK) == 0xe000302f) y
// RV32F
#define       WHEN_IS_FLW(x, y) if (((x) & ISB_TYPE_MASK) == 0x00002007) y
#define       WHEN_IS_FSW(x, y) if (((x) & ISB_TYPE_MASK) == 0x00002027) y
#define   WHEN_IS_FMADD_S(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x00000043) y
#define   WHEN_IS_FMSUB_S(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x00000047) y
#define  WHEN_IS_FNMSUB_S(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x0000004b) y
#define  WHEN_IS_FNMADD_S(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x0000004f) y
#define    WHEN_IS_FADD_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x00000053) y
#define    WHEN_IS_FSUB_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x08000053) y
#define    WHEN_IS_FMUL_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x10000053) y
#define    WHEN_IS_FDIV_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x18000053) y
#define   WHEN_IS_FSQRT_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x58000053 && RS2_IS(x, 0)) y
#define   WHEN_IS_FSGNJ_S(x, y) if (((x) &   R_TYPE_MASK) == 0x20000053) y
#define  WHEN_IS_FSGNJN_S(x, y) if (((x) &   R_TYPE_MASK) == 0x20001053) y
#define  WHEN_IS_FSGNJX_S(x, y) if (((x) &   R_TYPE_MASK) == 0x20002053) y
#define    WHEN_IS_FMIN_S(x, y) if (((x) &   R_TYPE_MASK) == 0x28000053) y
#define    WHEN_IS_FMAX_S(x, y) if (((x) &   R_TYPE_MASK) == 0x28001053) y
#define  WHEN_IS_FCVT_W_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc0000053 && RS2_IS(x, 0)) y
#define WHEN_IS_FCVT_WU_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc0000053 && RS2_IS(x, 1)) y
#define   WHEN_IS_FMV_X_W(x, y) if (((x) &   R_TYPE_MASK) == 0xe0000053 && RS2_IS(x, 0)) y
#define     WHEN_IS_FEQ_S(x, y) if (((x) &   R_TYPE_MASK) == 0xa0002053) y
#define     WHEN_IS_FLT_S(x, y) if (((x) &   R_TYPE_MASK) == 0xa0001053) y
#define     WHEN_IS_FLE_S(x, y) if (((x) &   R_TYPE_MASK) == 0xa0000053) y
#define  WHEN_IS_FCLASS_S(x, y) if (((x) &   R_TYPE_MASK) == 0xe0001053) y // rs2 should be 0
#define  WHEN_IS_FCVT_S_W(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd0000053 && RS2_IS(x, 0)) y
#define WHEN_IS_FCVT_S_WU(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd0000053 && RS2_IS(x, 1)) y
#define   WHEN_IS_FMV_W_X(x, y) if (((x) &   R_TYPE_MASK) == 0xf0000053 && RS2_IS(x, 0)) y
// RV64F
#define  WHEN_IS_FCVT_L_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc0000053 && RS2_IS(x, 2)) y
#define WHEN_IS_FCVT_LU_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc0000053 && RS2_IS(x, 3)) y
#define  WHEN_IS_FCVT_S_L(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd0000053 && RS2_IS(x, 2)) y
#define WHEN_IS_FCVT_S_LU(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd0000053 && RS2_IS(x, 3)) y
// RV32D
#define       WHEN_IS_FLD(x, y) if (((x) & ISB_TYPE_MASK) == 0x00003007) y
#define       WHEN_IS_FSD(x, y) if (((x) & ISB_TYPE_MASK) == 0x00003027) y
#define   WHEN_IS_FMADD_D(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x02000043) y
#define   WHEN_IS_FMSUB_D(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x02000047) y
#define  WHEN_IS_FNMSUB_D(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x0200004b) y
#define  WHEN_IS_FNMADD_D(x, y) if (((x) & R4_TYPE_ROUND_MODE_MASK) == 0x0200004f) y
#define    WHEN_IS_FADD_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x02000053) y
#define    WHEN_IS_FSUB_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x0a000053) y
#define    WHEN_IS_FMUL_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x12000053) y
#define    WHEN_IS_FDIV_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x1a000053) y
#define   WHEN_IS_FSQRT_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x5a000053 && RS2_IS(x, 0)) y
#define   WHEN_IS_FSGNJ_D(x, y) if (((x) &   R_TYPE_MASK) == 0x22000053) y
#define  WHEN_IS_FSGNJN_D(x, y) if (((x) &   R_TYPE_MASK) == 0x22001053) y
#define  WHEN_IS_FSGNJX_D(x, y) if (((x) &   R_TYPE_MASK) == 0x22002053) y
#define    WHEN_IS_FMIN_D(x, y) if (((x) &   R_TYPE_MASK) == 0x2a000053) y
#define    WHEN_IS_FMAX_D(x, y) if (((x) &   R_TYPE_MASK) == 0x2a001053) y
#define  WHEN_IS_FCVT_S_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x40000053 && RS2_IS(x, 1)) y
#define  WHEN_IS_FCVT_D_S(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0x42000053 && RS2_IS(x, 0)) y
#define     WHEN_IS_FEQ_D(x, y) if (((x) &   R_TYPE_MASK) == 0xa2002053) y
#define     WHEN_IS_FLT_D(x, y) if (((x) &   R_TYPE_MASK) == 0xa2001053) y
#define     WHEN_IS_FLE_D(x, y) if (((x) &   R_TYPE_MASK) == 0xa2000053) y
#define  WHEN_IS_FCLASS_D(x, y) if (((x) &   R_TYPE_MASK) == 0xe2001053) y // rs2 should be 0
#define  WHEN_IS_FCVT_W_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc2000053 && RS2_IS(x, 0)) y
#define WHEN_IS_FCVT_WU_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc2000053 && RS2_IS(x, 1)) y
#define  WHEN_IS_FCVT_D_W(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd2000053 && RS2_IS(x, 0)) y
#define WHEN_IS_FCVT_D_WU(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd2000053 && RS2_IS(x, 1)) y
// RV64D
#define  WHEN_IS_FCVT_L_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc2000053 && RS2_IS(x, 2)) y
#define WHEN_IS_FCVT_LU_D(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xc2000053 && RS2_IS(x, 3)) y
#define   WHEN_IS_FMV_X_D(x, y) if (((x) &   R_TYPE_MASK) == 0xe2000053) y // rs2 should be 0
#define  WHEN_IS_FCVT_D_L(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd2000053 && RS2_IS(x, 2)) y
#define WHEN_IS_FCVT_D_LU(x, y) if (((x) &  R_TYPE_ROUND_MODE_MASK) == 0xd2000053 && RS2_IS(x, 3)) y
#define   WHEN_IS_FMV_D_X(x, y) if (((x) &   R_TYPE_MASK) == 0xf2000053) y // rs2 should be 0

  // RV32/64I
  WHEN_IS_BEQ       (inst, {riscv_signal_event(E_event_branch); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_BNE       (inst, {riscv_signal_event(E_event_branch); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_BLT       (inst, {riscv_signal_event(E_event_branch); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_BGE       (inst, {riscv_signal_event(E_event_branch); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_BLTU      (inst, {riscv_signal_event(E_event_branch); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_BGEU      (inst, {riscv_signal_event(E_event_branch); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_JAL       (inst, {riscv_signal_event(E_event_jal); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_JALR      (inst, {riscv_signal_event(E_event_jalr); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AUIPC     (inst, {riscv_signal_event(E_event_auipc); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_LB        (inst, {riscv_signal_event(E_event_load); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_LH        (inst, {riscv_signal_event(E_event_load); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_LW        (inst, {riscv_signal_event(E_event_load); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_LD        (inst, {riscv_signal_event(E_event_load); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_LBU       (inst, {riscv_signal_event(E_event_load); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_LHU       (inst, {riscv_signal_event(E_event_load); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_LWU       (inst, {riscv_signal_event(E_event_load); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SB        (inst, {riscv_signal_event(E_event_store); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SH        (inst, {riscv_signal_event(E_event_store); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SW        (inst, {riscv_signal_event(E_event_store); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SD        (inst, {riscv_signal_event(E_event_store); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SLLI      (inst, {riscv_signal_event(E_event_shift); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SRLI      (inst, {riscv_signal_event(E_event_shift); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SRAI      (inst, {riscv_signal_event(E_event_shift); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SLL       (inst, {riscv_signal_event(E_event_shift); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SRL       (inst, {riscv_signal_event(E_event_shift); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_SRA       (inst, {riscv_signal_event(E_event_shift); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FENCE     (inst, {riscv_signal_event(E_event_fence); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV32/64 Zifencei
  WHEN_IS_FENCE_I   (inst, {riscv_signal_event(E_event_fence); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV32M
  WHEN_IS_MUL       (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_MULH      (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_MULHSU    (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_MULHU     (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_DIV       (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_DIVU      (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_REM       (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_REMU      (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV64M
  WHEN_IS_MULW      (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_DIVW      (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_DIVUW     (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_REMW      (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_REMUW     (inst, {riscv_signal_event(E_event_mulDiv); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV32A
  WHEN_IS_LR_W      (inst, {riscv_signal_event(E_event_lr);
                            riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();}); // XXX should it also count as a load?
  WHEN_IS_SC_W      (inst, {riscv_signal_event(E_event_sc);
                            riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();}); // XXX should it also count as a store upon success?
  WHEN_IS_AMOSWAP_W (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOADD_W  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOXOR_W  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOAND_W  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOOR_W   (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMIN_W  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMAX_W  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMINU_W (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMAXU_W (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV64A
  WHEN_IS_LR_D      (inst, {riscv_signal_event(E_event_lr);
                            riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();}); // XXX should it also count as a load?
  WHEN_IS_SC_D      (inst, {riscv_signal_event(E_event_sc);
                            riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();}); // XXX should it also count as a store upon success?
  WHEN_IS_AMOSWAP_D (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOADD_D  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOXOR_D  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOAND_D  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOOR_D   (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMIN_D  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMAX_D  (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMINU_D (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_AMOMAXU_D (inst, {riscv_signal_event(E_event_amo); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV32F
  WHEN_IS_FLW       (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSW       (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMADD_S   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMSUB_S   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FNMSUB_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FNMADD_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FADD_S    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSUB_S    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMUL_S    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FDIV_S    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSQRT_S   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSGNJ_S   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSGNJN_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSGNJX_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMIN_S    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMAX_S    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_W_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_WU_S (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMV_X_W   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FEQ_S     (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FLT_S     (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FLE_S     (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCLASS_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_S_W  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_S_WU (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMV_W_X   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV64
  WHEN_IS_FCVT_L_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_LU_S (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_S_L  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_S_LU (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV32
  WHEN_IS_FLD       (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSD       (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMADD_D   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMSUB_D   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FNMSUB_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FNMADD_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FADD_D    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSUB_D    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMUL_D    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FDIV_D    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSQRT_D   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSGNJ_D   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSGNJN_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FSGNJX_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMIN_D    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMAX_D    (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_S_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_D_S  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FEQ_D     (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FLT_D     (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FLE_D     (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCLASS_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_W_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_WU_D (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_D_W  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_D_WU (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  // RV64D
  WHEN_IS_FCVT_L_D  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_LU_D (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMV_X_D   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_D_L  (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FCVT_D_LU (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
  WHEN_IS_FMV_D_X   (inst, {riscv_signal_event(E_event_fp); printf("%s, %d:", __FILE__, __LINE__); print_newline();});
}
