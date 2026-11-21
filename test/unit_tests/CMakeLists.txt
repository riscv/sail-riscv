# Sail unit tests. Currently this only runs the default config (RV64D).

add_executable(unit_tests
    "main_unit_tests.cpp"
)

target_link_libraries(unit_tests
    PRIVATE riscv_model default_config
)

# The PGO training does not run the unit tests, so GCC has no profile for them.
target_compile_options(unit_tests PRIVATE $<$<CXX_COMPILER_ID:GNU>:-Wno-missing-profile>)

add_test(
    NAME "unit_tests"
    COMMAND $<TARGET_FILE:unit_tests>
)

set_property(TEST "unit_tests"
    PROPERTY LABELS TestAtBuildTime
)
