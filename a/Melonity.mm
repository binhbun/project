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
        NSLog(@"[Bypass] Menu đã được khởi tạo trước đó, bỏ qua");
        return;
    }
    
    NSLog(@"[Bypass] ===== BẮT ĐẦU KHỞI TẠO MENU CHẠY NGẦM =====");
    
    uintptr_t slide = get_unity_framework_slide();
    if (slide == 0) {
        NSLog(@"[Bypass] KHÔNG TÌM THẤY SLIDE CỦA DYLIB!");
        return;
    }
    
    Class MenuLoadClass = NSClassFromString(@"MenuLoad");
    if (!MenuLoadClass) {
        NSLog(@"[Bypass] KHÔNG TÌM THẤY CLASS MenuLoad!");
        return;
    }
    
    @try {
        // 1. Gọi hàm khởi tạo vùng nhớ sub_94008
        uintptr_t addr_sub_94008 = slide + 0x94008;
        if (addr_sub_94008) {
            void (*sub_94008)(uintptr_t) = (void (*)(uintptr_t))addr_sub_94008;
            uintptr_t addr_qword_F4E240 = slide + 0xF4E240;
            
            uintptr_t oldValue = 0;
            if (addr_qword_F4E240) {
                oldValue = *(uintptr_t*)addr_qword_F4E240;
            }
            sub_94008(oldValue);
        }
        
        // 2. Tạo thực thể MenuLoad instance mới
        id menuInstance = [[MenuLoadClass alloc] init];
        if (!menuInstance) {
            NSLog(@"[Bypass] KHÔNG THỂ TẠO INSTANCE MenuLoad!");
            return;
        }
        
        // 3. Gán con trỏ thực thể vào biến quản lý tĩnh qword_F4E248
        uintptr_t addr_qword_F4E248 = slide + 0xF4E248;
        if (addr_qword_F4E248) {
            *(uintptr_t*)addr_qword_F4E248 = (uintptr_t)CFBridgingRetain(menuInstance);
        }
        
        // 4. Gọi hàm kích hoạt nhận diện cử chỉ hiển thị đồ họa
        SEL selector = NSSelectorFromString(@"InitializeGestureRecognizers");
        safePerformSelector(menuInstance, selector);
        
        menuInitialized = YES;
        NSLog(@"[Bypass] ===== MENU ĐÃ ĐƯỢC NẠP NGẦM THÀNH CÔNG THÀNH CÔNG! =====");
        
    } @catch (NSException *e) {
        NSLog(@"[Bypass] LỖI PHÁT SINH KHI KHỞI TẠO MENU NGẦM: %@", e);
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
        NSLog(@"[Bypass Network] Đang mồi dữ liệu ngầm cho dylib...");

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


// Chặn tầng hiển thị đồ họa của UIViewController để ẩn hoàn toàn các Alert đòi key
@interface UIViewController (BypassHideAlert)
@end

@implementation UIViewController (BypassHideAlert)

- (void)custom_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    
    // Kiểm tra xem View chuẩn bị hiện lên có phải là một UIAlertController hay không
    if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alert = (UIAlertController *)viewControllerToPresent;
        
        // TRƯỜNG HỢP 1: Chặn hộp thoại đòi nhập Key (Có chứa ô nhập dữ liệu)
        if (alert.textFields.count > 0) {
            NSLog(@"[Bypass Background] Phát hiện Alert nhập Key. Tiến hành chặn và xử lý ngầm...");
            
            UITextField *textField = alert.textFields.firstObject;
            textField.text = @"MJXI"; // Mồi sẵn chuỗi xác minh vào cấu trúc biến
            
            for (UIAlertAction *action in alert.actions) {
                if ([action.title isEqualToString:@"OK"]) {
                    void (^actionHandler)(UIAlertAction *) = [action valueForKey:@"handler"];
                    if (actionHandler) {
                        // Thực thi trực tiếp logic gửi dữ liệu mà không cần hiển thị giao diện lên màn hình
                        actionHandler(action);
                    }
                    break;
                }
            }
            
            // Thực thi block hoàn thành của lệnh present (nếu có) để hệ thống không bị treo
            if (completion) completion();
            return; // ĐÃ ẨN: Không gọi hàm [super presentViewController:] gốc
        }
        
        // TRƯỜNG HỢP 2: Chặn hộp thoại hiển thị kết quả "Result"
        if ([alert.title isEqualToString:@"Result"] || [alert.message isEqualToString:@"heng"]) {
            NSLog(@"[Bypass Background] Phát hiện Alert Result. Tiến hành chặn và tự động kích nổ Menu đồ họa...");
            
            for (UIAlertAction *action in alert.actions) {
                if ([action.title isEqualToString:@"OK"]) {
                    void (^actionHandler)(UIAlertAction *) = [action valueForKey:@"handler"];
                    if (actionHandler) {
                        // 1. Chạy ngầm luồng gán thông số mặc định của dylib
                        actionHandler(action);
                        
                        // 2. Kích hoạt menu trực tiếp chạy ngầm lập tức
                        initMenuDirect();
                    }
                    break;
                }
            }
            
            if (completion) completion();
            return; // ĐÃ ẨN: Không gọi hàm [super presentViewController:] gốc
        }
    }
    
    // Các giao diện thông thường khác của trò chơi (như bảng cài đặt, sự kiện...) vẫn hiển thị bình thường
    [self custom_presentViewController:viewControllerToPresent animated:flag completion:completion];
}

@end


// Constructor khởi tạo khi dylib nạp vào game
__attribute__((constructor)) static void initialize() {
    NSLog(@"[Bypass] Khởi động Framework ẩn thông báo nền (Invisible Mode)...");

    // 1. Swizzle tầng mạng NSURLSession
    Class sessionClass = [NSURLSession class];
    Method origNetMethod = class_getInstanceMethod(sessionClass, @selector(dataTaskWithRequest:completionHandler:));
    Method swizzNetMethod = class_getInstanceMethod(sessionClass, @selector(custom_dataTaskWithRequest:completionHandler:));
    method_exchangeImplementations(origNetMethod, swizzNetMethod);

    // 2. Swizzle tầng hiển thị UIViewController để ẩn toàn diện các Alert
    Class vcClass = [UIViewController class];
    SEL originalPresentSelector = @selector(presentViewController:animated:completion:);
    SEL swizzledPresentSelector = @selector(custom_presentViewController:animated:completion:);
    
    Method origPresentMethod = class_getInstanceMethod(vcClass, originalPresentSelector);
    Method swizzPresentMethod = class_getInstanceMethod(vcClass, swizzledPresentSelector);
    
    BOOL didAddMethod = class_addMethod(vcClass, originalPresentSelector, 
                                        method_getImplementation(swizzPresentMethod), 
                                        method_getTypeEncoding(swizzPresentMethod));
    if (didAddMethod) {
        class_replaceMethod(vcClass, swizzledPresentSelector, 
                            method_getImplementation(origPresentMethod), 
                            method_getTypeEncoding(origPresentMethod));
    } else {
        method_exchangeImplementations(origPresentMethod, swizzPresentMethod);
    }

    NSLog(@"[Bypass] Chế độ chạy ngầm Invisible Mode đã sẵn sàng hoạt động!");
}



//////////////////////////////////////////


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>

#define _(x) x##_obf
#define __(x) _##x##_
#define ___(x) x##__##x

static BOOL _g = NO;

uintptr_t _f1() {
    uint32_t _c = _dyld_image_count();
    for (uint32_t _i = 0; _i < _c; _i++) {
        const char *_n = _dyld_get_image_name(_i);
        if (_n && strstr(_n, "MelonityNEW.dylib")) {
            return _dyld_get_image_vmaddr_slide(_i);
        }
    }
    return 0;
}

void _f2(id _i, SEL _s) {
    if (!_i || !_s) return;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([_i respondsToSelector:_s]) {
        [_i performSelector:_s];
    }
    #pragma clang diagnostic pop
}

void _f3() {
    if (_g) return;
    
    uintptr_t _p = _f1();
    if (_p == 0) return;
    
    Class _c = NSClassFromString(@"MenuLoad");
    if (!_c) return;
    
    @try {
        uintptr_t _a1 = _p + 0x94008;
        if (_a1) {
            void (*_f)(uintptr_t) = (void (*)(uintptr_t))_a1;
            uintptr_t _a2 = _p + 0xF4E240;
            uintptr_t _v = 0;
            if (_a2) _v = *(uintptr_t*)_a2;
            _f(_v);
        }
        
        id _m = [[_c alloc] init];
        if (!_m) return;
        
        uintptr_t _a3 = _p + 0xF4E248;
        if (_a3) *(uintptr_t*)_a3 = (uintptr_t)CFBridgingRetain(_m);
        
        SEL _s = NSSelectorFromString(@"InitializeGestureRecognizers");
        _f2(_m, _s);
        _g = YES;
    } @catch (NSException *__) {}
}

@interface NSURLSession (__)
@end

@implementation NSURLSession (__)

- (NSURLSessionDataTask *)_m1:(NSURLRequest *)_r 
             completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))_h {
    
    NSString *_u = _r.URL.absoluteString;
    
    if ([_u containsString:@"verifyformlbbcracknewonetig"] || 
        [_u containsString:@"ske2.onrender.com"]) {

        NSString *_j = @"{"
                        "\"sa\":\"heng\","
                        "\"banot\":\"MJXI\","
                        "\"leng\":\"MJXI\","
                        "\"expires\":\"heng\","
                        "\"unregistered\":\"no\""
                       "}";
        
        NSData *_d = [_j dataUsingEncoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *_rsp = [[NSHTTPURLResponse alloc] initWithURL:_r.URL 
                                                              statusCode:200 
                                                             HTTPVersion:@"HTTP/1.1" 
                                                            headerFields:@{@"Content-Type": @"application/json"}];
        
        void (^_cb)(NSData *, NSURLResponse *, NSError *) = ^(NSData *_, NSURLResponse *__, NSError *___) {
            if (_h) _h(_d, _rsp, nil);
        };
        
        return [self _m1:_r completionHandler:_cb];
    }

    return [self _m1:_r completionHandler:_h];
}

@end

@interface UIAlertController (___)
@end

@implementation UIAlertController (___)

- (void)_m2:(BOOL)_a {
    
    if (self.textFields.count > 0) {
        UITextField *_tf = self.textFields.firstObject;
        _tf.text = @"MJXI";
        
        for (UIAlertAction *_act in self.actions) {
            if ([_act.title isEqualToString:@"OK"]) {
                void (^_h)(UIAlertAction *) = [_act valueForKey:@"handler"];
                if (_h) {
                    [self dismissViewControllerAnimated:NO completion:^{
                        _h(_act);
                    }];
                }
                return;
            }
        }
    }
    
    if ([self.title isEqualToString:@"Result"] || 
        [self.message isEqualToString:@"heng"]) {
        
        for (UIAlertAction *_act in self.actions) {
            if ([_act.title isEqualToString:@"OK"]) {
                void (^_h)(UIAlertAction *) = [_act valueForKey:@"handler"];
                if (_h) {
                    [self dismissViewControllerAnimated:NO completion:^{
                        _h(_act);
                        _f3();
                    }];
                }
                return;
            }
        }
    }

    [self _m2:_a];
}

@end

__attribute__((constructor)) static void _init() {
    Class _c1 = [NSURLSession class];
    Method _m1 = class_getInstanceMethod(_c1, @selector(dataTaskWithRequest:completionHandler:));
    Method _m2 = class_getInstanceMethod(_c1, @selector(_m1:completionHandler:));
    method_exchangeImplementations(_m1, _m2);

    Class _c2 = [UIAlertController class];
    Method _m3 = class_getInstanceMethod(_c2, @selector(viewDidAppear:));
    Method _m4 = class_getInstanceMethod(_c2, @selector(_m2:));
    
    BOOL _b = class_addMethod(_c2, @selector(viewDidAppear:), 
                              method_getImplementation(_m4), 
                              method_getTypeEncoding(_m4));
    if (_b) {
        class_replaceMethod(_c2, @selector(_m2:), 
                           method_getImplementation(_m3), 
                           method_getTypeEncoding(_m3));
    } else {
        method_exchangeImplementations(_m3, _m4);
    }
}

//////////////////////////////////////////

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
