#import <Foundation/Foundation.h>
#import <dlfcn.h>

__attribute__((constructor))
static void load_hidden_dylib() {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    
    NSString *hiddenPath = [bundlePath stringByAppendingPathComponent:@"PlugIns/80pool.dylib"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:hiddenPath]) {
        void *handle = dlopen([hiddenPath UTF8String], RTLD_NOW);
        if (handle == NULL) {
            NSLog(@"[Loader] : %s", dlerror());
        } else {
            NSLog(@"[Loader] : %@", hiddenPath);
        }
    } else {
        NSLog(@"[Loader]: %@", hiddenPath);
    }
}
