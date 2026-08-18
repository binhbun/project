#define API_CHECK_UDID_V2    @"https://gmvmoba.com/checkv2"
#define BASE_URL_V2          @"https://gmvmoba.com/connectv2" 
#define PROFILE_URL_V2       @"https://gmvmoba.com/udid/checkv2"
#define ZALO_INFO_V2         @"૮₍´˶• . • ⑅ ₎ა"
#define GAME_NAME_V2         @"PUBG" 
#define GET_KEY_URL_V2       @"https://gmvmoba.com/gmvmoba/getkey"
#define API_DYLIB_SERVER_V2  @"https://gmvmoba.com/api/check-bundle/gmvmobav2"

static NSString *const kSavedUDID_V2 = @"GMV_UDID_DEVICE_V2";
static UIAlertController *_currentUpdateAlert_V2 = nil; 

static NSString * GetCurrentBID_V2() {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.gmvmoba.v2";
    NSMutableString *ms = [bid mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)ms, NULL, kCFStringTransformStripDiacritics, NO);
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"999abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ."];
    return [[ms componentsSeparatedByCharactersInSet:[allowed invertedSet]] componentsJoinedByString:@""];
}

static NSString * PrivateAccount_V2() { 
    return [NSString stringWithFormat:@"GMV_PV_V2_%@", GetCurrentBID_V2()]; 
}

static NSString * TrackingAccount_V2(NSString *userKey) { 
    return [NSString stringWithFormat:@"GMV_TRK_V2_%@", userKey]; 
}

@interface RotateViewController_V2 : UIViewController 
@end

@implementation RotateViewController_V2

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

@interface KeyManager_V2 : NSObject
@property (nonatomic, strong) UIWindow *alertWindow_V2;
@property (nonatomic, strong) UIVisualEffectView *blurView_V2; 
@property (nonatomic, assign) BOOL isChecking_V2; 
@property (nonatomic, assign) BOOL isDialogVisible_V2; 
@property (nonatomic, assign) BOOL lastRequireKeyState_V2;
@property (nonatomic, strong) NSTimer *updateCheckTimer_V2; 
+ (instancetype)shared_V2;
@end

@implementation KeyManager_V2

+ (instancetype)shared_V2 {
    static KeyManager_V2 *shared_V2 = nil;
    static dispatch_once_t onceToken_V2;
    dispatch_once(&onceToken_V2, ^{ 
        shared_V2 = [[KeyManager_V2 alloc] init]; 
        shared_V2.lastRequireKeyState_V2 = YES;
    });
    return shared_V2;
}

+ (NSMutableArray *)getSavedBIDsForKey_V2:(NSString *)key {
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: TrackingAccount_V2(key), (__bridge id)kSecReturnData: @YES};
    CFTypeRef dataRef = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef) == errSecSuccess) {
        NSData *data = (__bridge_transfer NSData *)dataRef;
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return [[str componentsSeparatedByString:@","] mutableCopy];
    }
    return [NSMutableArray array];
}

+ (void)saveBIDs_V2:(NSArray *)bids forKey:(NSString *)key {
    NSString *str = [bids componentsJoinedByString:@","];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: TrackingAccount_V2(key)};
    SecItemDelete((__bridge CFDictionaryRef)query);
    NSMutableDictionary *dict = [query mutableCopy];
    [dict setObject:data forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)dict, NULL);
}

+ (void)resetKeychainBIDList_V2:(NSString *)key {
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: TrackingAccount_V2(key)};
    SecItemDelete((__bridge CFDictionaryRef)query);
}

+ (void)verifyKey_V2:(NSString *)userKey {
    if (!userKey || userKey.length < 2) {
        [self showToast_V2:@"⛔ Vui lòng nhập Key"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
            [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO; 
            [self showMainAlert_V2:nil]; 
        });
        return;
    }
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID_V2] ?: @"UNKNOWN";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:BASE_URL_V2]];
    req.HTTPMethod = @"POST";
    NSString *params = [NSString stringWithFormat:@"game=%@&user_key=%@&serial=%@", GAME_NAME_V2, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!data) { 
                [self showToast_V2:@"⛔ Lỗi kết nối Server!"]; 
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO;
                        [self showMainAlert_V2:userKey];
                    });
                return; 
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *serverReason = json[@"reason"] ?: @"Key không hợp lệ hoặc đã hết hạn";
            
            if ([json[@"status"] boolValue]) {
                int deviceUsed = [json[@"data"][@"device_used"] intValue]; 
                int maxSlot = [json[@"data"][@"device"] intValue];        
                NSString *currentBID = GetCurrentBID_V2();
                
                NSMutableArray *savedBIDs = [self getSavedBIDsForKey_V2:userKey];
                
                if (deviceUsed == 0 && savedBIDs.count > 0) {
                    [self resetKeychainBIDList_V2:userKey];
                    [savedBIDs removeAllObjects];
                }
                
                if ([savedBIDs containsObject:currentBID]) {
                    [self processSuccess_V2:userKey json:json];
                } else if (savedBIDs.count < maxSlot) {
                    [savedBIDs addObject:currentBID];
                    [self saveBIDs_V2:savedBIDs forKey:userKey];
                    [self processSuccess_V2:userKey json:json];
                } else {
                    [self showToast_V2:@"⛔ Hết slot Game cho Key này!\nKey Đã dùng cho Game khác rồi!"];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO;
                        [self showMainAlert_V2:userKey];
                    });
                }
            } else {
                [self showToast_V2:[NSString stringWithFormat:@"⛔ %@", serverReason]];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
                    [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO;
                    [self showMainAlert_V2:userKey]; 
                });
            }
        });
    }] resume];
}

+ (void)processSuccess_V2:(NSString *)userKey json:(NSDictionary *)json {
    [self savePermanentKey_V2:userKey];
    [self showToast_V2:[NSString stringWithFormat:@"✅ Thành Công!\nHạn: %@", json[@"data"][@"EXP"]]];

    [self startUpdatePolling_V2];
    static BOOL isMenuStarted_V2 = NO;
    if (!isMenuStarted_V2) {
        // [YourMenuClass startMenu]; 
        isMenuStarted_V2 = YES;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self hideAllUI_V2];
    });
}

+ (void)silentVerifyKey_V2:(NSString *)userKey {
    if (!userKey || userKey.length < 2) return;

    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID_V2] ?: @"UNKNOWN";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:BASE_URL_V2]];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 10.0;
    
    NSString *params = [NSString stringWithFormat:@"game=%@&user_key=%@&serial=%@", GAME_NAME_V2, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL status = [json[@"status"] boolValue];
            
            if (!status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([KeyManager_V2 shared_V2].updateCheckTimer_V2) {
                        [[KeyManager_V2 shared_V2].updateCheckTimer_V2 invalidate];
                        [KeyManager_V2 shared_V2].updateCheckTimer_V2 = nil;
                    }
                    
                    NSString *serverReason = json[@"reason"] ?: @"Key không hợp lệ hoặc đã hết hạn";
                    [self showToast_V2:[NSString stringWithFormat:@"⛔ %@", serverReason]];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
                        
                        [self prepareWindow_V2]; 
                        [KeyManager_V2 shared_V2].alertWindow_V2.hidden = NO;
                        [[KeyManager_V2 shared_V2].alertWindow_V2 makeKeyAndVisible];
                        [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO; 
                        [self showMainAlert_V2:userKey]; 
                    });
                });
            }
        }
    }] resume];
}

+ (void)hideAllUI_V2 {
    [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO;
    [self setBlurActive_V2:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [KeyManager_V2 shared_V2].alertWindow_V2.hidden = YES;
    });
}

+ (void)showMainAlert_V2:(NSString *)initialKey {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KeyManager_V2 shared_V2].isDialogVisible_V2) return;
        
        [self prepareWindow_V2];
        [KeyManager_V2 shared_V2].alertWindow_V2.hidden = NO;
        [KeyManager_V2 shared_V2].alertWindow_V2.userInteractionEnabled = YES;
        [self setBlurActive_V2:YES];
        [KeyManager_V2 shared_V2].isDialogVisible_V2 = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"「 🔥 GMV MOBA V2 🔥 」" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        NSString *msg = ZALO_INFO_V2;
        NSMutableAttributedString *attrMsg = [[NSMutableAttributedString alloc] initWithString:msg];
        [attrMsg addAttribute:NSForegroundColorAttributeName value:[UIColor systemGreenColor] range:NSMakeRange(0, msg.length)];
        [alert setValue:attrMsg forKey:@"attributedMessage"];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Nhập key vào đây...";
            textField.textAlignment = NSTextAlignmentCenter;
            textField.text = initialKey ?: [self getPermanentKey_V2]; 
            
            UIButton *pasteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [pasteBtn setTitle:@"Dán" forState:UIControlStateNormal];
            pasteBtn.frame = CGRectMake(0, 0, 45, 30);
            [pasteBtn addTarget:self action:@selector(handlePaste_V2:) forControlEvents:UIControlEventTouchUpInside];
            textField.rightView = pasteBtn;
            textField.rightViewMode = UITextFieldViewModeAlways;
            objc_setAssociatedObject(pasteBtn, "targetField_V2", textField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Get Key" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:GET_KEY_URL_V2] options:@{} completionHandler:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO; 
                [self showMainAlert_V2:nil];
            });
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Check Key" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { 
            [KeyManager_V2 shared_V2].isDialogVisible_V2 = NO;
            [self verifyKey_V2:alert.textFields.firstObject.text]; 
        }]];
        
        [[KeyManager_V2 shared_V2].alertWindow_V2.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)prepareWindow_V2 {
    if (![KeyManager_V2 shared_V2].alertWindow_V2) {
        // Khởi tạo Window bao phủ toàn màn hình
        [KeyManager_V2 shared_V2].alertWindow_V2 = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        // windowLevel cực cao để luôn nằm trên cùng (đè cả Status Bar)
        [KeyManager_V2 shared_V2].alertWindow_V2.windowLevel = UIWindowLevelStatusBar + 999.0;
        [KeyManager_V2 shared_V2].alertWindow_V2.rootViewController = [RotateViewController_V2 new];
        [KeyManager_V2 shared_V2].alertWindow_V2.backgroundColor = [UIColor clearColor];

        // Tạo lớp Blur siêu mờ (Dark Style)
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        [KeyManager_V2 shared_V2].blurView_V2 = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        
        // Đặt kích thước lớn hơn màn hình một chút để tránh lộ viền khi xoay
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGFloat side = MAX(screenRect.size.width, screenRect.size.height) * 1.5;
        [KeyManager_V2 shared_V2].blurView_V2.frame = CGRectMake(0, 0, side, side);
        [KeyManager_V2 shared_V2].blurView_V2.center = [KeyManager_V2 shared_V2].alertWindow_V2.center;
        
        [KeyManager_V2 shared_V2].blurView_V2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [KeyManager_V2 shared_V2].blurView_V2.alpha = 0.0; // Mặc định ẩn
        
        // Thêm một lớp phủ màu đen nhẹ để hiệu ứng Blur trông sâu hơn (siêu mờ)
        UIView *overlay = [[UIView alloc] initWithFrame:[KeyManager_V2 shared_V2].blurView_V2.bounds];
        overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [[KeyManager_V2 shared_V2].blurView_V2.contentView addSubview:overlay];

        [[KeyManager_V2 shared_V2].alertWindow_V2.rootViewController.view addSubview:[KeyManager_V2 shared_V2].blurView_V2];

        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    [KeyManager_V2 shared_V2].alertWindow_V2.windowScene = scene; break;
                }
            }
        }
    }
}

+ (void)savePermanentKey_V2:(NSString *)key { 
    if (!key) return; 
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding]; 
    NSDictionary *pQ = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: PrivateAccount_V2()}; 
    SecItemDelete((__bridge CFDictionaryRef)pQ); 
    NSMutableDictionary *p = [pQ mutableCopy]; 
    [p setObject:keyData forKey:(__bridge id)kSecValueData]; 
    SecItemAdd((__bridge CFDictionaryRef)p, NULL); 
}

+ (NSString *)getPermanentKey_V2 { 
    NSDictionary *query = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword, (__bridge id)kSecAttrAccount: PrivateAccount_V2(), (__bridge id)kSecReturnData: @YES, (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne}; 
    CFTypeRef dataRef = NULL; 
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef) == errSecSuccess) { 
        NSData *data = (__bridge_transfer NSData *)dataRef; 
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]; 
    } 
    return nil; 
}

+ (void)showToast_V2:(NSString *)message { 
    dispatch_async(dispatch_get_main_queue(), ^{ 
        [self prepareWindow_V2]; 
        [KeyManager_V2 shared_V2].alertWindow_V2.hidden = NO; 
        UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert]; 
        [[KeyManager_V2 shared_V2].alertWindow_V2.rootViewController presentViewController:toast animated:YES completion:nil]; 
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ 
            [toast dismissViewControllerAnimated:YES completion:nil]; 
        }); 
    }); 
}

+ (void)setBlurActive_V2:(BOOL)active { 
    [UIView animateWithDuration:0.3 animations:^{ 
        [KeyManager_V2 shared_V2].blurView_V2.alpha = active ? 1.0 : 0.0; 
    }]; 
}

+ (void)handlePaste_V2:(UIButton *)sender { 
    UITextField *t = (UITextField *)objc_getAssociatedObject(sender, "targetField_V2"); 
    if (t) t.text = [UIPasteboard generalPasteboard].string; 
}

+ (void)checkUpdateFirstV2 {
}
+ (void)checkUpdateFirst_V2 {
     if ([KeyManager_V2 shared_V2].isChecking_V2) return;
    [KeyManager_V2 shared_V2].isChecking_V2 = YES;
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0.0";
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID_V2] ?: @"UNKNOWN";
    NSString *rawBID = GetCurrentBID_V2();
    NSString *encodedBID = [rawBID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlStr = [NSString stringWithFormat:@"%@?bid=%@&name=%@&udid=%@&ver=%@", API_DYLIB_SERVER_V2, encodedBID, [GAME_NAME_V2 stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]], udid, version];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlStr] completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KeyManager_V2 shared_V2].isChecking_V2 = NO;
            if (data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                BOOL forceUpdate = [json[@"force_update"] boolValue];
                BOOL requireKey = [json[@"require_key"] ?: @(YES) boolValue];

                if (forceUpdate) {
                    if (!_currentUpdateAlert_V2) {
                        [[KeyManager_V2 shared_V2].alertWindow_V2.rootViewController dismissViewControllerAnimated:NO completion:nil];
                        [self showForceUpdateAlert_V2:json[@"update_link"] message:json[@"update_msg"]];
                    }
                    return;
                } else {
                    if (_currentUpdateAlert_V2) {
                        [_currentUpdateAlert_V2 dismissViewControllerAnimated:YES completion:nil];
                        _currentUpdateAlert_V2 = nil;
                        [self hideAllUI_V2];
                    }
                }

                if (!requireKey) {
                    [KeyManager_V2 shared_V2].lastRequireKeyState_V2 = NO;
                    [self hideAllUI_V2];
                    return;
                }

                [KeyManager_V2 shared_V2].lastRequireKeyState_V2 = YES;
                if (![KeyManager_V2 shared_V2].isDialogVisible_V2) {
                    [self checkDeviceAndStart_V2];
                }
            }
        });
    }] resume];
}

+ (void)verifyKeyForPolling_V2:(NSString *)userKey {
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:kSavedUDID_V2] ?: @"UNKNOWN";
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:BASE_URL_V2]];
    req.HTTPMethod = @"POST";
    NSString *params = [NSString stringWithFormat:@"game=%@&user_key=%@&serial=%@", GAME_NAME_V2, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (![json[@"status"] boolValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{ [self showMainAlert_V2:userKey]; });
            }
        }
    }] resume];
}

+ (void)showForceUpdateAlert_V2:(NSString *)link message:(NSString *)msg {
    [self prepareWindow_V2];
    [KeyManager_V2 shared_V2].alertWindow_V2.hidden = NO; 
    [self setBlurActive_V2:YES];
    _currentUpdateAlert_V2 = [UIAlertController alertControllerWithTitle:@"🚀 Bảo Trì V2 🚀" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [_currentUpdateAlert_V2 addAction:[UIAlertAction actionWithTitle:@"Cập Nhật" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link] options:@{} completionHandler:^(BOOL success) {
            exit(0);
        }];
    }]];
    [[KeyManager_V2 shared_V2].alertWindow_V2.rootViewController presentViewController:_currentUpdateAlert_V2 animated:YES completion:nil];
}

+ (void)checkDeviceAndStart_V2 {
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:API_CHECK_UDID_V2] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json[@"status"] boolValue] && json[@"udid"]) {
                    [[NSUserDefaults standardUserDefaults] setObject:json[@"udid"] forKey:kSavedUDID_V2];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSString *storedKey = [self getPermanentKey_V2];
                    if (storedKey) [self verifyKey_V2:storedKey]; else [self showMainAlert_V2:nil];
                    return;
                }
            }
            [self showGetUDIDAlert_V2];
        });
    }] resume];
}

+ (void)showGetUDIDAlert_V2 {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([KeyManager_V2 shared_V2].isDialogVisible_V2) return;
        [self prepareWindow_V2];
        [KeyManager_V2 shared_V2].alertWindow_V2.hidden = NO;
        [self setBlurActive_V2:YES];
        [KeyManager_V2 shared_V2].isDialogVisible_V2 = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"XÁC MINH UDID V2" 
                                                                       message:@"Vui lòng 'Click Lấy UDID' để cài đặt hồ sơ xác minh thiết bị." 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionGet = [UIAlertAction actionWithTitle:@"Click Lấy UDID (Safari)" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PROFILE_URL_V2] options:@{} completionHandler:^(BOOL success) {
                if (success) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        UIAlertController *waitingAlert = [UIAlertController alertControllerWithTitle:@"♻️ ĐANG CHỜ XÁC MINH V2" 
                                                                                              message:@"Đang chờ cài đặt DNS Profile UDID và xác minh trong Cài đặt.\n\nNếu đã cài và xác minh thành công, hãy nhấn OK để thoát Game, sau đó mở lại để cập nhật." 
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                        
                        [waitingAlert addAction:[UIAlertAction actionWithTitle:@"OK Luôn" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self hideAllUI_V2];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                exit(0);
                            });
                        }]];
                        
                        [[KeyManager_V2 shared_V2].alertWindow_V2.rootViewController presentViewController:waitingAlert animated:YES completion:nil];
                    });
                }
            }];
        }];
        
        [alert addAction:actionGet];
        [[KeyManager_V2 shared_V2].alertWindow_V2.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

+ (void)handleTimerCheck_V2 {
    NSString *storedKey = [self getPermanentKey_V2];
    
    if (storedKey && storedKey.length > 1) {
        [self silentVerifyKey_V2:storedKey];
    } else {
        if ([KeyManager_V2 shared_V2].updateCheckTimer_V2) {
            [[KeyManager_V2 shared_V2].updateCheckTimer_V2 invalidate];
            [KeyManager_V2 shared_V2].updateCheckTimer_V2 = nil;
        }
    }
}

+ (void)startUpdatePolling_V2 {
    if ([KeyManager_V2 shared_V2].updateCheckTimer_V2 && [[KeyManager_V2 shared_V2].updateCheckTimer_V2 isValid]) {
        return;
    }
    
    [KeyManager_V2 shared_V2].updateCheckTimer_V2 = [NSTimer scheduledTimerWithTimeInterval:10.0 
                                                                          target:self 
                                                                        selector:@selector(handleTimerCheck_V2) 
                                                                        userInfo:nil 
                                                                         repeats:YES];
}

+ (void)load_V2 {
    static dispatch_once_t once_V2;
    dispatch_once(&once_V2, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self checkUpdateFirstV2]; 
        });
    });
}
@end
