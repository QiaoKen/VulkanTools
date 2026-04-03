#!/bin/bash

echo "=== 简单API Dump测试 ==="

# 设置环境变量
export VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_api_dump
export VK_LUNARG_API_DUMP_SHOW_API_DURATION=true
export VK_LUNARG_API_DUMP_API_DURATION_ONLY=false

# 创建一个简单的Vulkan程序
cat > /tmp/simple_vulkan.c << 'EOF'
#include <vulkan/vulkan.h>
#include <stdio.h>

int main() {
    VkInstance instance;
    VkInstanceCreateInfo createInfo = {0};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    
    printf("创建Vulkan实例...\n");
    VkResult result = vkCreateInstance(&createInfo, NULL, &instance);
    if (result == VK_SUCCESS) {
        printf("成功！\n");
        vkDestroyInstance(instance, NULL);
    } else {
        printf("失败: %d\n", result);
    }
    return 0;
}
EOF

# 编译
gcc -o /tmp/simple_vulkan /tmp/simple_vulkan.c -lvulkan

# 运行
echo "运行测试程序..."
/tmp/simple_vulkan

echo "=== 测试完成 ==="