#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);

BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    return YES;
}

static NSString *getDeviceUDID() {
    return [[UIDevice currentDevice].identifierForVendor UUIDString]; 
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
        NSRegularExpression *regexAuth = [NSRegularExpression regularExpressionWithPattern:@"\"requireAuth\"\\s*:\\s*true" options:NSRegularExpressionCaseInsensitive error:nil];
        [regexAuth replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"\"requireAuth\":false"];
        isModified = YES;
    }

    if ([jsonStr containsString:@"isExpired"] || [jsonStr containsString:@"expiredAt"]) {
        NSLog(@"[AppLoggerBypass] Nắn dữ liệu VIP...");

        NSRegularExpression *regexUDID = [NSRegularExpression regularExpressionWithPattern:@"\"device_udid\"\\s*:\\s*\"[^\"]+\"" options:0 error:nil];
        [regexUDID replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:[NSString stringWithFormat:@"\"device_udid\":\"%@\"", getDeviceUDID()]];

        [mutableJson replaceOccurrencesOfString:@"\"isExpired\":true" withString:@"\"isExpired\":false" options:0 range:NSMakeRange(0, mutableJson.length)];
        
        NSRegularExpression *regexDate = [NSRegularExpression regularExpressionWithPattern:@"\"expiredAt\"\\s*:\\s*\"[^\"]+\"" options:0 error:nil];
        [regexDate replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"\"expiredAt\":\"9999-12-23T10:41:57.000Z\""];
        
        NSRegularExpression *regexKey = [NSRegularExpression regularExpressionWithPattern:@"\"key\"\\s*:\\s*\"[^\"]+\"" options:0 error:nil];
        [regexKey replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"\"key\":\"GMVMOBA-BINHBUN\""];
        
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

        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        if (jsonClass) {
            SEL jsonSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
            Method jsonMethod = class_getClassMethod(jsonClass, jsonSelector);
            if (jsonMethod) {
                orig_JSONObjectWithData = (id(*)(Class, SEL, NSData*, NSJSONReadingOptions, NSError**))method_setImplementation(jsonMethod, (IMP)replaced_JSONObjectWithData);
                NSLog(@"[AppLoggerBypass] -> Đã kích hoạt bộ phân tích xử lý Regex.");
            }
        }
    }
}
