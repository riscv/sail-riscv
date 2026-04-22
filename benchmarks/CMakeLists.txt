include(FetchContent)
set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
set(BENCHMARK_DOWNLOAD_DEPENDENCIES ON)
FetchContent_Declare(
    google_benchmark
    GIT_REPOSITORY https://github.com/CodSpeedHQ/codspeed-cpp
    SOURCE_SUBDIR google_benchmark
    GIT_TAG main
)
FetchContent_MakeAvailable(google_benchmark)

add_executable(sail_riscv_bench
    bench_main.cpp
    ${CMAKE_SOURCE_DIR}/c_emulator/traploop_detector.cpp
)

target_link_libraries(sail_riscv_bench
    PRIVATE benchmark::benchmark riscv_model
)

add_dependencies(sail_riscv_bench generated_sail_riscv_model)
