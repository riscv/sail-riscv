add_custom_target(test_lean_emulator
    COMMAND cmake -P "${CMAKE_CURRENT_SOURCE_DIR}/test_lean_emulator.cmake"
)

add_dependencies(test_lean_emulator generated_lean_executable_rv64d)
