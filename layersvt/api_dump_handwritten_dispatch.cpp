/* Copyright (c) 2015-2023 The Khronos Group Inc.
 * Copyright (c) 2015-2023 Valve Corporation
 * Copyright (c) 2015-2023 LunarG, Inc.
 * Copyright (C) 2015-2016 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Lenny Komow <lenny@lunarg.com>
 * Author: Shannon McPherson <shannon@lunarg.com>
 * Author: David Pinedo <david@lunarg.com>
 * Author: Charles Giessen <charles@lunarg.com>
 */

// Implementation file for specifically implemented functions

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))

#include "generated/api_dump_dispatch.h"
#include "api_dump_handwritten_functions.h"

// ---- VK_ARM_draw_state_bundle dispatch stub ----
template <ApiDumpFormat Format>
VKAPI_ATTR void VKAPI_CALL vkCmdDrawStateBundleARM(
    VkCommandBuffer commandBuffer,
    const VkDrawStateBundleInfoARM* pDrawStateBundleInfo)
{
    std::lock_guard<std::mutex> lg(ApiDumpInstance::current().outputMutex());
    ApiDumpInstance::current().startApiTimer();

    dump_function_head(ApiDumpInstance::current(), "vkCmdDrawStateBundleARM",
                       "commandBuffer, pDrawStateBundleInfo", "void");

    if constexpr (Format == ApiDumpFormat::Text) {
        if (ApiDumpInstance::current().settings().shouldPreDump() &&
            ApiDumpInstance::current().shouldDumpOutput()) {
            dump_before_pre_dump_formatting<Format>(ApiDumpInstance::current().settings());
            dump_params_vkCmdDrawStateBundleARM<Format>(
                ApiDumpInstance::current(), commandBuffer, pDrawStateBundleInfo);
        }
    }

    // Call through: look up the real function pointer via GetDeviceProcAddr
    auto pfn = reinterpret_cast<PFN_vkCmdDrawStateBundleARM>(
        device_dispatch_table(commandBuffer)->GetDeviceProcAddr(
            VK_NULL_HANDLE, "vkCmdDrawStateBundleARM"));
    if (pfn) {
        pfn(commandBuffer, pDrawStateBundleInfo);
    }

    if (ApiDumpInstance::current().shouldDumpOutput()) {
        if (ApiDumpInstance::current().settings().apiDurationOnly()) {
            auto api_duration = ApiDumpInstance::current().getApiDuration();
            if (ApiDumpInstance::current().settings().showApiDuration() ||
                ApiDumpInstance::current().settings().apiDurationOnly()) {
                ApiDumpInstance::current().settings().stream()
                    << "vkCmdDrawStateBundleARM - API Duration: "
                    << api_duration.count() << " us" << std::endl;
            }
        } else {
            auto api_duration = ApiDumpInstance::current().getApiDuration();
            if (ApiDumpInstance::current().settings().showApiDuration())
                ApiDumpInstance::current().settings().stream()
                    << "API Duration: " << api_duration.count() << " us" << std::endl;
            dump_pre_function_formatting<Format>(ApiDumpInstance::current().settings());
            dump_params_vkCmdDrawStateBundleARM<Format>(
                ApiDumpInstance::current(), commandBuffer, pDrawStateBundleInfo);
            dump_post_function_formatting<Format>(ApiDumpInstance::current().settings());
            flush(ApiDumpInstance::current().settings());
        }
    }
}

// Helper: expose vkCmdDrawStateBundleARM through GetProcAddr for all formats
template <ApiDumpFormat Format>
static PFN_vkVoidFunction arm_draw_state_bundle_get_proc(const char* pName) {
    if (strcmp(pName, "vkCmdDrawStateBundleARM") == 0)
        return reinterpret_cast<PFN_vkVoidFunction>(vkCmdDrawStateBundleARM<Format>);
    return nullptr;
}
// ---- end VK_ARM_draw_state_bundle dispatch stub ----

extern "C" {

EXPORT_FUNCTION VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL vkGetInstanceProcAddr(VkInstance instance, const char* pName) {
    PFN_vkVoidFunction instance_func = nullptr;
    switch (ApiDumpInstance::current().settings().format()) {
        case ApiDumpFormat::Text:
            instance_func = api_dump_known_instance_functions<ApiDumpFormat::Text>(instance, pName);
            break;
        case ApiDumpFormat::Html:
            instance_func = api_dump_known_instance_functions<ApiDumpFormat::Html>(instance, pName);
            break;
        case ApiDumpFormat::Json:
            instance_func = api_dump_known_instance_functions<ApiDumpFormat::Json>(instance, pName);
            break;
    }
    if (instance_func) return instance_func;
    PFN_vkVoidFunction device_func = nullptr;

    switch (ApiDumpInstance::current().settings().format()) {
        case ApiDumpFormat::Text:
            device_func = api_dump_known_device_functions<ApiDumpFormat::Text>(NULL, pName);
            break;
        case ApiDumpFormat::Html:
            device_func = api_dump_known_device_functions<ApiDumpFormat::Html>(NULL, pName);
            break;
        case ApiDumpFormat::Json:
            device_func = api_dump_known_device_functions<ApiDumpFormat::Json>(NULL, pName);
            break;
    }
    // Make sure that device functions queried through GIPA works
    if (device_func) return device_func;

    // VK_ARM_draw_state_bundle vendor extension
    switch (ApiDumpInstance::current().settings().format()) {
        case ApiDumpFormat::Text: { auto f = arm_draw_state_bundle_get_proc<ApiDumpFormat::Text>(pName);  if (f) return f; break; }
        case ApiDumpFormat::Html: { auto f = arm_draw_state_bundle_get_proc<ApiDumpFormat::Html>(pName);  if (f) return f; break; }
        case ApiDumpFormat::Json: { auto f = arm_draw_state_bundle_get_proc<ApiDumpFormat::Json>(pName);  if (f) return f; break; }
    }

    // Haven't created an instance yet, exit now since there is no instance_dispatch_table
    if (instance_dispatch_table(instance)->GetInstanceProcAddr == NULL) return nullptr;
    return instance_dispatch_table(instance)->GetInstanceProcAddr(instance, pName);
}

EXPORT_FUNCTION VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL vkGetDeviceProcAddr(VkDevice device, const char* pName) {
    PFN_vkVoidFunction device_func = nullptr;
    switch (ApiDumpInstance::current().settings().format()) {
        case ApiDumpFormat::Text:
            device_func = api_dump_known_device_functions<ApiDumpFormat::Text>(device, pName);
            break;
        case ApiDumpFormat::Html:
            device_func = api_dump_known_device_functions<ApiDumpFormat::Html>(device, pName);
            break;
        case ApiDumpFormat::Json:
            device_func = api_dump_known_device_functions<ApiDumpFormat::Json>(device, pName);
            break;
    }
    if (device_func) return device_func;

    // VK_ARM_draw_state_bundle vendor extension
    switch (ApiDumpInstance::current().settings().format()) {
        case ApiDumpFormat::Text: { auto f = arm_draw_state_bundle_get_proc<ApiDumpFormat::Text>(pName);  if (f) return f; break; }
        case ApiDumpFormat::Html: { auto f = arm_draw_state_bundle_get_proc<ApiDumpFormat::Html>(pName);  if (f) return f; break; }
        case ApiDumpFormat::Json: { auto f = arm_draw_state_bundle_get_proc<ApiDumpFormat::Json>(pName);  if (f) return f; break; }
    }

    // Haven't created a device yet, exit now since there is no device_dispatch_table
    if (device_dispatch_table(device)->GetDeviceProcAddr == NULL) return nullptr;
    return device_dispatch_table(device)->GetDeviceProcAddr(device, pName);
}
}
