#!/usr/bin/env bash
# Build VulkanTools layers for Linux ARM64 (aarch64-none-linux-gnu)
#
# Usage:
#   ./build_arm64_linux.sh [debug|release]   (default: release)
#
# Outputs:
#   build-linux-arm64-debug/layersvt/   – Debug .so files
#   build-linux-arm64-release/layersvt/ – Release .so files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Config ────────────────────────────────────────────────────────────────────
BUILD_TYPE="${1:-release}"
case "${BUILD_TYPE,,}" in
    debug)   CMAKE_BUILD_TYPE=Debug   ;;
    release) CMAKE_BUILD_TYPE=Release ;;
    *)
        echo "ERROR: unknown build type '${BUILD_TYPE}'. Use 'debug' or 'release'."
        exit 1
        ;;
esac

BUILD_DIR="build-linux-arm64-${BUILD_TYPE,,}"
EXTERNAL_DIR="external/arm64-linux"
TOOLCHAIN_FILE="cmake/aarch64-linux-gnu.cmake"

VULKAN_HEADERS_DIR="${SCRIPT_DIR}/${EXTERNAL_DIR}/Vulkan-Headers/build/install/share/cmake/VulkanHeaders"
VULKAN_LOADER_DIR="${SCRIPT_DIR}/${EXTERNAL_DIR}/Vulkan-Loader/build/install/lib/cmake/VulkanLoader"
VULKAN_UTILITY_DIR="${SCRIPT_DIR}/${EXTERNAL_DIR}/Vulkan-Utility-Libraries/build/install/lib/cmake/VulkanUtilityLibraries"
VALIJSON_DIR="${SCRIPT_DIR}/${EXTERNAL_DIR}/valijson/build/install/lib/cmake/valijson"

echo "============================================================"
echo " VulkanTools ARM64 Linux build"
echo " Build type : ${CMAKE_BUILD_TYPE}"
echo " Build dir  : ${BUILD_DIR}"
echo "============================================================"

# ── Step 1: Build dependencies (skip if already installed) ───────────────────
if [[ ! -f "${VULKAN_HEADERS_DIR}/VulkanHeadersConfig.cmake" ]]; then
    echo ""
    echo ">>> Building ARM64 dependencies (Vulkan-Headers, Loader, Utility-Libraries, valijson)..."
    python3 scripts/update_deps.py \
        --dir "${EXTERNAL_DIR}" \
        --config release \
        --cmake_var CMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/${TOOLCHAIN_FILE}" \
        --cmake_var CMAKE_BUILD_TYPE=Release \
        --cmake_var BUILD_WSI_XCB_SUPPORT=OFF \
        --cmake_var BUILD_WSI_XLIB_SUPPORT=OFF \
        --cmake_var BUILD_WSI_WAYLAND_SUPPORT=OFF \
        --cmake_var BUILD_WSI_DIRECTFB_SUPPORT=OFF
    echo ">>> Dependencies done."
else
    echo ">>> Dependencies already present, skipping update_deps."
fi

# ── Step 2: CMake configure ───────────────────────────────────────────────────
echo ""
echo ">>> Configuring ${CMAKE_BUILD_TYPE} build..."
cmake -S . -B "${BUILD_DIR}" \
    -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_FILE}" \
    -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
    -DBUILD_TESTS=OFF \
    -DBUILD_LAYERMGR=OFF \
    -DBUILD_APIDUMP=ON \
    -DBUILD_MONITOR=ON \
    -DBUILD_SCREENSHOT=ON \
    -DVulkanHeaders_DIR="${VULKAN_HEADERS_DIR}" \
    -DVulkanLoader_DIR="${VULKAN_LOADER_DIR}" \
    -DVulkanUtilityLibraries_DIR="${VULKAN_UTILITY_DIR}" \
    -Dvalijson_DIR="${VALIJSON_DIR}"

# ── Step 3: Build ─────────────────────────────────────────────────────────────
echo ""
echo ">>> Building with $(nproc) parallel jobs..."
cmake --build "${BUILD_DIR}" --config "${CMAKE_BUILD_TYPE}" -j"$(nproc)"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo " Build complete: ${BUILD_DIR}/layersvt/"
echo "============================================================"
file "${BUILD_DIR}"/layersvt/libVkLayer_*.so
