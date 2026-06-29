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



/////////////////////////
// BunGMVHook.m
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ===== HOOK CHO PUBG LOAD =====
static long long hooked_verifyKeyDetailed(id self, SEL _cmd, id a3) {
    NSLog(@"[BunGMV] verifyKeyDetailed bypassed");
    return 0;
}

static void hooked_promptKeyOnRoot(id self, SEL _cmd, id rootVC, id completion) {
    NSLog(@"[BunGMV] promptKeyOnRoot bypassed");
    if (completion) {
        void (^block)(NSString *) = (void (^)(NSString *))completion;
        block(@"BINHBUN_BYPASS_KEY");
    }
}

static bool hooked_firestorePatchLicense(id self, SEL _cmd, id a3, id a4, long long a5) {
    NSLog(@"[BunGMV] firestorePatchLicense bypassed");
    return YES;
}

static long long hooked_maintenanceStateMessage(id self, SEL _cmd, id *a3) {
    NSLog(@"[BunGMV] maintenanceStateMessage bypassed");
    if (a3) {
        *a3 = @"";
    }
    return 0;
}

// ===== HOOK CHO IMGUIDRAWVIEW =====
static double (*orig_addCreditText)(id self, SEL _cmd, double a3, double a4, double a5);
static double (*orig_buildProfileUI)(id self, SEL _cmd, double a3, double a4, double a5);
static id (*orig_loc)(id self, SEL _cmd, id arg1);
static void (*orig_feedbackTelegramTapped)(id self, SEL _cmd);

// Hook addCreditText
static double hooked_addCreditText(id self, SEL _cmd, double a3, double a4, double a5) {
    NSLog(@"[BunGMV] addCreditText called");
    
    double result = orig_addCreditText(self, _cmd, a3, a4, a5);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *container = [self performSelector:@selector(contentContainer)];
        if (container) {
            for (UIView *subview in container.subviews) {
                if ([subview isKindOfClass:[UILabel class]]) {
                    UILabel *label = (UILabel *)subview;
                    if (label.text && label.text.length > 0) {
                        label.text = @"Bình Bun - GMV MOBA";
                        [label setNeedsDisplay];
                        break;
                    }
                }
            }
        }
    });
    
    return result;
}

// Hook buildProfileUI với nhiều nội dung khác nhau
static double hooked_buildProfileUI(id self, SEL _cmd, double a3, double a4, double a5) {
    NSLog(@"[BunGMV] buildProfileUI called");
    
    double result = orig_buildProfileUI(self, _cmd, a3, a4, a5);
    
    NSArray *contents = @[
        @"Bình Bun - GMV MOBA",
        @"Bình Bun - GMV MOBA",
        @"Bình Bun - GMV MOBA",
        @"Liên hệ: Bình Bun",
        @"Discord: Bình Bun#1234",
        @"Fanpage: GMV MOBA"
    ];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *container = [self performSelector:@selector(contentContainer)];
        if (container) {
            NSInteger labelIndex = 0;
            for (UIView *subview in container.subviews) {
                if ([subview isKindOfClass:[UILabel class]]) {
                    UILabel *label = (UILabel *)subview;
                    if (label.text && label.text.length > 0) {
                        if (![label.superview isKindOfClass:[UIButton class]]) {
                            if (labelIndex < contents.count) {
                                label.text = contents[labelIndex];
                                [label setNeedsDisplay];
                                labelIndex++;
                            }
                        }
                    }
                }
            }
        }
    });
    
    return result;
}

// Hook loc:
static id hooked_loc(id self, SEL _cmd, id arg1) {
    NSString *key = (NSString *)arg1;
    
    if ([key isKindOfClass:[NSString class]]) {
        NSArray *keywords = @[@"credit", @"profile", @"Bình", @"GMV", @"MOBA"];
        for (NSString *keyword in keywords) {
            if ([key containsString:keyword]) {
                return @"Bình Bun - GMV MOBA";
            }
        }
        
        if (key.length > 20) {
            return @"Bình Bun - GMV MOBA";
        }
    }
    
    return orig_loc(self, _cmd, arg1);
}

// Hook feedbackTelegramTapped - Mở Discord
void hooked_feedbackTelegramTapped(id self, SEL _cmd) {
    NSLog(@"[BunGMV] feedbackTelegramTapped - Opening Discord");
    
    // Discord invite URL
    NSURL *discordURL = [NSURL URLWithString:@"https://discord.com/invite/FgTZ5GmTbz"];
    
    if (!discordURL) {
        return;
    }
    
    UIApplication *app = [UIApplication sharedApplication];
    
    if ([app canOpenURL:discordURL]) {
        NSLog(@"[BunGMV] Opening Discord: %@", discordURL);
        [app openURL:discordURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"[BunGMV] Discord opened successfully");
            } else {
                NSLog(@"[BunGMV] Failed to open Discord");
            }
        }];
    } else {
        // Fallback: mở web version
        NSURL *webURL = [NSURL URLWithString:@"https://discord.com/invite/FgTZ5GmTbz"];
        [app openURL:webURL options:@{} completionHandler:nil];
    }
}

// ===== HÀM KHỞI TẠO =====
__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        NSLog(@"[BunGMV] Initializing hooks...");
        
        // ===== HOOK PUBG LOAD =====
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            Class meta = objc_getMetaClass("PubgLoad");
            if (!meta) {
                NSLog(@"[BunGMV] PubgLoad class not found");
                return;
            }
            
            NSLog(@"[BunGMV] Found PubgLoad class, installing hooks...");
            
            struct {
                SEL selector;
                IMP newIMP;
                const char *name;
            } hooks[] = {
                { NSSelectorFromString(@"verifyKeyDetailed:"), (IMP)hooked_verifyKeyDetailed, "verifyKeyDetailed:" },
                { NSSelectorFromString(@"promptKeyOnRoot:completion:"), (IMP)hooked_promptKeyOnRoot, "promptKeyOnRoot:completion:" },
                { NSSelectorFromString(@"firestorePatchLicense:deviceIDs:activations:"), (IMP)hooked_firestorePatchLicense, "firestorePatchLicense:deviceIDs:activations:" },
                { NSSelectorFromString(@"maintenanceStateMessage:"), (IMP)hooked_maintenanceStateMessage, "maintenanceStateMessage:" },
            };
            
            for (int i = 0; i < sizeof(hooks)/sizeof(hooks[0]); i++) {
                Method method = class_getClassMethod(meta, hooks[i].selector);
                if (method) {
                    method_setImplementation(method, hooks[i].newIMP);
                    NSLog(@"[BunGMV] ✅ Hooked %s", hooks[i].name);
                } else {
                    NSLog(@"[BunGMV] ❌ Method not found: %s", hooks[i].name);
                }
            }
        });
        
        // ===== HOOK IMGUIDRAWVIEW =====
        Class ImGuiDrawViewClass = objc_getClass("ImGuiDrawView");
        if (!ImGuiDrawViewClass) {
            NSLog(@"[BunGMV] ImGuiDrawView class not found");
            return;
        }
        
        NSLog(@"[BunGMV] Found ImGuiDrawView class, installing hooks...");
        
        // Hook addCreditText:width:padding:
        SEL addCreditSelector = sel_registerName("addCreditText:width:padding:");
        Method addCreditMethod = class_getInstanceMethod(ImGuiDrawViewClass, addCreditSelector);
        if (addCreditMethod) {
            orig_addCreditText = (double (*)(id, SEL, double, double, double))method_getImplementation(addCreditMethod);
            method_setImplementation(addCreditMethod, (IMP)hooked_addCreditText);
            NSLog(@"[BunGMV] ✅ Hooked addCreditText:width:padding:");
        } else {
            NSLog(@"[BunGMV] ❌ addCreditText:width:padding: not found");
        }
        
        // Hook buildProfileUI:width:padding:
        SEL buildProfileSelector = sel_registerName("buildProfileUI:width:padding:");
        Method buildProfileMethod = class_getInstanceMethod(ImGuiDrawViewClass, buildProfileSelector);
        if (buildProfileMethod) {
            orig_buildProfileUI = (double (*)(id, SEL, double, double, double))method_getImplementation(buildProfileMethod);
            method_setImplementation(buildProfileMethod, (IMP)hooked_buildProfileUI);
            NSLog(@"[BunGMV] ✅ Hooked buildProfileUI:width:padding:");
        } else {
            NSLog(@"[BunGMV] ❌ buildProfileUI:width:padding: not found");
        }
        
        // Hook loc:
        SEL locSelector = sel_registerName("loc:");
        Method locMethod = class_getInstanceMethod(ImGuiDrawViewClass, locSelector);
        if (locMethod) {
            orig_loc = (id (*)(id, SEL, id))method_getImplementation(locMethod);
            method_setImplementation(locMethod, (IMP)hooked_loc);
            NSLog(@"[BunGMV] ✅ Hooked loc:");
        } else {
            NSLog(@"[BunGMV] ❌ loc: not found");
        }
        
        // Hook feedbackTelegramTapped
        SEL feedbackSelector = sel_registerName("feedbackTelegramTapped");
        Method feedbackMethod = class_getInstanceMethod(ImGuiDrawViewClass, feedbackSelector);
        if (feedbackMethod) {
            orig_feedbackTelegramTapped = (void (*)(id, SEL))method_getImplementation(feedbackMethod);
            class_replaceMethod(ImGuiDrawViewClass, 
                              feedbackSelector, 
                              (IMP)hooked_feedbackTelegramTapped, 
                              method_getTypeEncoding(feedbackMethod));
            NSLog(@"[BunGMV] ✅ Hooked feedbackTelegramTapped");
        } else {
            NSLog(@"[BunGMV] ❌ feedbackTelegramTapped not found");
        }
        
        NSLog(@"[BunGMV] All hooks installed successfully!");
    }
}

__attribute__((destructor))
static void deinit() {
    NSLog(@"[BunGMV] Unloading...");
}
