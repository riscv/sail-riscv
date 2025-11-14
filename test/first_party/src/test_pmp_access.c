// Basic test for PMP read and write access faults from
// various privileges. We use machine mode with mstatus.MPRV/MPP
// rather than actually switching mode for simplicity.
// Execute permission is also not checked because that is tricky.

#include "common/runtime.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PMPCFG_L (0b1 << 7)
#define PMPCFG_NA4 (0b10 << 3)
#define PMPCFG_NAPOT (0b11 << 3)
#define PMPCFG_X (0b1 << 2)
#define PMPCFG_W (0b1 << 1)
#define PMPCFG_R (0b1 << 0)

#define MSTATUS_MPP_MASK (0b11 << 11)
#define MSTATUS_MPP_MACHINE (0b11 << 11)
#define MSTATUS_MPP_SUPERVISOR (0b01 << 11)
#define MSTATUS_MPP_USER (0b00 << 11)
#define MSTATUS_MPRV_MASK (0b1 << 17)

// Support PMP grain up to 4 MB.
#define REGION_SIZE_EXP 26
#define REGION_SIZE (1 << REGION_SIZE_EXP)
__attribute__((aligned(REGION_SIZE))) volatile uint8_t REGION[REGION_SIZE];

enum AccessType {
  Read,
  Write,
};

// Try to read REGION and return true if it succeeds, false if it traps.
// This clobbers the trap handler if there is one.
__attribute__((naked)) bool read_succeeds() {
  // This is a hack, but set mtvec so it will jump to `trap` on a trap. This
  // doesn't check mcause and assumes there's no existing trap handler. It also
  // assumes we are already in machine mode.
  asm volatile(
    // Store mstatus in mscratch. We need to restore it
    // on a trap because it changes MPRV.
    "csrr a0, mstatus;"
    "csrw mscratch, a0;"
    // Set trap handler to 1:
    "la a0, 1f;"
    "csrw mtvec, a0;"
    // Do a load.
    "la a0, REGION;"
    "lbu a0, 0(a0);"
    // Return 1 (true).
    "li a0, 1;"
    "ret;"
    // Trap handler must be 4-byte aligned.
    ".balign 4;"
    "1:"
    // Restore mstatus.
    "csrr a0, mscratch;"
    "csrw mstatus, a0;"
    // Return 0 (false).
    "li a0, 0;"
    "ret;"
  );
}

// Same as read_succeeds but with a store instead.
__attribute__((naked)) bool write_succeeds() {
  asm volatile("csrr a0, mstatus;"
               "csrw mscratch, a0;"
               "la a0, 1f;"
               "csrw mtvec, a0;"
               "la a0, REGION;"
               "sb zero, 0(a0);"
               "li a0, 1;"
               "ret;"
               ".balign 4;"
               "1:"
               "csrr a0, mscratch;"
               "csrw mstatus, a0;"
               "li a0, 0;"
               "ret;");
}

void set_pmp0_access(uint8_t access) {
  // We enable pmpaddr1 with all access, otherwise we will get traps when trying
  // to do loads/stores e.g. to the stack with effective privilege Supervisor or
  // User.

  uint_xlen_t pmpcfg0 = (PMPCFG_NAPOT | access) |                               // pmpaddr0
                        ((PMPCFG_NAPOT | PMPCFG_R | PMPCFG_W | PMPCFG_X) << 8); // pmpaddr1

  asm volatile("csrw pmpcfg0, %[cfg]" : : [cfg] "r"(pmpcfg0));
  // PMP changes require an SFENCE.VMA on any hart that implements
  // page-based virtual memory, even if VM is not currently enabled.
  // (Doesn't actually affect the Sail model.)
  asm volatile("sfence.vma");
}

enum Privilege {
  Machine,
  Supervisor,
  User,
};

void set_effective_privilege(enum Privilege priv) {
  // Set mstatus.MPP and mstatus.MPRV so that loads/stores are
  // done in the specified mode.

  // Clear MPP and set MPRV.
  uint_xlen_t mpp = MSTATUS_MPP_MASK;
  uint_xlen_t mprv = MSTATUS_MPRV_MASK;
  asm volatile("csrc mstatus, %[mpp];"
               "csrs mstatus, %[mprv];"
               :
               : [mpp] "r"(mpp), [mprv] "r"(mprv));

  // Now set MPP to the requested mode.
  switch (priv) {
  case Machine:
    mpp = MSTATUS_MPP_MACHINE;
    break;
  case Supervisor:
    mpp = MSTATUS_MPP_SUPERVISOR;
    break;
  case User:
    mpp = MSTATUS_MPP_USER;
    break;
  }

  asm volatile("csrs mstatus, %[mpp]" : : [mpp] "r"(mpp));
}

int main() {
  // Configure pmpaddr0 to match REGION and pmpaddr1 to match everything.
  uint_xlen_t ones = UINT_XLEN_MAX;
  uint_xlen_t region_pmpaddr = ((uint_xlen_t)(&REGION) >> 2) | ~(ones << (REGION_SIZE_EXP - 3));
  asm volatile("csrw pmpaddr0, %[pmpaddr]" : : [pmpaddr] "r"(region_pmpaddr));
  asm volatile("csrw pmpaddr1, %[pmpaddr]" : : [pmpaddr] "r"(ones));
  // Turn both PMPs off. Recall pmpaddr0 and pmpaddr1 are both configured in
  // pmpcfg0.
  asm volatile("csrw pmpcfg0, zero");

  asm volatile("sfence.vma");

  // Access should succeed in machine mode with all regions OFF.
  if (!read_succeeds() || !write_succeeds()) {
    return 1;
  }

  // So pmp1 gets configured.
  set_pmp0_access(0);

  for (int priv = Machine; priv <= User; ++priv) {
    // All accesses should succeed in machine mode since we don't lock the PMPs.
    bool is_machine = priv == Machine;

    set_effective_privilege(priv);

    set_pmp0_access(PMPCFG_R | PMPCFG_W);
    if (!read_succeeds()) {
      return priv * 6 + 2;
    }
    if (!write_succeeds()) {
      return priv * 6 + 3;
    }

    set_pmp0_access(PMPCFG_R);
    if (!read_succeeds()) {
      return priv * 6 + 4;
    }
    if (write_succeeds() && !is_machine) {
      return priv * 6 + 5;
    }

    // Can't test W but no R since it is reserved.

    set_pmp0_access(0);
    if (read_succeeds() && !is_machine) {
      return priv * 6 + 6;
    }
    if (write_succeeds() && !is_machine) {
      return priv * 6 + 7;
    }
  }

  return 0;
}
