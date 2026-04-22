#include <chrono>
#include <cstdint>
#include <cstdio>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include "config_utils.h"
#include "elf_loader.h"
#include "file_utils.h"
#include "jsoncons/json.hpp"
#include "riscv_callbacks_log.h"
#include "riscv_model_impl.h"
#include "rts.h"
#include "sail.h"
#include "sail_config.h"
#include "symbol_table.h"
#include "traploop_detector.h"
#include <benchmark/benchmark.h>

// This is still very much a POC. I am still testing it!

FILE *trace_log = stdout;

#include <filesystem>
namespace fs = std::filesystem;

namespace {

// Minimal state we need
std::optional<uint64_t> htif_tohost_address;
uint64_t total_insns = 0;

// Reset between runs.
void reset_bench_state() {
  htif_tohost_address = std::nullopt;
  total_insns = 0;
  g_symbols.clear();
}

uint64_t load_elf_bench(ModelImpl &model, const std::string &filename) {
  ELF elf = ELF::open(filename);

  switch (elf.architecture()) {
  case Architecture::RV32:
    if (model.zxlen != 32) {
      throw std::runtime_error("32-bit ELF not supported by RV64 model");
    }
    break;
  case Architecture::RV64:
    if (model.zxlen != 64) {
      throw std::runtime_error("64-bit ELF not supported by RV32 model");
    }
    break;
  }

  elf.load([](uint64_t address, const uint8_t *data, uint64_t length) {
    for (uint64_t i = 0; i < length; ++i) {
      write_mem(address + i, data[i]);
    }
  });

  const auto symbols = elf.symbols();
  const auto reversed_symbols = reverse_symbol_table(symbols);
  g_symbols.insert(reversed_symbols.begin(), reversed_symbols.end());

  const auto &tohost = symbols.find("tohost");
  if (tohost != symbols.end()) {
    htif_tohost_address = tohost->second;
  }

  return elf.entry();
}

void init_model_bench(ModelImpl &model, uint64_t elf_entry, const char *config_file) {
  model.zset_pc_reset_address(elf_entry);
  if (htif_tohost_address.has_value()) {
    model.zenable_htif(*htif_tohost_address);
  }
  model.zinit_model(config_file != nullptr ? config_file : "");
  model.zinit_boot_requirements(UNIT);
}

void run_model_bench(ModelImpl &model, uint64_t insn_limit, traploop_detector &loop_detector) {
  bool is_waiting = false;
  uint64_t max_wait_steps = get_config_uint64({"platform", "max_time_to_wait"});
  uint64_t wait_steps_remaining = 0;

  mach_int step_no = 0;
  uint64_t insn_cnt = 0;
  uint64_t insns_per_tick = get_config_uint64({"platform", "instructions_per_tick"});

  while (!model.zhtif_done && (insn_limit == 0 || total_insns < insn_limit)) {
    model.call_pre_step_callbacks(is_waiting);

    {
      sail_int sail_step;
      CREATE(sail_int)(&sail_step);
      CONVERT_OF(sail_int, mach_int)(&sail_step, step_no);
      is_waiting = model.ztry_step(sail_step, wait_steps_remaining == 0);
      KILL(sail_int)(&sail_step);

      if (model.have_exception) {
        // For benchmarks: just stop, let model_fini handle cleanup.
        break;
      }
      if (is_waiting) {
        if (wait_steps_remaining == 0) {
          wait_steps_remaining = max_wait_steps;
        } else {
          --wait_steps_remaining;
        }
      } else {
        wait_steps_remaining = 0;
      }
    }

    model.call_post_step_callbacks(is_waiting);

    if (!is_waiting) {
      step_no++;
      insn_cnt++;
      total_insns++;
    }

    if (model.zhtif_done) {
      if (model.zhtif_exit_code != 0) {
        throw std::runtime_error("HTIF failure: " + std::to_string(model.zhtif_exit_code));
      }
    }

    if (insn_cnt == insns_per_tick) {
      insn_cnt = 0;
      model.ztick_clock(UNIT);
    } else if (wait_steps_remaining > 0) {
      model.ztick_clock(UNIT);
    }

    if (loop_detector.loop_detected()) {
      throw std::runtime_error("possible trap loop detected");
    }
  }
}
void run_one_elf(const std::string &elf_path, uint64_t insn_limit) {
  reset_bench_state();

  ModelImpl model;

  // Use the default config baked into the model. Get rid of file I/O, JSON parsing,
  // schema validation.
  sail_config_set_string(get_default_config());
  model.set_reservation_set_size_exp(get_config_uint64({"platform", "reservation_set_size_exp"}));

  model.model_init();

  traploop_detector loop_detector;
  model.register_callback(&loop_detector);

  uint64_t entry = load_elf_bench(model, elf_path);
  init_model_bench(model, entry, "");

  run_model_bench(model, insn_limit, loop_detector);

  model.model_fini();
}

} // namespace

int main(int argc, char **argv) {
  for (const auto &entry : fs::directory_iterator("build/test")) {
    if (!entry.is_directory()) {
      continue;
    }
    auto test_dir = entry.path() / "riscv-tests";
    if (!fs::exists(test_dir)) {
      continue;
    }
    // For testing purposes, limit execution to 10 tests for now due to extremely slow runtime of CodSpeed in CI.
    int count = 0;
    for (const auto &elf : fs::directory_iterator(test_dir)) {
      if (count++ >= 10) {
        break;
      }
      if (!elf.is_regular_file()) {
        continue;
      }
      // For now test only rv64
      std::string name = elf.path().filename().string();
      if (name.rfind("rv64", 0) != 0) {
        continue;
      }
      std::string path = elf.path().string();
      std::string bench_name = "riscv-tests::" + name;
      benchmark::RegisterBenchmark(bench_name.c_str(), [path](benchmark::State &s) {
        for (auto _ : s) {
          run_one_elf(path, 0);
          benchmark::ClobberMemory();
        }
      })->Unit(benchmark::kMillisecond);
    }
  }
  benchmark::Initialize(&argc, argv);
  benchmark::RunSpecifiedBenchmarks();
  benchmark::Shutdown();
  return 0;
}
