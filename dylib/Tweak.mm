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

@interface SnowEffectView : UIView
@end
@implementation SnowEffectView

+ (Class)layerClass {
    return [CAEmitterLayer class];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CAEmitterLayer *emitter = (CAEmitterLayer *)self.layer;
    emitter.emitterPosition = CGPointMake(self.bounds.size.width / 2.0, -30);
    emitter.emitterSize = CGSizeMake(self.bounds.size.width, 1);
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (!self.window) return;

    CAEmitterLayer *emitter = (CAEmitterLayer *)self.layer;
    emitter.emitterShape = kCAEmitterLayerLine;
    emitter.emitterMode = kCAEmitterLayerOutline;

    CGFloat commonWidth = 15.0;
    CGFloat commonScale = 0.05;

   
    CAEmitterCell *snowCell = [self createBaseCell];
    snowCell.contents = (__bridge id)[[self drawSnowflakeWidth:commonWidth] CGImage];
    snowCell.color = [[UIColor whiteColor] CGColor];
    snowCell.birthRate = 10;
    snowCell.scale = commonScale; 
    snowCell.spinRange = 0.8;

    
    CAEmitterCell *cherryCell = [self createBaseCell];
    cherryCell.contents = (__bridge id)[[self drawFlowerWithPetals:5 width:commonWidth] CGImage];
    cherryCell.color = [[UIColor colorWithRed:1.0 green:0.75 blue:0.8 alpha:1.0] CGColor];
    cherryCell.birthRate = 18;
    cherryCell.scale = commonScale;
    cherryCell.spinRange = 2.5;

   
    CAEmitterCell *apricotCell = [self createBaseCell];
    apricotCell.contents = (__bridge id)[[self drawFlowerWithPetals:5 width:commonWidth] CGImage];
  
    apricotCell.color = [[UIColor colorWithRed:1.0 green:0.95 blue:0.0 alpha:1.0] CGColor];
    apricotCell.birthRate = 15;
    apricotCell.scale = commonScale;
    apricotCell.spinRange = 2.0;

    emitter.emitterCells = @[snowCell, cherryCell, apricotCell];
}

- (CAEmitterCell *)createBaseCell {
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.lifetime = 20.0;
    cell.velocity = 60;
    cell.velocityRange = 30;
    cell.yAcceleration = 25;
    cell.emissionRange = M_PI / 6;
    cell.scaleRange = 0.02; 
    cell.alphaSpeed = -0.01;
    cell.spin = 0;
    return cell;
}

- (UIImage *)drawSnowflakeWidth:(CGFloat)width {
    CGSize size = CGSizeMake(width, width);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(context, width * 0.12); 
    CGContextSetLineCap(context, kCGLineCapRound);

    CGPoint center = CGPointMake(width / 2.0, width / 2.0);
    CGFloat radius = width / 2.0;
    for (int i = 0; i < 5; i++) {
        CGFloat angle = (i * 2.0 * M_PI / 5) - (M_PI / 2.0);
        CGPoint point = CGPointMake(center.x + radius * cos(angle), center.y + radius * sin(angle));
        CGContextMoveToPoint(context, center.x, center.y);
        CGContextAddLineToPoint(context, point.x, point.y);
    }
    CGContextStrokePath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)drawFlowerWithPetals:(int)petals width:(CGFloat)width {
    CGSize size = CGSizeMake(width, width);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [[UIColor whiteColor] setFill];
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint center = CGPointMake(width / 2.0, width / 2.0);
    CGFloat petalRadius = width / 2.0;
    CGFloat centerRadius = width * 0.1;

    for (int i = 0; i < petals; i++) {
        CGFloat startAngle = (i * 2.0 * M_PI / petals) - (M_PI / petals / 2.0) - (M_PI / 2.0);
        CGFloat endAngle = startAngle + (2.0 * M_PI / petals);
        CGPoint petalStart = CGPointMake(center.x + centerRadius * cos(startAngle), center.y + centerRadius * sin(startAngle));
        CGPoint petalTip = CGPointMake(center.x + petalRadius * cos((startAngle + endAngle) / 2.0), center.y + petalRadius * sin((startAngle + endAngle) / 2.0));
        
        if (i == 0) [path moveToPoint:petalStart];
        else [path addLineToPoint:petalStart];

        [path addQuadCurveToPoint:petalTip controlPoint:CGPointMake(center.x + petalRadius * 1.3 * cos(startAngle), center.y + petalRadius * 1.3 * sin(startAngle))];
        [path addQuadCurveToPoint:petalStart controlPoint:CGPointMake(center.x + petalRadius * 1.3 * cos(endAngle), center.y + petalRadius * 1.3 * sin(endAngle))];
    }
    [path closePath];
    [path fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
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
        [[KeyManager shared].alertWindow makeKeyAndVisible];
        [KeyManager shared].alertWindow.hidden = NO;
        [self setBlurActive:YES];
        [KeyManager shared].isDialogVisible = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"「 🔥 GMV MOBA 🔥 」" message:nil preferredStyle:UIAlertControllerStyleAlert];
        __weak UIAlertController *weakAlert = alert;

        NSMutableAttributedString *attrMsg = [[NSMutableAttributedString alloc] initWithString:ZALO_INFO];
        [attrMsg addAttribute:NSForegroundColorAttributeName value:[UIColor systemGreenColor] range:NSMakeRange(0, ZALO_INFO.length)];
        [alert setValue:attrMsg forKey:@"attributedMessage"];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Nhập key vào đây...";
            textField.textAlignment = NSTextAlignmentCenter;
            
            if (initialKey && initialKey.length > 0) {
                textField.text = initialKey;
            } else {
                textField.text = [self getPermanentKey];
            }
            
            UIButton *pasteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [pasteBtn setTitle:@"Dán" forState:UIControlStateNormal];
            pasteBtn.frame = CGRectMake(0, 0, 45, 30);
            [pasteBtn addTarget:self action:@selector(handlePaste:) forControlEvents:UIControlEventTouchUpInside];
            textField.rightView = pasteBtn;
            textField.rightViewMode = UITextFieldViewModeAlways;
            objc_setAssociatedObject(pasteBtn, "targetField", textField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Get Key" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:GET_KEY_URL] options:@{} completionHandler:^(BOOL success) {
                    [KeyManager shared].isDialogVisible = NO; 
                    [self showMainAlert:nil];
                }];
            });
        }]];


        [alert addAction:[UIAlertAction actionWithTitle:@"Check Key" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { 
            [KeyManager shared].isDialogVisible = NO;
            [self verifyKey:weakAlert.textFields.firstObject.text]; 
        }]];
        
        [[KeyManager shared].alertWindow.rootViewController presentViewController:alert animated:YES completion:^{
            [alert.view endEditing:YES];
        }];
    });
}



+ (void)prepareWindow {
    if (![KeyManager shared].alertWindow) {
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [KeyManager shared].alertWindow = window;
        
        window.windowLevel = UIWindowLevelStatusBar + 9999.0;
        window.backgroundColor = [UIColor clearColor];

        RotateViewController *rvc = [[RotateViewController alloc] init];
        window.rootViewController = rvc;

        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window.windowScene = scene;
                    break;
                }
            }
        }

        UIView *mainView = rvc.view;

        UIView *blackOverlay = [[UIView alloc] initWithFrame:mainView.bounds];
        blackOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1.0];
        blackOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [mainView addSubview:blackOverlay];

        SnowEffectView *snow = [[SnowEffectView alloc] initWithFrame:mainView.bounds];
        snow.userInteractionEnabled = NO;
        snow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [mainView addSubview:snow];

        window.hidden = NO;
        [window makeKeyAndVisible];
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