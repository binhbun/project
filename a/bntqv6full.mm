#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    return YES;
}

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

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
        
        NSLog(@"[NSURLSession Hook] Đã phát hiện và chuyển hướng URL: %@ -> %@", urlString, newUrlString);
        return [mutableRequest copy];
    }
    
    return request;
}

NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    
    // Kiểm tra và thay đổi request trước khi chuyển tiếp cho hàm gốc
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    
    // Trả quyền điều khiển lại cho hàm gốc chạy tiếp tục
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

typedef id (*InitWithURL_t)(id, SEL, id);

static InitWithURL_t orig_initWithURL = NULL;

id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        if ([urlString containsString:@"api.authtool.app"]) {
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.authtool.app" 
                                                                          withString:@"calm-unit-61cc.teamgamehub99.workers.dev"];
            NSLog(@"[Bypass] Redirecting: %@ -> %@", urlString, newUrlString);
            return orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {
        NSLog(@"[AppLoggerBypass] Khởi chạy kiến trúc Hybrid Bypass v4 (Regex Engine Mode)...");

        Class netToolClass = NSClassFromString(@"NetTool");
        if (netToolClass) {
            SEL verifySelector = NSSelectorFromString(@"verifySignature:withData:usingPublicKeyString:");
            Method verifyMethod = class_getClassMethod(netToolClass, verifySelector);
            if (verifyMethod) {
                method_setImplementation(verifyMethod, (IMP)replaced_verifySignature_withData_usingPublicKeyString);
                NSLog(@"[AppLoggerBypass] -> Đã đồng bộ liên kết kiểm tra chữ ký NetTool.");
            }
        }

       Class sessionClass = NSClassFromString(@"NSURLSession");
    if (sessionClass) {
        SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
        Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
        
        if (targetMethod) {
            orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
            method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);
            NSLog(@"[NSURLSession Hook] Khởi tạo Hook dataTaskWithRequest thành công!");
        } else {
            NSLog(@"[NSURLSession Hook] Không tìm thấy method.");
        }
    }

        Method m = class_getInstanceMethod(NSClassFromString(@"NSMutableURLRequest"), @selector(initWithURL:));
        
        if (m) {
            // 4. Ép kiểu an toàn bằng typedef đã định nghĩa ở trên
            orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_initWithURL);
            
            NSLog(@"[Bypass] Hook thành công!");
        }

    
    }
}
