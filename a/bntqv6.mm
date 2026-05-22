#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);

BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    return YES;
}

id replaced_JSONObjectWithData(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error) {
    if (!data) {
        return orig_JSONObjectWithData(self, _cmd, data, opt, error);
    }

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (jsonStr) {
        if ([jsonStr containsString:@"clientIdMode"] && [jsonStr containsString:@"requireAuth"]) {
            
            NSString *modifiedStr = [jsonStr stringByReplacingOccurrencesOfString:@"\"requireAuth\":true" 
                                                                       withString:@"\"requireAuth\":false"];
            
            NSData *modifiedData = [modifiedStr dataUsingEncoding:NSUTF8StringEncoding];
            return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
        }
        
        if ([jsonStr containsString:@"expiredAt"] || [jsonStr containsString:@"device_udid"] || [jsonStr containsString:@"\"code\":9999"]) {
            
            NSString *modifiedStr = [jsonStr stringByReplacingOccurrencesOfString:@"\"type\":\"normal\"" 
                                                                       withString:@"\"type\":\"premium\""];
            
            modifiedStr = [modifiedStr stringByReplacingOccurrencesOfString:@"\"package\":{\"data\":null}" 
                                                                 withString:@"\"package\":{\"data\":\"activated_package_premium\"}"];
            
            modifiedStr = [modifiedStr stringByReplacingOccurrencesOfString:@"2026-05-22" 
                                                                 withString:@"9999-05-22"];
            
            NSData *modifiedData = [modifiedStr dataUsingEncoding:NSUTF8StringEncoding];
            return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
        }
    }

    return orig_JSONObjectWithData(self, _cmd, data, opt, error);
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {
        Class netToolClass = NSClassFromString(@"NetTool");
        if (netToolClass) {
            SEL verifySelector = NSSelectorFromString(@"verifySignature:withData:usingPublicKeyString:");
            
            Method verifyMethod = class_getClassMethod(netToolClass, verifySelector);
            
            if (verifyMethod) {
                method_setImplementation(verifyMethod, (IMP)replaced_verifySignature_withData_usingPublicKeyString);
            } else {
            }
        }
        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        if (jsonClass) {
            SEL jsonSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
            Method jsonMethod = class_getClassMethod(jsonClass, jsonSelector);
            if (jsonMethod) {
                orig_JSONObjectWithData = (id(*)(Class, SEL, NSData*, NSJSONReadingOptions, NSError**))method_setImplementation(jsonMethod, (IMP)replaced_JSONObjectWithData);
            }
        }
        
        Class errorUIClass = NSClassFromString(@"ASStatusView");
        if (errorUIClass) {
            SEL showAnimSelector = NSSelectorFromString(@"showWithAnimation");
            Method showAnimMethod = class_getInstanceMethod(errorUIClass, showAnimSelector);
            if (showAnimMethod) {
                method_setImplementation(showAnimMethod, imp_implementationWithBlock(^(id self) {
                }));
            }

            SEL initSelector = NSSelectorFromString(@"initWithFrame:");
            Method initMethod = class_getInstanceMethod(errorUIClass, initSelector);
            if (initMethod) {
                id (*orig_initWithFrame)(id, SEL, CGRect) = (id(*)(id, SEL, CGRect))method_getImplementation(initMethod);
                method_setImplementation(initMethod, imp_implementationWithBlock(^(id self, CGRect frame) {
                    id instance = orig_initWithFrame(self, initSelector, frame);
                    if (instance && [instance isKindOfClass:[UIView class]]) {
                        ((UIView *)instance).hidden = YES;
                        ((UIView *)instance).alpha = 0.0f;
                    }
                    return instance;
                }));
            }

            SEL initSecureSelector = NSSelectorFromString(@"initWithFrame:secureMode:");
            Method initSecureMethod = class_getInstanceMethod(errorUIClass, initSecureSelector);
            if (initSecureMethod) {
                id (*orig_initWithFrameSecure)(id, SEL, CGRect, BOOL) = (id(*)(id, SEL, CGRect, BOOL))method_getImplementation(initSecureMethod);
                method_setImplementation(initSecureMethod, imp_implementationWithBlock(^(id self, CGRect frame, BOOL secureMode) {
                    id instance = orig_initWithFrameSecure(self, initSecureSelector, frame, secureMode);
                    if (instance && [instance isKindOfClass:[UIView class]]) {
                        ((UIView *)instance).hidden = YES;
                        ((UIView *)instance).alpha = 0.0f;
                    }
                    return instance;
                }));
            }
        }
    }
}