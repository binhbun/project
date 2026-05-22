#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);

// 1. Tầng Xác thực: Giữ nguyên khóa cứng Class Method luôn trả về YES
BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    NSLog(@"[BypassTweak] ---> Khóa thành công Class Method verifySignature! Ép trạng thái TRẢ VỀ YES.");
    return YES;
}

// 2. Tầng Dữ liệu: Sử dụng Regex để quét sạch và hiệu chỉnh chuỗi JSON bất kể khoảng trắng
id replaced_JSONObjectWithData(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error) {
    if (!data) {
        return orig_JSONObjectWithData(self, _cmd, data, opt, error);
    }

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (jsonStr) {
        // --- XỬ LÝ 1: Triệt tiêu Dialog đòi Key (package-v3) ---
        if ([jsonStr containsString:@"clientIdMode"] && ([jsonStr containsString:@"requireAuth"] || [jsonStr containsString:@"requireAuth "])) {
            NSLog(@"[BypassTweak] Phát hiện chuỗi package-v3. Tiến hành áp dụng bộ lọc Regex cho requireAuth...");
            
            // Regex @"\"requireAuth\"\\s*:\\s*true" nhận diện được cả "requireAuth":true, "requireAuth" : true, "requireAuth": true
            NSRegularExpression *regexAuth = [NSRegularExpression regularExpressionWithPattern:@"\"requireAuth\"\\s*:\\s*true" 
                                                                                       options:NSRegularExpressionCaseInsensitive 
                                                                                         error:nil];
            
            NSMutableString *mutableJson = [jsonStr mutableCopy];
            [regexAuth replaceMatchesInString:mutableJson 
                                      options:0 
                                        range:NSMakeRange(0, mutableJson.length) 
                                 withTemplate:@"\"requireAuth\":false"];
            
            NSLog(@"[BypassTweak] Kết quả sau hiệu chỉnh package-v3: %@", mutableJson);
            
            NSData *modifiedData = [mutableJson dataUsingEncoding:NSUTF8StringEncoding];
            return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
        }
        
        // --- XỬ LÝ 2: Ép cấu trúc tài khoản VIP (credential-v3) ---
        if ([jsonStr containsString:@"expiredAt"] || [jsonStr containsString:@"device_udid"] || [jsonStr containsString:@"\"code\":9999"]) {
            NSLog(@"[BypassTweak] Phát hiện chuỗi credential-v3. Đang tiến hành chuyển đổi sang gói VIP...");
            
            NSMutableString *mutableJson = [jsonStr mutableCopy];
            
            // Xử lý loại tài khoản sang premium
            NSRegularExpression *regexType = [NSRegularExpression regularExpressionWithPattern:@"\"type\"\\s*:\\s*\"normal\"" options:0 error:nil];
            [regexType replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"\"type\":\"premium\""];
            
            // Xử lý nạp gói kích hoạt từ null sang chuỗi active
            NSRegularExpression *regexPkg = [NSRegularExpression regularExpressionWithPattern:@"\"package\"\\s*:\\s*\\{\\s*\"data\"\\s*:\\s*null\\s*\\}" options:0 error:nil];
            [regexPkg replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"\"package\":{\"data\":\"activated_package_premium\"}"];
            
            // Xử lý gia hạn thời gian (Tự động tìm bất kỳ ngày nào trong năm 2026 đổi thành 2036)
            NSRegularExpression *regexYear = [NSRegularExpression regularExpressionWithPattern:@"2026-" options:0 error:nil];
            [regexYear replaceMatchesInString:mutableJson options:0 range:NSMakeRange(0, mutableJson.length) withTemplate:@"9999-"];
            
            NSLog(@"[BypassTweak] Kết quả sau hiệu chỉnh credential-v3 VIP: %@", mutableJson);
            
            NSData *modifiedData = [mutableJson dataUsingEncoding:NSUTF8StringEncoding];
            return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
        }
    }

    return orig_JSONObjectWithData(self, _cmd, data, opt, error);
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {
        NSLog(@"[BypassTweak] Khởi chạy kiến trúc Hybrid Bypass v4 (Regex Engine Mode)...");

        // Hook Class Method (+) verifySignature:... của lớp NetTool
        Class netToolClass = NSClassFromString(@"NetTool");
        if (netToolClass) {
            SEL verifySelector = NSSelectorFromString(@"verifySignature:withData:usingPublicKeyString:");
            Method verifyMethod = class_getClassMethod(netToolClass, verifySelector);
            if (verifyMethod) {
                method_setImplementation(verifyMethod, (IMP)replaced_verifySignature_withData_usingPublicKeyString);
                NSLog(@"[BypassTweak] -> Đã đồng bộ liên kết kiểm tra chữ ký NetTool.");
            }
        }

        // Hook phương thức dịch JSON hệ thống
        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        if (jsonClass) {
            SEL jsonSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
            Method jsonMethod = class_getClassMethod(jsonClass, jsonSelector);
            if (jsonMethod) {
                orig_JSONObjectWithData = (id(*)(Class, SEL, NSData*, NSJSONReadingOptions, NSError**))method_setImplementation(jsonMethod, (IMP)replaced_JSONObjectWithData);
                NSLog(@"[BypassTweak] -> Đã kích hoạt bộ phân tích xử lý Regex.");
            }
        }
        
        // Vô hiệu hóa giao diện thông báo lỗi (ASStatusView)
        Class errorUIClass = NSClassFromString(@"ASStatusView");
        if (errorUIClass) {
            SEL showSelector = NSSelectorFromString(@"showErrorWithTitle:message:buttonTitle:");
            Method uiMethod = class_getInstanceMethod(errorUIClass, showSelector);
            if (uiMethod) {
                method_setImplementation(uiMethod, imp_implementationWithBlock(^(id self, id title, id msg, id btn) {
                    NSLog(@"[BypassTweak] Khóa hộp thoại thông báo lỗi.");
                }));
            }
        }

        Class errorUIClass1 = NSClassFromString(@"ASStatusView");
        if (errorUIClass1) {
            SEL showSelector1 = NSSelectorFromString(@"showSuccessWithTitle:message:buttonTitle:");
            Method uiMethod1 = class_getInstanceMethod(errorUIClass1, showSelector1);
            if (uiMethod1) {
                method_setImplementation(uiMethod1, imp_implementationWithBlock(^(id self, id title, id msg, id btn) {
                    NSLog(@"[BypassTweak] Khóa hộp thoại thông báo done.");
                }));
            }
        }
    }
}
