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
  let prefix : string = match fmt {
    Canonical_Lowercase => "rv" ^ dec_str(xlen) ^ "i",
    DeviceTree_ISA_Extensions => "\"i\"",
  };

  let extensions = [
  // First append the single letter extensions.
    Ext_M,
    Ext_A,
    Ext_F,
    Ext_D,
    // Ext_G,
    // Ext_Q,
    Ext_C,
    Ext_B,
    // Ext_P,
    Ext_V,
    //Ext_H,
  // S and U are not valid extensions in the device-tree, whereas H is.

  // Append the Z extensions, ordered by category and then alphabetically.
  // Zi
    Ext_Zicbom,
    Ext_Zicboz,
    Ext_Zicntr,
    Ext_Zicond,
    Ext_Zicsr,
    Ext_Zifencei,
    Ext_Zihpm,
    Ext_Zimop,

  // Zm
    Ext_Zmmul,

  // Za
    Ext_Zaamo,
    Ext_Zabha,
    Ext_Zalrsc,
    Ext_Zawrs,

  // Zf, Zd, and Zq
    Ext_Zfa,
    Ext_Zfh,
    Ext_Zfhmin,
    Ext_Zfinx,
    Ext_Zdinx,
    Ext_Zhinx,
    Ext_Zhinxmin,

  // Zc
    Ext_Zca,
    Ext_Zcb,
    Ext_Zcd,
    Ext_Zcf,
    Ext_Zcmop,

  // Zb
    Ext_Zba,
    Ext_Zbb,
    Ext_Zbc,
    Ext_Zbkb,
    Ext_Zbkc,
    Ext_Zbkx,
    Ext_Zbs,

  // Zk
    Ext_Zknd,
    Ext_Zkne,
    Ext_Zknh,
    Ext_Zkr,
    Ext_Zksed,
    Ext_Zksh,

  // Zv
    Ext_Zvbb,
    Ext_Zvbc,
    Ext_Zvkb,
    Ext_Zvkg,
    Ext_Zvkned,
    Ext_Zvknha,
    Ext_Zvknhb,
    Ext_Zvksh,

  // Append the Supervisor extensions, ordered alphabetically.
    Ext_Sscofpmf,
    Ext_Sstc,
    // Ext_svade
    // Ext_svadu
    Ext_Svinval,
    Ext_Svnapot,
    Ext_Svpbmt,

  // Append the Hypervisor extensions, ordered alphabetically.

  // Append the Machine mode extensions, ordered alphabetically.
    Ext_Smcntrpmf,
  ];

  var isa_string : string = prefix;
  foreach (i from (length(extensions) - 1) downto 0) {
    isa_string = isa_string ^ ext_wrap(extensions[i], fmt);
  };
  isa_string
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
