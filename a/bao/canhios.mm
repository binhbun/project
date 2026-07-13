#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
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
static UIVisualEffectView *_currentBlurView = nil;

static NSString * GetCurrentBID() {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.gmv.unknown";
    NSMutableString *ms = [bid mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)ms, NULL, kCFStringTransformStripDiacritics, NO);
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789."];
    return [[ms componentsSeparatedByCharactersInSet:[allowed invertedSet]] componentsJoinedByString:@""];
}
static NSString * PrivateAccount() { return [NSString stringWithFormat:@"GMV_PV_%@", GetCurrentBID()]; }
static NSString * TrackingAccount(NSString *userKey) { return [NSString stringWithFormat:@"GMV_TRK_%@", userKey]; }

@interface KeyManager : NSObject
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

// MARK: - Helper Methods
+ (UIWindow *)getKeyWindow {
    UIWindow *keyWindow = nil;
    
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    }
    
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    if (!keyWindow) {
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.windows.count > 0) {
                    keyWindow = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
        }
    }
    
    return keyWindow;
}

+ (UIViewController *)getTopViewController {
    UIViewController *topVC = [self getKeyWindow].rootViewController;
    
    if (!topVC) return nil;
    
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    if ([topVC isKindOfClass:[UINavigationController class]]) {
        topVC = [(UINavigationController *)topVC visibleViewController];
    }
    
    if ([topVC isKindOfClass:[UITabBarController class]]) {
        topVC = [(UITabBarController *)topVC selectedViewController];
    }
    
    return topVC;
}

+ (void)showBlurBackground:(BOOL)show onView:(UIView *)view {
    if (show) {
        if (!_currentBlurView) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            _currentBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            _currentBlurView.frame = view.bounds;
            _currentBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            UIView *overlay = [[UIView alloc] initWithFrame:_currentBlurView.bounds];
            overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
            overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_currentBlurView.contentView addSubview:overlay];
        }
        _currentBlurView.frame = view.bounds;
        _currentBlurView.alpha = 0;
        [view addSubview:_currentBlurView];
        
        [UIView animateWithDuration:0.3 animations:^{
            _currentBlurView.alpha = 1.0;
        }];
    } else {
        if (_currentBlurView) {
            [UIView animateWithDuration:0.3 animations:^{
                _currentBlurView.alpha = 0;
            } completion:^(BOOL finished) {
                [_currentBlurView removeFromSuperview];
                _currentBlurView = nil;
            }];
        }
    }
}

// MARK: - Keychain Methods
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

+ (void)savePermanentKey:(NSString *)key {
    if (!key) return;
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *pQ = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: PrivateAccount()};
    SecItemDelete((__bridge CFDictionaryRef)pQ);
    NSMutableDictionary *p = [pQ mutableCopy];
    [p setObject:keyData forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)p, NULL);
}

+ (NSString *)getPermanentKey {
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: PrivateAccount(), (__bridge id)kSecReturnData: @YES, (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne};
    CFTypeRef dataRef = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef) == errSecSuccess) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

// MARK: - UI Methods
+ (void)showMainAlert:(NSString *)initialKey {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KeyManager shared].isDialogVisible) return;
        
        UIViewController *topVC = [self getTopViewController];
        if (!topVC) {
            // Thử lại sau 0.5s nếu chưa có view controller
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self showMainAlert:initialKey];
            });
            return;
        }
        
        [KeyManager shared].isDialogVisible = YES;
        [self showBlurBackground:YES onView:topVC.view];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"「 🔥 GMV MOBA 🔥 」" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        NSString *msg = ZALO_INFO;
        NSMutableAttributedString *attrMsg = [[NSMutableAttributedString alloc] initWithString:msg];
        [attrMsg addAttribute:NSForegroundColorAttributeName value:[UIColor systemGreenColor] range:NSMakeRange(0, msg.length)];
        [alert setValue:attrMsg forKey:@"attributedMessage"];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Nhập key vào đây...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = initialKey ?: [self getPermanentKey];
            textField.keyboardAppearance = UIKeyboardAppearanceDark;
            
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
                [self showBlurBackground:NO onView:nil];
                [self showMainAlert:nil];
            });
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Check Key" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [KeyManager shared].isDialogVisible = NO;
            [self showBlurBackground:NO onView:nil];
            [self verifyKey:alert.textFields.firstObject.text];
        }]];
        
        // Lưu alert để có thể dismiss sau
        objc_setAssociatedObject(alert, "blurView", _currentBlurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)showToast:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = [self getTopViewController];
        if (!topVC) return;
        
        UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil 
                                                                       message:message 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [topVC presentViewController:toast animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [toast dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

+ (void)showForceUpdateAlert:(NSString *)link message:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *topVC = [self getTopViewController];
        if (!topVC) return;
        
        [self showBlurBackground:YES onView:topVC.view];
        
        _currentUpdateAlert = [UIAlertController alertControllerWithTitle:@"🚀 Bảo Trì 🚀" 
                                                                  message:msg 
                                                           preferredStyle:UIAlertControllerStyleAlert];
        [_currentUpdateAlert addAction:[UIAlertAction actionWithTitle:@"Cập Nhật" 
                                                                style:UIAlertActionStyleDestructive 
                                                              handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link] options:@{} completionHandler:^(BOOL success) {
                exit(0);
            }];
        }]];
        
        objc_setAssociatedObject(_currentUpdateAlert, "blurView", _currentBlurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [topVC presentViewController:_currentUpdateAlert animated:YES completion:nil];
    });
}

+ (void)showGetUDIDAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KeyManager shared].isDialogVisible) return;
        
        UIViewController *topVC = [self getTopViewController];
        if (!topVC) return;
        
        [KeyManager shared].isDialogVisible = YES;
        [self showBlurBackground:YES onView:topVC.view];

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
                            [KeyManager shared].isDialogVisible = NO;
                            [self showBlurBackground:NO onView:nil];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                exit(0);
                            });
                        }]];
                        
                        [topVC presentViewController:waitingAlert animated:YES completion:nil];
                    });
                }
            }];
        }];
        
        [alert addAction:actionGet];
        objc_setAssociatedObject(alert, "blurView", _currentBlurView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)hideAllUI {
    [KeyManager shared].isDialogVisible = NO;
    [self showBlurBackground:NO onView:nil];
    if (_currentUpdateAlert) {
        [_currentUpdateAlert dismissViewControllerAnimated:YES completion:nil];
        _currentUpdateAlert = nil;
    }
}

+ (void)handlePaste:(UIButton *)sender {
    UITextField *t = (UITextField *)objc_getAssociatedObject(sender, "targetField");
    if (t) t.text = [UIPasteboard generalPasteboard].string;
}

// MARK: - Verify Methods
+ (void)verifyKey:(NSString *)userKey {
    if (!userKey || userKey.length < 2) {
        [self showToast:@"⛔ Vui lòng nhập Key"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [KeyManager shared].isDialogVisible = NO;
            [self showMainAlert:nil];
        });
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
                        [KeyManager shared].isDialogVisible = NO;
                        [self showMainAlert:userKey];
                    });
                });
            }
        }
    }] resume];
}

// MARK: - Update Methods
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
                    if (storedKey) {
                        [self verifyKey:storedKey];
                    } else {
                        [self showMainAlert:nil];
                    }
                    return;
                }
            }
            [self showGetUDIDAlert];
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showMainAlert:userKey];
                });
            }
        }
    }] resume];
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

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

NSURLRequest *modifyRequestIfNeeded(NSURLRequest *request) {
    if (!request || !request.URL) return request;
    
    NSString *urlString = request.URL.absoluteString;
    if (!urlString) return request;
    
    if ([urlString containsString:@"api.cheatiosvip.net"] && 
        [urlString containsString:@"/api/app/config"]) {
        
        NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.cheatiosvip.net" 
                                                                      withString:@"api1.teamgamehub99.workers.dev"];
        
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.URL = [NSURL URLWithString:newUrlString];
        
        NSLog(@"[Bypass] Redirecting config request: %@ -> %@", urlString, newUrlString);
        return [mutableRequest copy];
    }
    
    return request;
}

NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

typedef id (*InitWithURL_t)(id, SEL, id);
static InitWithURL_t orig_initWithURL = NULL;

id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        if ([urlString containsString:@"api.cheatiosvip.net"] && 
            [urlString containsString:@"/api/app/config"]) {
            
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.cheatiosvip.net" 
                                                                          withString:@"api1.teamgamehub99.workers.dev"];
            NSLog(@"[Bypass] Redirecting config request: %@ -> %@", urlString, newUrlString);
            return orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {
        // Hook NSURLSession
        Class sessionClass = NSClassFromString(@"NSURLSession");
        if (sessionClass) {
            SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
            Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
            
            if (targetMethod) {
                orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
                method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);
                NSLog(@"[Bypass] NSURLSession hook installed");
            } else {
                NSLog(@"[Bypass] Failed to find NSURLSession method");
            }
        }

        Method m = class_getInstanceMethod(NSClassFromString(@"NSMutableURLRequest"), @selector(initWithURL:));
        if (m) {
            orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_initWithURL);
            NSLog(@"[Bypass] NSMutableURLRequest hook installed");
        }
    }
}


////////////////////////




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

typedef NSURLSessionDataTask *(*DataTaskWithRequest_t)(id, SEL, NSURLRequest *, void(^)(NSData *, NSURLResponse *, NSError *));
static DataTaskWithRequest_t orig_dataTaskWithRequest_completion = NULL;

NSURLRequest *modifyRequestIfNeeded(NSURLRequest *request) {
    if (!request || !request.URL) return request;
    
    NSString *host = request.URL.host;
    if (!host) return request;
    
    if ([host isEqualToString:@"api.cheatiosvip.net"]) {
        
        NSString *urlString = request.URL.absoluteString;
        NSString *targetHost = @"api1.teamgamehub99.workers.dev";
        
        NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:host withString:targetHost];
        
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.URL = [NSURL URLWithString:newUrlString];
        
        NSLog(@": %@ -> %@", urlString, newUrlString);
        return [mutableRequest copy];
    }
    
    return request;
}

NSURLSessionDataTask *hooked_dataTaskWithRequest_completion(id self, SEL _cmd, NSURLRequest *request, void(^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    
    NSURLRequest *finalRequest = modifyRequestIfNeeded(request);
    
    return orig_dataTaskWithRequest_completion(self, _cmd, finalRequest, completionHandler);
}

typedef id (*InitWithURL_t)(id, SEL, id);

static InitWithURL_t orig_initWithURL = NULL;

id hooked_initWithURL(id self, SEL _cmd, id url) {
    if ([url isKindOfClass:[NSURL class]]) {
        NSString *urlString = [url absoluteString];
        
        if ([urlString containsString:@"api.cheatiosvip.net"]) {
            NSString *newUrlString = [urlString stringByReplacingOccurrencesOfString:@"api.cheatiosvip.net" 
                                                                          withString:@"api1.teamgamehub99.workers.dev"];
            NSLog(@"[Bypass] Redirecting: %@ -> %@", urlString, newUrlString);
            return orig_initWithURL(self, _cmd, [NSURL URLWithString:newUrlString]);
        }
    }
    return orig_initWithURL(self, _cmd, url);
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {

       Class sessionClass = NSClassFromString(@"NSURLSession");
    if (sessionClass) {
        SEL targetSelector = @selector(dataTaskWithRequest:completionHandler:);
        Method targetMethod = class_getInstanceMethod(sessionClass, targetSelector);
        
        if (targetMethod) {
            orig_dataTaskWithRequest_completion = (DataTaskWithRequest_t)method_getImplementation(targetMethod);
            method_setImplementation(targetMethod, (IMP)hooked_dataTaskWithRequest_completion);
            NSLog(@"");
        } else {
            NSLog(@"");
        }
    }




        Method m = class_getInstanceMethod(NSClassFromString(@"NSMutableURLRequest"), @selector(initWithURL:));
        
        if (m) {
            orig_initWithURL = (InitWithURL_t)method_getImplementation(m);
            method_setImplementation(m, (IMP)hooked_initWithURL);
            
        }

    
    }
}
