#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *tokenKey = @"UdcQtEfruLt4svh32rOIMCgORz3CyuxDOyNfovwCkbqUxtVtjMrK8hzHos07LZ0d60I1VLKOY0fN34eOuG0ktOYQI6NDClS9tQLe";
static NSString *tieude = @"HỆ THỐNG XÁC THỰC";

@interface CheckKeyView : NSObject
+ (void)loadMenu;
@end

@implementation CheckKeyView {
    NSTimer *autoCheckTimer;
}

static CheckKeyView *mainInstance;

- (UIViewController *)topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

#pragma mark - KHỞI CHẠY

+ (void)loadMenu {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        mainInstance = [[CheckKeyView alloc] init];
        NSString *savedKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedKey"];
        
        if (savedKey) {
            [mainInstance validateKeyOnServer:savedKey isAutoCheck:YES];
        } else {
            [mainInstance showInputUI];
        }
    });
}

#pragma mark - GIAO DIỆN (UI)

- (void)showInputUI {
    [self stopTimer];

    UIView *oldView = [[UIApplication sharedApplication].keyWindow viewWithTag:8888];
    if (oldView) [oldView removeFromSuperview];

    UIView *bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    bgView.tag = 8888;

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 280)];
    box.center = bgView.center;
    box.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:1.0];
    box.layer.cornerRadius = 20;
    box.layer.borderWidth = 1.5;
    box.layer.borderColor = [UIColor systemGreenColor].CGColor;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 300, 30)];
    titleLabel.text = tieude;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:18];

    UITextField *keyField = [[UITextField alloc] initWithFrame:CGRectMake(20, 70, 260, 45)];
    keyField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    keyField.textColor = [UIColor whiteColor];
    keyField.placeholder = @" Nhập hoặc dán key...";
    keyField.layer.cornerRadius = 10;
    keyField.textAlignment = NSTextAlignmentCenter;
    keyField.tag = 1001;

    UIButton *btnPaste = [UIButton buttonWithType:UIButtonTypeSystem];
    btnPaste.frame = CGRectMake(20, 120, 260, 30);
    [btnPaste setTitle:@"📋 Dán từ bộ nhớ tạm" forState:UIControlStateNormal];
    [btnPaste setTitleColor:[UIColor systemYellowColor] forState:UIControlStateNormal];
    [btnPaste addTarget:self action:@selector(actionPaste) forControlEvents:UIControlEventTouchUpInside];

    UIButton *btnCheck = [UIButton buttonWithType:UIButtonTypeSystem];
    btnCheck.frame = CGRectMake(20, 165, 260, 45);
    btnCheck.backgroundColor = [UIColor systemGreenColor];
    [btnCheck setTitle:@"KÍCH HOẠT NGAY" forState:UIControlStateNormal];
    [btnCheck setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btnCheck.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    btnCheck.layer.cornerRadius = 10;
    [btnCheck addTarget:self action:@selector(actionSubmit) forControlEvents:UIControlEventTouchUpInside];

    UIButton *btnGet = [UIButton buttonWithType:UIButtonTypeSystem];
    btnGet.frame = CGRectMake(20, 225, 260, 30);
    [btnGet setTitle:@"🌐 Lấy Key Miễn Phí" forState:UIControlStateNormal];
    [btnGet setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [btnGet addTarget:self action:@selector(actionGetURL) forControlEvents:UIControlEventTouchUpInside];

    [box addSubview:titleLabel]; [box addSubview:keyField]; [box addSubview:btnPaste]; [box addSubview:btnCheck]; [box addSubview:btnGet];
    [bgView addSubview:box];
    [[UIApplication sharedApplication].keyWindow addSubview:bgView];
}

#pragma mark - HÀNH ĐỘNG (ACTIONS)

- (void)actionPaste {
    UITextField *tf = [[UIApplication sharedApplication].keyWindow viewWithTag:1001];
    tf.text = [UIPasteboard generalPasteboard].string ?: @"";
}

- (void)actionSubmit {
    UITextField *tf = [[UIApplication sharedApplication].keyWindow viewWithTag:1001];
    NSString *input = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (input.length < 3) {
        [self showAlert:@"Vui lòng nhập Key!" forceInput:YES];
        return;
    }
    [self validateKeyOnServer:input isAutoCheck:NO];
}

- (void)actionGetURL {
    NSURL *url = [NSURL URLWithString:@"https://getkeyfree.io.vn/lay-link.php?id=4&user=admin"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
    [self showInputUI];
}

#pragma mark - TIMER LOGIC

- (void)startTimer {
    [self stopTimer];
    autoCheckTimer = [NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(backgroundCheck) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    if (autoCheckTimer) {
        [autoCheckTimer invalidate];
        autoCheckTimer = nil;
    }
}

- (void)backgroundCheck {
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedKey"];
    if (savedKey) [self validateKeyOnServer:savedKey isAutoCheck:YES];
}

#pragma mark - SERVER VALIDATION

- (void)validateKeyOnServer:(NSString *)key isAutoCheck:(BOOL)autoCheck {
    NSString *uuid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    NSString *model = [[UIDevice currentDevice] model];
    
    NSString *rawUrl = [NSString stringWithFormat:@"https://getkeyfree.io.vn/key.php?key=%@&uuid=%@&hash=%@&devicemodel=%@", 
                        key, uuid, tokenKey, model];
    NSString *encodedUrl = [rawUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:encodedUrl] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data) return;

        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *status = json[@"status"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([status isEqualToString:@"success"]) {
                [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"SavedKey"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                UIView *bgView = [[UIApplication sharedApplication].keyWindow viewWithTag:8888];
                if (bgView) [bgView removeFromSuperview];
                
                [self startTimer];
                if (!autoCheck) {
                    [self showAlert:[NSString stringWithFormat:@"✅ Thành công!\nHạn dùng: %@", json[@"amount"]] forceInput:NO];
                }
            } else {
                [self stopTimer];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SavedKey"];
                NSString *msg = json[@"messenger"] ?: @"Key đã hết hạn!";
                [self showAlert:[NSString stringWithFormat:@"❌ %@", msg] forceInput:YES];
            }
        });
    }] resume];
}

- (void)showAlert:(NSString *)msg forceInput:(BOOL)force {
    if ([self topMostController].class == [UIAlertController class]) return;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"THÔNG BÁO" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (force) [self showInputUI];
    }]];
    [[self topMostController] presentViewController:alert animated:YES completion:nil];
}

@end

static __attribute__((constructor)) void init() {
    [CheckKeyView loadMenu];
}
