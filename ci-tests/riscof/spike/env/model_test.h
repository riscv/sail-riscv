#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define RVMODEL_HALT                                                           \
  li x1, 1;                                                                    \
  write_tohost:                                                                \
  sw x1, tohost, x3;                                                           \
  j write_tohost;

#define RVMODEL_BOOT

#define RVMODEL_DATA_BEGIN                                                     \
  RVMODEL_DATA_SECTION.align 4;                                                \
  .global begin_signature;                                                     \
  begin_signature:

#define RVMODEL_DATA_END                                                       \
  .align 4;                                                                    \
  .global end_signature;                                                       \
  end_signature:

#define RVMODEL_IO_INIT
#define RVMODEL_IO_WRITE_STR(_R, _STR)
#define RVMODEL_IO_CHECK()
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#define RVMODEL_SET_MSW_INT                                                    \
  li t1, 1;                                                                    \
  li t2, 0x2000000;                                                            \
  sw t1, 0(t2);

#define RVMODEL_CLEAR_MSW_INT                                                  \
  li t2, 0x2000000;                                                            \
  sw x0, 0(t2);

#define RVMODEL_CLEAR_MTIMER_INT
#define RVMODEL_CLEAR_MEXT_INT

#endif
