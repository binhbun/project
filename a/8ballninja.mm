#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <string.h>
#import <pthread.h>
#import "fishhook.h"

// Cấu trúc shared memory giữa Helpshift và Ninja
typedef struct {
    uint64_t magic1;              // 0x00: 0xDEADC0FEDEADC0FE
    uint64_t pid;                 // 0x08
    uint8_t state;                // 0x10
    uint8_t padding1[3];
    uint32_t version;             // 0x14
    uint8_t encrypted_offsets[528]; // 0x18 đến 0x228
    uint64_t magic2;              // 0x228: 0xCAFEBABECAFEBABE
} SharedMemory;

// Địa chỉ trong ninja.framework
#define OFFSET_G_OFFSETS        0x2679B0
#define OFFSET_G_OFFSETS_LOADED 0x2679B0  // Cần xác nhận lại địa chỉ này
#define OFFSET_ADDR_LOGGED_IN   0x22F6F9

// Hàm lấy slide của ninja.framework
static uintptr_t get_ninja_slide(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "ninja.framework")) {
            NSLog(@"[Bypass] Found ninja.framework at: %s", name);
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// Hàm giải mã và vá offsets
static bool decrypt_and_patch_offsets(uintptr_t ninja_slide) {
    NSLog(@"[Bypass] Starting offsets decryption...");
    
    // Định nghĩa function pointers
    typedef uint64_t (*hs_get_shm_ptr_t)(void);
    typedef uint64_t (*hs_get_active_key_t)(void);
    typedef uint64_t (*ninja_get_offset_mask_t)(void);
    
    // Lấy con trỏ hàm từ libHelpshift.dylib
    hs_get_shm_ptr_t hs_get_shm_ptr = (hs_get_shm_ptr_t)dlsym(RTLD_DEFAULT, "hs_get_shm_ptr");
    hs_get_active_key_t hs_get_active_key = (hs_get_active_key_t)dlsym(RTLD_DEFAULT, "hs_get_active_key");
    
    if (!hs_get_shm_ptr) {
        NSLog(@"[Bypass] ❌ Cannot find hs_get_shm_ptr");
        return false;
    }
    
    if (!hs_get_active_key) {
        NSLog(@"[Bypass] ❌ Cannot find hs_get_active_key");
        return false;
    }
    
    NSLog(@"[Bypass] ✅ Found hs_get_shm_ptr at: %p", hs_get_shm_ptr);
    NSLog(@"[Bypass] ✅ Found hs_get_active_key at: %p", hs_get_active_key);
    
    // Lấy shared memory pointer
    uint64_t shm_addr = hs_get_shm_ptr();
    if (!shm_addr) {
        NSLog(@"[Bypass] ❌ Shared memory is NULL - Helpshift not initialized yet");
        return false;
    }
    
    NSLog(@"[Bypass] Shared memory at: 0x%llx", shm_addr);
    
    SharedMemory *shm = (SharedMemory *)shm_addr;
    
    // Kiểm tra magic numbers
    NSLog(@"[Bypass] Magic1: 0x%llx (expected: 0xDEADC0FEDEADC0FE)", shm->magic1);
    NSLog(@"[Bypass] Magic2: 0x%llx (expected: 0xCAFEBABECAFEBABE)", shm->magic2);
    
    if (shm->magic1 != 0xDEADC0FEDEADC0FEULL) {
        NSLog(@"[Bypass] ❌ Invalid magic1");
        return false;
    }
    
    if (shm->magic2 != 0xCAFEBABECAFEBABEULL) {
        NSLog(@"[Bypass] ❌ Invalid magic2");
        return false;
    }
    
    // Kiểm tra PID
    pid_t current_pid = getpid();
    NSLog(@"[Bypass] Shared memory PID: %lld, Current PID: %d", shm->pid, current_pid);
    
    if (shm->pid != current_pid) {
        NSLog(@"[Bypass] ❌ PID mismatch");
        return false;
    }
    
    // Kiểm tra state
    NSLog(@"[Bypass] Shared memory state: %d (1=ready, 2-4=processing)", shm->state);
    
    // Đợi state = 1 (ready)
    int retry = 100;
    while (shm->state != 1 && retry > 0) {
        if (shm->state >= 2 && shm->state <= 4) {
            usleep(50000); // 50ms
            retry--;
        } else {
            break;
        }
    }
    
    if (shm->state != 1) {
        NSLog(@"[Bypass] ❌ Shared memory not ready, state=%d", shm->state);
        return false;
    }
    
    // Lấy active key
    uint64_t active_key = hs_get_active_key();
    NSLog(@"[Bypass] Active key: 0x%llx", active_key);
    
    // Lấy offset mask từ ninja.framework
    uint64_t offset_mask = 0;
    ninja_get_offset_mask_t ninja_get_offset_mask = (ninja_get_offset_mask_t)dlsym(RTLD_DEFAULT, "ninja_get_offset_mask");
    
    if (ninja_get_offset_mask) {
        offset_mask = ninja_get_offset_mask();
        NSLog(@"[Bypass] Offset mask: 0x%llx", offset_mask);
    } else {
        // Thử tìm hàm bằng offset cứng nếu không export
        // Cần xác định offset của ninja_get_offset_mask từ IDA
        NSLog(@"[Bypass] ⚠️ ninja_get_offset_mask not found via dlsym, trying offset search...");
        
        // Tạm thời dùng offset_mask = 0 nếu không tìm thấy
        // Bạn cần tìm offset thực tế của hàm này
        offset_mask = 0;
        NSLog(@"[Bypass] Using offset_mask = 0 (may cause incorrect decryption)");
    }
    
    // Copy encrypted offsets từ shared memory
    uint8_t decrypted_offsets[528];
    memcpy(decrypted_offsets, shm->encrypted_offsets, 528);
    
    // XOR decrypt với active_key và offset_mask
    uint64_t *offsets_ptr = (uint64_t *)decrypted_offsets;
    uint64_t xor_key = active_key ^ offset_mask;
    
    NSLog(@"[Bypass] XOR key: 0x%llx", xor_key);
    
    for (int i = 0; i < 528 / 8; i++) {
        offsets_ptr[i] ^= xor_key;
    }
    
    // Ghi offsets đã giải mã vào bộ nhớ
    uintptr_t g_offsets_addr = ninja_slide + OFFSET_G_OFFSETS;
    memcpy((void *)g_offsets_addr, decrypted_offsets, 528);
    
    NSLog(@"[Bypass] ✅ Offsets written to 0x%llx", g_offsets_addr);
    
    // Đặt cờ g_offsets_loaded = 1
    uintptr_t g_offsets_loaded_addr = ninja_slide + OFFSET_G_OFFSETS_LOADED;
    *(uint8_t *)g_offsets_loaded_addr = 1;
    
    NSLog(@"[Bypass] ✅ g_offsets_loaded set to 1 at 0x%llx", g_offsets_loaded_addr);
    
    // Xóa dữ liệu nhạy cảm khỏi stack
    memset(decrypted_offsets, 0, 528);
    
    NSLog(@"[Bypass] 🎉 Offsets decryption complete!");
    return true;
}

// Hàm vá trạng thái login
static bool patch_login_state(uintptr_t ninja_slide) {
    uintptr_t addr_logged_in = ninja_slide + OFFSET_ADDR_LOGGED_IN;
    
    // Đọc trạng thái hiện tại
    uint8_t current_state = *(uint8_t *)addr_logged_in;
    NSLog(@"[Bypass] Current login state at 0x%llx: %d", addr_logged_in, current_state);
    
    // Vá thành 1 (đã login)
    *(uint8_t *)addr_logged_in = 1;
    
    // Kiểm tra lại
    uint8_t new_state = *(uint8_t *)addr_logged_in;
    
    if (new_state == 1) {
        NSLog(@"[Bypass] ✅ LOGIN PATCH SUCCESS! (0x%llx: %d -> %d)", addr_logged_in, current_state, new_state);
        return true;
    } else {
        NSLog(@"[Bypass] ❌ LOGIN PATCH FAILED! (0x%llx: %d -> %d)", addr_logged_in, current_state, new_state);
        return false;
    }
}

// Thread chạy bypass
static void bypass_thread(void) {
    NSLog(@"[Bypass] Bypass thread started");
    
    // Đợi ninja.framework được load
    uintptr_t ninja_slide = 0;
    int retry = 50;
    
    while (ninja_slide == 0 && retry > 0) {
        ninja_slide = get_ninja_slide();
        if (ninja_slide == 0) {
            usleep(100000); // 100ms
            retry--;
        }
    }
    
    if (ninja_slide == 0) {
        NSLog(@"[Bypass] ❌ Cannot find ninja.framework after retries");
        return;
    }
    
    NSLog(@"[Bypass] ninja.framework slide: 0x%llx", ninja_slide);
    
    // Đợi Helpshift khởi tạo shared memory
    NSLog(@"[Bypass] Waiting for Helpshift initialization...");
    sleep(1);
    
    // Thử giải mã offsets
    bool offsets_ok = decrypt_and_patch_offsets(ninja_slide);
    
    // Vá login state
    bool login_ok = patch_login_state(ninja_slide);
    
    if (offsets_ok && login_ok) {
        NSLog(@"[Bypass] 🎉 ALL PATCHES SUCCESSFUL!");
    } else {
        NSLog(@"[Bypass] ⚠️ Some patches failed - offsets=%d, login=%d", offsets_ok, login_ok);
    }
}

// Hook dlsym để debug
static void *(*original_dlsym)(void *handle, const char *symbol);
static void *hooked_dlsym(void *handle, const char *symbol) {
    void *result = original_dlsym(handle, symbol);
    
    if (symbol) {
        if (strcmp(symbol, "hs_get_shm_ptr") == 0) {
            NSLog(@"[Bypass] 🔍 dlsym(hs_get_shm_ptr) = %p", result);
        } else if (strcmp(symbol, "hs_get_active_key") == 0) {
            NSLog(@"[Bypass] 🔍 dlsym(hs_get_active_key) = %p", result);
        } else if (strcmp(symbol, "ninja_get_offset_mask") == 0) {
            NSLog(@"[Bypass] 🔍 dlsym(ninja_get_offset_mask) = %p", result);
        }
    }
    
    return result;
}

// Constructor - chạy khi dylib được load
__attribute__((constructor)) static void initialize(void) {
    NSLog(@"[Bypass] ========================================");
    NSLog(@"[Bypass] 🚀 Ninja Bypass Dylib LOADED!");
    NSLog(@"[Bypass] ========================================");
    
    // Hook dlsym để theo dõi
    struct rebinding rebindings[] = {
        {"dlsym", (void *)hooked_dlsym, (void **)&original_dlsym}
    };
    rebind_symbols(rebindings, 1);
    NSLog(@"[Bypass] ✅ dlsym hook installed");
    
    // Tạo thread bypass
    pthread_t thread;
    pthread_create(&thread, NULL, (void *(*)(void *))bypass_thread, NULL);
    pthread_detach(thread);
    
    NSLog(@"[Bypass] ✅ Bypass thread created");
}
