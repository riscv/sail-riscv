#pragma once
#include "riscv_callbacks_if.h"
#include "sail.h"

class rvfi_callbacks : public callbacks_if {

public:
  // callbacks_if
  void mem_write_callback(
    ModelImpl &model,
    ModelImpl::MemoryAccessType,
    sbits paddr,
    int64_t width,
    lbits value
  ) override;
  void mem_read_callback(
    ModelImpl &model,
    ModelImpl::MemoryAccessType,
    sbits paddr,
    int64_t width,
    lbits value
  ) override;
  void mem_exception_callback(ModelImpl &model, sbits paddr, uint64_t num_of_exception) override;
  void xreg_write_callback(ModelImpl &model, sbits reg, sbits value) override;
  void trap_callback(ModelImpl &model, bool is_interrupt, fbits cause) override;
};
