#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Security/Security.h>
#import <sys/sysctl.h>

__attribute__((visibility("hidden"))) static const unsigned char _url1[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xDB, 0xF9, 0x21, 0x63, 0xDD, 0xC0, 0xEC, 0x22, 0x29, 0x91, 0xCF, 0xF1, 0x2F, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url2[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xCD, 0xF2, 0x26, 0x69, 0x97, 0xC2, 0xE8, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url3[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xDB, 0xF9, 0x21, 0x63, 0xDD, 0xD1, 0xEE, 0x24, 0x60, 0x9C, 0xCC, 0xFA, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url4[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xCF, 0xED, 0x21, 0x28, 0x91, 0xC9, 0xF9, 0x28, 0x6D, 0xD8, 0xC2, 0xEA, 0x24, 0x5D, 0x98, 0xC6, 0xB1, 0x2A, 0x55, 0x81, 0xCF, 0xFE, 0x2E, 0x5A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url5[] = {0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x95, 0xC8, 0xE1, 0x79, 0x65, 0x9C, 0xDA, 0xF6, 0x39, 0x67, 0x91, 0x81, 0xF9, 0x26, 0x69, 0xDC, 0xC9, 0xF0, 0x3E, 0x6A, 0x9D, 0xC3, 0xFD, 0x64, 0x61, 0x90, 0xD4, 0xF4, 0x2F, 0x40, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_gmv_pv[] = {0x21, 0x18, 0x56, 0xA0, 0xFA, 0xCF, 0x0B, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_unknown[] = {0x33, 0x1B, 0x4B, 0xB1, 0xE5, 0xCE, 0x1A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_comma[] = {0x4A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _str_placeholder[] = {0x28, 0x3D, 0xE1, 0x45, 0x07, 0xE9, 0x74, 0x68, 0x9B, 0xD4, 0xB8, 0x21, 0xC1, 0x51, 0xC3, 0xBB, 0x92, 0x94, 0x33, 0x0D, 0xE3, 0x67, 0x2A, 0xDD, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_enter_key[] = {0x84, 0xCE, 0x94, 0xDF, 0xFC, 0xEC, 0x3D, 0x23, 0x92, 0x6E, 0x2A, 0x39, 0x65, 0xD1, 0xC2, 0xF3, 0xB7, 0xBF, 0x5D, 0xDF, 0xBA, 0x02, 0x61, 0x8A, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_connect_error[] = {0x84, 0xCE, 0x94, 0xDF, 0xE6, 0x78, 0xEF, 0x94, 0x97, 0x8D, 0xF3, 0xB6, 0xB8, 0x4E, 0xD8, 0xBB, 0x38, 0xE4, 0x4B, 0x3E, 0xF3, 0x69, 0x57, 0x96, 0xDC, 0xEB, 0x2D, 0x75, 0xD3, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_invalid_key[] = {0x84, 0xCE, 0x94, 0xDF, 0xE1, 0xFC, 0x2D, 0x23, 0x95, 0xC5, 0x5B, 0xE3, 0x6C, 0x96, 0x8C, 0xF3, 0xB7, 0xBE, 0x53, 0xDF, 0xBA, 0x25, 0xE5, 0x48, 0x29, 0xBD, 0x20, 0x68, 0x13, 0x1B, 0x2B, 0x28, 0x26, 0x31, 0x31, 0x5C, 0xE9, 0x19, 0x9C, 0x42, 0x24, 0xF2, 0x4C, 0xD7, 0xCA, 0x70, 0xF6, 0x9A, 0x98, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_slot_full[] = {0x84, 0xCE, 0x94, 0xDF, 0xE2, 0x78, 0xEE, 0xBC, 0x8A, 0x8D, 0xEB, 0x3B, 0x6D, 0x85, 0x8C, 0xDC, 0x37, 0x68, 0x95, 0x8F, 0xF9, 0x21, 0x6B, 0xD3, 0xE5, 0xF8, 0x31, 0x27, 0x9C, 0x62, 0x3C, 0x32, 0x27, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_key_used[] = {0x2D, 0x30, 0x79, 0xDF, 0x6E, 0x09, 0x97, 0xA0, 0xDE, 0xC9, 0x5B, 0xEE, 0x6C, 0x96, 0x8C, 0xF8, 0x3E, 0x6A, 0xD0, 0xE8, 0xFB, 0x24, 0x61, 0xD3, 0xC5, 0xF5, 0x8B, 0xA6, 0x91, 0x81, 0xEE, 0xAA, 0xBD, 0x66, 0xC9, 0xBE, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_success[] = {0x84, 0xC9, 0x85, 0xDF, 0xFE, 0xF1, 0x97, 0xA3, 0x90, 0xC5, 0xB8, 0x14, 0xC1, 0x45, 0xC2, 0xFC, 0x77, 0x0F, 0xB8, 0x4E, 0x20, 0xE8, 0x6A, 0xC9, 0x8E, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_get_key[] = {0x21, 0x30, 0x74, 0xDF, 0xE1, 0xFC, 0x2D, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_check_key[] = {0x25, 0x3D, 0x65, 0x9C, 0xC1, 0xB9, 0x1F, 0x66, 0x87, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_paste[] = {0x22, 0x96, 0xA1, 0x91, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_update_title[] = {0x96, 0xCA, 0x9A, 0x7F, 0x8A, 0xDB, 0xB5, 0xB9, 0x5D, 0xC2, 0xB8, 0x03, 0x70, 0x32, 0x14, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_update_btn[] = {0x25, 0xB4, 0xBA, 0x52, 0xDA, 0xB9, 0x1A, 0x6B, 0x1F, 0x17, 0x35, 0x23, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_udid_title[] = {0x3E, 0x96, 0x81, 0xBC, 0x8A, 0xD4, 0x1D, 0x4D, 0xB6, 0x8D, 0xCD, 0x13, 0x4B, 0xB5, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_udid_msg[] = {0x30, 0x20, 0x69, 0xDF, 0xC6, 0x5A, 0xE6, 0x6D, 0x99, 0x8D, 0xDB, 0x3B, 0x6B, 0x92, 0xC7, 0xBB, 0x1A, 0xE4, 0x4A, 0x0A, 0xE3, 0x69, 0x51, 0xB7, 0xE7, 0xD9, 0x68, 0xC3, 0x63, 0x40, 0x27, 0xC8, 0x26, 0x96, 0x63, 0x3F, 0x23, 0x19, 0x30, 0x32, 0x7F, 0xF7, 0x8F, 0x83, 0x82, 0xF9, 0xAD, 0x80, 0x65, 0x85, 0xE3, 0x89, 0x9B, 0xC9, 0xDC, 0x50, 0xEF, 0x5E, 0xC8, 0xCA, 0xFB, 0x2F, 0x54, 0xCB, 0xD2, 0xFD, 0x29, 0xDE, 0x50, 0x66, 0xE0, 0x63, 0x5C, 0x0C, 0x63, 0x1C, 0x6C, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_udid_btn[] = {0x25, 0x39, 0x69, 0x9C, 0xC1, 0xB9, 0x18, 0xE2, 0x44, 0x08, 0xE1, 0x77, 0x57, 0xB5, 0xE5, 0xDF, 0x76, 0x2D, 0xA3, 0xCE, 0xFC, 0x28, 0x76, 0x9A, 0x87, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_waiting_title[] = {0x84, 0xCC, 0xBB, 0x10, 0x12, 0x16, 0x74, 0xC7, 0x6E, 0xEC, 0xD6, 0x10, 0x22, 0xB2, 0xE4, 0x7A, 0xED, 0x99, 0xD0, 0xF7, 0x59, 0xC8, 0x47, 0xD3, 0xE3, 0xD4, 0x06, 0x4F, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_waiting_msg[] = {0xA2, 0xC5, 0x61, 0x91, 0xCD, 0xB9, 0x37, 0x6B, 0x1F, 0x16, 0x05, 0x77, 0x61, 0x32, 0x0C, 0xF2, 0x76, 0xC1, 0x61, 0x4E, 0x20, 0xFE, 0x70, 0xD3, 0xEA, 0xD3, 0x1B, 0x27, 0xA2, 0xD3, 0xF3, 0x2D, 0x6F, 0x99, 0xC5, 0xBF, 0x1F, 0x7D, 0xBD, 0xE7, 0xBE, 0x3B, 0xFB, 0x57, 0x82, 0xE9, 0x8F, 0x9A, 0x95, 0x85, 0xFD, 0x26, 0x54, 0x81, 0x84, 0xE7, 0x3C, 0x52, 0x86, 0xC0, 0xB2, 0x02, 0xFF, 0x4B, 0xCF, 0xB5, 0x84, 0xAE, 0x0B, 0x63, 0x23, 0x37, 0x10, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_ok_btn[] = {0x29, 0x1E, 0x20, 0xB3, 0xDF, 0x5A, 0xE0, 0x6D, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _msg_gmv_title[] = {0x96, 0xCA, 0x94, 0x5A, 0x8A, 0xDE, 0x19, 0x55, 0xDE, 0xE0, 0xD7, 0x15, 0x43, 0xD1, 0x5C, 0x04, 0xC2, 0xA0, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url_param1[] = {0x43, 0x15, 0x3F, 0x9D, 0xC3, 0xFD, 0x69, 0x26, 0xBE, 0x8B, 0xF6, 0x36, 0x6F, 0x94, 0x91, 0xBE, 0x16, 0x23, 0x85, 0xCB, 0xF3, 0x2D, 0x39, 0xD6, 0xEE, 0xBB, 0x3E, 0x62, 0x80, 0x9C, 0xB9, 0x0B, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _url_param2[] = {0x01, 0x34, 0x6D, 0x9A, 0x97, 0xBC, 0x14, 0x25, 0x8B, 0xDE, 0xFD, 0x25, 0x5D, 0x9A, 0xC9, 0xE2, 0x6B, 0x20, 0xB0, 0x89, 0xE9, 0x2C, 0x76, 0x9A, 0xCF, 0xF1, 0x75, 0x22, 0xB2, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _bid_fallback[] = {0x05, 0x3A, 0x6D, 0xD1, 0xCD, 0xF4, 0x22, 0x2D, 0x8B, 0xC3, 0xF3, 0x39, 0x6D, 0x86, 0xC2, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_update_link[] = {0x13, 0x25, 0x64, 0x9E, 0xDE, 0xFC, 0x0B, 0x6F, 0x97, 0xC3, 0xF3, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_update_msg[] = {0x13, 0x25, 0x64, 0x9E, 0xDE, 0xFC, 0x0B, 0x6E, 0x8D, 0xCA, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_require_key[] = {0x14, 0x30, 0x71, 0x8A, 0xC3, 0xEB, 0x31, 0x5C, 0x95, 0xC8, 0xE1, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_status[] = {0x15, 0x21, 0x61, 0x8B, 0xDF, 0xEA, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_reason[] = {0x14, 0x30, 0x61, 0x8C, 0xC5, 0xF7, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_device_used[] = {0x02, 0x30, 0x76, 0x96, 0xC9, 0xFC, 0x0B, 0x76, 0x8D, 0xC8, 0xFC, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_device[] = {0x02, 0x30, 0x76, 0x96, 0xC9, 0xFC, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_data[] = {0x02, 0x34, 0x74, 0x9E, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _key_exp[] = {0x23, 0x0D, 0x50, 0x00};

__attribute__((visibility("hidden"))) static const unsigned char _cls_rotate[] = {0x39, 0x23, 0x67, 0xcd, 0xc5, 0xf7, 0x62, 0x77, 0xcb, 0xda, 0xf7, 0x00};
__attribute__((visibility("hidden"))) static const unsigned char _cls_paste[] = {0x39, 0x6c, 0x72, 0x8f, 0xcd, 0xf8, 0x26, 0x31, 0x96, 0xca, 0xf3, 0x00};

#define GAME_NAME @"PUBG"
#define ZALO_INFO @"૮₍´˶• . • ⑅ ₎ა"

__attribute__((visibility("hidden"))) static NSString* _f9a1c(const unsigned char *p) {
    if (!p) return @"";
    NSMutableData *d = [NSMutableData data];
    NSUInteger n = 0, i = 0;
    int st = 0;
    while (st != 2) {
        switch (st) {
            case 0: { while (p[n] != 0x00) n++; st = 1; break; }
            case 1: {
                if (i < n) {
                    unsigned char v = p[i] ^ 0x55 ^ (i * 0x33) ^ 0x33;
                    [d appendBytes:&v length:1];
                    i++;
                    st = 1;
                } else st = 2;
                break;
            }
            default: st = 2; break;
        }
    }
    return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

__attribute__((visibility("hidden"))) static NSString* _fb2d0(void) { return _f9a1c(_url1); }
__attribute__((visibility("hidden"))) static NSString* _fc3e1(void) { return _f9a1c(_url2); }
__attribute__((visibility("hidden"))) static NSString* _fd4f2(void) { return _f9a1c(_url3); }
__attribute__((visibility("hidden"))) static NSString* _fe503(void) { return _f9a1c(_url5); }
__attribute__((visibility("hidden"))) static NSString* _ff614(void) { return _f9a1c(_url4); }
__attribute__((visibility("hidden"))) static NSString* _f0725(void) { return _f9a1c(_str_unknown); }
__attribute__((visibility("hidden"))) static NSString* _f1836(void) { return _f9a1c(_str_comma); }
__attribute__((visibility("hidden"))) static NSString* _f2947(void) { return _f9a1c(_str_gmv_pv); }
__attribute__((visibility("hidden"))) static NSString* _f3a58(void) { return _f9a1c(_str_placeholder); }
__attribute__((visibility("hidden"))) static NSString* _f4b69(void) { return _f9a1c(_msg_enter_key); }
__attribute__((visibility("hidden"))) static NSString* _f5c7a(void) { return _f9a1c(_msg_connect_error); }
__attribute__((visibility("hidden"))) static NSString* _f6d8b(void) { return _f9a1c(_msg_invalid_key); }
__attribute__((visibility("hidden"))) static NSString* _f7e9c(void) { return _f9a1c(_msg_slot_full); }
__attribute__((visibility("hidden"))) static NSString* _f8fad(void) { return _f9a1c(_msg_key_used); }
__attribute__((visibility("hidden"))) static NSString* _f900e(void) { return _f9a1c(_msg_success); }
__attribute__((visibility("hidden"))) static NSString* _fa11f(void) { return _f9a1c(_msg_get_key); }
__attribute__((visibility("hidden"))) static NSString* _fb220(void) { return _f9a1c(_msg_check_key); }
__attribute__((visibility("hidden"))) static NSString* _fc331(void) { return _f9a1c(_msg_paste); }
__attribute__((visibility("hidden"))) static NSString* _fd442(void) { return _f9a1c(_msg_update_title); }
__attribute__((visibility("hidden"))) static NSString* _fe553(void) { return _f9a1c(_msg_update_btn); }
__attribute__((visibility("hidden"))) static NSString* _ff664(void) { return _f9a1c(_msg_udid_title); }
__attribute__((visibility("hidden"))) static NSString* _f0775(void) { return _f9a1c(_msg_udid_msg); }
__attribute__((visibility("hidden"))) static NSString* _f1886(void) { return _f9a1c(_msg_udid_btn); }
__attribute__((visibility("hidden"))) static NSString* _f2997(void) { return _f9a1c(_msg_waiting_title); }
__attribute__((visibility("hidden"))) static NSString* _f3aa8(void) { return _f9a1c(_msg_waiting_msg); }
__attribute__((visibility("hidden"))) static NSString* _f4bb9(void) { return _f9a1c(_msg_ok_btn); }
__attribute__((visibility("hidden"))) static NSString* _f5cca(void) { return _f9a1c(_msg_gmv_title); }
__attribute__((visibility("hidden"))) static NSString* _f6ddb(void) { return _f9a1c(_url_param1); }
__attribute__((visibility("hidden"))) static NSString* _f7eec(void) { return _f9a1c(_url_param2); }
__attribute__((visibility("hidden"))) static NSString* _f8ffd(void) { return _f9a1c(_bid_fallback); }
__attribute__((visibility("hidden"))) static NSString* _f900f(void) { return _f9a1c(_key_update_link); }
__attribute__((visibility("hidden"))) static NSString* _fa120(void) { return _f9a1c(_key_update_msg); }
__attribute__((visibility("hidden"))) static NSString* _fb231(void) { return _f9a1c(_key_require_key); }
__attribute__((visibility("hidden"))) static NSString* _fc342(void) { return _f9a1c(_key_status); }
__attribute__((visibility("hidden"))) static NSString* _fd453(void) { return _f9a1c(_key_reason); }
__attribute__((visibility("hidden"))) static NSString* _fe564(void) { return _f9a1c(_key_device_used); }
__attribute__((visibility("hidden"))) static NSString* _ff675(void) { return _f9a1c(_key_device); }
__attribute__((visibility("hidden"))) static NSString* _f0786(void) { return _f9a1c(_key_data); }
__attribute__((visibility("hidden"))) static NSString* _f1897(void) { return _f9a1c(_key_exp); }

__attribute__((visibility("hidden"))) static NSString* _f29a8(void) { return @"GMV_UDID_DEVICE"; }
__attribute__((visibility("hidden"))) static NSString* _f3ab9(NSString *k) {
    volatile int _j1 = 41; volatile int _j2 = _j1 ^ 17; (void)_j2;
    return [NSString stringWithFormat:@"GMV_TRK_%@", k];
}

static const unsigned char _sel_mainBundle[] = {0xb, 0x34, 0x69, 0x91, 0xe8, 0xec, 0x3a, 0x67, 0x92, 0xc8, 0x00};
static const unsigned char _sel_bundleId[] = {0x4, 0x20, 0x6e, 0x9b, 0xc6, 0xfc, 0x1d, 0x67, 0x9b, 0xc3, 0xec, 0x3e, 0x64, 0x98, 0xc9, 0xe9, 0x00};
static const unsigned char _sel_mutCopy[] = {0xb, 0x20, 0x74, 0x9e, 0xc8, 0xf5, 0x31, 0x40, 0x91, 0xdd, 0xe1, 0x00};
static const unsigned char _sel_invSet[] = {0xf, 0x3b, 0x76, 0x9a, 0xd8, 0xed, 0x31, 0x67, 0xad, 0xc8, 0xec, 0x00};
static const unsigned char _sel_charSetWith[] = {0x5, 0x3d, 0x61, 0x8d, 0xcb, 0xfa, 0x20, 0x66, 0x8c, 0xfe, 0xfd, 0x23, 0x55, 0x98, 0xd8, 0xf3, 0x15, 0x6d, 0x91, 0xdd, 0xfb, 0x2a, 0x70, 0x96, 0xdc, 0xee, 0x01, 0x69, 0xa1, 0xd5, 0xee, 0x22, 0x68, 0x92, 0x9a, 0x00};
static const unsigned char _sel_compSepBy[] = {0x5, 0x3a, 0x6d, 0x8f, 0xc5, 0xf7, 0x31, 0x6d, 0x8a, 0xde, 0xcb, 0x32, 0x72, 0x90, 0xde, 0xfa, 0x22, 0x60, 0x94, 0xed, 0xe3, 0x0a, 0x6c, 0x92, 0xdc, 0xfc, 0x2b, 0x73, 0x97, 0xd3, 0xef, 0x02, 0x68, 0xa6, 0xc5, 0xeb, 0x70, 0x00};
static const unsigned char _sel_compJoinBy[] = {0x5, 0x3a, 0x6d, 0x8f, 0xc5, 0xf7, 0x31, 0x6d, 0x8a, 0xde, 0xd2, 0x38, 0x6b, 0x9f, 0xc9, 0xff, 0x14, 0x7c, 0xa3, 0xdb, 0xe8, 0x20, 0x6a, 0x94, 0x94, 0x00};

static inline SEL _selOf(const unsigned char *enc) {
    return NSSelectorFromString(_f9a1c(enc));
}

static const unsigned char _sel_objForKey[] = {0x9, 0x37, 0x6a, 0x9a, 0xc9, 0xed, 0x12, 0x6c, 0x8c, 0xe6, 0xfd, 0x2e, 0x67, 0x95, 0xff, 0xee, 0x34, 0x76, 0x93, 0xdd, 0xf3, 0x39, 0x70, 0xc9, 0x00};
static const unsigned char _sel_boolVal[] = {0x4, 0x3a, 0x6f, 0x93, 0xfc, 0xf8, 0x38, 0x76, 0x9b, 0x00};
static const unsigned char _sel_intVal[] = {0xf, 0x3b, 0x74, 0xa9, 0xcb, 0xf5, 0x21, 0x66, 0x00};

static inline id _jGet(id dict, NSString *key) {
    return ((id(*)(id, SEL, id))objc_msgSend)(dict, _selOf(_sel_objForKey), key);
}
static inline BOOL _jBool(id x) {
    return ((BOOL(*)(id, SEL))objc_msgSend)(x, _selOf(_sel_boolVal));
}
static inline NSInteger _jInt(id x) {
    return ((NSInteger(*)(id, SEL))objc_msgSend)(x, _selOf(_sel_intVal));
}

__attribute__((visibility("hidden"))) static NSString* _f4bca(void) {
    id bundleCls = objc_getClass("NSBundle");
    id bundle = ((id(*)(id, SEL))objc_msgSend)(bundleCls, _selOf(_sel_mainBundle));
    id rawBid = ((id(*)(id, SEL))objc_msgSend)(bundle, _selOf(_sel_bundleId));
    NSString *bid = rawBid ?: _f8ffd();

    NSMutableString *ms = ((id(*)(id, SEL))objc_msgSend)(bid, _selOf(_sel_mutCopy));
    CFStringTransform((__bridge CFMutableStringRef)ms, NULL, kCFStringTransformStripDiacritics, NO);

    id charSetCls = objc_getClass("NSCharacterSet");
    NSString *allowedChars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.";
    NSCharacterSet *allowed = ((id(*)(id, SEL, id))objc_msgSend)(charSetCls, _selOf(_sel_charSetWith), allowedChars);
    id inverted = ((id(*)(id, SEL))objc_msgSend)(allowed, _selOf(_sel_invSet));
    id parts = ((id(*)(id, SEL, id))objc_msgSend)(ms, _selOf(_sel_compSepBy), inverted);
    id joined = ((id(*)(id, SEL, id))objc_msgSend)(parts, _selOf(_sel_compJoinBy), @"");
    return joined;
}

__attribute__((visibility("hidden"))) static NSString* _f5cdb(void) {
    return [NSString stringWithFormat:@"%@%@", _f2947(), _f4bca()];
}


static BOOL _f6dec_shouldAutorotate(id self, SEL _cmd) { return YES; }
static NSUInteger _f7edf_orientMask(id self, SEL _cmd) { return UIInterfaceOrientationMaskLandscape; }
static NSInteger _f8fe0_preferredOrient(id self, SEL _cmd) { return UIInterfaceOrientationLandscapeRight; }
static void _f900f_viewWillLayout(id self, SEL _cmd) {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    ((void(*)(struct objc_super*, SEL))objc_msgSendSuper)(&sup, _cmd);
    UIView *v = ((id(*)(id, SEL))objc_msgSend)(self, @selector(view));
    UIWindow *w = ((id(*)(id, SEL))objc_msgSend)(v, @selector(window));
    if (w) {
        CGRect b = ((CGRect(*)(id, SEL))objc_msgSend)(w, @selector(bounds));
        ((void(*)(id, SEL, CGRect))objc_msgSend)(v, @selector(setFrame:), b);
    }
}

static Class _f0721_registerRotateClass(void) {
    NSString *name = _f9a1c(_cls_rotate);
    Class existing = NSClassFromString(name);
    if (existing) return existing;

    Class cls = objc_allocateClassPair([UIViewController class], [name UTF8String], 0);
    class_addMethod(cls, @selector(shouldAutorotate), (IMP)_f6dec_shouldAutorotate, "c@:");
    class_addMethod(cls, @selector(supportedInterfaceOrientations), (IMP)_f7edf_orientMask, "Q@:");
    class_addMethod(cls, @selector(preferredInterfaceOrientationForPresentation), (IMP)_f8fe0_preferredOrient, "q@:");
    class_addMethod(cls, @selector(viewWillLayoutSubviews), (IMP)_f900f_viewWillLayout, "v@:");
    objc_registerClassPair(cls);
    return cls;
}

static void _f1832_handlePaste(id self, SEL _cmd, UIButton *sender) {
    UITextField *t = (UITextField *)objc_getAssociatedObject(sender, "targetField");
    if (t) t.text = [UIPasteboard generalPasteboard].string;
}

static Class _f2943_registerPasteClass(void) {
    NSString *name = _f9a1c(_cls_paste);
    Class existing = NSClassFromString(name);
    if (existing) return existing;

    Class cls = objc_allocateClassPair([NSObject class], [name UTF8String], 0);
    class_addMethod(object_getClass(cls), @selector(handlePaste:), (IMP)_f1832_handlePaste, "v@:@");
    objc_registerClassPair(cls);
    return cls;
}

typedef struct {
    UIWindow *w;
    UIVisualEffectView *bv;
    BOOL checking;
    BOOL dialogVisible;
    BOOL lastRequireKey;
    NSTimer *timer;
} _St;

__attribute__((visibility("hidden"))) static _St _gs = {0};
__attribute__((visibility("hidden"))) static UIAlertController *_gAlert = nil;

__attribute__((visibility("hidden"))) static void _f3a54(NSString *k);
__attribute__((visibility("hidden"))) static void _f4b65(NSString *k);
__attribute__((visibility("hidden"))) static void _f5c76(NSString *l, NSString *m);
__attribute__((visibility("hidden"))) static void _f6d87(NSString *initialKey);
__attribute__((visibility("hidden"))) static void _f7e98(void);
__attribute__((visibility("hidden"))) static void _f8fa9(void);

__attribute__((visibility("hidden"))) static NSMutableArray* _f900a(NSString *key) {
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f3ab9(key),
        (__bridge id)kSecReturnData: @YES
    };
    CFTypeRef ref = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &ref) == errSecSuccess) {
        NSData *d = (__bridge_transfer NSData *)ref;
        NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
        return [[s componentsSeparatedByString:_f1836()] mutableCopy];
    }
    return [NSMutableArray array];
}

__attribute__((visibility("hidden"))) static void _fa11b(NSArray *bids, NSString *key) {
    NSString *s = [bids componentsJoinedByString:_f1836()];
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f3ab9(key)
    };
    SecItemDelete((__bridge CFDictionaryRef)q);
    NSMutableDictionary *m = [q mutableCopy];
    [m setObject:d forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)m, NULL);
}

__attribute__((visibility("hidden"))) static void _fb22c(NSString *key) {
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f3ab9(key)
    };
    SecItemDelete((__bridge CFDictionaryRef)q);
}

__attribute__((visibility("hidden"))) static void _fc33d(NSString *key) {
    if (!key) return;
    NSData *kd = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *pq = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f5cdb()
    };
    SecItemDelete((__bridge CFDictionaryRef)pq);
    NSMutableDictionary *p = [pq mutableCopy];
    [p setObject:kd forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)p, NULL);
}

__attribute__((visibility("hidden"))) static NSString* _fd44e(void) {
    NSDictionary *q = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: _f5cdb(),
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    CFTypeRef ref = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &ref) == errSecSuccess) {
        NSData *d = (__bridge_transfer NSData *)ref;
        return [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    }
    return nil;
}

__attribute__((visibility("hidden"))) static void _fe55f(void) {
    if (!_gs.w) {
        _gs.w = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _gs.w.windowLevel = UIWindowLevelStatusBar + 999.0;

        Class rotateCls = _f0721_registerRotateClass();
        _gs.w.rootViewController = [[rotateCls alloc] init];
        _gs.w.backgroundColor = [UIColor clearColor];

        UIBlurEffect *be = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _gs.bv = [[UIVisualEffectView alloc] initWithEffect:be];

        CGRect sr = [UIScreen mainScreen].bounds;
        CGFloat side = MAX(sr.size.width, sr.size.height) * 1.5;
        _gs.bv.frame = CGRectMake(0, 0, side, side);
        _gs.bv.center = _gs.w.center;
        _gs.bv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _gs.bv.alpha = 0.0;

        UIView *ov = [[UIView alloc] initWithFrame:_gs.bv.bounds];
        ov.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [_gs.bv.contentView addSubview:ov];
        [_gs.w.rootViewController.view addSubview:_gs.bv];

        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
                if (sc.activationState == UISceneActivationStateForegroundActive) {
                    _gs.w.windowScene = sc;
                    break;
                }
            }
        }
    }
}

__attribute__((visibility("hidden"))) static void _ff660(BOOL a) {
    [UIView animateWithDuration:0.3 animations:^{ _gs.bv.alpha = a ? 1.0 : 0.0; }];
}

__attribute__((visibility("hidden"))) static void _f0771(void) {
    _gs.dialogVisible = NO;
    _ff660(NO);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _gs.w.hidden = YES;
    });
}

__attribute__((visibility("hidden"))) static void _f1882(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        _fe55f();
        _gs.w.hidden = NO;
        UIAlertController *t = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
        [_gs.w.rootViewController presentViewController:t animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [t dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

__attribute__((visibility("hidden"))) static void _f2993(NSString *userKey, NSDictionary *json) {
    _fc33d(userKey);
    NSString *exp = _jGet(_jGet(json, _f0786()), _f1897()) ?: @"N/A";
    _f1882([NSString stringWithFormat:@"%@%@", _f900e(), exp]);

    if (!_gs.timer || ![_gs.timer isValid]) {
        __block void (^blk)(void) = ^{
            NSString *sk = _fd44e();
            if (sk && sk.length > 1) {
                _f4b65(sk);
            } else if (_gs.timer) {
                [_gs.timer invalidate];
                _gs.timer = nil;
            }
        };
        _gs.timer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                       target:[NSBlockOperation blockOperationWithBlock:blk]
                                                     selector:@selector(main)
                                                     userInfo:nil
                                                      repeats:YES];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ _f0771(); });
}

__attribute__((visibility("hidden"))) static void _f3a54(NSString *userKey) {
    if (!userKey || userKey.length < 2) {
        _f1882(_f4b69());
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            _gs.dialogVisible = NO;
            _f6d87(nil);
        });
        return;
    }

    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:_f29a8()] ?: _f0725();
    NSString *base = _fc3e1();
    NSString *fmt = _f7eec();

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:base]];
    req.HTTPMethod = @"POST";
    NSString *params = [NSString stringWithFormat:fmt, GAME_NAME, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err || !data) {
                _f1882(_f5c7a());
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    _gs.dialogVisible = NO;
                    _f6d87(userKey);
                });
                return;
            }

            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json) return;

            NSString *reason = _jGet(json, _fd453()) ?: _f6d8b();

            BOOL statusVal = _jBool(_jGet(json, _fc342()));
            intptr_t addrMix = (intptr_t)(__bridge void*)json;
            int chk = (int)(addrMix & 0xF);
            BOOL gate = ((chk * chk) >= 0) ? statusVal : !statusVal;

            if (gate) {
                int used = (int)_jInt(_jGet(_jGet(json, _f0786()), _fe564()));
                int maxSlot = (int)_jInt(_jGet(_jGet(json, _f0786()), _ff675()));
                NSString *bid = _f4bca();
                NSMutableArray *saved = _f900a(userKey);

                if (used == 0 && saved.count > 0) {
                    _fb22c(userKey);
                    [saved removeAllObjects];
                }

                if ([saved containsObject:bid]) {
                    _f2993(userKey, json);
                } else if (saved.count < maxSlot) {
                    [saved addObject:bid];
                    _fa11b(saved, userKey);
                    _f2993(userKey, json);
                } else {
                    _f1882([NSString stringWithFormat:@"%@\n%@", _f7e9c(), _f8fad()]);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        _gs.dialogVisible = NO;
                        _f6d87(userKey);
                    });
                }
            } else {
                _f1882([NSString stringWithFormat:@"⛔ %@", reason]);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    _gs.dialogVisible = NO;
                    _f6d87(userKey);
                });
            }
        });
    }] resume];
}

__attribute__((visibility("hidden"))) static void _f4b65(NSString *userKey) {
    if (!userKey || userKey.length < 2) return;

    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:_f29a8()] ?: _f0725();
    NSString *base = _fc3e1();
    NSString *fmt = _f7eec();

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:base]];
    req.HTTPMethod = @"POST";
    req.timeoutInterval = 10.0;
    NSString *params = [NSString stringWithFormat:fmt, GAME_NAME, userKey, udid];
    req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (err || !data) return;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (!_jBool(_jGet(json, _fc342()))) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_gs.timer) { [_gs.timer invalidate]; _gs.timer = nil; }
                NSString *reason = _jGet(json, _fd453()) ?: _f6d8b();
                _f1882([NSString stringWithFormat:@"⛔ %@", reason]);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    _fe55f();
                    _gs.w.hidden = NO;
                    [_gs.w makeKeyAndVisible];
                    _gs.dialogVisible = NO;
                    _f6d87(userKey);
                });
            });
        }
    }] resume];
}

__attribute__((visibility("hidden"))) static void _f6d87(NSString *initialKey) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_gs.dialogVisible) return;

        _fe55f();
        _gs.w.hidden = NO;
        _gs.w.userInteractionEnabled = YES;
        _ff660(YES);
        _gs.dialogVisible = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:_f5cca() message:nil preferredStyle:UIAlertControllerStyleAlert];

        NSString *msg = ZALO_INFO;
        NSMutableAttributedString *am = [[NSMutableAttributedString alloc] initWithString:msg];
        [am addAttribute:NSForegroundColorAttributeName value:[UIColor systemGreenColor] range:NSMakeRange(0, msg.length)];
        [alert setValue:am forKey:@"attributedMessage"];

        Class pasteCls = _f2943_registerPasteClass();

        [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.placeholder = _f3a58();
            tf.textAlignment = NSTextAlignmentCenter;
            tf.text = initialKey ?: _fd44e();

            UIButton *pb = [UIButton buttonWithType:UIButtonTypeSystem];
            [pb setTitle:_fc331() forState:UIControlStateNormal];
            pb.frame = CGRectMake(0, 0, 45, 30);
            [pb addTarget:pasteCls action:@selector(handlePaste:) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(pb, "targetField", tf, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            tf.rightView = pb;
            tf.rightViewMode = UITextFieldViewModeAlways;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:_fa11f() style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_fe503()] options:@{} completionHandler:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                _gs.dialogVisible = NO;
                _f6d87(nil);
            });
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:_fb220() style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            _gs.dialogVisible = NO;
            _f3a54(alert.textFields.firstObject.text);
        }]];

        [_gs.w.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((visibility("hidden"))) static void _f5c76(NSString *link, NSString *msg) {
    _fe55f();
    _gs.w.hidden = NO;
    _ff660(YES);

    _gAlert = [UIAlertController alertControllerWithTitle:_fd442() message:msg preferredStyle:UIAlertControllerStyleAlert];
    [_gAlert addAction:[UIAlertAction actionWithTitle:_fe553() style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link] options:@{} completionHandler:^(BOOL ok) {
            exit(0);
        }];
    }]];
    [_gs.w.rootViewController presentViewController:_gAlert animated:YES completion:nil];
}

__attribute__((visibility("hidden"))) static void _f7e98(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_gs.dialogVisible) return;

        _fe55f();
        _gs.w.hidden = NO;
        _ff660(YES);
        _gs.dialogVisible = YES;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:_ff664() message:_f0775() preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *act = [UIAlertAction actionWithTitle:_f1886() style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_fd4f2()] options:@{} completionHandler:^(BOOL ok) {
                if (ok) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        UIAlertController *wa = [UIAlertController alertControllerWithTitle:_f2997() message:_f3aa8() preferredStyle:UIAlertControllerStyleAlert];
                        [wa addAction:[UIAlertAction actionWithTitle:_f4bb9() style:UIAlertActionStyleDefault handler:^(UIAlertAction *a2) {
                            _f0771();
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ exit(0); });
                        }]];
                        [_gs.w.rootViewController presentViewController:wa animated:YES completion:nil];
                    });
                }
            }];
        }];

        [alert addAction:act];
        [_gs.w.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((visibility("hidden"))) static void _f8fa9(void) {
    NSString *api = _fb2d0();
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:api] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];

    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err || !data) { _f7e98(); return; }
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json || !_jBool(_jGet(json, _fc342())) || !_jGet(json, @"udid")) { _f7e98(); return; }

            NSString *udid = _jGet(json, @"udid");
            [[NSUserDefaults standardUserDefaults] setObject:udid forKey:_f29a8()];
            [[NSUserDefaults standardUserDefaults] synchronize];

            NSString *sk = _fd44e();
            if (sk) { _f3a54(sk); } else { _f6d87(nil); }
        });
    }] resume];
}

__attribute__((visibility("hidden"))) static void _f900b(void) {
    if (_gs.checking) return;
    _gs.checking = YES;

    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: @"1.0.0";
    NSString *udid = [[NSUserDefaults standardUserDefaults] objectForKey:_f29a8()] ?: _f0725();
    NSString *rawBid = _f4bca();
    NSString *encBid = [rawBid stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *server = _ff614();
    NSString *fmt = _f6ddb();

    NSString *urlStr = [NSString stringWithFormat:fmt, server, encBid,
                        [GAME_NAME stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                        udid, ver];

    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) { _gs.checking = NO; return; }

    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _gs.checking = NO;
            if (err || !data) return;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (!json) return;

            BOOL forceUpdate = _jBool(_jGet(json, @"force_update"));
            BOOL requireKey = _jGet(json, _fb231()) ? _jBool(_jGet(json, _fb231())) : YES;

            if (forceUpdate) {
                NSString *link = _jGet(json, _f900f()) ?: @"";
                NSString *msg = _jGet(json, _fa120()) ?: @"Update required";
                if (!_gAlert) {
                    [_gs.w.rootViewController dismissViewControllerAnimated:NO completion:nil];
                    _f5c76(link, msg);
                }
                return;
            } else if (_gAlert) {
                [_gAlert dismissViewControllerAnimated:YES completion:nil];
                _gAlert = nil;
                _f0771();
            }

            if (!requireKey) {
                _gs.lastRequireKey = NO;
                _f0771();
                return;
            }

            _gs.lastRequireKey = YES;
            if (!_gs.dialogVisible) { _f8fa9(); }
        });
    }] resume];
}

__attribute__((visibility("hidden"))) __attribute__((constructor))
static void _finit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _f900b();
    });
}
