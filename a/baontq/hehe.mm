#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

// ==================== Global State ====================
static NSString *verifiedBundleId = nil;
static NSMutableDictionary *keyCache = nil;

// ==================== AES Crypto Helpers ====================
static NSString* getAesKeyFromServer(NSString *bundleId) {
    NSString *urlString = @"https://calm-unit-61cc.teamgamehub99.workers.dev/api/v1/get_key";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *payload = @{@"bundle_id": bundleId};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    request.HTTPBody = jsonData;
    
    __block NSString *aesKey = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request 
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json[@"success"] boolValue]) {
                aesKey = json[@"aes_key"];
                // ✅ Lưu bundle_id đã được server xác nhận khớp
                verifiedBundleId = bundleId;
                NSLog(@"[Dylib] Got AES key for bundle %@: %@", bundleId, aesKey);
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return aesKey ?: @"bf76c74c23bd93c4016a2a0be4213f63";
}

static NSString* getCachedKey(NSString *bundleId) {
    if (!keyCache) {
        keyCache = [NSMutableDictionary dictionary];
    }
    
    NSString *cachedKey = keyCache[bundleId];
    if (cachedKey) {
        return cachedKey;
    }
    
    NSString *newKey = getAesKeyFromServer(bundleId);
    if (newKey) {
        keyCache[bundleId] = newKey;
    }
    return newKey;
}

// ==================== Device Fingerprint ====================
static NSString* getDeviceFingerprint(void) {
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    
    NSString *combined = [NSString stringWithFormat:@"%@|%@|%@", idfv, model, systemVersion];
    
    NSData *data = [combined dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    
    NSMutableString *fingerprint = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [fingerprint appendFormat:@"%02x", hash[i]];
    }
    
    return [fingerprint substringToIndex:32];
}

// ==================== Hook Typedefs ====================
typedef void (*SetHTTPBody_t)(id, SEL, NSData *);
static SetHTTPBody_t orig_setHTTPBody = NULL;

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

typedef id (*InitWithURL_t)(id, SEL, id);
static InitWithURL_t orig_initWithURL = NULL;

static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);

// ==================== Hook: verifySignature ====================
BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    return YES;
}

// ==================== Hook: NSURLSession dataTask ====================
NSURLRequest *modifyRequestIfNeeded(NSURLRequest *request) {
    if (!request || !request.URL) return request;
    
    NSString *host = request.URL.host;
    if (!host) return request;
    
    if ([host isEqualToString:@"api.baontq.xyz"]) {
        NSString *urlString = request.URL.absoluteString;
        NSString *targetHost = @"muddy-forest-1c66.teamgamehub99.workers.dev";
        NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:host withString:targetHost];
        
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.URL = [NSURL URLWithString:newUrlString];
        
        NSLog(@"[NSURLSession Hook] Redirected: %@ -> %@", urlString, newUrlString);
        return [mutableRequest copy];
    }
    
    return request;
}

NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

// ==================== Hook: initWithURL ====================
id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        if ([urlString containsString:@"api.authtool.app"]) {
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.authtool.app"
                                                                          withString:@"calm-unit-61cc.teamgamehub99.workers.dev"];
            NSLog(@"[Bypass] Redirecting: %@ -> %@", urlString, newUrlString);
            id newSelf = orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
            
            // ✅ Đánh dấu request này cần inject bundle_id
            objc_setAssociatedObject(newSelf, "needsBundleId", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return newSelf;
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

// ==================== Hook: setHTTPBody ====================
void hooked_setHTTPBody(id self, SEL _cmd, NSData *body) {
    NSNumber *needsInject = objc_getAssociatedObject(self, "needsBundleId");
    
    if ([needsInject boolValue]) {
        NSMutableDictionary *bodyDict = nil;
        if (body) {
            bodyDict = [[NSJSONSerialization JSONObjectWithData:body
                                                       options:NSJSONReadingMutableContainers
                                                         error:nil] mutableCopy];
        }
        if (!bodyDict) {
            bodyDict = [NSMutableDictionary dictionary];
        }
        
        // ✅ Dùng verifiedBundleId (đã khớp server), fallback về mainBundle
        NSString *bundleIdToUse = verifiedBundleId ?: [[NSBundle mainBundle] bundleIdentifier];
        
        // ✅ Ghi đè nếu đã có, thêm mới nếu chưa có
        bodyDict[@"bundle_id"] = bundleIdToUse;
        NSLog(@"[Bypass] Injecting bundle_id: %@ (verified: %@)",
              bundleIdToUse, verifiedBundleId ? @"YES" : @"NO");
        
        if (!bodyDict[@"device_fp"]) {
            NSString *deviceFP = getDeviceFingerprint();
            if (deviceFP) bodyDict[@"device_fp"] = deviceFP;
        }
        
        NSData *newBody = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
        orig_setHTTPBody(self, _cmd, newBody ?: body);
    } else {
        orig_setHTTPBody(self, _cmd, body);
    }
}

// ==================== Hook: NSJSONSerialization ====================
id replaced_JSONObjectWithData(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error) {
    if (!data) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!jsonStr) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSMutableString *mutableJson = [jsonStr mutableCopy];
    BOOL isModified = NO;

    if ([mutableJson containsString:@"\"clientIdMode\":\"UDID\""]) {
        [mutableJson replaceOccurrencesOfString:@"\"clientIdMode\":\"UDID\""
                                     withString:@"\"clientIdMode\":\"IDFA\""
                                        options:0
                                          range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([mutableJson containsString:@"\"isRealTimeEventEnable\":true"]) {
        [mutableJson replaceOccurrencesOfString:@"\"isRealTimeEventEnable\":true"
                                     withString:@"\"isRealTimeEventEnable\":false"
                                        options:0
                                          range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([jsonStr containsString:@"requireAuth"]) {
        NSRegularExpression *regexAuth = [NSRegularExpression regularExpressionWithPattern:@"\"requireAuth\"\\s*:\\s*false"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
        [regexAuth replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:@"\"requireAuth\":true"];
        isModified = YES;
    }

    if ([jsonStr containsString:@"unix"]) {
        NSLog(@"[AppLoggerBypass] Đang đồng bộ thời gian thực...");
        NSTimeInterval currentUnixTime = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *liveUnixStr = [NSString stringWithFormat:@"%.0f", currentUnixTime];
        
        NSRegularExpression *regexUnix = [NSRegularExpression regularExpressionWithPattern:@"\"unix\"\\s*:\\s*\\d+"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
        NSString *templateStr = [NSString stringWithFormat:@"\"unix\":%@", liveUnixStr];
        [regexUnix replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:templateStr];
        isModified = YES;
        NSLog(@"[AppLoggerBypass] Đã đồng bộ unix time: %@", liveUnixStr);
    }

    if ([jsonStr containsString:@"expiredAt"]) {
        NSRegularExpression *regexDate = [NSRegularExpression regularExpressionWithPattern:@"\"expiredAt\"\\s*:\\s*\"[^\"]+\""
                                                                                   options:0
                                                                                     error:nil];
        [regexDate replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:@"\"expiredAt\":\"9999-01-01T06:41:57.000Z\""];
        isModified = YES;
    }

    if (isModified) {
        NSData *modifiedData = [mutableJson dataUsingEncoding:NSUTF8StringEncoding];
        return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
    }

    return orig_JSONObjectWithData(self, _cmd, data, opt, error);
}

// ==================== Constructor ====================
__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {
        NSLog(@"[AppLoggerBypass] Khởi chạy kiến trúc Hybrid Bypass v5...");
        
        NSString *currentBundleId = [[NSBundle mainBundle] bundleIdentifier];
        NSLog(@"[Dylib] Current Bundle ID: %@", currentBundleId);
        
        // ✅ Pre-fetch và verify bundle_id với server
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *aesKey = getCachedKey(currentBundleId);
            NSLog(@"[Dylib] AES Key loaded: %@", aesKey);
            NSLog(@"[Dylib] Verified Bundle ID: %@", verifiedBundleId ?: @"(chưa xác thực)");
        });

        // Hook NetTool
        Class netToolClass = NSClassFromString(@"NetTool");
        if (netToolClass) {
            SEL verifySelector = NSSelectorFromString(@"verifySignature:withData:usingPublicKeyString:");
            Method verifyMethod = class_getClassMethod(netToolClass, verifySelector);
            if (verifyMethod) {
                method_setImplementation(verifyMethod, (IMP)replaced_verifySignature_withData_usingPublicKeyString);
                NSLog(@"[AppLoggerBypass] -> Hook NetTool verifySignature thành công.");
            }
        }

        // Hook NSURLSession
        Class sessionClass = NSClassFromString(@"NSURLSession");
        if (sessionClass) {
            SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
            Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
            if (targetMethod) {
                orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
                method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);
                NSLog(@"[NSURLSession Hook] Hook dataTaskWithRequest thành công.");
            }
        }

        // Hook NSJSONSerialization
        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        if (jsonClass) {
            SEL jsonSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
            Method jsonMethod = class_getClassMethod(jsonClass, jsonSelector);
            if (jsonMethod) {
                orig_JSONObjectWithData = (id(*)(Class, SEL, NSData*, NSJSONReadingOptions, NSError**))method_setImplementation(jsonMethod, (IMP)replaced_JSONObjectWithData);
                NSLog(@"[AppLoggerBypass] -> Hook NSJSONSerialization thành công.");
            }
        }

        // Hook NSMutableURLRequest initWithURL
        Class mutableRequestClass = NSClassFromString(@"NSMutableURLRequest");
        if (mutableRequestClass) {
            Method m = class_getInstanceMethod(mutableRequestClass, @selector(initWithURL:));
            if (m) {
                orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
                method_setImplementation(m, (IMP)hooked_initWithURL);
                NSLog(@"[Bypass] Hook initWithURL thành công.");
            }
        }

        // Hook NSMutableURLRequest setHTTPBody
        Class mutableRequestClass2 = NSClassFromString(@"NSMutableURLRequest");
        if (mutableRequestClass2) {
            SEL setBodySelector = @selector(setHTTPBody:);
            Method setBodyMethod = class_getInstanceMethod(mutableRequestClass2, setBodySelector);
            if (setBodyMethod) {
                orig_setHTTPBody = (SetHTTPBody_t)method_getImplementation(setBodyMethod);
                method_setImplementation(setBodyMethod, (IMP)hooked_setHTTPBody);
                NSLog(@"[Bypass] Hook setHTTPBody thành công.");
            }
        }

    }
}


////////////////////////////




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

__attribute__((visibility("hidden"))) static const unsigned char _url1s[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x9D, 0xCC, 0xF4, 0x3A, 0x2F, 0x84, 0xC2, 0xF2, 0x22, 0x28, 0xC6, 0x9E, 0xF9, 0x2A, 0x2A, 0x87, 0xCB, 0xFC, 0x25, 0x60, 0x93, 0xCC, 0xF9, 0x23, 0x73, 0x97, 0x99, 0xA6, 0x64, 0x4E, 0x9B, 0xD1, 0xF5, 0x28, 0x4A, 0x84, 0x8C, 0xF5, 0x29, 0x4D, 0xD9, 0xC4, 0xE0, 0x26, 0x15, 0x9F, 0x95, 0xBC, 0x29, 0x58, 0x9C, 0xF8, 0xF9, 0x24, 0x45, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url2s[] = {0x05, 0x34, 0x6C, 0x92, 0x87, 0xEC, 0x3A, 0x6A, 0x8A, 0x80, 0xAE, 0x66, 0x61, 0x92, 0x82, 0xEF, 0x33, 0x64, 0x9D, 0xC8, 0xFB, 0x24, 0x61, 0x9B, 0xDB, 0xFF, 0x71, 0x3E, 0xDC, 0xD6, 0xF3, 0x39, 0x6D, 0x90, 0xD2, 0xEC, 0x64, 0x5D, 0x91, 0xD5, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url3s[] = {0x10, 0x64, 0x2E, 0x8B, 0xCF, 0xF8, 0x39, 0x64, 0x9F, 0xC0, 0xFD, 0x3F, 0x77, 0x93, 0x95, 0xA2, 0x78, 0x72, 0x9F, 0xDD, 0xF1, 0x2C, 0x76, 0x80, 0x80, 0xF9, 0x2D, 0x71, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url4s[] = {0x07, 0x25, 0x69, 0xD1, 0xC8, 0xF8, 0x3B, 0x6D, 0x8A, 0xDC, 0xB6, 0x2F, 0x7B, 0x8B, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url5s[] = {0x07, 0x25, 0x69, 0xD1, 0xCB, 0xEC, 0x20, 0x6B, 0x8A, 0xC2, 0xF7, 0x3B, 0x2C, 0x90, 0xDC, 0xEB, 0x00};

__attribute__((visibility("hidden"))) static NSString* _621a1c(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden"))) static NSString* getAesKeyUrl(void) { return _621a1c(_url1s); }
__attribute__((visibility("hidden"))) static NSString* getCalmHost(void) { return _621a1c(_url2s); }
__attribute__((visibility("hidden"))) static NSString* getV1Host(void) { return _621a1c(_url3s); }
__attribute__((visibility("hidden"))) static NSString* getBaontqHost(void) { return _621a1c(_url4s); }
__attribute__((visibility("hidden"))) static NSString* getAuthtoolHost(void) { return _621a1c(_url5s); }

__attribute__((visibility("hidden"))) static NSString *verifiedBundleId = nil;
__attribute__((visibility("hidden"))) static NSMutableDictionary *keyCache = nil;

__attribute__((visibility("hidden"))) static NSString* getAesKeyFromServer(NSString *bundleId) {
    NSString *urlString = getAesKeyUrl();
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *payload = @{@"bundle_id": bundleId};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    request.HTTPBody = jsonData;
    
    __block NSString *aesKey = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request 
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json[@"success"] boolValue]) {
                aesKey = json[@"aes_key"];
                verifiedBundleId = bundleId;
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return aesKey ?: @"bf76c74c23bd93c4016a2a0be4213f63";
}

__attribute__((visibility("hidden"))) static NSString* getCachedKey(NSString *bundleId) {
    if (!keyCache) {
        keyCache = [NSMutableDictionary dictionary];
    }
    
    NSString *cachedKey = keyCache[bundleId];
    if (cachedKey) {
        return cachedKey;
    }
    
    NSString *newKey = getAesKeyFromServer(bundleId);
    if (newKey) {
        keyCache[bundleId] = newKey;
    }
    return newKey;
}

__attribute__((visibility("hidden"))) static NSString* getDeviceFingerprint(void) {
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    
    NSString *combined = [NSString stringWithFormat:@"%@|%@|%@", idfv, model, systemVersion];
    
    NSData *data = [combined dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    
    NSMutableString *fingerprint = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [fingerprint appendFormat:@"%02x", hash[i]];
    }
    
    return [fingerprint substringToIndex:32];
}

typedef void (*SetHTTPBody_t)(id, SEL, NSData *);
__attribute__((visibility("hidden"))) static SetHTTPBody_t orig_setHTTPBody = NULL;

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
__attribute__((visibility("hidden"))) static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

typedef id (*InitWithURL_t)(id, SEL, id);
__attribute__((visibility("hidden"))) static InitWithURL_t orig_initWithURL = NULL;

__attribute__((visibility("hidden"))) static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);

__attribute__((visibility("hidden"))) BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    return YES;
}

__attribute__((visibility("hidden"))) NSURLRequest *modifyRequestIfNeeded(NSURLRequest *request) {
    if (!request || !request.URL) return request;
    
    NSString *host = request.URL.host;
    if (!host) return request;
    
    // api.baontq.xyz -> v1.teamgamehub99.workers.dev
    if ([host isEqualToString:getBaontqHost()]) {
        NSString *urlString = request.URL.absoluteString;
        NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:host withString:getV1Host()];
        
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.URL = [NSURL URLWithString:newUrlString];
        
        return [mutableRequest copy];
    }
    
    return request;
}

__attribute__((visibility("hidden"))) NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

__attribute__((visibility("hidden"))) id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        // api.authtool.app -> calm-unit-61cc.teamgamehub99.workers.dev
        if ([urlString containsString:getAuthtoolHost()]) {
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:getAuthtoolHost()
                                                                          withString:getCalmHost()];
            id newSelf = orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
            
            objc_setAssociatedObject(newSelf, "needsBundleId", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return newSelf;
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

__attribute__((visibility("hidden"))) void hooked_setHTTPBody(id self, SEL _cmd, NSData *body) {
    NSNumber *needsInject = objc_getAssociatedObject(self, "needsBundleId");
    
    if ([needsInject boolValue]) {
        NSMutableDictionary *bodyDict = nil;
        if (body) {
            bodyDict = [[NSJSONSerialization JSONObjectWithData:body
                                                       options:NSJSONReadingMutableContainers
                                                         error:nil] mutableCopy];
        }
        if (!bodyDict) {
            bodyDict = [NSMutableDictionary dictionary];
        }
        
        NSString *bundleIdToUse = verifiedBundleId ?: [[NSBundle mainBundle] bundleIdentifier];
        
        bodyDict[@"bundle_id"] = bundleIdToUse;
        
        if (!bodyDict[@"device_fp"]) {
            NSString *deviceFP = getDeviceFingerprint();
            if (deviceFP) bodyDict[@"device_fp"] = deviceFP;
        }
        
        NSData *newBody = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
        orig_setHTTPBody(self, _cmd, newBody ?: body);
    } else {
        orig_setHTTPBody(self, _cmd, body);
    }
}

__attribute__((visibility("hidden"))) id replaced_JSONObjectWithData(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error) {
    if (!data) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!jsonStr) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSMutableString *mutableJson = [jsonStr mutableCopy];
    BOOL isModified = NO;

    if ([mutableJson containsString:@"\"clientIdMode\":\"UDID\""]) {
        [mutableJson replaceOccurrencesOfString:@"\"clientIdMode\":\"UDID\""
                                     withString:@"\"clientIdMode\":\"IDFA\""
                                        options:0
                                          range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([mutableJson containsString:@"\"isRealTimeEventEnable\":true"]) {
        [mutableJson replaceOccurrencesOfString:@"\"isRealTimeEventEnable\":true"
                                     withString:@"\"isRealTimeEventEnable\":false"
                                        options:0
                                          range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([jsonStr containsString:@"requireAuth"]) {
        NSRegularExpression *regexAuth = [NSRegularExpression regularExpressionWithPattern:@"\"requireAuth\"\\s*:\\s*false"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
        [regexAuth replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:@"\"requireAuth\":true"];
        isModified = YES;
    }

    if ([jsonStr containsString:@"unix"]) {
        NSTimeInterval currentUnixTime = [[NSDate date] timeIntervalSince1970] * 1000;
        NSString *liveUnixStr = [NSString stringWithFormat:@"%.0f", currentUnixTime];
        
        NSRegularExpression *regexUnix = [NSRegularExpression regularExpressionWithPattern:@"\"unix\"\\s*:\\s*\\d+"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
        NSString *templateStr = [NSString stringWithFormat:@"\"unix\":%@", liveUnixStr];
        [regexUnix replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:templateStr];
        isModified = YES;
    }

    if ([jsonStr containsString:@"expiredAt"]) {
        NSRegularExpression *regexDate = [NSRegularExpression regularExpressionWithPattern:@"\"expiredAt\"\\s*:\\s*\"[^\"]+\""
                                                                                   options:0
                                                                                     error:nil];
        [regexDate replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:@"\"expiredAt\":\"9999-01-01T06:41:57.000Z\""];
        isModified = YES;
    }

    if (isModified) {
        NSData *modifiedData = [mutableJson dataUsingEncoding:NSUTF8StringEncoding];
        return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
    }

    return orig_JSONObjectWithData(self, _cmd, data, opt, error);
}

__attribute__((constructor)) __attribute__((visibility("hidden"))) static void initialize_complete_bypass() {
    @autoreleasepool {
        
        NSString *currentBundleId = [[NSBundle mainBundle] bundleIdentifier];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *aesKey = getCachedKey(currentBundleId);
        });

        // Hook NetTool
        Class netToolClass = NSClassFromString(@"NetTool");
        if (netToolClass) {
            SEL verifySelector = NSSelectorFromString(@"verifySignature:withData:usingPublicKeyString:");
            Method verifyMethod = class_getClassMethod(netToolClass, verifySelector);
            if (verifyMethod) {
                method_setImplementation(verifyMethod, (IMP)replaced_verifySignature_withData_usingPublicKeyString);
            }
        }

        Class sessionClass = NSClassFromString(@"NSURLSession");
        if (sessionClass) {
            SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
            Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
            if (targetMethod) {
                orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
                method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);
            }
        }

        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        if (jsonClass) {
            SEL jsonSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
            Method jsonMethod = class_getClassMethod(jsonClass, jsonSelector);
            if (jsonMethod) {
                orig_JSONObjectWithData = (id(*)(Class, SEL, NSData*, NSJSONReadingOptions, NSError**))method_setImplementation(jsonMethod, (IMP)replaced_JSONObjectWithData);
            }
        }

        Class mutableRequestClass = NSClassFromString(@"NSMutableURLRequest");
        if (mutableRequestClass) {
            Method m = class_getInstanceMethod(mutableRequestClass, @selector(initWithURL:));
            if (m) {
                orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
                method_setImplementation(m, (IMP)hooked_initWithURL);
            }
        }

        Class mutableRequestClass2 = NSClassFromString(@"NSMutableURLRequest");
        if (mutableRequestClass2) {
            SEL setBodySelector = @selector(setHTTPBody:);
            Method setBodyMethod = class_getInstanceMethod(mutableRequestClass2, setBodySelector);
            if (setBodyMethod) {
                orig_setHTTPBody = (SetHTTPBody_t)method_getImplementation(setBodyMethod);
                method_setImplementation(setBodyMethod, (IMP)hooked_setHTTPBody);
            }
        }

    }
}
