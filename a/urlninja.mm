// ============================================================
// CallerLogger.xm - SỬA LỖI BUILD
// ============================================================
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <execinfo.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CFNetwork/CFNetwork.h>

#define LOG(fmt, ...) NSLog(@"[CallerLog] " fmt, ##__VA_ARGS__)

#include "fishhook.h"

// Force load symbols
__attribute__((used)) static CFURLRef (*__cfurlcreatewithstring_ref)(CFAllocatorRef, CFStringRef, CFURLRef) = CFURLCreateWithString;
__attribute__((used)) static CFHTTPMessageRef (*__cfhttpmessagecreaterequest_ref)(CFAllocatorRef, CFStringRef, CFURLRef, CFStringRef) = CFHTTPMessageCreateRequest;

static NSString* getSymbolName(void *addr) {
    Dl_info info;
    if (dladdr(addr, &info)) {
        const char *fname = info.dli_fname ? strrchr(info.dli_fname, '/') : NULL;
        fname = fname ? fname + 1 : (info.dli_fname ? info.dli_fname : "???");
        if (info.dli_sname) {
            return [NSString stringWithFormat:@"%s!%s+%llu", fname, info.dli_sname,
                    (unsigned long long)((uintptr_t)addr - (uintptr_t)info.dli_saddr)];
        }
    }
    return @"???";
}

static void logCaller(const char *funcName, NSString *detail) {
    void *frames[15];
    int count = backtrace(frames, 15);
    LOG(@"========================================");
    LOG(@"%s | %@", funcName, detail);
    LOG(@"Stack:");
    for (int i = 0; i < count; i++) LOG(@"  [%d] %@", i, getSymbolName(frames[i]));
    LOG(@"========================================");
}

// Hook CFHTTPMessageCreateRequest
static CFHTTPMessageRef (*orig_CFHTTPMessageCreateRequest)(CFAllocatorRef, CFStringRef, CFURLRef, CFStringRef);
static CFHTTPMessageRef hook_CFHTTPMessageCreateRequest(CFAllocatorRef a, CFStringRef m, CFURLRef u, CFStringRef v) {
    logCaller("CFHTTPMessageCreateRequest", (__bridge NSString*)CFURLGetString(u));
    return orig_CFHTTPMessageCreateRequest(a, m, u, v);
}

// Hook CFURLCreateWithString
static CFURLRef (*orig_CFURLCreateWithString)(CFAllocatorRef, CFStringRef, CFURLRef);
static CFURLRef hook_CFURLCreateWithString(CFAllocatorRef a, CFStringRef s, CFURLRef b) {
    logCaller("CFURLCreateWithString", (__bridge NSString*)s);
    return orig_CFURLCreateWithString(a, s, b);
}

// Hook NSURL URLWithString:
static NSURL* (*orig_URLWithString)(id, SEL, NSString*);
static NSURL* hook_URLWithString(id self, SEL _cmd, NSString *s) {
    NSURL *url = orig_URLWithString(self, _cmd, s);
    if (s && [s rangeOfString:@"anubisw"].location != NSNotFound) {
        logCaller("NSURL URLWithString:", s);
    }
    return url;
}

// Hook NSURLSession dataTaskWithRequest:completionHandler:
static id (*orig_dataTask)(id, SEL, id, id);
static id hook_dataTask(id self, SEL _cmd, id req, id handler) {
    NSURL *url = [req URL];
    if (url) logCaller("NSURLSession dataTaskWithRequest:", [url absoluteString]);
    return orig_dataTask(self, _cmd, req, handler);
}

__attribute__((constructor)) static void init() {
    @autoreleasepool {
        LOG(@"CallerLogger v2.0 Loaded!");
        
        // Fishhook C functions
        struct rebinding rb[] = {
            {"CFHTTPMessageCreateRequest", (void*)hook_CFHTTPMessageCreateRequest, (void**)&orig_CFHTTPMessageCreateRequest},
            {"CFURLCreateWithString", (void*)hook_CFURLCreateWithString, (void**)&orig_CFURLCreateWithString},
        };
        rebind_symbols(rb, sizeof(rb)/sizeof(rb[0]));
        
        // Swizzle ObjC methods
        Method m;
        m = class_getClassMethod(objc_getClass("NSURL"), @selector(URLWithString:));
        if (m) {
            orig_URLWithString = (NSURL*(*)(id,SEL,NSString*))method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_URLWithString);
        }
        
        m = class_getInstanceMethod(objc_getClass("NSURLSession"), @selector(dataTaskWithRequest:completionHandler:));
        if (m) {
            orig_dataTask = (id(*)(id,SEL,id,id))method_getImplementation(m);
            method_setImplementation(m, (IMP)hook_dataTask);
        }
        
        LOG(@"All hooks installed!");
    }
}
