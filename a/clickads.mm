#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface TermsManager : NSObject
@end

@implementation TermsManager

static BOOL b1Processing = NO;
static BOOL b1Finished = NO;

static BOOL b2Processing = NO;
static BOOL b2Finished = NO;

static UIAlertController *currentAlert = nil;

+ (void)showTermsDialog {
    dispatch_async(dispatch_get_main_queue(), ^{
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
        if (!rootVC || rootVC.presentedViewController) return;

        // 1. Update English Message
        NSString *msg = @"Please follow the steps in order.";
        if (b1Processing) msg = @"⏳ Verifying \"Step 1\"...\nPlease complete the task on the previous page.";
        else if (b1Finished && !b2Processing) msg = @"✅ Step 1 Complete! Now activate Step 2.";
        else if (b2Processing) msg = @"⏳ Verifying \"Step 2\"...\nPlease complete the task on the previous page.";

        currentAlert = [UIAlertController alertControllerWithTitle:@"Hi User!"
                                                           message:msg
                                                    preferredStyle:UIAlertControllerStyleAlert];

        // --- BUTTON 1 ---
        NSString *t1 = b1Finished ? @"Step 1 ✅" : (b1Processing ? @"Checking..." : @"Step 1");
        UIAlertAction *a1 = [UIAlertAction actionWithTitle:t1 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (!b1Processing && !b1Finished) {
                b1Processing = YES;
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://bio.binhbun.com/api/index.html"] options:@{} completionHandler:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    b1Processing = NO;
                    b1Finished = YES;
                    [self refreshAlert:rootVC];
                });
            }
            [self refreshAlert:rootVC];
        }];

        // Color Logic: Green if processing or finished
        if (b1Processing || b1Finished) {
            [a1 setValue:[UIColor systemGreenColor] forKey:@"titleTextColor"];
        }

        // --- BUTTON 2 ---
        NSString *t2 = b2Processing ? @"Checking..." : @"Step 2";
        UIAlertAction *a2 = [UIAlertAction actionWithTitle:t2 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (b1Finished && !b2Processing) {
                b2Processing = YES;
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://bio.binhbun.com/api1/index.html"] options:@{} completionHandler:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [currentAlert dismissViewControllerAnimated:YES completion:nil];
                    // Reset states if needed for next launch
                    b2Processing = NO;
                    b2Finished = YES;
                });
            }
            [self refreshAlert:rootVC];
        }];

        // Button 2 Styling: Gray if locked, Green if checking
        if (!b1Finished) {
            [a2 setValue:[UIColor grayColor] forKey:@"titleTextColor"];
        } else if (b2Processing) {
            [a2 setValue:[UIColor systemGreenColor] forKey:@"titleTextColor"];
        }

        [currentAlert addAction:a1];
        [currentAlert addAction:a2];
        [rootVC presentViewController:currentAlert animated:YES completion:nil];
    });
}

// Helper to refresh UI without overlapping alerts
+ (void)refreshAlert:(UIViewController *)rootVC {
    if (currentAlert) {
        [currentAlert dismissViewControllerAnimated:NO completion:^{
            [self showTermsDialog];
        }];
    }
}

static __attribute__((constructor)) void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [TermsManager showTermsDialog];
    });
}

@end
