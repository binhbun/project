// Tweak.xm - FINAL VERSION
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
#import <pthread.h>

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

static bool bypass_done = false;
static pthread_mutex_t bypass_mutex = PTHREAD_MUTEX_INITIALIZER;

// ==================== FIND SYMBOLS ====================

static void* find_symbol(const char* name) {
    void *handle = dlopen(NULL, RTLD_LAZY);
    if (!handle) return NULL;
    void *sym = dlsym(handle, name);
    dlclose(handle);
    return sym;
}

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
    
    p = get_global_address("__ZL5g_shm");
    if (p) {
        g_shm = *(void**)p;
        NSLog(@"[Bypass] g_shm address: %p, value: %p", p, g_shm);
    }
    
    p = get_global_address("__ZL7g_nonce");
    if (p) {
        g_nonce = *(uint64_t*)p;
        NSLog(@"[Bypass] g_nonce address: %p", p);
    }
    
    p = get_global_address("__ZL9g_user_id");
    if (p) {
        g_user_id = *(uint32_t*)p;
        NSLog(@"[Bypass] g_user_id address: %p", p);
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

// ==================== THỰC HIỆN BYPASS ====================

static void perform_bypass() {
    pthread_mutex_lock(&bypass_mutex);
    if (bypass_done) {
        pthread_mutex_unlock(&bypass_mutex);
        return;
    }
    bypass_done = true;
    pthread_mutex_unlock(&bypass_mutex);
    
    NSLog(@"[Bypass] ===== PERFORMING BYPASS =====");
    
    // Gán hardcoded data
    g_username = std::string(HARDCODED_USERNAME);
    g_key = std::string(HARDCODED_KEY);
    g_device_id = std::string(HARDCODED_DEVICE_ID);
    g_version = std::string(HARDCODED_VERSION);
    g_server_base = std::string("https://anubisw.com");
    
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
        
        NSLog(@"[Bypass] Shared memory updated!");
        NSLog(@"[Bypass]   status: %d, pid: %llu", shm->status, shm->pid);
        NSLog(@"[Bypass]   build: %u, remaining: %u", shm->build_version, shm->remaining_sec);
        NSLog(@"[Bypass]   nonce: 0x%llx", shm->nonce);
    }
    
    NSLog(@"[Bypass] ===== BYPASS COMPLETE =====");
}

// ==================== FUNCTION TYPES ====================

typedef void (*hs_deliver_credentials_t)(void*, void*, void*, void*, void*);
typedef int (*hs_https_post_t)(const char*, const void*, int, void*, int);
typedef int (*hs_https_get_t)(const char*, void*);

// ==================== ORIGINAL FUNCTIONS ====================

static hs_deliver_credentials_t original_hs_deliver_credentials = NULL;
static hs_https_post_t original_hs_https_post = NULL;
static hs_https_get_t original_hs_https_get = NULL;

// ==================== HOOK hs_deliver_credentials ====================

static void hooked_hs_deliver_credentials(
    void *__s,
    void *a2,
    void *a3,
    void *a4,
    void *a5
) {
    NSLog(@"[Bypass] ===== hs_deliver_credentials CALLED =====");
    NSLog(@"[Bypass] Username: %s", __s ? (char *)__s : "NULL");
    NSLog(@"[Bypass] Device ID: %s", a3 ? (char *)a3 : "NULL");
    NSLog(@"[Bypass] Version: %s", a4 ? (char *)a4 : "NULL");
    
    perform_bypass();
    
    // KHÔNG gọi original để bypass
}

// ==================== HOOK hs_https_post ====================

static int hooked_hs_https_post(const char *url, const void *data, int len, void *response, int timeout) {
    NSLog(@"[Bypass] hs_https_post: %s", url ? url : "NULL");
    
    // Intercept all requests
    if (url) {
        perform_bypass();
        
        // Trả về response thành công
        if (response) {
            std::string *resp = (std::string *)response;
            
            if (strstr(url, "auth") || strstr(url, "deliver") || strstr(url, "ninja")) {
                *resp = "{\"status\":\"ok\",\"user_id\":156417,\"session_key\":\"bd9485e5db686393032a3078364ded93801dd4b87d0978156541c8f7d6f4f5c8\",\"heartbeat_token\":\"eaa0d651dfd7a0e91c46c519240a79f31b5f83d3760a10017f31678406c5d3b4\",\"heartbeat_interval\":60,\"remaining_seconds\":2563027}";
            } else if (strstr(url, "heartbeat") || strstr(url, "hb")) {
                *resp = "{\"status\":\"ok\",\"new_token\":\"eaa0d651dfd7a0e91c46c519240a79f31b5f83d3760a10017f31678406c5d3b4\"}";
            } else {
                *resp = "{\"status\":\"ok\"}";
            }
        }
        return 200;
    }
    
    if (original_hs_https_post) {
        return original_hs_https_post(url, data, len, response, timeout);
    }
    return 404;
}

// ==================== HOOK hs_https_get ====================

static int hooked_hs_https_get(const char *url, void *response) {
    NSLog(@"[Bypass] hs_https_get: %s", url ? url : "NULL");
    
    if (url) {
        perform_bypass();
        if (response) {
            std::string *resp = (std::string *)response;
            *resp = "{\"status\":\"ok\"}";
        }
        return 200;
    }
    
    if (original_hs_https_get) {
        return original_hs_https_get(url, response);
    }
    return 404;
}

// ==================== SETUP HOOKS ====================

static void setup_hooks() {
    struct rebinding rebindings[3];
    int count = 0;
    
    // Hook hs_deliver_credentials
    void *target = find_symbol("_hs_deliver_credentials");
    if (!target) target = find_symbol("hs_deliver_credentials");
    
    if (target) {
        NSLog(@"[Bypass] Found hs_deliver_credentials at: %p", target);
        rebindings[count].name = "_hs_deliver_credentials";
        rebindings[count].replacement = (void*)hooked_hs_deliver_credentials;
        rebindings[count].replaced = (void**)&original_hs_deliver_credentials;
        count++;
        NSLog(@"[Bypass] Hooked hs_deliver_credentials!");
    }
    
    // Hook hs_https_post
    void *target_post = find_symbol("_hs_https_post");
    if (!target_post) target_post = find_symbol("hs_https_post");
    
    if (target_post) {
        NSLog(@"[Bypass] Found hs_https_post at: %p", target_post);
        rebindings[count].name = "_hs_https_post";
        rebindings[count].replacement = (void*)hooked_hs_https_post;
        rebindings[count].replaced = (void**)&original_hs_https_post;
        count++;
        NSLog(@"[Bypass] Hooked hs_https_post!");
    }
    
    // Hook hs_https_get
    void *target_get = find_symbol("_hs_https_get");
    if (!target_get) target_get = find_symbol("hs_https_get");
    
    if (target_get) {
        NSLog(@"[Bypass] Found hs_https_get at: %p", target_get);
        rebindings[count].name = "_hs_https_get";
        rebindings[count].replacement = (void*)hooked_hs_https_get;
        rebindings[count].replaced = (void**)&original_hs_https_get;
        count++;
        NSLog(@"[Bypass] Hooked hs_https_get!");
    }
    
    if (count > 0) {
        rebind_symbols(rebindings, count);
    }
}

// ==================== FORCE BYPASS ====================

static void force_bypass() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSLog(@"[Bypass] Forcing bypass after 1s...");
        perform_bypass();
    });
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
        
        force_bypass();
        NSLog(@"[Bypass] ===== INIT COMPLETE =====");
    } @catch (NSException *e) {
        NSLog(@"[Bypass] Init error: %@", e);
    }
}
