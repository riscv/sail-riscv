#include "responses.h"
#include "gdb_run_info.h"
#include "protocol_handler.h"
#include "riscv_model_impl.h"
#include "target_regs.h"
#include "triggers.h"
#include <iomanip>
#include <iostream>
#include <set>
#include <sstream>

namespace response {

void interrupt::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  proto_handler.interrupt();
  // Reply will be sent when the interrupt is processed.
}

void qsupported::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  std::vector<std::string> stub_features = {
    // textual error replies (`E.errtext`)
    "error-message+",

    // Not advertising software breakpoint support doesn't seem to
    // matter, both GDB and LLDB still ask to set software
    // breakpoints.  As noted below, we implement only hardware
    // breakpoints.
    // "swbreak+",

    // hardware breakpoint support
    "hwbreak+",

    // no-ack mode
    "QStartNoAckMode+",
  };
  std::string resp;
  bool added_first = false;
  for (const auto &f : stub_features) {
    if (m_gdb_features.find(f) == m_gdb_features.end()) {
      continue;
    }
    if (added_first) {
      resp.append(";");
    }
    resp.append(f);
    added_first = true;
  }
  if (added_first) {
    resp.append(";");
  }
  // XML target descriptions
  // "This packet is not probed by default; the remote stub must
  // request it, by supplying an appropriate `qSupported` response."
  resp.append("qXfer:features:read+");
  // "If the stub supports `QStartNoAckMode` and prefers to operate in
  // no-acknowledgment mode, it should report that to GDB by including
  // `QStartNoAckMode+` in its response to `qSupported`."
  resp.append(";");
  resp.append("QStartNoAckMode+");
  proto_handler.send_response(resp);
}

void qstartnoackmode::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  proto_handler.enter_noack_mode();
  proto_handler.send_response("OK");
}

void qhostinfo::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  const ModelImpl &model = proto_handler.get_model();
  bool is_32bit = (model.xlen() == 32);
  // See https://github.com/llvm/llvm-project/blob/main/lldb/docs/resources/lldbgdbremote.md#qhostinfo
  // ';'-separated key-value pairs.
  // example response is 'cputype:16777223;cpusubtype:3;ostype:darwin;vendor:apple;endian:little;ptrsize:8;'
  std::string resp;
  // "cputype: is a number that is the mach-o CPU type that is being debugged (base 10)"
  // "cpusubtype: is a number that is the mach-o CPU subtype type that is being debugged (base 10)"
  // see llvm/include/llvm/BinaryFormat/MachO.h
  resp.append("cputype:24;");
  resp.append("cpusubtype:0;");
  // Send 'arch', 'ostype' and 'vendor' instead of 'triple' since
  // these can be sent as is while 'triple' needs to be hex-encoded.
  std::string arch = is_32bit ? "riscv32;" : "riscv64;";
  resp.append("arch:" + arch);
  resp.append("ostype:unknown;");
  resp.append("vendor:unknown;");
  // "endian: is one of "little", "big", or "pdp""
  // TODO: get this from the ELF or sail-riscv config.
  resp.append("endian:little;");
  // "ptrsize: an unsigned number that represents how big pointers are in bytes on the debug target"
  if (is_32bit) {
    resp.append("ptrsize:4;");
  } else {
    resp.append("ptrsize:8;");
  }
  // "watchpoint_exceptions_received: one of "before" or "after" to
  // specify if a watchpoint is triggered before or after the pc when
  // it stops"
  // Since we check the pc after a step, i.e. before the instruction
  // at the pc executes, presumably the right value is "before".
  resp.append("watchpoint_exceptions_received:before;");
  proto_handler.send_response(resp);
}

void empty_response::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  proto_handler.send_empty_response();
}

void ok::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  proto_handler.send_response("OK");
}

void qattached::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  // Reply that we created a new process.
  proto_handler.send_response("0");
}

void qoffsets::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  // No relocation needed.
  proto_handler.send_response("Text=0;Data=0;Bss=0");
}

void question::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  proto_handler.send_stop_reply();
}

void read_general_registers::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  ModelImpl &model = proto_handler.get_model();
  auto regs = get_general_regs(model);
  proto_handler.send_response(regs);
}

void read_register::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  ModelImpl &model = proto_handler.get_model();
  auto reg = get_register(model, m_regidx);
  proto_handler.send_response(reg);
}

void write_register::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  ModelImpl &model = proto_handler.get_model();
  auto reg = set_register(model, m_regidx, m_regval);
  proto_handler.send_response(reg);
}

void qXfer_features_read::dispatch(protocol_handler &proto_handler, gdb_run_info &info) {
  if (m_annex == "target.xml") {
    ModelImpl &model = proto_handler.get_model();
    auto xml = get_target_xml(model);
    std::ostringstream buf;
    if (m_offset + m_length < xml.length()) {
      buf << "m" << xml.substr(m_offset, m_length);
    } else {
      buf << "l" << xml.substr(m_offset);
    }
    proto_handler.send_response(buf.str());
  } else {
    if (info.enable_trace) {
      std::ostringstream msg;
      msg << "qXfer_features_read: unrecognized annex: " << m_annex << " (offs:" << m_offset << " len:" << m_length
          << ").";
      fprintf(info.trace_log, "%s\n", msg.str().c_str());
    }
    proto_handler.send_response("");
  }
}

void read_memory::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  std::ostringstream buf;
  buf << std::hex << std::setfill('0');
  for (uint64_t ptr = m_addr; ptr < m_addr + m_length; ++ptr) {
    unsigned byte = static_cast<unsigned>(read_mem(ptr)) & 0xff;
    buf << std::setw(2) << byte;
  }
  proto_handler.send_response(buf.str());
}

void single_step::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  ModelImpl &model = proto_handler.get_model();
  if (m_opt_addr.has_value()) {
    model.set_pc(m_opt_addr.value());
  }
  proto_handler.do_step();
  proto_handler.send_stop_reply();
}

void forward_continue::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  ModelImpl &model = proto_handler.get_model();
  if (m_opt_addr.has_value()) {
    model.set_pc(m_opt_addr.value());
  }
  proto_handler.start_continue();
}

void write_binary_data::dispatch(protocol_handler &proto_handler, gdb_run_info &info) {
  std::ostringstream buf;
  buf << std::hex << std::setfill('0');
  for (uint64_t i = 0; i < m_length; ++i) {
    uint8_t byte = static_cast<uint8_t>(m_data[i]);
    if (info.enable_trace) {
      buf << "mem[" << std::setw(16) << (m_addr + i) << "] <-- " << std::setw(2) << static_cast<uint64_t>(byte)
          << std::endl;
    }
    write_mem(m_addr + i, byte);
  }
  if (info.enable_trace) {
    fprintf(info.trace_log, "%s", buf.str().c_str());
  }
  proto_handler.send_response("OK");
}

void vkill::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  // We have only one process, assume that's the one specified, even
  // though the pid seems somewhat random.
  (void)m_pid;
  proto_handler.reset();
  proto_handler.send_response("OK");
}

void breakpoint::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  // Both breakpoints are currently handled as "hardware" breakpoints.
  // "Software" breakpoints modify modify the target's memory,
  // typically to replace the instruction at the specified address
  // with a breakpoint instruction. "Hardware" breakpoints don't
  // modify target memory; this is the approach used in this
  // implementation.  A request for a software breakpoints is treated
  // exactly like that for a hardware breakpoint, to avoid the
  // book-keeping required to keep track of overwritten instructions
  // and their replacement on breakpoint removal.
  (void)m_type;

  // Ignore the kind, which for `gdb` is typically 2 or 4 indicating
  // the size of the breakpoint instruction to insert, since we're not
  // writing to instruction memory.
  (void)m_kind;

  triggers &t = proto_handler.triggers();
  switch (m_cmd) {
  case TriggerCmd::Add:
    t.add_breakpoint(m_addr);
    // The PC might be at this new breakpoint, but that doesn't
    // matter since the execution has already been broken at this
    // point.
    break;
  case TriggerCmd::Remove:
    t.remove_breakpoint(m_addr);
    break;
  }

  proto_handler.send_response("OK");
}

void watchpoint::dispatch(protocol_handler &proto_handler, gdb_run_info &) {
  int64_t width = static_cast<int64_t>(m_kind);

  triggers &t = proto_handler.triggers();
  if (m_cmd == TriggerCmd::Add) {
    t.add_watchpoint(m_type, m_addr, width);
  } else {
    t.remove_watchpoint(m_type, m_addr, width);
  }

  proto_handler.send_response("OK");
}

} // namespace response
