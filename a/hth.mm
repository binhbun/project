#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>      
#import <mach/mach.h>       
#import <mach/vm_map.h>
uintptr_t get_dylib_slide(const char *dylib_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, dylib_name)) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0; 
}

#define TARGET_CLASS "LoginKey"

@interface NSObject (LoginKeyClean)
- (UIView *)successPopup;
- (UIView *)loadingHUD;
- (UIView *)parentView;
@end

@implementation NSObject (LoginKeyFinalHook)

- (void)hk_startAuthFlowInView:(id)view {
    if ([self respondsToSelector:@selector(setParentView:)]) {
        [self performSelector:@selector(setParentView:) withObject:view];
    }
    


    uintptr_t dylib_slide = get_dylib_slide("bypassindia.dylib");
    
    if (dylib_slide != 0) {
        uint8_t *isAuth = (uint8_t *)(dylib_slide + 0x3C9258);
        uint8_t *isTouchEnable = (uint8_t *)(dylib_slide + 0x3C4A2C);

        if (isAuth) {
            mach_port_t task = mach_task_self();
            vm_protect(task, (uintptr_t)isAuth & ~PAGE_MASK, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            *isAuth = 1;
        }
        
        if (isTouchEnable) {
            mach_port_t task = mach_task_self();
            vm_protect(task, (uintptr_t)isTouchEnable & ~PAGE_MASK, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            *isTouchEnable = 1;
        }
        
        NSLog(@"[binhbun] Đã patch thành công vào bypassindia.dylib tại slide: 0x%lx", dylib_slide);
    } else {
        NSLog(@"[binhbun] Không tìm thấy bypassindia.dylib để patch!");
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf) {
            if ([weakSelf respondsToSelector:@selector(hideHUD)]) [weakSelf performSelector:@selector(hideHUD)];
            if ([weakSelf respondsToSelector:@selector(showImageLikeSuccessPopupWithExpiry:)]) {
                [weakSelf performSelector:@selector(showImageLikeSuccessPopupWithExpiry:) withObject:@"GMV MOBA"];
            }
        }
    });
}

- (void)hk_closeSuccessPopup {
    NSLog(@"[binhbun] Đang đóng Popup và ép mở lại cảm ứng...");
    
    UIView *parent = nil;
    if ([self respondsToSelector:@selector(parentView)]) {
        parent = [self performSelector:@selector(parentView)];
    }

    UIView *popup = nil;
    if ([self respondsToSelector:@selector(successPopup)]) {
        popup = [self performSelector:@selector(successPopup)];
        [popup removeFromSuperview]; 
    }
    
    UIView *hud = nil;
    if ([self respondsToSelector:@selector(loadingHUD)]) {
        hud = [self performSelector:@selector(loadingHUD)];
        [hud removeFromSuperview]; 
    }

    if (parent) {
        parent.userInteractionEnabled = YES;
    }
    [[UIApplication sharedApplication] keyWindow].userInteractionEnabled = YES;
    
    UIViewController *root = [[UIApplication sharedApplication] keyWindow].rootViewController;
    root.view.userInteractionEnabled = YES;

    NSLog(@"[binhbun] Đã dọn sạch. Thử gọi Menu bằng 3 ngón ngay!");
}

@end

#pragma mark - Constructor

__attribute__((constructor))
static void init_stable_bypass() {
    Class cls = objc_getClass(TARGET_CLASS);
    if (!cls) return;

    method_exchangeImplementations(
        class_getInstanceMethod(cls, @selector(startAuthFlowInView:)),
        class_getInstanceMethod([NSObject class], @selector(hk_startAuthFlowInView:))
    );

    method_exchangeImplementations(
        class_getInstanceMethod(cls, NSSelectorFromString(@"closeSuccessPopup")),
        class_getInstanceMethod([NSObject class], @selector(hk_closeSuccessPopup))
    );

    method_exchangeImplementations(
        class_getInstanceMethod(cls, NSSelectorFromString(@"handleLoginFailWithMessage:")),
        class_getInstanceMethod([NSObject class], @selector(hk_handleLoginFailWithMessage:))
    );
    
    NSLog(@"[binhbun] Deep Swizzling Completed.");
}
