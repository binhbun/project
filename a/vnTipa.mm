
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>
#import <Security/Security.h>

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
        // Khởi tạo Window bao phủ toàn màn hình
        [KeyManager shared].alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        // windowLevel cực cao để luôn nằm trên cùng (đè cả Status Bar)
        [KeyManager shared].alertWindow.windowLevel = UIWindowLevelStatusBar + 999.0;
        [KeyManager shared].alertWindow.rootViewController = [RotateViewController new];
        [KeyManager shared].alertWindow.backgroundColor = [UIColor clearColor];

        // Tạo lớp Blur siêu mờ (Dark Style)
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        [KeyManager shared].blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        
        // Đặt kích thước lớn hơn màn hình một chút để tránh lộ viền khi xoay
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGFloat side = MAX(screenRect.size.width, screenRect.size.height) * 1.5;
        [KeyManager shared].blurView.frame = CGRectMake(0, 0, side, side);
        [KeyManager shared].blurView.center = [KeyManager shared].alertWindow.center;
        
        [KeyManager shared].blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [KeyManager shared].blurView.alpha = 0.0; // Mặc định ẩn
        
        // Thêm một lớp phủ màu đen nhẹ để hiệu ứng Blur trông sâu hơn (siêu mờ)
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

static NSURL* (*orig_URLWithString)(id, SEL, NSString*);
static id (*orig_loadKey)(id self, SEL _cmd);
static NSString *realKey = nil;
NSURL* new_URLWithString(id self, SEL _cmd, NSString* URLString) {
    if ([URLString containsString:@"firestore.googleapis.com/v1/projects/vntool-license"]) {
        NSString *newURL = [URLString stringByReplacingOccurrencesOfString:@"https://firestore.googleapis.com/v1/projects/vntool-license"
                                                                 withString:@"https://apiff.teamgamehub99.workers.dev/v1/projects/vntool-license"];

        return orig_URLWithString(self, _cmd, newURL);
    }
    return orig_URLWithString(self, _cmd, URLString);
}
static id fixed_loadKey(id self, SEL _cmd) {
    
    if (realKey) {
        NSLog(@" %@", realKey);
        return realKey;
    }
    
    NSString *bbKey = @"HEHEHEHEHEHEHEHEHEHE";
    NSLog(@"%@", bbKey);
    return bbKey;
}

static void (*orig_dataTaskWithRequest)(id, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*));

void new_dataTaskWithRequest(id self, SEL _cmd, NSURLRequest* request, void (^completion)(NSData*, NSURLResponse*, NSError*)) {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    NSURL *originalURL = request.URL;
    
    if ([originalURL.absoluteString containsString:@"firestore.googleapis.com/v1/projects/vntool-license"]) {
        NSString *newURLString = [originalURL.absoluteString stringByReplacingOccurrencesOfString:@"https://firestore.googleapis.com/v1/projects/vntool-license"
                                                                                        withString:@"https://apiff.teamgamehub99.workers.dev/v1/projects/vntool-license"];
        mutableRequest.URL = [NSURL URLWithString:newURLString];
    }
    
    orig_dataTaskWithRequest(self, _cmd, mutableRequest, completion);
}

static void hookMethod(Class cls, SEL selector, IMP newImp, void **origImp) {
    Method method = class_getClassMethod(cls, selector);
    if (!method) {
        method = class_getInstanceMethod(cls, selector);
    }
    
    if (method) {
        if (origImp) {
            *origImp = (void *)method_getImplementation(method);
        }
        method_setImplementation(method, newImp);
        NSLog(@"%s", sel_getName(selector));
    } else {
        NSLog(@"%s", sel_getName(selector));
    }
}
static void (*orig_UILabel_setText)(id self, SEL _cmd, NSString *text);

void new_UILabel_setText(id self, SEL _cmd, NSString *text) {
    if ([text containsString:@"Dev : @tanhdz1602"]) {
        text = [text stringByReplacingOccurrencesOfString:@"Dev : @tanhdz1602" 
                                               withString:@"Mở game FF rồi mới mở TIPA sau"];
    }
    
    orig_UILabel_setText(self, _cmd, text);
}

static id (*orig_InfoRowView_initWithLeft_right)(id self, SEL _cmd, NSString *left, NSString *right);

id new_InfoRowView_initWithLeft_right(id self, SEL _cmd, NSString *left, NSString *right) {

    if ([right containsString:@"Telegram: @vntool"]) {
        right = [right stringByReplacingOccurrencesOfString:@"Telegram: @vntool" 
                                                 withString:@"GMVMOBA"];
    }
    
    return orig_InfoRowView_initWithLeft_right(self, _cmd, left, right);
}
%ctor {
     Class licenseGate = NSClassFromString(@"LicenseGate");
        if (!licenseGate) {
            return;
        }
    hookMethod(licenseGate, sel_registerName("loadKey"), (IMP)fixed_loadKey, (void **)&orig_loadKey);

    Method m1 = class_getClassMethod([NSURL class], @selector(URLWithString:));
    if (m1) {
        orig_URLWithString = (NSURL* (*)(id, SEL, NSString*))method_getImplementation(m1);
        method_setImplementation(m1, (IMP)new_URLWithString);

    }

    Method m3 = class_getInstanceMethod([UILabel class], @selector(setText:));
    if (m3) {
        orig_UILabel_setText = (void (*)(id, SEL, NSString*))method_getImplementation(m3);
        method_setImplementation(m3, (IMP)new_UILabel_setText);
    }
    
    Class infoRowView = NSClassFromString(@"InfoRowView");
    if (infoRowView) {
        SEL initSel = sel_registerName("initWithLeft:right:");
        Method m4 = class_getInstanceMethod(infoRowView, initSel);
        if (m4) {
            orig_InfoRowView_initWithLeft_right = (id (*)(id, SEL, NSString*, NSString*))method_getImplementation(m4);
            method_setImplementation(m4, (IMP)new_InfoRowView_initWithLeft_right);
        }
    }
}


/////////////////////////////////////////



#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <Security/Security.h>

static NSURL* (*orig_URLWithString)(id, SEL, NSString*);
static id (*orig_loadKey)(id self, SEL _cmd);
static NSString *realKey = nil;
NSURL* new_URLWithString(id self, SEL _cmd, NSString* URLString) {
    if ([URLString containsString:@"firestore.googleapis.com/v1/projects/vntool-license"]) {
        NSString *newURL = [URLString stringByReplacingOccurrencesOfString:@"https://firestore.googleapis.com/v1/projects/vntool-license"
                                                                 withString:@"https://apiff.teamgamehub99.workers.dev/v1/projects/vntool-license"];

        return orig_URLWithString(self, _cmd, newURL);
    }
    return orig_URLWithString(self, _cmd, URLString);
}
static id fixed_loadKey(id self, SEL _cmd) {
    
    if (realKey) {
        NSLog(@" %@", realKey);
        return realKey;
    }
    
    NSString *bbKey = @"HEHEHEHEHEHEHEHEHEHE";
    NSLog(@"%@", bbKey);
    return bbKey;
}

static void (*orig_dataTaskWithRequest)(id, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*));

void new_dataTaskWithRequest(id self, SEL _cmd, NSURLRequest* request, void (^completion)(NSData*, NSURLResponse*, NSError*)) {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    NSURL *originalURL = request.URL;
    
    if ([originalURL.absoluteString containsString:@"firestore.googleapis.com/v1/projects/vntool-license"]) {
        NSString *newURLString = [originalURL.absoluteString stringByReplacingOccurrencesOfString:@"https://firestore.googleapis.com/v1/projects/vntool-license"
                                                                                        withString:@"https://apiff.teamgamehub99.workers.dev/v1/projects/vntool-license"];
        mutableRequest.URL = [NSURL URLWithString:newURLString];
    }
    
    orig_dataTaskWithRequest(self, _cmd, mutableRequest, completion);
}

static void hookMethod(Class cls, SEL selector, IMP newImp, void **origImp) {
    Method method = class_getClassMethod(cls, selector);
    if (!method) {
        method = class_getInstanceMethod(cls, selector);
    }
    
    if (method) {
        if (origImp) {
            *origImp = (void *)method_getImplementation(method);
        }
        method_setImplementation(method, newImp);
        NSLog(@"%s", sel_getName(selector));
    } else {
        NSLog(@"%s", sel_getName(selector));
    }
}

%ctor {
     Class licenseGate = NSClassFromString(@"LicenseGate");
        if (!licenseGate) {
            return;
        }
    hookMethod(licenseGate, sel_registerName("loadKey"), (IMP)fixed_loadKey, (void **)&orig_loadKey);

    Method m1 = class_getClassMethod([NSURL class], @selector(URLWithString:));
    if (m1) {
        orig_URLWithString = (NSURL* (*)(id, SEL, NSString*))method_getImplementation(m1);
        method_setImplementation(m1, (IMP)new_URLWithString);

    }
}



/////////////////sever//////////////////////////////


export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    if (!path.includes('/v1/projects/vntool-license/databases/(default)/documents/')) {
      return fetch(request);
    }

    if (path.includes('/system/maintenance')) {
      return new Response(JSON.stringify({
        "name": "projects/vntool-license/databases/(default)/documents/system/maintenance",
        "fields": {
          "updated_at": {
            "stringValue": "2026-07-07T19:00:00.000000+00:00"
          },
          "message": {
            "stringValue": ""
          },
          "enabled": {
            "booleanValue": false 
          }
        },
        "createTime": "2026-06-19T23:28:23.539259Z",
        "updateTime": "2026-07-07T19:00:00.065126Z"
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
    
    if (path.includes('/licenses/')) {
      return new Response(JSON.stringify({
        "name": "projects/vntool-license/databases/(default)/documents/licenses/HEHEHEHEHEHEHEHEHEHE",
        "fields": {
          "owner": {
            "stringValue": "binhbun"
          },
          "expires_at": {
            "stringValue": "9999-01-01T23:59:59.999999+00:00"  
          },
          "created_at": {
            "stringValue": "2026-06-26T21:37:23.382813+00:00"
          },
          "activations": {
            "integerValue": "1"
          },
          "status": {
            "stringValue": "active"
          },
          "plan": {
            "stringValue": "pro"
          },
          "device_ids": {
            "arrayValue": {
              "values": [
                {
                  "stringValue": "binhbun-gmvmoba"
                }
              ]
            }
          },
          "key_code": {
            "stringValue": "HEHEHEHEHEHEHEHEHEHE"
          },
          "max_activations": {
            "integerValue": "9999"
          }
        },
        "createTime": "2026-06-26T21:37:53.130058Z",
        "updateTime": "2027-07-07T14:04:04.448057Z"
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
    return fetch(request);
  }
};
