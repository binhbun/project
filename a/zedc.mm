#import <Foundation/Foundation.h>
#import <objc/runtime.h>

__attribute__((constructor))
static void bypassPPAPIKey() {
    
    Class ppapi = objc_getClass("PPAPIKey");
    if (!ppapi) {
        return;
    }
    
    Method origLoad = class_getClassMethod(ppapi, @selector(load));
    if (origLoad) {
        IMP newLoad = imp_implementationWithBlock(^(id self) {
        });
        method_setImplementation(origLoad, newLoad);
    }
    
    Method origShared = class_getClassMethod(ppapi, @selector(shared));
    if (origShared) {
        IMP newShared = imp_implementationWithBlock(^(id self) {
            id dummy = class_createInstance(ppapi, 0);
            return dummy;
        });
        method_setImplementation(origShared, newShared);
    }
    
    Method origSetToken = class_getInstanceMethod(ppapi, @selector(setToken:));
    if (origSetToken) {
        IMP newSetToken = imp_implementationWithBlock(^(id self, id token) {
        });
        method_setImplementation(origSetToken, newSetToken);
    }
    
    Method origSetEN = class_getInstanceMethod(ppapi, @selector(setEN:));
    if (origSetEN) {
        IMP newSetEN = imp_implementationWithBlock(^(id self, BOOL en) {
        });
        method_setImplementation(origSetEN, newSetEN);
    }
    
    Method origSetVer = class_getInstanceMethod(ppapi, @selector(setVer:));
    if (origSetVer) {
        IMP newSetVer = imp_implementationWithBlock(^(id self, id ver) {
        });
        method_setImplementation(origSetVer, newSetVer);
    }
    
    Method origGetDeviceKey = class_getInstanceMethod(ppapi, @selector(getDeviceKey));
    if (origGetDeviceKey) {
        IMP newGetDeviceKey = imp_implementationWithBlock(^id(id self) {
            return nil;
        });
        method_setImplementation(origGetDeviceKey, newGetDeviceKey);
    }
    
    Method origGetKeyExpire = class_getInstanceMethod(ppapi, @selector(getKeyExpire));
    if (origGetKeyExpire) {
        IMP newGetKeyExpire = imp_implementationWithBlock(^id(id self) {
            return nil;
        });
        method_setImplementation(origGetKeyExpire, newGetKeyExpire);
    }
    
    Method origGetKeyAmount = class_getInstanceMethod(ppapi, @selector(getKeyAmount));
    if (origGetKeyAmount) {
        IMP newGetKeyAmount = imp_implementationWithBlock(^id(id self) {
            return nil;
        });
        method_setImplementation(origGetKeyAmount, newGetKeyAmount);
    }
    
    Method origGetDeviceID = class_getInstanceMethod(ppapi, @selector(getDeviceID));
    if (origGetDeviceID) {
        IMP newGetDeviceID = imp_implementationWithBlock(^id(id self) {
            return @"BYPASSED_DEVICE_ID";
        });
        method_setImplementation(origGetDeviceID, newGetDeviceID);
    }
    
    Method origGetAppBundle = class_getInstanceMethod(ppapi, @selector(getAppBundle));
    if (origGetAppBundle) {
        IMP newGetAppBundle = imp_implementationWithBlock(^id(id self) {
            NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
            return bundleId ?: @"com.unknown.bypass";
        });
        method_setImplementation(origGetAppBundle, newGetAppBundle);
    }
    
    Method origExitKey = class_getInstanceMethod(ppapi, @selector(exitKey));
    if (origExitKey) {
        IMP newExitKey = imp_implementationWithBlock(^(id self) {
        });
        method_setImplementation(origExitKey, newExitKey);
    }
    
    Method origCopyKey = class_getInstanceMethod(ppapi, @selector(copyKey));
    if (origCopyKey) {
        IMP newCopyKey = imp_implementationWithBlock(^id(id self) {
            return nil;
        });
        method_setImplementation(origCopyKey, newCopyKey);
    }
    
    Method origPackageData = class_getInstanceMethod(ppapi, @selector(packageData:));
    if (origPackageData) {
        IMP newPackageData = imp_implementationWithBlock(^id(id self, id data) {
            return data;
        });
        method_setImplementation(origPackageData, newPackageData);
    }
    
    Method origLoading = class_getInstanceMethod(ppapi, @selector(loading:));
    if (origLoading) {
        IMP newLoading = imp_implementationWithBlock(^(id self, id param) {
        });
        method_setImplementation(origLoading, newLoading);
    }
}
