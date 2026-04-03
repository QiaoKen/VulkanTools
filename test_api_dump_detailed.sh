#!/bin/bash

echo "=== 详细API Dump测试 ==="

# 设置环境变量
export VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_api_dump
export VK_LUNARG_API_DUMP_SHOW_API_DURATION=true
export VK_LUNARG_API_DUMP_API_DURATION_ONLY=false
export VK_LUNARG_API_DUMP_LOG_FILENAME=api_dump_output.txt

echo "环境变量设置："
echo "VK_INSTANCE_LAYERS=$VK_INSTANCE_LAYERS"
echo "VK_LUNARG_API_DUMP_SHOW_API_DURATION=$VK_LUNARG_API_DUMP_SHOW_API_DURATION"
echo "VK_LUNARG_API_DUMP_LOG_FILENAME=$VK_LUNARG_API_DUMP_LOG_FILENAME"

# 创建一个更复杂的Vulkan测试程序
echo "创建详细测试程序..."
cat > /tmp/test_vulkan_detailed.c << 'EOF'
#include <vulkan/vulkan.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    VkInstance instance;
    VkInstanceCreateInfo createInfo = {0};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    
    printf("开始创建Vulkan实例...\n");
    VkResult result = vkCreateInstance(&createInfo, NULL, &instance);
    if (result == VK_SUCCESS) {
        printf("Vulkan实例创建成功\n");
        
        // 获取物理设备
        uint32_t deviceCount = 0;
        vkEnumeratePhysicalDevices(instance, &deviceCount, NULL);
        printf("找到 %u 个物理设备\n", deviceCount);
        
        if (deviceCount > 0) {
            VkPhysicalDevice* devices = malloc(sizeof(VkPhysicalDevice) * deviceCount);
            vkEnumeratePhysicalDevices(instance, &deviceCount, devices);
            
            // 获取设备属性
            VkPhysicalDeviceProperties deviceProperties;
            vkGetPhysicalDeviceProperties(devices[0], &deviceProperties);
            printf("设备名称: %s\n", deviceProperties.deviceName);
            
            // 获取队列族属性
            uint32_t queueFamilyCount = 0;
            vkGetPhysicalDeviceQueueFamilyProperties(devices[0], &queueFamilyCount, NULL);
            printf("队列族数量: %u\n", queueFamilyCount);
            
            free(devices);
        }
        
        vkDestroyInstance(instance, NULL);
        printf("Vulkan实例已销毁\n");
    } else {
        printf("Vulkan实例创建失败: %d\n", result);
    }
    return 0;
}
EOF

# 编译测试程序
echo "编译详细测试程序..."
gcc -o /tmp/test_vulkan_detailed /tmp/test_vulkan_detailed.c -lvulkan

# 运行测试程序
echo "运行详细测试程序..."
/tmp/test_vulkan_detailed

# 检查输出文件
echo "检查输出文件..."
if [ -f "api_dump_output.txt" ]; then
    echo "找到API Dump输出文件：api_dump_output.txt"
    echo "文件内容："
    cat api_dump_output.txt
else
    echo "未找到api_dump_output.txt文件"
    echo "检查当前目录文件："
    ls -la *.txt 2>/dev/null || echo "没有找到txt文件"
fi

echo "=== 测试完成 ==="