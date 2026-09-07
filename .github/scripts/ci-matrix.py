#!/usr/bin/python

import argparse
import copy
import json
import os
import pathlib
import sys


def define_build_matrix_entries() -> list[dict]:
    entries: list[dict] = []

    entries.append(
        {
            "os": "ubuntu-22.04",
            "cmake_version": "3.20.0",
            "first_party_tests": "true",
        }
    )
    entries.append(
        {
            "os": "ubuntu-22.04",
            "cmake_version": "4.1.2",
            "first_party_tests": "true",
            "run_all_steps": "true",
        }
    )
    entries.append(
        {
            "os": "ubuntu-24.04-arm",
            "cmake_version": "3.20.0",
            "first_party_tests": "true",
        }
    )
    entries.append(
        {
            "os": "ubuntu-24.04-arm",
            "cmake_version": "4.1.2",
            "first_party_tests": "true",
            "clang_tidy": "true",
        }
    )
    entries.append(
        {
            "os": "macos-latest",
            "cmake_version": "3.20.0",
            "first_party_tests": "true",
        }
    )
    entries.append(
        {
            "os": "macos-latest",
            "cmake_version": "4.1.2",
            "first_party_tests": "true",
        }
    )
    entries.append(
        {
            "os": "ubuntu-latest",
            "container": "rockylinux:8.9.20231119",
            "cmake_version": "3.20.0",
            "first_party_tests": "false",
        }
    )
    entries.append(
        {
            "os": "ubuntu-24.04-arm",
            "container": "rockylinux:8.9.20231119",
            "cmake_version": "3.20.0",
            "first_party_tests": "false",
        }
    )

    return entries


# The test matrix tries to equalize the CI runtimes across the
# parallel test runs for each platform.  It is not always optimal to
# put each test suite into a different runner for each build: since
# there are currently 8 build variants (i.e. entries in the build
# matrix above), and 5 test suites in the default build
# ('riscv-tests', riscv-arch-tests', 'damo-tests' and 2
# 'riscv-vector-tests'), there would be 40 runners needed for the test
# matrix.  The smaller runtime for each suite is often neutralized by
# the time waiting for more runners to be available.
#
# Instead, tests are grouped using labels (see test/CMakeLists.txt),
# and a test runner is used per label per build.


def sail_riscv_test_labels() -> list[str]:
    return ["GeneralTest", "VectorTest", "HypervisorTest"]


def define_test_matrix_entries(builds: list[dict]) -> list[dict]:
    entries: list[dict] = []
    labels = sail_riscv_test_labels()

    for e in builds:
        for l in labels:
            t_ent = copy.deepcopy(e)
            t_ent["label"] = l
            entries.append(t_ent)

    return entries


def gen_output(tag: str, entries: list[dict]):
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        # eliminate whitespace in json
        json_output = json.dumps(entries, separators=(",", ":"))
        with pathlib.Path(github_output).open("a") as f:
            f.write(f"{tag}={json_output}\n")
    else:
        print(json.dumps(entries, indent=2))


def show_build_matrix(opts):
    build_include = define_build_matrix_entries()
    gen_output("build_include", build_include)


def show_test_matrix(opts):
    builds = define_build_matrix_entries()
    test_include = define_test_matrix_entries(builds)
    gen_output("test_include", test_include)


def cli_parser():
    parser = argparse.ArgumentParser(description="Generate CI matrix entries")
    parser.add_argument(
        "-b", "--build", action="store_const", const=True, help="generate build matrix"
    )
    parser.add_argument(
        "-t", "--test", action="store_const", const=True, help="generate test matrix"
    )
    return parser


def main() -> int:
    parser = cli_parser()
    cliopts = sys.argv[1:]
    if len(cliopts) == 0:
        parser.print_help()
        sys.exit(0)

    opts = parser.parse_args(cliopts)
    if opts.build:
        show_build_matrix(opts)
    elif opts.test:
        show_test_matrix(opts)

    return 0


if __name__ == "__main__":
    sys.exit(main())
