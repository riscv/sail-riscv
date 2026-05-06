#include "riscv_sim_utils.h"
#include "elf_loader.h"
#include "rts.h"
#include "symbol_table.h"
#include <stdexcept>

namespace riscv_sim {

LoadResult load_sail(ModelImpl &model, const std::string &filename, bool main_file) {
  ELF elf = ELF::open(filename);

  switch (elf.architecture()) {
  case Architecture::RV32:
    if (model.zxlen != 32) {
      throw ConfigError("32-bit ELF not supported by RV" + std::to_string(model.zxlen) + " model.");
    }
    break;
  case Architecture::RV64:
    if (model.zxlen != 64) {
      throw ConfigError("64-bit ELF not supported by RV" + std::to_string(model.zxlen) + " model.");
    }
    break;
  }

  // Load into memory.
  elf.load([](uint64_t address, const uint8_t *data, uint64_t length) {
    // TODO: We could definitely improve on rts.c's memory implementation
    // (which is O(N^2)) and writing one byte at a time here.
    for (uint64_t i = 0; i < length; ++i) {
      write_mem(address + i, data[i]);
    }
  });

  // Load the entire symbol table.
  const auto symbols = elf.symbols();

  // Save reversed symbol table for log symbolization.
  // If multiple symbols from different ELF files have the same value the first
  // one wins.
  const auto reversed_symbols = reverse_symbol_table(symbols);
  g_symbols.insert(reversed_symbols.begin(), reversed_symbols.end());

  LoadResult result;
  result.entry = elf.entry();

  if (main_file) {
    // Only scan for test-signature/htif symbols in the main ELF file.
    const auto &tohost = symbols.find("tohost");
    if (tohost == symbols.end()) {
      fprintf(stderr, "Unable to locate tohost symbol; disabling HTIF.\n");
    } else {
      result.htif_tohost = tohost->second;
      fprintf(stdout, "HTIF located at 0x%0" PRIx64 "\n", *result.htif_tohost);
    }
    const auto &begin_sig = symbols.find("begin_signature");
    if (begin_sig != symbols.end()) {
      fprintf(stdout, "begin_signature: 0x%0" PRIx64 "\n", begin_sig->second);
      result.sig_start = begin_sig->second;
    }
    const auto &end_sig = symbols.find("end_signature");
    if (end_sig != symbols.end()) {
      fprintf(stdout, "end_signature: 0x%0" PRIx64 "\n", end_sig->second);
      result.sig_end = end_sig->second;
    }
  }

  return result;
}

void init_sail(ModelImpl &model, uint64_t elf_entry, std::optional<uint64_t> htif_tohost, const char *config_file) {
  // zset_pc_reset_address must be called before zinit_model
  // because reset happens inside init_model().
  model.zset_pc_reset_address(elf_entry);
  if (htif_tohost.has_value()) {
    model.zenable_htif(*htif_tohost);
  }
  model.zinit_model(config_file != nullptr ? config_file : "");
  model.zinit_boot_requirements(UNIT);
}

// reinitialize to clear state and memory, typically across tests runs
void reinit_sail(ModelImpl &model, uint64_t elf_entry, std::optional<uint64_t> htif_tohost, const char *config_file) {
  model.model_fini();
  model.model_init();
  init_sail(model, elf_entry, htif_tohost, config_file);
}

void write_dtb_to_rom(ModelImpl &model, const std::vector<uint8_t> &dtb, uint64_t addr) {
  uint64_t size = static_cast<uint64_t>(dtb.size());

  // Overflow check for addr + size - 1
  uint64_t end = addr + size - 1;
  if (end < addr) {
    char buf[128];
    snprintf(buf, sizeof(buf), "DTB address/size overflow: addr=0x%" PRIx64 ", size=0x%" PRIx64, addr, size);
    throw ConfigError(buf);
  }

  // Validate DTB range against configured PMA memory regions.
  if (!model.zdtb_within_configured_pma_memory(addr, size)) {
    char buf[256];
    snprintf(
      buf,
      sizeof(buf),
      "DTB does not fit in any configured PMA memory region: "
      "addr=0x%" PRIx64 ", size=0x%" PRIx64 " (end=0x%" PRIx64 "). "
      "Hint: adjust memory.dtb_address or memory.regions in the config.",
      addr,
      size,
      end
    );
    throw ConfigError(buf);
  }

  for (uint8_t d : dtb) {
    write_mem(addr++, d);
  }
}

} // namespace riscv_sim
