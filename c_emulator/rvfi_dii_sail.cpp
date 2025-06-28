#include "sail.h"
#include "rvfi_dii.h"

#ifdef __cplusplus
extern "C" {
#endif

unit rvfi_set_inst_data_insn(uint64_t insn)
{
  rvfi_handler::rvfi_set_inst_data_insn(insn);
  return UNIT;
}

unit rvfi_set_inst_data_order(uint64_t order)
{
  rvfi_handler::rvfi_set_inst_data_order(order);
  return UNIT;
}

unit rvfi_set_inst_data_mode(uint8_t mode)
{
  rvfi_handler::rvfi_set_inst_data_mode(mode);
  return UNIT;
}

unit rvfi_set_inst_data_ixl(uint8_t ixl)
{
  rvfi_handler::rvfi_set_inst_data_ixl(ixl);
  return UNIT;
}

uint64_t rvfi_get_insn(unit)
{
  return rvfi_handler::rvfi_get_insn();
}

unit rvfi_set_pc_data_rdata(uint64_t rdata)
{
  rvfi_handler::rvfi_set_pc_data_rdata(rdata);
  return UNIT;
}

unit rvfi_set_pc_data_wdata(uint64_t wdata)
{
  rvfi_handler::rvfi_set_pc_data_wdata(wdata);
  return UNIT;
}

#ifdef __cplusplus
} // extern "C"
#endif
