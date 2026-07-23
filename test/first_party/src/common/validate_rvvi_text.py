#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
#
# Validate RVVI-TEXT trace output from the Sail RISC-V simulator.
#
# Runs the simulator with --trace-rvvi-text, validates the trace with
# the official rvviTextChecker.py, and checks that the trace contains
# expected RVVI-TEXT elements (RET, X register change, C CSR change,
# MEM data access, and optionally TRAP).

import argparse
import os
import re
import subprocess
import sys
import tempfile


def run_simulator(args, trace_file):
    cmd = [
        args.sim,
        "--config", args.config,
        "--config-override", args.config_override,
        "--trace-rvvi-text",
        "--trace-output", trace_file,
        "--inst-limit", str(args.inst_limit),
        args.elf,
    ]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=120)


def main():
    parser = argparse.ArgumentParser(
        description="Validate RVVI-TEXT trace output"
    )
    parser.add_argument("--sim", required=True, help="Path to sail_riscv_sim")
    parser.add_argument("--elf", required=True, help="Path to test ELF")
    parser.add_argument("--config", required=True, help="Simulator config JSON")
    parser.add_argument("--config-override", required=True,
                        help="Config override JSON")
    parser.add_argument("--rvvi-checker", required=True,
                        help="Path to rvviTextChecker.py")
    parser.add_argument("--inst-limit", type=int, default=10000,
                        help="Max instructions to run")
    parser.add_argument("--expect-trap", action="store_true",
                        help="Require at least one TRAP event")
    parser.add_argument("--expect-mem", action="store_true",
                        help="Require at least one MEM element")
    args = parser.parse_args()

    trace_file = tempfile.mktemp(suffix=".rvvi")
    try:
        # Run simulator
        sim = run_simulator(args, trace_file)
        if sim.returncode != 0:
            print(f"FAIL: simulator exited with code {sim.returncode}",
                  file=sys.stderr)
            if sim.stdout:
                print(f"--- simulator stdout ---\n{sim.stdout}", file=sys.stderr)
            if sim.stderr:
                print(f"--- simulator stderr ---\n{sim.stderr}", file=sys.stderr)
            return 1

        if not os.path.exists(trace_file):
            print("FAIL: simulator produced no trace file", file=sys.stderr)
            return 1

        with open(trace_file) as f:
            trace = f.read()

        # Step 1: Validate with rvviTextChecker.py
        checker = subprocess.run(
            [sys.executable, args.rvvi_checker, trace_file],
            capture_output=True, text=True, timeout=30
        )
        if checker.returncode != 0:
            print("FAIL: rvviTextChecker.py rejected the trace", file=sys.stderr)
            if checker.stderr:
                print(checker.stderr, file=sys.stderr)
            return 1
        print(f"rvviTextChecker: {checker.stdout.strip()}")

        # Step 2: Content checks — verify expected RVVI-TEXT elements
        checks = [
            (r'^VERSION \d+ \d+', "VERSION header"),
            (r'^VENDOR ', "VENDOR header"),
            (r'^PARAMS \d+ ', "PARAMS header"),
            (r'\bRET 0x[0-9a-fA-F]+ 0x[0-9a-fA-F]+', "RET instruction event"),
            (r'\bX \d+ 0x[0-9a-fA-F]+', "X register change"),
            (r'\bC 0x[0-9a-fA-F]+ 0x[0-9a-fA-F]+', "C CSR change"),
            (r'\bMODE 0x[0-9a-fA-F]+', "MODE element"),
        ]

        if args.expect_trap:
            checks.append((r'\bTRAP 0x[0-9a-fA-F]+ 0x[0-9a-fA-F]+',
                          "TRAP event"))

        if args.expect_mem:
            checks.append((r'\bMEM D \d+ 0x[0-9a-fA-F]+ 0x[0-9a-fA-F]+ \d+',
                          "MEM data access element"))

        failed = []
        for pattern, name in checks:
            if not re.search(pattern, trace, re.MULTILINE):
                failed.append((name, pattern))

        if failed:
            print("FAIL: missing expected RVVI-TEXT content:", file=sys.stderr)
            for name, pattern in failed:
                print(f"  - {name} (pattern {pattern!r})", file=sys.stderr)

            # Show first few lines for debugging
            print("\n--- Trace (first 10 lines) ---", file=sys.stderr)
            for j, line in enumerate(trace.split('\n')):
                if j >= 10:
                    break
                print(f"  {line}", file=sys.stderr)
            return 1

        print("PASS: RVVI-TEXT trace is valid and contains expected content")
        return 0

    finally:
        if os.path.exists(trace_file):
            os.unlink(trace_file)


if __name__ == "__main__":
    sys.exit(main())
