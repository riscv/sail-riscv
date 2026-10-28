#!/usr/bin/python

import argparse
import copy
import json
import os
import pathlib
import sys
from typing import NotRequired, TypedDict, cast


class Build(TypedDict):
    os: str
    cmake_version: str
    first_party_tests: bool
    container: NotRequired[str]
    run_all_steps: NotRequired[bool]
    clang_tidy: NotRequired[bool]


class Test(Build):
    label: str


def define_build_matrix_entries() -> list[Build]:
    entries: list[Build] = []

    entries.append(
        {
            "os": "ubuntu-22.04",
            "cmake_version": "3.20.0",
            "first_party_tests": True,
        }
    )
    entries.append(
        {
            "os": "ubuntu-22.04",
            "cmake_version": "4.1.2",
            "first_party_tests": True,
            "run_all_steps": True,
        }
    )
    entries.append(
        {
            "os": "ubuntu-24.04-arm",
            "cmake_version": "3.20.0",
            "first_party_tests": True,
        }
    )
    entries.append(
        {
            "os": "ubuntu-24.04-arm",
            "cmake_version": "4.1.2",
            "first_party_tests": True,
            "clang_tidy": True,
        }
    )
    entries.append(
        {
            "os": "macos-latest",
            "cmake_version": "3.20.0",
            "first_party_tests": True,
        }
    )
    entries.append(
        {
            "os": "macos-latest",
            "cmake_version": "4.1.2",
            "first_party_tests": True,
        }
    )
    entries.append(
        {
            "os": "ubuntu-latest",
            "container": "rockylinux:8.9.20231119",
            "cmake_version": "3.20.0",
            "first_party_tests": False,
        }
    )
    entries.append(
        {
            "os": "ubuntu-24.04-arm",
            "container": "rockylinux:8.9.20231119",
            "cmake_version": "3.20.0",
            "first_party_tests": False,
        }
    )

    return entries


# The test matrix tries to equalize the CI runtimes across the
# parallel test runs for each platform.  Since each test suite
# may be of a different size, it is not always optimal to
# put each test suite into a different runner for each build.
# Instead, tests are grouped using labels (see test/CMakeLists.txt),
# and a test runner is used per label per build.
# Each test suite is run only once per platform build (regardless of
# the CMake version).

sail_riscv_test_labels: list[str] = ["GeneralTest", "VectorTest", "HypervisorTest"]


def define_test_matrix_entries(builds: list[Build]) -> list[Test]:
    entries: list[Test] = []
    seen_platforms: set[tuple[str, str | None]] = set()

    for e in builds:
        os, container = e["os"], e.get("container", None)
        if (os, container) in seen_platforms:
            continue
        seen_platforms.add((os, container))

        for l in sail_riscv_test_labels:
            t_ent = cast(Test, copy.deepcopy(e))
            t_ent["label"] = l
            entries.append(t_ent)

    print(len(entries))
    return entries


def gen_output(tag: str, entries: list[Build] | list[Test]):
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
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "-b", "--build", action="store_const", const=True, help="generate build matrix"
    )
    group.add_argument(
        "-t", "--test", action="store_const", const=True, help="generate test matrix"
    )
    return parser


def main() -> int:
    parser = cli_parser()
    opts = parser.parse_args()
    if opts.build:
        show_build_matrix(opts)
    elif opts.test:
        show_test_matrix(opts)

    return 0


if __name__ == "__main__":
    sys.exit(main())
