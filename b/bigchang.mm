#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define TARGET_CLASS "APIKEY"

@interface Binhbun : NSObject
@end

@implementation Binhbun

+ (void)paid:(id)completion {
    NSLog(@"[Binhbun] Bypassing paid: block...");
    if (completion) {
        void (^block)(void) = completion;
        block();
    }
}

- (BOOL)hasShownSuccessAlert {
    return YES;
}

- (void)checkKey { 
    NSLog(@"[Binhbun] checkKey bypassed.");
}

- (void)checkAndRequestUDIDIfNeeded {
    NSLog(@"[Binhbun] checkAndRequestUDID bypassed.");
}

- (void)checkUDIDStatusFromServer:(id)a3 {
    NSLog(@"[Binhbun] checkUDIDStatusFromServer bypassed.");
}

- (id)savedUDID {
    return @"Binhbun-BYPASS-UDID-9999";
}

- (BOOL)hasUDID {
    return YES;
}

@end

static __attribute__((constructor)) void init_Binhbun_bypass() {
     dispatch_async(dispatch_get_main_queue(), ^{
        
        Class targetCls = objc_getClass(TARGET_CLASS);
        Class customCls = [Binhbun class];

        if (targetCls && customCls) {
            NSArray *instanceMethods = @[
                @"checkKey", 
                @"checkAndRequestUDIDIfNeeded", 
                @"hasShownSuccessAlert",
                @"checkUDIDStatusFromServer:",
                @"savedUDID",
                @"hasUDID"
            ];

            for (NSString *selName in instanceMethods) {
                SEL sel = NSSelectorFromString(selName);
                Method origM = class_getInstanceMethod(targetCls, sel);
                Method custM = class_getInstanceMethod(customCls, sel);
                
                if (origM && custM) {
                    method_exchangeImplementations(origM, custM);
                }
            }

            Method origClassMethod = class_getClassMethod(targetCls, @selector(paid:));
            Method custClassMethod = class_getClassMethod(customCls, @selector(paid:));
            
            if (origClassMethod && custClassMethod) {
                method_exchangeImplementations(origClassMethod, custClassMethod);
            }
            
            NSLog(@"[Binhbun] Successfully hooked %s", TARGET_CLASS);
        } else {
            NSLog(@"[Binhbun] Failed to find class %s", TARGET_CLASS);
        }
    });
}



#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define TARGET_CLASS "APIKEY"

// Khai báo các biến toàn cục dựa trên file a.mm để chúng ta can thiệp trực tiếp
// Lưu ý: Các biến này thường nằm ở vùng nhớ DATA của binary gốc
extern BOOL iskey;
extern id keyValidationStatus;

static void (*orig_paid)(id, SEL, id);

void my_paid_hook(id self, SEL _cmd, id completion) {
    // 1. NGĂN CHẶN CRASH: Thay vì tự ý chạy block trong luồng riêng
    // Chúng ta sẽ gán các giá trị mà hàm sub_119C8 mong đợi vào bộ nhớ
    
    NSLog(@"[Binhbun] PUBG: Setting global memory states...");
    
    // Giả lập trạng thái đã kích hoạt để sub_119C8 không gọi lại đệ quy
    // Lưu ý: Nếu extern không hoạt động, bạn cần tìm offset của biến này
    @try {
        // Gán trực tiếp vào các biến logic của file a.mm
        // iskey = YES; 
        // keyValidationStatus = @"Bypassed"; 
    } @catch (NSException *e) {}

    if (completion) {
        
        void (^block)(void) = completion;
        
        @try {
            block();
            NSLog(@"[Binhbun] PUBG: Block executed on original thread.");
        } @catch (NSException *eb) {
            NSLog(@"[Binhbun] Prevented crash from block: %@", eb);
        }
    }
}

static __attribute__((constructor)) void init_Binhbun_bypass() {
        dispatch_async(dispatch_get_main_queue(), ^{
        
        Class targetCls = objc_getClass(TARGET_CLASS);
        if (!targetCls) return;

        Method origMethod = class_getClassMethod(targetCls, NSSelectorFromString(@"paid:"));
        if (origMethod) {
            orig_paid = (void(*)(id, SEL, id))method_getImplementation(origMethod);
            method_setImplementation(origMethod, (IMP)my_paid_hook);
        }

        class_replaceMethod(targetCls, NSSelectorFromString(@"checkKey"), imp_implementationWithBlock(^(id _self){}), "v@:");
        
        class_replaceMethod(targetCls, NSSelectorFromString(@"hasShownSuccessAlert"), imp_implementationWithBlock(^BOOL(id _self){ return YES; }), "B@:");
        class_replaceMethod(targetCls, NSSelectorFromString(@"hasUDID"), imp_implementationWithBlock(^BOOL(id _self){ return YES; }), "B@:");
        class_replaceMethod(targetCls, NSSelectorFromString(@"isUDIDModeEnabled"), imp_implementationWithBlock(^BOOL(id _self){ return YES; }), "B@:");
        
        class_replaceMethod(targetCls, NSSelectorFromString(@"savedUDID"), imp_implementationWithBlock(^id(id _self){ 
            return @"Binhbun-BYPASS-PRO-PUBG"; 
        }), "@@:");

        NSLog(@"[Binhbun] PUBG Deep Patch Applied. Delay 15s Finished.");
    });
}