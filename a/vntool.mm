#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Security/Security.h>

static id (*orig_fetch)(id self, SEL _cmd, id a3);
static id (*orig_getJSON)(id self, SEL _cmd, id a3, long long *a4);
static BOOL (*orig_patch)(id self, SEL _cmd, id a3, id a4, long long a5);
static long long (*orig_maintenance)(id self, SEL _cmd, id *a3);
static long long (*orig_verify)(id self, SEL _cmd, id a3);
static id (*orig_loadKey)(id self, SEL _cmd);
static void (*orig_saveKey)(id self, SEL _cmd, id a3);
static void (*orig_forgetKey)(id self, SEL _cmd);
static id (*orig_parseISO)(id self, SEL _cmd, id a3);
static id (*orig_objectForKeyedSubscript)(id self, SEL _cmd, id key);

#define ONE_YEAR_SECONDS (365 * 24 * 60 * 60)
#define ONE_HUNDRED_YEARS_SECONDS (100LL * ONE_YEAR_SECONDS)

static long long fixed_verify(id self, SEL _cmd, id a3) {
    NSLog(@"[Bypass] ✅ License verification bypassed");
    return 0;
}

static id fixed_fetch(id self, SEL _cmd, id a3) {
    NSLog(@"[Bypass] ✅ fetch: bypassed with fake license (input: %@)", a3);
    
    @autoreleasepool {
        NSMutableDictionary *fakeLicense = [NSMutableDictionary dictionary];
        
        NSMutableDictionary *license = [NSMutableDictionary dictionary];
        license[@"key"] = @"BYPASSED_LICENSE_ACTIVE_9999";
        license[@"type"] = @"permanent";
        license[@"status"] = @"active";
        license[@"expires"] = @"2099-12-31T23:59:59Z";
        license[@"issued"] = @"2024-01-01T00:00:00Z";
        fakeLicense[@"license"] = license;
        
        NSMutableArray *devices = [NSMutableArray array];
        [devices addObject:@{@"id": @"bypass_device_001", @"name": @"Bypassed Primary"}];
        [devices addObject:@{@"id": @"bypass_device_002", @"name": @"Bypassed Secondary"}];
        [devices addObject:@{@"id": @"bypass_device_003", @"name": @"Bypassed Tertiary"}];
        fakeLicense[@"devices"] = devices;
        
        fakeLicense[@"acts"] = @{
            @"current": @1,
            @"max": @9999
        };
        
        fakeLicense[@"maintenance"] = @{
            @"status": @"ok",
            @"message": @"No maintenance required - Bypassed",
            @"until": @"2099-01-01T00:00:00Z"
        };
        
        fakeLicense[@"features"] = @{
            @"premium": @YES,
            @"unlimited": @YES,
            @"all_features": @YES,
            @"pro": @YES
        };
        
        fakeLicense[@"user"] = @{
            @"id": @"bypass_user_999",
            @"name": @"Bypass User",
            @"email": @"bypass@license.com",
            @"tier": @"ultimate"
        };
        
        return fakeLicense;
    }
}

static id fixed_getJSON(id self, SEL _cmd, id a3, long long *a4) {
    NSLog(@"[Bypass] ✅ getJSON: bypassed (URL: %@)", a3);
    
    if (a4) {
        *a4 = 200;
    }
    
    NSMutableDictionary *response = [NSMutableDictionary dictionary];
    response[@"status"] = @"success";
    response[@"code"] = @200;
    response[@"message"] = @"License validated successfully";
    response[@"data"] = @{
        @"valid": @YES,
        @"verified": @YES,
        @"timestamp": @([[NSDate date] timeIntervalSince1970]),
        @"bypass": @YES
    };
    
    return response;
}

static BOOL fixed_patch(id self, SEL _cmd, id a3, id a4, long long a5) {
    NSLog(@"[Bypass] ✅ patch: bypassed (key: %@, devices: %lu, acts: %lld)", 
          a3, (unsigned long)[(NSArray *)a4 count], a5);
    return YES;
}

static long long fixed_maintenance(id self, SEL _cmd, id *a3) {
    NSLog(@"[Bypass] ✅ maintenance: bypassed");
    if (a3) {
        *a3 = @"No maintenance required - Bypassed";
    }
    return 0;
}

static id fixed_loadKey(id self, SEL _cmd) {
    NSLog(@"[Bypass] ✅ loadKey: returning fake key");
    return @"BYPASSED_ACTIVE_LICENSE_KEY_9999_ULTIMATE";
}

static void fixed_saveKey(id self, SEL _cmd, id a3) {
    NSLog(@"[Bypass] ✅ saveKey: bypassed (would save: %@)", a3);
}

static void fixed_forgetKey(id self, SEL _cmd) {
    NSLog(@"[Bypass] ✅ forgetKey: bypassed");
}

static id fixed_parseISO(id self, SEL _cmd, id a3) {
    NSLog(@"[Bypass] ✅ parseISO: %@", a3);
    
    if (!a3 || [a3 length] == 0) {
        NSTimeInterval futureSeconds = 100.0 * 365.0 * 24.0 * 60.0 * 60.0;
        return [NSDate dateWithTimeIntervalSinceNow:futureSeconds];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDate *date = [formatter dateFromString:a3];
    
    if (!date) {
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        date = [formatter dateFromString:a3];
    }
    
    if (!date) {
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        date = [formatter dateFromString:a3];
    }
    
    if (!date) {
        NSTimeInterval futureSeconds = 100.0 * 365.0 * 24.0 * 60.0 * 60.0;
        date = [NSDate dateWithTimeIntervalSinceNow:futureSeconds];
        NSLog(@"[Bypass] ⚠️ parseISO: fallback to future date");
    }
    
    return date;
}

static id fixed_objectForKeyedSubscript(id self, SEL _cmd, id key) {
    
    id result = orig_objectForKeyedSubscript(self, _cmd, key);
    
    if ([key isKindOfClass:[NSString class]]) {
        NSString *keyStr = (NSString *)key;
        
        if ([keyStr isEqualToString:@"status"]) {
            if (!result || ![result isEqualToString:@"active"]) {
                return @"active";
            }
        }
        
        if ([keyStr isEqualToString:@"valid"] || [keyStr isEqualToString:@"verified"]) {
            return @YES;
        }
        
        if ([keyStr isEqualToString:@"expires"] || [keyStr isEqualToString:@"expiration"]) {
            if (!result) {
                return @"2099-12-31T23:59:59Z";
            }
        }
    }
    
    return result;
}

// ============================================================
// HÀM HOOK HELPER
// ============================================================

static void hookMethod(Class cls, SEL selector, IMP newImp, void **origImp) {
    Method method = class_getClassMethod(cls, selector);
    if (!method) {
        method = class_getInstanceMethod(cls, selector);
    }
    
    if (method) {
        *origImp = (void *)method_getImplementation(method);
        method_setImplementation(method, newImp);
        NSLog(@"[Bypass] ✅ Hooked %s", sel_getName(selector));
    } else {
        NSLog(@"[Bypass] ❌ Failed to find method %s", sel_getName(selector));
    }
}

__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        
        Class licenseGate = NSClassFromString(@"LicenseGate");
        if (!licenseGate) {
            return;
        }
        
        NSLog(@" %p", licenseGate);
        
        hookMethod(licenseGate, sel_registerName("verify:"), (IMP)fixed_verify, (void **)&orig_verify);
        hookMethod(licenseGate, sel_registerName("fetch:"), (IMP)fixed_fetch, (void **)&orig_fetch);
        hookMethod(licenseGate, sel_registerName("getJSON:status:"), (IMP)fixed_getJSON, (void **)&orig_getJSON);
        hookMethod(licenseGate, sel_registerName("patch:devices:acts:"), (IMP)fixed_patch, (void **)&orig_patch);
        hookMethod(licenseGate, sel_registerName("maintenance:"), (IMP)fixed_maintenance, (void **)&orig_maintenance);
        hookMethod(licenseGate, sel_registerName("loadKey"), (IMP)fixed_loadKey, (void **)&orig_loadKey);
        hookMethod(licenseGate, sel_registerName("saveKey:"), (IMP)fixed_saveKey, (void **)&orig_saveKey);
        hookMethod(licenseGate, sel_registerName("forgetKey"), (IMP)fixed_forgetKey, (void **)&orig_forgetKey);
        hookMethod(licenseGate, sel_registerName("parseISO:"), (IMP)fixed_parseISO, (void **)&orig_parseISO);
        
        Class dictClass = NSClassFromString(@"NSDictionary");
        if (dictClass) {
            hookMethod(dictClass, sel_registerName("objectForKeyedSubscript:"), 
                      (IMP)fixed_objectForKeyedSubscript, (void **)&orig_objectForKeyedSubscript);
        }
        
        Class userDefaultsClass = NSClassFromString(@"NSUserDefaults");
        if (userDefaultsClass) {
            Method boolMethod = class_getInstanceMethod(userDefaultsClass, sel_registerName("boolForKey:"));
            if (boolMethod) {
                IMP origBool = method_getImplementation(boolMethod);
                method_setImplementation(boolMethod, imp_implementationWithBlock(^BOOL(id self, id key) {
                    if ([key isKindOfClass:[NSString class]]) {
                        NSString *keyStr = (NSString *)key;
                        if ([keyStr containsString:@"license"] || [keyStr containsString:@"valid"]) {
                            return YES;
                        }
                    }
                    return ((BOOL (*)(id, SEL, id))origBool)(self, sel_registerName("boolForKey:"), key);
                }));
            }
        }
        
        Class bundleClass = NSClassFromString(@"NSBundle");
        if (bundleClass) {
            Method bundleMethod = class_getInstanceMethod(bundleClass, sel_registerName("bundleIdentifier"));
            if (bundleMethod) {
                IMP origBundle = method_getImplementation(bundleMethod);
                method_setImplementation(bundleMethod, imp_implementationWithBlock(^id(id self) {
                  
                    id result = ((id (*)(id, SEL))origBundle)(self, sel_registerName("bundleIdentifier"));
                    if (!result) {
                        return @"com.bypass.license";
                    }
                    return result;
                }));
            }
        }
        
        Class dateClass = NSClassFromString(@"NSDate");
        if (dateClass) {
            Method timeMethod = class_getInstanceMethod(dateClass, sel_registerName("timeIntervalSinceNow"));
            if (timeMethod) {
                IMP origTime = method_getImplementation(timeMethod);
                method_setImplementation(timeMethod, imp_implementationWithBlock(^double(id self) {
                    double result = ((double (*)(id, SEL))origTime)(self, sel_registerName("timeIntervalSinceNow"));
   
                    if (result < -31536000) {
                        return 31536000.0;
                    }
                    return result;
                }));
            }
        }
    }
}
