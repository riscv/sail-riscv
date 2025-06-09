/*=======================================================================================*/
/*  This Sail RISC-V architecture model, comprising all files and                        */
/*  directories except where otherwise noted is subject the BSD                          */
/*  two-clause license in the LICENSE file.                                              */
/*                                                                                       */
/*  SPDX-License-Identifier: BSD-2-Clause                                                */
/*=======================================================================================*/

// Identifies the largest MMU address translation mode supported by this hart.
function mmu_type() -> string = {
  if xlen == 32 then {
    if hartSupports(Ext_Sv32) then "sv32" else "none"
  } else {
    assert(xlen == 64);
    if hartSupports(Ext_Sv57) then "sv57"
    else if hartSupports(Ext_Sv48) then "sv48"
    else if hartSupports(Ext_Sv39) then "sv39"
    else "none"
  }
}

// Generators for Device-Tree source corresponding to the model
// configuration.
// NOTE: These assume a valid model configuration.

// Generates the value for the "riscv,isa-base" property.
function generate_isa_base() -> string = {
  "rv" ^ dec_str(xlen) ^ "i"
}

// Generates an ISA string in the appropriate format.

enum ISA_Format = {Canonical_Lowercase, DeviceTree_ISA_Extensions}

/* Some notes from the "ISA Extension Naming Convections" section of
   the manual:

  . The first letter following the "Z" conventionally indicates the
    most closely related alphabetical extension category,
    IMAFDQLCBKJTPVH.  If multiple "Z" extensions are named, they
    should be ordered first by category, then alphabetically within a
    category—for example, "Zicsr_Zifencei_Ztso".

  . All multi-letter extensions, including those with the "Z" prefix, must be
    separated from other multi-letter extensions by an underscore, e.g.,
    "RV32IMACZicsr_Zifencei".

  . Standard supervisor-level extensions (prefixed with either 'Ss' or
    'Sv') should be listed after standard unprivileged extensions, and
    like other multi-letter extensions, must be separated from other
    multi-letter extensions by an underscore. If multiple
    supervisor-level extensions are listed, they should be ordered
    alphabetically.

  . Standard machine-level extensions (prefixed with the letters "Sm")
    should be listed after standard lesser-privileged extensions, and
    like other multi-letter extensions, must be separated from other
    multi-letter extensions by an underscore. If multiple
    machine-level extensions are listed, they should be ordered
    alphabetically.

  Once the Sail configuration supports extension version numbers, we could
  add them to the generated isa string.

  The device-tree specification for the ISA string is at:
  https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Documentation/devicetree/bindings/riscv/extensions.yaml

  As the above document uses lower-case, the generator below does too.
*/

function ext_wrap(ext : extension, fmt : ISA_Format) -> string = {
  if not(hartSupports(ext)) then return "";
  let s = extensionName(ext);
  match fmt {
    Canonical_Lowercase =>
      // Single letter extensions are concatenated without a separator.
      if string_length(s) == 1 then s else "_" ^ s,
    DeviceTree_ISA_Extensions =>
      ", \"" ^ s ^ "\"",
  }
}

function generate_isa_string(fmt : ISA_Format) -> string = {
  // The Sail compiler blows up if this string is constructed in one go.
  // Build it up in pieces.
  let prefix : string = match fmt {
    Canonical_Lowercase => "rv" ^ dec_str(xlen) ^ "i",
    DeviceTree_ISA_Extensions => "\"i\"",
  };

  // First append the single letter extensions.

  let singles = ""
  ^ ext_wrap(Ext_M, fmt)
  ^ ext_wrap(Ext_A, fmt)
  ^ ext_wrap(Ext_F, fmt)
  ^ ext_wrap(Ext_D, fmt)
  ^ ext_wrap(Ext_C, fmt)
  ^ ext_wrap(Ext_B, fmt)
  ^ ext_wrap(Ext_V, fmt);
  // S and U are not valid extensions in the device-tree, whereas H is.

  // Append the Z extensions, ordered by category and then alphabetically.
  let zi_exts = ""
  ^ ext_wrap(Ext_Zicbom, fmt)
  ^ ext_wrap(Ext_Zicboz, fmt)
  ^ ext_wrap(Ext_Zicntr, fmt)
  ^ ext_wrap(Ext_Zicond, fmt)
  ^ ext_wrap(Ext_Zicsr, fmt)
  ^ ext_wrap(Ext_Zifencei, fmt)
  ^ ext_wrap(Ext_Zihpm, fmt)
  ^ ext_wrap(Ext_Zimop, fmt)

  ^ ext_wrap(Ext_Zmmul, fmt);

  let za_exts = ""
  ^ ext_wrap(Ext_Zaamo, fmt)
  ^ ext_wrap(Ext_Zabha, fmt)
  ^ ext_wrap(Ext_Zalrsc, fmt)
  ^ ext_wrap(Ext_Zawrs, fmt);

  let zf_exts = ""
  ^ ext_wrap(Ext_Zfa, fmt)
  ^ ext_wrap(Ext_Zfh, fmt)
  ^ ext_wrap(Ext_Zfhmin, fmt)
  ^ ext_wrap(Ext_Zfinx, fmt)
  ^ ext_wrap(Ext_Zdinx, fmt)
  ^ ext_wrap(Ext_Zhinx, fmt)
  ^ ext_wrap(Ext_Zhinxmin, fmt);

  let zc_exts = ""
  ^ ext_wrap(Ext_Zca, fmt)
  ^ ext_wrap(Ext_Zcb, fmt)
  ^ ext_wrap(Ext_Zcd, fmt)
  ^ ext_wrap(Ext_Zcf, fmt)
  ^ ext_wrap(Ext_Zcmop, fmt);

  let zb_exts = ""
  ^ ext_wrap(Ext_Zba, fmt)
  ^ ext_wrap(Ext_Zbb, fmt)
  ^ ext_wrap(Ext_Zbc, fmt)
  ^ ext_wrap(Ext_Zbkb, fmt)
  ^ ext_wrap(Ext_Zbkc, fmt)
  ^ ext_wrap(Ext_Zbkx, fmt)
  ^ ext_wrap(Ext_Zbs, fmt);

  let zk_exts = ""
  ^ ext_wrap(Ext_Zknd, fmt)
  ^ ext_wrap(Ext_Zkne, fmt)
  ^ ext_wrap(Ext_Zknh, fmt)
  ^ ext_wrap(Ext_Zkr, fmt)
  ^ ext_wrap(Ext_Zksed, fmt)
  ^ ext_wrap(Ext_Zksh, fmt);

  let zv_exts = ""
  ^ ext_wrap(Ext_Zvbb, fmt)
  ^ ext_wrap(Ext_Zvbc, fmt)
  ^ ext_wrap(Ext_Zvkb, fmt)
  ^ ext_wrap(Ext_Zvkg, fmt)
  ^ ext_wrap(Ext_Zvkned, fmt)
  ^ ext_wrap(Ext_Zvknha, fmt)
  ^ ext_wrap(Ext_Zvknhb, fmt)
  ^ ext_wrap(Ext_Zvksh, fmt);

  // Append the Supervisor extensions, ordered alphabetically.

  let s_exts = ""
  ^ ext_wrap(Ext_Sscofpmf, fmt)
  ^ ext_wrap(Ext_Sstc, fmt)
  // Handle svade and svadu here when ready.
  ^ ext_wrap(Ext_Svinval, fmt)
  ^ ext_wrap(Ext_Svnapot, fmt)
  ^ ext_wrap(Ext_Svpbmt, fmt);

  // Append the Hypervisor extensions, ordered alphabetically.

  // Append the Machine mode extensions, ordered alphabetically.

  let m_exts = ""
  ^ ext_wrap(Ext_Smcntrpmf, fmt);

  prefix ^ singles
  ^ zi_exts ^ za_exts ^ zf_exts ^ zc_exts ^ zb_exts ^ zk_exts ^ zv_exts
  ^ s_exts ^ m_exts
}

// Generates the full Device-Tree configuration for the model.

function generate_dts() -> string = {
  let clock_freq : int = config platform.clock_frequency;
  let ram_base_hi = unsigned(plat_ram_base >> 32);
  let ram_base_lo = unsigned(plat_ram_base[31 .. 0]);
  let ram_size_hi = unsigned(plat_ram_size >> 32);
  let ram_size_lo = unsigned(plat_ram_size[31 .. 0]);
  let clint_base_hi = unsigned(plat_clint_base >> 32);
  let clint_base_lo = unsigned(plat_clint_base[31 .. 0]);
  let clint_size_hi = unsigned(plat_clint_size >> 32);
  let clint_size_lo = unsigned(plat_clint_size[31 .. 0]);

  // `hex_str` is used for the unit-addresses of the `memory@` and `clint@` nodes
  // instead of `hex_bits_str` since they cannot have leading zeros.  These addresses
  // also cannot have a '0x' prefix which explains the `string_drop(., 2)`.

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
^ "    timebase-frequency = <" ^ dec_str(clock_freq / plat_insns_per_tick) ^ ">;\n"
^ "    CPU0: cpu@0 {\n"
^ "      device_type = \"cpu\";\n"
^ "      reg = <0>;\n"
^ "      status = \"okay\";\n"
^ "      compatible = \"riscv\";\n"
^ "      riscv,isa-base = \"" ^ generate_isa_base() ^ "\";\n"
         // NOTE: The "riscv,isa" property is marked deprecated but is
         // probably still widely used.
^ "      riscv,isa = \"" ^ generate_isa_string(Canonical_Lowercase) ^ "\";\n"
^ "      riscv,isa-extensions = " ^ generate_isa_string(DeviceTree_ISA_Extensions) ^ ";\n"
^ "      mmu-type = \"riscv," ^ mmu_type() ^ "\";\n"
^ "      clock-frequency = <" ^ dec_str(clock_freq) ^ ">;\n"
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
