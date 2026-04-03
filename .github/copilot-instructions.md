# VulkanTools Project Guidelines

## Build System

VulkanTools uses CMake as its build system.

### Quick Start
```bash
# Clone and build
git clone https://github.com/LunarG/VulkanTools.git
cd VulkanTools

# Configure with dependencies
cmake -S . -B build -D UPDATE_DEPS=ON -D BUILD_WERROR=ON -D BUILD_TESTS=ON -D CMAKE_BUILD_TYPE=Debug

# Build
cmake --build build --config Debug

# Run tests
cd build && ctest
```

### Requirements
- CMake >= 3.22.1
- C++17 compatible toolchain
- Python >= 3.10
- Qt 6.5 (optional, for Vulkan Configurator)

### Code Generation
Some source code in `layersvt/generated/` is generated from Vulkan-Headers:
```bash
# Generate source code
python3 scripts/generate_source.py external/Vulkan-Headers/[config]/[arch]/registry/

# Or use CMake helper target
cmake -S . -B build -D VT_CODEGEN=ON
cmake --build build --target vt_codegen
```

## Architecture

```
layersvt/              Vulkan validation layers
  api_dump.h           API call logging layer
  screenshot.cpp       Screenshot capture layer
  monitor.cpp          FPS monitoring layer
  generated/           Auto-generated layer code
vkconfig_gui/          Vulkan Configurator GUI (Qt)
vkconfig_core/         Vulkan Configurator core library
vkconfig_cmd/          Vulkan Configurator CLI
scripts/               Code generation and build scripts
tests/                 Test suite
```

### Key Components

| Component | Description |
|-----------|-------------|
| `VK_LAYER_LUNARG_api_dump` | Logs all Vulkan API calls with parameters |
| `VK_LAYER_LUNARG_screenshot` | Captures screenshots at specified frames |
| `VK_LAYER_LUNARG_monitor` | Displays FPS in window title bar |
| Vulkan Configurator | GUI/CLI tool for managing layers |

## Code Style

- Follow [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html) with exceptions:
  - Column limit: 132 (not 80)
  - Indent: 4 spaces (not 2)
- Run `clang-format` before committing:
  ```bash
  git clang-format --style=file
  ```
- Commit messages: `<component>: <description>` (50 char limit subject)

## Layer Development

### Layer Structure
```cpp
// Intercept Vulkan function
VKAPI_ATTR VkResult VKAPI_CALL vkQueuePresentKHR(VkQueue queue, const VkPresentInfoKHR *pPresentInfo) {
    // Pre-call logic
    auto* my_data = get_my_layer_data(queue);
    
    // Call down the chain
    VkResult result = device_dispatch_table(queue)->QueuePresentKHR(queue, pPresentInfo);
    
    // Post-call logic (e.g., frame counting)
    frameNumber++;
    
    return result;
}
```

### Frame Counting
- `api_dump`: Uses `nextFrame()` after `vkQueuePresentKHR`
- `screenshot`: Increments `frameNumber` in `QueuePresentKHR`
- Frame filtering via `output_range` setting (e.g., `"5-10"` for frames 5-14)

## Testing

```bash
# Run all tests
cd build && ctest

# Run specific test
cd build && ctest -R api_dump

# Manual api_dump test
VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_api_dump ./vkinfo
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `CMakeLists.txt` | Main build configuration |
| `scripts/known_good.json` | Dependency versions |
| `layersvt/vk_layer_settings.txt` | Layer configuration template |
| `layersvt/api_dump.h` | API dump implementation |
| `CONTRIBUTING.md` | Contribution guidelines |

## Documentation

- Build instructions: `BUILD.md`
- Layer docs: `layersvt/*.md`
- Vulkan Configurator: `vkconfig_gui/README.md`
