import Std.Data.ExtHashMap.Basic

import ELFSage
import LeanRV64DExecutable
import LeanRV64DExecutable.Step
import Sail.Sail

open Register

def readElf (elfFilepath : System.FilePath) : IO (Except String RawELFFile) := do
  let bytes <- IO.FS.readBinFile elfFilepath
  pure (mkRawELFFile? bytes)

def readElf32 (elfFilepath : System.FilePath) : IO (Except String ELF32File) := do
  let bytes <- IO.FS.readBinFile elfFilepath
  match mkRawELFFile? bytes with
  | .error warning => do
    pure (.error warning)
  | .ok (.elf32 elf) => do
    -- IO.println s!"{repr elf}"
    pure (.ok elf)
  | .ok (.elf64 _elf) => do
    pure (.error "64 bit ELF file not supported")

inductive MachineBits where
  | B32
  | B64

def DEFAULT_RSTVEC := 0x00001000

def initializeMemory (_size: MachineBits) (elf : ELF64File) : Std.ExtHashMap Nat (BitVec 8) :=
  -- From: sail-riscv/c_emulator/riscv_sim.cpp
  --
  -- let RST_VEC_SIZE : UInt32 := 8
  -- let is_32bit_model := match size with
  --   | .B32 => true
  --   | .B64 => false
  -- let entry : UInt64 := sorry
  -- -- Little endian
  -- let reset_vec : List UInt32 := [
  --   0x297,                                                     -- auipc  t0,0x0
  --   (0x28593 : UInt32) + (RST_VEC_SIZE * (4 : UInt32) <<< 20), -- addi   a1, t0, &dtb
  --   0xf1402573,                                                -- csrr   a0, mhartid
  --   if is_32bit_model then 0x0182a283                          -- lw     t0,24(t0)
  --                     else 0x0182b283,                         -- ld     t0,24(t0)
  --   0x28067,                                                   -- jr     t0
  --   0,
  --   UInt64.toUInt32 (entry &&& 0xffffffff),
  --   UInt64.toUInt32 (entry >>> 32)
  -- ]
  -- let rv_rom_base := DEFAULT_RSTVEC

  let update_mem_segment mem first_addr body :=
    let addrs := Array.range' first_addr (Array.size body)
    Array.foldl (λ mem (addr, byte) =>
      if mem.contains addr then
        panic s!"Address {addr} is already written to!"
      else
        mem.insert addr byte.toBitVec
    ) mem (Array.zip addrs body)

  -- Handle interpreted_segments
  let mem'' := List.foldl (λ mem (_header, inst) =>
          -- TODO(JP): Is this address correct?
          update_mem_segment mem inst.segment_base inst.segment_body.data
        ) default elf.interpreted_segments
  -- Handle interpreted_sections
  let mem' := mem''
  -- let mem' := List.foldl (λ mem (_header, inst) =>
  --         -- TODO(JP): Is this address correct?
  --         update_mem_segment mem inst.section_offset inst.section_body.data
  --       ) mem'' elf.interpreted_sections
  -- Handle bits_and_bobs
  let mem := List.foldl (λ mem (addr, data) =>
          update_mem_segment mem addr data.data
        ) mem' elf.bits_and_bobs

  mem

def is_tohost (s : ELF64SectionHeaderTableEntry × InterpretedSection) : Bool :=
  s.snd.section_name_as_string == some ".tohost"

set_option maxRecDepth 2000000

def initializeRegisters (elf: ELF64File): SailM PUnit :=
  open LeanRV64DExecutable.Functions in
  open Sail in
  do
  let tohost_addr_m :=
    (elf.interpreted_sections.find? is_tohost).map
      (λ (s: ELF64SectionHeaderTableEntry × InterpretedSection) => s.snd.section_addr)
  match tohost_addr_m with
  | none => do
      panic ".tohost address not found in ELF"
  | some tohost_addr => do
    let tohost_addr := BitVec.ofNat 64 (tohost_addr)
    writeReg PC (elf.file_header.e_entry:UInt64).toBitVec
    writeReg htif_tohost tohost_addr
    enable_htif tohost_addr

    writeReg rvfi_instruction (← (undefined_RVFI_DII_Instruction_Packet ()))
    writeReg rvfi_inst_data (← (undefined_RVFI_DII_Execution_Packet_InstMetaData ()))
    writeReg rvfi_pc_data (← (undefined_RVFI_DII_Execution_Packet_PC ()))
    writeReg rvfi_int_data (← (undefined_RVFI_DII_Execution_Packet_Ext_Integer ()))
    writeReg rvfi_int_data_present (← (undefined_bool ()))
    writeReg rvfi_mem_data (← (undefined_RVFI_DII_Execution_Packet_Ext_MemAccess ()))
    writeReg rvfi_mem_data_present (← (undefined_bool ()))
    writeReg nextPC (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x1 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x2 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x3 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x4 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x5 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x6 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x7 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x8 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x9 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x10 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x11 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x12 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x13 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x14 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x15 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x16 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x17 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x18 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x19 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x20 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x21 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x22 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x23 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x24 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x25 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x26 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x27 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x28 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x29 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x30 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg x31 (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg cur_privilege (← (undefined_Privilege ()))
    writeReg cur_inst (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg mie (← (undefined_Minterrupts ()))
    writeReg mip (← (undefined_Minterrupts ()))
    writeReg medeleg (← (undefined_Medeleg ()))
    writeReg mideleg (← (undefined_Minterrupts ()))
    writeReg mtvec (← (undefined_Mtvec ()))
    writeReg mcause (← (undefined_Mcause ()))
    writeReg mepc (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg mtval (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg mscratch (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg scounteren (← (undefined_Counteren ()))
    writeReg mcounteren (← (undefined_Counteren ()))
    writeReg mcountinhibit (← (undefined_Counterin ()))
    writeReg mcycle (← (undefined_bitvector 64))
    writeReg mtime (← (undefined_bitvector 64))
    writeReg minstret (← (undefined_bitvector 64))
    writeReg minstret_increment (← (undefined_bool ()))
    writeReg stvec (← (undefined_Mtvec ()))
    writeReg sscratch (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg sepc (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg scause (← (undefined_Mcause ()))
    writeReg stval (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg tselect (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg vstart (← (undefined_bitvector 16))
    writeReg vl (← (undefined_bitvector ((2 ^i 2) *i 8)))
    writeReg vtype (← (undefined_Vtype ()))
    writeReg pmpcfg_n (← (undefined_vector 64 (← (undefined_Pmpcfg_ent ()))))
    writeReg pmpaddr_n (← (undefined_vector 64 (← (undefined_bitvector ((2 ^i 2) *i 8)))))
    writeReg vr0 (← (undefined_bitvector 65536))
    writeReg vr1 (← (undefined_bitvector 65536))
    writeReg vr2 (← (undefined_bitvector 65536))
    writeReg vr3 (← (undefined_bitvector 65536))
    writeReg vr4 (← (undefined_bitvector 65536))
    writeReg vr5 (← (undefined_bitvector 65536))
    writeReg vr6 (← (undefined_bitvector 65536))
    writeReg vr7 (← (undefined_bitvector 65536))
    writeReg vr8 (← (undefined_bitvector 65536))
    writeReg vr9 (← (undefined_bitvector 65536))
    writeReg vr10 (← (undefined_bitvector 65536))
    writeReg vr11 (← (undefined_bitvector 65536))
    writeReg vr12 (← (undefined_bitvector 65536))
    writeReg vr13 (← (undefined_bitvector 65536))
    writeReg vr14 (← (undefined_bitvector 65536))
    writeReg vr15 (← (undefined_bitvector 65536))
    writeReg vr16 (← (undefined_bitvector 65536))
    writeReg vr17 (← (undefined_bitvector 65536))
    writeReg vr18 (← (undefined_bitvector 65536))
    writeReg vr19 (← (undefined_bitvector 65536))
    writeReg vr20 (← (undefined_bitvector 65536))
    writeReg vr21 (← (undefined_bitvector 65536))
    writeReg vr22 (← (undefined_bitvector 65536))
    writeReg vr23 (← (undefined_bitvector 65536))
    writeReg vr24 (← (undefined_bitvector 65536))
    writeReg vr25 (← (undefined_bitvector 65536))
    writeReg vr26 (← (undefined_bitvector 65536))
    writeReg vr27 (← (undefined_bitvector 65536))
    writeReg vr28 (← (undefined_bitvector 65536))
    writeReg vr29 (← (undefined_bitvector 65536))
    writeReg vr30 (← (undefined_bitvector 65536))
    writeReg vr31 (← (undefined_bitvector 65536))
    writeReg vcsr (← (undefined_Vcsr ()))
    -- writeReg mhpmevent (← (undefined_vector 32 (← (undefined_HpmEvent ()))))
    -- writeReg mhpmcounter (← (undefined_vector 32 (← (undefined_bitvector 64))))
    -- writeReg float_result (← (undefined_bitvector 64))
    -- writeReg float_fflags (← (undefined_bitvector 64))
    writeReg f0 (← (undefined_bitvector (8 *i 8)))
    writeReg f1 (← (undefined_bitvector (8 *i 8)))
    writeReg f2 (← (undefined_bitvector (8 *i 8)))
    writeReg f3 (← (undefined_bitvector (8 *i 8)))
    writeReg f4 (← (undefined_bitvector (8 *i 8)))
    writeReg f5 (← (undefined_bitvector (8 *i 8)))
    writeReg f6 (← (undefined_bitvector (8 *i 8)))
    writeReg f7 (← (undefined_bitvector (8 *i 8)))
    writeReg f8 (← (undefined_bitvector (8 *i 8)))
    writeReg f9 (← (undefined_bitvector (8 *i 8)))
    writeReg f10 (← (undefined_bitvector (8 *i 8)))
    writeReg f11 (← (undefined_bitvector (8 *i 8)))
    writeReg f12 (← (undefined_bitvector (8 *i 8)))
    writeReg f13 (← (undefined_bitvector (8 *i 8)))
    writeReg f14 (← (undefined_bitvector (8 *i 8)))
    writeReg f15 (← (undefined_bitvector (8 *i 8)))
    writeReg f16 (← (undefined_bitvector (8 *i 8)))
    writeReg f17 (← (undefined_bitvector (8 *i 8)))
    writeReg f18 (← (undefined_bitvector (8 *i 8)))
    writeReg f19 (← (undefined_bitvector (8 *i 8)))
    writeReg f20 (← (undefined_bitvector (8 *i 8)))
    writeReg f21 (← (undefined_bitvector (8 *i 8)))
    writeReg f22 (← (undefined_bitvector (8 *i 8)))
    writeReg f23 (← (undefined_bitvector (8 *i 8)))
    writeReg f24 (← (undefined_bitvector (8 *i 8)))
    writeReg f25 (← (undefined_bitvector (8 *i 8)))
    writeReg f26 (← (undefined_bitvector (8 *i 8)))
    writeReg f27 (← (undefined_bitvector (8 *i 8)))
    writeReg f28 (← (undefined_bitvector (8 *i 8)))
    writeReg f29 (← (undefined_bitvector (8 *i 8)))
    writeReg f30 (← (undefined_bitvector (8 *i 8)))
    writeReg f31 (← (undefined_bitvector (8 *i 8)))
    writeReg fcsr (← (undefined_Fcsr ()))
    writeReg mcyclecfg (← (undefined_CountSmcntrpmf ()))
    writeReg minstretcfg (← (undefined_CountSmcntrpmf ()))
    writeReg mtimecmp (← (undefined_bitvector 64))
    writeReg stimecmp (← (undefined_bitvector 64))
    writeReg htif_done (← (undefined_bool ()))
    writeReg htif_exit_code (← (undefined_bitvector 64))
    writeReg htif_cmd_write (← (undefined_bit ()))
    writeReg htif_payload_writes (← (undefined_bitvector 4))
    writeReg satp (← (undefined_bitvector ((2 ^i 2) *i 8)))

def my_main (elf: ELF64File) : SailM Int :=
  open LeanRV64DExecutable.Functions in
  open Sail in
  do
  sailTryCatch
    (do
      init_model ""
      cycle_count ()
      -- Note: init_model resets the PC to 0, so we need to set it again
      writeReg PC (elf.file_header.e_entry:UInt64).toBitVec
      print_bits_effect "PC = " (← readReg PC)
      print_bits_effect "htif_tohost = " (← readReg htif_tohost)
      loop ()
    )
    (λ the_exception ↦ do
      match the_exception with
      | .Error_not_implemented s => (pure (print_string "Error: Not implemented: " s))
      | .Error_internal_error s => (pure (print_string "Error: internal error: " s))
      | .Error_reserved_behavior s => (pure (print_string "Error: Reserved behavior: " s))
      return 1
    )

def runElf64 (elf : ELF64File) : IO UInt32 :=
  open Sail in
  open LeanRV64DExecutable.Functions in
  do
    let mem := initializeMemory MachineBits.B64 elf
    let regs := Std.ExtDHashMap.emptyWithCapacity
    let initialState := ⟨regs, (), mem, default, default, default⟩
    let main := do
      sail_model_init ()
      initializeRegisters elf
      my_main elf
    match main.run initialState with
    | .ok res s => do
      for m in s.sailOutput do
        IO.print m
      IO.Process.exit $ UInt8.ofInt res
    | .error e s => do
      for m in s.sailOutput do
        IO.print m
      IO.eprintln s!"Error while running the sail program!: {e.print}"
      IO.Process.exit 1
