add_custom_command(
  DEPENDS
      generated_lean_executable_rv64d
      ${CMAKE_CURRENT_SOURCE_DIR}/LeanRiscv.lean
      ${CMAKE_CURRENT_SOURCE_DIR}/Main.lean
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/.lake/build/bin/lean_riscv_emulator
  COMMENT "Building the Lean RISC-V 64-bit emulator."
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND lake update
  COMMAND lake build lean_riscv_emulator
)

add_custom_target(build_lean_emulator
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.lake/build/bin/lean_riscv_emulator
)
