#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

NSURLRequest *modifyRequestIfNeeded(NSURLRequest *request) {
    if (!request || !request.URL) return request;
    
    NSString *urlString = request.URL.absoluteString;
    if (!urlString) return request;
    
    if ([urlString containsString:@"api.cheatiosvip.net"] && 
        [urlString containsString:@"/api/app/config"]) {
        
        NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.cheatiosvip.net" 
                                                                      withString:@"api1.teamgamehub99.workers.dev"];
        
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.URL = [NSURL URLWithString:newUrlString];
        
        NSLog(@"[Bypass] Redirecting config request: %@ -> %@", urlString, newUrlString);
        return [mutableRequest copy];
    }
    
    return request;
}

NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

typedef id (*InitWithURL_t)(id, SEL, id);
static InitWithURL_t orig_initWithURL = NULL;

id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        if ([urlString containsString:@"api.cheatiosvip.net"] && 
            [urlString containsString:@"/api/app/config"]) {
            
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.cheatiosvip.net" 
                                                                          withString:@"api1.teamgamehub99.workers.dev"];
            NSLog(@"[Bypass] Redirecting config request: %@ -> %@", urlString, newUrlString);
            return orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {
        // Hook NSURLSession
        Class sessionClass = NSClassFromString(@"NSURLSession");
        if (sessionClass) {
            SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
            Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
            
            if (targetMethod) {
                orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
                method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);
                NSLog(@"[Bypass] NSURLSession hook installed");
            } else {
                NSLog(@"[Bypass] Failed to find NSURLSession method");
            }
        }

        Method m = class_getInstanceMethod(NSClassFromString(@"NSMutableURLRequest"), @selector(initWithURL:));
        if (m) {
            orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_initWithURL);
            NSLog(@"[Bypass] NSMutableURLRequest hook installed");
        }
    }
}


////////////////////////




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

NSURLRequest *modifyRequestIfNeeded(NSURLRequest *request) {
    if (!request || !request.URL) return request;
    
    NSString *host = request.URL.host;
    if (!host) return request;
    
    if ([host isEqualToString:@"api.cheatiosvip.net"]) {
        
        NSString *urlString = request.URL.absoluteString;
        NSString *targetHost = @"api1.teamgamehub99.workers.dev";
        
        NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:host withString:targetHost];
        
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.URL = [NSURL URLWithString:newUrlString];
        
        NSLog(@": %@ -> %@", urlString, newUrlString);
        return [mutableRequest copy];
    }
    
    return request;
}

NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

typedef id (*InitWithURL_t)(id, SEL, id);

static InitWithURL_t orig_initWithURL = NULL;

id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        if ([urlString containsString:@"api.cheatiosvip.net"]) {
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.cheatiosvip.net" 
                                                                          withString:@"api1.teamgamehub99.workers.dev"];
            NSLog(@"[Bypass] Redirecting: %@ -> %@", urlString, newUrlString);
            return orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {

       Class sessionClass = NSClassFromString(@"NSURLSession");
    if (sessionClass) {
        SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
        Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
        
        if (targetMethod) {
            orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
            method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);
            NSLog(@"");
        } else {
            NSLog(@"");
        }
    }




        Method m = class_getInstanceMethod(NSClassFromString(@"NSMutableURLRequest"), @selector(initWithURL:));
        
        if (m) {
            orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_initWithURL);
            
        }

    
    }
}
