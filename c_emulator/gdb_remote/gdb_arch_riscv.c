#include "riscv_platform.h"
#include "riscv_platform_impl.h"
#include "riscv_sail.h"
#include "gdb_utils.h"
#include "gdb_arch.h"

mach_bits riscv_get_reg(struct rsp_conn *conn, struct sail_arch *arch, uint64_t regno) {
  switch (regno) {
  case 0:
    return 0;

#define case_reg(rno)				\
    case rno:					\
      return zx ## rno				\

  case_reg(1);
  case_reg(2);
  case_reg(3);
  case_reg(4);
  case_reg(5);
  case_reg(6);
  case_reg(7);
  case_reg(8);
  case_reg(9);
  case_reg(10);
  case_reg(11);
  case_reg(12);
  case_reg(13);
  case_reg(14);
  case_reg(15);
  case_reg(16);
  case_reg(17);
  case_reg(18);
  case_reg(19);
  case_reg(20);
  case_reg(21);
  case_reg(22);
  case_reg(23);
  case_reg(24);
  case_reg(25);
  case_reg(26);
  case_reg(27);
  case_reg(28);
  case_reg(29);
  case_reg(30);
  case_reg(31);

#undef case_reg

  default:
    dprintf(conn->log_fd, "unrecognized register number %ld\n", regno);
    conn_exit(conn, 1);
    return 0;
  }
}

void riscv_set_reg(struct rsp_conn *conn, struct sail_arch *arch, uint64_t regno, mach_bits regval) {
  switch (regno) {
  case 0:
    dprintf(conn->log_fd, "ignoring attempt to write $zero\n");
    break;

#define case_reg(reg)                           \
    case reg:                                   \
      zx ## reg = regval;                       \
      break

  case_reg(1);
  case_reg(2);
  case_reg(3);
  case_reg(4);
  case_reg(5);
  case_reg(6);
  case_reg(7);
  case_reg(8);
  case_reg(9);
  case_reg(10);
  case_reg(11);
  case_reg(12);
  case_reg(13);
  case_reg(14);
  case_reg(15);
  case_reg(16);
  case_reg(17);
  case_reg(18);
  case_reg(19);
  case_reg(20);
  case_reg(21);
  case_reg(22);
  case_reg(23);
  case_reg(24);
  case_reg(25);
  case_reg(26);
  case_reg(27);
  case_reg(28);
  case_reg(29);
  case_reg(30);
  case_reg(31);

#undef case_reg

  default:
    dprintf(conn->log_fd, "unrecognized register number %ld\n", regno);
    exit(1);
  }
}

mach_bits riscv_get_pc(struct rsp_conn *conn, struct sail_arch *arch) {
  return zPC;
}

void riscv_set_pc(struct rsp_conn *conn, struct sail_arch *arch, mach_bits regval) {
  zPC = regval;
}

int riscv_step(struct rsp_conn *conn, struct sail_arch *arch) {
  // step at current address
  sail_int sail_step;
  bool stepped;
  CREATE(sail_int)(&sail_step);
  CONVERT_OF(sail_int, mach_int)(&sail_step, conn->model.step_no);
  stepped = zstep(sail_step);
  KILL(sail_int)(&sail_step);
  if (have_exception) {
    dprintf(conn->log_fd, "internal Sail exception, exiting!\n");
    conn_exit(conn, 1);
  }
  if (stepped) conn->model.step_no++;
  return 0;
}

bool riscv_is_done(struct rsp_conn *conn, struct sail_arch *arch) {
  // fixme: we may not have a legal zhtif!
  return zhtif_done;
}

struct sail_arch *get_gdb_riscv_arch() {
  struct sail_arch *arch = (struct sail_arch *)malloc(sizeof(*arch));
  arch->archlen = (zxlen_val == 32) ? ARCH32 : ARCH64; // only RV32 or RV64 for now
  arch->nregs = 32;
  arch->get_reg = riscv_get_reg;
  arch->get_pc  = riscv_get_pc;
  arch->set_reg = riscv_set_reg;
  arch->set_pc  = riscv_set_pc;
  arch->step    = riscv_step;
  arch->is_done = riscv_is_done;
  return arch;
}
