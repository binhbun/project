#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
// FAKE CLASS IMPLEMENTATION
// ============================================================

@interface AnhvuAuthFake : NSObject
+ (instancetype)shareInstance;
- (NSString *)getDeviceModel;
- (NSString *)getDeviceUUID;
- (NSString *)getKey;
- (NSDate *)getExpirationDate;
- (BOOL)isActivated;
- (void)packages:(NSString *)pkg onAuthenticated:(void (^)(void))callback;
@end

@implementation AnhvuAuthFake

static AnhvuAuthFake *sharedInstance = nil;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        NSLog(@"[Bypass] Fake AnhvuAuth instance created");
    });
    return sharedInstance;
}

- (NSString *)getDeviceModel {
    return @"iPhone16,2";
}

- (NSString *)getDeviceUUID {
    return @"F0A1B2C3-D4E5-6789-ABCD-EF0123456789";
}

- (NSString *)getKey {
    return @"VALID_AUTH_KEY_2026_XYZ_ABC_DEF_GHI_JKL";
}

- (NSDate *)getExpirationDate {
    return [NSDate dateWithTimeIntervalSinceNow:10 * 365 * 24 * 60 * 60];
}

- (BOOL)isActivated {
    return YES;
}

- (void)packages:(NSString *)pkg onAuthenticated:(void (^)(void))callback {
    NSLog(@"[Bypass] packages called with pkg: %@", pkg);
    if (callback) {
        NSLog(@"[Bypass] Calling authentication callback immediately");
        callback();
    }
}

@end

// ============================================================
// SWIZZLE FUNCTIONS
// ============================================================

static void swizzleMethod(Class targetClass, Class fakeClass, SEL selector) {
    Method originalMethod = class_getClassMethod(targetClass, selector);
    Method fakeMethod = class_getClassMethod(fakeClass, selector);
    
    if (!originalMethod) {
        originalMethod = class_getInstanceMethod(targetClass, selector);
        fakeMethod = class_getInstanceMethod(fakeClass, selector);
    }
    
    if (originalMethod && fakeMethod) {
        method_exchangeImplementations(originalMethod, fakeMethod);
        NSLog(@"[Bypass] Swizzled: %@", NSStringFromSelector(selector));
    }
}

// ============================================================
// CONSTRUCTOR - CHẠY KHI DYLIB ĐƯỢC LOAD
// ============================================================

__attribute__((constructor))
static void bypass_init() {
    NSLog(@"[Bypass] Dylib loaded!");
    
    Class targetClass = objc_getClass("AnhvuAuth");
    Class fakeClass = objc_getClass("AnhvuAuthFake");
    
    if (!targetClass || !fakeClass) {
        NSLog(@"[Bypass] Cannot find classes!");
        return;
    }
    
    // Swizzle tất cả methods cần thiết
    NSArray *methods = @[
        @"shareInstance",
        @"getDeviceModel",
        @"getDeviceUUID",
        @"getKey",
        @"getExpirationDate",
        @"isActivated",
        @"packages:onAuthenticated:"
    ];
    
    for (NSString *methodName in methods) {
        SEL selector = NSSelectorFromString(methodName);
        if (selector) {
            swizzleMethod(targetClass, fakeClass, selector);
        }
    }
    
    NSLog(@"[Bypass] All hooks installed!");
}
