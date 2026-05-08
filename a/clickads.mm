#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface TermsManager : NSObject
@end

@implementation TermsManager

+ (void)showTermsDialog {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 1. Lấy Key Window và RootVC
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) { window = w; break; }
                    }
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
        
        UIViewController *rootVC = window.rootViewController;
        if (!rootVC) return;

        // 2. Tạo Alert Controller
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hi User!"
                                                                       message:@"Click \"Activate\" and wait 30 seconds to unlock."
                                                                      
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // 3. Tạo nút "Read" 
        // Lưu ý: Vì UIAlertAction luôn đóng alert khi nhấn, chúng ta sẽ mở link 
        // và hiện lại 1 alert mới hoặc thay đổi thuộc tính nếu alert cũ chưa bị hủy.
        UIAlertAction *readAction = [UIAlertAction actionWithTitle:@"Activate"
                                                             style:UIAlertActionStyleDestructive
                                                           handler:^(UIAlertAction * _Nonnull action) {
            
            // Mở link điều khoản
            NSURL *url = [NSURL URLWithString:@"https://bio.binhbun.com/api/index.html"];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];

            // Đợi một chút để alert cũ đóng hẳn, sau đó hiện Alert "Check Read"
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                UIAlertController *checkAlert = [UIAlertController alertControllerWithTitle:@"Check Activate"
                                                                                   message:@"Wait 30 seconds to unlock, on the \"Activate\" page to unlock."
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                
                [rootVC presentViewController:checkAlert animated:YES completion:^{
                    // Đóng sau 30 giây kể từ lúc hiện "check read"
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [checkAlert dismissViewControllerAnimated:YES completion:nil];
                    });
                }];
            });
        }];

        [alert addAction:readAction];

        // 4. Hiển thị Alert đầu tiên
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

static __attribute__((constructor)) void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [TermsManager showTermsDialog];
    });
}

@end