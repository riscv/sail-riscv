#include "common/encoding.h"
#include "common/runtime.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* SPMP test program
 *
 * This test verifies basic SPMP functionality:
 * 1. Enables SPMP via mseccfg.SSPMP
 * 2. Configure SPMP entry to allow access to a region
 * 3. Verify access works/traps as expected
 *
 * It uses the S-mode indirect CSRs (siselect, sireg, sireg2)
 * and spmpswitch registers.
 */

/* SPMP specific definitions */
#define CSR_SPMPSWITCH 0x1F0
#define CSR_SPMPSWITCHH 0x1F1

#define MSECCFG_SSPMP 0x40

#define SPMPCFG_L (1 << 7)
#define SPMPCFG_A_OFF 0
#define SPMPCFG_A_TOR (1 << 3)
#define SPMPCFG_A_NA4 (2 << 3)
#define SPMPCFG_A_NAPOT (3 << 3)
#define SPMPCFG_X (1 << 2)
#define SPMPCFG_W (1 << 1)
#define SPMPCFG_R (1 << 0)
#define SPMPCFG_U (1 << 8)
#define SPMPCFG_SHARED (1 << 9)

#define REGION_SIZE_EXP 16
#define REGION_SIZE (1 << REGION_SIZE_EXP)
__attribute__((aligned(REGION_SIZE))) volatile uint8_t REGION[REGION_SIZE];

/* Helper to read/write specific types of access */
__attribute__((naked)) bool read_succeeds() {
  /* Set up trap handler */
  asm volatile("csrr t0, mtvec;"
               "csrr t1, mscratch;"
               "csrw mscratch, t0;" /* Save mtvec */
               "la t0, 1f;"
               "csrw mtvec, t0;"

               /* Perform load */
               "la a0, REGION;"
               "lbu a0, 0(a0);"

               /* Success */
               "li a0, 1;"
               "csrr t0, mscratch;"
               "csrw mtvec, t0;" /* Restore mtvec */
               "ret;"

               /* Trap handler */
               ".balign 4;"
               "1:"
               "csrr t0, mscratch;"
               "csrw mtvec, t0;" /* Restore mtvec */
               "li a0, 0;"
               "ret;");
}

__attribute__((naked)) bool write_succeeds() {
  asm volatile("csrr t0, mtvec;"
               "csrr t1, mscratch;"
               "csrw mscratch, t0;"
               "la t0, 1f;"
               "csrw mtvec, t0;"

               "la a0, REGION;"
               "sb zero, 0(a0);"

               "li a0, 1;"
               "csrr t0, mscratch;"
               "csrw mtvec, t0;"
               "ret;"

               ".balign 4;"
               "1:"
               "csrr t0, mscratch;"
               "csrw mtvec, t0;"
               "li a0, 0;"
               "ret;");
}

void enable_spmp(void) {
  unsigned long mseccfg = read_csr(mseccfg);
  mseccfg |= MSECCFG_SSPMP;
  write_csr(mseccfg, mseccfg);

  // Set mpmpdeleg to 0 to delegate all entries to SPMP
  write_csr(0x1F2, 0);
}

void configure_spmp_entry(int idx, unsigned long addr, unsigned long cfg) {
  write_csr(siselect, 0x100 + idx);
  write_csr(sireg, addr); /* spmpaddr */
  write_csr(sireg2, cfg); /* spmpcfg */
}

unsigned long read_spmp_cfg(int idx) {
  write_csr(siselect, 0x100 + idx);
  return read_csr(sireg2);
}

void set_spmpswitch(int idx, bool active) {
  unsigned long sw = read_csr(0x1F0); // spmpswitch
  if (active) {
    sw |= (1UL << idx);
  } else {
    sw &= ~(1UL << idx);
  }
  asm volatile("csrw 0x1F0, %0" ::"r"(sw));
}

unsigned long get_napot_addr(unsigned long region_start) {
  unsigned long t = REGION_SIZE_EXP - 3;
  unsigned long mask = (1UL << t) - 1;
  unsigned long base_paddr = (region_start >> 2);
  return base_paddr | mask;
}

/*
 * Try access with specific privilege setup
 * mode: 1 = Supervisor, 0 = User (MPP value)
 * sum: true = allow S-mode to access U-mode memory (if MPP=S)
 */
bool try_access(bool is_write, int mode, bool sum) {
  unsigned long mstatus;
  asm volatile("csrr %0, mstatus" : "=r"(mstatus));

  unsigned long mstatus_test = mstatus;
  mstatus_test &= ~(3UL << 11);                // Clear MPP
  mstatus_test |= ((unsigned long)mode << 11); // Set MPP
  mstatus_test |= (1UL << 17);                 // MPRV = 1
  if (sum) {
    mstatus_test |= (1UL << 18); // SUM = 1
  } else {
    mstatus_test &= ~(1UL << 18); // SUM = 0
  }

  asm volatile("csrw mstatus, %0" : : "r"(mstatus_test));

  bool result;
  if (is_write) {
    result = write_succeeds();
  } else {
    result = read_succeeds();
  }

  // Restore mstatus
  asm volatile("csrw mstatus, %0" : : "r"(mstatus));
  return result;
}

#define S_MODE 1
#define U_MODE 0

// Test Scenario 1: SHARED=0, U=0
// Expected: U-mode DENY, S-mode ALLOW
void test_s_mode_only(unsigned long addr_val) {
  printf("Test Scenario 1: S-mode Only (SHARED=0, U=0)\n");
  unsigned long cfg = SPMPCFG_A_NAPOT | SPMPCFG_R | SPMPCFG_W; // SHARED=0, U=0 implied
  configure_spmp_entry(0, addr_val, cfg);
  asm volatile("sfence.vma");

  // S-mode Access (SUM=0, though irrelevant as it's not U-bit)
  if (try_access(false, S_MODE, false) && try_access(true, S_MODE, false)) {
    printf("  S-mode (R/W): PASS\n");
  } else {
    printf("  S-mode (R/W): FAIL (Should succeed)\n");
  }

  // U-mode Access
  if (!try_access(false, U_MODE, false) && !try_access(true, U_MODE, false)) {
    printf("  U-mode (R/W): PASS (Access Denied)\n");
  } else {
    printf("  U-mode (R/W): FAIL (Access Should be Denied)\n");
  }
}

// Test Scenario 2: SHARED=0, U=1
// Expected: U-mode ALLOW. S-mode: SUM=0 DENY, SUM=1 ALLOW (EnforceNoX)
void test_u_mode_rule(unsigned long addr_val) {
  printf("Test Scenario 2: U-mode Rule (SHARED=0, U=1)\n");
  unsigned long cfg = SPMPCFG_A_NAPOT | SPMPCFG_R | SPMPCFG_W | SPMPCFG_U; // SHARED=0
  configure_spmp_entry(0, addr_val, cfg);
  asm volatile("sfence.vma");

  // U-mode Access
  if (try_access(false, U_MODE, false) && try_access(true, U_MODE, false)) {
    printf("  U-mode (R/W): PASS\n");
  } else {
    printf("  U-mode (R/W): FAIL (Should succeed)\n");
  }

  // S-mode Access, SUM=0
  if (!try_access(false, S_MODE, false) && !try_access(true, S_MODE, false)) {
    printf("  S-mode (SUM=0): PASS (Access Denied)\n");
  } else {
    printf("  S-mode (SUM=0): FAIL (Access Should be Denied)\n");
  }

  // S-mode Access, SUM=1
  if (try_access(false, S_MODE, true) && try_access(true, S_MODE, true)) {
    printf("  S-mode (SUM=1): PASS (Access Allowed)\n");
  } else {
    printf("  S-mode (SUM=1): FAIL (Access Should be Allowed)\n");
  }
}

// Test Scenario 3a: SHARED=1, U=1, RWX=110 (RW-)
// Expected: S-mode RW, U-mode Read-Only (W denied)
void test_shared_region_rw(unsigned long addr_val) {
  printf("Test Scenario 3a: Shared Region (SHARED=1, U=1, RWX=110)\n");
  unsigned long cfg = SPMPCFG_A_NAPOT | SPMPCFG_R | SPMPCFG_W | SPMPCFG_U | SPMPCFG_SHARED;
  configure_spmp_entry(0, addr_val, cfg);
  asm volatile("sfence.vma");

  // S-mode Access (Shared ignores SUM usually, behaves like enforce)
  if (try_access(false, S_MODE, false) && try_access(true, S_MODE, false)) {
    printf("  S-mode (R/W): PASS\n");
  } else {
    printf("  S-mode (R/W): FAIL (Should succeed)\n");
  }

  // U-mode Access
  bool read_ok = try_access(false, U_MODE, false);
  bool write_ok = try_access(true, U_MODE, false);

  if (read_ok && !write_ok) {
    printf("  U-mode: PASS (Read OK, Write Denied)\n");
  } else {
    printf("  U-mode: FAIL (Read=%d, Write=%d, Expected 1, 0)\n", read_ok, write_ok);
  }
}

// Test Scenario 3b: SHARED=1, U=1, RWX=111 (RWX)
// Expected: S-mode RWX, U-mode Execute-Only (R and W denied)
void test_shared_region_rwx(unsigned long addr_val) {
  printf("Test Scenario 3b: Shared Region (SHARED=1, U=1, RWX=111)\n");
  unsigned long cfg = SPMPCFG_A_NAPOT | SPMPCFG_R | SPMPCFG_W | SPMPCFG_X | SPMPCFG_U | SPMPCFG_SHARED;
  configure_spmp_entry(0, addr_val, cfg);
  asm volatile("sfence.vma");

  // S-mode Access
  if (try_access(false, S_MODE, false) && try_access(true, S_MODE, false)) {
    printf("  S-mode (R/W): PASS\n");
  } else {
    printf("  S-mode (R/W): FAIL (Should succeed)\n");
  }

  // U-mode Access (Should fail Load/Store)
  bool read_ok = try_access(false, U_MODE, false);
  bool write_ok = try_access(true, U_MODE, false);

  if (!read_ok && !write_ok) {
    printf("  U-mode: PASS (Read Denied, Write Denied - Exec Only)\n");
  } else {
    printf("  U-mode: FAIL (Read=%d, Write=%d, Expected 0, 0)\n", read_ok, write_ok);
  }
}

int main(void) {
  printf("Starting SPMP Comprehensive Test\n");

  enable_spmp();
  // Activate entry 0
  set_spmpswitch(0, true);

  unsigned long spmpaddr_val = get_napot_addr((unsigned long)REGION);

  test_s_mode_only(spmpaddr_val);
  test_u_mode_rule(spmpaddr_val);
  test_shared_region_rw(spmpaddr_val);
  test_shared_region_rwx(spmpaddr_val);

  printf("SPMP Comprehensive Test Completed\n");
  return 0;
}
