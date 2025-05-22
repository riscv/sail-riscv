#include <string>
#include <sstream>
#include "sail.h"
#include "sail_config.h"
#include "dts.h"
#include "config_utils.h"

// Requires sail_config to have been initialized.
void print_dts(mach_bits xlen)
{
  uint64_t hart_hz = 1000000000; // 1GHz. TODO: get from config.
  uint64_t insns_per_tick
      = get_config_uint64({"platform", "instructions_per_tick"});
  uint64_t pmp_count = get_config_uint64({"memory", "pmp", "count"});
  uint64_t pmp_grain = get_config_uint64({"memory", "pmp", "grain"});
  uint64_t ram_base = get_config_uint64({"platform", "ram", "base"});
  uint64_t ram_size = get_config_uint64({"platform", "ram", "size"});
  uint64_t clint_base = get_config_uint64({"platform", "clint", "base"});
  uint64_t clint_size = get_config_uint64({"platform", "clint", "size"});

  // Default, should be adjusted based on config.
  const char *isa_string = "imafdc_zicntr_zihpm";
  std::stringstream s;
  s << std::dec
    << "/dts-v1/;\n"
       "\n"
       "/ {\n"
       "  #address-cells = <2>;\n"
       "  #size-cells = <2>;\n"
       "  compatible = \"ucbbar,spike-bare-dev\";\n"
       "  model = \"ucbbar,spike-bare\";\n"
       "  cpus {\n"
       "    #address-cells = <1>;\n"
       "    #size-cells = <0>;\n"
       "    timebase-frequency = <"
    << (hart_hz / insns_per_tick)
    << ">;\n"
       "    CPU0: cpu@0 {\n"
       "      device_type = \"cpu\";\n"
       "      reg = <0>;\n"
       "      status = \"okay\";\n"
       "      compatible = \"riscv\";\n"
       "      riscv,isa = \""
    << "rv" << (xlen == 32 ? "32" : "64") << isa_string
    << "\";\n"
       "      mmu-type = \"riscv,"
    << (xlen == 32 ? "sv32" : "sv39")
    << "\";\n"
       "      riscv,pmpregions = <"
    << pmp_count
    << ">;\n"
       "      riscv,pmpgranularity = <"
    << (2 << (pmp_grain + 1))
    << ">;\n"
       "      clock-frequency = <"
    << hart_hz
    << ">;\n"
       "      CPU0_intc: interrupt-controller {\n"
       "        #address-cells = <2>;\n"
       "        #interrupt-cells = <1>;\n"
       "        interrupt-controller;\n"
       "        compatible = \"riscv,cpu-intc\";\n"
       "      };\n"
       "    };\n"
       "  };\n"
    << std::hex << "  memory@" << ram_base
    << " {\n"
       "    device_type = \"memory\";\n"
       "    reg = <0x"
    << (ram_base >> 32) << " 0x" << (ram_base & (uint32_t)-1) << " 0x"
    << (ram_size >> 32) << " 0x" << (ram_size & (uint32_t)-1)
    << ">;\n"
       "  };\n"
       "  soc {\n"
       "    #address-cells = <2>;\n"
       "    #size-cells = <2>;\n"
       "    compatible = \"ucbbar,spike-bare-soc\", \"simple-bus\";\n"
       "    ranges;\n"
       "    clint@"
    << clint_base
    << " {\n"
       "      compatible = \"riscv,clint0\";\n"
       "      interrupts-extended = <&CPU0_intc 3 &CPU0_intc 7>;\n"
    << std::hex << "      reg = <0x" << (clint_base >> 32) << " 0x"
    << (clint_base & (uint32_t)-1) << " 0x" << (clint_size >> 32) << " 0x"
    << (clint_size & (uint32_t)-1)
    << ">;\n"
       "    };\n"
       "  };\n"
       "  htif {\n"
       "    compatible = \"ucb,htif0\";\n"
       "  };\n"
       "};\n";

  fprintf(stdout, "%s", s.str().c_str());
  exit(0);
}
