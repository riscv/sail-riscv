#pragma once

#include <bitset>
#include <cstdint>
#include <map>
#include <set>

struct gdb_run_info;

enum class AccessType {
  Read,
  Write,
};

enum class WatchType : size_t {
  Read,
  Write,
  Access,
};

struct watch_info {
  std::bitset<3> watches;
  int64_t width;
};

class triggers {
public:
  explicit triggers(gdb_run_info &info) : m_run_info{info} {
  }

  // Breakpoints
  void add_breakpoint(uint64_t addr);
  void remove_breakpoint(uint64_t addr);
  bool at_breakpoint(uint64_t addr);

  // Watchpoints
  void add_watchpoint(WatchType t, uint64_t addr, int64_t width);
  void remove_watchpoint(WatchType t, uint64_t addr, int64_t width);
  bool at_watchpoint(AccessType t, uint64_t addr, int64_t width);

  // Reset
  void clear() {
    m_breakpoints.clear();
    m_watchpoints.clear();
  }

private:
  gdb_run_info &m_run_info;
  std::set<uint64_t> m_breakpoints;
  std::map<uint64_t, watch_info> m_watchpoints;
};
