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

// Generates the value for the "riscv,isa-extensions" property
// (if `as_isa_ext == false`) or the "riscv,isa" property (otherwise).
// NOTE: The "riscv,isa" property is marked deprecated but is probably
// still widely used.

function dt_wrap(ext : extension, as_isa_ext : bool) -> string = {
  if not(hartSupports(ext)) then return "";
  let s = extensionName(ext);
  if   as_isa_ext
  then ", \"" ^ s ^ "\""
  // In "riscv,isa", single letter extensions are concatenated
  // without a separator.
  else if string_length(s) == 1
  then s
  else "_" ^ s
}

function generate_isa_string(as_isa_ext : bool) -> string = {
  (if   as_isa_ext
   then "\"i\""
   else "rv" ^ dec_str(xlen) ^ "i")

// First append the single letter extensions.

^ dt_wrap(Ext_M, as_isa_ext)
^ dt_wrap(Ext_A, as_isa_ext)
^ dt_wrap(Ext_F, as_isa_ext)
^ dt_wrap(Ext_D, as_isa_ext)
^ dt_wrap(Ext_C, as_isa_ext)
  // 'b' does not appear in the above device-tree spec for "riscv,isa-extensions".
^ (if as_isa_ext then "" else dt_wrap(Ext_B, false))
^ dt_wrap(Ext_V, as_isa_ext)
// S and U are not valid extensions in the device-tree, whereas H is.

// Append the Z extensions, ordered by category and then alphabetically.

^ dt_wrap(Ext_Zicbom, as_isa_ext)
^ dt_wrap(Ext_Zicboz, as_isa_ext)
^ dt_wrap(Ext_Zicntr, as_isa_ext)
^ dt_wrap(Ext_Zicond, as_isa_ext)
^ dt_wrap(Ext_Zicsr, as_isa_ext)
^ dt_wrap(Ext_Zifencei, as_isa_ext)
^ dt_wrap(Ext_Zihpm, as_isa_ext)
^ dt_wrap(Ext_Zimop, as_isa_ext)

// Zmmul is not a device-tree extension.

^ dt_wrap(Ext_Zaamo, as_isa_ext)
^ dt_wrap(Ext_Zabha, as_isa_ext)
^ dt_wrap(Ext_Zalrsc, as_isa_ext)
^ dt_wrap(Ext_Zawrs, as_isa_ext)

^ dt_wrap(Ext_Zfa, as_isa_ext)
^ dt_wrap(Ext_Zfh, as_isa_ext)
^ dt_wrap(Ext_Zfhmin, as_isa_ext)
^ dt_wrap(Ext_Zfinx, as_isa_ext)

// Zdinx and Zhinx{,min} are not extensions in device-tree.

^ dt_wrap(Ext_Zca, as_isa_ext)
^ dt_wrap(Ext_Zcb, as_isa_ext)
^ dt_wrap(Ext_Zcd, as_isa_ext)
^ dt_wrap(Ext_Zcf, as_isa_ext)
^ dt_wrap(Ext_Zcmop, as_isa_ext)

^ dt_wrap(Ext_Zba, as_isa_ext)
^ dt_wrap(Ext_Zbb, as_isa_ext)
^ dt_wrap(Ext_Zbc, as_isa_ext)
^ dt_wrap(Ext_Zbkb, as_isa_ext)
^ dt_wrap(Ext_Zbkc, as_isa_ext)
^ dt_wrap(Ext_Zbkx, as_isa_ext)
^ dt_wrap(Ext_Zbs, as_isa_ext)

^ dt_wrap(Ext_Zknd, as_isa_ext)
^ dt_wrap(Ext_Zkne, as_isa_ext)
^ dt_wrap(Ext_Zknh, as_isa_ext)
^ dt_wrap(Ext_Zkr, as_isa_ext)
^ dt_wrap(Ext_Zksed, as_isa_ext)
^ dt_wrap(Ext_Zksh, as_isa_ext)

^ dt_wrap(Ext_Zvbb, as_isa_ext)
^ dt_wrap(Ext_Zvbc, as_isa_ext)
^ dt_wrap(Ext_Zvkb, as_isa_ext)
^ dt_wrap(Ext_Zvkg, as_isa_ext)
^ dt_wrap(Ext_Zvkned, as_isa_ext)
^ dt_wrap(Ext_Zvknha, as_isa_ext)
^ dt_wrap(Ext_Zvknhb, as_isa_ext)
^ dt_wrap(Ext_Zvksh, as_isa_ext)

// Append the Supervisor extensions, ordered alphabetically.

^ dt_wrap(Ext_Sscofpmf, as_isa_ext)
^ dt_wrap(Ext_Sstc, as_isa_ext)
// Handle svade and svadu here when ready.
^ dt_wrap(Ext_Svinval, as_isa_ext)
^ dt_wrap(Ext_Svnapot, as_isa_ext)
^ dt_wrap(Ext_Svpbmt, as_isa_ext)

// Append the Hypervisor extensions, ordered alphabetically.

// Append the Machine mode extensions, ordered alphabetically.

// Smcntrpmf is not a device-tree extension.
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
^ "      riscv,isa = \"" ^ generate_isa_string(false) ^ "\";\n"
^ "      riscv,isa-extensions = " ^ generate_isa_string(true) ^ ";\n"
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
