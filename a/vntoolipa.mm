#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static long long hooked_verifyKeyDetailed(id self, SEL _cmd, id a3) {
    return 0;
}

static void hooked_promptKeyOnRoot(id self, SEL _cmd, id rootVC, id completion) {
    if (completion) {
        void (^block)(NSString *) = (void (^)(NSString *))completion;
        block(@"BINHBUN_BYPASS_KEY");
    }
}

static bool hooked_firestorePatchLicense(id self, SEL _cmd, id a3, id a4, long long a5) {
    return YES;
}

static long long hooked_maintenanceStateMessage(id self, SEL _cmd, id *a3) {
    if (a3) {
        *a3 = @"";
    }
    return 0;
}


__attribute__((constructor))
static void init_pubg_bypass(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class meta = objc_getMetaClass("PubgLoad");
        if (!meta) {
            return;
        }

        struct {
            SEL selector;
            IMP newIMP;
        } hooks[] = {
            { NSSelectorFromString(@"verifyKeyDetailed:"), (IMP)hooked_verifyKeyDetailed },
            { NSSelectorFromString(@"promptKeyOnRoot:completion:"), (IMP)hooked_promptKeyOnRoot },
            { NSSelectorFromString(@"firestorePatchLicense:deviceIDs:activations:"), (IMP)hooked_firestorePatchLicense },
            { NSSelectorFromString(@"maintenanceStateMessage:"), (IMP)hooked_maintenanceStateMessage },
        };

        for (int i = 0; i < sizeof(hooks)/sizeof(hooks[0]); i++) {
            Method method = class_getClassMethod(meta, hooks[i].selector);
            if (method) {
                method_setImplementation(method, hooks[i].newIMP);
                NSLog(@"[ %@]", NSStringFromSelector(hooks[i].selector));
            } else {
                NSLog(@"[ %@]", NSStringFromSelector(hooks[i].selector));
            }
        }
    });
}



/////////////////////////




#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>


static long long hooked_verifyKeyDetailed(id self, SEL _cmd, id a3) {
    return 0;
}

static void hooked_promptKeyOnRoot(id self, SEL _cmd, id rootVC, id completion) {
    if (completion) {
        void (^block)(NSString *) = (void (^)(NSString *))completion;
        block(@"BINHBUN_BYPASS_KEY");
    }
}

static bool hooked_firestorePatchLicense(id self, SEL _cmd, id a3, id a4, long long a5) {
    return YES;
}

static long long hooked_maintenanceStateMessage(id self, SEL _cmd, id *a3) {
    if (a3) {
        *a3 = @"";
    }
    return 0;
}

static void (*original_feedbackTelegramTapped)(id self, SEL _cmd);

void hooked_feedbackTelegramTapped(id self, SEL _cmd) {
    
    NSURL *discordURL = [NSURL URLWithString:@"https://discord.com/invite/FgTZ5GmTbz"];
    
    if (!discordURL) {
        return;
    }
    
    UIApplication *app = [UIApplication sharedApplication];
    
    if ([app canOpenURL:discordURL]) {
        NSLog(@" %@", discordURL);
        [app openURL:discordURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
            } else {
            }
        }];
    } else {
        NSURL *webURL = [NSURL URLWithString:@"https://discord.com/invite/FgTZ5GmTbz"];
        [app openURL:webURL options:@{} completionHandler:nil];
    }
}

__attribute__((constructor))
static void initialize() {
    
    Class targetClass = NSClassFromString(@"ImGuiDrawView");
    if (!targetClass) {
        return;
    }
    
    SEL selector = sel_registerName("feedbackTelegramTapped");
    Method originalMethod = class_getInstanceMethod(targetClass, selector);
    
    if (!originalMethod) {
        return;
    }
    
    original_feedbackTelegramTapped = (void (*)(id, SEL))method_getImplementation(originalMethod);
    
    class_replaceMethod(targetClass, 
                        selector, 
                        (IMP)hooked_feedbackTelegramTapped, 
                        method_getTypeEncoding(originalMethod));
    
}
__attribute__((constructor))
static void init_pubg_bypass(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class meta = objc_getMetaClass("PubgLoad");
        if (!meta) {
            return;
        }

        struct {
            SEL selector;
            IMP newIMP;
        } hooks[] = {
            { NSSelectorFromString(@"verifyKeyDetailed:"), (IMP)hooked_verifyKeyDetailed },
            { NSSelectorFromString(@"promptKeyOnRoot:completion:"), (IMP)hooked_promptKeyOnRoot },
            { NSSelectorFromString(@"firestorePatchLicense:deviceIDs:activations:"), (IMP)hooked_firestorePatchLicense },
            { NSSelectorFromString(@"maintenanceStateMessage:"), (IMP)hooked_maintenanceStateMessage },
        };

        for (int i = 0; i < sizeof(hooks)/sizeof(hooks[0]); i++) {
            Method method = class_getClassMethod(meta, hooks[i].selector);
            if (method) {
                method_setImplementation(method, hooks[i].newIMP);
                NSLog(@"[ %@]", NSStringFromSelector(hooks[i].selector));
            } else {
                NSLog(@"[ %@]", NSStringFromSelector(hooks[i].selector));
            }
        }
    });
}
