#import <Foundation/Foundation.h>
#import <dlfcn.h>

__attribute__((constructor))
static void load_hidden_dylib() {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    NSString *hiddenPath = [bundlePath stringByAppendingPathComponent:@"PlugIns/80pool.dylib"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:hiddenPath]) {
        void *handle = dlopen([hiddenPath UTF8String], RTLD_NOW);
        if (handle == NULL) {
            NSLog(@"[Loader] : %s", dlerror());
        } else {
            NSLog(@"[Loader] : %@", hiddenPath);
        }
    } else {
        NSLog(@"[Loader]: %@", hiddenPath);
    }
}



//////////////////////



#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <Security/Security.h>

class MenuPatcher {
public:
    static void patch() {
        Class cls = objc_getClass("GBModMenu");
        if (!cls) {
            NSLog(@"[GMVMOBA] Class GBModMenu not found!");
            return;
        }
        
        SEL sel = sel_registerName("buildCard");
        Method method = class_getInstanceMethod(cls, sel);
        
        if (method) {
            IMP originalIMP = method_getImplementation(method);
            
            IMP newIMP = imp_implementationWithBlock(^(id self) {
                ((void (*)(id, SEL))originalIMP)(self, sel);
                
                UILabel *mainLabel = (UILabel *)[self viewWithTag:11];
                if (mainLabel) {
                    [mainLabel setText:@"🔥 GMVMOBA 🔥"];
                    [mainLabel setFont:[UIFont boldSystemFontOfSize:16.0]];
                    [mainLabel setTextColor:[UIColor whiteColor]];
                    NSLog(@"[GMVMOBA] Main title updated");
                }
                UILabel *subLabel = (UILabel *)[self viewWithTag:12];
                if (subLabel) {
                    [subLabel setText:@"💎 8 Ball Premium 💎"];
                    [subLabel setFont:[UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium]];
                    
                    UIColor *goldColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
                    [subLabel setTextColor:goldColor];
                    NSLog(@"[GMVMOBA] Subtitle updated");
                }
            });
            
            method_setImplementation(method, newIMP);
            NSLog(@"[GMVMOBA] Menu patch installed!");
        }
    }
};


class CommunityPatcher {
public:
    static void patch() {
        Class cls = objc_getClass("GBModMenu");
        if (!cls) {
            NSLog(@"[GMVMOBA] Class GBModMenu not found for community!");
            return;
        }
        
        SEL sel = sel_registerName("buildRows");
        Method method = class_getInstanceMethod(cls, sel);
        
        if (method) {
            IMP originalIMP = method_getImplementation(method);
            
            IMP newIMP = imp_implementationWithBlock(^(id self) {
                ((void (*)(id, SEL))originalIMP)(self, sel);
                
                UILabel *titleLabel = (UILabel *)[self viewWithTag:330];
                if (titleLabel) {
                    [titleLabel setText:@"🌐 Community"];
                    [titleLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
                    [titleLabel setTextColor:[UIColor whiteColor]];
                    NSLog(@"[GMVMOBA] Community title updated");
                }
                
                NSArray *tags = @[@401, @402, @403];
                UIColor *discordColor = [UIColor colorWithRed:0.58 green:0.71 blue:0.98 alpha:1.0];
                UIColor *discordBgColor = [UIColor colorWithRed:0.23 green:0.31 blue:0.42 alpha:1.0];
                
                for (NSNumber *tag in tags) {
                    UIButton *btn = (UIButton *)[self viewWithTag:[tag integerValue]];
                    if (btn) {
                        // Đổi tên
                        [btn setTitle:@"Discord" forState:UIControlStateNormal];
                        
                        // Đổi màu
                        [btn setTitleColor:discordColor forState:UIControlStateNormal];
                        [btn setBackgroundColor:discordBgColor];
                        
                        // Font
                        [btn.titleLabel setFont:[UIFont boldSystemFontOfSize:11.0]];
                        
                        // Xóa action cũ và gán action mới
                        [btn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                        [btn addTarget:self 
                                action:@selector(openDiscord:) 
                      forControlEvents:UIControlEventTouchUpInside];
                        
                        NSLog(@"[GMVMOBA] Button %@ updated to Discord", tag);
                    }
                }
                
               UIButton *buyKeyBtn = (UIButton *)[self viewWithTag:404];
                if (buyKeyBtn) {
                    [buyKeyBtn setTitle:@"🔑 Buy Key VIP Now" 
                               forState:UIControlStateNormal];
                    
                    [buyKeyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    UIColor *vipColor = [UIColor colorWithRed:0.95 green:0.35 blue:0.0 alpha:1.0]; 
                    [buyKeyBtn setBackgroundColor:vipColor];
                    
                    CALayer *layer = buyKeyBtn.layer;
                    layer.cornerRadius = 8.0;
                    layer.masksToBounds = YES;
                    
                    [buyKeyBtn.titleLabel setFont:[UIFont systemFontOfSize:12.0 weight:UIFontWeightBold]];
                    
                    [buyKeyBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                    [buyKeyBtn addTarget:self 
                                  action:@selector(openBuyKey:) 
                        forControlEvents:UIControlEventTouchUpInside];
                    
                    NSLog(@"[GMVMOBA] Buy Key button updated to: 🔑 Buy Key VIP Now");
                }
            });
            
            method_setImplementation(method, newIMP);
            NSLog(@"[GMVMOBA] Community patch installed!");
        }
    }
    
    static void openDiscord(id self, SEL cmd) {
        NSString *discordLink = @"https://discord.gg/FgTZ5GmTbz";
        NSURL *url = [NSURL URLWithString:discordLink];
        
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url 
                                               options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} 
                                     completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"[GMVMOBA] Opened Discord: %@", discordLink);
                } else {
                    NSLog(@"[GMVMOBA] Failed to open Discord");
                }
            }];
        } else {
            NSLog(@"[GMVMOBA] Cannot open URL: %@", discordLink);
        }
    }

    static void openBuyKey(id self, SEL cmd) {
        NSString *buyLink = @"https://key.gmvmoba.com";
        NSURL *url = [NSURL URLWithString:buyLink];
        
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url 
                                               options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} 
                                     completionHandler:^(BOOL success) {
                if (success) {
                    NSLog(@"[GMVMOBA] Opened Buy Key: %@", buyLink);
                } else {
                    NSLog(@"[GMVMOBA] Failed to open Buy Key");
                }
            }];
        } else {
            NSLog(@"[GMVMOBA] Cannot open URL: %@", buyLink);
        }
    }
};

static void addDiscordMethod() {
    Class cls = objc_getClass("GBModMenu");
    if (!cls) return;
    
    SEL selector = sel_registerName("openDiscord:");
    if (!class_getInstanceMethod(cls, selector)) {

        class_addMethod(cls, 
                       selector, 
                       (IMP)CommunityPatcher::openDiscord, 
                       "v@:@");
        NSLog(@"[GMVMOBA] Added openDiscord: method to GBModMenu");
    }
}


__attribute__((constructor))
static void init() {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    NSString *hiddenPath = [bundlePath stringByAppendingPathComponent:@"PlugIns/80pool.dylib"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:hiddenPath]) {
        void *handle = dlopen([hiddenPath UTF8String], RTLD_NOW);
        if (handle == NULL) {
            NSLog(@"[Loader] : %s", dlerror());
        } else {
            NSLog(@"[Loader] : %@", hiddenPath);
        }
    } else {
        NSLog(@"[Loader]: %@", hiddenPath);
    }

    NSLog(@"[GMVMOBA] Dylib loading...");
    
    addDiscordMethod();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), 
                   dispatch_get_main_queue(), ^{
        MenuPatcher::patch();
        CommunityPatcher::patch();
        NSLog(@"[GMVMOBA] All patches applied successfully!");
    });
}
