#include "triggers.h"
#include "gdb_run_info.h"

#include <algorithm>
#include <iomanip>
#include <sstream>

namespace {

std::string_view to_string(WatchType w) {
  switch (w) {
  case WatchType::Read:
    return "Read";
  case WatchType::Write:
    return "Write";
  case WatchType::Access:
    return "Access";
  };
  return "Undefined";
}

} // namespace

void triggers::add_breakpoint(uint64_t addr) {
  std::ostringstream os;
  if (m_breakpoints.insert(addr).second) {
    os << "Breakpoint inserted at 0x" << std::hex << std::setfill('0') << std::setw(16) << addr;
  } else {
    os << "Breakpoint already present at 0x" << std::hex << std::setfill('0') << std::setw(16) << addr;
  }
  if (m_run_info.enable_trace) {
    fprintf(m_run_info.trace_log, "%s.\n", os.str().c_str());
  }
}

void triggers::remove_breakpoint(uint64_t addr) {
  std::ostringstream os;
  if (m_breakpoints.erase(addr) == 0) {
    os << "No breakpoint at 0x" << std::hex << std::setfill('0') << std::setw(16) << addr;
  } else {
    os << "Breakpoint removed from 0x" << std::hex << std::setfill('0') << std::setw(16) << addr;
  }
  if (m_run_info.enable_trace) {
    fprintf(m_run_info.trace_log, "%s.\n", os.str().c_str());
  }
}

bool triggers::at_breakpoint(uint64_t pc) {
  if (m_breakpoints.find(pc) == m_breakpoints.end()) {
    return false;
  }
  if (m_run_info.enable_trace) {
    std::ostringstream os;
    os << "Breakpoint hit at 0x" << std::hex << std::setfill('0') << std::setw(16) << pc;
    fprintf(m_run_info.trace_log, "%s.\n", os.str().c_str());
  }
  return true;
}

void triggers::add_watchpoint(WatchType t, uint64_t addr, int64_t width) {
  // Check if there is an existing watch on this address range.

  auto elem_ptr = std::find_if(m_watchpoints.begin(), m_watchpoints.end(), [&addr, &width](const auto &elem) {
    return elem.first == addr && elem.second.width == width;
  });

  if (elem_ptr != m_watchpoints.end()) {
    watch_info &wi = elem_ptr->second;
    wi.watches.set(static_cast<size_t>(t));

    if (m_run_info.enable_trace) {
      std::ostringstream os;
      os << "Watchpoint at 0x" << std::hex << std::setfill('0') << std::setw(16) << addr << "[" << wi.width << "]"
         << " augmented with " << to_string(t);
      fprintf(m_run_info.trace_log, "%s.\n", os.str().c_str());
    }
    return;
  }

  // Add a new watch on this range.

  watch_info wi = {
    .watches = {},
    .width = width,
  };
  wi.watches.set(static_cast<size_t>(t));
  m_watchpoints.emplace(addr, wi);

  if (m_run_info.enable_trace) {
    std::ostringstream os;
    os << to_string(t) << "Watchpoint added at 0x" << std::hex << std::setfill('0') << std::setw(16) << addr << "["
       << width << "]";
    fprintf(m_run_info.trace_log, "%s.\n", os.str().c_str());
  }
}

void triggers::remove_watchpoint(WatchType t, uint64_t addr, int64_t width) {
  std::ostringstream os;

  auto elem_ptr = std::find_if(m_watchpoints.begin(), m_watchpoints.end(), [&addr, &width](const auto &elem) {
    return elem.first == addr && elem.second.width == width;
  });

  if (elem_ptr != m_watchpoints.end()) {
    watch_info &wi = elem_ptr->second;
    wi.watches.reset(static_cast<size_t>(t));

    if (wi.watches.none()) {
      m_watchpoints.erase(elem_ptr);
      os << to_string(t) << "Watchpoint removed from 0x" << std::hex << std::setfill('0') << std::setw(16) << addr;
    } else {
      os << "Watchpoint at 0x" << std::hex << std::setfill('0') << std::setw(16) << addr << " removed " << to_string(t)
         << " watch";
    }
  } else {
    os << "No watchpoint at 0x" << std::hex << std::setfill('0') << std::setw(16) << addr;
  }

  if (m_run_info.enable_trace) {
    fprintf(m_run_info.trace_log, "%s.\n", os.str().c_str());
  }
}

bool triggers::at_watchpoint(AccessType t, uint64_t addr, int64_t width) {
  // TODO: a more efficient range-based match
  for (const auto &w : m_watchpoints) {
    // Match an overlapping access of the right type.  This assumes
    // that the provided ranges don't wrap if width-1 is used.
    if ((addr + width - 1 < w.first) | (w.first + w.second.width - 1 < addr)) {
      continue;
    }

    bool matched = w.second.watches.test(static_cast<size_t>(WatchType::Access));
    switch (t) {
    case AccessType::Read:
      matched |= w.second.watches.test(static_cast<size_t>(WatchType::Read));
      break;
    case AccessType::Write:
      matched |= w.second.watches.test(static_cast<size_t>(WatchType::Write));
      break;
    }
    if (!matched) {
      continue;
    }

    if (m_run_info.enable_trace) {
      std::ostringstream os;
      os << "Watchpoint hit for 0x" << std::hex << std::setfill('0') << std::setw(16) << addr << "[" << width << "]"
         << " at watch 0x" << w.first << "[" << w.second.width << "]";
      fprintf(m_run_info.trace_log, "%s.\n", os.str().c_str());
    }
    return true;
  }

  return false;
}
