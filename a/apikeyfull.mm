#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <stdint.h>
#include <string.h>
#import <Security/Security.h>

#define TARGET_CLASS "APIClient"
#define TARGET_CLASS_A "APIKEY"

@interface Binhbun : NSObject
@end

@implementation Binhbun

+ (void)paid:(id)completion {
    if (completion) {
        void (^block)(void) = completion;
        block();
    }
}

- (BOOL)hasShownSuccessAlert {
    return YES;
}

- (void)checkKey { 
}

- (void)checkAndRequestUDIDIfNeeded {
}

- (void)checkUDIDStatusFromServer:(id)a3 {
}

- (id)savedUDID {
    return @"Binhbun-BYPASS-UDID-9999";
}

- (BOOL)hasUDID {
    return YES;
}

@end

static __attribute__((constructor)) void binhbun_gmvmoba_big() {
     dispatch_async(dispatch_get_main_queue(), ^{
        
        Class targetCls = objc_getClass(TARGET_CLASS_A);
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
            
        } else {
        }
    });
}

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
}

- (void)hideUI:(BOOL)a3 { }
- (void)strictMode:(BOOL)a3 { }
- (void)silentMode:(BOOL)a3 { }

- (id)getPackageDataWithKey:(id)key {
    return [NSNumber numberWithBool:YES];
}

- (id)getKey { return @"binhbun       "; }
- (id)getExpiryDate { return @"9999-12-31"; }
- (id)getUDID { return @"gmvmobabinhbun"; }
- (id)getLoginIP { return @"127.0.0.1"; }
- (id)getPackageName { return @"com.gmvmoba.binhbun"; }

- (id)getDeviceModel {
    return [[UIDevice currentDevice] model];
}

@end


static __attribute__((constructor)) void binhbun_gmvmoba() {
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
            
        }
    });
}

#define API_CHECK_UDID    @"https://key.gmvmoba.com/udid/api/done"
#define BASE_URL          @"https://key.gmvmoba.com/connect" 
#define PROFILE_URL       @"https://key.gmvmoba.com/udid/profile"
#define ZALO_INFO         @"૮₍´˶• . • ⑅ ₎ა"
#define GAME_NAME         @"PUBG" 
#define GET_KEY_URL       @"https://key.gmvmoba.com/gmvmoba/getkey"
#define API_DYLIB_SERVER  @"https://key.gmvmoba.com/api/check-bundle/gmvmoba"

static NSString *const kSavedUDID = @"GMV_UDID_DEVICE";
static UIAlertController *_currentUpdateAlert = nil; 

static NSString * GetCurrentBID() {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.gmv.unknown";
    NSMutableString *ms = [bid mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)ms, NULL, kCFStringTransformStripDiacritics, NO);
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789."];
    return [[ms componentsSeparatedByCharactersInSet:[allowed invertedSet]] componentsJoinedByString:@""];
}
static NSString * PrivateAccount() { return [NSString stringWithFormat:@"GMV_PV_%@", GetCurrentBID()]; }
static NSString * TrackingAccount(NSString *userKey) { return [NSString stringWithFormat:@"GMV_TRK_%@", userKey]; }

@interface RotateViewController : UIViewController 
@end

@implementation RotateViewController

- (BOOL)shouldAutorotate { 
    return YES; 
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations { 
    return UIInterfaceOrientationMaskLandscape; 
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.view.window) {
        self.view.frame = self.view.window.bounds;
    }
}
@end

@interface KeyManager : NSObject
@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, strong) UIVisualEffectView *blurView; 
@property (nonatomic, assign) BOOL isChecking; 
@property (nonatomic, assign) BOOL isDialogVisible; 
@property (nonatomic, assign) BOOL lastRequireKeyState;
@property (nonatomic, strong) NSTimer *updateCheckTimer; 
+ (instancetype)shared;
@end

@implementation KeyManager

+ (instancetype)shared {
    static KeyManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ 
        shared = [[KeyManager alloc] init]; 
        shared.lastRequireKeyState = YES;
    });
    return shared;
}

+ (NSMutableArray *)getSavedBIDsForKey:(NSString *)key {
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: TrackingAccount(key), (__bridge id)kSecReturnData: @YES};
    CFTypeRef dataRef = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef) == errSecSuccess) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return [[str componentsSeparatedByString:@","] mutableCopy];
    }
    return [NSMutableArray array];
}

+ (void)saveBIDs:(NSArray *)bids forKey:(NSString *)key {
    NSString *str = [bids componentsJoinedByString:@","];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: TrackingAccount(key)};
    SecItemDelete((__bridge CFDictionaryRef)query);
    NSMutableDictionary *dict = [query mutableCopy];
    [dict setObject:data forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
}

+ (void)resetKeychainBIDList:(NSString *)key {
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: TrackingAccount(key)};
    SecItemDelete((__bridge CFDictionaryRef)query);
}

+ (void)verifyKey:(NSString *)userKey {
    if (!userKey || userKey.length < 2) {
        [self showToast:@"⛔ Vui lòng nhập Key"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [KeyManager shared].isDialogVisible = NO; [self showMainAlert:nil]; });
        return;
    }
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID] ?: @"UNKNOWN";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:BASE_URL]];
    req.HTTPMethod = @"POST";
    NSString *params = [NSString stringWithFormat:@"game=%@&user_key=%@&serial=%@", GAME_NAME, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!data) { 
                [self showToast:@"⛔ Lỗi kết nối Server!"]; 
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [KeyManager shared].isDialogVisible = NO;
                        [self showMainAlert:userKey];
                    });
                return; 
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *serverReason = json[@"reason"] ?: @"Key không hợp lệ hoặc đã hết hạn";
            
            if ([json[@"status"] boolValue]) {
                int deviceUsed = [json[@"data"][@"device_used"] intValue]; 
                int maxSlot = [json[@"data"][@"device"] intValue];        
                NSString *currentBID = GetCurrentBID();
                
                NSMutableArray *savedBIDs = [self getSavedBIDsForKey:userKey];
                
                if (deviceUsed == 0 && savedBIDs.count > 0) {
                    [self resetKeychainBIDList:userKey];
                    [savedBIDs removeAllObjects];
                }
                
                if ([savedBIDs containsObject:currentBID]) {
                    [self processSuccess:userKey json:json];
                } else if (savedBIDs.count < maxSlot) {
                    [savedBIDs addObject:currentBID];
                    [self saveBIDs:savedBIDs forKey:userKey];
                    [self processSuccess:userKey json:json];
                } else {
                    [self showToast:@"⛔ Hết slot Game cho Key này!\nKey Đã dùng cho Game khác rồi!"];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [KeyManager shared].isDialogVisible = NO;
                        [self showMainAlert:userKey];
                    });
                }
            } else {
                [self showToast:[NSString stringWithFormat:@"⛔ %@", serverReason]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
                    [KeyManager shared].isDialogVisible = NO;
                    [self showMainAlert:userKey]; 
                });
            }
        });
    }] resume];
}

+ (void)processSuccess:(NSString *)userKey json:(NSDictionary *)json {
    [self savePermanentKey:userKey];
    [self showToast:[NSString stringWithFormat:@"✅ Thành Công!\nHạn: %@", json[@"data"][@"EXP"]]];

    [self startUpdatePolling];
    static BOOL isMenuStarted = NO;
    if (!isMenuStarted) {
        // [YourMenuClass startMenu]; 
        isMenuStarted = YES;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self hideAllUI];
    });
}

+ (void)silentVerifyKey:(NSString *)userKey {
    if (!userKey || userKey.length < 2) return;

    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID] ?: @"UNKNOWN";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:BASE_URL]];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 10.0;
    
    NSString *params = [NSString stringWithFormat:@"game=%@&user_key=%@&serial=%@", GAME_NAME, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL status = [json[@"status"] boolValue];
            
            if (!status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([KeyManager shared].updateCheckTimer) {
                        [[KeyManager shared].updateCheckTimer invalidate];
                        [KeyManager shared].updateCheckTimer = nil;
                    }
                    
                    NSString *serverReason = json[@"reason"] ?: @"Key không hợp lệ hoặc đã hết hạn";
                    [self showToast:[NSString stringWithFormat:@"⛔ %@", serverReason]];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
                        
                        [self prepareWindow]; 
                        [KeyManager shared].alertWindow.hidden = NO;
                        [[KeyManager shared].alertWindow makeKeyAndVisible];
                        [KeyManager shared].isDialogVisible = NO; 
                        [self showMainAlert:userKey]; 
                    });
                });
            }
        }
    }] resume];
}
+ (void)hideAllUI {
    [KeyManager shared].isDialogVisible = NO;
    [self setBlurActive:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [KeyManager shared].alertWindow.hidden = YES;
    });
}


+ (void)showMainAlert:(NSString *)initialKey {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KeyManager shared].isDialogVisible) return;
        
        [self prepareWindow];
        [KeyManager shared].alertWindow.hidden = NO;
        [KeyManager shared].alertWindow.userInteractionEnabled = YES;
        [self setBlurActive:YES];
        [KeyManager shared].isDialogVisible = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"「 🔥 GMV MOBA 🔥 」" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        NSString *msg = ZALO_INFO;
        NSMutableAttributedString *attrMsg = [[NSMutableAttributedString alloc] initWithString:msg];
        [attrMsg addAttribute:NSForegroundColorAttributeName value:[UIColor systemGreenColor] range:NSMakeRange(0, msg.length)];
        [alert setValue:attrMsg forKey:@"attributedMessage"];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Nhập key vào đây...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = initialKey ?: [self getPermanentKey]; 
            
            UIButton *pasteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [pasteBtn setTitle:@"Dán" forState:UIControlStateNormal];
            pasteBtn.frame = CGRectMake(0, 0, 45, 30);
            [pasteBtn addTarget:self action:@selector(handlePaste:) forControlEvents:UIControlEventTouchUpInside];
            textField.rightView = pasteBtn;
            textField.rightViewMode = UITextFieldViewModeAlways;
            objc_setAssociatedObject(pasteBtn, "targetField", textField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Get Key" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:GET_KEY_URL] options:@{} completionHandler:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [KeyManager shared].isDialogVisible = NO; 
                [self showMainAlert:nil];
            });
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Check Key" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { 
            [KeyManager shared].isDialogVisible = NO;
            [self verifyKey:alert.textFields.firstObject.text]; 
        }]];
        
        [[KeyManager shared].alertWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}



+ (void)prepareWindow {
    if (![KeyManager shared].alertWindow) {
        [KeyManager shared].alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        [KeyManager shared].alertWindow.windowLevel = UIWindowLevelStatusBar + 999.0;
        [KeyManager shared].alertWindow.rootViewController = [RotateViewController new];
        [KeyManager shared].alertWindow.backgroundColor = [UIColor clearColor];

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        [KeyManager shared].blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGFloat side = MAX(screenRect.size.width, screenRect.size.height) * 1.5;
        [KeyManager shared].blurView.frame = CGRectMake(0, 0, side, side);
        [KeyManager shared].blurView.center = [KeyManager shared].alertWindow.center;
        
        [KeyManager shared].blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [KeyManager shared].blurView.alpha = 0.0;
        UIView *overlay = [[UIView alloc] initWithFrame:[KeyManager shared].blurView.bounds];
        overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [[KeyManager shared].blurView.contentView addSubview:overlay];

        [[KeyManager shared].alertWindow.rootViewController.view addSubview:[KeyManager shared].blurView];

        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    [KeyManager shared].alertWindow.windowScene = scene; break;
                }
            }
        }
    }
}

+ (void)savePermanentKey:(NSString *)key { if (!key) return; NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding]; NSDictionary *pQ = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: PrivateAccount()}; SecItemDelete((__bridge CFDictionaryRef)pQ); NSMutableDictionary *p = [pQ mutableCopy]; [p setObject:keyData forKey:(__bridge id)kSecValueData]; SecItemAdd((__bridge CFDictionaryRef)p, NULL); }
+ (NSString *)getPermanentKey { NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: PrivateAccount(), (__bridge id)kSecReturnData: @YES, (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne}; CFTypeRef dataRef = NULL; if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef) == errSecSuccess) { NSData *data = (__bridge_transfer NSData *)dataRef; return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]; } return nil; }
+ (void)showToast:(NSString *)message { dispatch_async(dispatch_get_main_queue(), ^{ [self prepareWindow]; [KeyManager shared].alertWindow.hidden = NO; UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert]; [[KeyManager shared].alertWindow.rootViewController presentViewController:toast animated:YES completion:nil]; dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [toast dismissViewControllerAnimated:YES completion:nil]; }); }); }
+ (void)setBlurActive:(BOOL)active { [UIView animateWithDuration:0.3 animations:^{ [KeyManager shared].blurView.alpha = active ? 1.0 : 0.0; }]; }
+ (void)handlePaste:(UIButton *)sender { UITextField *t = (UITextField *)objc_getAssociatedObject(sender, "targetField"); if (t) t.text = [UIPasteboard generalPasteboard].string; }

+ (void)checkUpdateFirst {
     if ([KeyManager shared].isChecking) return;
    [KeyManager shared].isChecking = YES;
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0.0";
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID] ?: @"UNKNOWN";
    NSString *rawBID = GetCurrentBID();
    NSString *encodedBID = [rawBID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlStr = [NSString stringWithFormat:@"%@?bid=%@&name=%@&udid=%@&ver=%@", API_DYLIB_SERVER, encodedBID, [GAME_NAME stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], udid, version];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlStr] completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KeyManager shared].isChecking = NO;
            if (data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                BOOL forceUpdate = [json[@"force_update"] boolValue];
                BOOL requireKey = [json[@"require_key"] ?: @(YES) boolValue];

                if (forceUpdate) {
                    if (!_currentUpdateAlert) {
                        [[KeyManager shared].alertWindow.rootViewController dismissViewControllerAnimated:NO completion:nil];
                        [self showForceUpdateAlert:json[@"update_link"] message:json[@"update_msg"]];
                    }
                    return;
                } else {
                    if (_currentUpdateAlert) {
                        [_currentUpdateAlert dismissViewControllerAnimated:YES completion:nil];
                        _currentUpdateAlert = nil;
                        [self hideAllUI];
                    }
                }

                if (!requireKey) {
                    [KeyManager shared].lastRequireKeyState = NO;
                    [self hideAllUI];
                    return;
                }

                [KeyManager shared].lastRequireKeyState = YES;
                if (![KeyManager shared].isDialogVisible) {
                    [self checkDeviceAndStart];
                }
            }
        });
    }] resume];
}

+ (void)verifyKeyForPolling:(NSString *)userKey {
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID] ?: @"UNKNOWN";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:BASE_URL]];
    req.HTTPMethod = @"POST";
    NSString *params = [NSString stringWithFormat:@"game=%@&user_key=%@&serial=%@", GAME_NAME, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (![json[@"status"] boolValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{ [self showMainAlert:userKey]; });
            }
        }
    }] resume];
}

+ (void)showForceUpdateAlert:(NSString *)link message:(NSString *)msg {
    [self prepareWindow];
    [KeyManager shared].alertWindow.hidden = NO; [self setBlurActive:YES];
    _currentUpdateAlert = [UIAlertController alertControllerWithTitle:@"🚀 Bảo Trì 🚀" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [_currentUpdateAlert addAction:[UIAlertAction actionWithTitle:@"Cập Nhật" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link] options:@{} completionHandler:^(BOOL success) {
            exit(0);
        }];
    }]];
    [[KeyManager shared].alertWindow.rootViewController presentViewController:_currentUpdateAlert animated:YES completion:nil];
}

+ (void)checkDeviceAndStart {
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:API_CHECK_UDID] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json[@"status"] boolValue] && json[@"udid"]) {
                    [[NSUserDefaults standardUserDefaults] setObject:json[@"udid"] forKey:kSavedUDID];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSString *storedKey = [self getPermanentKey];
                    if (storedKey) [self verifyKey:storedKey]; else [self showMainAlert:nil];
                    return;
                }
            }
            [self showGetUDIDAlert];
        });
    }] resume];
}

+ (void)showGetUDIDAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KeyManager shared].isDialogVisible) return;
        [self prepareWindow];
        [KeyManager shared].alertWindow.hidden = NO;
        [self setBlurActive:YES];
        [KeyManager shared].isDialogVisible = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"XÁC MINH UDID" 
                                                                       message:@"Vui lòng 'Click Lấy UDID' để cài đặt hồ sơ xác minh thiết bị." 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionGet = [UIAlertAction actionWithTitle:@"Click Lấy UDID (Safari)" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PROFILE_URL] options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        UIAlertController *waitingAlert = [UIAlertController alertControllerWithTitle:@"♻️ ĐANG CHỜ XÁC MINH" 
                                                                                              message:@"Đang chờ cài đặt DNS Profile UDID và xác minh trong Cài đặt.\n\nNếu đã cài và xác minh thành công, hãy nhấn OK để thoát Game, sau đó mở lại để cập nhật." 
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                        
                        [waitingAlert addAction:[UIAlertAction actionWithTitle:@"OK Luôn" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self hideAllUI];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                exit(0);
                            });
                        }]];
                        
                        [[KeyManager shared].alertWindow.rootViewController presentViewController:waitingAlert animated:YES completion:nil];
                    });
                }
            }];
        }];
        
        [alert addAction:actionGet];
        [[KeyManager shared].alertWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)handleTimerCheck {
    NSString *storedKey = [self getPermanentKey];
    
    if (storedKey && storedKey.length > 1) {
        [self silentVerifyKey:storedKey];
    } else {
        if ([KeyManager shared].updateCheckTimer) {
            [[KeyManager shared].updateCheckTimer invalidate];
            [KeyManager shared].updateCheckTimer = nil;
        }
    }
}

+ (void)startUpdatePolling {
    if ([KeyManager shared].updateCheckTimer && [[KeyManager shared].updateCheckTimer isValid]) {
        return;
    }
    
    [KeyManager shared].updateCheckTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 
                                                                          target:self 
                                                                        selector:@selector(handleTimerCheck) 
                                                                        userInfo:nil 
                                                                         repeats:YES];
}

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self checkUpdateFirst]; 
        });
    });
}
@end
#define SELF_NAME_FRAGMENT "SDKUnity3D.dylib"

static uint32_t find_self_index(void)
{
    uint32_t count = _dyld_image_count();
    if (!count)
        return (uint32_t)-1;

    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, SELF_NAME_FRAGMENT))
            return i;
    }
    return (uint32_t)-1;
}

static uint32_t adjusted_index(uint32_t caller_index)
{
    uint32_t self = find_self_index();
    if (self != (uint32_t)-1 && caller_index >= self)
        return caller_index + 1;
    return caller_index;
}

extern "C" __attribute__((visibility("default")))
uint32_t GMV_image_count(void)
{
    uint32_t real_count = _dyld_image_count();
    bool self_present   = (find_self_index() != (uint32_t)-1);
    return real_count - (self_present ? 1u : 0u);
}

extern "C" __attribute__((visibility("default")))
const struct mach_header *GMV_get_image_header(uint32_t index)
{
    return _dyld_get_image_header(adjusted_index(index));
}

extern "C" __attribute__((visibility("default")))
const char *GMV_get_image_name(uint32_t index)
{
    return _dyld_get_image_name(adjusted_index(index));
}

struct dyld_interpose_tuple {
    const void *replacement;
    const void *replacee;
};

#define DYLD_INTERPOSE(_replacement, _replacee) \
    __attribute__((used)) static struct dyld_interpose_tuple \
    _interpose_##_replacee \
    __attribute__((section("__DATA,__interpose"))) = { \
        (const void *)(&_replacement), (const void *)(&_replacee) \
}

DYLD_INTERPOSE(GMV_image_count,      _dyld_image_count);
DYLD_INTERPOSE(GMV_get_image_header, _dyld_get_image_header);
DYLD_INTERPOSE(GMV_get_image_name,   _dyld_get_image_name);


static NSString *verifiedBundleId = nil;
static NSMutableDictionary *keyCache = nil;

static NSString* getAesKeyFromServer(NSString *bundleId) {
    NSString *urlString = @"https://calm-unit-61cc.teamgamehub99.workers.dev/api/v1/get_key";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *payload = @{@"bundle_id": bundleId};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    request.HTTPBody = jsonData;
    
    __block NSString *aesKey = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request 
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json[@"success"] boolValue]) {
                aesKey = json[@"aes_key"];
                verifiedBundleId = bundleId;
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return aesKey ?: @"0000c74c23bd93c4016a2a0be4213f63";
}

static NSString* getCachedKey(NSString *bundleId) {
    if (!keyCache) {
        keyCache = [NSMutableDictionary dictionary];
    }
    
    NSString *cachedKey = keyCache[bundleId];
    if (cachedKey) {
        return cachedKey;
    }
    
    NSString *newKey = getAesKeyFromServer(bundleId);
    if (newKey) {
        keyCache[bundleId] = newKey;
    }
    return newKey;
}

static NSString* getDeviceFingerprint(void) {
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    
    NSString *combined = [NSString stringWithFormat:@"%@|%@|%@", idfv, model, systemVersion];
    
    NSData *data = [combined dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    
    NSMutableString *fingerprint = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [fingerprint appendFormat:@"%02x", hash[i]];
    }
    
    return [fingerprint substringToIndex:32];
}

typedef void (*SetHTTPBody_t)(id, SEL, NSData *);
static SetHTTPBody_t orig_setHTTPBody = NULL;

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

typedef id (*InitWithURL_t)(id, SEL, id);
static InitWithURL_t orig_initWithURL = NULL;

static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);

BOOL replaced_verifySignature_withData_usingPublicKeyString(Class self, SEL _cmd, NSData *signature, NSData *data, NSString *publicKeyString) {
    return YES;
}

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
        
        return [mutableRequest copy];
    }
    
    return request;
}

NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        if ([urlString containsString:@"api.authtool.app"]) {
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.authtool.app"
                                                                          withString:@"calm-unit-61cc.teamgamehub99.workers.dev"];
            NSLog(@"[Bypass] Redirecting: %@ -> %@", urlString, newUrlString);
            id newSelf = orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
            
            objc_setAssociatedObject(newSelf, "needsBundleId", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return newSelf;
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

void hooked_setHTTPBody(id self, SEL _cmd, NSData *body) {
    NSNumber *needsInject = objc_getAssociatedObject(self, "needsBundleId");
    
    if ([needsInject boolValue]) {
        NSMutableDictionary *bodyDict = nil;
        if (body) {
            bodyDict = [[NSJSONSerialization JSONObjectWithData:body
                                                       options:NSJSONReadingMutableContainers
                                                         error:nil] mutableCopy];
        }
        if (!bodyDict) {
            bodyDict = [NSMutableDictionary dictionary];
        }
        
        NSString *bundleIdToUse = verifiedBundleId ?: [[NSBundle mainBundle] bundleIdentifier];
        
        bodyDict[@"bundle_id"] = bundleIdToUse;
        
        if (!bodyDict[@"device_fp"]) {
            NSString *deviceFP = getDeviceFingerprint();
            if (deviceFP) bodyDict[@"device_fp"] = deviceFP;
        }
        
        NSData *newBody = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:nil];
        orig_setHTTPBody(self, _cmd, newBody ?: body);
    } else {
        orig_setHTTPBody(self, _cmd, body);
    }
}

id replaced_JSONObjectWithData(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error) {
    if (!data) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!jsonStr) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSMutableString *mutableJson = [jsonStr mutableCopy];
    BOOL isModified = NO;

    if ([mutableJson containsString:@"\"clientIdMode\":\"UDID\""]) {
        [mutableJson replaceOccurrencesOfString:@"\"clientIdMode\":\"UDID\""
                                     withString:@"\"clientIdMode\":\"IDFA\""
                                        options:0
                                          range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([mutableJson containsString:@"\"isRealTimeEventEnable\":true"]) {
        [mutableJson replaceOccurrencesOfString:@"\"isRealTimeEventEnable\":true"
                                     withString:@"\"isRealTimeEventEnable\":false"
                                        options:0
                                          range:NSMakeRange(0, mutableJson.length)];
        isModified = YES;
    }

    if ([jsonStr containsString:@"requireAuth"]) {
        NSRegularExpression *regexAuth = [NSRegularExpression regularExpressionWithPattern:@"\"requireAuth\"\\s*:\\s*false"
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
        [regexAuth replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:@"\"requireAuth\":true"];
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
        NSLog(@"[AppLoggerBypass] Đã đồng bộ unix time: %@", liveUnixStr);
    }

    if ([jsonStr containsString:@"expiredAt"]) {
        NSRegularExpression *regexDate = [NSRegularExpression regularExpressionWithPattern:@"\"expiredAt\"\\s*:\\s*\"[^\"]+\""
                                                                                   options:0
                                                                                     error:nil];
        [regexDate replaceMatchesInString:mutableJson
                                  options:0
                                    range:NSMakeRange(0, mutableJson.length)
                             withTemplate:@"\"expiredAt\":\"9999-01-01T06:41:57.000Z\""];
        isModified = YES;
    }

    if (isModified) {
        NSData *modifiedData = [mutableJson dataUsingEncoding:NSUTF8StringEncoding];
        return orig_JSONObjectWithData(self, _cmd, modifiedData, opt, error);
    }

    return orig_JSONObjectWithData(self, _cmd, data, opt, error);
}

__attribute__((constructor)) static void binhbun_gmvmoba_ap() {
    @autoreleasepool {
        
        NSString *currentBundleId = [[NSBundle mainBundle] bundleIdentifier];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *aesKey = getCachedKey(currentBundleId);
            NSLog(@"%@", aesKey);
        });

        Class netToolClass = NSClassFromString(@"NetTool");
        if (netToolClass) {
            SEL verifySelector = NSSelectorFromString(@"verifySignature:withData:usingPublicKeyString:");
            Method verifyMethod = class_getClassMethod(netToolClass, verifySelector);
            if (verifyMethod) {
                method_setImplementation(verifyMethod, (IMP)replaced_verifySignature_withData_usingPublicKeyString);
                NSLog(@"[AppLoggerBypass] -> Hook NetTool verifySignature thành công.");
            }
        }

        Class sessionClass = NSClassFromString(@"NSURLSession");
        if (sessionClass) {
            SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
            Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
            if (targetMethod) {
                orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
                method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);

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

        Class mutableRequestClass = NSClassFromString(@"NSMutableURLRequest");
        if (mutableRequestClass) {
            Method m = class_getInstanceMethod(mutableRequestClass, @selector(initWithURL:));
            if (m) {
                orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
                method_setImplementation(m, (IMP)hooked_initWithURL);
            }
        }

        Class mutableRequestClass2 = NSClassFromString(@"NSMutableURLRequest");
        if (mutableRequestClass2) {
            SEL setBodySelector = @selector(setHTTPBody:);
            Method setBodyMethod = class_getInstanceMethod(mutableRequestClass2, setBodySelector);
            if (setBodyMethod) {
                orig_setHTTPBody = (SetHTTPBody_t)method_getImplementation(setBodyMethod);
                method_setImplementation(setBodyMethod, (IMP)hooked_setHTTPBody);
            }
        }

    }
}
