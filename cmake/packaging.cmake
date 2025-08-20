# Miscellaneous installation

# https://lintian.debian.org/tags/non-standard-dir-perm
set(CMAKE_INSTALL_DEFAULT_DIRECTORY_PERMISSIONS
    OWNER_READ OWNER_WRITE OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
    WORLD_READ WORLD_EXECUTE
)

# https://lintian.debian.org/tags/no-copyright-file
install(FILES "${CMAKE_SOURCE_DIR}/LICENCE"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${CMAKE_PROJECT_NAME}"
    RENAME "copyright"
)
install(FILES "${CMAKE_SOURCE_DIR}/dependencies/softfloat/berkeley-softfloat-3/COPYING.txt"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${CMAKE_PROJECT_NAME}"
    RENAME "Berkeley-SoftFloat-LICENSE.txt"
)
install(FILES "${CMAKE_SOURCE_DIR}/dependencies/CLI11/LICENSE"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${CMAKE_PROJECT_NAME}"
    RENAME "CLI11-LICENSE.txt"
)
install(FILES "${CMAKE_SOURCE_DIR}/dependencies/elfio/LICENSE.txt"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${CMAKE_PROJECT_NAME}"
    RENAME "ELFIO-LICENSE.txt"
)

# `file(ARCHIVE_CREATE COMPRESSION Gzip)` creates files with
# timestamps without a way of turning them off.  Instead, just use
# gzip directly to pass -n.

# https://lintian.debian.org/tags/changelog-file-not-compressed
set(src_changelog "${CMAKE_SOURCE_DIR}/doc/ChangeLog.md")
set(gzip_changelog "${CMAKE_BINARY_DIR}/changelog.gz")
add_custom_command(
    DEPENDS ${src_changelog}
    OUTPUT ${gzip_changelog}
    VERBATIM
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND
        gzip
        # https://lintian.debian.org/tags/package-contains-timestamped-gzip
        -n
        # Write to stdout
        -c
        # https://lintian.debian.org/tags/changelog-not-compressed-with-max-compression
        -9
        ${src_changelog} > ${gzip_changelog}
)
add_custom_target(compressed_changelog DEPENDS ${gzip_changelog})

# https://lintian.debian.org/tags/no-changelog
install(FILES "${CMAKE_BINARY_DIR}/changelog.gz"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${CMAKE_PROJECT_NAME}")

# RPM doesn't need a compressed changelog.
install(FILES ${src_changelog}
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${CMAKE_PROJECT_NAME}")

# CPack configuration

if (NOT CPACK_GENERATOR)
    if (WINDOWS)
        set(CPACK_GENERATOR "ZIP")
    else()
        set(CPACK_GENERATOR "TGZ")
    endif()
endif()
if (DARWIN)
    # ${CMAKE_SYSTEM_NAME} is unfortunately "Darwin", but we want "Mac".
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-Mac-${CMAKE_HOST_SYSTEM_PROCESSOR}")
else()
    set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CMAKE_SYSTEM_NAME}-${CMAKE_HOST_SYSTEM_PROCESSOR}")
endif()

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Sail RISC-V Model")
set(CPACK_PACKAGE_DESCRIPTION "A formal specification of the RISC-V architecture written in Sail.")
set(CPACK_PACKAGE_VENDOR "RISC-V International")
set(CPACK_PACKAGE_CONTACT "prashanth@riscv.org")

# https://lintian.debian.org/tags/unstripped-binary-or-object
set(CPACK_STRIP_FILES TRUE)

# Settings for DEB.
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Prashanth Mundkur <${CPACK_PACKAGE_CONTACT}>")
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS TRUE)

# Settings for RPM.
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)
set(CPACK_RPM_PACKAGE_DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION})
set(CPACK_RPM_PACKAGE_LICENSE "BSD-2-Clause")
set(CPACK_RPM_PACKAGE_AUTOREQ TRUE)

include(CPack)
