#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <mach-o/dyld.h>

// Khai báo các biến trạng thái toàn cục
static BOOL menuInitialized = NO;

// Hàm lấy slide address của MelonityNEW.dylib
uintptr_t get_unity_framework_slide() {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "MelonityNEW.dylib")) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

// Hàm thực thi selector an toàn, tắt cảnh báo rò rỉ bộ nhớ của ARC
void safePerformSelector(id instance, SEL selector) {
    if (!instance || !selector) return;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([instance respondsToSelector:selector]) {
        [instance performSelector:selector];
    }
    #pragma clang diagnostic pop
}

// Hàm khởi tạo menu trực tiếp từ địa chỉ bộ nhớ đã được đồng bộ
void initMenuDirect() {
    if (menuInitialized) {
        NSLog(@"[Bypass] Menu đã được khởi tạo, bỏ qua");
        return;
    }
    
    NSLog(@"[Bypass] ===== BẮT ĐẦU KHỞI TẠO MENU DIRECT =====");
    
    uintptr_t slide = get_unity_framework_slide();
    if (slide == 0) {
        NSLog(@"[Bypass] KHÔNG TÌM THẤY SLIDE CỦA DYLIB!");
        return;
    }
    NSLog(@"[Bypass] Slide: 0x%lx", (unsigned long)slide);
    
    Class MenuLoadClass = NSClassFromString(@"MenuLoad");
    if (!MenuLoadClass) {
        NSLog(@"[Bypass] KHÔNG TÌM THẤY CLASS MenuLoad!");
        return;
    }
    NSLog(@"[Bypass] Đã tìm thấy class MenuLoad");
    
    @try {
        // 1. Gọi hàm khởi tạo vùng nhớ sub_94008
        uintptr_t addr_sub_94008 = slide + 0x94008;
        if (addr_sub_94008) {
            void (*sub_94008)(uintptr_t) = (void (*)(uintptr_t))addr_sub_94008;
            uintptr_t addr_qword_F4E240 = slide + 0xF4E240;
            
            // Đọc giá trị cấu trúc an toàn tránh lỗi crash phân vùng
            uintptr_t oldValue = 0;
            if (addr_qword_F4E240) {
                oldValue = *(uintptr_t*)addr_qword_F4E240;
            }
            sub_94008(oldValue);
            NSLog(@"[Bypass] Đã thực thi hoàn tất sub_94008");
        }
        
        // 2. Tạo thực thể MenuLoad instance mới
        id menuInstance = [[MenuLoadClass alloc] init];
        if (!menuInstance) {
            NSLog(@"[Bypass] KHÔNG THỂ TẠO INSTANCE MenuLoad!");
            return;
        }
        NSLog(@"[Bypass] Đã tạo instance MenuLoad thành công");
        
        // 3. Gán con trỏ thực thể vào biến quản lý tĩnh qword_F4E248
        uintptr_t addr_qword_F4E248 = slide + 0xF4E248;
        if (addr_qword_F4E248) {
            *(uintptr_t*)addr_qword_F4E248 = (uintptr_t)CFBridgingRetain(menuInstance);
            NSLog(@"[Bypass] Đã gán thực thể vào con trỏ qword_F4E248");
        }
        
        // 4. Gọi hàm kích hoạt nhận diện cử chỉ hiển thị đồ họa
        SEL selector = NSSelectorFromString(@"InitializeGestureRecognizers");
        safePerformSelector(menuInstance, selector);
        
        menuInitialized = YES;
        NSLog(@"[Bypass] ===== MENU ĐÃ ĐƯỢC KHỞI TẠO THÀNH CÔNG THÔNG QUA DIRECT INJECTION! =====");
        
    } @catch (NSException *e) {
        NSLog(@"[Bypass] LỖI PHÁT SINH KHI KHỞI TẠO MENU: %@", e);
    }
}


// Hook vào NSURLSession để định hình dữ liệu sạch tuyệt đối từ Server
@interface NSURLSession (BypassMelonityNetwork)
@end

@implementation NSURLSession (BypassMelonityNetwork)

- (NSURLSessionDataTask *)custom_dataTaskWithRequest:(NSURLRequest *)request 
                                   completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    
    NSString *urlAbsoluteString = request.URL.absoluteString;
    
    if ([urlAbsoluteString containsString:@"verifyformlbbcracknewonetig"] || [urlAbsoluteString containsString:@"ske2.onrender.com"]) {
        NSLog(@"[Bypass Network] Đang cấu hình lại gói tin mồi đa biến...");

        NSString *fakeJSON = @"{"
                               "\"sa\":\"heng\","
                               "\"banot\":\"MJXI\","
                               "\"leng\":\"MJXI\","
                               "\"expires\":\"heng\","
                               "\"unregistered\":\"no\""
                             "}";
        
        NSData *fakeData = [fakeJSON dataUsingEncoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *fakeResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL 
                                                                      statusCode:200 
                                                                     HTTPVersion:@"HTTP/1.1" 
                                                                    headerFields:@{@"Content-Type": @"application/json"}];
        
        void (^customHandler)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable) = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(fakeData, fakeResponse, nil);
            }
        };
        
        return [self custom_dataTaskWithRequest:request completionHandler:customHandler];
    }

    return [self custom_dataTaskWithRequest:request completionHandler:completionHandler];
}

@end


// Xử lý tự động hóa UI: Đóng Alert và kích nổ menu đồ họa trực tiếp
@interface UIAlertController (BypassAlertNoJB)
@end

@implementation UIAlertController (BypassAlertNoJB)

- (void)custom_viewDidAppear:(BOOL)animated {
    
    // TRƯỜNG HỢP 1: Bảng đòi nhập Key ban đầu (Có chứa TextField)
    if (self.textFields.count > 0) {
        NSLog(@"[Bypass UI] Tự động xử lý bảng nhập Key...");
        UITextField *textField = self.textFields.firstObject;
        textField.text = @"MJXI"; 
        
        for (UIAlertAction *action in self.actions) {
            if ([action.title isEqualToString:@"OK"]) {
                void (^actionHandler)(UIAlertAction *) = [action valueForKey:@"handler"];
                if (actionHandler) {
                    [self dismissViewControllerAnimated:NO completion:^{
                        actionHandler(action);
                    }];
                }
                return;
            }
        }
    }
    
    // TRƯỜNG HỢP 2: Bảng thông báo kết quả "Result"
    if ([self.title isEqualToString:@"Result"] || [self.message isEqualToString:@"heng"]) {
        NSLog(@"[Bypass UI] Phát hiện bảng kết quả Result. Tiến hành thực thi ép nạp Menu...");
        
        for (UIAlertAction *action in self.actions) {
            if ([action.title isEqualToString:@"OK"]) {
                void (^actionHandler)(UIAlertAction *) = [action valueForKey:@"handler"];
                if (actionHandler) {
                    [self dismissViewControllerAnimated:NO completion:^{
                        // 1. Chạy luồng xử lý mặc định của dylib
                        actionHandler(action);
                        
                        // 2. Ép gọi hàm khởi tạo menu trực tiếp ngay lập tức trên Main Thread
                        NSLog(@"[Bypass UI] Bấm nút OK thành công. Gọi hàm khởi tạo menu trực tiếp...");
                        initMenuDirect();
                    }];
                }
                return;
            }
        }
    }

    [self custom_viewDidAppear:animated];
}

@end


// Constructor khởi tạo khi dylib nạp vào bộ nhớ ứng dụng
__attribute__((constructor)) static void initialize() {
    NSLog(@"[Bypass] Khởi động Framework kết hợp Direct Injection...");

    // Swizzle NSURLSession
    Class sessionClass = [NSURLSession class];
    Method origNetMethod = class_getInstanceMethod(sessionClass, @selector(dataTaskWithRequest:completionHandler:));
    Method swizzNetMethod = class_getInstanceMethod(sessionClass, @selector(custom_dataTaskWithRequest:completionHandler:));
    method_exchangeImplementations(origNetMethod, swizzNetMethod);

    // Swizzle UIAlertController
    Class alertClass = [UIAlertController class];
    Method origAlertMethod = class_getInstanceMethod(alertClass, @selector(viewDidAppear:));
    Method swizzAlertMethod = class_getInstanceMethod(alertClass, @selector(custom_viewDidAppear:));
    
    BOOL didAddMethod = class_addMethod(alertClass, @selector(viewDidAppear:), 
                                        method_getImplementation(swizzAlertMethod), 
                                        method_getTypeEncoding(swizzAlertMethod));
    if (didAddMethod) {
        class_replaceMethod(alertClass, @selector(custom_viewDidAppear:), 
                            method_getImplementation(origAlertMethod), 
                            method_getTypeEncoding(origAlertMethod));
    } else {
        method_exchangeImplementations(origAlertMethod, swizzAlertMethod);
    }

    NSLog(@"[Bypass] Hệ thống tích hợp đã sẵn sàng để biên dịch.");
}
