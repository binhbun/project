#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define TARGET_CLASS "APIKEY"

@interface Binhbun : NSObject
@end

@implementation Binhbun

+ (void)paid:(id)completion {
    NSLog(@"[Binhbun] Bypassing paid: block...");
    if (completion) {
        void (^block)(void) = completion;
        block();
    }
}

- (BOOL)hasShownSuccessAlert {
    return YES;
}

- (void)checkKey { 
    NSLog(@"[Binhbun] checkKey bypassed.");
}

- (void)checkAndRequestUDIDIfNeeded {
    NSLog(@"[Binhbun] checkAndRequestUDID bypassed.");
}

- (void)checkUDIDStatusFromServer:(id)a3 {
    NSLog(@"[Binhbun] checkUDIDStatusFromServer bypassed.");
}

- (id)savedUDID {
    return @"Binhbun-BYPASS-UDID-9999";
}

- (BOOL)hasUDID {
    return YES;
}

@end

static __attribute__((constructor)) void init_Binhbun_bypass() {
     dispatch_async(dispatch_get_main_queue(), ^{
        
        Class targetCls = objc_getClass(TARGET_CLASS);
        Class customCls = [Binhbun class];

        if (targetCls && customCls) {
            NSArray *instanceMethods = @[
                @"checkKey", 
                @"checkAndRequestUDIDIfNeeded", 
                @"hasShownSuccessAlert",
                @"checkUDIDStatusFromServer:",
                @"savedUDID",
                @"hasUDID"
            ];

            for (NSString *selName in instanceMethods) {
                SEL sel = NSSelectorFromString(selName);
                Method origM = class_getInstanceMethod(targetCls, sel);
                Method custM = class_getInstanceMethod(customCls, sel);
                
                if (origM && custM) {
                    method_exchangeImplementations(origM, custM);
                }
            }

            Method origClassMethod = class_getClassMethod(targetCls, @selector(paid:));
            Method custClassMethod = class_getClassMethod(customCls, @selector(paid:));
            
            if (origClassMethod && custClassMethod) {
                method_exchangeImplementations(origClassMethod, custClassMethod);
            }
            
            NSLog(@"[Binhbun] Successfully hooked %s", TARGET_CLASS);
        } else {
            NSLog(@"[Binhbun] Failed to find class %s", TARGET_CLASS);
        }
    });
}