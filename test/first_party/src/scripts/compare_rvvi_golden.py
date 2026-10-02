#!/usr/bin/env python3
# Run --trace-rvvi-text twice, check grammar/lint, then match the main window
# against a TRACE-field golden file.

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from match_rvvi_trace import match_text


def run_sim(args, trace_path: str) -> subprocess.CompletedProcess:
    cmd = [
        args.sim,
        "--config",
        args.config,
        "--config-override",
        args.config_override,
        "--trace-rvvi-text",
        "--trace-output",
        trace_path,
        "--inst-limit",
        str(args.inst_limit),
        args.elf,
    ]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=120, check=False)


def run_validator(tool: str, trace_path: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, tool, trace_path],
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate RVVI-TEXT and match TRACE fields in main"
    )
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
            print(
                "FAIL: RVVI-TEXT is not deterministic across two runs", file=sys.stderr
            )
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
            golden = json.load(f)
        errors = match_text(a, golden, args.elf)
        if errors:
            print("FAIL: TRACE field mismatch in main window", file=sys.stderr)
            for err in errors:
                print(" ", err, file=sys.stderr)
            return 1

    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
