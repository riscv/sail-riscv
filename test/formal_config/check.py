"""Check the production formal-backend build graph without compiling the model.

The Sail stub records Lean invocations and creates only the declared output file.
This tests configuration selection, output identity and dependency invalidation;
it is not a test of generated Lean semantics.
"""

import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BACKENDS = ("smt", "rmem", "rocq", "lem", "lean", "lean_executable")


def run(*args: str) -> str:
    result = subprocess.run(args, text=True, capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError(f"{shlex.join(args)}\n{result.stdout}\n{result.stderr}")
    return result.stdout


def check(directory: Path, overrides: tuple[int, ...]) -> None:
    source = directory / "source"
    source.mkdir(parents=True)
    for name in ("model", "config", "handwritten_support"):
        (source / name).symlink_to(ROOT / name, target_is_directory=True)
    (source / "fixture.sail").write_text("// Build-graph dependency only.\n")
    stub = source / "sail_stub.py"
    stub.write_text(
        f"#!{sys.executable}\n"
        "import json, pathlib, sys\n"
        "args = sys.argv[1:]\n"
        'if "--list-files-separated" in args:\n'
        '    print(pathlib.Path(__file__).with_name("fixture.sail"))\n'
        "else:\n"
        '    assert "--lean" in args, args\n'
        '    output = pathlib.Path(args[args.index("--lean-output-dir") + 1])\n'
        '    name = args[args.index("-o") + 1]\n'
        '    leaf = name.replace("_executable", "Executable").replace("_", "")\n'
        "    (output / name).mkdir(parents=True, exist_ok=True)\n"
        '    (output / name / (leaf + ".lean")).write_text("-- Stub output.\\n")\n'
        '    with (output / "calls.jsonl").open("a") as log:\n'
        '        log.write(json.dumps(args) + "\\n")\n'
    )
    stub.chmod(0o755)
    (source / "CMakeLists.txt").write_text(
        "cmake_minimum_required(VERSION 3.20)\n"
        "project(formal_config_test NONE)\n"
        "set(CMAKE_INSTALL_LIBDIR lib)\n"
        "set(SAIL_REQUIRED_VER 0)\n"
        'set(SAIL_BIN "${CMAKE_CURRENT_SOURCE_DIR}/sail_stub.py")\n'
        "add_subdirectory(config)\n"
        "add_subdirectory(model)\n"
    )
    build = directory / "build"
    configs = {
        xlen: build / "config" / f"rv{xlen}d_v256_e{xlen}.json" for xlen in (32, 64)
    }
    flags = []
    for xlen in overrides:
        configs[xlen] = directory / f"custom RV{xlen} config.json"
        configs[xlen].write_text("{}\n")
        flags.append(f"-DSAIL_FORMAL_CONFIG_RV{xlen}D:FILEPATH={configs[xlen]}")
    run("cmake", "-S", str(source), "-B", str(build), "-G", "Unix Makefiles", *flags)
    for xlen in (32, 64):
        for backend in BACKENDS:
            target = f"generated_{backend}_rv{xlen}d"
            rules = build / "model" / "CMakeFiles" / f"{target}.dir" / "build.make"
            commands = [
                shlex.split(line.strip())
                for line in rules.read_text().splitlines()
                if line.startswith("\t") and "sail_stub.py" in line
            ]
            assert commands, target
            for command in commands:
                assert command[command.index("--config") + 1] == str(configs[xlen]), (
                    command
                )
                if backend.startswith("lean"):
                    suffix = "_executable" if backend == "lean_executable" else ""
                    assert command[command.index("-o") + 1] == f"Lean_RV{xlen}D{suffix}"

    targets = ("generated_lean_rv32d", "generated_lean_rv64d")
    run("cmake", "--build", str(build), "--target", *targets)
    calls = build / "model" / "calls.jsonl"
    before = calls.read_text().splitlines()
    assert len(before) == 2
    run("cmake", "--build", str(build), "--target", *targets)
    assert calls.read_text().splitlines() == before, "Unchanged inputs rebuilt"

    # Make the RV64 configuration newer than its output without a timing-dependent sleep.
    output = build / "model" / "Lean_RV64D" / "LeanRV64D.lean"
    newer = output.stat().st_mtime_ns + 2_000_000_000
    os.utime(configs[64], ns=(newer, newer))
    run("cmake", "--build", str(build), "--target", *targets)
    after = calls.read_text().splitlines()
    assert len(after) == 3, (
        "Configuration changes must regenerate only their architecture"
    )
    last = json.loads(after[-1])
    assert last[last.index("-o") + 1] == "Lean_RV64D"
    assert last[last.index("--config") + 1] == str(configs[64])


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="sail-formal-config-") as temporary:
        for name, overrides in (("default", ()), ("rv64", (64,)), ("both", (32, 64))):
            check(Path(temporary) / name, overrides)
            print(
                f"{name}: configuration, model identity and rebuild checks passed",
                flush=True,
            )


if __name__ == "__main__":
    main()
