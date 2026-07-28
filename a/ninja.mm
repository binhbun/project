#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import "fishhook.h"

// ========== DECLARE ORIGINAL FUNCTIONS ==========
void (*orig_DrawLogin)(void*) = NULL;

// ========== FIND SLIDE ==========
uintptr_t get_slide() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "ninja.framework")) {
            if (!strstr(name, "libHelpshift.dylib")) {
                NSLog(@"[Bypass] Found framework: %s", name);
                return _dyld_get_image_vmaddr_slide(i);
            }
        }
    }
    return 0;
}

// ========== PATCH BY OFFSET ==========
void patch_login_state() {
    uintptr_t slide = get_slide();
    if (slide == 0) {
        NSLog(@"[Bypass] Cannot find framework!");
        return;
    }
    
    // Địa chỉ từ bss
    uintptr_t addr_logged_in = slide + 0x22F6F9;
    uintptr_t addr_is_logging_in = slide + 0x22F6F8;
    
    NSLog(@"[Bypass] logged_in at: 0x%lx", addr_logged_in);
    NSLog(@"[Bypass] is_logging_in at: 0x%lx", addr_is_logging_in);
    
    // Đọc giá trị hiện tại
    uint8_t current_logged = *(uint8_t *)addr_logged_in;
    uint8_t current_is_logging = *(uint8_t *)addr_is_logging_in;
    
    NSLog(@"[Bypass] Current: logged_in=%d, is_logging_in=%d", 
          current_logged, current_is_logging);
    
    // Patch
    *(uint8_t *)addr_is_logging_in = 0;
    *(uint8_t *)addr_logged_in = 1;
    
    // Verify
    uint8_t new_logged = *(uint8_t *)addr_logged_in;
    uint8_t new_is_logging = *(uint8_t *)addr_is_logging_in;
    
    if (new_logged == 1 && new_is_logging == 0) {
        NSLog(@"[Bypass] ✅ PATCH SUCCESS!");
    } else {
        NSLog(@"[Bypass] ❌ PATCH FAILED!");
    }
}

// ========== HOOK DRAWLOGIN ==========
void my_DrawLogin(void *a1) {
    NSLog(@"[Bypass] ⚡ DrawLogin called - patching...");
    
    // Patch mỗi khi DrawLogin được gọi
    patch_login_state();
    
    // Gọi hàm gốc
    if (orig_DrawLogin) {
        orig_DrawLogin(a1);
    }
}

// ========== INITIALIZE ==========
__attribute__((constructor)) static void initialize() {
    NSLog(@"[Bypass] ========================================");
    NSLog(@"[Bypass] 🚀 Dylib INJECTED SUCCESSFULLY!");
    NSLog(@"[Bypass] ========================================");
    
    // Đợi game load
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), 
                   dispatch_get_main_queue(), ^{
        
        // Patch trực tiếp
        patch_login_state();
        
        // Hook DrawLogin (nếu muốn)
        // Sử dụng rebind_symbols với struct đúng
        struct rebinding rebindings[1];
        rebindings[0].name = "_Z9DrawLoginP11ImGuiIO_";
        rebindings[0].replacement = (void *)my_DrawLogin;
        rebindings[0].replaced = (void **)&orig_DrawLogin;
        
        int result = rebind_symbols(rebindings, 1);
        
        if (result == 0) {
            NSLog(@"[Bypass] ✅ DrawLogin hooked successfully!");
        } else {
            NSLog(@"[Bypass] ⚠️ Failed to hook DrawLogin (result: %d)", result);
        }
        
        // Patch lại sau 5 giây
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), 
                       dispatch_get_main_queue(), ^{
            patch_login_state();
        });
        
        // Patch định kỳ
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (1) {
                [NSThread sleepForTimeInterval:10.0];
                patch_login_state();
            }
        });
    });
}
