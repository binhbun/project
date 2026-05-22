#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#include <CommonCrypto/CommonCrypto.h>
#include <dlfcn.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <unistd.h>
#include <execinfo.h>   // ← thêm cho backtrace()

static _Thread_local int _inHook = 0;

#define ALOG(fmt, ...) do { \
    if (_inHook == 0) { \
        _inHook++; \
        NSLog(@"[AppLogger] " fmt, ##__VA_ARGS__); \
        _inHook--; \
    } \
} while(0)

#define GUARD_ENTER_RET(call) do { if (_inHook > 0) return (call); _inHook++; } while(0)
#define GUARD_ENTER_VOID(call) do { if (_inHook > 0) { (call); return; } _inHook++; } while(0)
#define GUARD_EXIT() do { _inHook--; } while(0)

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Caller Tracking
// ─────────────────────────────────────────────────────────────────────────────

// Cấu hình: số frame stack trace muốn in (không tính frame của AppLogger)
#define AL_CALLER_DEPTH  5
// Lọc frame: chỉ in frame chứa bundle prefix (để bỏ system frames)
// Đặt nil để in tất cả frames
#define AL_CALLER_FILTER @"vn.vng"     // ← đổi thành bundle prefix của app

/**
 * Trả về chuỗi caller info từ call stack.
 * - filterPrefix: nếu khác nil, chỉ lấy frame chứa chuỗi đó
 * - depth: số frame tối đa trả về
 *
 * Output ví dụ:
 *   [Caller] MyNetworkManager -[MyNetworkManager fetchUser:] (MyNetworkManager.m:42)
 */
static NSString *callerInfo(NSString * _Nullable filterPrefix, int depth) {
    NSArray<NSString *> *stack = [NSThread callStackSymbols];
    // Frame 0 = callerInfo, Frame 1 = al_xxx hook → bắt đầu từ frame 2
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    int found = 0;
    for (NSUInteger i = 2; i < stack.count && found < depth; i++) {
        NSString *frame = stack[i];
        // Bỏ qua các frame của AppLogger chính nó
        if ([frame containsString:@"al_"] || [frame containsString:@"AppLogger"]) continue;
        // Nếu có filter thì chỉ lấy frame match
        if (filterPrefix && filterPrefix.length > 0) {
            if (![frame containsString:filterPrefix]) continue;
        }
        // Rút gọn: bỏ số frame đầu "1   AppName   0x00001234 "
        NSRange r = [frame rangeOfString:@"0x" options:NSCaseInsensitiveSearch];
        NSString *clean = (r.location != NSNotFound && r.location + 12 < frame.length)
            ? [frame substringFromIndex:r.location + 11]
            : frame;
        [result addObject:[clean stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        found++;
    }
    if (result.count == 0) {
        // Fallback: nếu filter quá hẹp, lấy frame đầu tiên không phải system
        for (NSUInteger i = 2; i < MIN(stack.count, (NSUInteger)(depth + 2)); i++) {
            NSString *frame = stack[i];
            if ([frame containsString:@"al_"] || [frame containsString:@"AppLogger"]) continue;
            NSRange r = [frame rangeOfString:@"0x" options:NSCaseInsensitiveSearch];
            NSString *clean = (r.location != NSNotFound && r.location + 12 < frame.length)
                ? [frame substringFromIndex:r.location + 11]
                : frame;
            [result addObject:[clean stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            break;
        }
    }
    return result.count > 0
        ? [result componentsJoinedByString:@"\n│  ┆    "]
        : @"<unknown>";
}

// Macro tiện lợi: log caller inline sau mỗi ALOG block
#define ALOG_CALLER() do { \
    if (_inHook == 0) { \
        _inHook++; \
        NSString *_c = callerInfo(AL_CALLER_FILTER, AL_CALLER_DEPTH); \
        NSLog(@"[AppLogger] │  ↑ Caller: %@", _c); \
        _inHook--; \
    } \
} while(0)

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────────────────────────────────────

static NSString *hexBytes(const void *bytes, size_t len) {
    if (!bytes || len == 0) return @"<empty>";
    const uint8_t *b = (const uint8_t *)bytes;
    NSMutableString *s = [NSMutableString stringWithCapacity:MIN(len,48)*3];
    size_t cap = MIN(len, 48);
    for (size_t i = 0; i < cap; i++) [s appendFormat:@"%02x ", b[i]];
    if (len > 48) [s appendString:@"…"];
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

static NSString *ccAlgName(CCAlgorithm a) {
    switch(a) {
        case kCCAlgorithmAES:      return @"AES";
        case kCCAlgorithmDES:      return @"DES";
        case kCCAlgorithm3DES:     return @"3DES";
        case kCCAlgorithmRC4:      return @"RC4";
        case kCCAlgorithmRC2:      return @"RC2";
        case kCCAlgorithmBlowfish: return @"Blowfish";
        default: return [NSString stringWithFormat:@"Alg(%u)", a];
    }
}

static NSString *hmacAlgName(CCHmacAlgorithm a) {
    switch(a) {
        case kCCHmacAlgSHA1:   return @"SHA1";
        case kCCHmacAlgSHA256: return @"SHA256";
        case kCCHmacAlgSHA384: return @"SHA384";
        case kCCHmacAlgSHA512: return @"SHA512";
        case kCCHmacAlgMD5:    return @"MD5";
        default: return @"Unknown";
    }
}

static NSString *dataPreview(NSData *d, NSUInteger limit) {
    if (!d || d.length == 0) return @"<empty>";
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    if (s) return s.length > limit ? [s substringToIndex:limit] : s;
    return hexBytes(d.bytes, d.length);
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSURLSession Hook
// ─────────────────────────────────────────────────────────────────────────────

@interface NSURLSession (AL) @end
@implementation NSURLSession (AL)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class cls = [NSURLSession class];
        void (^sw)(SEL,SEL) = ^(SEL o, SEL h) {
            Method a = class_getInstanceMethod(cls, o);
            Method b = class_getInstanceMethod(cls, h);
            if (a && b) { method_exchangeImplementations(a, b); ALOG(@"✅ Hooked NSURLSession %@", NSStringFromSelector(o)); }
        };
        sw(@selector(dataTaskWithRequest:completionHandler:),
           @selector(al_dataTaskWithRequest:completionHandler:));
        sw(@selector(dataTaskWithURL:completionHandler:),
           @selector(al_dataTaskWithURL:completionHandler:));
        sw(@selector(uploadTaskWithRequest:fromData:completionHandler:),
           @selector(al_uploadTaskWithRequest:fromData:completionHandler:));
    });
}

// Hàm log request — giờ kèm caller (hàm ĐANG GỬI request)
static void _logReq(NSURLRequest *req) {
    ALOG(@"┌─ REQUEST %@ %@", req.HTTPMethod ?: @"GET", req.URL.absoluteString);
    [req.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *_) {
        ALOG(@"│  H: %@: %@", k, v);
    }];
    if (req.HTTPBody.length)
        ALOG(@"│  Body: %@", dataPreview(req.HTTPBody, 500));
    // ← THÊM: in caller (hàm đang gửi request)
    ALOG_CALLER();
    ALOG(@"└────────────────────────────");
}

// Hàm log response — caller ở đây là completion handler (hàm ĐANG NHẬN)
static void _logResp(NSURL *url, NSData *data, NSURLResponse *resp, NSError *err) {
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
    if (err) {
        ALOG(@"✗ RESP ERR %@ → %@", url.absoluteString, err.localizedDescription);
        ALOG_CALLER();
        return;
    }
    ALOG(@"┌─ RESPONSE %ld %@", (long)http.statusCode, url.absoluteString);
    if (data.length) ALOG(@"│  Body: %@", dataPreview(data, 600));
    // ← THÊM: in caller (hàm đang nhận/xử lý response)
    ALOG_CALLER();
    ALOG(@"└────────────────────────────");
}

- (NSURLSessionDataTask *)al_dataTaskWithRequest:(NSURLRequest *)req
                               completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))cb {
    _logReq(req);
    return [self al_dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        _logResp(req.URL, d, r, e);
        if (cb) cb(d, r, e);
    }];
}

- (NSURLSessionDataTask *)al_dataTaskWithURL:(NSURL *)url
                           completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))cb {
    ALOG(@"┌─ REQUEST GET %@", url.absoluteString);
    ALOG_CALLER();   // ← hàm đang gửi
    ALOG(@"└────────────────────────────");
    return [self al_dataTaskWithURL:url completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        _logResp(url, d, r, e);
        if (cb) cb(d, r, e);
    }];
}

- (NSURLSessionUploadTask *)al_uploadTaskWithRequest:(NSURLRequest *)req
                                            fromData:(NSData *)body
                                   completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))cb {
    ALOG(@"┌─ UPLOAD %@ %@ [%lu bytes]", req.HTTPMethod, req.URL.absoluteString, (unsigned long)body.length);
    ALOG_CALLER();   // ← hàm đang gửi upload
    ALOG(@"└────────────────────────────");
    return [self al_uploadTaskWithRequest:req fromData:body completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        _logResp(req.URL, d, r, e);
        if (cb) cb(d, r, e);
    }];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CCCrypt / CCHmac Interpose (kèm caller)
// ─────────────────────────────────────────────────────────────────────────────

static CCCryptorStatus al_CCCrypt(
    CCOperation op, CCAlgorithm alg, CCOptions opts,
    const void *key, size_t keyLen,
    const void *iv,
    const void *in, size_t inLen,
    void *out, size_t outAvail, size_t *outMoved)
{
    CCCryptorStatus st = CCCrypt(op, alg, opts, key, keyLen, iv, in, inLen, out, outAvail, outMoved);
    ALOG(@"🔐 CCCrypt | %@ | %@ | PKCS7=%@ ECB=%@ | key[%zu]=%@ | in[%zu]=%@ | out[%zu]=%@ | status=%d",
         (op == kCCEncrypt) ? @"ENC" : @"DEC",
         ccAlgName(alg),
         (opts & kCCOptionPKCS7Padding) ? @"Y" : @"N",
         (opts & kCCOptionECBMode)      ? @"Y" : @"N",
         keyLen, hexBytes(key, keyLen),
         inLen,  hexBytes(in, inLen),
         outMoved ? *outMoved : 0, hexBytes(out, outMoved ? *outMoved : 0),
         (int)st);
    // ← THÊM: hàm nào đang gọi encrypt/decrypt
    ALOG_CALLER();
    return st;
}

static void al_CCHmac(CCHmacAlgorithm alg,
                      const void *key, size_t keyLen,
                      const void *data, size_t dataLen,
                      void *mac)
{
    CCHmac(alg, key, keyLen, data, dataLen, mac);
    ALOG(@"🔑 CCHmac | %@ | key[%zu]=%@ | data[%zu]=%@ | mac=%@",
         hmacAlgName(alg),
         keyLen, hexBytes(key, keyLen),
         dataLen, hexBytes(data, dataLen),
         hexBytes(mac, 32));
    // ← THÊM: hàm nào đang tạo HMAC
    ALOG_CALLER();
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Keychain Interpose (kèm caller)
// ─────────────────────────────────────────────────────────────────────────────

static void _logKC(const char *op, CFDictionaryRef q) {
    NSDictionary *d = (__bridge NSDictionary *)q;
    NSString *svc  = d[(__bridge id)kSecAttrService]  ?: @"-";
    NSString *acct = d[(__bridge id)kSecAttrAccount]  ?: @"-";
    NSData   *val  = d[(__bridge id)kSecValueData];
    NSString *valStr = val ? (([[NSString alloc] initWithData:val encoding:NSUTF8StringEncoding])
                              ?: hexBytes(val.bytes, val.length)) : @"-";
    ALOG(@"🗝️  Keychain %s | svc=%@ acct=%@ val=%@", op, svc, acct, valStr);
}

static OSStatus al_SecItemAdd(CFDictionaryRef attrs, CFTypeRef *res) {
    _logKC("ADD", attrs);
    OSStatus s = SecItemAdd(attrs, res);
    ALOG(@"   → SecItemAdd: %d", (int)s);
    ALOG_CALLER();   // ← hàm đang lưu Keychain
    return s;
}
static OSStatus al_SecItemCopyMatching(CFDictionaryRef q, CFTypeRef *res) {
    _logKC("QUERY", q);
    OSStatus s = SecItemCopyMatching(q, res);
    if (s == errSecSuccess && res && *res) {
        if (CFGetTypeID(*res) == CFDataGetTypeID()) {
            NSData *d = (__bridge NSData *)*res;
            NSString *str = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
            ALOG(@"   → SecItemQuery result: %@", str ?: hexBytes(d.bytes, d.length));
        }
    } else {
        ALOG(@"   → SecItemQuery: %d", (int)s);
    }
    ALOG_CALLER();   // ← hàm đang đọc Keychain
    return s;
}
static OSStatus al_SecItemUpdate(CFDictionaryRef q, CFDictionaryRef a) {
    _logKC("UPDATE", q); _logKC("  new", a);
    OSStatus s = SecItemUpdate(q, a);
    ALOG(@"   → SecItemUpdate: %d", (int)s);
    ALOG_CALLER();
    return s;
}
static OSStatus al_SecItemDelete(CFDictionaryRef q) {
    _logKC("DELETE", q);
    OSStatus s = SecItemDelete(q);
    ALOG(@"   → SecItemDelete: %d", (int)s);
    ALOG_CALLER();
    return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSJSONSerialization (kèm caller)
// ─────────────────────────────────────────────────────────────────────────────

@interface NSJSONSerialization (AL) @end
@implementation NSJSONSerialization (AL)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void (^sw)(SEL,SEL) = ^(SEL o, SEL h) {
            Method a = class_getClassMethod([NSJSONSerialization class], o);
            Method b = class_getClassMethod([NSJSONSerialization class], h);
            if (a && b) { method_exchangeImplementations(a, b); ALOG(@"✅ Hooked NSJSONSerialization %@", NSStringFromSelector(o)); }
        };
        sw(@selector(JSONObjectWithData:options:error:),
           @selector(al_JSONObjectWithData:options:error:));
        sw(@selector(dataWithJSONObject:options:error:),
           @selector(al_dataWithJSONObject:options:error:));
    });
}

+ (id)al_JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)err {
    id result = [self al_JSONObjectWithData:data options:opt error:err];
    if (_inHook == 0) {
        _inHook++;
        NSString *preview = dataPreview(data, 400);
        NSLog(@"[AppLogger] 📄 JSON Parse [%lu B] → %@", (unsigned long)data.length, preview);
        // ← THÊM: hàm đang nhận/parse JSON
        NSString *caller = callerInfo(AL_CALLER_FILTER, AL_CALLER_DEPTH);
        NSLog(@"[AppLogger] │  ↑ Receiver: %@", caller);
        _inHook--;
    }
    return result;
}

+ (NSData *)al_dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)err {
    NSData *result = [self al_dataWithJSONObject:obj options:opt error:err];
    if (_inHook == 0) {
        _inHook++;
        NSString *preview = dataPreview(result, 400);
        NSLog(@"[AppLogger] 📄 JSON Serialize [%lu B] → %@", (unsigned long)result.length, preview);
        // ← THÊM: hàm đang gửi/serialize JSON
        NSString *caller = callerInfo(AL_CALLER_FILTER, AL_CALLER_DEPTH);
        NSLog(@"[AppLogger] │  ↑ Sender: %@", caller);
        _inHook--;
    }
    return result;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSData Base64 (kèm caller)
// ─────────────────────────────────────────────────────────────────────────────

@interface NSData (ALBase64) @end
@implementation NSData (ALBase64)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class cls = [NSData class];
        Method a = class_getInstanceMethod(cls, @selector(base64EncodedStringWithOptions:));
        Method b = class_getInstanceMethod(cls, @selector(al_base64EncodedStringWithOptions:));
        if (a && b) { method_exchangeImplementations(a, b); ALOG(@"✅ Hooked NSData base64EncodedStringWithOptions:"); }

        Method c = class_getInstanceMethod(cls, @selector(initWithBase64EncodedString:options:));
        Method d2 = class_getInstanceMethod(cls, @selector(al_initWithBase64EncodedString:options:));
        if (c && d2) { method_exchangeImplementations(c, d2); ALOG(@"✅ Hooked NSData initWithBase64EncodedString:"); }
    });
}

- (NSString *)al_base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)opts {
    NSString *result = [self al_base64EncodedStringWithOptions:opts];
    ALOG(@"🔡 B64 Encode [%lu B] → %@", (unsigned long)self.length,
         result.length > 120 ? [result substringToIndex:120] : result);
    ALOG_CALLER();   // ← hàm đang encode
    return result;
}

- (instancetype)al_initWithBase64EncodedString:(NSString *)str options:(NSDataBase64DecodingOptions)opts {
    NSData *result = [self al_initWithBase64EncodedString:str options:opts];
    NSString *decoded = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    ALOG(@"🔡 B64 Decode [%lu B] → %@", (unsigned long)result.length,
         decoded ? (decoded.length > 120 ? [decoded substringToIndex:120] : decoded)
                 : hexBytes(result.bytes, result.length));
    ALOG_CALLER();   // ← hàm đang decode
    return result;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSUserDefaults (kèm caller)
// ─────────────────────────────────────────────────────────────────────────────

static BOOL udAllow(NSString *key) {
    if (!key) return NO;
    static const char * const skip[] = {
        "NS", "UI", "_UI", "_NS", "Apple", "com.apple",
        "Log", "AK", "AG", "AB", "AC", "PKP", "WebKit",
        "Bar", "Force", "RB", "Disable", NULL
    };
    const char *k = key.UTF8String;
    for (int i = 0; skip[i]; i++) {
        if (strncmp(k, skip[i], strlen(skip[i])) == 0) return NO;
    }
    return YES;
}

@interface NSUserDefaults (AL) @end
@implementation NSUserDefaults (AL)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class cls = [NSUserDefaults class];
        void (^sw)(SEL,SEL) = ^(SEL a, SEL b) {
            method_exchangeImplementations(class_getInstanceMethod(cls,a),
                                           class_getInstanceMethod(cls,b));
        };
        sw(@selector(setObject:forKey:),  @selector(al_setObject:forKey:));
        sw(@selector(objectForKey:),      @selector(al_objectForKey:));
        sw(@selector(setInteger:forKey:), @selector(al_setInteger:forKey:));
        sw(@selector(setBool:forKey:),    @selector(al_setBool:forKey:));
    });
}

- (void)al_setObject:(id)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD SET  %-45@ = %@", key, val);
        ALOG_CALLER();
    }
    [self al_setObject:val forKey:key];
}
- (id)al_objectForKey:(NSString *)key {
    id val = [self al_objectForKey:key];
    if (udAllow(key)) {
        ALOG(@"📖 UD GET  %-45@ = %@", key, val);
        ALOG_CALLER();
    }
    return val;
}
- (void)al_setInteger:(NSInteger)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD INT  %-45@ = %ld", key, (long)val);
        ALOG_CALLER();
    }
    [self al_setInteger:val forKey:key];
}
- (void)al_setBool:(BOOL)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD BOOL %-45@ = %@", key, val ? @"YES" : @"NO");
        ALOG_CALLER();
    }
    [self al_setBool:val forKey:key];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSObject trace (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

#define APP_BUNDLE_PREFIX "vn.vng"   // ← đổi thành prefix phù hợp

@interface NSObject (ALTrace) @end
@implementation NSObject (ALTrace)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Method a = class_getClassMethod([NSObject class], @selector(initialize));
        Method b = class_getClassMethod([NSObject class], @selector(al_initialize));
        if (a && b) method_exchangeImplementations(a, b);
    });
}

+ (void)al_initialize {
    [self al_initialize];
    const char *n = class_getName(self);
    if (n && strstr(n, APP_BUNDLE_PREFIX)) {
        ALOG(@"🏗️  +[%s initialize]", n);
    }
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIApplication sendAction (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

@interface UIApplication (AL) @end
@implementation UIApplication (AL)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class cls = [UIApplication class];
        Method a = class_getInstanceMethod(cls, @selector(sendAction:to:from:forEvent:));
        Method b = class_getInstanceMethod(cls, @selector(al_sendAction:to:from:forEvent:));
        if (a && b) method_exchangeImplementations(a, b);
    });
}

- (BOOL)al_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
    if (event && event.type == UIEventTypeTouches) {
        ALOG(@"🎯 ACTION [%@  %@]  sender=%@",
             NSStringFromClass([target class]),
             NSStringFromSelector(action),
             NSStringFromClass([sender class]));
    }
    return [self al_sendAction:action to:target from:sender forEvent:event];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DYLD Interpose table
// ─────────────────────────────────────────────────────────────────────────────

typedef struct { const void *replacement; const void *replacee; } interpose_t;

__attribute__((used))
static const interpose_t _interposes[]
    __attribute__((section("__DATA,__interpose"))) = {
    { (void *)al_CCCrypt,             (void *)CCCrypt             },
    { (void *)al_CCHmac,              (void *)CCHmac              },
    { (void *)al_SecItemAdd,          (void *)SecItemAdd          },
    { (void *)al_SecItemCopyMatching, (void *)SecItemCopyMatching },
    { (void *)al_SecItemUpdate,       (void *)SecItemUpdate       },
    { (void *)al_SecItemDelete,       (void *)SecItemDelete       },
};

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Constructor
// ─────────────────────────────────────────────────────────────────────────────

__attribute__((constructor))
static void AppLoggerInit(void) {
    NSLog(@"[AppLogger] ╔══════════════════════════════════════╗");
    NSLog(@"[AppLogger] ║    🚀  AppLogger Enhanced  v2.2      ║");
    NSLog(@"[AppLogger] ╠══════════════════════════════════════╣");
    NSLog(@"[AppLogger] ║ Bundle  : %@", [[NSBundle mainBundle] bundleIdentifier]);
    NSLog(@"[AppLogger] ║ Version : %@ (%@)",
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
    NSLog(@"[AppLogger] ║ Device  : %@ iOS %@",
          [UIDevice currentDevice].model, [UIDevice currentDevice].systemVersion);
    NSLog(@"[AppLogger] ╠══════════════════════════════════════╣");
    NSLog(@"[AppLogger] ║ Hooks: NSURLSession · CCCrypt · CCHmac");
    NSLog(@"[AppLogger] ║        Keychain · JSON · Base64");
    NSLog(@"[AppLogger] ║        UserDefaults · UIAction · ObjC init");
    NSLog(@"[AppLogger] ║ + Caller tracking: %s (depth=%d)",
          [AL_CALLER_FILTER UTF8String], AL_CALLER_DEPTH);
    NSLog(@"[AppLogger] ╚══════════════════════════════════════╝");

    NSMutableArray *tp = [NSMutableArray array];
    for (NSBundle *fw in [NSBundle allFrameworks]) {
        NSString *bid = fw.bundleIdentifier ?: fw.bundlePath.lastPathComponent;
        if (![bid hasPrefix:@"com.apple"] && ![bid hasPrefix:@"Apple"]
            && ![bid hasSuffix:@".framework"])
            [tp addObject:bid];
    }
    NSLog(@"[AppLogger] 📦 Third-party frameworks (%lu): %@",
          (unsigned long)tp.count, [tp componentsJoinedByString:@", "]);

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] 📲 DidFinishLaunching"); }];
    [nc addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] ▶️  DidBecomeActive"); }];
    [nc addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] ⏸️  DidEnterBackground"); }];
    [nc addObserverForName:UIApplicationWillTerminateNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] 🛑 WillTerminate"); }];
}