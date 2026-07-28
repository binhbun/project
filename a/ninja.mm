#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import "fishhook.h"

// ========== DECLARE ORIGINAL FUNCTIONS ==========
void (*orig_DrawLogin)(void*) = NULL;
void (*orig_DrawMenu)(void*) = NULL;
void (*orig_FetchSocialInfo)(void) = NULL;
void (*orig_save_persistence)(void) = NULL;

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

// ========== SCAN FOR FUNCTIONS ==========
void scan_for_functions() {
    void *handle = dlopen(NULL, RTLD_LAZY);
    if (!handle) return;
    
    const char* possible_names[] = {
        "_Z8DrawMenuP11ImGuiIO_",
        "_Z8DrawMenuPv",
        "_Z8DrawMenuv",
        "_ZN6ImGui8DrawMenuEP11ImGuiIO_",
        "_ZL8DrawMenuP11ImGuiIO_",
        "_Z8DrawMenuPKc",
        "DrawMenu",
        "_Z9DrawLoginP11ImGuiIO_",
        "_Z16FetchSocialInfov",
        "_Z17save_persistencev",
        NULL
    };
    
    for (int i = 0; possible_names[i] != NULL; i++) {
        void *func = dlsym(handle, possible_names[i]);
        if (func) {
            NSLog(@"[Bypass] ✅ Found: %s -> %p", possible_names[i], func);
        }
    }
    dlclose(handle);
}

// ========== PATCH ALL ==========
void patch_all() {
    uintptr_t slide = get_slide();
    if (slide == 0) {
        NSLog(@"[Bypass] Cannot find framework!");
        return;
    }
    
    // OFFSETS TỪ IDA
    uintptr_t addr_logged_in = slide + 0x22F6F9;
    uintptr_t addr_is_logging_in = slide + 0x22F6F8;
    uintptr_t addr_first_time = slide + 0x22F899;
    uintptr_t addr_g_login_show_password = slide + 0x22F898;
    uintptr_t addr_g_MenuLangLoaded = slide + 0x22F8ED;
    uintptr_t addr_s_logged_login_screen = slide + 0x22F768;
    uintptr_t addr_s_seeded = slide + 0x22F769;
    uintptr_t addr_langDropdownOpen = slide + 0x22F86A;
    uintptr_t addr_s_socialFetchTriggered = slide + 0x22F891;
    uintptr_t addr_spinner_angle = slide + 0x22F894;
    uintptr_t addr_g_SocialFetched = slide + 0x22F890;
    uintptr_t addr_g_ResellerFetched = slide + 0x22F88E;
    uintptr_t addr_g_ResellerFetching = slide + 0x22F88F;
    
    // PATCH
    *(uint8_t *)addr_logged_in = 1;
    *(uint8_t *)addr_is_logging_in = 0;
    *(uint8_t *)addr_first_time = 1;
    *(uint8_t *)addr_s_logged_login_screen = 1;
    *(uint8_t *)addr_s_seeded = 1;
    *(uint8_t *)addr_s_socialFetchTriggered = 1;
    *(uint8_t *)addr_langDropdownOpen = 0;
    *(uint8_t *)addr_g_MenuLangLoaded = 1;
    *(uint8_t *)addr_g_login_show_password = 0;
    *(uint8_t *)addr_g_SocialFetched = 1;
    *(uint8_t *)addr_g_ResellerFetched = 1;
    *(uint8_t *)addr_g_ResellerFetching = 0;
    *(int *)addr_spinner_angle = 0;
    
    // Patch thêm vùng bss xung quanh
    for (int offset = 0x22F6F0; offset < 0x22F730; offset++) {
        uintptr_t addr = slide + offset;
        uint8_t value = *(uint8_t *)addr;
        if (value == 0 || value == 1) {
            *(uint8_t *)addr = 1;
        }
    }
    
    NSLog(@"[Bypass] ✅ All patches applied!");
    NSLog(@"[Bypass] logged_in=%d, is_logging_in=%d", 
          *(uint8_t *)addr_logged_in, *(uint8_t *)addr_is_logging_in);
}

// ========== HOOK DRAWLOGIN ==========
void my_DrawLogin(void *a1) {
    NSLog(@"[Bypass] ⚡ DrawLogin called");
    patch_all();
    
    // Gọi DrawMenu trực tiếp
    void (*DrawMenu)(void*) = dlsym(RTLD_DEFAULT, "_Z8DrawMenuP11ImGuiIO_");
    if (DrawMenu) {
        NSLog(@"[Bypass] 🎯 Calling DrawMenu directly!");
        DrawMenu(a1);
        return;
    }
    
    // Fallback
    if (orig_DrawLogin) {
        orig_DrawLogin(a1);
    }
}

// ========== HOOK DRAWMENU ==========
void my_DrawMenu(void *a1) {
    NSLog(@"[Bypass] 🎯 DrawMenu called!");
    patch_all();
    
    if (orig_DrawMenu) {
        orig_DrawMenu(a1);
    }
}

// ========== HOOK FETCH SOCIAL INFO ==========
void my_FetchSocialInfo() {
    NSLog(@"[Bypass] 📡 FetchSocialInfo blocked!");
    // Không gọi hàm gốc
}

// ========== HOOK SAVE PERSISTENCE ==========
void my_save_persistence() {
    NSLog(@"[Bypass] 💾 save_persistence blocked!");
    // Không gọi hàm gốc
}

// ========== INSTALL HOOKS ==========
void install_hooks() {
    struct rebinding rebindings[4];
    int count = 0;
    
    // Hook DrawLogin
    void *drawlogin = dlsym(RTLD_DEFAULT, "_Z9DrawLoginP11ImGuiIO_");
    if (drawlogin) {
        rebindings[count].name = "_Z9DrawLoginP11ImGuiIO_";
        rebindings[count].replacement = (void *)my_DrawLogin;
        rebindings[count].replaced = (void **)&orig_DrawLogin;
        count++;
    }
    
    // Hook DrawMenu
    void *drawmenu = dlsym(RTLD_DEFAULT, "_Z8DrawMenuP11ImGuiIO_");
    if (drawmenu) {
        rebindings[count].name = "_Z8DrawMenuP11ImGuiIO_";
        rebindings[count].replacement = (void *)my_DrawMenu;
        rebindings[count].replaced = (void **)&orig_DrawMenu;
        count++;
    }
    
    // Hook FetchSocialInfo
    void *fetch = dlsym(RTLD_DEFAULT, "_Z16FetchSocialInfov");
    if (fetch) {
        rebindings[count].name = "_Z16FetchSocialInfov";
        rebindings[count].replacement = (void *)my_FetchSocialInfo;
        rebindings[count].replaced = (void **)&orig_FetchSocialInfo;
        count++;
    }
    
    // Hook save_persistence
    void *save = dlsym(RTLD_DEFAULT, "_Z17save_persistencev");
    if (save) {
        rebindings[count].name = "_Z17save_persistencev";
        rebindings[count].replacement = (void *)my_save_persistence;
        rebindings[count].replaced = (void **)&orig_save_persistence;
        count++;
    }
    
    int result = rebind_symbols(rebindings, count);
    NSLog(@"[Bypass] Hook result: %d (%d hooks)", result, count);
}

// ========== CALL DRAWMENU REPEATEDLY ==========
void trigger_menu_loop() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int count = 0;
        while (1) {
            [NSThread sleepForTimeInterval:2.0];
            count++;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                patch_all();
                
                void (*DrawMenu)(void*) = dlsym(RTLD_DEFAULT, "_Z8DrawMenuP11ImGuiIO_");
                if (DrawMenu) {
                    NSLog(@"[Bypass] 🔄 Triggering DrawMenu #%d", count);
                    DrawMenu(NULL);
                }
            });
        }
    });
}

// ========== INITIALIZE ==========
__attribute__((constructor)) static void initialize() {
    NSLog(@"[Bypass] ========================================");
    NSLog(@"[Bypass] 🚀 Bypass dylib loaded!");
    NSLog(@"[Bypass] ========================================");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), 
                   dispatch_get_main_queue(), ^{
        
        // 1. Scan functions
        scan_for_functions();
        
        // 2. Patch all
        patch_all();
        
        // 3. Install hooks
        install_hooks();
        
        // 4. Trigger menu
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), 
                       dispatch_get_main_queue(), ^{
            void (*DrawMenu)(void*) = dlsym(RTLD_DEFAULT, "_Z8DrawMenuP11ImGuiIO_");
            if (DrawMenu) {
                NSLog(@"[Bypass] 🚀 First DrawMenu trigger!");
                DrawMenu(NULL);
            } else {
                NSLog(@"[Bypass] ❌ DrawMenu not found!");
            }
        });
        
        // 5. Trigger loop
        trigger_menu_loop();
    });
}


//////////////////////////////////


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
