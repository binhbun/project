#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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
// MARK: - Caller Tracking
// ─────────────────────────────────────────────────────────────────────────────

#define AL_CALLER_DEPTH  5
#define AL_CALLER_FILTER @"vn.vng"     // ← đổi thành bundle prefix của app

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
    ALOG(@"🔐 CCCrypt | %@ | %@ | PKCS7=%@ ECB=%@ | key[%zu]=%@ | in[%zu]=%@ | out[%zu]=%@ | status=%d",
         (op == kCCEncrypt) ? @"ENC" : @"DEC",
         ccAlgName(alg),
         (opts & kCCOptionPKCS7Padding) ? @"Y" : @"N",
         (opts & kCCOptionECBMode)      ? @"Y" : @"N",
         keyLen, hexBytes(key, keyLen),
         inLen,  hexBytes(in, inLen),
         outMoved ? *outMoved : 0, hexBytes(out, outMoved ? *outMoved : 0),
         (int)st);
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
    ALOG_CALLER();
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DYLD Interpose table
// ─────────────────────────────────────────────────────────────────────────────

typedef struct { const void *replacement; const void *replacee; } interpose_t;

__attribute__((used))
static const interpose_t _interposes[]
    __attribute__((section("__DATA,__interpose"))) = {
    { (void *)al_CCCrypt, (void *)CCCrypt },
    { (void *)al_CCHmac,  (void *)CCHmac  },
};

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Constructor
// ─────────────────────────────────────────────────────────────────────────────

__attribute__((constructor))
static void AppLoggerInit(void) {
    NSLog(@"[AppLogger] ╔══════════════════════════════════════╗");
    NSLog(@"[AppLogger] ║    🚀  AppLogger (CCCrypt/CCHmac)    ║");
    NSLog(@"[AppLogger] ╠══════════════════════════════════════╣");
    NSLog(@"[AppLogger] ║ Bundle  : %@", [[NSBundle mainBundle] bundleIdentifier]);
    NSLog(@"[AppLogger] ║ Version : %@ (%@)",
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
    NSLog(@"[AppLogger] ║ Device  : %@ iOS %@",
          [UIDevice currentDevice].model, [UIDevice currentDevice].systemVersion);
    NSLog(@"[AppLogger] ╠══════════════════════════════════════╣");
    NSLog(@"[AppLogger] ║ Hooks: CCCrypt · CCHmac");
    NSLog(@"[AppLogger] ║ + Caller tracking: %s (depth=%d)",
          [AL_CALLER_FILTER UTF8String], AL_CALLER_DEPTH);
    NSLog(@"[AppLogger] ╚══════════════════════════════════════╝");
}v
