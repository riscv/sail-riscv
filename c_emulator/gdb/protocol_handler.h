#pragma once

#include "config_utils.h"
#include "requests.h"
#include "riscv_callbacks_if.h"
#include "riscv_model_impl.h"
#include "triggers.h"
#include <asio.hpp>
#include <deque>
#include <set>
#include <string>

class connection;
struct gdb_run_info;

// Protocol handler is shared by the `connection` (its parent) and
// `riscv_model_impl` (as a callback object).
class protocol_handler : public std::enable_shared_from_this<protocol_handler>, public callbacks_if {
public:
  explicit protocol_handler(
    asio::any_io_executor executor,
    connection &connection,
    ModelImpl &model,
    gdb_run_info &info
  ) :
      m_executor(std::move(executor)),
      m_connection{connection},
      m_model{model},
      m_run_info{info},
      m_triggers{info} {

    m_insns_per_tick = get_config_uint64({"platform", "instructions_per_tick"});
  }

  void attach_callbacks() {
    auto self(shared_from_this());
    m_model.register_callback(self);
  }

  void detach_callbacks() {
    auto self(shared_from_this());
    m_model.remove_callback(self);
  }

  void reset() {
    m_model.reinit_sail();
    m_step_no = 0;
    m_insn_cnt = 0;
    m_interrupt_count = 0;
    m_has_trapped = false;
    m_triggered = false;
    m_in_continue = false;
    m_triggers.clear();
  }

  // This processes raw data as received over the input channel.
  void receive_data(const std::string &data);

  // Handle an interrupt notification.
  void interrupt() {
    ++m_interrupt_count;
  }

  void enter_noack_mode() {
    m_in_noack_mode = true;
  }

  // The response payload is without the $-# packet framing or any escapes.
  // Those are added by the protocol handler.
  void send_response(const std::string &payload);
  void send_empty_response();
  void send_stop_reply();

  // Access to the model.
  ModelImpl &get_model() {
    return m_model;
  }
  const ModelImpl &get_model() const {
    return m_model;
  }

  // Execution helpers
  void do_step();
  void start_continue();
  void continue_continue();
  void end_continue();

  // Callbacks
  void trap_callback(ModelImpl &, bool is_interrupt, fbits cause) override;
  void mem_write_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) override;
  void mem_read_callback(ModelImpl &model, const char *type, sbits paddr, int64_t width, lbits value) override;

  // Triggers
  class triggers &triggers() {
    return m_triggers;
  }
  const class triggers &triggers() const {
    return m_triggers;
  }
  void check_pc_breakpoint();

private:
  void parse();
  void process_raw_request(std::string cmd);
  void queue_response(response_handler_ptr resp);
  void handle_pending_responses();
  void send_data(const std::string &data);

  // protocol state
  asio::any_io_executor m_executor;
  connection &m_connection;
  std::string m_parse_buffer;
  request_parsers m_parsers;
  std::deque<response_handler_ptr> m_pending_responses;
  bool m_in_noack_mode = false;

  // execution state
  ModelImpl &m_model;
  gdb_run_info &m_run_info;
  int64_t m_step_no = 0;
  int64_t m_insn_cnt = 0;
  int64_t m_insns_per_tick = 0;
  int64_t m_interrupt_count = 0;
  bool m_has_trapped = false;
  bool m_triggered = false;
  bool m_in_continue = false;

  // triggers
  class triggers m_triggers;
};
