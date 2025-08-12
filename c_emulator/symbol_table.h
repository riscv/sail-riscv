#pragma once

#include <cstdint>
#include <optional>
#include <map>
#include <string>

// Reverse a symbol table so instead of name->value it's value->name.
std::map<uint64_t, std::string>
reverse_symbol_table(const std::map<std::string, uint64_t> &symbols);

// Find the symbol that is closest to `address` in value (but not greater than
// it). Return the symbol name and the symbol value (not the offset to
// `address`).
std::optional<std::pair<uint64_t, const std::string &>>
symbolize_address(const std::map<uint64_t, std::string> &symbols,
                  uint64_t address);

// Global symbol table.
// TODO: Don't use globals.
extern std::map<uint64_t, std::string> g_symbols;
