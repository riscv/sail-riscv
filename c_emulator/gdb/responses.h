#pragma once

#include "triggers.h"

#include <cstdint>
#include <optional>
#include <set>
#include <string>

struct gdb_run_info;
class protocol_handler;

namespace response {

class response_handler {
public:
  virtual ~response_handler() = default;

  virtual void dispatch(protocol_handler &, gdb_run_info &) {
  }

protected:
  response_handler() = default;
  response_handler(const response_handler &) = default;
  response_handler(response_handler &&) = default;

  response_handler &operator=(const response_handler &) = delete;
  response_handler &operator=(response_handler &&) = delete;
};

class interrupt : public response_handler {
public:
  interrupt() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class qsupported : public response_handler {
public:
  explicit qsupported(std::set<std::string> features) : m_gdb_features{std::move(features)} {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  std::set<std::string> m_gdb_features;
};

class qstartnoackmode : public response_handler {
public:
  qstartnoackmode() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class qhostinfo : public response_handler {
public:
  qhostinfo() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class empty_response : public response_handler {
public:
  empty_response() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class ok : public response_handler {
public:
  ok() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class qattached : public response_handler {
public:
  qattached() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class qoffsets : public response_handler {
public:
  qoffsets() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class question : public response_handler {
public:
  question() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class read_general_registers : public response_handler {
public:
  read_general_registers() = default;

  void dispatch(protocol_handler &, gdb_run_info &) override;
};

class read_register : public response_handler {
public:
  read_register(uint64_t regidx) : m_regidx(regidx) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  uint64_t m_regidx = 0;
};

class write_register : public response_handler {
public:
  write_register(uint64_t regidx, uint64_t regval) : m_regidx(regidx), m_regval(regval) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  uint64_t m_regidx = 0;
  uint64_t m_regval = 0;
};

class qXfer_features_read : public response_handler {
public:
  explicit qXfer_features_read(std::string annex, uint64_t offset, uint64_t length) :
      m_annex(std::move(annex)),
      m_offset(offset),
      m_length(length) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  std::string m_annex;
  uint64_t m_offset = 0;
  uint64_t m_length = 0;
};

class read_memory : public response_handler {
public:
  explicit read_memory(uint64_t addr, uint64_t length) : m_addr(addr), m_length(length) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  uint64_t m_addr = 0;
  uint64_t m_length = 0;
};

class single_step : public response_handler {
public:
  explicit single_step(std::optional<uint64_t> opt_addr) : m_opt_addr(std::move(opt_addr)) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  std::optional<uint64_t> m_opt_addr;
};

class forward_continue : public response_handler {
public:
  explicit forward_continue(std::optional<uint64_t> opt_addr) : m_opt_addr(std::move(opt_addr)) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  std::optional<uint64_t> m_opt_addr;
};

class write_binary_data : public response_handler {
public:
  explicit write_binary_data(uint64_t addr, uint64_t length, std::string data) :
      m_addr(addr),
      m_length(length),
      m_data(std::move(data)) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  uint64_t m_addr = 0;
  uint64_t m_length = 0;
  std::string m_data = 0;
};

class vkill : public response_handler {
public:
  explicit vkill(uint64_t pid) : m_pid(pid) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  [[maybe_unused]] uint64_t m_pid = 0;
};

enum class TriggerCmd {
  Add,
  Remove,
};

enum class BreakpointType {
  Software,
  Hardware,
};

class breakpoint : public response_handler {
public:
  explicit breakpoint(BreakpointType t, TriggerCmd cmd, uint64_t addr, std::string kind) :
      m_type(t),
      m_cmd(cmd),
      m_addr(addr),
      m_kind(std::move(kind)) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  BreakpointType m_type;
  TriggerCmd m_cmd;
  uint64_t m_addr = 0;
  std::string m_kind;
};

class watchpoint : public response_handler {
public:
  explicit watchpoint(WatchType t, TriggerCmd cmd, uint64_t addr, uint64_t kind) :
      m_type(t),
      m_cmd(cmd),
      m_addr(addr),
      m_kind(kind) {
  }

  void dispatch(protocol_handler &, gdb_run_info &) override;

private:
  WatchType m_type;
  TriggerCmd m_cmd;
  uint64_t m_addr = 0;
  uint64_t m_kind = 0;
};

} // namespace response
