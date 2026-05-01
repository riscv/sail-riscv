include(FetchContent)

# Allow downloads to be turned off (in particular, for targets that
# don't need it).  Downloads may not be needed for systems that have
# asio installed (e.g.  via `libasio-dev` on Ubuntu-based systems and
# `asio-devel` on Fedora-based systems).

option(DOWNLOAD_ASIO "Download asio" ON)

FetchContent_Declare(
  asio
  URL https://downloads.sourceforge.net/project/asio/asio/1.36.0%20%28Stable%29/asio-1.36.0.tar.bz2
  URL_HASH SHA3_256=5979be31450b6e8d09ab7e766f62f4f7e1be85f090f2a9a773e12203922e5ce9
)

if (DOWNLOAD_ASIO)
    FetchContent_MakeAvailable(asio)

    add_library(asio INTERFACE
        "${asio_SOURCE_DIR}/include/asio.hpp"
    )
    target_include_directories(asio INTERFACE
        "${asio_SOURCE_DIR}/include"
    )
    target_compile_definitions(asio INTERFACE
        -DASIO_NO_DEPRECATED
    )

    # On Rocky Linux 8.9, the build fails unless linked with -pthread.
    set(THREADS_PREFER_PTHREAD_FLAG TRUE)
    find_package(Threads)
    target_link_libraries(asio INTERFACE Threads::Threads)
endif()
