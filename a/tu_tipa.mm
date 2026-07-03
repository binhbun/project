// Tweak.xm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
// FUNCTION POINTERS
// ============================================================
static BOOL (*original_hasValidAPIKey)(id self, SEL _cmd);
static BOOL (*original_isAPIValidationInProgress)(id self, SEL _cmd);
static void (*original_updateAPIStatusUI)(id self, SEL _cmd);
static void (*original_updateAPIOverlay)(id self, SEL _cmd);
static void (*original_validateAPIKey)(id self, SEL _cmd);
static void (*original_telegramRowTapped)(id self, SEL _cmd);

// ============================================================
// HOOK 1: hasValidAPIKey - LUÔN TRẢ VỀ YES
// ============================================================
static BOOL hooked_hasValidAPIKey(id self, SEL _cmd) {
    // Luôn return YES để bypass mọi kiểm tra
    return YES;
}

// ============================================================
// HOOK 2: isAPIValidationInProgress - LUÔN NO
// ============================================================
static BOOL hooked_isAPIValidationInProgress(id self, SEL _cmd) {
    return NO;
}

// ============================================================
// HOOK 3: updateAPIStatusUI - CUSTOM HIỂN THỊ
// ============================================================
static void hooked_updateAPIStatusUI(id self, SEL _cmd) {
    NSLog(@"[Bypass] updateAPIStatusUI - customizing display");
    
    // Lấy các thành phần UI
    UITextField *keyField = [self valueForKey:@"apiKeyField"];
    UILabel *statusLabel = [self valueForKey:@"apiStatusLabel"];
    UISwitch *hudSwitch = [self valueForKey:@"hudSwitch"];
    UIButton *validateButton = [self valueForKey:@"apiValidateButton"];
    
    // Tạo fake key và expiry trong UserDefaults (nếu chưa có)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *existingKey = [defaults stringForKey:@"PakeAPIKey"];
    
    if (!existingKey || existingKey.length == 0) {
        // Tạo fake key
        NSString *fakeKey = @"GMV_PREMIUM_2024_ACTIVATED";
        [defaults setObject:fakeKey forKey:@"PakeAPIKey"];
        
        // Tạo expiry date (1 năm sau)
        NSDate *expiryDate = [NSDate dateWithTimeIntervalSinceNow:365 * 24 * 60 * 60];
        [defaults setObject:expiryDate forKey:@"PakeAPIKeyExpiry"];
        [defaults synchronize];
        
        NSLog(@"[Bypass] Created fake key: %@", fakeKey);
    }
    
    // Set text cho key field
    if (keyField) {
        NSString *key = [defaults stringForKey:@"PakeAPIKey"];
        keyField.text = key ? key : @"GMV_PREMIUM_2024_ACTIVATED";
    }
    
    // Custom status label
    if (statusLabel) {
        NSDate *expiry = [defaults objectForKey:@"PakeAPIKeyExpiry"];
        if (expiry) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterMediumStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            NSString *expiryStr = [formatter stringFromDate:expiry];
            statusLabel.text = [NSString stringWithFormat:@"✅ Premium Activated\n📅 Expires: %@", expiryStr];
            statusLabel.textColor = [UIColor greenColor];
            statusLabel.numberOfLines = 0;
        } else {
            statusLabel.text = @"✅ Premium Activated";
            statusLabel.textColor = [UIColor greenColor];
        }
    }
    
    // Enable HUD switch
    if (hudSwitch) {
        [hudSwitch setEnabled:YES];
    }
    
    // Update validate button
    if (validateButton) {
        [validateButton setTitle:@"✅ ACTIVATED" forState:UIControlStateNormal];
        [validateButton setEnabled:NO];
        validateButton.backgroundColor = [UIColor greenColor];
    }
    
    // Gọi updateAPIOverlay để ẩn overlay
    [self performSelector:@selector(updateAPIOverlay)];
    
    NSLog(@"[Bypass] ✅ UI updated to Premium status");
}

// ============================================================
// HOOK 4: updateAPIOverlay - ẨN OVERLAY
// ============================================================
static void hooked_updateAPIOverlay(id self, SEL _cmd) {
    NSLog(@"[Bypass] updateAPIOverlay - hiding overlay");
    
    // Ẩn overlay
    UIView *overlayView = [self valueForKey:@"apiOverlayView"];
    if (overlayView) {
        [overlayView setHidden:YES];
    }
    [self setValue:@NO forKey:@"apiOverlayVisible"];
    
    // Stop loading indicator
    UIActivityIndicatorView *loadingIndicator = [self valueForKey:@"apiLoadingIndicator"];
    if (loadingIndicator) {
        [loadingIndicator stopAnimating];
    }
    
    // Enable validate button
    UIButton *validateButton = [self valueForKey:@"apiValidateButton"];
    if (validateButton) {
        [validateButton setEnabled:YES];
    }
}

// ============================================================
// HOOK 5: validateAPIKey - TỰ ĐỘNG KÍCH HOẠT
// ============================================================
static void hooked_validateAPIKey(id self, SEL _cmd) {
    NSLog(@"[Bypass] validateAPIKey - auto-activating");
    
    // Lấy key từ text field
    UITextField *keyField = [self valueForKey:@"apiKeyField"];
    NSString *key = keyField.text;
    
    // Nếu key rỗng, tạo fake key
    if (!key || key.length == 0) {
        key = @"GMV_PREMIUM_2024_ACTIVATED";
        keyField.text = key;
    }
    
    // Lưu vào UserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:key forKey:@"PakeAPIKey"];
    
    // Tạo expiry date (1 năm sau)
    NSDate *expiryDate = [NSDate dateWithTimeIntervalSinceNow:365 * 24 * 60 * 60];
    [defaults setObject:expiryDate forKey:@"PakeAPIKeyExpiry"];
    [defaults synchronize];
    
    // Set valid state
    [self setValue:@YES forKey:@"hasValidAPIKey"];
    
    // Update UI
    [self performSelector:@selector(updateAPIStatusUI)];
    [self performSelector:@selector(updateAPIOverlay)];
    
    // Stop loading
    UIActivityIndicatorView *loadingIndicator = [self valueForKey:@"apiLoadingIndicator"];
    if (loadingIndicator) {
        [loadingIndicator stopAnimating];
    }
    
    NSLog(@"[Bypass] ✅ Account activated with key: %@", key);
}

// ============================================================
// HOOK 6: telegramRowTapped - MỞ LINK
// ============================================================
static void hooked_telegramRowTapped(id self, SEL _cmd) {
    NSLog(@"[Bypass] 📱 Opening Telegram: https://t.me/binhbun02");
    NSURL *telegramURL = [NSURL URLWithString:@"https://t.me/binhbun02"];
    [[UIApplication sharedApplication] openURL:telegramURL 
                                       options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO} 
                             completionHandler:nil];
}

// ============================================================
// HOOK 7: NSURLSession - CHẶN REQUEST
// ============================================================
static id (*original_dataTaskWithRequest)(id self, SEL _cmd, id request, id completionHandler);
static id hooked_dataTaskWithRequest(id self, SEL _cmd, id request, id completionHandler) {
    NSURL *url = [request URL];
    NSString *urlString = [url absoluteString];
    
    if ([urlString containsString:@"verify-key"]) {
        NSLog(@"[Bypass] 🎯 Intercepted verify-key request");
        
        // Fake response - SUCCESS với expiry date
        NSDictionary *fakeResponse = @{
            @"success": @YES,
            @"message": @"API key validated successfully",
            @"data": @{
                @"valid": @YES,
                @"activated": @YES,
                @"premium": @YES,
                @"expiry": @"2025-12-31T23:59:59Z"
            }
        };
        
        NSData *fakeData = [NSJSONSerialization dataWithJSONObject:fakeResponse options:0 error:nil];
        NSHTTPURLResponse *fakeHTTPResponse = [[NSHTTPURLResponse alloc] 
            initWithURL:url 
            statusCode:200 
            HTTPVersion:@"HTTP/1.1" 
            headerFields:@{@"Content-Type": @"application/json"}];
        
        void (^handler)(NSData *, NSURLResponse *, NSError *) = completionHandler;
        handler(fakeData, fakeHTTPResponse, nil);
        
        return nil;
    }
    
    return original_dataTaskWithRequest(self, _cmd, request, completionHandler);
}

// ============================================================
// CONSTRUCTOR
// ============================================================
%ctor {
    @autoreleasepool {
        NSLog(@"[Bypass] ========================================");
        NSLog(@"[Bypass] 🚀 Loading GMV Premium Bypass v4.0");
        
        Class homeVC = NSClassFromString(@"HomeViewController");
        if (!homeVC) {
            NSLog(@"[Bypass] ❌ HomeViewController not found");
            return;
        }
        
        // ============================================================
        // HOOK 1: hasValidAPIKey - QUAN TRỌNG NHẤT
        // ============================================================
        SEL hasValidSel = sel_registerName("hasValidAPIKey");
        Method hasValidMethod = class_getInstanceMethod(homeVC, hasValidSel);
        if (hasValidMethod) {
            original_hasValidAPIKey = (typeof(original_hasValidAPIKey))method_getImplementation(hasValidMethod);
            method_setImplementation(hasValidMethod, (IMP)hooked_hasValidAPIKey);
            NSLog(@"[Bypass] ✅ Hooked hasValidAPIKey -> always YES");
        }
        
        // ============================================================
        // HOOK 2: isAPIValidationInProgress
        // ============================================================
        SEL inProgressSel = sel_registerName("isAPIValidationInProgress");
        Method inProgressMethod = class_getInstanceMethod(homeVC, inProgressSel);
        if (inProgressMethod) {
            original_isAPIValidationInProgress = (typeof(original_isAPIValidationInProgress))method_getImplementation(inProgressMethod);
            method_setImplementation(inProgressMethod, (IMP)hooked_isAPIValidationInProgress);
            NSLog(@"[Bypass] ✅ Hooked isAPIValidationInProgress -> always NO");
        }
        
        // ============================================================
        // HOOK 3: updateAPIStatusUI
        // ============================================================
        SEL updateStatusSel = sel_registerName("updateAPIStatusUI");
        Method updateStatusMethod = class_getInstanceMethod(homeVC, updateStatusSel);
        if (updateStatusMethod) {
            original_updateAPIStatusUI = (typeof(original_updateAPIStatusUI))method_getImplementation(updateStatusMethod);
            method_setImplementation(updateStatusMethod, (IMP)hooked_updateAPIStatusUI);
            NSLog(@"[Bypass] ✅ Hooked updateAPIStatusUI");
        }
        
        // ============================================================
        // HOOK 4: updateAPIOverlay
        // ============================================================
        SEL updateOverlaySel = sel_registerName("updateAPIOverlay");
        Method updateOverlayMethod = class_getInstanceMethod(homeVC, updateOverlaySel);
        if (updateOverlayMethod) {
            original_updateAPIOverlay = (typeof(original_updateAPIOverlay))method_getImplementation(updateOverlayMethod);
            method_setImplementation(updateOverlayMethod, (IMP)hooked_updateAPIOverlay);
            NSLog(@"[Bypass] ✅ Hooked updateAPIOverlay");
        }
        
        // ============================================================
        // HOOK 5: validateAPIKey
        // ============================================================
        SEL validateSel = sel_registerName("validateAPIKey");
        Method validateMethod = class_getInstanceMethod(homeVC, validateSel);
        if (validateMethod) {
            original_validateAPIKey = (typeof(original_validateAPIKey))method_getImplementation(validateMethod);
            method_setImplementation(validateMethod, (IMP)hooked_validateAPIKey);
            NSLog(@"[Bypass] ✅ Hooked validateAPIKey");
        }
        
        // ============================================================
        // HOOK 6: telegramRowTapped
        // ============================================================
        SEL telegramSel = sel_registerName("telegramRowTapped");
        Method telegramMethod = class_getInstanceMethod(homeVC, telegramSel);
        if (telegramMethod) {
            original_telegramRowTapped = (typeof(original_telegramRowTapped))method_getImplementation(telegramMethod);
            method_setImplementation(telegramMethod, (IMP)hooked_telegramRowTapped);
            NSLog(@"[Bypass] ✅ Hooked telegramRowTapped");
        }
        
        // ============================================================
        // HOOK 7: NSURLSession
        // ============================================================
        Class sessionClass = NSClassFromString(@"NSURLSession");
        if (sessionClass) {
            SEL dataTaskSel = sel_registerName("dataTaskWithRequest:completionHandler:");
            Method dataTaskMethod = class_getInstanceMethod(sessionClass, dataTaskSel);
            if (dataTaskMethod) {
                original_dataTaskWithRequest = (typeof(original_dataTaskWithRequest))method_getImplementation(dataTaskMethod);
                method_setImplementation(dataTaskMethod, (IMP)hooked_dataTaskWithRequest);
                NSLog(@"[Bypass] ✅ Hooked NSURLSession dataTaskWithRequest");
            }
        }
        
        // ============================================================
        // AUTO-ACTIVATE SAU KHI APP LOAD
        // ============================================================
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            if (!keyWindow) {
                keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
            }
            
            UIViewController *rootVC = keyWindow.rootViewController;
            if ([rootVC isKindOfClass:homeVC]) {
                // Tạo fake data trong UserDefaults
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if (![defaults stringForKey:@"PakeAPIKey"]) {
                    [defaults setObject:@"GMV_PREMIUM_2024_ACTIVATED" forKey:@"PakeAPIKey"];
                    [defaults setObject:[NSDate dateWithTimeIntervalSinceNow:365 * 24 * 60 * 60] 
                                 forKey:@"PakeAPIKeyExpiry"];
                    [defaults synchronize];
                }
                
                // Set valid state
                [rootVC setValue:@YES forKey:@"hasValidAPIKey"];
                
                // Update UI
                [rootVC performSelector:@selector(updateAPIStatusUI)];
                [rootVC performSelector:@selector(updateAPIOverlay)];
                
                NSLog(@"[Bypass] ✅ Auto-activated successfully!");
            }
        });
        
        NSLog(@"[Bypass] ✅ Bypass loaded successfully!");
        NSLog(@"[Bypass] 📱 Telegram: https://t.me/binhbun02");
        NSLog(@"[Bypass] 🔓 Premium status: ACTIVATED");
        NSLog(@"[Bypass] ========================================");
    }
}
