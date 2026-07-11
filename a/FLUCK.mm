#import <objc/runtime.h>
#import <Foundation/Foundation.h>

static id my_load(id self, SEL _cmd, NSString *key) {
    if ([key isEqualToString:@"key"]) {
        return @"BINMHBUN_GMVMOBA";
    }
    if ([key isEqualToString:@"expiry_timestamp"]) {
        return @"4102444800.0"; 
    }
    return nil;
}

typedef void (^ValidationCompletion)(BOOL, NSString *, NSString *, id);

static void my_validateKey(id self, SEL _cmd, NSString *key, ValidationCompletion completion) {
    if (!completion) return;
    completion(YES, @"success", @"License valid", @{});
}

__attribute__((constructor))
static void bypass(void) {
    Class khClass = objc_getClass("KeychainHelper");
    if (khClass) {
        Method m = class_getClassMethod(khClass, NSSelectorFromString(@"load:"));
        if (m) {
            method_setImplementation(m, (IMP)my_load);
        }
    }
    Class kaClass = objc_getClass("KeyAuthSystem");
    if (kaClass) {
        SEL sel = NSSelectorFromString(@"validateKey:completion:");
        Method m = class_getInstanceMethod(kaClass, sel);
        if (m) {
            method_setImplementation(m, (IMP)my_validateKey);
        }
    }
}



////////////////////




