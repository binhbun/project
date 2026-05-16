#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <string.h>

uintptr_t get_unity_framework_slide() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        // Kiểm tra xem hình ảnh dylib hiện tại có phải là UnityFramework hay không
        if (name && strstr(name, "UnityFramework.dylib")) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

void start_bypass_loop() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        uintptr_t slide = 0;
        
        while ((slide = get_unity_framework_slide()) == 0) {
            [NSThread sleepForTimeInterval:0.1]; 
        }
        
        NSLog(@"[Bypass] Đã tìm thấy UnityFramework.dylib tại Slide Offset: 0x%lx", slide);
        
        uintptr_t byte_3B8B50_addr = slide + 0x3B8B50;
        
        for (int i = 0; i < 20; i++) {
            *(bool *)byte_3B8B50_addr = true;
            [NSThread sleepForTimeInterval:0.5];
        }
        
        *(bool *)byte_3B8B50_addr = true;
        NSLog(@"[Bypass] Kích hoạt trạng thái Đăng nhập thành công thành công!");
    });
}

__attribute__((constructor)) static void initialize() {
    NSLog(@"[Bypass] Dylib đã được inject vào tiến trình chính!");
    start_bypass_loop();
}
