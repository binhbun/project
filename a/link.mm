#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString * const kTargetURL = @"https://gmvmoba.com/dd/";

static BOOL shouldRedirectURL(NSURL *url) {
    if (!url || !url.host) return NO;

    NSString *host = url.host.lowercaseString;

    NSArray<NSString *> *blockedHosts = @[
        @"t.me",
        @"telegram.me",
        @"telegram.org",
        @"telegram.dog",
        @"zalo.me",
        @"zalo.com",
        @"zalo.vn"
    ];

    for (NSString *blocked in blockedHosts) {
        if ([host isEqualToString:blocked] || [host hasSuffix:[@"." stringByAppendingString:blocked]]) {
            return YES;
        }
    }
    return NO;
}

static BOOL (*orig_openURL_options_completion)(id, SEL, NSURL *, NSDictionary *, void (^)(BOOL));

static BOOL my_openURL_options_completion(id self, SEL _cmd,
                                          NSURL *url,
                                          NSDictionary *options,
                                          void (^completion)(BOOL)) {
    NSLog(@"[Hook] URL gốc: %@", url.absoluteString);

    if (shouldRedirectURL(url)) {
        NSURL *newURL = [NSURL URLWithString:kTargetURL];
        NSLog(@"[Hook] URL thuộc nhóm t.me/zalo.me → thay bằng: %@", newURL.absoluteString);
        return orig_openURL_options_completion(self, _cmd, newURL, options, completion);
    }

    NSLog(@"[Hook] URL không khớp điều kiện → giữ nguyên");
    return orig_openURL_options_completion(self, _cmd, url, options, completion);
}

static BOOL (*orig_openURL_legacy)(id, SEL, NSURL *);

static BOOL my_openURL_legacy(id self, SEL _cmd, NSURL *url) {
    NSLog(@"[Hook] URL gốc (legacy): %@", url.absoluteString);

    if (shouldRedirectURL(url)) {
        NSURL *newURL = [NSURL URLWithString:kTargetURL];
        NSLog(@"[Hook] Legacy: thay bằng %@", newURL.absoluteString);
        return orig_openURL_legacy(self, _cmd, newURL);
    }

    return orig_openURL_legacy(self, _cmd, url);
}

static void swizzleInstanceMethod(Class cls, SEL sel, IMP newIMP, IMP *outOrigIMP) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) {
        NSLog(@"[Hook] Không tìm thấy method %@", NSStringFromSelector(sel));
        return;
    }
    if (outOrigIMP) {
        *outOrigIMP = method_getImplementation(m);
    }
    class_replaceMethod(cls, sel, newIMP, method_getTypeEncoding(m));
    NSLog(@"[Hook] Đã hook %@", NSStringFromSelector(sel));
}

__attribute__((constructor))
static void initHook(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        Class appCls = objc_getClass("UIApplication");
        if (!appCls) {
            NSLog(@"[Hook] Không tìm thấy UIApplication");
            return;
        }

        swizzleInstanceMethod(appCls,
                              @selector(openURL:options:completionHandler:),
                              (IMP)my_openURL_options_completion,
                              (IMP *)&orig_openURL_options_completion);

        swizzleInstanceMethod(appCls,
                              @selector(openURL:),
                              (IMP)my_openURL_legacy,
                              (IMP *)&orig_openURL_legacy);
    });
}
