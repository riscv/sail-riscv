#!/bin/sh

req_major="0"
req_minor="17"
req_patch="1"

function check {
    local version=$(sail -v | cut -d ' ' -f 2);

    if [ "$?" -ne 0 ]; then
        echo "Could not find Sail version: 'sail -v' command failed"
        exit 1
    fi

    local message="Sail version must be at least ${req_major}.${req_minor}.${req_patch}, got ${version}"

    local major=$(echo $version | cut -d '.' -f 1);
    local minor=$(echo $version | cut -d '.' -f 2);
    local patch=$(echo $version | cut -d '.' -f 3);

    # Sail version string may be two digits without a patch version,
    # in which case we treat it as zero.
    if [ -z "$patch" ]; then
        patch="0"
    fi

    if [ "$major" -lt "$req_major" ]; then
        echo "${message}"
        exit 1
    elif [ "$major" -gt "$req_major" ]; then
        exit 0
    fi

    if [ "$minor" -lt "$req_minor" ]; then
        echo "${message}"
        exit 1
    elif [ "$minor" -gt "$req_minor" ]; then
        exit 0
    fi

    if [ "$patch" -lt "$req_patch" ]; then
        echo "${message}"
        exit 1
    fi

    exit 0
}

check
