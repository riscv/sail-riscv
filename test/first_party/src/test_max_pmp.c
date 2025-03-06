#include "common/runtime.h"

#include <stdint.h>
#include <stddef.h>

#define PMPCFG_L (0b1 << 7)
#define PMPCFG_NA4 (0b10 << 3)
#define PMPCFG_NAPOT (0b11 << 3)
#define PMPCFG_X (0b1 << 2)
#define PMPCFG_W (0b1 << 1)
#define PMPCFG_R (0b1 << 0)

#define MSTATUS_MPP_MASK (0b11 << 11)
#define MSTATUS_MPRV_MASK (0b1 << 17)

volatile unsigned GLOBAL = 1;

int main()
{
  printf("Testing 0xFF..FF PMP addresses\n");

  uint_xlen_t ones = UINT_XLEN_MAX;

  asm volatile("csrw pmpaddr0, %[ones]" : : [ones] "r"(ones));

  // Set mstatus.MPP and mstatus.MPRV so that loads/stores are
  // done in user mode. If they don't match the pmp then
  // they'll fail.
  uint_xlen_t mpp = MSTATUS_MPP_MASK;
  uint_xlen_t mprv = MSTATUS_MPRV_MASK;
  asm volatile("csrc mstatus, %[mpp];"
               "csrs mstatus, %[mprv];"
               :
               : [mpp] "r"(mpp), [mprv] "r"(mprv));

  uint_xlen_t pmpcfg_napot = PMPCFG_NAPOT | PMPCFG_X | PMPCFG_W | PMPCFG_R;

  asm volatile("csrw pmpcfg0, %[cfg]" : : [cfg] "r"(pmpcfg_napot));

  // Access memory to test loads/stores.
  GLOBAL += 2;
  if (GLOBAL != 3) {
    return 1;
  }
  return 0;
}
