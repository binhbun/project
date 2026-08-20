
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define LOG(fmt, ...) NSLog(@"[Bypass] " fmt, ##__VA_ARGS__)

static NSArray* kTargetDomains = @[@"getuid.vip", @"getuid.vip"];
static NSString* kReplacementDomain = @"proxyvip.teamgamehub99.workers.dev";

// ==================== HOOK +[NSURL URLWithString:] ====================
static NSURL* (*orig_URLWithString)(id self, SEL _cmd, NSString *URLString);
static NSURL* override_URLWithString(id self, SEL _cmd, NSString *URLString) {
    if (URLString) {
        for (NSString *target in kTargetDomains) {
            if ([URLString containsString:target]) {
                NSString *newURL = [URLString stringByReplacingOccurrencesOfString:target 
                                                                         withString:kReplacementDomain];
                if ([newURL hasPrefix:@"http://"]) {
                    newURL = [newURL stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                }
                LOG(@"URLWithString: %@ -> %@", URLString, newURL);
                return orig_URLWithString(self, _cmd, newURL);
            }
        }
    }
    return orig_URLWithString(self, _cmd, URLString);
}

// ==================== HOOK +[NSURL URLWithString:relativeToURL:] ====================
static NSURL* (*orig_URLWithString_relative)(id self, SEL _cmd, NSString *URLString, NSURL *baseURL);
static NSURL* override_URLWithString_relative(id self, SEL _cmd, NSString *URLString, NSURL *baseURL) {
    if (baseURL) {
        NSString *baseString = [baseURL absoluteString];
        for (NSString *target in kTargetDomains) {
            if ([baseString containsString:target]) {
                NSString *newBase = [baseString stringByReplacingOccurrencesOfString:target 
                                                                          withString:kReplacementDomain];
                if ([newBase hasPrefix:@"http://"]) {
                    newBase = [newBase stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                }
                NSURL *newBaseURL = [NSURL URLWithString:newBase];
                LOG(@"URLWithString:relative: %@ -> %@", baseString, newBase);
                return orig_URLWithString_relative(self, _cmd, URLString, newBaseURL);
            }
        }
    }
    return orig_URLWithString_relative(self, _cmd, URLString, baseURL);
}

// ==================== HOOK -[NSMutableURLRequest setURL:] ====================
static void (*orig_setURL)(id self, SEL _cmd, NSURL *url);
static void override_setURL(id self, SEL _cmd, NSURL *url) {
    if (url) {
        NSString *urlString = [url absoluteString];
        for (NSString *target in kTargetDomains) {
            if ([urlString containsString:target]) {
                NSString *newURLString = [urlString stringByReplacingOccurrencesOfString:target 
                                                                              withString:kReplacementDomain];
                if ([newURLString hasPrefix:@"http://"]) {
                    newURLString = [newURLString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                }
                NSURL *newURL = [NSURL URLWithString:newURLString];
                LOG(@"setURL: %@ -> %@", urlString, newURLString);
                orig_setURL(self, _cmd, newURL);
                return;
            }
        }
    }
    orig_setURL(self, _cmd, url);
}

// ==================== HOOK NSURLSession dataTaskWithRequest ====================
static NSURLSessionDataTask* (*orig_dataTaskWithRequest)(id self, SEL _cmd, NSURLRequest *request, id completionHandler);
static NSURLSessionDataTask* override_dataTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, id completionHandler) {
    NSURL *url = [request URL];
    if (url) {
        NSString *urlString = [url absoluteString];
        for (NSString *target in kTargetDomains) {
            if ([urlString containsString:target]) {
                NSMutableURLRequest *mutableRequest = [request mutableCopy];
                NSString *newURLString = [urlString stringByReplacingOccurrencesOfString:target 
                                                                              withString:kReplacementDomain];
                if ([newURLString hasPrefix:@"http://"]) {
                    newURLString = [newURLString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                }
                [mutableRequest setURL:[NSURL URLWithString:newURLString]];
                
                NSDictionary *headers = request.allHTTPHeaderFields;
                for (NSString *key in headers) {
                    if (![key isEqualToString:@"Host"]) {
                        [mutableRequest setValue:headers[key] forHTTPHeaderField:key];
                    }
                }
                
                LOG(@"dataTask: %@ -> %@", urlString, newURLString);
                return orig_dataTaskWithRequest(self, _cmd, mutableRequest, completionHandler);
            }
        }
    }
    return orig_dataTaskWithRequest(self, _cmd, request, completionHandler);
}

// ==================== HOOK NSURLSession dataTaskWithURL ====================
static NSURLSessionDataTask* (*orig_dataTaskWithURL)(id self, SEL _cmd, NSURL *url);
static NSURLSessionDataTask* override_dataTaskWithURL(id self, SEL _cmd, NSURL *url) {
    if (url) {
        NSString *urlString = [url absoluteString];
        for (NSString *target in kTargetDomains) {
            if ([urlString containsString:target]) {
                NSString *newURLString = [urlString stringByReplacingOccurrencesOfString:target 
                                                                              withString:kReplacementDomain];
                if ([newURLString hasPrefix:@"http://"]) {
                    newURLString = [newURLString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                }
                NSURL *newURL = [NSURL URLWithString:newURLString];
                LOG(@"dataTaskWithURL: %@ -> %@", urlString, newURLString);
                return orig_dataTaskWithURL(self, _cmd, newURL);
            }
        }
    }
    return orig_dataTaskWithURL(self, _cmd, url);
}

// ==================== HOOK NSURLConnection ====================
static NSURLConnection* (*orig_connectionWithRequest)(id self, SEL _cmd, NSURLRequest *request, id delegate);
static NSURLConnection* override_connectionWithRequest(id self, SEL _cmd, NSURLRequest *request, id delegate) {
    NSURL *url = [request URL];
    if (url) {
        NSString *urlString = [url absoluteString];
        for (NSString *target in kTargetDomains) {
            if ([urlString containsString:target]) {
                NSMutableURLRequest *mutableRequest = [request mutableCopy];
                NSString *newURLString = [urlString stringByReplacingOccurrencesOfString:target 
                                                                              withString:kReplacementDomain];
                if ([newURLString hasPrefix:@"http://"]) {
                    newURLString = [newURLString stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                }
                [mutableRequest setURL:[NSURL URLWithString:newURLString]];
                LOG(@"connectionWithRequest: %@ -> %@", urlString, newURLString);
                return orig_connectionWithRequest(self, _cmd, mutableRequest, delegate);
            }
        }
    }
    return orig_connectionWithRequest(self, _cmd, request, delegate);
}

// ==================== SWIZZLE ====================
static void swizzleMethod(Class cls, SEL original, IMP replacement, IMP *store) {
    Method method = class_getClassMethod(cls, original);
    if (!method) method = class_getInstanceMethod(cls, original);
    if (method) {
        *store = (IMP)method_getImplementation(method);
        class_replaceMethod(cls, original, replacement, method_getTypeEncoding(method));
        LOG(@"Swizzled: %@ %@", NSStringFromClass(cls), NSStringFromSelector(original));
    }
}

// ==================== INIT ====================
__attribute__((constructor)) static void initialize() {
    @autoreleasepool {
        LOG(@"========================================");
        LOG(@"Bypass Loaded! Redirecting: %@ -> %@", kTargetDomains, kReplacementDomain);
        LOG(@"========================================");

        swizzleMethod(objc_getClass("NSURL"), @selector(URLWithString:),
                      (IMP)&override_URLWithString, (IMP*)&orig_URLWithString);
        
        swizzleMethod(objc_getClass("NSURL"), @selector(URLWithString:relativeToURL:),
                      (IMP)&override_URLWithString_relative, (IMP*)&orig_URLWithString_relative);
        
        swizzleMethod(objc_getClass("NSMutableURLRequest"), @selector(setURL:),
                      (IMP)&override_setURL, (IMP*)&orig_setURL);
        
        swizzleMethod(objc_getClass("NSURLSession"), @selector(dataTaskWithRequest:completionHandler:),
                      (IMP)&override_dataTaskWithRequest, (IMP*)&orig_dataTaskWithRequest);
        
        swizzleMethod(objc_getClass("NSURLSession"), @selector(dataTaskWithURL:),
                      (IMP)&override_dataTaskWithURL, (IMP*)&orig_dataTaskWithURL);
        
        swizzleMethod(objc_getClass("NSURLConnection"), @selector(connectionWithRequest:delegate:),
                      (IMP)&override_connectionWithRequest, (IMP*)&orig_connectionWithRequest);

        LOG(@"All hooks installed!");
    }
}
