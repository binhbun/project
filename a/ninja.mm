// Tweak.xm - FINAL WORKING
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
    bool g_offsets_loaded;
    void *g_offsets;
    uint32_t g_offsets_version;
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

// ==================== FAKE RESPONSE ====================

static const char* FAKE_AUTH_RESPONSE = 
"{\"status\":\"ok\",\"user_id\":156417,"
"\"ed25519_signature\":\"250ae49cc587b90e6263ff008e578d0047d68dcb4e3e6078857554f1b007212aeb0bbeaf03a3ec5f3eeccff8696c082533fbde5438e68228986fe2d3e3f13843\","
"\"ed25519_public\":\"ead13d1ceb0b50a34593f51e2a620872da50b81fc196e14a039fa0b82f8e957f\","
"\"encrypted_config\":{"
"\"alg\":\"aes-256-gcm\","
"\"n\":\"a3ecb4b81346d48c3bfcf954\","
"\"c\":\"5ea169f7fd5e1d644f5820827986460233aab5c74eec2d81a0b2a1ad4f3ca5764e51c9eb3c0da4e93d86f89d738d00b6eaea8fab05a9ff7f23cb8fedeb18bcece68a3f7130edb1bd92b8e4422b26b4cf253a208c0e583f33b4de9f952c74b84a5208c4226f6df8c30a6141e7586b8152be832291658afa2f53c2d0cf9fc86899ee98913d4eaada2e55a820e9d531b4051b65812fabd5d9e3fd8f09919c878da9db947f47f147e55249c9c2e43d0b5a6ea07a8e80a636942b8e8ced52406b1d9e944803022fbd224d4580cc29c5664dc6e0065ec7f5f2826edc066f591d03dd14365ae0f86ae1203aa9017b715319efe657a5b3d82b91f6637ae280c78f69e49c1da8f08d92aa676d8428f9a580e2f5db30bb1d4752a2bb51728a660d938216fa4fcb7ed6b3a26e55da07d70da3aa38a532f89ec1da30348f37957055820404436357f4ab289b32243caa9f9612e2d2eb9c2b792b9a6d39ec371d13a05e1e6c2b1a2cda6ea41c3b9eb47737b0f182b7b19de73eddcedbf644ce0c536398c061474f7861e67865f86272d3980c297359c7ba42897ff72fd35388eff8161d70d8514f3373ab495c3f7a558d0578e07479c2eb766e031c1a72cd9900cfabe9028359b78a90d25f76177a4dee5f1ec73f7c2e7b9e3825f4bf192868e32448bdfe12902cd22a8ef627c86dbf8cf3e814838fec954c08ea310090c27e369363ff6d026d8638dfdc8b0d2e015121187832dcc5982f681d5356ebee3c2037003e135e6fa2abff0217d315634e321496c4485f2dea51301a599d21c3e7067e8770aa230964ba8f9fc812cfa9e0763e610048b6532d2e18969ccfb608e533a14714ab94f743eb31c1093481db2611f569c274dab7834d62c5f1f8f14e934a38d7d00465d87e393cd0f0fc513568562330bc1c361a3b4be4e1d1854dfba24d4b1882c2590cdfbb40e8003e4dff93bd4138c402067f940b71351e014c4cf3d4ca0438297ee0a56bcf63d92d7f2abac83d91a6003d67ce4cbf9480d5cbb08290de748d15cd8ec35283c9df6e5e3c51c9a91c33cea345981b87d678229b88348bdbae9ea6cd624bd710ec9faeb719bc05470b8111c4aece93d73c6efd3696ad1e2ff3e47cf6641838191232118606576b537bb7ca33dcf26cb943785cda1cc0dfeab5d05e4d8b95e0a6604c4e881d9f2b676a6158c16cc605de7b8b3bad07f55ad0f7b45c98057466b2ca2cc15ee45bbfeb14da0d0493ff087a11cd762cc6ee505349838a30f455c314bc2bfa6192bd52dc45f704746b16ded2f2e31579cd6f1d34c3f47c634177c3b0880e899ac27af4f8cb020022ed50b80785e3427b3540037b03a04bb5b9017d48adbc19df42a9f17b9253b2a3d06ccd6410e98f74f8488ddb93ccaafedcc31675164e268fb6e3b346106b21886c6d3f2ccca42696b9d90aabb1a926208860813ba7338521cf510c5c3fe1871cb7cea07e1707cab5c49cb6116e0df90505ca153c3ccc7efb06eb6d5bcd525be886e653b9ae8f857f30e89c003bb8a9d4fcc2f69b5d17b66d79fdc906b1319e6f690728877d88b7475cbe6dd8a3dc4f011a1cd3b3f22c58381bf1aec3e1aee57b64c9e2527a1e5b7c2cadb2982e37f6d47059ce57eafaa91cdf4122308b5a6b813e4d5bd16215b6320cf6ddcbdd1f850918242ce46392980273074cf602af626bfbcc317c5cf32e28fa8613a9fcd1496f69908c59b7fca9d50cb24683ec8a1fdd0e89ba4ece0e00aa3c233a58120d080d32f612a37abaad7d8eed9f1d0dd239b30afbfed2d549c45b1a0637b2486fb64ab0bec43331591017b564d69f97dc2acab6838a0a6523155f60230a03ad0910a728374876736bd67627e09eece3afe8d41350529bce594999f21c96e630c38868613afa523938390c0af079d4a52a651c640ea7c46819c41518c31bd0d41425d28e711b422283fa28857b74467ed8513c11f002675066f7e278a549939532d99c35f3e0b6ec94e33866788e9cc3af20354f88309fbfa2d2375e1c2992fa83d3c9d0cb3a308c5dd94ea98b2dd38439583239034de357b03147b8017fa03613ec675a4c3f05e0b8d7879deb0f114c8457f24a48e3cbda719d56263b6c9c35d79d294cbc3a00a0dd11a9f133a9ea3be9ebfc529aba078232d8b70e5a31e811fda4e04f70b4330ba86f79191dbe715021a7f694f1aa7b31cf9014a0a684f83a42de3bd13950da90d6730a7dcc99af24ee8143d7a4db110a34af8ead1254160817eaa1cb7b175cd30d32ee936d1ffea2db15f6a8b3284dfa50dd70d7ccd0f692a168e79f91a921d4e39b8c051e954d52d1ffe2748922fbd3d85e82040a737d53f5218960f21a2170e5cf97abd3db254e8efa71f4ed33ce8cec5412768fb4e951603e26d19441545e6788aaf15f5c8d4be303824ef8164cdd6192a78d8b5b2a07eda2e6742c1eb3916769459e898754f1c4dabdba47118f8553b625e3758e2aeed4a0fc97493f68f60c5a52ddf4300f0f2eac61728af1a05d5be7780ead044355fcfc329f145e09de74eacfe2dee41d94beadc767fa549ed19743af939c2548af3732d001a2e4c9c6a49f17d004ee74d3d9d7940fc6a1b0ec1c0e785f6a48fbd17fc165995f6e778939ead7bd821b00aa627e12b7e270d49046cca03f0a98b5927f7f\","
"\"t\":\"c73f9b0e82bc6dd4a11642699a731374\"},"
"\"session_key\":\"bd9485e5db686393032a3078364ded93801dd4b87d0978156541c8f7d6f4f5c8\","
"\"heartbeat_token\":\"eaa0d651dfd7a0e91c46c519240a79f31b5f83d3760a10017f31678406c5d3b4\","
"\"heartbeat_interval\":60,\"remaining_seconds\":2563027}";

// ==================== FIND SYMBOLS ====================

static void* find_symbol(const char* name) {
    void *handle = dlopen(NULL, RTLD_LAZY);
    if (!handle) return NULL;
    void *sym = dlsym(handle, name);
    dlclose(handle);
    return sym;
}

// ==================== FIND HS_HTTPS_POST BY OFFSET ====================

static void* find_hs_https_post_by_offset() {
    void *deliver = find_symbol("_hs_deliver_credentials");
    if (!deliver) deliver = find_symbol("hs_deliver_credentials");
    
    if (!deliver) {
        NSLog(@"[Bypass] Cannot find hs_deliver_credentials");
        return NULL;
    }
    
    Dl_info info;
    if (dladdr(deliver, &info) == 0) {
        NSLog(@"[Bypass] Cannot get info for hs_deliver_credentials");
        return NULL;
    }
    
    uintptr_t base = (uintptr_t)info.dli_fbase;
    NSLog(@"[Bypass] libHelpshift.dylib base: %p", (void*)base);
    NSLog(@"[Bypass] hs_deliver_credentials at: %p (offset 0x%llx)", deliver, (uint64_t)deliver - base);
    
    uint64_t https_offset = 0x81EC;
    void *https_post = (void *)(base + https_offset);
    NSLog(@"[Bypass] Calculated hs_https_post at: %p (offset 0x%llx)", https_post, https_offset);
    
    return https_post;
}

// ==================== SHARED MEMORY ====================

static void* init_shared_memory() {
    void *shm = malloc(sizeof(NinjaShm));
    if (!shm) return NULL;
    
    mlock(shm, sizeof(NinjaShm));
    memset(shm, 0, sizeof(NinjaShm));
    
    uint64_t *magic = (uint64_t *)shm;
    magic[0] = 0xDEADC0FEDEADC0FEULL;
    magic[65] = 0xCAFEBABECAFEBABEULL;
    
    NinjaShm *ninja = (NinjaShm *)shm;
    ninja->pid = getpid();
    ninja->status = 1;
    ninja->build_version = HARDCODED_BUILD_VERSION;
    ninja->flags = 31;
    ninja->nonce = HARDCODED_NONCE;
    ninja->remaining_sec = HARDCODED_REMAINING_SECONDS;
    
    NSLog(@"[Bypass] Shared memory created at: %p", shm);
    return shm;
}

// ==================== FIND GLOBALS ====================

static void find_globals() {
    void *p;
    
    p = find_symbol("__ZL5g_shm");
    if (!p) p = find_symbol("g_shm");
    if (p) {
        g_shm = *(void**)p;
        NSLog(@"[Bypass] g_shm found: %p", g_shm);
    }
    
    if (g_shm == NULL) {
        void *new_shm = init_shared_memory();
        if (new_shm && p) {
            *(void**)p = new_shm;
            g_shm = new_shm;
        } else if (new_shm) {
            static void *static_shm = new_shm;
            g_shm = static_shm;
        }
        NSLog(@"[Bypass] Assigned g_shm = %p", g_shm);
    }
    
    p = find_symbol("__ZL16g_offsets_loaded");
    if (p) {
        g_offsets_loaded = *(bool*)p;
        NSLog(@"[Bypass] g_offsets_loaded = %d", g_offsets_loaded);
    }
}

// ==================== PERFORM BYPASS ====================

static void perform_bypass() {
    pthread_mutex_lock(&bypass_mutex);
    if (bypass_done) {
        pthread_mutex_unlock(&bypass_mutex);
        return;
    }
    bypass_done = true;
    pthread_mutex_unlock(&bypass_mutex);
    
    NSLog(@"[Bypass] ===== PERFORMING BYPASS =====");
    
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
    
    uint8_t hmac_out[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, HARDCODED_SESSION_KEY, (CC_LONG)strlen(HARDCODED_SESSION_KEY));
    CC_SHA256_Update(&ctx, &g_nonce, sizeof(g_nonce));
    pid_t pid = getpid();
    CC_SHA256_Update(&ctx, &pid, sizeof(pid));
    CC_SHA256_Final(hmac_out, &ctx);
    memcpy(&g_active_key, hmac_out, sizeof(uint64_t));
    
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
    }
    
    NSLog(@"[Bypass] ===== BYPASS COMPLETE =====");
}

// ==================== CHECK OFFSETS LOADED ====================

static void check_offsets_loaded() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        void *p = find_symbol("__ZL16g_offsets_loaded");
        if (p) {
            g_offsets_loaded = *(bool*)p;
            NSLog(@"[Bypass] g_offsets_loaded = %d", g_offsets_loaded);
            if (g_offsets_loaded) {
                NSLog(@"[Bypass] ✅ Offsets loaded successfully!");
            } else {
                NSLog(@"[Bypass] ⚠️ Offsets not loaded yet");
            }
        }
    });
}

// ==================== HOOK hs_https_post ====================

typedef int (*hs_https_post_t)(const char*, const char*, int, std::string*, int);
static hs_https_post_t original_hs_https_post = NULL;

static int hooked_hs_https_post(const char *url, const char *data, int len, std::string *response, int timeout) {
    NSLog(@"[Bypass] ===== hs_https_post CALLED =====");
    NSLog(@"[Bypass] URL: %s", url ? url : "NULL");
    
    if (url && (strstr(url, "auth") || strstr(url, "deliver") || strstr(url, "ninja"))) {
        NSLog(@"[Bypass] Intercepting AUTH request - returning fake response");
        perform_bypass();
        
        if (response) {
            *response = std::string(FAKE_AUTH_RESPONSE);
            NSLog(@"[Bypass] Fake auth response assigned! (len: %zu)", response->length());
        }
        return 200;
    }
    
    if (url && strstr(url, "heartbeat")) {
        NSLog(@"[Bypass] Intercepting HEARTBEAT request");
        if (response) {
            *response = "{\"encrypted_response\":{\"n\":\"cc5fd21845faf599eff8667b\",\"c\":\"85fe99befeb470c10c8fbe1272faf79e7e86f10645dda899324d1629cb5d651b133479e8322c107fa53d205214b27ec8100db4ba815d4401d3503c2f6e7d2d16f624fd9ae9529cfd8f59db1eb1c51e95977933cdfcd2ec2d2bab3edb374c\",\"t\":\"d634105d18a6ee610f4b9f57102acde2\"}}";
        }
        return 200;
    }
    
    if (original_hs_https_post) {
        return original_hs_https_post(url, data, len, response, timeout);
    }
    return 404;
}

// ==================== HOOK hs_deliver_credentials ====================

typedef void (*hs_deliver_credentials_t)(void*, void*, void*, void*, void*);
static hs_deliver_credentials_t original_hs_deliver_credentials = NULL;

static void hooked_hs_deliver_credentials(
    void *__s, void *a2, void *a3, void *a4, void *a5
) {
    NSLog(@"[Bypass] ===== hs_deliver_credentials CALLED =====");
    NSLog(@"[Bypass] Username: %s", __s ? (char *)__s : "NULL");
    perform_bypass();
}

// ==================== SETUP HOOKS ====================

static void setup_hooks() {
    struct rebinding rebindings[2];
    int count = 0;
    
    // Hook hs_deliver_credentials
    void *target = find_symbol("_hs_deliver_credentials");
    if (!target) target = find_symbol("hs_deliver_credentials");
    
    if (target) {
        rebindings[count].name = "_hs_deliver_credentials";
        rebindings[count].replacement = (void*)hooked_hs_deliver_credentials;
        rebindings[count].replaced = (void**)&original_hs_deliver_credentials;
        count++;
        NSLog(@"[Bypass] Hooked hs_deliver_credentials at: %p", target);
    }
    
    // Hook hs_https_post by offset
    void *target_post = find_hs_https_post_by_offset();
    
    if (target_post) {
        original_hs_https_post = (hs_https_post_t)target_post;
        
        const char* mangled = "__ZL13hs_https_postPKcS0_iRNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEi";
        rebindings[count].name = mangled;
        rebindings[count].replacement = (void*)hooked_hs_https_post;
        rebindings[count].replaced = (void**)&original_hs_https_post;
        count++;
        NSLog(@"[Bypass] Hooked hs_https_post at: %p (by offset)", target_post);
    } else {
        NSLog(@"[Bypass] WARNING: Cannot find hs_https_post");
    }
    
    if (count > 0) {
        rebind_symbols(rebindings, count);
    }
}

// ==================== FORCE BYPASS ====================

static void force_bypass_after_delay() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        perform_bypass();
        check_offsets_loaded();
    });
}

// ==================== INIT ====================

__attribute__((constructor))
static void init() {
    NSLog(@"[Bypass] ===== DYLIB LOADED ===== PID: %d", getpid());
    
    @try {
        find_globals();
        setup_hooks();
        force_bypass_after_delay();
        NSLog(@"[Bypass] ===== INIT COMPLETE =====");
    } @catch (NSException *e) {
        NSLog(@"[Bypass] Init error: %@", e);
    }
}
