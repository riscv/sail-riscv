import LeanRiscv

def main (args : List String) : IO UInt32 := do
  if args.length != 2 then do
    IO.println "usage: run-riscv-lean <elf_file>"
    pure 255
  else do
    match (← readElf args[1]!) with
    | Except.error err => do
      IO.println "Failed to parse ELF file:"
      IO.println err
      pure 255
    | Except.ok (.elf64 elf) => runElf64 elf
    | Except.ok (.elf32 _elf) => do
      -- runElf32 elf
      IO.println "32 bit ELF file not supported"
      pure 255
