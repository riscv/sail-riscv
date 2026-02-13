#include "elf_loader.h"
#include "elfio/elf_types.hpp"

#include <elfio/elfio.hpp>
#include <memory>

ELF::ELF(std::unique_ptr<ELFIO::elfio> elf) : m_elf(std::move(elf)) {
}

ELF ELF::open(const std::string &filename) {
  auto reader = std::make_unique<ELFIO::elfio>();

  if (!reader->load(filename)) {
    throw std::runtime_error("File '" + filename + "' is not found or it is not an ELF file");
  }

  if (reader->get_machine() != ELFIO::EM_RISCV) {
    throw std::runtime_error("File '" + filename + "' is not a RISC-V ELF file");
  }

  return ELF(std::move(reader));
}

ELF ELF::create(Architecture arch) {
  auto elf = std::make_unique<ELFIO::elfio>();

  // Little Endian.
  switch (arch) {
  case Architecture::RV32:
    elf->create(ELFIO::ELFCLASS32, ELFIO::ELFDATA2LSB);
    break;
  case Architecture::RV64:
    elf->create(ELFIO::ELFCLASS64, ELFIO::ELFDATA2LSB);
    break;
  }

  elf->set_machine(ELFIO::EM_RISCV);
  elf->set_os_abi(ELFIO::ELFOSABI_NONE);

  // Core dump by default.
  elf->set_type(ELFIO::ET_CORE);

  return ELF(std::move(elf));
}

Architecture ELF::architecture() const {
  switch (m_elf->get_class()) {
  case ELFIO::ELFCLASS32:
    return Architecture::RV32;
  case ELFIO::ELFCLASS64:
    return Architecture::RV64;
  default:
    throw std::runtime_error("Unknown ELF class " + std::to_string(m_elf->get_class()));
  }
}

// Entry point.
uint64_t ELF::entry() const {
  return m_elf->get_entry();
}

void ELF::set_entry(uint64_t addr) {
  m_elf->set_entry(addr);
}

void ELF::load(std::function<void(uint64_t, const uint8_t *, uint64_t)> writer) const {
  std::vector<uint8_t> zeros;
  for (const auto &seg : m_elf->segments) {
    if (seg->get_type() == ELFIO::PT_LOAD) {
      // It's a segment that we should load into memory.
      if (seg->get_file_size() > seg->get_memory_size()) {
        // File size must be <= memory size.
        throw std::runtime_error(
          "Invalid ELF segment: file size (" + std::to_string(seg->get_file_size()) +
          ") is greater than memory size (" + std::to_string(seg->get_memory_size()) + ")"
        );
      }
      // Write the data to memory.
      writer(seg->get_physical_address(), reinterpret_cast<const uint8_t *>(seg->get_data()), seg->get_file_size());
      // If the memory size is greater than the file size the remaining
      // bytes should be zeroed.
      if (seg->get_memory_size() > seg->get_file_size()) {
        zeros.resize(seg->get_memory_size() - seg->get_file_size(), 0);
        writer(seg->get_physical_address() + seg->get_file_size(), zeros.data(), zeros.size());
      }
    }
  }
}

std::map<std::string, uint64_t> ELF::symbols() const {
  using namespace ELFIO;

  std::map<std::string, uint64_t> symbolMap;

  const section *symtab = m_elf->sections[".symtab"];
  if (symtab != nullptr) {
    const_symbol_section_accessor accessor(*m_elf, symtab);
    unsigned index = 0;
    std::string name;
    Elf64_Addr value = 0;
    Elf_Xword size = 0;
    unsigned char bind = '\x00';
    unsigned char type = '\x00';
    Elf_Half section_index = 0;
    unsigned char other = '\x00';

    while (accessor.get_symbol(index, name, value, size, bind, type, section_index, other)) {
      if ((type == STT_NOTYPE || type == STT_FUNC || type == STT_OBJECT || type == STT_COMMON) &&
          section_index != SHN_UNDEF) {
        symbolMap[name] = value;
      }
      ++index;
    }
  }
  return symbolMap;
}

void ELF::add_segment(uint64_t address, const std::vector<uint8_t> &data) {
  // The ELF format doesn't require this but the ELFIO library only lets
  // you add segments by adding sections first.
  ELFIO::section *sec = m_elf->sections.add(".text");
  sec->set_type(ELFIO::SHT_PROGBITS);
  sec->set_flags(ELFIO::SHF_ALLOC | ELFIO::SHF_EXECINSTR);
  sec->set_addr_align(1);
  sec->set_data(reinterpret_cast<const char *>(data.data()), data.size());

  ELFIO::segment *seg = m_elf->segments.add();
  seg->set_type(ELFIO::PT_LOAD);
  seg->set_virtual_address(address);
  seg->set_physical_address(address);
  seg->set_flags(ELFIO::PF_R | ELFIO::PF_W | ELFIO::PF_X);
  seg->set_align(1);

  seg->add_section(sec, 1);
}

void ELF::save(const std::string &filename) const {
  std::ofstream file(filename);
  m_elf->save(file);
}
