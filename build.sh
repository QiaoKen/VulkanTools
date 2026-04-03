#!/bin/bash
# VulkanTools 编译脚本
# 用法: ./build.sh [选项]
#   -c, --clean       清理构建目录后重新编译
#   -d, --debug       Debug 模式（默认）
#   -r, --release     Release 模式
#   -j, --jobs N      并行编译线程数（默认: CPU核心数）
#   -t, --tests       编译并运行测试
#   -h, --help        显示帮助信息

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
BUILD_TYPE="Debug"
CLEAN=0
RUN_TESTS=0
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}   $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    grep '^#' "$0" | grep -v '#!/' | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--clean)   CLEAN=1 ;;
        -d|--debug)   BUILD_TYPE="Debug" ;;
        -r|--release) BUILD_TYPE="Release" ;;
        -j|--jobs)    JOBS="$2"; shift ;;
        -t|--tests)   RUN_TESTS=1 ;;
        -h|--help)    usage ;;
        *) log_error "未知参数: $1"; usage ;;
    esac
    shift
done

log_info "构建类型: ${BUILD_TYPE}"
log_info "并行线程: ${JOBS}"
log_info "构建目录: ${BUILD_DIR}"

# 清理
if [[ $CLEAN -eq 1 ]]; then
    log_warn "清理构建目录..."
    rm -rf "${BUILD_DIR}"
fi

mkdir -p "${BUILD_DIR}"

# CMake 配置
log_info "运行 CMake 配置..."
cmake -S "${SCRIPT_DIR}" \
      -B "${BUILD_DIR}" \
      -D CMAKE_BUILD_TYPE="${BUILD_TYPE}" \
      -D UPDATE_DEPS=ON \
      -D BUILD_WERROR=OFF \
      -D BUILD_TESTS="${RUN_TESTS}" \
      -D BUILD_APIDUMP=ON \
      -D BUILD_MONITOR=ON \
      -D BUILD_SCREENSHOT=ON

log_success "CMake 配置完成"

# 编译
log_info "开始编译（-j${JOBS}）..."
cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" -- -j"${JOBS}"

log_success "编译完成"

# 运行测试
if [[ $RUN_TESTS -eq 1 ]]; then
    log_info "运行测试..."
    cd "${BUILD_DIR}"
    ctest --output-on-failure --build-config "${BUILD_TYPE}" -j"${JOBS}"
    log_success "测试完成"
fi

echo ""
log_success "全部完成！构建产物位于: ${BUILD_DIR}"
