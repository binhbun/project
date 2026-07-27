// Tweak.xm - Bypass hoàn toàn, không cần server

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import <fishhook.h>
#import <string>

// ============================================
// DỮ LIỆU CỨNG - FAKE KEY
// ============================================
#define FAKE_USERNAME "GMVMOBABINHBUN8BALLVIPPRO2026"
#define FAKE_KEY "GMVMOBABINHBUN8BALLVIPPRO2026"
#define FAKE_DEVICE_ID "BD0773FE-2C91-40DA-89A5-498BA7F54DF1"
#define FAKE_VERSION "56.26.0"
#define FAKE_SERVER_BASE "http://localhost/"

// ============================================
// FAKE RESPONSE - Giả lập server trả về
// ============================================
static NSString* getFakeAuthResponse() {
    return @"{"
        "\"status\":\"ok\","
        "\"user_id\":832159,"
        "\"ed25519_signature\":\"d7a59db6c1c6f3d1d403abde0cef644add4de6bd68776c9b815df204e2a3666a18460303db8dcaca2271ae55c7763aa2a209e3b9ced0ba9b13b69d8600de5b34\","
        "\"ed25519_public\":\"ead13d1ceb0b50a34593f51e2a620872da50b81fc196e14a039fa0b82f8e957f\","
        "\"encrypted_config\":{"
            "\"alg\":\"aes-256-gcm\","
            "\"n\":\"e5434c001bb38be0bbd423f3\","
            "\"c\":\"e8234814fd3c2c0178a038b2a0580b05d1891cdeacc5eca6d6a8674a971b7effef3756cd95c5054ff18c77a9957eeaf58ab47974e8ee312838f360d71feb32fbb4dff79aa77af37a8d054dfd77e4a40b43ae2cdda374a406a61451c8af5f793fc4e7fd5fcb4a93aee6eb80020595e1a8701abd7334d1edd18da85873aa43648613a8b9fc32b1c745e0c31a1df7c155249e6447b38ed254b16aeb5a88875966a4a1715cf1bc703e7cd5cd27859c697507a115ebe5460d916f22ee1c7b403e2f4e1c9ce983fb4d4b4648965fcde8fd62090a4e81a8a7a57be6d383a40060ab4b619e38e4acf299714804ba9c0264d8b38c758bc49c6bb7dd5173a660cee40d70f4bd206e65450bdc8a7bead62a2eae63726fba760e294384a6002adbec326541593f49ac727224a5f40b6ef09df7ea54e94e8d5acc5706262ac96b190f1542e7dd94fd275bd25c4155c3e2cb0fcdc99b5b3e0994982952428c1f2a7acc5aee218476c36bff65ec3cbad8328981d6b2334a541d6aefe01be6372f3e7238fa60fcb89fdbc3a4872dac196cf8eb0c69aff6e41546e1e51f1d3c743a1402534b64f6272adb4486161320e3fa6200a2bf95869fb18da7e27c3acf8e8afac3cee939d7fcef13cc7993c0565370e6efbdf8076e34943a127f05ad1e7f5249a91cbb889579626b79ef71282997c2fb001350af70cc0a53ece9b7fd2aa16fefbfb319996e5058a35c9c0fa3ee40882512984798f4c7cabdb8ed39595fa145822d837ca3c740e9642488531e120cbb8602ea6de248bae710b91b95fc7ad26b04ef5a51025552da1b89872e404f50f0419d18f90bb05ef47bdc65f94bb858a3e831da2b25a16cdd11268bfbc491ea0498c67d8dcc6d4f0b70ffb4d59fb78c5a62e5c6337706a280b5d11ee7aecaa56d5c340392869ba297528ee5013ad707bb89df97cb4000f0f5cba9c7842b941c7600482285bfcb71c225b895a733c6856f9542ad8be99c7b92c27cd7a3a9c3133902ddc34a10d4e0c18b0a18e960fd21d6bb26821599150a0568a0f8ec0c63447f9347a5898b3c4beef1be48215a7feba0783539618d45a9c076a7b50dede1710c4d9a83c3e3ce4820831fc213cff03b87d9bb4fe9f4181a6701e943cf292f23108fad3eac305a58283864aebf423bc800de2dd1efbfa7acf184b1bc40382606a6a731a863eb6dea382474efe6efb489ba2398a709643153cc6f67a214cf1866e1dda6928778d57221d01e6e6535eb4094c78e6977c58c74b0f7e03b797fbb387a277b3eb4bbf31e3145024213a10bcda17b1d5c8c7516243b85f59fa85ca634d4d8a522bbfc059c087998000b32d8677b83d8c542b18d775b1838e247bdf12af646764e53cfe97a3cf60f1aa8185576a9f13f3c26f131b03a58d5d2b7c5be37b60bb3f58661f1dc5fd5a49ac0f36e8321bfae8fb45db81a8b8138ccdc43c7c97e035028a4d2ddb27f81cc0853ce316d7656d7ffadbe43f7ac583ff63af807173c9b91c451492fc566359128fc9816d755abd210e0cbe728c21affbb0b2154041ffeaf4fc73ba9a99734665cdadce1c1455b53b69a6fa6d44499ada6c36bf0a9fead5fe76036beab94a1a15b2cdbaacad9be968b5aab04464b2ef28d8bb5cf8869ace9a378cec00e6ff0d165913b16dee2dcd32cdcb8b91781d071f42daaaecfa390aa45cb3c664f3783dd6584efa20dcef16106be413ad17833f5d5bcbd4458b8910c078066b493cf479f0a66076890c7272e89d6194f19f3264d10aa4ff446eab1479218f867907a7cd31cc529ff60cc849ec43fe9ff26e114f0a00c97431e7b6fe2f2d884d66c3a811e446afc3874bbb09b85d8e532756f38bbc0c49ca96a83f5c1959bcb83cb6fb235465931f4582e9cdd757f2d010a67749b60965678ce1ed98096770a86439af5d2c014fc97dc296fde7f7fe91351d03c9ce1d1d3f3fdbf95bb9ac25dcaa357dbb26f46248610c08ffafbb7a0b52bab1a86b893588a6ad926697e1eacb155d24cc0d110ed46af2641b5266eeb7380c99ea5d6f360fb66d0849a150549ce56120af6a91fd50e7259043655d91926acc5a87639f7b42aea94a9888868de0bc4bf44a7848415222b08038c8eede7e2004eb7d4081ccee54ae6a0583efa48a41a499b6bc7bbb0d18b0d50a92aed8e5942555258441c50acfc070f0d9a70d02248b1468d9327cc6e1b5f51afdfdab52bd92c56dc9cfca8aa823f48cfb9e552f23f9f933208c045ddfd9bbf0f429aacfb67556b9f9692c7d7cadc42e6190cb339a049623945b6d0e75bb88eafea50f2878d55e1190ac6facb7fddef264b83c5ef624d6086aa54e5dd1d41da2f2190dc50133a3cea3e9d9576e406f197d0347f554a07ae87d9b06dc1a229f27925e3c993ec3d118de60f6c4d176549fcbd2f1b3dc01cf5ee91afde86e9c9feaeb8de4057c927aa13edf5c089449e1b67d64429d97d479abe6922e7966a479cde75649f9f63ebf46aa9510118a4a43a8aed71db7126d0ce25a1f3cb116ec156575add5fb5525c55c8d92679c85a6292578c09bb719ea8bd33a4ff9c1ab725422b4d425f47336845c7c06492ea083b9cbb475c57943438425fcc7efb154e4bb0260ac1f52d9e7c56276bbddcbf97886f86634d7ee095105cd228eba8c118cbc0c405d8\","
            "\"t\":\"81eba2c093dacefb1729dfe07e3d799e\""
        "},"
        "\"session_key\":\"dc10f0dec118f2dd2b0e6a10295a03f60bf9fd0d64420731224a09129d8efd04\","
        "\"heartbeat_token\":\"14408f071c8c7382ca05aafbf8fe53399403f3121f8119f6f97abbb2ccd6889f\","
        "\"heartbeat_interval\":60,"
        "\"remaining_seconds\":2584771"
    "}";
}

// ============================================
// Function Pointers
// ============================================
typedef void (*hs_deliver_credentials_t)(const char*, const char*, const char*, const char*, const char*);
typedef int (*hs_https_post_t)(const char*, const void*, int, void*, unsigned int);

static hs_deliver_credentials_t orig_hs_deliver_credentials = NULL;
static hs_https_post_t orig_hs_https_post = NULL;

// Biến để biết đã bypass chưa
static BOOL bypassCompleted = NO;

// ============================================
// HOOK hs_https_post - KHÔNG GỬI REQUEST, TRẢ VỀ FAKE RESPONSE
// ============================================
int hooked_hs_https_post(const char* url, const void* data, int data_len, void* response, unsigned int timeout) {
    NSLog(@"[InjectAuth] 🌐 HOOKED hs_https_post");
    NSLog(@"[InjectAuth] URL: %s", url ? url : "NULL");
    
    // Nếu là auth request -> TRẢ VỀ FAKE RESPONSE LUÔN
    if (url && strstr(url, "auth.php")) {
        NSLog(@"[InjectAuth] 🚀 BYPASS: Returning fake response without server request!");
        NSLog(@"[InjectAuth] 📦 Fake key: %s", FAKE_KEY);
        
        // Tạo fake response
        NSString *fakeResponse = getFakeAuthResponse();
        NSData *fakeData = [fakeResponse dataUsingEncoding:NSUTF8StringEncoding];
        
        // response là std::string*, copy fake data vào
        if (response) {
            std::string *respStr = (std::string*)response;
            respStr->assign((const char*)[fakeData bytes], [fakeData length]);
            NSLog(@"[InjectAuth] ✅ Fake response injected into response object!");
        }
        
        bypassCompleted = YES;
        return 200; // Trả về HTTP 200
    }
    
    // Các request khác vẫn gửi bình thường
    if (orig_hs_https_post) {
        return orig_hs_https_post(url, data, data_len, response, timeout);
    }
    
    return 0;
}

// ============================================
// HOOK hs_deliver_credentials - ÉP NHẬN FAKE CREDENTIALS
// ============================================
void hooked_hs_deliver_credentials(const char* __s, const char* a2, const char* a3, const char* a4, const char* a5) {
    NSLog(@"[InjectAuth] 🔥 HOOKED hs_deliver_credentials");
    NSLog(@"[InjectAuth] 📦 Injecting fake credentials!");
    NSLog(@"[InjectAuth]   username: %s", FAKE_USERNAME);
    NSLog(@"[InjectAuth]   key: %s", FAKE_KEY);
    NSLog(@"[InjectAuth]   device_id: %s", FAKE_DEVICE_ID);
    NSLog(@"[InjectAuth]   version: %s", FAKE_VERSION);
    NSLog(@"[InjectAuth]   server_base: %s", FAKE_SERVER_BASE);
    
    if (orig_hs_deliver_credentials) {
        orig_hs_deliver_credentials(
            FAKE_USERNAME,
            FAKE_KEY,
            FAKE_DEVICE_ID,
            FAKE_VERSION,
            FAKE_SERVER_BASE
        );
        NSLog(@"[InjectAuth] ✅ Auth completed with fake credentials!");
        bypassCompleted = YES;
    }
}

// ============================================
// Hook bằng FishHook
// ============================================
BOOL hook_with_fishhook() {
    NSLog(@"[InjectAuth] 🔧 Hooking with FishHook...");
    
    void* func1 = dlsym(RTLD_DEFAULT, "hs_deliver_credentials");
    if (func1) {
        struct rebinding rebind1 = {
            "hs_deliver_credentials",
            (void*)hooked_hs_deliver_credentials,
            (void**)&orig_hs_deliver_credentials
        };
        
        void* func2 = dlsym(RTLD_DEFAULT, "_ZL13hs_https_postPKcS0_iRNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEi");
        if (!func2) {
            func2 = dlsym(RTLD_DEFAULT, "hs_https_post");
        }
        
        if (func2) {
            struct rebinding rebind2 = {
                "hs_https_post",
                (void*)hooked_hs_https_post,
                (void**)&orig_hs_https_post
            };
            
            struct rebinding rebindings[] = {rebind1, rebind2};
            int result = rebind_symbols(rebindings, 2);
            
            if (result == 0) {
                NSLog(@"[InjectAuth] ✅ Both hooks installed!");
                return YES;
            }
        } else {
            int result = rebind_symbols(&rebind1, 1);
            if (result == 0) {
                NSLog(@"[InjectAuth] ✅ hs_deliver_credentials hooked!");
                return YES;
            }
        }
    }
    
    NSLog(@"[InjectAuth] ❌ FishHook failed!");
    return NO;
}

// ============================================
// Hook NSURLSession - Dự phòng
// ============================================
void hook_nsurlsession() {
    Class NSURLSession = objc_getClass("NSURLSession");
    if (!NSURLSession) return;
    
    SEL selector = sel_registerName("dataTaskWithRequest:completionHandler:");
    Method method = class_getInstanceMethod(NSURLSession, selector);
    if (!method) return;
    
    IMP originalIMP = method_getImplementation(method);
    
    IMP newIMP = imp_implementationWithBlock(^(id self, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
        NSString *url = request.URL.absoluteString;
        
        if ([url containsString:@"auth.php"]) {
            NSLog(@"[InjectAuth] 🚀 NSURLSession bypass: Returning fake response!");
            
            // Tạo fake response
            NSData *fakeData = [getFakeAuthResponse() dataUsingEncoding:NSUTF8StringEncoding];
            NSHTTPURLResponse *fakeResponse = [[NSHTTPURLResponse alloc] 
                initWithURL:request.URL
                statusCode:200
                HTTPVersion:@"HTTP/1.1"
                headerFields:@{@"Content-Type": @"application/json"}];
            
            completionHandler(fakeData, fakeResponse, nil);
            bypassCompleted = YES;
            return (NSURLSessionDataTask *)nil;
        }
        
        return ((NSURLSessionDataTask* (*)(id, SEL, NSURLRequest*, id))originalIMP)(self, selector, request, completionHandler);
    });
    
    method_setImplementation(method, newIMP);
    NSLog(@"[InjectAuth] ✅ NSURLSession hooked");
}

// ============================================
// Main Constructor
// ============================================
__attribute__((constructor))
static void initialize() {
    NSLog(@"[InjectAuth] =========================================");
    NSLog(@"[InjectAuth] 🚀 BYPASS: InjectAuth dylib loaded!");
    NSLog(@"[InjectAuth] =========================================");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @try {
            NSLog(@"[InjectAuth] ⏰ Initializing bypass...");
            NSLog(@"[InjectAuth] 📦 Fake key: %s", FAKE_KEY);
            
            // Hook với FishHook
            BOOL hooked = hook_with_fishhook();
            
            // Hook NSURLSession (dự phòng)
            hook_nsurlsession();
            
            NSLog(@"[InjectAuth] =========================================");
            NSLog(@"[InjectAuth] 📊 Bypass Status:");
            NSLog(@"[InjectAuth]   FishHook: %@", hooked ? @"✅" : @"❌");
            NSLog(@"[InjectAuth]   Key: %s", FAKE_KEY);
            NSLog(@"[InjectAuth] =========================================");
            
        } @catch (NSException *e) {
            NSLog(@"[InjectAuth] ❌ Exception: %@", e);
        }
    });
}
