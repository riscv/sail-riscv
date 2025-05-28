function generate_dts() -> string = {
  let hart_hz : int = config platform.hart_hz;
  let pmp_grain : int = 2 ^ (sys_pmp_grain + 2);
  let ram_base_hi = unsigned(plat_ram_base >> 32);
  let ram_base_lo = unsigned(plat_ram_base[31 .. 0]);
  let ram_size_hi = unsigned(plat_ram_size >> 32);
  let ram_size_lo = unsigned(plat_ram_size[31 .. 0]);
  let clint_base_hi = unsigned(plat_clint_base >> 32);
  let clint_base_lo = unsigned(plat_clint_base[31 .. 0]);
  let clint_size_hi = unsigned(plat_clint_size >> 32);
  let clint_size_lo = unsigned(plat_clint_size[31 .. 0]);
  let isa_string : string = "imafdc_zicntr_zihpm"; // Default, should be adjusted based on config.
  "/dts-v1/;\n"
^ "\n"
^ "/ {\n"
^ "  #address-cells = <2>;\n"
^ "  #size-cells = <2>;\n"
^ "  compatible = \"ucbbar,spike-bare-dev\";\n"
^ "  model = \"ucbbar,spike-bare\";\n"
^ "  cpus {\n"
^ "    #address-cells = <1>;\n"
^ "    #size-cells = <0>;\n"
^ "    timebase-frequency = <" ^ dec_str(hart_hz / plat_insns_per_tick) ^ ">;\n"
^ "    CPU0: cpu@0 {\n"
^ "      device_type = \"cpu\";\n"
^ "      reg = <0>;\n"
^ "      status = \"okay\";\n"
^ "      compatible = \"riscv\";\n"
^ "      riscv,isa = \"" ^ "rv" ^ dec_str(xlen) ^ isa_string ^ "\";\n"
^ "      mmu-type = \"riscv," ^ (if xlen == 32 then "sv32" else "sv39") ^ "\";\n"
^ "      riscv,pmpregions = <" ^ dec_str(sys_pmp_count) ^ ">;\n"
^ "      riscv,pmpgranularity = <" ^ dec_str(pmp_grain) ^ ">;\n"
^ "      clock-frequency = <" ^ dec_str(hart_hz) ^ ">;\n"
^ "      CPU0_intc: interrupt-controller {\n"
^ "        #address-cells = <2>;\n"
^ "        #interrupt-cells = <1>;\n"
^ "        interrupt-controller;\n"
^ "        compatible = \"riscv,cpu-intc\";\n"
^ "      };\n"
^ "    };\n"
^ "  };\n"
^ "  memory@" ^ string_drop(hex_str(unsigned(plat_ram_base)), 2) ^ " {\n"
^ "    device_type = \"memory\";\n"
^ "    reg = <" ^ hex_str(ram_base_hi) ^ " " ^ hex_str(ram_base_lo)
^ " " ^ hex_str(ram_size_hi) ^ " " ^ hex_str(ram_size_lo) ^ ">;\n"
^ "  };\n"
^ "  soc {\n"
^ "    #address-cells = <2>;\n"
^ "    #size-cells = <2>;\n"
^ "    compatible = \"ucbbar,spike-bare-soc\", \"simple-bus\";\n"
^ "    ranges;\n"
^ "    clint@" ^ string_drop(hex_str(unsigned(plat_clint_base)), 2) ^ " {\n"
^ "      compatible = \"riscv,clint0\";\n"
^ "      interrupts-extended = <&CPU0_intc 3 &CPU0_intc 7>;\n"
^ "      reg = <" ^ hex_str(clint_base_hi) ^ " " ^ hex_str(clint_base_lo)
^ " " ^ hex_str(clint_size_hi) ^ " " ^ hex_str(clint_size_lo) ^ ">;\n"
^ "    };\n"
^ "  };\n"
^ "  htif {\n"
^ "    compatible = \"ucb,htif0\";\n"
^ "  };\n"
^ "};\n"
}
