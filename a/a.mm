#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <Security/Security.h>

#define TARGET_CLASS "APIClient"

@interface APIClient_Twink : NSObject
@end

@implementation APIClient_Twink

+ (id)sharedAPIClient {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)paid:(id)completion {
    if (completion) {
        void (^block)(void) = completion;
        block();
    }
}

- (void)start:(id)comp1 init:(id)comp2 {
    if (comp2) { ((void (^)(void))comp2)(); }
    if (comp1) { ((void (^)(void))comp1)(); }
}

- (void)setToken:(id)token {
    NSLog(@"[Gemini] Token: %@", token);
}

- (void)hideUI:(BOOL)a3 { }
- (void)strictMode:(BOOL)a3 { }
- (void)silentMode:(BOOL)a3 { }

- (id)getPackageDataWithKey:(id)key {
    return [NSNumber numberWithBool:YES];
}

- (id)getKey { return @"Kabra       "; }
- (id)getExpiryDate { return @"9999-12-31"; }
- (id)getUDID { return @"gmvmobabinhbun"; }
- (id)getLoginIP { return @"127.0.0.1"; }
- (id)getPackageName { return @"com.gmvmoba.binhbun"; }

- (id)getDeviceModel {
    return [[UIDevice currentDevice] model];
}

@end


static __attribute__((constructor)) void init_gemini_bypass() {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        Class targetCls = objc_getClass(TARGET_CLASS);
        Class customCls = [APIClient_Twink class];

        if (targetCls && customCls) {
            NSArray *methods = @[
                @"paid:", @"start:init:", @"setToken:", @"hideUI:", 
                @"strictMode:", @"silentMode:", @"getPackageDataWithKey:", 
                @"getKey", @"getExpiryDate", @"getUDID", 
                @"getLoginIP", @"getPackageName"
            ];

            for (NSString *selName in methods) {
                SEL sel = NSSelectorFromString(selName);
                Method origM = class_getInstanceMethod(targetCls, sel);
                Method custM = class_getInstanceMethod(customCls, sel);
                
                if (origM && custM) {
                    method_exchangeImplementations(origM, custM);
                }
            }

            Method origS = class_getClassMethod(targetCls, @selector(sharedAPIClient));
            Method custS = class_getClassMethod(customCls, @selector(sharedAPIClient));
            
            if (origS && custS) {
                method_exchangeImplementations(origS, custS);
            }
            
            NSLog(@"[Gemini] Successfully %s", TARGET_CLASS);
        }
    });
}