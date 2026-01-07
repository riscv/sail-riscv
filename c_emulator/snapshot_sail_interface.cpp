#include "snapshot_sail_interface.h"

#include <cstring>
#include <stdexcept>

#include "sail.h"
#include "sail_riscv_model.h"

namespace snapshot {

// Helper to create sbits from uint64_t
static sbits create_sbits(uint64_t value) {
  sbits result;
  result.bits = value;
  result.len = 64;  // Assume 64-bit for now (xlen)
  return result;
}

// Helper to get uint64_t from sbits
static uint64_t get_sbits_value(const sbits &sb) {
  return sb.bits;
}

PCState get_pc(hart::Model &model) {
  PCState result;
  result.pc = get_sbits_value(model.zPC);
  result.next_pc = get_sbits_value(model.znextPC);
  return result;
}

void set_pc(hart::Model &model, uint64_t pc_val, uint64_t next_pc_val) {
  model.zPC.bits = pc_val;
  model.zPC.len = 64;
  model.znextPC.bits = next_pc_val;
  model.znextPC.len = 64;
}

std::vector<uint64_t> get_xregs(hart::Model &model) {
  std::vector<uint64_t> regs(32, 0);
  regs[0] = 0;  // x0 is always zero
  regs[1] = get_sbits_value(model.zx1);
  regs[2] = get_sbits_value(model.zx2);
  regs[3] = get_sbits_value(model.zx3);
  regs[4] = get_sbits_value(model.zx4);
  regs[5] = get_sbits_value(model.zx5);
  regs[6] = get_sbits_value(model.zx6);
  regs[7] = get_sbits_value(model.zx7);
  regs[8] = get_sbits_value(model.zx8);
  regs[9] = get_sbits_value(model.zx9);
  regs[10] = get_sbits_value(model.zx10);
  regs[11] = get_sbits_value(model.zx11);
  regs[12] = get_sbits_value(model.zx12);
  regs[13] = get_sbits_value(model.zx13);
  regs[14] = get_sbits_value(model.zx14);
  regs[15] = get_sbits_value(model.zx15);
  regs[16] = get_sbits_value(model.zx16);
  regs[17] = get_sbits_value(model.zx17);
  regs[18] = get_sbits_value(model.zx18);
  regs[19] = get_sbits_value(model.zx19);
  regs[20] = get_sbits_value(model.zx20);
  regs[21] = get_sbits_value(model.zx21);
  regs[22] = get_sbits_value(model.zx22);
  regs[23] = get_sbits_value(model.zx23);
  regs[24] = get_sbits_value(model.zx24);
  regs[25] = get_sbits_value(model.zx25);
  regs[26] = get_sbits_value(model.zx26);
  regs[27] = get_sbits_value(model.zx27);
  regs[28] = get_sbits_value(model.zx28);
  regs[29] = get_sbits_value(model.zx29);
  regs[30] = get_sbits_value(model.zx30);
  regs[31] = get_sbits_value(model.zx31);
  return regs;
}

void set_xregs(hart::Model &model, const std::vector<uint64_t> &regs) {
  if (regs.size() != 32) {
    return;
  }

  // x0 is always zero, skip it
  model.zx1.bits = regs[1]; model.zx1.len = 64;
  model.zx2.bits = regs[2]; model.zx2.len = 64;
  model.zx3.bits = regs[3]; model.zx3.len = 64;
  model.zx4.bits = regs[4]; model.zx4.len = 64;
  model.zx5.bits = regs[5]; model.zx5.len = 64;
  model.zx6.bits = regs[6]; model.zx6.len = 64;
  model.zx7.bits = regs[7]; model.zx7.len = 64;
  model.zx8.bits = regs[8]; model.zx8.len = 64;
  model.zx9.bits = regs[9]; model.zx9.len = 64;
  model.zx10.bits = regs[10]; model.zx10.len = 64;
  model.zx11.bits = regs[11]; model.zx11.len = 64;
  model.zx12.bits = regs[12]; model.zx12.len = 64;
  model.zx13.bits = regs[13]; model.zx13.len = 64;
  model.zx14.bits = regs[14]; model.zx14.len = 64;
  model.zx15.bits = regs[15]; model.zx15.len = 64;
  model.zx16.bits = regs[16]; model.zx16.len = 64;
  model.zx17.bits = regs[17]; model.zx17.len = 64;
  model.zx18.bits = regs[18]; model.zx18.len = 64;
  model.zx19.bits = regs[19]; model.zx19.len = 64;
  model.zx20.bits = regs[20]; model.zx20.len = 64;
  model.zx21.bits = regs[21]; model.zx21.len = 64;
  model.zx22.bits = regs[22]; model.zx22.len = 64;
  model.zx23.bits = regs[23]; model.zx23.len = 64;
  model.zx24.bits = regs[24]; model.zx24.len = 64;
  model.zx25.bits = regs[25]; model.zx25.len = 64;
  model.zx26.bits = regs[26]; model.zx26.len = 64;
  model.zx27.bits = regs[27]; model.zx27.len = 64;
  model.zx28.bits = regs[28]; model.zx28.len = 64;
  model.zx29.bits = regs[29]; model.zx29.len = 64;
  model.zx30.bits = regs[30]; model.zx30.len = 64;
  model.zx31.bits = regs[31]; model.zx31.len = 64;
}

std::vector<uint64_t> get_fregs(hart::Model &model) {
  std::vector<uint64_t> regs(32, 0);
  regs[0] = get_sbits_value(model.zf0);
  regs[1] = get_sbits_value(model.zf1);
  regs[2] = get_sbits_value(model.zf2);
  regs[3] = get_sbits_value(model.zf3);
  regs[4] = get_sbits_value(model.zf4);
  regs[5] = get_sbits_value(model.zf5);
  regs[6] = get_sbits_value(model.zf6);
  regs[7] = get_sbits_value(model.zf7);
  regs[8] = get_sbits_value(model.zf8);
  regs[9] = get_sbits_value(model.zf9);
  regs[10] = get_sbits_value(model.zf10);
  regs[11] = get_sbits_value(model.zf11);
  regs[12] = get_sbits_value(model.zf12);
  regs[13] = get_sbits_value(model.zf13);
  regs[14] = get_sbits_value(model.zf14);
  regs[15] = get_sbits_value(model.zf15);
  regs[16] = get_sbits_value(model.zf16);
  regs[17] = get_sbits_value(model.zf17);
  regs[18] = get_sbits_value(model.zf18);
  regs[19] = get_sbits_value(model.zf19);
  regs[20] = get_sbits_value(model.zf20);
  regs[21] = get_sbits_value(model.zf21);
  regs[22] = get_sbits_value(model.zf22);
  regs[23] = get_sbits_value(model.zf23);
  regs[24] = get_sbits_value(model.zf24);
  regs[25] = get_sbits_value(model.zf25);
  regs[26] = get_sbits_value(model.zf26);
  regs[27] = get_sbits_value(model.zf27);
  regs[28] = get_sbits_value(model.zf28);
  regs[29] = get_sbits_value(model.zf29);
  regs[30] = get_sbits_value(model.zf30);
  regs[31] = get_sbits_value(model.zf31);
  return regs;
}

void set_fregs(hart::Model &model, const std::vector<uint64_t> &regs) {
  if (regs.size() != 32) {
    return;
  }
  model.zf0.bits = regs[0]; model.zf0.len = 64;
  model.zf1.bits = regs[1]; model.zf1.len = 64;
  model.zf2.bits = regs[2]; model.zf2.len = 64;
  model.zf3.bits = regs[3]; model.zf3.len = 64;
  model.zf4.bits = regs[4]; model.zf4.len = 64;
  model.zf5.bits = regs[5]; model.zf5.len = 64;
  model.zf6.bits = regs[6]; model.zf6.len = 64;
  model.zf7.bits = regs[7]; model.zf7.len = 64;
  model.zf8.bits = regs[8]; model.zf8.len = 64;
  model.zf9.bits = regs[9]; model.zf9.len = 64;
  model.zf10.bits = regs[10]; model.zf10.len = 64;
  model.zf11.bits = regs[11]; model.zf11.len = 64;
  model.zf12.bits = regs[12]; model.zf12.len = 64;
  model.zf13.bits = regs[13]; model.zf13.len = 64;
  model.zf14.bits = regs[14]; model.zf14.len = 64;
  model.zf15.bits = regs[15]; model.zf15.len = 64;
  model.zf16.bits = regs[16]; model.zf16.len = 64;
  model.zf17.bits = regs[17]; model.zf17.len = 64;
  model.zf18.bits = regs[18]; model.zf18.len = 64;
  model.zf19.bits = regs[19]; model.zf19.len = 64;
  model.zf20.bits = regs[20]; model.zf20.len = 64;
  model.zf21.bits = regs[21]; model.zf21.len = 64;
  model.zf22.bits = regs[22]; model.zf22.len = 64;
  model.zf23.bits = regs[23]; model.zf23.len = 64;
  model.zf24.bits = regs[24]; model.zf24.len = 64;
  model.zf25.bits = regs[25]; model.zf25.len = 64;
  model.zf26.bits = regs[26]; model.zf26.len = 64;
  model.zf27.bits = regs[27]; model.zf27.len = 64;
  model.zf28.bits = regs[28]; model.zf28.len = 64;
  model.zf29.bits = regs[29]; model.zf29.len = 64;
  model.zf30.bits = regs[30]; model.zf30.len = 64;
  model.zf31.bits = regs[31]; model.zf31.len = 64;
}

std::vector<std::vector<uint8_t>> get_vregs(hart::Model &model) {
  std::vector<std::vector<uint8_t>> regs(32);
  // Vector register support is complex (lbits uses GMP for arbitrary precision)
  // For now, return empty vectors - this can be implemented later
  // TODO: Implement proper lbits to byte vector conversion using GMP functions
  (void)model;  // Suppress unused parameter warning
  return regs;
}

void set_vregs(hart::Model &model, const std::vector<std::vector<uint8_t>> &regs) {
  if (regs.size() != 32) {
    return;
  }
  // Vector register support is complex (lbits uses GMP for arbitrary precision)
  // For now, do nothing - this can be implemented later
  // TODO: Implement proper byte vector to lbits conversion using GMP functions
  (void)model;
  (void)regs;
}

std::map<uint16_t, uint64_t> get_csrs(hart::Model &model) {
  std::map<uint16_t, uint64_t> csrs;

  // Capture key CSRs by accessing model members directly
  // This is safer than using zread_CSR() which can crash for non-existent CSRs
  
  // Machine-mode CSRs (0x3xx range)
  // mstatus (0x300) - stored as struct zMstatus with .zbits field
  csrs[0x300] = model.zmstatus.zbits;
  
  // misa (0x301) - stored as struct zMisa with .zbits field
  csrs[0x301] = get_sbits_value(model.zmisa.zbits);
  
  // medeleg (0x302) - stored as struct zMedeleg with .zbits field (uint64_t)
  csrs[0x302] = model.zmedeleg.zbits;
  
  // mideleg (0x303) - stored as struct zMinterrupts with .zbits field
  csrs[0x303] = get_sbits_value(model.zmideleg.zbits);
  
  // mie (0x304) - stored as struct zMinterrupts with .zbits field
  csrs[0x304] = get_sbits_value(model.zmie.zbits);
  
  // mtvec (0x305) - stored as struct zMtvec with .zbits field
  csrs[0x305] = get_sbits_value(model.zmtvec.zbits);
  
  // mscratch (0x340)
  csrs[0x340] = get_sbits_value(model.zmscratch);
  
  // mepc (0x341)
  csrs[0x341] = get_sbits_value(model.zmepc);
  
  // mcause (0x342) - stored as struct zMcause with .zbits field
  csrs[0x342] = get_sbits_value(model.zmcause.zbits);
  
  // mtval (0x343)
  csrs[0x343] = get_sbits_value(model.zmtval);
  
  // mip (0x344) - stored as struct zMinterrupts with .zbits field
  csrs[0x344] = get_sbits_value(model.zmip.zbits);
  
  // Machine information CSRs (0xfxx range)
  // mvendorid (0xf11)
  csrs[0xf11] = model.zmvendorid;
  
  // marchid (0xf12)
  csrs[0xf12] = get_sbits_value(model.zmarchid);
  
  // mimpid (0xf13)
  csrs[0xf13] = get_sbits_value(model.zmimpid);
  
  // mhartid (0xf14)
  csrs[0xf14] = get_sbits_value(model.zmhartid);
  
  // mconfigptr (0xf15)
  csrs[0xf15] = get_sbits_value(model.zmconfigptr);
  
  // Machine counters (0xbxx range)
  // mcycle (0xb00)
  csrs[0xb00] = model.zmcycle;
  
  // minstret (0xb02)
  csrs[0xb02] = model.zminstret;
  
  // mtime (platform timer, not a standard CSR but important state)
  // Stored as zmtime (uint64_t)
  
  return csrs;
}

void set_csr(hart::Model &model, uint16_t addr, uint64_t value) {
  sbits csr_value;
  csr_value.bits = value;
  csr_value.len = 64;

  struct hart::zresultzIbzCuzK result;
  model.zwrite_CSR(&result, addr, csr_value);
  
  // Check if write succeeded
  if (result.kind != hart::Kind_zOkzIbzCuzK) {
    // Write failed, but we continue anyway
    // In a full implementation, we might want to log this
  }
}

std::string get_cur_privilege(hart::Model &model) {
  switch (model.zcur_privilege) {
    case hart::zMachine: return "Machine";
    case hart::zSupervisor: return "Supervisor";
    case hart::zUser: return "User";
    case hart::zVirtualUser: return "VirtualUser";
    case hart::zVirtualSupervisor: return "VirtualSupervisor";
    default: return "Unknown";
  }
}

std::string get_hart_state(hart::Model &model) {
  // Access hart state from model
  // The hart state is stored in model.zhart_state
  // For now, return a basic state - this can be expanded based on actual hart_state structure
  return "HART_ACTIVE";
}

} // namespace snapshot

