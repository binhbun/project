
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <Security/Security.h>

static NSURL* (*orig_URLWithString)(id, SEL, NSString*);
static id (*orig_loadKey)(id self, SEL _cmd);
static NSString *realKey = nil;
NSURL* new_URLWithString(id self, SEL _cmd, NSString* URLString) {
    if ([URLString containsString:@"firestore.googleapis.com/v1/projects/vntool-license"]) {
        NSString *newURL = [URLString stringByReplacingOccurrencesOfString:@"https://firestore.googleapis.com/v1/projects/vntool-license"
                                                                 withString:@"https://apiff.teamgamehub99.workers.dev/v1/projects/vntool-license"];

        return orig_URLWithString(self, _cmd, newURL);
    }
    return orig_URLWithString(self, _cmd, URLString);
}
static id fixed_loadKey(id self, SEL _cmd) {
    
    if (realKey) {
        NSLog(@" %@", realKey);
        return realKey;
    }
    
    NSString *bbKey = @"HEHEHEHEHEHEHEHEHEHE";
    NSLog(@"%@", bbKey);
    return bbKey;
}

static void (*orig_dataTaskWithRequest)(id, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*));

void new_dataTaskWithRequest(id self, SEL _cmd, NSURLRequest* request, void (^completion)(NSData*, NSURLResponse*, NSError*)) {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    NSURL *originalURL = request.URL;
    
    if ([originalURL.absoluteString containsString:@"firestore.googleapis.com/v1/projects/vntool-license"]) {
        NSString *newURLString = [originalURL.absoluteString stringByReplacingOccurrencesOfString:@"https://firestore.googleapis.com/v1/projects/vntool-license"
                                                                                        withString:@"https://apiff.teamgamehub99.workers.dev/v1/projects/vntool-license"];
        mutableRequest.URL = [NSURL URLWithString:newURLString];
    }
    
    orig_dataTaskWithRequest(self, _cmd, mutableRequest, completion);
}

static void hookMethod(Class cls, SEL selector, IMP newImp, void **origImp) {
    Method method = class_getClassMethod(cls, selector);
    if (!method) {
        method = class_getInstanceMethod(cls, selector);
    }
    
    if (method) {
        if (origImp) {
            *origImp = (void *)method_getImplementation(method);
        }
        method_setImplementation(method, newImp);
        NSLog(@"%s", sel_getName(selector));
    } else {
        NSLog(@"%s", sel_getName(selector));
    }
}

%ctor {
     Class licenseGate = NSClassFromString(@"LicenseGate");
        if (!licenseGate) {
            return;
        }
    hookMethod(licenseGate, sel_registerName("loadKey"), (IMP)fixed_loadKey, (void **)&orig_loadKey);

    Method m1 = class_getClassMethod([NSURL class], @selector(URLWithString:));
    if (m1) {
        orig_URLWithString = (NSURL* (*)(id, SEL, NSString*))method_getImplementation(m1);
        method_setImplementation(m1, (IMP)new_URLWithString);

    }
}



/////////////////sever//////////////////////////////


export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    if (!path.includes('/v1/projects/vntool-license/databases/(default)/documents/')) {
      return fetch(request);
    }

    if (path.includes('/system/maintenance')) {
      return new Response(JSON.stringify({
        "name": "projects/vntool-license/databases/(default)/documents/system/maintenance",
        "fields": {
          "updated_at": {
            "stringValue": "2026-07-07T19:00:00.000000+00:00"
          },
          "message": {
            "stringValue": ""
          },
          "enabled": {
            "booleanValue": false 
          }
        },
        "createTime": "2026-06-19T23:28:23.539259Z",
        "updateTime": "2026-07-07T19:00:00.065126Z"
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
    
    if (path.includes('/licenses/')) {
      return new Response(JSON.stringify({
        "name": "projects/vntool-license/databases/(default)/documents/licenses/HEHEHEHEHEHEHEHEHEHE",
        "fields": {
          "owner": {
            "stringValue": "binhbun"
          },
          "expires_at": {
            "stringValue": "9999-01-01T23:59:59.999999+00:00"  
          },
          "created_at": {
            "stringValue": "2026-06-26T21:37:23.382813+00:00"
          },
          "activations": {
            "integerValue": "1"
          },
          "status": {
            "stringValue": "active"
          },
          "plan": {
            "stringValue": "pro"
          },
          "device_ids": {
            "arrayValue": {
              "values": [
                {
                  "stringValue": "binhbun-gmvmoba"
                }
              ]
            }
          },
          "key_code": {
            "stringValue": "HEHEHEHEHEHEHEHEHEHE"
          },
          "max_activations": {
            "integerValue": "9999"
          }
        },
        "createTime": "2026-06-26T21:37:53.130058Z",
        "updateTime": "2027-07-07T14:04:04.448057Z"
      }), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
    return fetch(request);
  }
};
