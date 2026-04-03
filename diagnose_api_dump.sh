#!/bin/bash

echo "=== API Dump诊断脚本 ==="

# 检查当前环境
echo "1. 当前工作目录："
pwd

echo -e "\n2. 环境变量："
echo "VK_INSTANCE_LAYERS: $VK_INSTANCE_LAYERS"
echo "VK_LUNARG_API_DUMP_SHOW_API_DURATION: $VK_LUNARG_API_DUMP_SHOW_API_DURATION"
echo "VK_LUNARG_API_DUMP_LOG_FILENAME: $VK_LUNARG_API_DUMP_LOG_FILENAME"

echo -e "\n3. 检查层是否可用："
vulkaninfo --summary 2>&1 | grep -A 10 "Instance Layers"

echo -e "\n4. 检查配置文件："
if [ -f "layersvt/vk_layer_settings.txt" ]; then
    echo "配置文件存在：layersvt/vk_layer_settings.txt"
    echo "API Duration设置："
    grep -E "(show_api_duration|api_duration_only)" layersvt/vk_layer_settings.txt
else
    echo "配置文件不存在"
fi

echo -e "\n5. 创建测试程序..."
cat > /tmp/test_api_dump.c << 'EOF'
#include <vulkan/vulkan.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
    VkInstance instance;
    VkInstanceCreateInfo createInfo = {0};
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    
    printf("开始Vulkan测试...\n");
    
    VkResult result = vkCreateInstance(&createInfo, NULL, &instance);
    if (result == VK_SUCCESS) {
        printf("实例创建成功\n");
        
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
            
            free(devices);
        }
        
        vkDestroyInstance(instance, NULL);
        printf("实例已销毁\n");
    } else {
        printf("实例创建失败: %d\n", result);
    }
    
    printf("测试完成\n");
    return 0;
}
EOF

echo -e "\n6. 编译测试程序..."
gcc -o /tmp/test_api_dump /tmp/test_api_dump.c -lvulkan

echo -e "\n7. 测试不同的配置："

# 测试1：输出到标准输出
echo -e "\n测试1：输出到标准输出"
export VK_INSTANCE_LAYERS=VK_LAYER_LUNARG_api_dump
export VK_LUNARG_API_DUMP_SHOW_API_DURATION=true
export VK_LUNARG_API_DUMP_API_DURATION_ONLY=false
unset VK_LUNARG_API_DUMP_LOG_FILENAME
/tmp/test_api_dump

# 测试2：输出到文件
echo -e "\n测试2：输出到文件"
export VK_LUNARG_API_DUMP_LOG_FILENAME=test_output.txt
/tmp/test_api_dump

echo -e "\n8. 检查输出文件："
if [ -f "test_output.txt" ]; then
    echo "找到输出文件：test_output.txt"
    echo "文件大小：$(stat -c%s test_output.txt) 字节"
    echo "文件内容前10行："
    head -10 test_output.txt
else
    echo "未找到test_output.txt"
fi

echo -e "\n9. 检查所有txt文件："
ls -la *.txt 2>/dev/null | grep -E "(api_dump|apidump|test_output)" | head -10

echo -e "\n=== 诊断完成 ==="