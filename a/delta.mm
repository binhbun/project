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

