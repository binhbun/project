#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static id (*orig_JSONObjectWithData)(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error);

id replaced_JSONObjectWithData(Class self, SEL _cmd, NSData *data, NSJSONReadingOptions opt, NSError **error) {
    if (!data) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!jsonStr) return orig_JSONObjectWithData(self, _cmd, data, opt, error);

    NSError *parseError = nil;
    id jsonObject = orig_JSONObjectWithData(self, _cmd, data, opt, &parseError);
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [jsonObject mutableCopy];
        NSString *action = dict[@"action"];
        
        if ([action isEqualToString:@"crash"]) {
            
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            // NSTimeInterval expireTime = currentTime + (30 * 24 * 60 * 60); 
            
            NSDateComponents *components = [[NSDateComponents alloc] init];
            components.year = 9999;
            components.month = 1;
            components.day = 1;
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDate *expireDate = [calendar dateFromComponents:components];
            NSTimeInterval expireTime = [expireDate timeIntervalSince1970];
            
            NSDictionary *fakeResponse = @{
                @"action": @"ok",
                @"ex": @((long long)expireTime), 
                @"pm": @"200",
                @"sig": @"ab3328878ce8bdff22e91af92afa85ce9d506c3ea5e8fc303ee3affded4ab9bd",
                @"ts": @((long long)currentTime)
            };
            
            return fakeResponse;
        }
        
        return dict;
    }
    
    return jsonObject;
}

__attribute__((constructor)) static void initialize_complete_bypass() {
    @autoreleasepool {
        
        Class jsonClass = NSClassFromString(@"NSJSONSerialization");
        if (jsonClass) {
            SEL jsonSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
            Method jsonMethod = class_getClassMethod(jsonClass, jsonSelector);
            if (jsonMethod) {
                orig_JSONObjectWithData = (id(*)(Class, SEL, NSData*, NSJSONReadingOptions, NSError**))method_setImplementation(jsonMethod, (IMP)replaced_JSONObjectWithData);
            }
        }
    }
}

///////////////////////////////////////




#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#define K 0x5A
#define E(c) ((unsigned char)((c) ^ K))

static inline NSString* dec(const unsigned char* b, int n) {
    NSMutableString* s = [NSMutableString stringWithCapacity:n];
    for (int i = 0; i < n; i++) [s appendFormat:@"%c", b[i] ^ K];
    return s;
}

static const unsigned char _cls[]  = { E('A'),E('D'),E('M'),E('C'),E('h'),E('e'),E('c'),E('k'),E('e'),E('r') };
static const unsigned char _sel1[] = { E('c'),E('h'),E('e'),E('c'),E('k'),E('S'),E('t'),E('a'),E('t'),E('u'),E('s') };
static const unsigned char _sel2[] = { E('s'),E('c'),E('h'),E('e'),E('d'),E('u'),E('l'),E('e'),E('P'),E('e'),E('r'),E('i'),E('o'),E('d'),E('i'),E('c'),E('C'),E('h'),E('e'),E('c'),E('k') };
static const unsigned char _sel3[] = { E('k'),E('i'),E('l'),E('l'),E('W'),E('i'),E('t'),E('h'),E('M'),E('e'),E('s'),E('s'),E('a'),E('g'),E('e'),E(':') };

static void noop_v(id self, SEL _cmd)        {}
static void noop_v_id(id self, SEL _cmd, id msg) {}

%ctor {
    Class cls = NSClassFromString(dec(_cls, 10));
    if (!cls) return;
    Class meta = object_getClass(cls); 
    class_replaceMethod(meta, NSSelectorFromString(dec(_sel1, 11)), (IMP)noop_v,    "v@:");
    class_replaceMethod(meta, NSSelectorFromString(dec(_sel2, 21)), (IMP)noop_v,    "v@:");
    class_replaceMethod(meta, NSSelectorFromString(dec(_sel3, 16)), (IMP)noop_v_id, "v@:@");
}

////
#import <UIKit/UIKit.h>
@interface ADMChecker : NSObject
+ (void)checkStatus;
+ (void)schedulePeriodicCheck;
+ (void)killWithMessage:(id)msg;
@end

%hook ADMChecker

+ (void)checkStatus {
}

+ (void)schedulePeriodicCheck {
}

+ (void)killWithMessage:(id)msg {
    NSLog(@"[Bypass_ADM] Phát hiện cuộc gọi killWithMessage nhưng đã chặn thành công! Thông điệp: %@", msg);
}

%end
