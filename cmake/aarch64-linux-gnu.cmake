# CMake toolchain file for aarch64-none-linux-gnu (Arm GNU Toolchain 12.3)
# Usage:
#   cmake -S . -B build-linux-arm64 \
#         -DCMAKE_TOOLCHAIN_FILE=cmake/aarch64-linux-gnu.cmake \
#         -DUPDATE_DEPS=ON -DBUILD_TESTS=OFF

set(TOOLCHAIN_ROOT "/code/ddk3/tools/gcc/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu/arm-gnu-toolchain-12.3.rel1-x86_64-aarch64-none-linux-gnu")

set(CMAKE_SYSTEM_NAME      Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER   "${TOOLCHAIN_ROOT}/bin/aarch64-none-linux-gnu-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_ROOT}/bin/aarch64-none-linux-gnu-g++")
set(CMAKE_AR           "${TOOLCHAIN_ROOT}/bin/aarch64-none-linux-gnu-ar")
set(CMAKE_RANLIB       "${TOOLCHAIN_ROOT}/bin/aarch64-none-linux-gnu-gcc-ranlib")
set(CMAKE_STRIP        "${TOOLCHAIN_ROOT}/bin/aarch64-none-linux-gnu-strip")

set(CMAKE_SYSROOT "${TOOLCHAIN_ROOT}/aarch64-none-linux-gnu/libc")

# Thirdparty headers (xcb, X11, wayland, drm, etc.) from DDK
set(DDK_THIRDPARTY_INCLUDE "/code/ddk3/ddk/thirdparty/include")
set(CMAKE_C_FLAGS_INIT   "-I${DDK_THIRDPARTY_INCLUDE}")
set(CMAKE_CXX_FLAGS_INIT "-I${DDK_THIRDPARTY_INCLUDE}")

# Search only in the sysroot and toolchain for libraries/headers
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
