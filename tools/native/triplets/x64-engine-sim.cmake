set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)

# Upstream CMake explicitly requests static Boost libraries.
if(PORT MATCHES "^boost-")
    set(VCPKG_LIBRARY_LINKAGE static)
endif()
