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
static BOOL (*orig_isEqualToString)(id self, SEL _cmd, id aString);

static NSString *realKey = nil;
static NSDictionary *realLicenseData = nil;

static id fixed_parseISO(id self, SEL _cmd, id a3);
static id fixed_fetch_bb(id self, SEL _cmd, id a3);

static id fixed_fetch_bb(id self, SEL _cmd, id a3) {
    NSMutableDictionary *bbLicense = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *license = [NSMutableDictionary dictionary];
    license[@"key"] = @"BINHBUN_LICENSE_ACTIVE_9999";
    license[@"type"] = @"permanent";
    license[@"status"] = @"active";
    license[@"expires"] = @"2099-12-31T23:59:59Z";
    license[@"issued"] = @"2024-01-01T00:00:00Z";
    bbLicense[@"license"] = license;
    
    bbLicense[@"devices"] = @[
        @{@"id": @"device_001", @"name": @"BINHBUN Device"},
        @{@"id": @"device_002", @"name": @"Secondary Device"},
        @{@"id": @"device_003", @"name": @"Tertiary Device"}
    ];
    
    bbLicense[@"acts"] = @{
        @"current": @1,
        @"max": @9999
    };
    
    bbLicense[@"maintenance"] = @{
        @"status": @"ok",
        @"message": @"No maintenance required - BINHBUN",
        @"until": @"2099-01-01T00:00:00Z"
    };
    
    bbLicense[@"features"] = @{
        @"premium": @YES,
        @"unlimited": @YES,
        @"all_features": @YES,
        @"pro": @YES
    };
    
    bbLicense[@"user"] = @{
        @"id": @"bypass_user_999",
        @"name": @"Bypass User",
        @"email": @"bypass@license.com",
        @"tier": @"ultimate"
    };
    
    realLicenseData = bbLicense;
    return bbLicense;
}

static id fixed_fetch(id self, SEL _cmd, id a3) {
    NSLog(@"[Bypass] 🔍 fetch: called with: %@", a3);
    
    id result = orig_fetch(self, _cmd, a3);
    
    if (!result || ![result isKindOfClass:[NSDictionary class]]) {
        return fixed_fetch_bb(self, _cmd, a3);
    }
    
    NSMutableDictionary *licenseData = [result mutableCopy];
    
    NSMutableDictionary *license = [[licenseData objectForKey:@"license"] mutableCopy];
    if (!license) {
        license = [NSMutableDictionary dictionary];
    }
    
    NSString *status = [license objectForKey:@"status"];
    if (![status isEqualToString:@"active"]) {
        license[@"status"] = @"active";
        NSLog(@": %@ -> ", status);
    }
    
    NSString *expires = [license objectForKey:@"expires"];
    if (expires) {
        NSDate *expireDate = fixed_parseISO(self, _cmd, expires);
        if (expireDate) {
            NSDate *now = [NSDate date];
            if ([expireDate compare:now] == NSOrderedAscending) {
                NSTimeInterval futureSeconds = 100.0 * 365.0 * 24.0 * 60.0 * 60.0;
                NSDate *newExpire = [NSDate dateWithTimeIntervalSinceNow:futureSeconds];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
                license[@"expires"] = [formatter stringFromDate:newExpire];
                NSLog(@"[Bypass] ✅ Extended expiration date");
            }
        }
    } else {
        NSTimeInterval futureSeconds = 100.0 * 365.0 * 24.0 * 60.0 * 60.0;
        NSDate *newExpire = [NSDate dateWithTimeIntervalSinceNow:futureSeconds];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        license[@"expires"] = [formatter stringFromDate:newExpire];

    }
    
    if (![license objectForKey:@"type"]) {
        license[@"type"] = @"permanent";
    }
    
    if (![license objectForKey:@"key"]) {
        license[@"key"] = @"BINHBUN_LICENSE_ACTIVE";
    }
    
    licenseData[@"license"] = license;
    
    NSArray *devices = [licenseData objectForKey:@"devices"];
    if (!devices || ![devices isKindOfClass:[NSArray class]]) {
        licenseData[@"devices"] = @[
            @{@"id": @"device_001", @"name": @"BINHBUN Device"},
            @{@"id": @"device_002", @"name": @"Secondary Device"}
        ];
    }
    
    NSDictionary *acts = [licenseData objectForKey:@"acts"];
    if (!acts) {
        licenseData[@"acts"] = @{
            @"current": @1,
            @"max": @9999
        };
    } else {
        NSMutableDictionary *newActs = [acts mutableCopy];
        NSNumber *max = [newActs objectForKey:@"max"];
        NSNumber *current = [newActs objectForKey:@"current"];
        if (!max || [max integerValue] < [current integerValue] + 1) {
            newActs[@"max"] = @9999;
        }
        licenseData[@"acts"] = newActs;
    }
    
    NSDictionary *maintenance = [licenseData objectForKey:@"maintenance"];
    if (!maintenance) {
        licenseData[@"maintenance"] = @{
            @"status": @"ok",
            @"message": @"No maintenance required"
        };
    }
    
    realLicenseData = licenseData;
    
    return licenseData;
}

static id fixed_getJSON(id self, SEL _cmd, id a3, long long *a4) {
    NSLog(@": %@", a3);
    
    if (a4) {
        *a4 = 200;
    }
    
    id result = nil;
    if (orig_getJSON) {
        result = orig_getJSON(self, _cmd, a3, a4);
    }
    
    if (!result || ![result isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        response[@"status"] = @"success";
        response[@"code"] = @200;
        response[@"message"] = @"BINHBUN - GMVMOBA";
        response[@"data"] = @{
            @"valid": @YES,
            @"verified": @YES,
            @"timestamp": @([[NSDate date] timeIntervalSince1970]),
            @"bypass": @YES
        };
        return response;
    }
    
    NSMutableDictionary *fixedResponse = [result mutableCopy];
    if (![fixedResponse objectForKey:@"status"] || 
        ![[fixedResponse objectForKey:@"status"] isEqualToString:@"success"]) {
        fixedResponse[@"status"] = @"success";
    }
    
    NSMutableDictionary *data = [[fixedResponse objectForKey:@"data"] mutableCopy];
    if (!data) {
        data = [NSMutableDictionary dictionary];
    }
    data[@"valid"] = @YES;
    data[@"verified"] = @YES;
    fixedResponse[@"data"] = data;
    
    return fixedResponse;
}

static BOOL fixed_patch(id self, SEL _cmd, id a3, id a4, long long a5) {
    NSLog(@": %@, : %lu, : %lld", 
          a3, (unsigned long)[(NSArray *)a4 count], a5);
    
    BOOL result = NO;
    if (orig_patch) {
        result = orig_patch(self, _cmd, a3, a4, a5);
    }
    
    if (!result) {
    }
    
    if (a3 && [a3 isKindOfClass:[NSString class]]) {
        realKey = a3;
    }
    
    return YES;
}

static long long fixed_maintenance(id self, SEL _cmd, id *a3) {
    
    if (a3) {
        *a3 = @"No";
    }
    return 0;
}

static long long fixed_verify(id self, SEL _cmd, id a3) {
    NSLog(@" %@", a3);
    
    if (a3 && [a3 isKindOfClass:[NSString class]]) {
        if (!realKey) {
            realKey = a3;
        }
    }
    
    return 0;
}

static id fixed_loadKey(id self, SEL _cmd) {
    
    if (realKey) {
        NSLog(@" %@", realKey);
        return realKey;
    }
    
    NSString *bbKey = @"BINHBUN_ACTIVE_LICENSE_KEY";
    NSLog(@"%@", bbKey);
    return bbKey;
}

static void fixed_saveKey(id self, SEL _cmd, id a3) {
    NSLog(@"[Bypass] 🔍 saveKey: called with: %@", a3);
    
    if (a3 && [a3 isKindOfClass:[NSString class]]) {
        realKey = a3;
    }
    
    if (orig_saveKey) {
        orig_saveKey(self, _cmd, a3);
    }
}

static void fixed_forgetKey(id self, SEL _cmd) {
    NSLog(@"[Bypass] 🔍 forgetKey: called");
    realKey = nil;
    
    if (orig_forgetKey) {
        orig_forgetKey(self, _cmd);
    }
}

static id fixed_parseISO(id self, SEL _cmd, id a3) {
    if (!a3 || [a3 length] == 0) {
        NSTimeInterval futureSeconds = 100.0 * 365.0 * 24.0 * 60.0 * 60.0;
        return [NSDate dateWithTimeIntervalSinceNow:futureSeconds];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    NSArray *formats = @[
        @"yyyy-MM-dd'T'HH:mm:ss'Z'",
        @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        @"yyyy-MM-dd HH:mm:ss",
        @"yyyy-MM-dd"
    ];
    
    NSDate *date = nil;
    for (NSString *format in formats) {
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        date = [formatter dateFromString:a3];
        if (date) break;
    }
    
    if (!date) {
        NSTimeInterval futureSeconds = 100.0 * 365.0 * 24.0 * 60.0 * 60.0;
        date = [NSDate dateWithTimeIntervalSinceNow:futureSeconds];
        NSLog(@"[Bypass] ⚠️ parseISO: fallback to future date for: %@", a3);
    }
    
    return date;
}

static id fixed_objectForKeyedSubscript(id self, SEL _cmd, id key) {
    id result = nil;
    if (orig_objectForKeyedSubscript) {
        result = orig_objectForKeyedSubscript(self, _cmd, key);
    }
    
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
                return @"9999-12-31T23:59:59Z";
            }
        }
        
        if ([keyStr isEqualToString:@"type"]) {
            if (!result) {
                return @"permanent";
            }
        }
        
        if ([keyStr isEqualToString:@"max"]) {
            if (!result || [result integerValue] == 0) {
                return @9999;
            }
        }
    }
    
    return result;
}

static BOOL fixed_isEqualToString(id self, SEL _cmd, id aString) {
    if ([aString isKindOfClass:[NSString class]]) {
        NSString *str = (NSString *)aString;
        if ([str isEqualToString:@"invalid"] || 
            [str isEqualToString:@"expired"] ||
            [str isEqualToString:@"inactive"]) {
            return NO;
        }
    }
    
    if (orig_isEqualToString) {
        return orig_isEqualToString(self, _cmd, aString);
    }
    
    return [self isEqual:aString];
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


__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        
        // Tìm class LicenseGate
        Class licenseGate = NSClassFromString(@"LicenseGate");
        if (!licenseGate) {
            return;
        }
        
        NSLog(@"%p", licenseGate);
        
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
        
        Class stringClass = NSClassFromString(@"NSString");
        if (stringClass) {
            hookMethod(stringClass, sel_registerName("isEqualToString:"), 
                      (IMP)fixed_isEqualToString, (void **)&orig_isEqualToString);
        }
        
        Class userDefaultsClass = NSClassFromString(@"NSUserDefaults");
        if (userDefaultsClass) {
            Method boolMethod = class_getInstanceMethod(userDefaultsClass, sel_registerName("boolForKey:"));
            if (boolMethod) {
                IMP origBool = method_getImplementation(boolMethod);
                method_setImplementation(boolMethod, imp_implementationWithBlock(^BOOL(id self, id key) {
                    if ([key isKindOfClass:[NSString class]]) {
                        NSString *keyStr = (NSString *)key;
                        if ([keyStr containsString:@"license"] || 
                            [keyStr containsString:@"valid"] ||
                            [keyStr containsString:@"active"]) {
                            return YES;
                        }
                    }
                    return ((BOOL (*)(id, SEL, id))origBool)(self, sel_registerName("boolForKey:"), key);
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
                    if (result < -86400 * 30) {
                        return 86400 * 365.0;
                    }
                    return result;
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
                        return @"com.binhbun.app";
                    }
                    return result;
                }));
            }
        }
    }
}



////////////////////////////////////////




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
