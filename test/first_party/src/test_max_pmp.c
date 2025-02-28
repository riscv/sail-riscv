#include "common/runtime.h"
#include "common/riscv_int.h"

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

int main()
{
  printf("Testing 0xFF..FF PMP addresses\n");

  __riscv_uint_xlen_t ones = __RISCV_UINT_XLEN_MAX;

  asm volatile("csrw pmpaddr0, %[ones]" : : [ones] "r"(ones));

  // Set mstatus.MPP and mstatus.MPRV so that loads/stores are
  // done in user mode. If they don't match the pmp then
  // they'll fail.
  __riscv_uint_xlen_t mpp = MSTATUS_MPP_MASK;
  __riscv_uint_xlen_t mprv = MSTATUS_MPRV_MASK;
  asm volatile("csrc mstatus, %[mpp];"
               "csrs mstatus, %[mprv];"
               :
               : [mpp] "r"(mpp), [mprv] "r"(mprv));

  __riscv_uint_xlen_t pmpcfg_napot
      = PMPCFG_NAPOT | PMPCFG_X | PMPCFG_W | PMPCFG_R;

  asm volatile("csrw pmpcfg0, %[cfg]" : : [cfg] "r"(pmpcfg_napot));

  // Access memory to test loads/stores.
  printf("Passed\n");
}
