#!/bin/bash
# VulkanTools Release Build Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build_release"
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

log_info "=== Generating Release build files ==="
cmake -S "${SCRIPT_DIR}" \
      -B "${BUILD_DIR}" \
      -D CMAKE_BUILD_TYPE=Release \
      -D UPDATE_DEPS=ON \
      -D BUILD_WERROR=OFF \
      -D BUILD_TESTS=OFF \
      -D BUILD_APIDUMP=ON \
      -D BUILD_MONITOR=ON \
      -D BUILD_SCREENSHOT=ON

log_success "CMake 配置完成"

log_info "=== Building Release target ==="
cmake --build "${BUILD_DIR}" --config Release -- -j"${JOBS}"

log_success "=== Release build complete ==="
echo "Output: ${BUILD_DIR}/"
