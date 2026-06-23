#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>

#define MAX_HIDDEN_DYLIB 50
#define SELF_NAME "GMV.dylib" 

static uint32_t g_hidden_indices[MAX_HIDDEN_DYLIB];
static uint32_t g_hidden_count = 0;
static bool g_initialized = false;

static bool is_system_library(const char *path)
{
    if (!path) return true;
    
    const char *system_paths[] = {
        "/usr/lib/",
        "/System/",
        "/usr/local/",
        "/usr/bin/",
        "/bin/",
        "/sbin/",
        "/Library/Apple/",
        "/System/Library/",
        NULL
    };
    
    for (int i = 0; system_paths[i] != NULL; i++) {
        if (strstr(path, system_paths[i]) == path) {
            return true;
        }
    }
    
    return false;
}

static void init_hidden_list(void)
{
    if (g_initialized) return;
    
    uint32_t count = _dyld_image_count();
    if (count == 0) return;
    
    // Tìm index của dylib hiện tại
    uint32_t self_index = (uint32_t)-1;
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, SELF_NAME)) {
            self_index = i;
            break;
        }
    }
    
    // Nếu không tìm thấy, thử tìm dylib không phải hệ thống cuối cùng
    if (self_index == (uint32_t)-1) {
        for (uint32_t i = count - 1; i > 0; i--) {
            const char *name = _dyld_get_image_name(i);
            if (name && !is_system_library(name) && 
                (strstr(name, ".dylib") || strstr(name, ".bundle"))) {
                self_index = i;
                break;
            }
        }
    }
    
    if (self_index == (uint32_t)-1) return;
    
    // Ẩn từ vị trí hiện tại đến hết (bao gồm chính nó)
    uint32_t idx = 0;
    for (uint32_t i = self_index; i < count && idx < MAX_HIDDEN_DYLIB; i++) {
        g_hidden_indices[idx++] = i;
    }
    
    g_hidden_count = idx;
    g_initialized = true;
}

static uint32_t adjusted_index(uint32_t caller_index)
{
    init_hidden_list();
    
    if (g_hidden_count == 0) {
        return caller_index;
    }
    
    uint32_t offset = 0;
    for (uint32_t i = 0; i < g_hidden_count; i++) {
        if (caller_index >= g_hidden_indices[i] - offset) {
            offset++;
        }
    }
    return caller_index + offset;
}

extern "C" __attribute__((visibility("default")))
uint32_t GMV_image_count(void)
{
    init_hidden_list();
    uint32_t real_count = _dyld_image_count();
    return real_count - g_hidden_count;
}

extern "C" __attribute__((visibility("default")))
const struct mach_header *GMV_get_image_header(uint32_t index)
{
    return _dyld_get_image_header(adjusted_index(index));
}

extern "C" __attribute__((visibility("default")))
const char *GMV_get_image_name(uint32_t index)
{
    return _dyld_get_image_name(adjusted_index(index));
}

struct dyld_interpose_tuple {
    const void *replacement;
    const void *replacee;
};

#define DYLD_INTERPOSE(_replacement, _replacee) \
    __attribute__((used)) static struct dyld_interpose_tuple \
    _interpose_##_replacee \
    __attribute__((section("__DATA,__interpose"))) = { \
        (const void *)(&_replacement), (const void *)(&_replacee) \
    }

DYLD_INTERPOSE(GMV_image_count,      _dyld_image_count);
DYLD_INTERPOSE(GMV_get_image_header, _dyld_get_image_header);
DYLD_INTERPOSE(GMV_get_image_name,   _dyld_get_image_name);

///////////////////

#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <stdint.h>
#include <string.h>

#define SELF_NAME_FRAGMENT "tên_dylib.dylib"

static uint32_t find_self_index(void)
{
    uint32_t count = _dyld_image_count();
    if (!count)
        return (uint32_t)-1;

    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, SELF_NAME_FRAGMENT))
            return i;
    }
    return (uint32_t)-1;
}

static uint32_t adjusted_index(uint32_t caller_index)
{
    uint32_t self = find_self_index();
    if (self != (uint32_t)-1 && caller_index >= self)
        return caller_index + 1;
    return caller_index;
}

extern "C" __attribute__((visibility("default")))
uint32_t GMV_image_count(void)
{
    uint32_t real_count = _dyld_image_count();
    bool self_present   = (find_self_index() != (uint32_t)-1);
    return real_count - (self_present ? 1u : 0u);
}

extern "C" __attribute__((visibility("default")))
const struct mach_header *GMV_get_image_header(uint32_t index)
{
    return _dyld_get_image_header(adjusted_index(index));
}

extern "C" __attribute__((visibility("default")))
const char *GMV_get_image_name(uint32_t index)
{
    return _dyld_get_image_name(adjusted_index(index));
}

struct dyld_interpose_tuple {
    const void *replacement;
    const void *replacee;
};

#define DYLD_INTERPOSE(_replacement, _replacee) \
    __attribute__((used)) static struct dyld_interpose_tuple \
    _interpose_##_replacee \
    __attribute__((section("__DATA,__interpose"))) = { \
        (const void *)(&_replacement), (const void *)(&_replacee) \
    }

DYLD_INTERPOSE(GMV_image_count,      _dyld_image_count);
DYLD_INTERPOSE(GMV_get_image_header, _dyld_get_image_header);
DYLD_INTERPOSE(GMV_get_image_name,   _dyld_get_image_name);

