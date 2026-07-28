#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <UIKit/UIKit.h>

// ============================================================
// 1. CẤU TRÚC SHARED MEMORY GIẢ
// ============================================================

typedef struct {
    uint64_t magic1;
    uint64_t pid;
    uint8_t state;
    uint8_t padding[7];
    uint32_t version;
    uint8_t reserved[16];
    uint64_t active_key;
    uint8_t offsets_data[528];
} FakeSharedMemory;

static FakeSharedMemory g_fake_shm = {0};
static uint64_t g_fake_active_key = 0;

// ============================================================
// 2. OFFSETS TỪ RESPONSE
// ============================================================

#define OFFSET_SHARED_DIRECTOR                       0x15E42A8
#define OFFSET_SHARED_USER_INFO                      0x2D7C20
#define OFFSET_SHARED_MAIN_MANAGER                   0x366310
#define OFFSET_SHARED_MENU_MANAGER                   0x33621C
#define OFFSET_USERINFO_SYNC_FLAG                    0x340
#define OFFSET_HOOK_SET_ACTIVE_VISUAL_CUE            0x118910
#define OFFSET_HOOK_START_MATCH                      0x12696C
#define OFFSET_CUE_SPIN_OFFSET                       0x4557670
#define OFFSET_CUE_MAX_POWER_OFFSET                  0x4557668
#define OFFSET_MENU_GET_STATE_ID                     0x12EF94
#define OFFSET_MENU_MANAGER_GET_STATE_ID             0x336BC8
#define OFFSET_MENU_POP_STATE                        0x3372A8
#define OFFSET_TAKE_SHOT_FUNC                        0x122B84
#define OFFSET_GAMEMANAGER_SHOT_FIELD                0x3B0
#define OFFSET_VISUAL_CUE_POWERBAR_VIEW              0x520
#define OFFSET_CC_GET_ACTIVE_ACTION                  0x7FA738
#define OFFSET_POCKET_GRAVITY_FACTOR                 0x0
#define OFFSET_POCKET_PULL_FACTOR                    0x0
#define OFFSET_FUN_BALL_TABLE_BOUNDS                 0xCF3C
#define OFFSET_FUN_CALC_VELOCITY                     0xE5E4
#define OFFSET_FUN_CALC_VELOCITY_POST                0x30FE4C
#define OFFSET_TOUCH_DELEGATE_GLOBAL                 0x4732968
#define OFFSET_FUN_DISPATCH_TOUCHES                  0x1657B64
#define OFFSET_RULES_CLASSIFICATION_VEC              0xC8
#define OFFSET_RULES_POCKET_NOMINATION               0x68
#define OFFSET_RULES_NOMINATED_POCKET                0x118
#define OFFSET_SCREEN_HEIGHT_OFFSET                  0x0
#define OFFSET_SCREEN_WIDTH_OFFSET                   0x0
#define OFFSET_FN_CONVERT_TO_WORLD                   0x1564054
#define OFFSET_CCDIRECTOR_SINGLETON                  0x4B65F80
#define OFFSET_CONTENT_SCALE_FACTOR                  0x456C1E8
#define OFFSET_MAINMANAGER_STATE_MANAGER_FIELD       0x3C8
#define OFFSET_GAMEMANAGER_RULES_FIELD               0x3F8
#define OFFSET_GAMEMANAGER_TABLE_FIELD               0x400
#define OFFSET_GAMEMANAGER_VISUAL_CUE_FIELD          0x4D0
#define OFFSET_GAMEMANAGER_VISUAL_ENGLISH_CONTROL_FIELD 0x4E0
#define OFFSET_GAMEMANAGER_STATE_MANAGER_FIELD       0x520
#define OFFSET_GAMEMANAGER_GAME_MODE_FIELD           0x5D8
#define OFFSET_VISUAL_CUE_VISUAL_GUIDE_FIELD         0x3B8
#define OFFSET_VISUAL_CUE_POWER_FIELD                0x3C0
#define OFFSET_TABLE_TABLE_PROPERTIES_FIELD          0x3C8
#define OFFSET_TABLE_FRICTION_PROPERTIES_FIELD       0x3D8
#define OFFSET_TABLE_BALLS_FIELD                     0x468
#define OFFSET_TABLE_COLLISION_BOUNDS_FIELD          0x5A0
#define OFFSET_TABLE_CUSHIONS_FIELD                  0x6E8
#define OFFSET_TABLE_CUSHIONS_ACTIVE_FIELD           0x6F0
#define OFFSET_TABLE_BALL_PROPERTIES_FIELD           0x3D0
#define OFFSET_VISUAL_ENGLISH_CONTROL_ENGLISH_FIELD  0x3C8
#define OFFSET_VISUAL_ENGLISH_CONTROL_INPUT_RADIUS_FIELD 0x3D8
#define OFFSET_VISUAL_ENGLISH_CONTROL_ANIMATE_ENGLISH_TIME_FIELD 0x440
#define OFFSET_VISUAL_ENGLISH_CONTROL_ANIMATE_ENGLISH_TARGET_FIELD 0x458
#define OFFSET_MENU_STATE_MANAGER_FIELD              0x3B0
#define OFFSET_TIER_SELECTOR_CENTERED_TIER_CODE      0x528
#define OFFSET_TIER_SELECTOR_TABLE                   0x4E8
#define OFFSET_CC_TABLE_SCROLL_PROGRESS              0x588

// ============================================================
// 3. ĐỊA CHỈ TRONG libHelpshift.dylib (từ IDA)
// ============================================================

#define OFFSET_HS_g_shm          0x249A0
#define OFFSET_HS_g_active_key   0x249A8
#define OFFSET_HS_g_user_id      0x249B0
#define OFFSET_HS_g_remaining_seconds 0x249E0

// ============================================================
// 4. ĐỊA CHỈ TRONG ninja.framework (từ IDA)
// ============================================================

#define OFFSET_NINJA_logged_in          0x22F6F9
#define OFFSET_NINJA_g_offsets_loaded   0x267B70
#define OFFSET_NINJA_g_version_state    0x267B74

#define OFFSET_NINJA_xmmword_2679C0     0x2679C0
#define OFFSET_NINJA_xmmword_2679D0     0x2679D0
#define OFFSET_NINJA_xmmword_2679E0     0x2679E0
#define OFFSET_NINJA_unk_2679F0         0x2679F0
#define OFFSET_NINJA_xmmword_267A00     0x267A00
#define OFFSET_NINJA_xmmword_267A10     0x267A10
#define OFFSET_NINJA_unk_267A20         0x267A20
#define OFFSET_NINJA_xmmword_267A30     0x267A30
#define OFFSET_NINJA_xmmword_267A40     0x267A40
#define OFFSET_NINJA_xmmword_267A50     0x267A50
#define OFFSET_NINJA_xmmword_267A60     0x267A60
#define OFFSET_NINJA_xmmword_267A70     0x267A70
#define OFFSET_NINJA_xmmword_267A80     0x267A80
#define OFFSET_NINJA_unk_267A90         0x267A90
#define OFFSET_NINJA_xmmword_267AA0     0x267AA0
#define OFFSET_NINJA_xmmword_267AB0     0x267AB0
#define OFFSET_NINJA_xmmword_267AC0     0x267AC0
#define OFFSET_NINJA_xmmword_267AD0     0x267AD0
#define OFFSET_NINJA_xmmword_267AE0     0x267AE0
#define OFFSET_NINJA_xmmword_267AF0     0x267AF0
#define OFFSET_NINJA_xmmword_267B00     0x267B00
#define OFFSET_NINJA_xmmword_267B10     0x267B10
#define OFFSET_NINJA_xmmword_267B20     0x267B20
#define OFFSET_NINJA_xmmword_267B30     0x267B30
#define OFFSET_NINJA_xmmword_267B40     0x267B40
#define OFFSET_NINJA_xmmword_267B50     0x267B50
#define OFFSET_NINJA_xmmword_267B60     0x267B60
#define OFFSET_NINJA_g_offsets          0x2679B0

// ============================================================
// 5. CẤU TRÚC LƯU THÔNG TIN LIBRARY
// ============================================================

typedef struct {
    uintptr_t base;
    uintptr_t slide;
    const char* path;
    const char* name;
} LibraryInfo;

// ============================================================
// 6. HÀM TÌM LIBRARY
// ============================================================

LibraryInfo find_library(const char* library_name) {
    LibraryInfo info = {0, 0, NULL, NULL};
    uint32_t count = _dyld_image_count();
    
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name) continue;
        
        if (strstr(name, library_name)) {
            if (strstr(name, "libHelpshift.dylib") && 
                strstr(library_name, "ninja.framework")) {
                continue;
            }
            
            info.base = (uintptr_t)_dyld_get_image_header(i);
            info.slide = _dyld_get_image_vmaddr_slide(i);
            info.path = name;
            info.name = library_name;
            
            NSLog(@"[Bypass] ✅ Found %s: %s", library_name, name);
            NSLog(@"[Bypass]    slide: 0x%llX", (uint64_t)info.slide);
            return info;
        }
    }
    
    NSLog(@"[Bypass] ❌ Cannot find %s!", library_name);
    return info;
}

// ============================================================
// 7. SETUP FAKE SHARED MEMORY
// ============================================================

void setup_fake_shared_memory(void) {
    g_fake_shm.magic1 = 0xDEADC0FEDEADC0FE;
    g_fake_shm.pid = getpid();
    g_fake_shm.state = 1;
    g_fake_shm.version = 1;
    g_fake_active_key = 0x1234567890ABCDEF;
    g_fake_shm.active_key = g_fake_active_key;
    memset(g_fake_shm.offsets_data, 0, 528);
    
    NSLog(@"[Bypass] ✅ Fake shared memory setup:");
    NSLog(@"[Bypass]    magic1: 0x%llX", g_fake_shm.magic1);
    NSLog(@"[Bypass]    pid: %llu", g_fake_shm.pid);
    NSLog(@"[Bypass]    state: %u (1=ready)", g_fake_shm.state);
    NSLog(@"[Bypass]    active_key: 0x%llX", g_fake_active_key);
}

// ============================================================
// 8. FORCE SET OFFSETS
// ============================================================

void force_set_offsets_ninja(LibraryInfo ninja) {
    if (!ninja.base) {
        NSLog(@"[Bypass] ❌ No ninja.framework info!");
        return;
    }
    
    uintptr_t base = ninja.slide;
    uint64_t *p;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_2679C0);
    *p = OFFSET_SHARED_DIRECTOR;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_2679D0);
    *p = OFFSET_SHARED_USER_INFO;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_2679E0);
    *p = OFFSET_SHARED_MAIN_MANAGER;
    
    p = (uint64_t *)(base + OFFSET_NINJA_unk_2679F0);
    *p = OFFSET_SHARED_MENU_MANAGER;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A00);
    *p = OFFSET_USERINFO_SYNC_FLAG;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A10);
    *p = OFFSET_HOOK_SET_ACTIVE_VISUAL_CUE;
    
    p = (uint64_t *)(base + OFFSET_NINJA_unk_267A20);
    *p = OFFSET_HOOK_START_MATCH;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A30);
    *p = OFFSET_CUE_SPIN_OFFSET;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A40);
    *p = OFFSET_CUE_MAX_POWER_OFFSET;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A50);
    *p = OFFSET_MENU_GET_STATE_ID;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A60);
    *p = OFFSET_MENU_MANAGER_GET_STATE_ID;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A70);
    *p = OFFSET_MENU_POP_STATE;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267A80);
    *p = OFFSET_TAKE_SHOT_FUNC;
    
    p = (uint64_t *)(base + OFFSET_NINJA_unk_267A90);
    *p = OFFSET_GAMEMANAGER_SHOT_FIELD;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267AA0);
    *p = OFFSET_VISUAL_CUE_POWERBAR_VIEW;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267AB0);
    *p = OFFSET_CC_GET_ACTIVE_ACTION;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267AC0);
    *p = OFFSET_POCKET_GRAVITY_FACTOR;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267AD0);
    *p = OFFSET_POCKET_PULL_FACTOR;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267AE0);
    *p = OFFSET_FUN_BALL_TABLE_BOUNDS;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267AF0);
    *p = OFFSET_FUN_CALC_VELOCITY;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267B00);
    *p = OFFSET_FUN_CALC_VELOCITY_POST;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267B10);
    *p = OFFSET_TOUCH_DELEGATE_GLOBAL;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267B20);
    *p = OFFSET_FUN_DISPATCH_TOUCHES;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267B30);
    *p = OFFSET_RULES_CLASSIFICATION_VEC;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267B40);
    *p = OFFSET_RULES_POCKET_NOMINATION;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267B50);
    *p = OFFSET_RULES_NOMINATED_POCKET;
    
    p = (uint64_t *)(base + OFFSET_NINJA_xmmword_267B60);
    *p = OFFSET_SCREEN_HEIGHT_OFFSET;
    
    p = (uint64_t *)(base + OFFSET_NINJA_g_offsets);
    *p = OFFSET_SCREEN_WIDTH_OFFSET;
    
    NSLog(@"[Bypass]   All offsets forced!");
}

// ============================================================
// 9. PATCH VERSION STATE
// ============================================================

void patch_version_state(LibraryInfo ninja) {
    if (!ninja.base) return;
    
    uintptr_t addr_state = ninja.slide + OFFSET_NINJA_g_version_state;
    uint32_t *state_ptr = (uint32_t *)addr_state;
    
    uint32_t current = *state_ptr;
    NSLog(@"[Bypass]   g_ninja_version_state at 0x%llX = %u", (uint64_t)addr_state, current);
    
    *state_ptr = 0;
    
    uint32_t new_value = *state_ptr;
    NSLog(@"[Bypass]   g_ninja_version_state changed: %u -> %u", current, new_value);
}


void patch_helpshift(LibraryInfo hs) {
    if (!hs.base) {
        NSLog(@"[Bypass] ❌ Cannot patch helpshift!");
        return;
    }
    
    NSLog(@"[Bypass] Patching libHelpshift.dylib...");
    
    uintptr_t addr_shm = hs.slide + OFFSET_HS_g_shm;
    void **shm_ptr = (void **)addr_shm;
    *shm_ptr = &g_fake_shm;
    NSLog(@"[Bypass]   g_shm at 0x%llX -> %p", (uint64_t)addr_shm, &g_fake_shm);
    
    uintptr_t addr_key = hs.slide + OFFSET_HS_g_active_key;
    uint64_t *key_ptr = (uint64_t *)addr_key;
    *key_ptr = g_fake_active_key;
    NSLog(@"[Bypass]   g_active_key at 0x%llX -> 0x%llX", (uint64_t)addr_key, g_fake_active_key);
    
    uintptr_t addr_user = hs.slide + OFFSET_HS_g_user_id;
    uint32_t *user_ptr = (uint32_t *)addr_user;
    *user_ptr = 156417;
    NSLog(@"[Bypass]   g_user_id at 0x%llX -> %d", (uint64_t)addr_user, 156417);
    
    uintptr_t addr_remaining = hs.slide + OFFSET_HS_g_remaining_seconds;
    uint32_t *remaining_ptr = (uint32_t *)addr_remaining;
    *remaining_ptr = 2563027;
    NSLog(@"[Bypass]   g_remaining_seconds at 0x%llX -> %d", (uint64_t)addr_remaining, 2563027);
    
    NSLog(@"[Bypass] ✅ libHelpshift.dylib patched!");
}

// ============================================================
// 11. PATCH NINJA
// ============================================================

void patch_ninja(LibraryInfo ninja) {
    if (!ninja.base) {
        NSLog(@"[Bypass] ❌ Cannot patch ninja!");
        return;
    }
    
    NSLog(@"[Bypass] Patching ninja.framework...");
    
    uintptr_t addr_logged = ninja.slide + OFFSET_NINJA_logged_in;
    uint8_t *logged_ptr = (uint8_t *)addr_logged;
    *logged_ptr = 1;
    NSLog(@"[Bypass]   logged_in at 0x%llX -> 1", (uint64_t)addr_logged);
    
    uintptr_t addr_loaded = ninja.slide + OFFSET_NINJA_g_offsets_loaded;
    uint8_t *loaded_ptr = (uint8_t *)addr_loaded;
    *loaded_ptr = 1;
    NSLog(@"[Bypass]   g_offsets_loaded at 0x%llX -> 1", (uint64_t)addr_loaded);
    
    patch_version_state(ninja);
    force_set_offsets_ninja(ninja);
    
    NSLog(@"[Bypass] ✅ ninja.framework patched!");
}

// ============================================================
// 12. CHECK STATUS
// ============================================================

void check_status(LibraryInfo hs, LibraryInfo ninja) {
    NSLog(@"[Bypass] ========================================");
    NSLog(@"[Bypass] STATUS CHECK:");
    
    if (hs.base) {
        void *shm = *(void **)(hs.slide + OFFSET_HS_g_shm);
        uint64_t key = *(uint64_t *)(hs.slide + OFFSET_HS_g_active_key);
        uint32_t user = *(uint32_t *)(hs.slide + OFFSET_HS_g_user_id);
        uint32_t remaining = *(uint32_t *)(hs.slide + OFFSET_HS_g_remaining_seconds);
        NSLog(@"[Bypass]   libHelpshift:");
        NSLog(@"[Bypass]     g_shm = %p", shm);
        NSLog(@"[Bypass]     g_active_key = 0x%llX", key);
        NSLog(@"[Bypass]     g_user_id = %d", user);
        NSLog(@"[Bypass]     g_remaining_seconds = %d", remaining);
        
        if (shm == &g_fake_shm) {
            FakeSharedMemory *fs = (FakeSharedMemory *)shm;
            NSLog(@"[Bypass]     fake_shm.state = %u", fs->state);
        }
    }
    
    if (ninja.base) {
        uint8_t logged = *(uint8_t *)(ninja.slide + OFFSET_NINJA_logged_in);
        uint8_t loaded = *(uint8_t *)(ninja.slide + OFFSET_NINJA_g_offsets_loaded);
        uint32_t state = *(uint32_t *)(ninja.slide + OFFSET_NINJA_g_version_state);
        NSLog(@"[Bypass]   ninja.framework:");
        NSLog(@"[Bypass]     logged_in = %d", logged);
        NSLog(@"[Bypass]     g_offsets_loaded = %d", loaded);
        NSLog(@"[Bypass]     g_ninja_version_state = %u", state);
    }
    
    NSLog(@"[Bypass] ========================================");
}

// ============================================================
// 13. DO_ALL_PATCHES - GỌI NGAY LẬP TỨC
// ============================================================

static void do_all_patches(void) {
    NSLog(@"[Bypass] Starting patches (IMMEDIATE)...");
    
    setup_fake_shared_memory();
    
    LibraryInfo hs = find_library("libHelpshift.dylib");
    if (hs.base) {
        patch_helpshift(hs);
    }
    
    LibraryInfo ninja = find_library("ninja.framework");
    if (ninja.base) {
        patch_ninja(ninja);
    }
    
    check_status(hs, ninja);
    
    NSLog(@"[Bypass] ✅ ALL PATCHES COMPLETED!");
}

// ============================================================
// 14. HÀM INITIALIZE - KHÔNG DÙNG dispatch_after
// ============================================================

__attribute__((constructor)) static void initialize(void) {
    NSLog(@"[Bypass] ========================================");
    NSLog(@"[Bypass] 🚀 Dylib INJECTED SUCCESSFULLY!");
    NSLog(@"[Bypass] ========================================");
    
    // Patch NGAY LẬP TỨC, không đợi
    // Dùng dispatch_async với priority cao
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Đợi 0.1s để framework load
        usleep(100000);
        do_all_patches();
    });
}
