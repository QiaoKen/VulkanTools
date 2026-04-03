#!/bin/bash

echo "=== API Dump调试脚本 ==="

# 检查当前环境
echo "1. 检查环境变量："
echo "VK_INSTANCE_LAYERS: $VK_INSTANCE_LAYERS"
echo "VK_LOADER_LAYERS_ENABLE: $VK_LOADER_LAYERS_ENABLE"
echo "VK_LOADER_LAYERS_DISABLE: $VK_LOADER_LAYERS_DISABLE"

# 检查层是否可用
echo -e "\n2. 检查可用层："
vulkaninfo --summary 2>&1 | grep -A 5 "Instance Layers"

# 检查配置文件
echo -e "\n3. 检查层配置文件："
if [ -f "layersvt/vk_layer_settings.txt" ]; then
    echo "找到配置文件：layersvt/vk_layer_settings.txt"
    grep -E "(show_api_duration|api_duration_only|log_filename)" layersvt/vk_layer_settings.txt
else
    echo "未找到配置文件"
fi

# 创建测试程序
echo -e "\n4. 创建测试程序..."
cat > /tmp/debug_vulkan.c << 'EOF'
#include <vulkan/vulkan.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    VkInstance instance;
    VkInstanceCreateInfo createInfo = {0};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    
    printf("测试Vulkan API Dump...\n");
    
    VkResult result = vkCreateInstance(&createInfo, NULL, &instance);
    if (result == VK_SUCCESS) {
        printf("实例创建成功\n");
        
        // 获取物理设备
        uint32_t deviceCount = 0;
        vkEnumeratePhysicalDevices(instance, &deviceCount, NULL);
        printf("找到 %u 个物理设备\n", deviceCount);
        
        vkDestroyInstance(instance, NULL);
        printf("实例已销毁\n");
    } else {
        printf("实例创建失败: %d\n", result);
    }
    
    return 0;
}
EOF

# 编译测试程序
echo -e "\n5. 编译测试程序..."
gcc -o /tmp/debug_vulkan /tmp/debug_vulkan.c -lvulkan

# 测试不同的环境变量设置
echo -e "\n6. 测试不同的环境变量设置："

# 测试1：标准设置
echo -e "\n测试1：标准设置"
export VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_api_dump
export VK_LUNARG_API_DUMP_SHOW_API_DURATION=true
export VK_LUNARG_API_DUMP_API_DURATION_ONLY=false
/tmp/debug_vulkan

# 检查输出文件
echo -e "\n7. 检查输出文件："
ls -la *.txt 2>/dev/null | grep -E "(api_dump|apidump)" | head -10

# 检查是否有新的输出文件
echo -e "\n8. 检查最近修改的文件："
find . -name "*.txt" -type f -mmin -1 2>/dev/null | head -10

echo -e "\n=== 调试完成 ==="