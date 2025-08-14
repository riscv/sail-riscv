#include "elf_loader.h"
#include "elfio/elf_types.hpp"

#include <elfio/elfio.hpp>

ELF::ELF(std::unique_ptr<ELFIO::elfio> reader)
    : m_reader(std::move(reader))
{
}

ELF ELF::open(const std::string &filename)
{
  auto reader = std::make_unique<ELFIO::elfio>();

  if (!reader->load(filename)) {
    throw std::runtime_error("File '" + filename
                             + "' is not found or it is not an ELF file");
  }

  if (reader->get_machine() != ELFIO::EM_RISCV) {
    throw std::runtime_error("File '" + filename
                             + "' is not a RISC-V ELF file");
  }

  return ELF(std::move(reader));
}

Architecture ELF::architecture() const
{
  switch (m_reader->get_class()) {
  case ELFIO::ELFCLASS32:
    return Architecture::RV32;
  case ELFIO::ELFCLASS64:
    return Architecture::RV64;
  default:
    throw std::runtime_error("Unknown ELF class "
                             + std::to_string(m_reader->get_class()));
  }
}

// Entry point.
uint64_t ELF::entry() const
{
  return m_reader->get_entry();
}

void ELF::load(
    std::function<void(uint64_t, const uint8_t *, uint64_t)> writer) const
{
  for (const auto &seg : m_reader->segments) {
    if (seg->get_type() == ELFIO::PT_LOAD) {
      // It's a segment that we should load into memory.
      if (seg->get_file_size() > seg->get_memory_size()) {
        // File size must be <= memory size.
        throw std::runtime_error("Invalid ELF segment: file size ("
                                 + std::to_string(seg->get_file_size())
                                 + ") is greater than memory size ("
                                 + std::to_string(seg->get_memory_size())
                                 + ")");
      }
      // Write the data to memory.
      writer(seg->get_physical_address(),
             reinterpret_cast<const uint8_t *>(seg->get_data()),
             seg->get_file_size());
      // If the memory size is greater than the file size the remaining
      // bytes should be zeroed.
      if (seg->get_memory_size() > seg->get_file_size()) {
        std::vector<uint8_t> zeros(
            seg->get_memory_size() - seg->get_file_size(), 0);
        writer(seg->get_physical_address() + seg->get_file_size(), zeros.data(),
               zeros.size());
      }
    }
  }
}

std::map<std::string, uint64_t> ELF::symbols() const
{
  using namespace ELFIO;

  std::map<std::string, uint64_t> symbolMap;

  const section *symtab = m_reader->sections[".symtab"];
  if (symtab != nullptr) {
    const_symbol_section_accessor accessor(*m_reader, symtab);
    unsigned index = 0;
    std::string name;
    Elf64_Addr value = 0;
    Elf_Xword size = 0;
    unsigned char bind = '\x00';
    unsigned char type = '\x00';
    Elf_Half section_index = 0;
    unsigned char other = '\x00';

    while (accessor.get_symbol(index, name, value, size, bind, type,
                               section_index, other)) {
      if ((type == STT_NOTYPE || type == STT_FUNC || type == STT_OBJECT
           || type == STT_COMMON)
          && section_index != SHN_UNDEF) {
        symbolMap[name] = value;
      }
      ++index;
    }
  }
  return symbolMap;
}
