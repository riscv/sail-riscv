#include "mem_dump.h"

#include "elf_loader.h"
#include "riscv_model_impl.h"

// Write all memory that has been written to an ELF file.
// The entry point is set to `entry`.
void dump_memory_to_elf(ModelImpl &model, const std::string &filename, uint64_t entry) {
  ELF elf = ELF::create(model.xlen() == 32 ? Architecture::RV32 : Architecture::RV64);
  elf.set_entry(entry);
  std::vector<uint8_t> segment;
  uint64_t segment_addr = 0;
  model.memory().for_each_byte(
    [&](uint64_t addr, uint8_t value) {
      if (segment_addr + segment.size() == addr) {
        // Add to existing segment.
        segment.push_back(value);
      } else {
        // New segment. Note that although this is correct and adds the minimal
        // amount of data to the ELF, in some cases where a large number of random
        // addresses have been written you end up with ELFs with a very large
        // number of small segments which is quite inefficient.
        if (!segment.empty()) {
          elf.add_segment(segment_addr, segment);
        }
        segment_addr = addr;
        segment.clear();
        segment.push_back(value);
      }
    },
    false
  );
  if (!segment.empty()) {
    elf.add_segment(segment_addr, segment);
  }
  elf.save(filename);
}
