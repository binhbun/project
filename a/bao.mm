#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    return YES;
}

static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);


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


id replaced_JSONObjectWithData(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error) {
    if (!data) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!jsonStr) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSMutableString *mutableJson = [jsonStr mutableCopy];
    BOOL isModified = NO;

    if ([mutableJson containsString:@"\"clientIdMode\":\"UDID\""]) {
        [mutableJson replaceOccurrencesOfString:@"\"clientIdMode\":\"UDID\"" withString:@"\"clientIdMode\":\"IDFA\"" options:0 range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([mutableJson containsString:@"\"isRealTimeEventEnable\":true"]) {
        [mutableJson replaceOccurrencesOfString:@"\"isRealTimeEventEnable\":true" withString:@"\"isRealTimeEventEnable\":false" options:0 range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([jsonStr containsString:@"requireAuth"]) {
        NSRegularExpression *regexAuth = [NSRegularExpression regularExpressionWithPattern:@"\"requireAuth\"\\s*:\\s*false" options:NSRegularExpressionCaseInsensitive error:nil];
        [regexAuth replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"\"requireAuth\":true"];
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
    NSLog(@"[AppLoggerBypass] Đã đồng bộ unix time thành công: %@", liveUnixStr);
}


 if ([jsonStr containsString:@"expiredAt"]) {
         NSRegularExpression *regexDate = [NSRegularExpression regularExpressionWithPattern:@"\"expiredAt\"\\s*:\\s*\"[^\"]+\"" options:0 error:nil];
        [regexDate replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"\"expiredAt\":\"9999-01-01T06:41:57.000Z\""];
        isModified = YES;
    }

    if (isModified) {
        NSData *modifiedData = [mutableJson dataUsingEncoding:NSUTF8StringEncoding];
        return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
    }

    return orig_JSONObjectWithData(self, _cmd, data, opt, error);
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

     Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        if (jsonClass) {
            SEL jsonSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
            Method jsonMethod = class_getClassMethod(jsonClass, jsonSelector);
            if (jsonMethod) {
                orig_JSONObjectWithData = (id(*)(Class, SEL, NSData*, NSJSONReadingOptions, NSError**))method_setImplementation(jsonMethod, (IMP)replaced_JSONObjectWithData);
                NSLog(@"[AppLoggerBypass] -> Đã kích hoạt bộ phân tích xử lý Regex.");
            }
        }

        Method m = class_getInstanceMethod(NSClassFromString(@"NSMutableURLRequest"), @selector(initWithURL:));
        
        if (m) {
            orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_initWithURL);
            
            NSLog(@"[Bypass] Hook thành công!");
        }

    
    }
}
