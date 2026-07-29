// Tweak.xm - Dùng fishhook để hook
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <string>
#import <cstring>
#import <CommonCrypto/CommonCrypto.h>
#import <dlfcn.h>
#import <sys/mman.h>
#import <unistd.h>
#import <mach-o/dyld.h>
#import <fishhook.h>

// ==================== GLOBAL VARIABLES ====================

extern "C" {
    void *g_shm;
    uint64_t g_active_key;
    uint32_t g_user_id;
    uint8_t g_aes_key[32];
    uint64_t g_nonce;
    uint32_t g_remaining_seconds;
    uint32_t g_heartbeat_interval;
    std::string g_username;
    std::string g_key;
    std::string g_device_id;
    std::string g_version;
    std::string g_server_base;
    std::string g_session_key;
    std::string g_heartbeat_token;
}

// ==================== STRUCT SHARED MEMORY ====================

struct NinjaShm {
    uint8_t unknown1[8];
    uint64_t pid;
    uint8_t unknown2[6];
    uint8_t status;
    uint32_t version;
    uint32_t build_version;
    uint32_t flags;
    uint8_t unknown3[12];
    uint64_t nonce;
    uint8_t unknown4[8];
    uint32_t remaining_sec;
};

// ==================== HARDCODED DATA ====================

#define HARDCODED_USERNAME "A9Der4qHxPbmAyfLa3Ka109y2fcYrCsa"
#define HARDCODED_KEY "A9Der4qHxPbmAyfLa3Ka109y2fcYrCsa"
#define HARDCODED_DEVICE_ID "BD0773FE-2C91-40DA-89A5-498BA7F54DF1"
#define HARDCODED_VERSION "56.26.0"
#define HARDCODED_BUILD_VERSION 562600
#define HARDCODED_SESSION_KEY "bd9485e5db686393032a3078364ded93801dd4b87d0978156541c8f7d6f4f5c8"
#define HARDCODED_HEARTBEAT_TOKEN "eaa0d651dfd7a0e91c46c519240a79f31b5f83d3760a10017f31678406c5d3b4"
#define HARDCODED_USER_ID 156417
#define HARDCODED_HEARTBEAT_INTERVAL 60
#define HARDCODED_REMAINING_SECONDS 2563027
#define HARDCODED_NONCE 0x934fdc2833e915e8

// ==================== FIND SYMBOLS ====================

static void* find_symbol(const char* name) {
    void *handle = dlopen(NULL, RTLD_LAZY);
    if (!handle) return NULL;
    void *sym = dlsym(handle, name);
    dlclose(handle);
    return sym;
}

// ==================== GET GLOBAL ADDRESS ====================

static void* get_global_address(const char* name) {
    void *handle = dlopen(NULL, RTLD_LAZY);
    if (!handle) return NULL;
    void *sym = dlsym(handle, name);
    dlclose(handle);
    return sym;
}

// ==================== SHARED MEMORY ====================

static void* init_shared_memory() {
    void *shm = malloc(sizeof(NinjaShm));
    if (!shm) {
        NSLog(@"[Bypass] malloc failed");
        return NULL;
    }
    
    mlock(shm, sizeof(NinjaShm));
    memset(shm, 0, sizeof(NinjaShm));
    
    NSLog(@"[Bypass] Shared memory created at: %p", shm);
    return shm;
}

// ==================== FIND GLOBALS ====================

static void find_globals() {
    void *p;
    
    // Các global trong bss
    p = get_global_address("__ZL5g_shm");
    if (p) {
        g_shm = *(void**)p;
        NSLog(@"[Bypass] g_shm address: %p, value: %p", p, g_shm);
    }
    
    p = get_global_address("__ZL7g_nonce");
    if (p) {
        g_nonce = *(uint64_t*)p;
        NSLog(@"[Bypass] g_nonce address: %p, value: 0x%llx", p, g_nonce);
    }
    
    p = get_global_address("__ZL9g_user_id");
    if (p) {
        g_user_id = *(uint32_t*)p;
        NSLog(@"[Bypass] g_user_id address: %p, value: %u", p, g_user_id);
    }
    
    p = get_global_address("__ZL12g_active_key");
    if (p) {
        g_active_key = *(uint64_t*)p;
        NSLog(@"[Bypass] g_active_key address: %p", p);
    }
    
    p = get_global_address("__ZL9g_aes_key");
    if (p) {
        memcpy(g_aes_key, p, 32);
        NSLog(@"[Bypass] g_aes_key address: %p", p);
    }
    
    p = get_global_address("__ZL19g_remaining_seconds");
    if (p) {
        g_remaining_seconds = *(uint32_t*)p;
        NSLog(@"[Bypass] g_remaining_seconds address: %p", p);
    }
    
    p = get_global_address("__ZL20g_heartbeat_interval");
    if (p) {
        g_heartbeat_interval = *(uint32_t*)p;
        NSLog(@"[Bypass] g_heartbeat_interval address: %p", p);
    }
    
    // Các std::string globals
    p = get_global_address("__ZL10g_username");
    if (p) {
        g_username = *(std::string*)p;
        NSLog(@"[Bypass] g_username address: %p", p);
    }
    
    p = get_global_address("__ZL13g_session_key");
    if (p) {
        g_session_key = *(std::string*)p;
        NSLog(@"[Bypass] g_session_key address: %p", p);
    }
    
    p = get_global_address("__ZL17g_heartbeat_token");
    if (p) {
        g_heartbeat_token = *(std::string*)p;
        NSLog(@"[Bypass] g_heartbeat_token address: %p", p);
    }
    
    // Nếu g_shm NULL, tạo mới và gán
    if (g_shm == NULL) {
        NSLog(@"[Bypass] g_shm is NULL, creating new shared memory");
        void *new_shm = init_shared_memory();
        
        if (new_shm) {
            p = get_global_address("__ZL5g_shm");
            if (p) {
                *(void**)p = new_shm;
                g_shm = new_shm;
                NSLog(@"[Bypass] Assigned g_shm = %p", g_shm);
            } else {
                static void *static_shm = NULL;
                static_shm = new_shm;
                g_shm = static_shm;
                NSLog(@"[Bypass] Using static g_shm = %p", g_shm);
            }
        }
    }
}

// ==================== FUNCTION TYPES ====================

typedef void (*hs_deliver_credentials_t)(void*, void*, void*, void*, void*);

// ==================== ORIGINAL FUNCTION ====================

static hs_deliver_credentials_t original_hs_deliver_credentials = NULL;

// ==================== HOOK FUNCTION ====================

static void hooked_hs_deliver_credentials(
    void *__s,
    void *a2,
    void *a3,
    void *a4,
    void *a5
) {
    NSLog(@"[Bypass] ===== HOOKED hs_deliver_credentials =====");
    NSLog(@"[Bypass] Username: %s", __s ? (char *)__s : "NULL");
    NSLog(@"[Bypass] Device ID: %s", a3 ? (char *)a3 : "NULL");
    NSLog(@"[Bypass] Version: %s", a4 ? (char *)a4 : "NULL");
    
    @try {
        // Gán hardcoded data
        g_username = std::string(HARDCODED_USERNAME);
        g_key = std::string(HARDCODED_KEY);
        g_device_id = std::string(HARDCODED_DEVICE_ID);
        g_version = std::string(HARDCODED_VERSION);
        g_server_base = a5 ? std::string((char*)a5) : std::string("https://anubisw.com");
        
        // Gán session data
        g_session_key = std::string(HARDCODED_SESSION_KEY);
        g_heartbeat_token = std::string(HARDCODED_HEARTBEAT_TOKEN);
        
        g_heartbeat_interval = HARDCODED_HEARTBEAT_INTERVAL;
        g_remaining_seconds = HARDCODED_REMAINING_SECONDS;
        g_user_id = HARDCODED_USER_ID;
        g_nonce = HARDCODED_NONCE;
        
        // Tính active key
        uint8_t hmac_out[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_CTX ctx;
        CC_SHA256_Init(&ctx);
        CC_SHA256_Update(&ctx, HARDCODED_SESSION_KEY, (CC_LONG)strlen(HARDCODED_SESSION_KEY));
        CC_SHA256_Update(&ctx, &g_nonce, sizeof(g_nonce));
        pid_t pid = getpid();
        CC_SHA256_Update(&ctx, &pid, sizeof(pid));
        CC_SHA256_Final(hmac_out, &ctx);
        memcpy(&g_active_key, hmac_out, sizeof(uint64_t));
        
        // Ghi vào shared memory
        if (g_shm) {
            NinjaShm *shm = (NinjaShm *)g_shm;
            
            shm->status = 0;
            shm->pid = getpid();
            shm->version = 31;
            shm->build_version = HARDCODED_BUILD_VERSION;
            shm->flags = 31;
            shm->nonce = HARDCODED_NONCE;
            shm->remaining_sec = HARDCODED_REMAINING_SECONDS;
            
            __sync_synchronize();
            shm->status = 1;
            __sync_synchronize();
            
            NSLog(@"[Bypass] Shared memory updated:");
            NSLog(@"[Bypass]   status: %d", shm->status);
            NSLog(@"[Bypass]   pid: %llu", shm->pid);
            NSLog(@"[Bypass]   build: %u", shm->build_version);
            NSLog(@"[Bypass]   remaining: %u", shm->remaining_sec);
            NSLog(@"[Bypass]   nonce: 0x%llx", shm->nonce);
        } else {
            NSLog(@"[Bypass] WARNING: g_shm is NULL");
        }
        
        // KHÔNG gọi original
        NSLog(@"[Bypass] ===== BYPASS COMPLETE =====");
        
    } @catch (NSException *e) {
        NSLog(@"[Bypass] Exception: %@", e);
    }
}

// ==================== HOOK HS_HTTPS_POST ====================

typedef int (*hs_https_post_t)(const char*, const void*, int, void*, int);
static hs_https_post_t original_hs_https_post = NULL;

static int hooked_hs_https_post(const char *url, const void *data, int len, void *response, int timeout) {
    NSLog(@"[Bypass] hs_https_post: %s", url ? url : "NULL");
    return 200; // Luôn trả về thành công
}

// ==================== SETUP HOOKS ====================

static void setup_hooks() {
    // Hook hs_deliver_credentials
    void *target = find_symbol("_hs_deliver_credentials");
    if (!target) target = find_symbol("hs_deliver_credentials");
    
    if (target) {
        NSLog(@"[Bypass] Found hs_deliver_credentials at: %p", target);
        original_hs_deliver_credentials = (hs_deliver_credentials_t)target;
        
        // Dùng fishhook
        int result = rebind_symbols((struct rebinding[]){
            {"_hs_deliver_credentials", (void*)hooked_hs_deliver_credentials, (void**)&original_hs_deliver_credentials}
        }, 1);
        
        if (result == 0) {
            NSLog(@"[Bypass] Fishhook success!");
        } else {
            NSLog(@"[Bypass] Fishhook failed, trying manual hook...");
            // Fallback manual hook
            uintptr_t page = (uintptr_t)target & ~(PAGE_SIZE - 1);
            mprotect((void *)page, PAGE_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC);
            
            uint64_t addr = (uint64_t)hooked_hs_deliver_credentials;
            uint32_t *code = (uint32_t *)target;
            code[0] = 0xD2800000 | ((addr & 0xFFFF) << 5);
            code[1] = 0xF2A00000 | (((addr >> 16) & 0xFFFF) << 5);
            code[2] = 0xF2C00000 | (((addr >> 32) & 0xFFFF) << 5);
            code[3] = 0xF2E00000 | (((addr >> 48) & 0xFFFF) << 5);
            code[4] = 0xD61F0200;
            __sync_synchronize();
        }
    }
    
    // Hook hs_https_post
    void *target_http = find_symbol("_hs_https_post");
    if (!target_http) target_http = find_symbol("hs_https_post");
    
    if (target_http) {
        NSLog(@"[Bypass] Found hs_https_post at: %p", target_http);
        rebind_symbols((struct rebinding[]){
            {"_hs_https_post", (void*)hooked_hs_https_post, (void**)&original_hs_https_post}
        }, 1);
    }
}

// ==================== INIT ====================

__attribute__((constructor))
static void init() {
    NSLog(@"[Bypass] ===== DYLIB LOADED ===== PID: %d", getpid());
    
    @try {
        find_globals();
        setup_hooks();
        
        if (g_shm) {
            NinjaShm *shm = (NinjaShm *)g_shm;
            NSLog(@"[Bypass] SHM status: %d", shm->status);
        }
        
        NSLog(@"[Bypass] ===== INIT COMPLETE =====");
    } @catch (NSException *e) {
        NSLog(@"[Bypass] Init error: %@", e);
    }
}
