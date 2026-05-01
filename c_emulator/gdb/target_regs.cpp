#include "target_regs.h"
#include "config_utils.h"
#include "riscv_model_impl.h"
#include <sstream>

const register_map get_register_map() {
  register_map map = {
    // TODO: handle the E base ISA
    .pc_offset = 32,
    .fpr_offset = 33,
    // `fcsr` could be duplicated, as under `fpu` and `csr`.  We put
    // it only in the fpu annex.
    .fcsr_offset = 65,
  };
  return map;
}

std::string get_target_xml(const ModelImpl &model) {
  register_map map = get_register_map();
  std::ostringstream xml;

  xml << R"(<?xml version="1.0"?>
<!DOCTYPE target SYSTEM "gdb-target.dtd">
<target version="1.0">
)";

  // Current architectures are `riscv:rv32`, `riscv:rv64`, with
  // `riscv` being a default.
  xml << "<architecture>";
  if (model.xlen() == 32) {
    xml << "riscv:rv32";
  } else {
    xml << "riscv:rv64";
  }
  xml << "</architecture>" << std::endl;

  // The `org.gnu.gdb.riscv.cpu` feature is required for RISC-V
  // targets. It should contain the registers `x0` through `x31`, and
  // `pc`. Either the architectural names (`x0`, `x1`, etc) can be
  // used, or the ABI names (`zero`, `ra`, etc).
  xml << R"(<feature name="org.gnu.gdb.riscv.cpu">)" << std::endl;
  // TODO: handle 16 registers for the E base ISA.
  int regnum = 0;
  for (int i = 0; i < 32; ++i) {
    std::string typ = (i == 1) ? "code_ptr" : ((i == 2 || i == 3 || i == 4 || i == 8) ? "data_ptr" : "int");
    xml << "  <reg name=\"x" << i << "\" bitsize=\"" << model.xlen() << "\" type=\"" << typ << "\"";
    if (i == 0) {
      xml << R"( regnum="0" )";
    }
    xml << "/>" << std::endl;
    ++regnum;
  }
  assert(regnum == map.pc_offset);
  xml << "  <reg name=\"pc\" bitsize=\"" << model.xlen() << "\" type=\"code_ptr\"/>" << std::endl;
  xml << "</feature>" << std::endl;

  ++regnum;
  assert(regnum == map.fpr_offset);

  bool have_double = get_config_bool({"extensions", "D", "supported"});
  bool have_single = get_config_bool({"extensions", "F", "supported"});
  if (have_double | have_single) {
    // The `org.gnu.gdb.riscv.fpu` feature is optional. If present, it
    // should contain registers `f0` through `f31`, `fflags`, `frm`,
    // and `fcsr`. As with the cpu feature, either the architectural
    // register names, or the ABI names can be used.
    std::string fpu_type;
    xml << R"(<feature name="org.gnu.gdb.riscv.fpu">)" << std::endl;
    if (have_double) {
      assert(model.flen() == 64);
      // The registers can hold both ieee_single and ieee_double.
      xml << R"(  <union id="riscv_double">
    <field name="float" type="ieee_single"/>
    <field name="double" type="ieee_double"/>
  </union>
)";
      fpu_type = "riscv_double";
    } else {
      fpu_type = "ieee_single";
    }
    for (int i = 0; i < 32; ++i) {
      xml << "  <reg name=\"f" << i << "\" bitsize=\"" << model.flen() << "\" type=\"" << fpu_type << "\"";
      if (i == 0) {
        xml << " regnum = \"" << regnum << "\"";
      }
      xml << "/>" << std::endl;
      ++regnum;
    }
    xml << "  <reg name=\"fcsr\" bitsize=\"32\" type=\"int\" regnum=\"" << regnum << "\"/>" << std::endl;
    xml << "</feature>" << std::endl;
  }

  xml << "</target>" << std::endl;
  return xml.str();
}

// get_general_regs:
//
// Response is of the form 'XX..'
// Each byte of register data is described by two hex digits. The
// bytes with the register are transmitted in target byte order. The
// size of each register and their position within the `g` packet are
// determined by the target description (the above XML).

namespace {

// This assumes `buf` has been set up with std::hex and std::setfill.
void append_reg(std::ostringstream &buf, uint64_t bytes, int64_t nbytes) {
  // Send bytes in little-endian order.
  // TODO: handle big-endian model.
  for (int64_t b = 0; b < nbytes; ++b) {
    unsigned byte = bytes & 0xff;
    buf << std::setw(2) << byte;
    bytes >>= 8;
  }
}

} // namespace

std::string get_general_regs(ModelImpl &model) {
  register_map map = get_register_map();
  std::ostringstream buf;
  buf << std::hex << std::setfill('0');
  int64_t n_intbytes = model.xlen() / 8;

  for (int64_t i = 0; i < map.pc_offset; ++i) {
    const uint64_t reg = model.peek_xreg(i);
    append_reg(buf, reg, n_intbytes);
  }
  append_reg(buf, model.pc(), n_intbytes);

  bool have_double = get_config_bool({"extensions", "D", "supported"});
  bool have_single = get_config_bool({"extensions", "F", "supported"});
  if (have_double | have_single) {
    int64_t n_floatbytes = model.flen() / 8;
    for (int64_t i = 0; i < 32; ++i) {
      const uint64_t freg = model.peek_freg(i);
      append_reg(buf, freg, n_floatbytes);
    }
    append_reg(buf, model.fcsr(), 4);
  }
  return buf.str();
}

std::string get_register(ModelImpl &model, uint64_t regidx) {
  int64_t idx = static_cast<int64_t>(regidx);
  register_map map = get_register_map();

  std::ostringstream buf;
  buf << std::hex << std::setfill('0');
  int64_t n_intbytes = model.xlen() / 8;

  bool have_double = get_config_bool({"extensions", "D", "supported"});
  bool have_single = get_config_bool({"extensions", "F", "supported"});

  if (0 <= idx && idx < map.pc_offset) {
    uint64_t reg = model.peek_xreg(idx);
    append_reg(buf, reg, n_intbytes);
  } else if (idx == map.pc_offset) {
    append_reg(buf, model.pc(), n_intbytes);
  } else if ((have_single | have_double) && map.fpr_offset <= idx && idx <= map.fcsr_offset) {
    if (idx == map.fcsr_offset) {
      append_reg(buf, model.fcsr(), 4);
    } else {
      idx -= map.fpr_offset;
      const uint64_t freg = model.peek_freg(idx);
      int64_t n_floatbytes = model.flen() / 8;
      append_reg(buf, freg, n_floatbytes);
    }
  } else {
    buf << "E.invalid_register_idx";
  }
  return buf.str();
}

std::string set_register(ModelImpl &model, uint64_t regidx, uint64_t regval) {
  int64_t idx = static_cast<int64_t>(regidx);
  register_map map = get_register_map();

  bool have_double = get_config_bool({"extensions", "D", "supported"});
  bool have_single = get_config_bool({"extensions", "F", "supported"});

  if (0 <= idx && idx < map.pc_offset) {
    model.poke_xreg(idx, regval);
  } else if (idx == map.pc_offset) {
    model.set_pc(regval);
  } else if ((have_single | have_double) && map.fpr_offset <= idx && idx <= map.fcsr_offset) {
    if (idx == map.fcsr_offset) {
      model.set_fcsr(regval);
    } else {
      idx -= map.fpr_offset;
      model.poke_freg(idx, regval);
    }
  } else {
    return "E.invalid_register_idx";
  }

  return "OK";
}
