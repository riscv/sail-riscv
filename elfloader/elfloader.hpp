#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <string>

#include "elfio/elfio.hpp"

enum class Architecture { RV32, RV64 };
enum class Encoding { little, big };

class ELF {
public:
  // Open a RISC-V ELF file. Throws an exception if the file doesn't
  // exist or isn't a RISC-V ELF file.
  // static ELF open(const std::string &filename)
  // {
  //   ELFIO::elfio reader;

  //   if (!reader.load(filename)) {
  //     fprintf(
  //         stderr,
  //         ("File \'" + filename + "\' is not found or it is not an ELF file")
  //             .c_str());
  //     exit(EXIT_FAILURE);
  //   }

  //   if (reader.get_machine() != ELFIO::EM_RISCV) {
  //     fprintf(stderr,
  //             ("File \'" + filename + "\' is an RISC-V ELF file").c_str());
  //     exit(EXIT_FAILURE);
  //   }

  //   return ELF(std::move(reader));
  // }

  // Return the architecture (RV32/64).
  Architecture architecture() const
  {
    switch (m_reader.get_class()) {
    case ELFIO::ELFCLASS32:
      return Architecture::RV32;
    case ELFIO::ELFCLASS64:
      return Architecture::RV64;
    default:
      throw std::runtime_error("Unknown ELF class "
                               + std::to_string(m_reader.get_class()));
    }
  }

  // Return the entry point (where execution should begin).
  uint64_t entry() const
  {
    return m_reader.get_entry();
  }

  // Return true if this is a Position-Independent Executable (the `type` is
  // ET_DYN).
  bool is_pie() const
  {
    return m_reader.get_type() == ELFIO::ET_DYN;
  }

  // Call `writer()` to load all of the loadable sections into memory (or you
  // can do anything else with them).
  void
  load(std::function<void(uint64_t, const uint8_t *, uint64_t)> writer) const
  {
    for (const auto &seg : m_reader.segments) {
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
        // if (seg->get_memory_size() > seg->get_file_size()) {
        //   std::vector<uint8_t> zeros(
        //       seg->get_memory_size() - seg->get_file_size(), 0);
        //   writer(seg->get_physical_address() + seg->get_file_size(),
        //          zeros.data(), zeros.size());
        // }
      }
    }
  }

  // Load and return the symbol table. It isn't cached - every time you call
  // this the entire symbol table is loaded from disk. Note only STT_FUNC and
  // STT_NOTYPE symbols that are not SHN_UNDEF are returned.

  std::unordered_map<std::string, uint64_t> symbols() const
  {
    using namespace ELFIO;

    std::unordered_map<std::string, uint64_t> symbolMap;
    section *symtab_sec = m_reader.sections[".symtab"];
    // fprintf(stderr,"name:%s,type:%d",symtab_sec->get_name().c_str(),symtab_sec->get_type());
    if (symtab_sec && symtab_sec->get_type() == SHT_SYMTAB) {
      const symbol_section_accessor symbols(m_reader, symtab_sec);
      for (unsigned int j = 0; j < symbols.get_symbols_num(); ++j) {
        std::string name;
        Elf64_Addr value;
        Elf_Xword size;
        unsigned char bind, type, other;
        Elf_Half index;
        symbols.get_symbol(j, name, value, size, bind, type, index, other);
        // std::cout << "Symbol: " << name << ", Addr: 0x" << std::hex <<
        // value<< std::endl;
        symbolMap[name] = value;
      }
    }
    return symbolMap;
  }
ELF(const std::string &filename){
    if (!m_reader.load(filename)) {
      fprintf(
          stderr,
          ("File \'" + filename + "\' is not found or it is not an ELF file")
              .c_str());
      exit(EXIT_FAILURE);
    }

    if (m_reader.get_machine() != ELFIO::EM_RISCV) {
      fprintf(stderr,
              ("File \'" + filename + "\' is an RISC-V ELF file").c_str());
      exit(EXIT_FAILURE);
    }
    
  }
private:
  // explicit ELF(ELFIO::elfio reader)
  //     : m_reader(std::move(reader))
  // {
  // }
  
  ELFIO::elfio m_reader;
};
