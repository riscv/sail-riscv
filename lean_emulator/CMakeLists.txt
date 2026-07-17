configure_file("lakefile.toml.in" "${CMAKE_CURRENT_SOURCE_DIR}/lakefile.toml" @ONLY)
configure_file("lake-manifest.json.in" "${CMAKE_CURRENT_SOURCE_DIR}/lake-manifest.json" @ONLY)

add_custom_command(
  OUTPUT ${CMAKE_BINARY_DIR}/lean-emulator-build
  COMMENT "Creating symlink for the Lean emulator output."
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/lean-emulator-build
  COMMAND ${CMAKE_COMMAND} -E create_symlink
          ${CMAKE_BINARY_DIR}/lean-emulator-build
          ${CMAKE_SOURCE_DIR}/lean_emulator/.lake
  USES_TERMINAL
)

add_custom_command(
  DEPENDS
      generated_lean_executable_rv64d
      ${CMAKE_BINARY_DIR}/lean-emulator-build
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
