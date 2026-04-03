#!/bin/bash

echo "=== 测试API Dump层 ==="

# 设置环境变量
export VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_api_dump
export VK_LUNARG_API_DUMP_SHOW_API_DURATION=true
export VK_LUNARG_API_DUMP_API_DURATION_ONLY=false

# 检查层是否可用
echo "1. 检查可用层："
vulkaninfo --layers | grep api_dump

# 创建一个简单的Vulkan测试程序
echo "2. 创建测试程序..."
cat > /tmp/test_vulkan.c << 'EOF'
#include <vulkan/vulkan.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    VkInstance instance;
    VkInstanceCreateInfo createInfo = {0};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    
    VkResult result = vkCreateInstance(&createInfo, NULL, &instance);
    if (result == VK_SUCCESS) {
        printf("Vulkan实例创建成功\n");
        vkDestroyInstance(instance, NULL);
    } else {
        printf("Vulkan实例创建失败: %d\n", result);
    }
    return 0;
}
EOF

# 编译测试程序
echo "3. 编译测试程序..."
gcc -o /tmp/test_vulkan /tmp/test_vulkan.c -lvulkan

# 运行测试程序
echo "4. 运行测试程序（应该显示API调用）..."
/tmp/test_vulkan

echo "=== 测试完成 ==="