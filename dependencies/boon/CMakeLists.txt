option(ENABLE_BUILD_TIME_SCHEMA_VALIDATION "Enable schema validation of generated configurations using Boon." OFF)

if (ENABLE_BUILD_TIME_SCHEMA_VALIDATION)
  find_package(Cargo)
  if(NOT Cargo_FOUND)
      set(try_rustup "installing rustup from https://rustup.rs")
      if (APPLE)
          message(FATAL_ERROR "Cargo not found. Try 'brew install rust' or ${try_rustup}.")
      elseif (UNIX)
          message(FATAL_ERROR "Cargo not found. Try 'sudo apt install cargo' or 'sudo dnf install cargo' or ${try_rustup}.")
      else()
          message(FATAL_ERROR "Cargo not found. Try ${try_rustup}.")
      endif()
  endif()

  include(ExternalProject)
  ExternalProject_Add(
      boon
      DOWNLOAD_COMMAND ""
      CONFIGURE_COMMAND ""
      BUILD_COMMAND ""
      # TODO: Once we depend on CMake 3.26, use INSTALL_BYPRODUCTS
      BUILD_BYPRODUCTS "${CMAKE_CURRENT_BINARY_DIR}/bin/boon"
      INSTALL_COMMAND cargo install boon-cli --locked --root ${CMAKE_CURRENT_BINARY_DIR}
  )

  add_executable(boon_cli IMPORTED GLOBAL)
  add_dependencies(boon_cli boon)
  set_target_properties(boon_cli PROPERTIES
      IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/bin/boon"
  )
endif()
