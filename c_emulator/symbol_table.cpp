#include "symbol_table.h"
#include <optional>

std::map<uint64_t, std::string>
reverse_symbol_table(const std::map<std::string, uint64_t> &symbols)
{
  std::map<uint64_t, std::string> reversed;
  for (const auto &it : symbols) {
    // If multiple symbols have the same value the last one alphabetically wins.
    reversed[it.second] = it.first;
  }
  return reversed;
}

std::optional<std::pair<uint64_t, const std::string &>>
symbolize_address(const std::map<uint64_t, std::string> &symbols,
                  uint64_t address)
{
  // Find the first symbol > the address.
  auto it = symbols.upper_bound(address);
  if (it == symbols.begin()) {
    // The very first symbol is greater than the address,
    // or there are no symbols and begin() = end().
    return std::nullopt;
  }
  // Go back one symbol to the first symbol <= the address.
  --it;
  return *it;
}

std::map<uint64_t, std::string> g_symbols;
