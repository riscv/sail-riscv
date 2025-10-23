#include <optional>
#include "rvfi_dii.h"
#include "rvfi_dii_sail.h"

std::optional<rvfi_handler> rvfi;

unit rvfi_set_inst_data_insn(uint64_t insn)
{
  if (rvfi.has_value()) {
    rvfi->rvfi_set_inst_data_insn(insn);
  }
  return UNIT;
}

unit rvfi_set_inst_data_order(uint64_t order)
{
  if (rvfi.has_value()) {
    rvfi->rvfi_set_inst_data_order(order);
  }
  return UNIT;
}

unit rvfi_set_inst_data_mode(uint8_t mode)
{
  if (rvfi.has_value()) {
    rvfi->rvfi_set_inst_data_mode(mode);
  }
  return UNIT;
}

unit rvfi_set_inst_data_ixl(uint8_t ixl)
{
  if (rvfi.has_value()) {
    rvfi->rvfi_set_inst_data_ixl(ixl);
  }
  return UNIT;
}

uint32_t rvfi_get_insn(unit)
{
  if (rvfi.has_value()) {
    return rvfi->rvfi_get_insn();
  } else {
    fprintf(stderr,
            "Calling rvfi_get_insn is invalid when RVFI is not enabled!\n");
    exit(EXIT_FAILURE);
  }
}

unit rvfi_set_pc_data_rdata(uint64_t rdata)
{
  if (rvfi.has_value()) {
    rvfi->rvfi_set_pc_data_rdata(rdata);
  }
  return UNIT;
}

unit rvfi_set_pc_data_wdata(uint64_t wdata)
{
  if (rvfi.has_value()) {
    rvfi->rvfi_set_pc_data_wdata(wdata);
  }
  return UNIT;
}
