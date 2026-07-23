#!/usr/bin/env python3
# Compare --trace-rvvi-text output against a golden file.
# Runs the simulator twice (determinism), then the syntax checker and linter.

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile


def run_sim(args, trace_path: str) -> subprocess.CompletedProcess:
    cmd = [
        args.sim,
        "--config", args.config,
        "--config-override", args.config_override,
        "--trace-rvvi-text",
        "--trace-output", trace_path,
        "--inst-limit", str(args.inst_limit),
        args.elf,
    ]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=120)


def run_validator(tool: str, trace_path: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, tool, trace_path], capture_output=True, text=True, timeout=30
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Diff RVVI-TEXT output against a golden trace")
    parser.add_argument("--sim", required=True)
    parser.add_argument("--elf", required=True)
    parser.add_argument("--config", required=True)
    parser.add_argument("--config-override", required=True)
    parser.add_argument("--inst-limit", type=int, default=10000)
    parser.add_argument("--golden", required=True)
    parser.add_argument("--checker", required=True)
    parser.add_argument("--lint", required=True)
    args = parser.parse_args()

    with tempfile.TemporaryDirectory() as tmp:
        first = os.path.join(tmp, "first.rvvi")
        second = os.path.join(tmp, "second.rvvi")
        r1 = run_sim(args, first)
        if r1.returncode != 0:
            print(f"FAIL: simulator exited {r1.returncode}", file=sys.stderr)
            print(r1.stderr, file=sys.stderr)
            return 1
        r2 = run_sim(args, second)
        if r2.returncode != 0:
            print(f"FAIL: second simulator run exited {r2.returncode}", file=sys.stderr)
            return 1
        with open(first, encoding="utf-8") as f:
            a = f.read()
        with open(second, encoding="utf-8") as f:
            b = f.read()
        if a != b:
            print("FAIL: RVVI-TEXT is not deterministic across two runs", file=sys.stderr)
            return 1

        checker = run_validator(args.checker, first)
        if checker.returncode != 0:
            print("FAIL: rvviTextChecker.py rejected the trace", file=sys.stderr)
            if checker.stderr:
                print(checker.stderr, file=sys.stderr)
            return 1

        lint = run_validator(args.lint, first)
        if lint.returncode != 0:
            print("FAIL: lint_rvvi_trace.py rejected the trace", file=sys.stderr)
            if lint.stderr:
                print(lint.stderr, file=sys.stderr)
            return 1

        with open(args.golden, encoding="utf-8") as f:
            golden = f.read()
        if a != golden:
            print("FAIL: RVVI-TEXT does not match golden", file=sys.stderr)
            a_lines = a.splitlines()
            g_lines = golden.splitlines()
            print(f"  generated {len(a_lines)} lines, golden {len(g_lines)} lines", file=sys.stderr)
            for i, (x, y) in enumerate(zip(a_lines, g_lines), 1):
                if x != y:
                    print(f"  first diff at line {i}:", file=sys.stderr)
                    print(f"    golden: {y}", file=sys.stderr)
                    print(f"    got:    {x}", file=sys.stderr)
                    break
            else:
                if len(a_lines) != len(g_lines):
                    print("  traces share a common prefix but differ in length", file=sys.stderr)
            return 1

    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
