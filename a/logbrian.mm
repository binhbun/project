#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#include <CommonCrypto/CommonCrypto.h>
#include <dlfcn.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <unistd.h>
#include <execinfo.h>

static _Thread_local int _inHook = 0;

#define ALOG(fmt, ...) do { \
    if (_inHook == 0) { \
        _inHook++; \
        NSLog(@"[AppLogger] " fmt, ##__VA_ARGS__); \
        _inHook--; \
    } \
} while(0)

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

static NSString *hexBytes(const void *bytes, size_t len) {
    if (!bytes || len == 0) return @"<empty>";
    const uint8_t *b = (const uint8_t *)bytes;
    NSMutableString *s = [NSMutableString stringWithCapacity:len * 3];
    for (size_t i = 0; i < len; i++) {
        [s appendFormat:@"%02x ", b[i]];
    }
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

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Caller Tracking (Tối giản)
// ─────────────────────────────────────────────────────────────────────────────

#define AL_CALLER_DEPTH  1
#define AL_CALLER_FILTER @"com.miniclip.8ballpoolmult"

static NSString *callerInfo(NSString * _Nullable filterPrefix, int depth) {
    NSArray<NSString *> *stack = [NSThread callStackSymbols];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    int found = 0;
    
    for (NSUInteger i = 2; i < stack.count && found < depth; i++) {
        NSString *frame = stack[i];
        if ([frame containsString:@"al_"] || [frame containsString:@"AppLogger"]) continue;
        if (filterPrefix && filterPrefix.length > 0) {
            if (![frame containsString:filterPrefix]) continue;
        }
        NSRange r1 = [frame rangeOfString:@"0x"];
        if (r1.location != NSNotFound) {
            NSString *clean = [frame substringFromIndex:r1.location];
            NSRange r2 = [clean rangeOfString:@" " options:NSBackwardsSearch];
            if (r2.location != NSNotFound && r2.location + 1 < clean.length) {
                clean = [clean substringFromIndex:r2.location + 1];
            }
            [result addObject:clean];
            found++;
        }
    }
    
    return result.count > 0 ? result.firstObject : @"<unknown>";
}

#define ALOG_CALLER() do { \
    if (_inHook == 0) { \
        _inHook++; \
        ALOG(@"↳ %@", callerInfo(AL_CALLER_FILTER, AL_CALLER_DEPTH)); \
        _inHook--; \
    } \
} while(0)

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Log Body FULL không giới hạn
// ─────────────────────────────────────────────────────────────────────────────

static void LogFullBody(NSString *prefix, NSData *data) {
    if (!data || data.length == 0) {
        ALOG(@"%@ <empty>", prefix);
        return;
    }
    
    ALOG(@"%@ [%lu bytes]:", prefix, (unsigned long)data.length);
    
    // Log FULL hex từng dòng 32 bytes
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    size_t length = data.length;
    size_t offset = 0;
    
    while (offset < length) {
        size_t remain = length - offset;
        size_t lineLen = remain > 32 ? 32 : remain;
        
        NSMutableString *hexLine = [NSMutableString stringWithCapacity:lineLen * 3];
        NSMutableString *asciiLine = [NSMutableString stringWithCapacity:lineLen];
        
        for (size_t i = 0; i < lineLen; i++) {
            uint8_t byte = bytes[offset + i];
            [hexLine appendFormat:@"%02x ", byte];
            char c = (byte >= 32 && byte < 127) ? byte : '.';
            [asciiLine appendFormat:@"%c", c];
        }
        
        // Thêm padding để align
        while (hexLine.length < 32 * 3) {
            [hexLine appendString:@"   "];
        }
        
        ALOG(@"%@ %04zx: %@ | %@", prefix, offset, hexLine, asciiLine);
        offset += lineLen;
    }
    
    // Thử hiển thị dạng text nếu là UTF-8
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (str && str.length > 0) {
        ALOG(@"%@ TEXT (first 500 chars):", prefix);
        // Log từng dòng text
        NSUInteger textLen = str.length;
        NSUInteger textOffset = 0;
        NSUInteger chunkSize = 200;
        
        while (textOffset < textLen) {
            NSUInteger remain = textLen - textOffset;
            NSUInteger thisChunk = remain > chunkSize ? chunkSize : remain;
            NSString *chunk = [str substringWithRange:NSMakeRange(textOffset, thisChunk)];
            // Escape newlines để log 1 dòng
            chunk = [chunk stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            chunk = [chunk stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
            ALOG(@"%@   %@", prefix, chunk);
            textOffset += thisChunk;
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSURLSession Hook (CHỈ LOG BODY)
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
            if (a && b) { method_exchangeImplementations(a, b); }
        };
        sw(@selector(dataTaskWithRequest:completionHandler:),
           @selector(al_dataTaskWithRequest:completionHandler:));
        sw(@selector(dataTaskWithURL:completionHandler:),
           @selector(al_dataTaskWithURL:completionHandler:));
        sw(@selector(uploadTaskWithRequest:fromData:completionHandler:),
           @selector(al_uploadTaskWithRequest:fromData:completionHandler:));
    });
}

static void _logReq(NSURLRequest *req) {
    ALOG(@"═══════════════════════════════════════════════════════════════");
    ALOG(@"📤 %@ %@", req.HTTPMethod ?: @"GET", req.URL.absoluteString);
    if (req.HTTPBody.length) {
        LogFullBody(@"REQUEST BODY", req.HTTPBody);
    } else {
        ALOG(@"REQUEST BODY: <empty>");
    }
    ALOG_CALLER();
    ALOG(@"═══════════════════════════════════════════════════════════════");
}

static void _logResp(NSURL *url, NSData *data, NSURLResponse *resp, NSError *err) {
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
    ALOG(@"═══════════════════════════════════════════════════════════════");
    
    if (err) {
        ALOG(@"❌ ERROR %@: %@", url.absoluteString, err);
        ALOG(@"═══════════════════════════════════════════════════════════════");
        return;
    }
    
    ALOG(@"📥 %ld %@", (long)http.statusCode, url.absoluteString);
    if (data.length) {
        LogFullBody(@"RESPONSE BODY", data);
    } else {
        ALOG(@"RESPONSE BODY: <empty>");
    }
    ALOG_CALLER();
    ALOG(@"═══════════════════════════════════════════════════════════════");
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
    ALOG(@"═══════════════════════════════════════════════════════════════");
    ALOG(@"📤 GET %@", url.absoluteString);
    ALOG(@"REQUEST BODY: <empty>");
    ALOG_CALLER();
    ALOG(@"═══════════════════════════════════════════════════════════════");
    return [self al_dataTaskWithURL:url completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        _logResp(url, d, r, e);
        if (cb) cb(d, r, e);
    }];
}

- (NSURLSessionUploadTask *)al_uploadTaskWithRequest:(NSURLRequest *)req
                                            fromData:(NSData *)body
                                   completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))cb {
    ALOG(@"═══════════════════════════════════════════════════════════════");
    ALOG(@"📤 UPLOAD %@ %@", req.HTTPMethod, req.URL.absoluteString);
    if (body.length) {
        LogFullBody(@"UPLOAD BODY", body);
    }
    ALOG_CALLER();
    ALOG(@"═══════════════════════════════════════════════════════════════");
    return [self al_uploadTaskWithRequest:req fromData:body completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        _logResp(req.URL, d, r, e);
        if (cb) cb(d, r, e);
    }];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CCCrypt / CCHmac (LOG NGẮN)
// ─────────────────────────────────────────────────────────────────────────────

static CCCryptorStatus al_CCCrypt(
    CCOperation op, CCAlgorithm alg, CCOptions opts,
    const void *key, size_t keyLen,
    const void *iv,
    const void *in, size_t inLen,
    void *out, size_t outAvail, size_t *outMoved)
{
    CCCryptorStatus st = CCCrypt(op, alg, opts, key, keyLen, iv, in, inLen, out, outAvail, outMoved);
    
    if (st == kCCSuccess) {
        ALOG(@"═══════════════════════════════════════════════════════════════");
        ALOG(@"🔐 %@ %@ [in:%zu out:%zu]", 
             (op == kCCEncrypt) ? @"ENC" : @"DEC",
             ccAlgName(alg), inLen, outMoved ? *outMoved : 0);
        if (keyLen) ALOG(@"Key: %@", hexBytes(key, MIN(keyLen, 32)));
        if (inLen) ALOG(@"In:  %@", hexBytes(in, MIN(inLen, 64)));
        if (outMoved && *outMoved) ALOG(@"Out: %@", hexBytes(out, MIN(*outMoved, 64)));
        ALOG_CALLER();
        ALOG(@"═══════════════════════════════════════════════════════════════");
    }
    
    return st;
}

static void al_CCHmac(CCHmacAlgorithm alg,
                      const void *key, size_t keyLen,
                      const void *data, size_t dataLen,
                      void *mac)
{
    CCHmac(alg, key, keyLen, data, dataLen, mac);
    
    size_t macLen = 32;
    switch(alg) {
        case kCCHmacAlgMD5: macLen = 16; break;
        case kCCHmacAlgSHA1: macLen = 20; break;
        case kCCHmacAlgSHA256: macLen = 32; break;
        case kCCHmacAlgSHA384: macLen = 48; break;
        case kCCHmacAlgSHA512: macLen = 64; break;
        default: macLen = 32;
    }
    
    ALOG(@"═══════════════════════════════════════════════════════════════");
    ALOG(@"🔑 HMAC %@ [data:%zu mac:%zu]", hmacAlgName(alg), dataLen, macLen);
    ALOG(@"Key: %@", hexBytes(key, MIN(keyLen, 32)));
    ALOG(@"MAC: %@", hexBytes(mac, macLen));
    ALOG_CALLER();
    ALOG(@"═══════════════════════════════════════════════════════════════");
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSJSONSerialization (CHỈ LOG LỖI)
// ─────────────────────────────────────────────────────────────────────────────

@interface NSJSONSerialization (AL) @end
@implementation NSJSONSerialization (AL)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        void (^sw)(SEL,SEL) = ^(SEL o, SEL h) {
            Method a = class_getClassMethod([NSJSONSerialization class], o);
            Method b = class_getClassMethod([NSJSONSerialization class], h);
            if (a && b) { method_exchangeImplementations(a, b); }
        };
        sw(@selector(JSONObjectWithData:options:error:),
           @selector(al_JSONObjectWithData:options:error:));
    });
}

+ (id)al_JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError **)err {
    id result = [self al_JSONObjectWithData:data options:opt error:err];
    
    if (err && *err) {
        if (_inHook == 0) {
            _inHook++;
            ALOG(@"⚠️ JSON PARSE ERROR: %@", *err);
            ALOG(@"Data: %@", hexBytes(data.bytes, MIN(data.length, 128)));
            _inHook--;
        }
    }
    
    return result;
}

@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSData Base64 (LOG NGẮN)
// ─────────────────────────────────────────────────────────────────────────────

@interface NSData (ALBase64) @end
@implementation NSData (ALBase64)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class cls = [NSData class];
        Method a = class_getInstanceMethod(cls, @selector(base64EncodedStringWithOptions:));
        Method b = class_getInstanceMethod(cls, @selector(al_base64EncodedStringWithOptions:));
        if (a && b) { method_exchangeImplementations(a, b); }
    });
}

- (NSString *)al_base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)opts {
    NSString *result = [self al_base64EncodedStringWithOptions:opts];
    ALOG(@"🔡 B64 [%lu B] -> %@", (unsigned long)self.length, 
         result.length > 100 ? [[result substringToIndex:100] stringByAppendingString:@"…"] : result);
    return result;
}

@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSUserDefaults (CHỈ LOG SET)
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
        sw(@selector(setInteger:forKey:), @selector(al_setInteger:forKey:));
        sw(@selector(setBool:forKey:),    @selector(al_setBool:forKey:));
        sw(@selector(setFloat:forKey:),   @selector(al_setFloat:forKey:));
        sw(@selector(setDouble:forKey:),  @selector(al_setDouble:forKey:));
    });
}

- (void)al_setObject:(id)val forKey:(NSString *)key {
    if (udAllow(key)) ALOG(@"💾 UD SET %@ = %@", key, val);
    [self al_setObject:val forKey:key];
}

- (void)al_setInteger:(NSInteger)val forKey:(NSString *)key {
    if (udAllow(key)) ALOG(@"💾 UD SET %@ = %ld", key, (long)val);
    [self al_setInteger:val forKey:key];
}

- (void)al_setBool:(BOOL)val forKey:(NSString *)key {
    if (udAllow(key)) ALOG(@"💾 UD SET %@ = %@", key, val ? @"YES" : @"NO");
    [self al_setBool:val forKey:key];
}

- (void)al_setFloat:(float)val forKey:(NSString *)key {
    if (udAllow(key)) ALOG(@"💾 UD SET %@ = %f", key, val);
    [self al_setFloat:val forKey:key];
}

- (void)al_setDouble:(double)val forKey:(NSString *)key {
    if (udAllow(key)) ALOG(@"💾 UD SET %@ = %f", key, val);
    [self al_setDouble:val forKey:key];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DYLD Interpose
// ─────────────────────────────────────────────────────────────────────────────

typedef struct { const void *replacement; const void *replacee; } interpose_t;

__attribute__((used))
static const interpose_t _interposes[]
    __attribute__((section("__DATA,__interpose"))) = {
    { (void *)al_CCCrypt,             (void *)CCCrypt             },
    { (void *)al_CCHmac,              (void *)CCHmac              },
};

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Constructor
// ─────────────────────────────────────────────────────────────────────────────

__attribute__((constructor))
static void AppLoggerInit(void) {
    NSLog(@"[AppLogger] 🚀 Logger v5.0 - FULL BODY LOG");
    NSLog(@"[AppLogger] ═══════════════════════════════════════════════════════════════");
}






////////////////////////////////////////





#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#include <CommonCrypto/CommonCrypto.h>
#include <dlfcn.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <unistd.h>
#include <execinfo.h>

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

#define AL_CALLER_DEPTH  10
#define AL_CALLER_FILTER @"com.miniclip.8ballpoolmult"

static NSString *callerInfo(NSString * _Nullable filterPrefix, int depth) {
    NSArray<NSString *> *stack = [NSThread callStackSymbols];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    int found = 0;
    
    for (NSUInteger i = 2; i < stack.count && found < depth; i++) {
        NSString *frame = stack[i];
        if ([frame containsString:@"al_"] || [frame containsString:@"AppLogger"]) continue;
        if (filterPrefix && filterPrefix.length > 0) {
            if (![frame containsString:filterPrefix]) continue;
        }
        NSRange r = [frame rangeOfString:@"0x" options:NSCaseInsensitiveSearch];
        NSString *clean = (r.location != NSNotFound && r.location + 12 < frame.length)
            ? [frame substringFromIndex:r.location + 11]
            : frame;
        [result addObject:[clean stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        found++;
    }
    
    if (result.count == 0) {
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

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────────────────────────────────────

static void logHexInChunks(NSString *prefix, const void *bytes, size_t length) {
    if (!bytes || length == 0) {
        ALOG(@"%@ <empty>", prefix);
        return;
    }
    
    const uint8_t *b = (const uint8_t *)bytes;
    size_t chunkSize = 32; // 32 bytes mỗi dòng để an toàn với syslog
    size_t offset = 0;
    
    while (offset < length) {
        size_t remain = length - offset;
        size_t thisChunk = remain > chunkSize ? chunkSize : remain;
        NSMutableString *hexStr = [NSMutableString stringWithCapacity:thisChunk * 3];
        NSMutableString *asciiStr = [NSMutableString stringWithCapacity:thisChunk];
        
        for (size_t i = 0; i < thisChunk; i++) {
            uint8_t byte = b[offset + i];
            [hexStr appendFormat:@"%02x ", byte];
            char c = (byte >= 32 && byte < 127) ? byte : '.';
            [asciiStr appendFormat:@"%c", c];
        }
        
        NSString *hex = [hexStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (offset == 0) {
            ALOG(@"%@[%zu] %@ | %@", prefix, length, hex, asciiStr);
        } else {
            ALOG(@"%@(cont) %@ | %@", prefix, hex, asciiStr);
        }
        offset += thisChunk;
    }
}

static NSString * __attribute__((unused)) hexBytes(const void *bytes, size_t len) {
    if (!bytes || len == 0) return @"<empty>";
    const uint8_t *b = (const uint8_t *)bytes;
    NSMutableString *s = [NSMutableString stringWithCapacity:MIN(len, 64) * 3];
    size_t cap = MIN(len, 64);
    for (size_t i = 0; i < cap; i++) [s appendFormat:@"%02x ", b[i]];
    if (len > 64) [s appendFormat:@"… (%zu more)", len - 64];
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

static void __attribute__((unused)) LogFullJSON(NSString *jsonString) {
    if (!jsonString) return;
    
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 📄 JSON DATA [%lu chars]", (unsigned long)jsonString.length);
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    
    // Chia nhỏ mỗi đoạn 500 ký tự
    int chunkSize = 500;
    int length = (int)jsonString.length;
    
    for (int i = 0; i < length; i += chunkSize) {
        int range = MIN(chunkSize, length - i);
        NSString *chunk = [jsonString substringWithRange:NSMakeRange(i, range)];
        ALOG(@"║ %@", chunk);
    }
    
    ALOG(@"╚═══════════════════════════════════════════════════════════");
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

static void _logReq(NSURLRequest *req) {
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 📤 REQUEST %@ %@", req.HTTPMethod ?: @"GET", req.URL.absoluteString);
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    
    [req.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *_) {
        ALOG(@"║ HEADER: %@ = %@", k, v);
    }];
    
    if (req.HTTPBody.length) {
        ALOG(@"║ BODY [%lu bytes]:", (unsigned long)req.HTTPBody.length);
        logHexInChunks(@"║", req.HTTPBody.bytes, req.HTTPBody.length);
    }
    
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
}

static void _logResp(NSURL *url, NSData *data, NSURLResponse *resp, NSError *err) {
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    
    if (err) {
        ALOG(@"║ ❌ RESPONSE ERROR %@", url.absoluteString);
        ALOG(@"║ Error: %@", err);
        ALOG_CALLER();
        ALOG(@"╚═══════════════════════════════════════════════════════════");
        return;
    }
    
    ALOG(@"║ 📥 RESPONSE %ld %@", (long)http.statusCode, url.absoluteString);
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    
    [http.allHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *_) {
        ALOG(@"║ HEADER: %@ = %@", k, v);
    }];
    
    if (data.length) {
        ALOG(@"║ BODY [%lu bytes]:", (unsigned long)data.length);
        logHexInChunks(@"║", data.bytes, data.length);
    }
    
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
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
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 📤 REQUEST GET %@", url.absoluteString);
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return [self al_dataTaskWithURL:url completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        _logResp(url, d, r, e);
        if (cb) cb(d, r, e);
    }];
}

- (NSURLSessionUploadTask *)al_uploadTaskWithRequest:(NSURLRequest *)req
                                            fromData:(NSData *)body
                                   completionHandler:(void(^)(NSData*,NSURLResponse*,NSError*))cb {
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 📤 UPLOAD %@ %@ [%lu bytes]", req.HTTPMethod, req.URL.absoluteString, (unsigned long)body.length);
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    ALOG(@"║ BODY:");
    logHexInChunks(@"║", body.bytes, body.length);
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return [self al_uploadTaskWithRequest:req fromData:body completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        _logResp(req.URL, d, r, e);
        if (cb) cb(d, r, e);
    }];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CCCrypt / CCHmac Interpose
// ─────────────────────────────────────────────────────────────────────────────

static CCCryptorStatus al_CCCrypt(
    CCOperation op, CCAlgorithm alg, CCOptions opts,
    const void *key, size_t keyLen,
    const void *iv,
    const void *in, size_t inLen,
    void *out, size_t outAvail, size_t *outMoved)
{
    CCCryptorStatus st = CCCrypt(op, alg, opts, key, keyLen, iv, in, inLen, out, outAvail, outMoved);
    
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 🔐 CCCrypt: %@ | %@", 
         (op == kCCEncrypt) ? @"ENCRYPT" : @"DECRYPT",
         ccAlgName(alg));
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    ALOG(@"║ Algorithm: %@", ccAlgName(alg));
    ALOG(@"║ Options: PKCS7=%@, ECB=%@",
         (opts & kCCOptionPKCS7Padding) ? @"YES" : @"NO",
         (opts & kCCOptionECBMode) ? @"YES" : @"NO");
    ALOG(@"║ Key [%zu]:", keyLen);
    logHexInChunks(@"║", key, keyLen);
    if (iv) {
        ALOG(@"║ IV:");
        logHexInChunks(@"║", iv, 16);
    }
    ALOG(@"║ Input [%zu]:", inLen);
    logHexInChunks(@"║", in, inLen);
    if (outMoved && st == kCCSuccess) {
        ALOG(@"║ Output [%zu]:", *outMoved);
        logHexInChunks(@"║", out, *outMoved);
    }
    ALOG(@"║ Status: %d %@", st, st == 0 ? @"✅ SUCCESS" : @"❌ ERROR");
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    
    return st;
}

static void al_CCHmac(CCHmacAlgorithm alg,
                      const void *key, size_t keyLen,
                      const void *data, size_t dataLen,
                      void *mac)
{
    CCHmac(alg, key, keyLen, data, dataLen, mac);
    
    size_t macLen = 0;
    switch(alg) {
        case kCCHmacAlgMD5: macLen = 16; break;
        case kCCHmacAlgSHA1: macLen = 20; break;
        case kCCHmacAlgSHA256: macLen = 32; break;
        case kCCHmacAlgSHA384: macLen = 48; break;
        case kCCHmacAlgSHA512: macLen = 64; break;
        default: macLen = 32;
    }
    
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 🔑 CCHmac: %@", hmacAlgName(alg));
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    ALOG(@"║ Key [%zu]:", keyLen);
    logHexInChunks(@"║", key, keyLen);
    ALOG(@"║ Data [%zu]:", dataLen);
    logHexInChunks(@"║", data, dataLen);
    ALOG(@"║ MAC [%zu]:", macLen);
    logHexInChunks(@"║", mac, macLen);
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Keychain Interpose
// ─────────────────────────────────────────────────────────────────────────────

static void _logKC(const char *op, CFDictionaryRef q) {
    NSDictionary *d = (__bridge NSDictionary *)q;
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 🔐 KEYCHAIN %s", op);
    
    for (id key in d) {
        id value = d[key];
        if ([value isKindOfClass:[NSData class]]) {
            NSData *data = value;
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (str) {
                ALOG(@"║ %@ = %@", key, str);
            } else {
                ALOG(@"║ %@ [%lu bytes]:", key, (unsigned long)data.length);
                logHexInChunks(@"║", data.bytes, data.length);
            }
        } else {
            ALOG(@"║ %@ = %@", key, value);
        }
    }
}

static OSStatus al_SecItemAdd(CFDictionaryRef attrs, CFTypeRef *res) {
    _logKC("ADD", attrs);
    OSStatus s = SecItemAdd(attrs, res);
    ALOG(@"║ Result: %d %@", (int)s, s == errSecSuccess ? @"✅" : @"❌");
    if (res && *res) {
        if (CFGetTypeID(*res) == CFDataGetTypeID()) {
            NSData *d = (__bridge NSData *)*res;
            ALOG(@"║ Returned:");
            logHexInChunks(@"║", d.bytes, d.length);
        }
    }
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return s;
}

static OSStatus al_SecItemCopyMatching(CFDictionaryRef q, CFTypeRef *res) {
    _logKC("QUERY", q);
    OSStatus s = SecItemCopyMatching(q, res);
    ALOG(@"║ Result: %d %@", (int)s, s == errSecSuccess ? @"✅" : @"❌");
    if (s == errSecSuccess && res && *res) {
        if (CFGetTypeID(*res) == CFDataGetTypeID()) {
            NSData *d = (__bridge NSData *)*res;
            NSString *str = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
            if (str) {
                ALOG(@"║ Returned String: %@", str);
            } else {
                ALOG(@"║ Returned Data:");
                logHexInChunks(@"║", d.bytes, d.length);
            }
        }
    }
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return s;
}

static OSStatus al_SecItemUpdate(CFDictionaryRef q, CFDictionaryRef a) {
    _logKC("UPDATE QUERY", q);
    _logKC("UPDATE NEW", a);
    OSStatus s = SecItemUpdate(q, a);
    ALOG(@"║ Result: %d %@", (int)s, s == errSecSuccess ? @"✅" : @"❌");
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return s;
}

static OSStatus al_SecItemDelete(CFDictionaryRef q) {
    _logKC("DELETE", q);
    OSStatus s = SecItemDelete(q);
    ALOG(@"║ Result: %d %@", (int)s, s == errSecSuccess ? @"✅" : @"❌");
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSJSONSerialization
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
        ALOG(@"╔═══════════════════════════════════════════════════════════");
        ALOG(@"║ 📄 JSON PARSE [%lu B]", (unsigned long)data.length);
        ALOG(@"╠═══════════════════════════════════════════════════════════");
        ALOG(@"║ Input Data:");
        logHexInChunks(@"║", data.bytes, data.length);
        
        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (jsonStr) {
            LogFullJSON(jsonStr);
        }
        if (result) {
            ALOG(@"║ Parsed Result: %@", result);
        }
        ALOG_CALLER();
        ALOG(@"╚═══════════════════════════════════════════════════════════");
        _inHook--;
    }
    
    return result;
}

+ (NSData *)al_dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)err {
    NSData *result = [self al_dataWithJSONObject:obj options:opt error:err];
    
    if (_inHook == 0) {
        _inHook++;
        ALOG(@"╔═══════════════════════════════════════════════════════════");
        ALOG(@"║ 📄 JSON SERIALIZE [%lu B]", (unsigned long)result.length);
        ALOG(@"╠═══════════════════════════════════════════════════════════");
        ALOG(@"║ Input Object: %@", obj);
        ALOG(@"║ Output Data:");
        logHexInChunks(@"║", result.bytes, result.length);
        
        NSString *jsonStr = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        if (jsonStr) {
            LogFullJSON(jsonStr);
        }
        ALOG_CALLER();
        ALOG(@"╚═══════════════════════════════════════════════════════════");
        _inHook--;
    }
    
    return result;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSData Base64
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
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 🔡 B64 ENCODE [%lu B]", (unsigned long)self.length);
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    ALOG(@"║ Input:");
    logHexInChunks(@"║", self.bytes, self.length);
    ALOG(@"║ Output: %@", result);
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return result;
}

- (instancetype)al_initWithBase64EncodedString:(NSString *)str options:(NSDataBase64DecodingOptions)opts {
    NSData *result = [self al_initWithBase64EncodedString:str options:opts];
    ALOG(@"╔═══════════════════════════════════════════════════════════");
    ALOG(@"║ 🔡 B64 DECODE [%lu B]", (unsigned long)str.length);
    ALOG(@"╠═══════════════════════════════════════════════════════════");
    ALOG(@"║ Input: %@", str);
    ALOG(@"║ Output:");
    logHexInChunks(@"║", result.bytes, result.length);
    ALOG_CALLER();
    ALOG(@"╚═══════════════════════════════════════════════════════════");
    return result;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSUserDefaults
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
        sw(@selector(setFloat:forKey:),   @selector(al_setFloat:forKey:));
        sw(@selector(setDouble:forKey:),  @selector(al_setDouble:forKey:));
    });
}

- (void)al_setObject:(id)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD SET %@ = %@", key, val);
        ALOG_CALLER();
    }
    [self al_setObject:val forKey:key];
}

- (id)al_objectForKey:(NSString *)key {
    id val = [self al_objectForKey:key];
    if (udAllow(key)) {
        ALOG(@"📖 UD GET %@ = %@", key, val);
        ALOG_CALLER();
    }
    return val;
}

- (void)al_setInteger:(NSInteger)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD SET %@ = %ld", key, (long)val);
        ALOG_CALLER();
    }
    [self al_setInteger:val forKey:key];
}

- (void)al_setBool:(BOOL)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD SET %@ = %@", key, val ? @"YES" : @"NO");
        ALOG_CALLER();
    }
    [self al_setBool:val forKey:key];
}

- (void)al_setFloat:(float)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD SET %@ = %f", key, val);
        ALOG_CALLER();
    }
    [self al_setFloat:val forKey:key];
}

- (void)al_setDouble:(double)val forKey:(NSString *)key {
    if (udAllow(key)) {
        ALOG(@"💾 UD SET %@ = %f", key, val);
        ALOG_CALLER();
    }
    [self al_setDouble:val forKey:key];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NSObject trace
// ─────────────────────────────────────────────────────────────────────────────

#define APP_BUNDLE_PREFIX "com.miniclip.8ballpoolmult"

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
        ALOG(@"🏗️ +[%s initialize]", n);
    }
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - UIApplication sendAction
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
        ALOG(@"🎯 ACTION: %@ %@ (sender: %@, target: %@)",
             NSStringFromClass([sender class]),
             NSStringFromSelector(action),
             sender, target);
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
    NSLog(@"[AppLogger] ╔═══════════════════════════════════════════════════════════");
    NSLog(@"[AppLogger] ║ 🚀 AppLogger Enhanced v3.0 - FULL DATA LOG");
    NSLog(@"[AppLogger] ╠═══════════════════════════════════════════════════════════");
    NSLog(@"[AppLogger] ║ Bundle  : %@", [[NSBundle mainBundle] bundleIdentifier]);
    NSLog(@"[AppLogger] ║ Version : %@ (%@)",
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
    NSLog(@"[AppLogger] ║ Device  : %@ iOS %@",
          [UIDevice currentDevice].model, [UIDevice currentDevice].systemVersion);
    NSLog(@"[AppLogger] ╠═══════════════════════════════════════════════════════════");
    NSLog(@"[AppLogger] ║ HOOKS: NSURLSession · CCCrypt · CCHmac");
    NSLog(@"[AppLogger] ║        Keychain · JSON · Base64");
    NSLog(@"[AppLogger] ║        UserDefaults · UIAction · ObjC init");
    NSLog(@"[AppLogger] ║ CALLER TRACKING: %s (depth=%d)",
          [AL_CALLER_FILTER UTF8String], AL_CALLER_DEPTH);
    NSLog(@"[AppLogger] ║ FULL HEX DUMP: ENABLED (32 bytes/line)");
    NSLog(@"[AppLogger] ║ FULL JSON LOG: ENABLED");
    NSLog(@"[AppLogger] ╚═══════════════════════════════════════════════════════════");

    NSMutableArray *tp = [NSMutableArray array];
    for (NSBundle *fw in [NSBundle allFrameworks]) {
        NSString *bid = fw.bundleIdentifier ?: fw.bundlePath.lastPathComponent;
        if (![bid hasPrefix:@"com.apple"] && ![bid hasPrefix:@"Apple"]
            && ![bid hasSuffix:@".framework"])
            [tp addObject:bid];
    }
    if (tp.count) {
        NSLog(@"[AppLogger] 📦 Third-party frameworks (%lu): %@",
              (unsigned long)tp.count, [tp componentsJoinedByString:@", "]);
    }

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] 📲 DidFinishLaunching"); }];
    [nc addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] ▶️ DidBecomeActive"); }];
    [nc addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] ⏸️ DidEnterBackground"); }];
    [nc addObserverForName:UIApplicationWillTerminateNotification object:nil queue:nil
                usingBlock:^(NSNotification *_){ NSLog(@"[AppLogger] 🛑 WillTerminate"); }];
}
