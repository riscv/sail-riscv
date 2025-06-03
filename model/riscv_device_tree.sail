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

function dt_wrap(s : string, as_isa_ext : bool) -> string = {
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

^ (if hartSupports(Ext_M) then dt_wrap("m", as_isa_ext) else "")
^ (if hartSupports(Ext_A) then dt_wrap("a", as_isa_ext) else "")
^ (if hartSupports(Ext_F) then dt_wrap("f", as_isa_ext) else "")
^ (if hartSupports(Ext_D) then dt_wrap("d", as_isa_ext) else "")
^ (if hartSupports(Ext_C) then dt_wrap("c", as_isa_ext) else "")
  // 'b' does not appear in the above device-tree spec for "riscv,isa-extensions".
^ (if hartSupports(Ext_B) & not(as_isa_ext) then "b"   else "")
^ (if hartSupports(Ext_V) then dt_wrap("v", as_isa_ext) else "")
// S and U are not valid extensions in the device-tree, whereas H is.

// Append the Z extensions, ordered by category and then alphabetically.

^ (if hartSupports(Ext_Zicbom) then dt_wrap("zicbom", as_isa_ext) else "")
^ (if hartSupports(Ext_Zicboz) then dt_wrap("zicboz", as_isa_ext) else "")
^ (if hartSupports(Ext_Zicntr) then dt_wrap("zicntr", as_isa_ext) else "")
^ (if hartSupports(Ext_Zicond) then dt_wrap("zicond", as_isa_ext) else "")
^ (if hartSupports(Ext_Zicsr)  then dt_wrap("zicsr", as_isa_ext)  else "")
^ (if hartSupports(Ext_Zifencei) then dt_wrap("zifencei", as_isa_ext)  else "")
^ (if hartSupports(Ext_Zihpm)  then dt_wrap("zihpm", as_isa_ext)  else "")
^ (if hartSupports(Ext_Zimop)  then dt_wrap("zimop", as_isa_ext)  else "")

// Zmmul is not a device-tree extension.

^ (if hartSupports(Ext_Zaamo)  then dt_wrap("zaamo", as_isa_ext)  else "")
^ (if hartSupports(Ext_Zabha)  then dt_wrap("zabha", as_isa_ext)  else "")
^ (if hartSupports(Ext_Zalrsc) then dt_wrap("zalrsc", as_isa_ext) else "")
^ (if hartSupports(Ext_Zawrs)  then dt_wrap("zawrs", as_isa_ext)  else "")

^ (if hartSupports(Ext_Zfa)    then dt_wrap("zfa", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zfh)    then dt_wrap("zfh", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zfhmin) then dt_wrap("zfhmin", as_isa_ext) else "")
^ (if hartSupports(Ext_Zfinx)  then dt_wrap("zfinx", as_isa_ext)  else "")

// Zdinx and Zhinx{,min} are not extensions in device-tree.

^ (if hartSupports(Ext_Zca)    then dt_wrap("zca", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zcb)    then dt_wrap("zcb", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zcd)    then dt_wrap("zcd", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zcf)    then dt_wrap("zcf", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zcmop)  then dt_wrap("zcmop", as_isa_ext)  else "")

^ (if hartSupports(Ext_Zba)    then dt_wrap("zba", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zbb)    then dt_wrap("zbb", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zbc)    then dt_wrap("zbc", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zbkb)   then dt_wrap("zbkb", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zbkc)   then dt_wrap("zbkc", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zbkx)   then dt_wrap("zbkx", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zbs)    then dt_wrap("zbs", as_isa_ext)    else "")

^ (if hartSupports(Ext_Zknd)   then dt_wrap("zknd", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zkne)   then dt_wrap("zkne", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zknh)   then dt_wrap("zknh", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zkr)    then dt_wrap("zkr", as_isa_ext)    else "")
^ (if hartSupports(Ext_Zksed)  then dt_wrap("zksed", as_isa_ext)  else "")
^ (if hartSupports(Ext_Zksh)   then dt_wrap("zksh", as_isa_ext)   else "")

^ (if hartSupports(Ext_Zvbb)   then dt_wrap("zvbb", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zvbc)   then dt_wrap("zvbc", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zvkb)   then dt_wrap("zvkb", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zvkg)   then dt_wrap("zvkg", as_isa_ext)   else "")
^ (if hartSupports(Ext_Zvkned) then dt_wrap("zvkned", as_isa_ext) else "")
^ (if hartSupports(Ext_Zvknha) then dt_wrap("zvknha", as_isa_ext) else "")
^ (if hartSupports(Ext_Zvknhb) then dt_wrap("zvknhb", as_isa_ext) else "")
^ (if hartSupports(Ext_Zvksh)  then dt_wrap("zvksh", as_isa_ext)  else "")

// Append the Supervisor extensions, ordered alphabetically.

^ (if hartSupports(Ext_Sscofpmf)  then dt_wrap("sscofpmf", as_isa_ext)  else "")
^ (if hartSupports(Ext_Sstc)      then dt_wrap("sstc", as_isa_ext)      else "")
// Handle svade and svadu here when ready.
^ (if hartSupports(Ext_Svinval)   then dt_wrap("svinval", as_isa_ext)   else "")
^ (if hartSupports(Ext_Svnapot)   then dt_wrap("svnapot", as_isa_ext)   else "")
^ (if hartSupports(Ext_Svpbmt)    then dt_wrap("svpbmt", as_isa_ext)    else "")

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
