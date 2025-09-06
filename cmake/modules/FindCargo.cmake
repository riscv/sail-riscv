# From https://github.com/alilleybrinker/FindCargo.cmake/blob/main/FindCargo.cmake

# MIT License
#
# Copyright (c) 2022 Andrew Lilley Brinker
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Find Cargo, possibly in ~/.cargo. Make sure to check in any `bin` subdirectories
# on the program search path
# TODO: Remove the Unix-ism ($ENV{HOME}) and replace it with something platform-agnostic.
find_program(CARGO_EXECUTABLE cargo PATHS "$ENV{HOME}/.cargo" PATH_SUFFIXES bin)

set(CARGO_VERSION "")
set(CARGO_CHANNEL "stable")

# If we found it, see if we can get its version.
if(CARGO_EXECUTABLE)
    execute_process(COMMAND ${CARGO_EXECUTABLE} -V OUTPUT_VARIABLE CARGO_VERSION_OUTPUT OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(CARGO_VERSION_OUTPUT MATCHES "cargo ([0-9]+\\.[0-9]+\\.[0-9]+).*")
        set(CARGO_VERSION ${CMAKE_MATCH_1})
    endif()

    execute_process(COMMAND ${CARGO_EXECUTABLE} -V OUTPUT_VARIABLE CARGO_CHANNEL_OUTPUT OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(CARGO_CHANNEL_OUTPUT MATCHES "cargo [0-9]+\\.[0-9]+\\.[0-9]+-([a-zA-Z]*).*")
        set(CARGO_CHANNEL ${CMAKE_MATCH_1})
    endif()
endif()

# Hides the CARGO_EXECUTABLE variable unless advanced variables are requested
mark_as_advanced(CARGO_EXECUTABLE)

# Require that we find both the executable and the version. Otherwise error out.
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    Cargo
    REQUIRED_VARS
        CARGO_VERSION
        CARGO_CHANNEL
        CARGO_EXECUTABLE
    VERSION_VAR
        CARGO_VERSION
)
