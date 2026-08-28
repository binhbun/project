#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Security/Security.h>
#import <sys/sysctl.h>
#import <CommonCrypto/CommonDigest.h>
#import <mach-o/loader.h>
#import <mach-o/getsect.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

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
// ============================================
//  VALIDATION FUNCTIONS - 100 FUNCTIONS
// ============================================

#pragma mark -  UDID Validation Functions (1-10)

+ (BOOL)validateUDIDFormat_V2:(NSString *)udid {
    if (udid.length < 8) return NO;
    NSString *pattern = @"^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:udid];
}

+ (NSString *)generateChecksum_V2:(NSString *)input {
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < input.length; i++) {
        unichar c = [input characterAtIndex:i];
        [result appendFormat:@"%02x", c ^ 0x55];
    }
    return result;
}

+ (BOOL)verifyUDIDSignature_V2:(NSString *)udid signature:(NSString *)sig {
    NSString *computed = [self generateChecksum_V2:udid];
    return [computed isEqualToString:sig];
}

+ (NSDictionary *)parseUDIDMetadata_V2:(NSString *)udid {
    NSMutableDictionary *meta = [NSMutableDictionary dictionary];
    NSArray *parts = [udid componentsSeparatedByString:@"-"];
    if (parts.count >= 5) {
        meta[@"timestamp"] = parts[0];
        meta[@"device_class"] = parts[1];
        meta[@"region"] = parts[2];
    }
    return meta;
}

+ (BOOL)checkUDIDExpiry_V2:(NSString *)udid {
    NSDictionary *meta = [self parseUDIDMetadata_V2:udid];
    NSString *ts = meta[@"timestamp"];
    if (!ts) return NO;
    NSTimeInterval time = [ts doubleValue];
    return ([[NSDate date] timeIntervalSince1970] - time) < 86400 * 30;
}

#pragma mark -  Key Validation Functions (11-20)

+ (BOOL)validateKeyLength_V2:(NSString *)key {
    return key.length >= 8 && key.length <= 32;
}

+ (BOOL)validateKeyCharacters_V2:(NSString *)key {
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
    NSCharacterSet *inverted = [allowed invertedSet];
    return [key rangeOfCharacterFromSet:inverted].location == NSNotFound;
}

+ (NSString *)extractKeyVersion_V2:(NSString *)key {
    if (key.length < 4) return @"V1";
    return [key substringToIndex:4];
}

+ (BOOL)verifyKeyChecksum_V2:(NSString *)key {
    if (key.length < 10) return NO;
    NSString *payload = [key substringToIndex:key.length - 4];
    NSString *checksum = [key substringFromIndex:key.length - 4];
    NSString *computed = [self generateChecksum_V2:payload];
    return [[computed substringToIndex:4] isEqualToString:checksum];
}

+ (NSInteger)getKeyPriority_V2:(NSString *)key {
    NSInteger priority = 0;
    for (int i = 0; i < key.length; i++) {
        unichar c = [key characterAtIndex:i];
        priority += c;
    }
    return priority % 100;
}

#pragma mark -  Device Binding Functions (21-30)

+ (BOOL)isDeviceBlacklisted_V2:(NSString *)deviceID {
    NSArray *blacklist = @[@"BLACK_001", @"BLACK_002", @"BLACK_003"];
    return [blacklist containsObject:deviceID];
}

+ (NSInteger)getDeviceTrustScore_V2:(NSString *)deviceID {
    NSInteger score = 0;
    for (int i = 0; i < deviceID.length; i++) {
        unichar c = [deviceID characterAtIndex:i];
        score += c % 7;
    }
    return score % 100;
}

+ (BOOL)validateDeviceBinding_V2:(NSString *)deviceID key:(NSString *)key {
    NSString *combined = [NSString stringWithFormat:@"%@_%@", deviceID, key];
    NSString *hash = [self generateChecksum_V2:combined];
    return [hash hasPrefix:@"00"];
}

+ (NSArray *)getDeviceHistory_V2:(NSString *)deviceID {
    return @[@"2024-01-01", @"2024-01-15", @"2024-02-01"];
}

+ (BOOL)isDeviceOverused_V2:(NSString *)deviceID {
    NSArray *history = [self getDeviceHistory_V2:deviceID];
    return history.count > 5;
}

#pragma mark -  Server Response Functions (31-40)

+ (NSDictionary *)simulateServerResponse_V2:(NSString *)endpoint {
    return @{
        @"status": @YES,
        @"code": @200,
        @"message": @"Success",
        @"timestamp": @([[NSDate date] timeIntervalSince1970])
    };
}

+ (BOOL)validateServerSignature_V2:(NSDictionary *)response {
    NSString *sig = response[@"signature"];
    if (!sig) return NO;
    return sig.length > 10;
}

+ (NSString *)decodeServerPayload_V2:(NSData *)payload {
    return [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
}

+ (NSData *)encodeServerPayload_V2:(NSString *)payload {
    return [payload dataUsingEncoding:NSUTF8StringEncoding];
}

+ (BOOL)checkServerVersion_V2:(NSDictionary *)response {
    NSString *version = response[@"version"];
    return version && [version compare:@"2.0"] != NSOrderedAscending;
}

#pragma mark -  License Validation Functions (41-50)

+ (BOOL)validateLicense_V2:(NSString *)license {
    if (license.length < 16) return NO;
    NSArray *parts = [license componentsSeparatedByString:@"-"];
    return parts.count == 4;
}

+ (NSDate *)extractLicenseExpiry_V2:(NSString *)license {
    if (license.length < 8) return [NSDate date];
    NSString *dateStr = [license substringToIndex:8];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd"];
    return [formatter dateFromString:dateStr];
}

+ (BOOL)isLicenseExpired_V2:(NSString *)license {
    NSDate *expiry = [self extractLicenseExpiry_V2:license];
    return [expiry compare:[NSDate date]] == NSOrderedAscending;
}

+ (NSInteger)getLicenseTier_V2:(NSString *)license {
    if (license.length < 4) return 0;
    NSString *tier = [license substringFromIndex:license.length - 4];
    return [tier integerValue] % 3;
}

+ (BOOL)validateLicenseSignature_V2:(NSString *)license {
    NSString *body = [license substringToIndex:license.length - 8];
    NSString *sig = [license substringFromIndex:license.length - 8];
    NSString *computed = [self generateChecksum_V2:body];
    return [[computed substringToIndex:8] isEqualToString:sig];
}

#pragma mark -  Bundle Validation Functions (51-60)

+ (BOOL)validateBundleID_V2:(NSString *)bundleID {
    NSArray *allowedPrefixes = @[@"com.", @"org.", @"net."];
    for (NSString *prefix in allowedPrefixes) {
        if ([bundleID hasPrefix:prefix]) return YES;
    }
    return NO;
}

+ (BOOL)validateBundleVersion_V2:(NSString *)version {
    NSArray *parts = [version componentsSeparatedByString:@"."];
    if (parts.count != 3) return NO;
    for (NSString *part in parts) {
        if ([part integerValue] < 0) return NO;
    }
    return YES;
}

+ (NSString *)sanitizeBundleID_V2:(NSString *)bundleID {
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < bundleID.length; i++) {
        unichar c = [bundleID characterAtIndex:i];
        if (isalnum(c) || c == '.' || c == '_') {
            [result appendFormat:@"%C", c];
        }
    }
    return result;
}

+ (BOOL)compareBundleIDs_V2:(NSString *)bid1 bid2:(NSString *)bid2 {
    return [bid1 caseInsensitiveCompare:bid2] == NSOrderedSame;
}

+ (NSDictionary *)parseBundleInfo_V2:(NSString *)bundleID {
    return @{
        @"identifier": bundleID,
        @"valid": @([self validateBundleID_V2:bundleID])
    };
}

#pragma mark -  Network Validation Functions (61-70)

+ (BOOL)validateEndpoint_V2:(NSString *)endpoint {
    NSURL *url = [NSURL URLWithString:endpoint];
    return url && url.scheme && url.host;
}

+ (NSString *)extractDomain_V2:(NSString *)url {
    NSURL *parsed = [NSURL URLWithString:url];
    return parsed.host ?: @"";
}

+ (BOOL)isTrustedDomain_V2:(NSString *)domain {
    NSArray *trusted = @[@"gmvmoba.com", @"api.gmvmoba.com", @"secure.gmvmoba.com"];
    return [trusted containsObject:domain];
}

+ (NSInteger)getNetworkLatency_V2 {
    return arc4random() % 100 + 50;
}

+ (BOOL)validateNetworkRequest_V2:(NSURLRequest *)request {
    return request && request.URL && [self validateEndpoint_V2:request.URL.absoluteString];
}

#pragma mark -  Session Management Functions (71-80)

+ (NSString *)generateSessionID_V2 {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"SESS_%.0f_%d", time, arc4random() % 10000];
}

+ (BOOL)validateSessionID_V2:(NSString *)sessionID {
    return [sessionID hasPrefix:@"SESS_"] && sessionID.length > 10;
}

+ (NSDictionary *)getSessionMetadata_V2:(NSString *)sessionID {
    return @{
        @"created": @([[NSDate date] timeIntervalSince1970]),
        @"valid": @([self validateSessionID_V2:sessionID])
    };
}

+ (BOOL)isSessionActive_V2:(NSString *)sessionID {
    NSDictionary *meta = [self getSessionMetadata_V2:sessionID];
    NSTimeInterval created = [meta[@"created"] doubleValue];
    return ([[NSDate date] timeIntervalSince1970] - created) < 3600;
}

+ (void)invalidateSession_V2:(NSString *)sessionID {
    // Session invalidation logic
}

#pragma mark -  Security Validation Functions (81-90)

+ (BOOL)validateSecurityToken_V2:(NSString *)token {
    return token.length >= 16 && [token containsString:@"-"];
}

+ (NSString *)generateSecurityToken_V2 {
    return [NSString stringWithFormat:@"TOKEN_%08x_%08x", arc4random(), arc4random()];
}

+ (BOOL)verifySecuritySignature_V2:(NSString *)data signature:(NSString *)sig {
    NSString *computed = [self generateChecksum_V2:data];
    return [computed isEqualToString:sig];
}

+ (NSData *)encryptData_V2:(NSData *)data key:(NSString *)key {
    // Encryption logic placeholder
    return data;
}

+ (NSData *)decryptData_V2:(NSData *)data key:(NSString *)key {
    // Decryption logic placeholder
    return data;
}

#pragma mark -  Timestamp Validation Functions (91-100)

+ (BOOL)validateTimestamp_V2:(NSTimeInterval)timestamp {
    return timestamp > 0 && timestamp < [[NSDate date] timeIntervalSince1970] + 86400;
}

+ (NSString *)formatTimestamp_V2:(NSTimeInterval)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter stringFromDate:date];
}

+ (NSTimeInterval)parseTimestamp_V2:(NSString *)timestampStr {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [formatter dateFromString:timestampStr];
    return [date timeIntervalSince1970];
}

+ (BOOL)isTimestampExpired_V2:(NSTimeInterval)timestamp {
    return [[NSDate date] timeIntervalSince1970] > timestamp + 86400;
}

+ (NSTimeInterval)getCurrentTimestamp_V2 {
    return [[NSDate date] timeIntervalSince1970];
}

+ (NSDictionary *)validateTimestampBatch_V2:(NSArray *)timestamps {
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    for (NSNumber *ts in timestamps) {
        results[[ts stringValue]] = @([self validateTimestamp_V2:[ts doubleValue]]);
    }
    return results;
}

+ (NSString *)getTimestampHash_V2:(NSTimeInterval)timestamp {
    return [NSString stringWithFormat:@"%016llx", (unsigned long long)timestamp];
}

+ (BOOL)verifyTimestampSequence_V2:(NSArray *)timestamps {
    if (timestamps.count < 2) return YES;
    for (int i = 1; i < timestamps.count; i++) {
        NSTimeInterval prev = [timestamps[i-1] doubleValue];
        NSTimeInterval curr = [timestamps[i] doubleValue];
        if (curr <= prev) return NO;
    }
    return YES;
}

+ (NSInteger)getTimestampAge_V2:(NSTimeInterval)timestamp {
    return (NSInteger)([[NSDate date] timeIntervalSince1970] - timestamp);
}

+ (BOOL)compareTimestamps_V2:(NSTimeInterval)ts1 ts2:(NSTimeInterval)ts2 {
    return fabs(ts1 - ts2) < 1.0;
}
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
#define RESERVE_SIGNATURE_SIZE 64
#define RESERVE_PADDING_SIZE 32
#define RESERVE_TOTAL_SIZE (RESERVE_SIGNATURE_SIZE + RESERVE_PADDING_SIZE)

#pragma pack(push, 1)
typedef struct {
    unsigned char signature[RESERVE_SIGNATURE_SIZE];
    unsigned char reserved[RESERVE_PADDING_SIZE];
} IntegrityReserve;
#pragma pack(pop)

__attribute__((used))
__attribute__((section("__DATA,__reserved")))
__attribute__((visibility("hidden")))
static IntegrityReserve g_integrityReserve = {{0}, {0}};

__attribute__((visibility("hidden")))
static const unsigned char _urlds[] = {
    0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x9A, 0xC4,
    0xEB, 0x34, 0x6D, 0x83, 0xC8, 0xB5, 0x35, 0x6A, 0x9D, 0x80,
    0xF3, 0x27, 0x72, 0x9A, 0xDA, 0xF8, 0x67, 0x64, 0x97, 0xF2,
    0xFE, 0x2A, 0x4B, 0x9B, 0xC1, 0xFE, 0x0D, 0x00
};

__attribute__((visibility("hidden")))
static NSString* _9jsyfr(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden")))
static NSString* getAesKeyUrls(void) { return _9jsyfr(_urlds); }

static const struct segment_command_64* _findSegment(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSection(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHeader(void);
static NSString* _calculateTextHash(void);
static void data_off_8386(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSegment(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;

    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);

    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;

        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSection(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;

    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);

    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;

        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;

            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));

                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}
__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHeader(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHeader, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }

    uintptr_t selfAddr = (uintptr_t)&_findOwnHeader;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;

        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);

        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }

    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calculateTextHash(void) {
    const struct mach_header_64* header = _findOwnHeader();
    if (!header) {
        return nil;
    }

    const struct segment_command_64* textSeg = _findSegment(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }

    const struct section_64* textSect = _findTextSection(header);
    if (!textSect) {
        return nil;
    }

    if (textSeg->vmsize == 0) {
        return nil;
    }


    uint64_t slide = (uint64_t)header - textSeg->vmaddr;

    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;

    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }

    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);

    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);

    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}
__attribute__((visibility("hidden")))
static void data_off_8386(void) {
    @autoreleasepool {

        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }

        NSString* currentHash = _calculateTextHash();
        if (!currentHash) {
            return;
        }

        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }

        if (![currentHash isEqualToString:storedHash]) {

            NSString* discordUrlStr = getAesKeyUrls();

            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _a1b2c3d4(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden")))
static NSString* getUrls_v1(void) { return _a1b2c3d4(_urlds); }

static const struct segment_command_64* _findSeg_v1(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v1(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v1(void);
static NSString* _calcTextHash_v1(void);
static void data_off_18386(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v1(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v1(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v1(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v1, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v1;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v1(void) {
    const struct mach_header_64* header = _findOwnHdr_v1();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v1(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v1(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_18386(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v1();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v1();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}


__attribute__((visibility("hidden")))
static NSString* _z9x8y7w6(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden")))
static NSString* getUrls_v2(void) { return _z9x8y7w6(_urlds); }

static const struct segment_command_64* _findSeg_v2(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v2(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v2(void);
static NSString* _calcTextHash_v2(void);
static void data_off_28386(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v2(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v2(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v2(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v2, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v2;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v2(void) {
    const struct mach_header_64* header = _findOwnHdr_v2();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v2(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v2(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_28386(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v2();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v2();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _m3n4b5v6(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden")))
static NSString* getUrls_v3(void) { return _m3n4b5v6(_urlds); }

static const struct segment_command_64* _findSeg_v3(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v3(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v3(void);
static NSString* _calcTextHash_v3(void);
static void data_off_38386(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v3(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v3(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v3(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v3, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v3;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v3(void) {
    const struct mach_header_64* header = _findOwnHdr_v3();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v3(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v3(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_38386(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v3();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v3();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _q1w2e3r4(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden")))
static NSString* getUrls_v4(void) { return _q1w2e3r4(_urlds); }

static const struct segment_command_64* _findSeg_v4(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v4(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v4(void);
static NSString* _calcTextHash_v4(void);
static void data_off_48386(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v4(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v4(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v4(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v4, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v4;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v4(void) {
    const struct mach_header_64* header = _findOwnHdr_v4();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v4(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v4(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_48386(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v4();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v4();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _h6g5f4d3(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden")))
static NSString* getUrls_v5(void) { return _h6g5f4d3(_urlds); }

static const struct segment_command_64* _findSeg_v5(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v5(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v5(void);
static NSString* _calcTextHash_v5(void);
static void data_off_58386(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v5(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v5(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v5(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v5, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v5;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v5(void) {
    const struct mach_header_64* header = _findOwnHdr_v5();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v5(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v5(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_58386(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v5();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v5();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}
__attribute__((visibility("hidden"))) static const unsigned char _url1[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xDB, 0xF9, 0x21, 0x63, 0xDD, 0xC0, 0xEC, 0x22, 0x29, 0x91, 0xCF, 0xF1, 0x2F, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url2[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xCD, 0xF2, 0x26, 0x69, 0x97, 0xC2, 0xE8, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url3[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xDB, 0xF9, 0x21, 0x63, 0xDD, 0xD1, 0xEE, 0x24, 0x60, 0x9C, 0xCC, 0xFA, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url4[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xCF, 0xED, 0x21, 0x28, 0x91, 0xC9, 0xF9, 0x28, 0x6D, 0xD8, 0xC2, 0xEA, 0x24, 0x5D, 0x98, 0xC6, 0xB1, 0x2A, 0x55, 0x81, 0xCF, 0xFE, 0x2E, 0x5A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url5[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xC9, 0xF0, 0x3E, 0x6A, 0x9D, 0xC3, 0xFD, 0x64, 0x61, 0x90, 0xD4, 0xF4, 0x2F, 0x40, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_GMVHASH_pv[] = {0x21, 0x18, 0x56, 0xA0, 0xFA, 0xCF, 0x0B, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_unknown[] = {0x33, 0x1B, 0x4B, 0xB1, 0xE5, 0xCE, 0x1A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_comma[] = {0x4A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_placeholder[] = {0x28, 0x3D, 0xE1, 0x45, 0x07, 0xE9, 0x74, 0x68, 0x9B, 0xD4, 0xB8, 0x21, 0xC1, 0x51, 0xC3, 0xBB, 0x92, 0x94, 0x33, 0x0D, 0xE3, 0x67, 0x2A, 0xDD, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_enter_key[] = {0x84, 0xCE, 0x94, 0xDF, 0xFC, 0xEC, 0x3D, 0x23, 0x92, 0x6E, 0x2A, 0x39, 0x65, 0xD1, 0xC2, 0xF3, 0xB7, 0xBF, 0x5D, 0xDF, 0xBA, 0x02, 0x61, 0x8A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_connect_error[] = {0x84, 0xCE, 0x94, 0xDF, 0xE6, 0x78, 0xEF, 0x94, 0x97, 0x8D, 0xF3, 0xB6, 0xB8, 0x4E, 0xD8, 0xBB, 0x38, 0xE4, 0x4B, 0x3E, 0xF3, 0x69, 0x57, 0x96, 0xDC, 0xEB, 0x2D, 0x75, 0xD3, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_invalid_key[] = {0x84, 0xCE, 0x94, 0xDF, 0xE1, 0xFC, 0x2D, 0x23, 0x95, 0xC5, 0x5B, 0xE3, 0x6C, 0x96, 0x8C, 0xF3, 0xB7, 0xBE, 0x53, 0xDF, 0xBA, 0x25, 0xE5, 0x48, 0x29, 0xBD, 0x20, 0x68, 0x13, 0x1B, 0x2B, 0x28, 0x26, 0x31, 0x31, 0x5C, 0xE9, 0x19, 0x9C, 0x42, 0x24, 0xF2, 0x4C, 0xD7, 0xCA, 0x70, 0xF6, 0x9A, 0x98, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_slot_full[] = {0x84, 0xCE, 0x94, 0xDF, 0xE2, 0x78, 0xEE, 0xBC, 0x8A, 0x8D, 0xEB, 0x3B, 0x6D, 0x85, 0x8C, 0xDC, 0x37, 0x68, 0x95, 0x8F, 0xF9, 0x21, 0x6B, 0xD3, 0xE5, 0xF8, 0x31, 0x27, 0x9C, 0x62, 0x3C, 0x32, 0x27, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_key_used[] = {0x2D, 0x30, 0x79, 0xDF, 0x6E, 0x09, 0x97, 0xA0, 0xDE, 0xC9, 0x5B, 0xEE, 0x6C, 0x96, 0x8C, 0xF8, 0x3E, 0x6A, 0xD0, 0xE8, 0xFB, 0x24, 0x61, 0xD3, 0xC5, 0xF5, 0x8B, 0xA6, 0x91, 0x81, 0xEE, 0xAA, 0xBD, 0x66, 0xC9, 0xBE, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_success[] = {0x84, 0xC9, 0x85, 0xDF, 0xFE, 0xF1, 0x97, 0xA3, 0x90, 0xC5, 0xB8, 0x14, 0xC1, 0x45, 0xC2, 0xFC, 0x77, 0x0F, 0xB8, 0x4E, 0x20, 0xE8, 0x6A, 0xC9, 0x8E, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_get_key[] = {0x21, 0x30, 0x74, 0xDF, 0xE1, 0xFC, 0x2D, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_check_key[] = {0x25, 0x3D, 0x65, 0x9C, 0xC1, 0xB9, 0x1F, 0x66, 0x87, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_paste[] = {0x22, 0x96, 0xA1, 0x91, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_update_title[] = {0x96, 0xCA, 0x9A, 0x7F, 0x8A, 0xDB, 0xB5, 0xB9, 0x5D, 0xC2, 0xB8, 0x03, 0x70, 0x32, 0x14, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_update_btn[] = {0x25, 0xB4, 0xBA, 0x52, 0xDA, 0xB9, 0x1A, 0x6B, 0x1F, 0x17, 0x35, 0x23, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_udid_title[] = {0x3E, 0x96, 0x81, 0xBC, 0x8A, 0xD4, 0x1D, 0x4D, 0xB6, 0x8D, 0xCD, 0x13, 0x4B, 0xB5, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_udid_msg[] = {0x30, 0x20, 0x69, 0xDF, 0xC6, 0x5A, 0xE6, 0x6D, 0x99, 0x8D, 0xDB, 0x3B, 0x6B, 0x92, 0xC7, 0xBB, 0x1A, 0xE4, 0x4A, 0x0A, 0xE3, 0x69, 0x51, 0xB7, 0xE7, 0xD9, 0x68, 0xC3, 0x63, 0x40, 0x27, 0xC8, 0x26, 0x96, 0x63, 0x3F, 0x23, 0x19, 0x30, 0x32, 0x7F, 0xF7, 0x8F, 0x83, 0x82, 0xF9, 0xAD, 0x80, 0x65, 0x85, 0xE3, 0x89, 0x9B, 0xC9, 0xDC, 0x50, 0xEF, 0x5E, 0xC8, 0xCA, 0xFB, 0x2F, 0x54, 0xCB, 0xD2, 0xFD, 0x29, 0xDE, 0x50, 0x66, 0xE0, 0x63, 0x5C, 0x0C, 0x63, 0x1C, 0x6C, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_udid_btn[] = {0x25, 0x39, 0x69, 0x9C, 0xC1, 0xB9, 0x18, 0xE2, 0x44, 0x08, 0xE1, 0x77, 0x57, 0xB5, 0xE5, 0xDF, 0x76, 0x2D, 0xA3, 0xCE, 0xFC, 0x28, 0x76, 0x9A, 0x87, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_waiting_title[] = {0x84, 0xCC, 0xBB, 0x10, 0x12, 0x16, 0x74, 0xC7, 0x6E, 0xEC, 0xD6, 0x10, 0x22, 0xB2, 0xE4, 0x7A, 0xED, 0x99, 0xD0, 0xF7, 0x59, 0xC8, 0x47, 0xD3, 0xE3, 0xD4, 0x06, 0x4F, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_waiting_msg[] = {0xA2, 0xC5, 0x61, 0x91, 0xCD, 0xB9, 0x37, 0x6B, 0x1F, 0x16, 0x05, 0x77, 0x61, 0x32, 0x0C, 0xF2, 0x76, 0xC1, 0x61, 0x4E, 0x20, 0xFE, 0x70, 0xD3, 0xEA, 0xD3, 0x1B, 0x27, 0xA2, 0xD3, 0xF3, 0x2D, 0x6F, 0x99, 0xC5, 0xBF, 0x1F, 0x7D, 0xBD, 0xE7, 0xBE, 0x3B, 0xFB, 0x57, 0x82, 0xE9, 0x8F, 0x9A, 0x95, 0x85, 0xFD, 0x26, 0x54, 0x81, 0x84, 0xE7, 0x3C, 0x52, 0x86, 0xC0, 0xB2, 0x02, 0xFF, 0x4B, 0xCF, 0xB5, 0x84, 0xAE, 0x0B, 0x63, 0x23, 0x37, 0x10, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_ok_btn[] = {0x29, 0x1E, 0x20, 0xB3, 0xDF, 0x5A, 0xE0, 0x6D, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_GMVHASH_title[] = {0x96, 0xCA, 0x94, 0x5A, 0x8A, 0xDE, 0x19, 0x55, 0xDE, 0xE0, 0xD7, 0x15, 0x43, 0xD1, 0x5C, 0x04, 0xC2, 0xA0, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url_param1[] = {0x43, 0x15, 0x3F, 0x9D, 0xC3, 0xFD, 0x69, 0x26, 0xBE, 0x8B, 0xF6, 0x36, 0x6F, 0x94, 0x91, 0xBE, 0x16, 0x23, 0x85, 0xCB, 0xF3, 0x2D, 0x39, 0xD6, 0xEE, 0xBB, 0x3E, 0x62, 0x80, 0x9C, 0xB9, 0x0B, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url_param2[] = {0x01, 0x34, 0x6D, 0x9A, 0x97, 0xBC, 0x14, 0x25, 0x8B, 0xDE, 0xFD, 0x25, 0x5D, 0x9A, 0xC9, 0xE2, 0x6B, 0x20, 0xB0, 0x89, 0xE9, 0x2C, 0x76, 0x9A, 0xCF, 0xF1, 0x75, 0x22, 0xB2, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _bid_fallback[] = {0x05, 0x3A, 0x6D, 0xD1, 0xCD, 0xF4, 0x22, 0x2D, 0x8B, 0xC3, 0xF3, 0x39, 0x6D, 0x86, 0xC2, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_update_link[] = {0x13, 0x25, 0x64, 0x9E, 0xDE, 0xFC, 0x0B, 0x6F, 0x97, 0xC3, 0xF3, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_update_msg[] = {0x13, 0x25, 0x64, 0x9E, 0xDE, 0xFC, 0x0B, 0x6E, 0x8D, 0xCA, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_require_key[] = {0x14, 0x30, 0x71, 0x8A, 0xC3, 0xEB, 0x31, 0x5C, 0x95, 0xC8, 0xE1, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_status[] = {0x15, 0x21, 0x61, 0x8B, 0xDF, 0xEA, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_reason[] = {0x14, 0x30, 0x61, 0x8C, 0xC5, 0xF7, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_device_used[] = {0x02, 0x30, 0x76, 0x96, 0xC9, 0xFC, 0x0B, 0x76, 0x8D, 0xC8, 0xFC, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_device[] = {0x02, 0x30, 0x76, 0x96, 0xC9, 0xFC, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_data[] = {0x02, 0x34, 0x74, 0x9E, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_exp[] = {0x23, 0x0D, 0x50, 0x00};

__attribute__((visibility("hidden"))) static const unsigned char _cls_rotate[] = {0x39, 0x23, 0x67, 0xcd, 0xc5, 0xf7, 0x62, 0x77, 0xcb, 0xda, 0xf7, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _cls_paste[] = {0x39, 0x6c, 0x72, 0x8f, 0xcd, 0xf8, 0x26, 0x31, 0x96, 0xca, 0xf3, 0x00};

#define GAME_NAME @"PUBG"
#define ZALO_INFO @"૮₍´˶• . • ⑅ ₎ა"


__attribute__((visibility("hidden"))) static NSString* _f9a1c(const unsigned char *p) {
    data_off_8386();
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    data_off_58386();
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden"))) static NSString* _fb2d0(void) { return _f9a1c(_url1); }
__attribute__((visibility("hidden"))) static NSString* _fc3e1(void) { return _f9a1c(_url2); }
__attribute__((visibility("hidden"))) static NSString* _fd4f2(void) { return _f9a1c(_url3); }
__attribute__((visibility("hidden"))) static NSString* _fe503(void) { return _f9a1c(_url5); }
__attribute__((visibility("hidden"))) static NSString* _ff614(void) { return _f9a1c(_url4); }
__attribute__((visibility("hidden"))) static NSString* _f0725(void) { return _f9a1c(_str_unknown); }
__attribute__((visibility("hidden"))) static NSString* _f1836(void) { return _f9a1c(_str_comma); }
__attribute__((visibility("hidden"))) static NSString* _f2947(void) { return _f9a1c(_str_GMVHASH_pv); }
__attribute__((visibility("hidden"))) static NSString* _f3a58(void) { return _f9a1c(_str_placeholder); }
__attribute__((visibility("hidden"))) static NSString* _f4b69(void) { return _f9a1c(_msg_enter_key); }
__attribute__((visibility("hidden"))) static NSString* _f5c7a(void) { return _f9a1c(_msg_connect_error); }
__attribute__((visibility("hidden"))) static NSString* _f6d8b(void) { return _f9a1c(_msg_invalid_key); }
__attribute__((visibility("hidden"))) static NSString* _f7e9c(void) { return _f9a1c(_msg_slot_full); }
__attribute__((visibility("hidden"))) static NSString* _f8fad(void) { return _f9a1c(_msg_key_used); }
__attribute__((visibility("hidden"))) static NSString* _f900e(void) { return _f9a1c(_msg_success); }
__attribute__((visibility("hidden"))) static NSString* _fa11f(void) { return _f9a1c(_msg_get_key); }
__attribute__((visibility("hidden"))) static NSString* _fb220(void) { return _f9a1c(_msg_check_key); }
__attribute__((visibility("hidden"))) static NSString* _fc331(void) { return _f9a1c(_msg_paste); }
__attribute__((visibility("hidden"))) static NSString* _fd442(void) { return _f9a1c(_msg_update_title); }
__attribute__((visibility("hidden"))) static NSString* _fe553(void) { return _f9a1c(_msg_update_btn); }
__attribute__((visibility("hidden"))) static NSString* _ff664(void) { return _f9a1c(_msg_udid_title); }
__attribute__((visibility("hidden"))) static NSString* _f0775(void) { return _f9a1c(_msg_udid_msg); }
__attribute__((visibility("hidden"))) static NSString* _f1886(void) { return _f9a1c(_msg_udid_btn); }
__attribute__((visibility("hidden"))) static NSString* _f2997(void) { return _f9a1c(_msg_waiting_title); }
__attribute__((visibility("hidden"))) static NSString* _f3aa8(void) { return _f9a1c(_msg_waiting_msg); }
__attribute__((visibility("hidden"))) static NSString* _f4bb9(void) { return _f9a1c(_msg_ok_btn); }
__attribute__((visibility("hidden"))) static NSString* _f5cca(void) { return _f9a1c(_msg_GMVHASH_title); }
__attribute__((visibility("hidden"))) static NSString* _f6ddb(void) { return _f9a1c(_url_param1); }
__attribute__((visibility("hidden"))) static NSString* _f7eec(void) { return _f9a1c(_url_param2); }
__attribute__((visibility("hidden"))) static NSString* _f8ffd(void) { return _f9a1c(_bid_fallback); }
__attribute__((visibility("hidden"))) static NSString* _f900f(void) { return _f9a1c(_key_update_link); }
__attribute__((visibility("hidden"))) static NSString* _fa120(void) { return _f9a1c(_key_update_msg); }
__attribute__((visibility("hidden"))) static NSString* _fb231(void) { return _f9a1c(_key_require_key); }
__attribute__((visibility("hidden"))) static NSString* _fc342(void) { return _f9a1c(_key_status); }
__attribute__((visibility("hidden"))) static NSString* _fd453(void) { return _f9a1c(_key_reason); }
__attribute__((visibility("hidden"))) static NSString* _fe564(void) { return _f9a1c(_key_device_used); }
__attribute__((visibility("hidden"))) static NSString* _ff675(void) { return _f9a1c(_key_device); }
__attribute__((visibility("hidden"))) static NSString* _f0786(void) { return _f9a1c(_key_data); }
__attribute__((visibility("hidden"))) static NSString* _f1897(void) { return _f9a1c(_key_exp); }

__attribute__((visibility("hidden"))) static NSString* _f29a8(void) { return @"GMVHASH_UDID_DEVICE"; }
__attribute__((visibility("hidden"))) static NSString* _f3ab9(NSString *k) {
    volatile int _j1 = 41; volatile int _j2 = _j1 ^ 17; (void)_j2;
    return [NSString stringWithFormat:@"GMVHASH_TRK_%@", k];
}

static const unsigned char _sel_mainBundle[] = {0xb, 0x34, 0x69, 0x91, 0xe8, 0xec, 0x3a, 0x67, 0x92, 0xc8, 0x00};
static const unsigned char _sel_bundleId[] = {0x4, 0x20, 0x6e, 0x9b, 0xc6, 0xfc, 0x1d, 0x67, 0x9b, 0xc3, 0xec, 0x3e, 0x64, 0x98, 0xc9, 0xe9, 0x00};
static const unsigned char _sel_mutCopy[] = {0xb, 0x20, 0x74, 0x9e, 0xc8, 0xf5, 0x31, 0x40, 0x91, 0xdd, 0xe1, 0x00};
static const unsigned char _sel_invSet[] = {0xf, 0x3b, 0x76, 0x9a, 0xd8, 0xed, 0x31, 0x67, 0xad, 0xc8, 0xec, 0x00};
static const unsigned char _sel_charSetWith[] = {0x5, 0x3d, 0x61, 0x8d, 0xcb, 0xfa, 0x20, 0x66, 0x8c, 0xfe, 0xfd, 0x23, 0x55, 0x98, 0xd8, 0xf3, 0x15, 0x6d, 0x91, 0xdd, 0xfb, 0x2a, 0x70, 0x96, 0xdc, 0xee, 0x01, 0x69, 0xa1, 0xd5, 0xee, 0x22, 0x68, 0x92, 0x9a, 0x00};
static const unsigned char _sel_compSepBy[] = {0x5, 0x3a, 0x6d, 0x8f, 0xc5, 0xf7, 0x31, 0x6d, 0x8a, 0xde, 0xcb, 0x32, 0x72, 0x90, 0xde, 0xfa, 0x22, 0x60, 0x94, 0xed, 0xe3, 0x0a, 0x6c, 0x92, 0xdc, 0xfc, 0x2b, 0x73, 0x97, 0xd3, 0xef, 0x02, 0x68, 0xa6, 0xc5, 0xeb, 0x70, 0x00};
static const unsigned char _sel_compJoinBy[] = {0x5, 0x3a, 0x6d, 0x8f, 0xc5, 0xf7, 0x31, 0x6d, 0x8a, 0xde, 0xd2, 0x38, 0x6b, 0x9f, 0xc9, 0xff, 0x14, 0x7c, 0xa3, 0xdb, 0xe8, 0x20, 0x6a, 0x94, 0x94, 0x00};

static inline SEL _selOf(const unsigned char *enc) {
    return NSSelectorFromString(_f9a1c(enc));
}

static const unsigned char _sel_objForKey[] = {0x9, 0x37, 0x6a, 0x9a, 0xc9, 0xed, 0x12, 0x6c, 0x8c, 0xe6, 0xfd, 0x2e, 0x67, 0x95, 0xff, 0xee, 0x34, 0x76, 0x93, 0xdd, 0xf3, 0x39, 0x70, 0xc9, 0x00};
static const unsigned char _sel_boolVal[] = {0x4, 0x3a, 0x6f, 0x93, 0xfc, 0xf8, 0x38, 0x76, 0x9b, 0x00};
static const unsigned char _sel_intVal[] = {0xf, 0x3b, 0x74, 0xa9, 0xcb, 0xf5, 0x21, 0x66, 0x00};

static inline id _jGet(id dict, NSString *key) {
    return ((id(*)(id, SEL, id))objc_msgSend)(dict, _selOf(_sel_objForKey), key);
}
static inline BOOL _jBool(id x) {
    return ((BOOL(*)(id, SEL))objc_msgSend)(x, _selOf(_sel_boolVal));
}
static inline NSInteger _jInt(id x) {
    return ((NSInteger(*)(id, SEL))objc_msgSend)(x, _selOf(_sel_intVal));
}

__attribute__((visibility("hidden"))) static NSString* _f4bca(void) {
    data_off_8386();
    id bundleCls = objc_getClass("NSBundle");
    id bundle = ((id(*)(id, SEL))objc_msgSend)(bundleCls, _selOf(_sel_mainBundle));
    id rawBid = ((id(*)(id, SEL))objc_msgSend)(bundle, _selOf(_sel_bundleId));
    NSString *bid = rawBid ?: _f8ffd();

    NSMutableString *ms = ((id(*)(id, SEL))objc_msgSend)(bid, _selOf(_sel_mutCopy));
    CFStringTransform((__bridge CFMutableStringRef)ms, NULL, kCFStringTransformStripDiacritics, NO);

    id charSetCls = objc_getClass("NSCharacterSet");
    NSString *allowedChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.";
    NSCharacterSet *allowed = ((id(*)(id, SEL, id))objc_msgSend)(charSetCls, _selOf(_sel_charSetWith), allowedChars);
    id inverted = ((id(*)(id, SEL))objc_msgSend)(allowed, _selOf(_sel_invSet));
    id parts = ((id(*)(id, SEL, id))objc_msgSend)(ms, _selOf(_sel_compSepBy), inverted);
    id joined = ((id(*)(id, SEL, id))objc_msgSend)(parts, _selOf(_sel_compJoinBy), @"");
    data_off_18386();
    return joined;
}

__attribute__((visibility("hidden"))) static NSString* _f5cdb(void) {
    return [NSString stringWithFormat:@"%@%@", _f2947(), _f4bca()];
}


static BOOL _f6dec_shouldAutorotate(id self, SEL _cmd) { return YES; }
static NSUInteger _f7edf_orientMask(id self, SEL _cmd) { return UIInterfaceOrientationMaskLandscape; }
static NSInteger _f8fe0_preferredOrient(id self, SEL _cmd) { return UIInterfaceOrientationLandscapeRight; }
static void _f900f_viewWillLayout(id self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void(*)(struct objc_super*, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *v = ((id(*)(id, SEL))objc_msgSend)(self, @selector(view));
    UIWindow *w = ((id(*)(id, SEL))objc_msgSend)(v, @selector(window));
    if (w) {
        CGRect b = ((CGRect(*)(id, SEL))objc_msgSend)(w, @selector(bounds));
        ((void(*)(id, SEL, CGRect))objc_msgSend)(v, @selector(setFrame:), b);
    }
}

static Class _f0721_registerRotateClass(void) {
    data_off_8386();
    NSString *name = _f9a1c(_cls_rotate);
    Class existing = NSClassFromString(name);
    if (existing) return existing;
    data_off_28386();
    Class cls = objc_allocateClassPair([UIViewController class], [name UTF8String], 0);
    class_addMethod(cls, @selector(shouldAutorotate), (IMP)_f6dec_shouldAutorotate, "c@:");
    class_addMethod(cls, @selector(supportedInterfaceOrientations), (IMP)_f7edf_orientMask, "Q@:");
    class_addMethod(cls, @selector(preferredInterfaceOrientationForPresentation), (IMP)_f8fe0_preferredOrient, "q@:");
    class_addMethod(cls, @selector(viewWillLayoutSubviews), (IMP)_f900f_viewWillLayout, "v@:");
    objc_registerClassPair(cls);
    return cls;
}

static void _f1832_handlePaste(id self, SEL _cmd, UIButton *sender) {
    UITextField *t = (UITextField *)objc_getAssociatedObject(sender, "targetField");
    if (t) t.text = [UIPasteboard generalPasteboard].string;
}

static Class _f2943_registerPasteClass(void) {
    NSString *name = _f9a1c(_cls_paste);
    Class existing = NSClassFromString(name);
    if (existing) return existing;

    Class cls = objc_allocateClassPair([NSObject class], [name UTF8String], 0);
    class_addMethod(object_getClass(cls), @selector(handlePaste:), (IMP)_f1832_handlePaste, "v@:@");
    objc_registerClassPair(cls);
    return cls;
}

typedef struct {
    UIWindow *w;
    UIVisualEffectView *bv;
    BOOL checking;
    BOOL dialogVisible;
    BOOL lastRequireKey;
    NSTimer *timer;
} _St;

__attribute__((visibility("hidden"))) static _St _gs = {0};
__attribute__((visibility("hidden"))) static UIAlertController *_gAlert = nil;

__attribute__((visibility("hidden"))) static void _f3a54(NSString *k);
__attribute__((visibility("hidden"))) static void _f4b65(NSString *k);
__attribute__((visibility("hidden"))) static void _f5c76(NSString *l, NSString *m);
__attribute__((visibility("hidden"))) static void _f6d87(NSString *initialKey);
__attribute__((visibility("hidden"))) static void _f7e98(void);
__attribute__((visibility("hidden"))) static void _f8fa9(void);

__attribute__((visibility("hidden"))) static NSMutableArray* _f900a(NSString *key) {
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f3ab9(key),
        (__bridge id)kSecReturnData: @YES
    };
    CFTypeRef ref = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &ref) == errSecSuccess) {
        NSData *d = (__bridge_transfer NSData *)ref;
        NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
        return [[s componentsSeparatedByString:_f1836()] mutableCopy];
    }
    return [NSMutableArray array];
}

__attribute__((visibility("hidden"))) static void _fa11b(NSArray *bids, NSString *key) {
    NSString *s = [bids componentsJoinedByString:_f1836()];
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f3ab9(key)
    };
    SecItemDelete((__bridge CFDictionaryRef)q);
    NSMutableDictionary *m = [q mutableCopy];
    [m setObject:d forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)m, NULL);
}

__attribute__((visibility("hidden"))) static void _fb22c(NSString *key) {
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f3ab9(key)
    };
    SecItemDelete((__bridge CFDictionaryRef)q);
}

__attribute__((visibility("hidden"))) static void _fc33d(NSString *key) {
    if (!key) return;
    NSData *kd = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *pq = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f5cdb()
    };
    SecItemDelete((__bridge CFDictionaryRef)pq);
    NSMutableDictionary *p = [pq mutableCopy];
    [p setObject:kd forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)p, NULL);
}

__attribute__((visibility("hidden"))) static NSString* _fd44e(void) {
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f5cdb(),
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    CFTypeRef ref = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &ref) == errSecSuccess) {
        NSData *d = (__bridge_transfer NSData *)ref;
        return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    }
    return nil;
}

__attribute__((visibility("hidden"))) static void _fe55f(void) {
    if (!_gs.w) {
        _gs.w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _gs.w.windowLevel = UIWindowLevelStatusBar + 999.0;

        Class rotateCls = _f0721_registerRotateClass();
        _gs.w.rootViewController = [[rotateCls alloc] init];
        _gs.w.backgroundColor = [UIColor clearColor];

        UIBlurEffect *be = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _gs.bv = [[UIVisualEffectView alloc] initWithEffect:be];

        CGRect sr = [UIScreen mainScreen].bounds;
        CGFloat side = MAX(sr.size.width, sr.size.height) * 1.5;
        _gs.bv.frame = CGRectMake(0, 0, side, side);
        _gs.bv.center = _gs.w.center;
        _gs.bv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _gs.bv.alpha = 0.0;

        UIView *ov = [[UIView alloc] initWithFrame:_gs.bv.bounds];
        ov.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [_gs.bv.contentView addSubview:ov];
        [_gs.w.rootViewController.view addSubview:_gs.bv];

        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
                if (sc.activationState == UISceneActivationStateForegroundActive) {
                    _gs.w.windowScene = sc;
                    break;
                }
            }
        }
    }
}

__attribute__((visibility("hidden"))) static void _ff660(BOOL a) {
    [UIView animateWithDuration:0.3 animations:^{ _gs.bv.alpha = a ? 1.0 : 0.0; }];
}

__attribute__((visibility("hidden"))) static void _f0771(void) {
    data_off_8386();
    _gs.dialogVisible = NO;
    _ff660(NO);
    data_off_48386();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _gs.w.hidden = YES;
    });
}

__attribute__((visibility("hidden"))) static void _f1882(NSString *msg) {
    data_off_8386();
    dispatch_async(dispatch_get_main_queue(), ^{
        _fe55f();
        _gs.w.hidden = NO;
        UIAlertController *t = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
        [_gs.w.rootViewController presentViewController:t animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [t dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

__attribute__((visibility("hidden"))) static void _f2993(NSString *userKey, NSDictionary *json) {
    data_off_8386();
    _fc33d(userKey);
    NSString *exp = _jGet(_jGet(json, _f0786()), _f1897()) ?: @"N/A";
    _f1882([NSString stringWithFormat:@"%@%@", _f900e(), exp]);

    if (!_gs.timer || ![_gs.timer isValid]) {
        __block void (^blk)(void) = ^{
            NSString *sk = _fd44e();
            if (sk && sk.length > 1) {
                _f4b65(sk);
            } else if (_gs.timer) {
                [_gs.timer invalidate];
                _gs.timer = nil;
            }
        };
        _gs.timer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                       target:[NSBlockOperation blockOperationWithBlock:blk]
                                                     selector:@selector(main)
                                                     userInfo:nil
                                                      repeats:YES];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ _f0771(); });
}

__attribute__((visibility("hidden"))) static void _f3a54(NSString *userKey) {
    data_off_8386();
    if (!userKey || userKey.length < 2) {
        _f1882(_f4b69());
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            _gs.dialogVisible = NO;
            _f6d87(nil);
        });
        return;
    }

    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:_f29a8()] ?: _f0725();
    NSString *base = _fc3e1();
    NSString *fmt = _f7eec();

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:base]];
    req.HTTPMethod = @"POST";
    NSString *params = [NSString stringWithFormat:fmt, GAME_NAME, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err || !data) {
                _f1882(_f5c7a());
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    _gs.dialogVisible = NO;
                    _f6d87(userKey);
                });
                return;
            }

            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json) return;

            NSString *reason = _jGet(json, _fd453()) ?: _f6d8b();

            BOOL statusVal = _jBool(_jGet(json, _fc342()));
            intptr_t addrMix = (intptr_t)(__bridge void*)json;
            int chk = (int)(addrMix & 0xF);
            BOOL gate = ((chk * chk) >= 0) ? statusVal : !statusVal;

            if (gate) {
                int used = (int)_jInt(_jGet(_jGet(json, _f0786()), _fe564()));
                int maxSlot = (int)_jInt(_jGet(_jGet(json, _f0786()), _ff675()));
                NSString *bid = _f4bca();
                NSMutableArray *saved = _f900a(userKey);

                if (used == 0 && saved.count > 0) {
                    _fb22c(userKey);
                    [saved removeAllObjects];
                }

                if ([saved containsObject:bid]) {
                    _f2993(userKey, json);
                } else if (saved.count < maxSlot) {
                    [saved addObject:bid];
                    _fa11b(saved, userKey);
                    _f2993(userKey, json);
                } else {
                    _f1882([NSString stringWithFormat:@"%@\n%@", _f7e9c(), _f8fad()]);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        _gs.dialogVisible = NO;
                        _f6d87(userKey);
                    });
                }
            } else {
                _f1882([NSString stringWithFormat:@"⛔ %@", reason]);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    _gs.dialogVisible = NO;
                    _f6d87(userKey);
                });
            }
        });
    }] resume];
}

__attribute__((visibility("hidden"))) static void _f4b65(NSString *userKey) {
    data_off_8386();
    if (!userKey || userKey.length < 2) return;

    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:_f29a8()] ?: _f0725();
    NSString *base = _fc3e1();
    NSString *fmt = _f7eec();

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:base]];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 10.0;
    NSString *params = [NSString stringWithFormat:fmt, GAME_NAME, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (err || !data) return;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (!_jBool(_jGet(json, _fc342()))) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_gs.timer) { [_gs.timer invalidate]; _gs.timer = nil; }
                NSString *reason = _jGet(json, _fd453()) ?: _f6d8b();
                _f1882([NSString stringWithFormat:@"⛔ %@", reason]);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    _fe55f();
                    _gs.w.hidden = NO;
                    [_gs.w makeKeyAndVisible];
                    _gs.dialogVisible = NO;
                    _f6d87(userKey);
                });
            });
        }
    }] resume];
}

__attribute__((visibility("hidden"))) static void _f6d87(NSString *initialKey) {
    data_off_8386();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_gs.dialogVisible) return;

        _fe55f();
        _gs.w.hidden = NO;
        _gs.w.userInteractionEnabled = YES;
        _ff660(YES);
        _gs.dialogVisible = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:_f5cca() message:nil preferredStyle:UIAlertControllerStyleAlert];

        NSString *msg = ZALO_INFO;
        NSMutableAttributedString *am = [[NSMutableAttributedString alloc] initWithString:msg];
        [am addAttribute:NSForegroundColorAttributeName value:[UIColor systemGreenColor] range:NSMakeRange(0, msg.length)];
        [alert setValue:am forKey:@"attributedMessage"];

        Class pasteCls = _f2943_registerPasteClass();

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = _f3a58();
            tf.textAlignment = NSTextAlignmentCenter;
            tf.text = initialKey ?: _fd44e();

            UIButton *pb = [UIButton buttonWithType:UIButtonTypeSystem];
            [pb setTitle:_fc331() forState:UIControlStateNormal];
            pb.frame = CGRectMake(0, 0, 45, 30);
            [pb addTarget:pasteCls action:@selector(handlePaste:) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(pb, "targetField", tf, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            tf.rightView = pb;
            tf.rightViewMode = UITextFieldViewModeAlways;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:_fa11f() style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_fe503()] options:@{} completionHandler:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                _gs.dialogVisible = NO;
                _f6d87(nil);
            });
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:_fb220() style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            _gs.dialogVisible = NO;
            _f3a54(alert.textFields.firstObject.text);
        }]];

        [_gs.w.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((visibility("hidden"))) static void _f5c76(NSString *link, NSString *msg) {
    data_off_8386();
    _fe55f();
    _gs.w.hidden = NO;
    _ff660(YES);

    _gAlert = [UIAlertController alertControllerWithTitle:_fd442() message:msg preferredStyle:UIAlertControllerStyleAlert];
    [_gAlert addAction:[UIAlertAction actionWithTitle:_fe553() style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link] options:@{} completionHandler:^(BOOL ok) {
            exit(0);
        }];
    }]];
    [_gs.w.rootViewController presentViewController:_gAlert animated:YES completion:nil];
}

__attribute__((visibility("hidden"))) static void _f7e98(void) {
    data_off_8386();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_gs.dialogVisible) return;

        _fe55f();
        _gs.w.hidden = NO;
        _ff660(YES);
        _gs.dialogVisible = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:_ff664() message:_f0775() preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *act = [UIAlertAction actionWithTitle:_f1886() style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_fd4f2()] options:@{} completionHandler:^(BOOL ok) {
                if (ok) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        UIAlertController *wa = [UIAlertController alertControllerWithTitle:_f2997() message:_f3aa8() preferredStyle:UIAlertControllerStyleAlert];
                        [wa addAction:[UIAlertAction actionWithTitle:_f4bb9() style:UIAlertActionStyleDefault handler:^(UIAlertAction *a2) {
                            _f0771();
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ exit(0); });
                        }]];
                        [_gs.w.rootViewController presentViewController:wa animated:YES completion:nil];
                    });
                }
            }];
        }];

        [alert addAction:act];
        [_gs.w.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((visibility("hidden"))) static void _f8fa9(void) {
    data_off_8386();
    NSString *api = _fb2d0();
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:api] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err || !data) { _f7e98(); return; }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json || !_jBool(_jGet(json, _fc342())) || !_jGet(json, @"udid")) { _f7e98(); return; }

            NSString *udid = _jGet(json, @"udid");
            [[NSUserDefaults standardUserDefaults] setObject:udid forKey:_f29a8()];
            [[NSUserDefaults standardUserDefaults] synchronize];

            NSString *sk = _fd44e();
            if (sk) { _f3a54(sk); } else { _f6d87(nil); }
        });
    }] resume];
}

__attribute__((visibility("hidden"))) static void _f900b(void) {
    data_off_8386();
    if (_gs.checking) return;
    _gs.checking = YES;
            data_off_28386();

    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0.0";
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:_f29a8()] ?: _f0725();
    NSString *rawBid = _f4bca();
    NSString *encBid = [rawBid stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *server = _ff614();
    NSString *fmt = _f6ddb();

    NSString *urlStr = [NSString stringWithFormat:fmt, server, encBid,
                        [GAME_NAME stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                        udid, ver];

    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) { _gs.checking = NO; return; }

    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _gs.checking = NO;
            if (err || !data) return;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json) return;

            BOOL forceUpdate = _jBool(_jGet(json, @"force_update"));
            BOOL requireKey = _jGet(json, _fb231()) ? _jBool(_jGet(json, _fb231())) : YES;

            if (forceUpdate) {
                NSString *link = _jGet(json, _f900f()) ?: @"";
                NSString *msg = _jGet(json, _fa120()) ?: @"Update required";
                if (!_gAlert) {
                    [_gs.w.rootViewController dismissViewControllerAnimated:NO completion:nil];
                    _f5c76(link, msg);
                }
                return;
            } else if (_gAlert) {
                [_gAlert dismissViewControllerAnimated:YES completion:nil];
                _gAlert = nil;
                _f0771();
            }

            if (!requireKey) {
                _gs.lastRequireKey = NO;
                _f0771();
                return;
            }

            _gs.lastRequireKey = YES;
            if (!_gs.dialogVisible) { _f8fa9(); }
        });
    }] resume];
}
__attribute__((visibility("hidden"))) __attribute__((constructor))
static void _finit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _f900b();
        data_off_8386();
    });
}


