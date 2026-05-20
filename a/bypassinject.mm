// GMV.mm
// Self-hiding dylib — hides itself and accompanying libraries from dyld
// image enumeration.
// Build: clang++ -std=c++17 -O2 -dynamiclib -install_name @rpath/GMV.dylib \
//               -arch arm64 -arch x86_64 -o GMV.dylib GMV.mm

#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <stdint.h>
#include <string.h>

// ---------------------------------------------------------------------------
// Libraries to hide — add or remove fragments as needed
// ---------------------------------------------------------------------------
static const char *const kHiddenLibs[] = {
    "GMV.dylib",
    "YourOtherLib.dylib",   // <-- replace / extend as needed
};
static const uint32_t kHiddenLibCount =
    sizeof(kHiddenLibs) / sizeof(kHiddenLibs[0]);

// ---------------------------------------------------------------------------
// is_hidden — returns true if the image name matches any hidden fragment
// ---------------------------------------------------------------------------
static bool is_hidden(const char *name)
{
    if (!name) return false;
    for (uint32_t i = 0; i < kHiddenLibCount; i++) {
        if (strstr(name, kHiddenLibs[i]))
            return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
// adjusted_index — maps a caller-visible index to the real dyld index,
// walking the real list and skipping over every hidden entry
// ---------------------------------------------------------------------------
static uint32_t adjusted_index(uint32_t caller_index)
{
    uint32_t total   = _dyld_image_count();
    uint32_t visible = 0;

    for (uint32_t real = 0; real < total; real++) {
        if (is_hidden(_dyld_get_image_name(real)))
            continue;
        if (visible == caller_index)
            return real;
        visible++;
    }
    return caller_index; // fallback: out-of-range, let dyld handle it
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

extern "C" __attribute__((visibility("default")))
uint32_t GMV_image_count(void)
{
    uint32_t total  = _dyld_image_count();
    uint32_t hidden = 0;
    for (uint32_t i = 0; i < total; i++) {
        if (is_hidden(_dyld_get_image_name(i)))
            hidden++;
    }
    return total - hidden;
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

// ---------------------------------------------------------------------------
// DYLD_INTERPOSE — uncomment to transparently replace the real dyld functions
// process-wide when injected via DYLD_INSERT_LIBRARIES (no caller changes needed)
// ---------------------------------------------------------------------------
/*
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
*/
