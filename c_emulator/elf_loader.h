#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>

#include <elfio/elfio.hpp>

enum class Architecture {
  RV32,
  RV64,
};

class ELF {
public:
  // Open a RISC-V ELF file. Throws an exception if the file doesn't
  // exist or isn't a RISC-V ELF file.
  static ELF open(const std::string &filename);

  // Return the architecture (RV32/64).
  Architecture architecture() const;

  // Return the entry point (where execution should begin).
  uint64_t entry() const;

  // Call `writer()` to load all of the loadable sections into memory (or you
  // can do anything else with them).
  void
  load(std::function<void(uint64_t /* address */, const uint8_t * /* data */,
                          uint64_t /* length */)>
           writer) const;

  // Load and return the symbol table. It isn't cached - every time you call
  // this the entire symbol table is loaded from disk. Note only STT_FUNC,
  // STT_OBJECT, STT_COMMON and STT_NOTYPE symbols that are not SHN_UNDEF are
  // returned.
  std::map<std::string, uint64_t> symbols() const;

private:
  explicit ELF(std::unique_ptr<ELFIO::elfio> reader);

  // Unfortunately there's a bug in ELFIO which means we can't std::move() it,
  // so we have to put it in a unique_ptr.
  // https://github.com/serge1/ELFIO/issues/157
  std::unique_ptr<ELFIO::elfio> m_reader;
};
