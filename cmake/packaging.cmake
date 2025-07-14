# Miscellaneous installation

# https://lintian.debian.org/tags/non-standard-dir-perm
set(CMAKE_INSTALL_DEFAULT_DIRECTORY_PERMISSIONS
    OWNER_READ OWNER_WRITE OWNER_EXECUTE
    GROUP_READ GROUP_EXECUTE
    WORLD_READ WORLD_EXECUTE
)

# https://lintian.debian.org/tags/no-copyright-file
install(FILES "${CMAKE_SOURCE_DIR}/LICENCE"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/${CPACK_PACKAGE_NAME}"
    RENAME "copyright"
)

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
set(CPACK_STRIP_FILES YES)

# Settings for DEB.
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Prashanth Mundkur <${CPACK_PACKAGE_CONTACT}>")
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

# Settings for RPM.
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)
set(CPACK_RPM_PACKAGE_DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION})
set(CPACK_RPM_PACKAGE_LICENSE "BSD-2-Clause")
set(CPACK_RPM_PACKAGE_AUTOREQ ON)

include(CPack)
