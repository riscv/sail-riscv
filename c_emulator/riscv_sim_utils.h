#pragma once
#include "riscv_model_impl.h"
#include <cstdint>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

namespace riscv_sim {

class ConfigError : public std::runtime_error {
public:
  using std::runtime_error::runtime_error;
};

struct LoadResult {
  uint64_t entry;
  std::optional<uint64_t> htif_tohost;
  std::optional<uint64_t> sig_start;
  std::optional<uint64_t> sig_end;
};

LoadResult load_sail(ModelImpl &model, const std::string &filename, bool main_file);
void init_sail(ModelImpl &model, uint64_t elf_entry, std::optional<uint64_t> htif_tohost, const char *config_file);
void reinit_sail(ModelImpl &model, uint64_t elf_entry, std::optional<uint64_t> htif_tohost, const char *config_file);
void write_dtb_to_rom(ModelImpl &model, const std::vector<uint8_t> &dtb, uint64_t addr);

} // namespace riscv_sim
