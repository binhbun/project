#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Security/Security.h>
#import <sys/sysctl.h>
#import <CommonCrypto/CommonDigest.h>
#import <mach-o/loader.h>
#import <mach-o/getsect.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

#define RESERVE_SIGNATURE_SIZE 64
#define RESERVE_PADDING_SIZE 32
#define RESERVE_TOTAL_SIZE (RESERVE_SIGNATURE_SIZE + RESERVE_PADDING_SIZE)

#pragma pack(push, 1)
typedef struct {
    unsigned char signature[RESERVE_SIGNATURE_SIZE];
    unsigned char reserved[RESERVE_PADDING_SIZE];
} IntegrityReserve;
#pragma pack(pop)

__attribute__((used))
__attribute__((section("__DATA,__reserved")))
__attribute__((visibility("hidden")))
static IntegrityReserve g_integrityReserve = {{0}, {0}};

__attribute__((visibility("hidden")))
static const unsigned char _urlds[] = {
    0x0E, 0x21, 0x74, 0x8F, 0xD9, 0xA3, 0x7B, 0x2C, 0x9A, 0xC4,
    0xEB, 0x34, 0x6D, 0x83, 0xC8, 0xB5, 0x35, 0x6A, 0x9D, 0x80,
    0xF3, 0x27, 0x72, 0x9A, 0xDA, 0xF8, 0x67, 0x64, 0x97, 0xF2,
    0xFE, 0x2A, 0x4B, 0x9B, 0xC1, 0xFE, 0x0D, 0x00
};

__attribute__((visibility("hidden")))
static NSString* _9jsyfr(const unsigned char *p) {
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

__attribute__((visibility("hidden")))
static NSString* getAesKeyUrls(void) { return _9jsyfr(_urlds); }

static const struct segment_command_64* _findSegment(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSection(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHeader(void);
static NSString* _calculateTextHash(void);
static void off_8386(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSegment(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;

    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);

    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;

        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSection(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;

    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);

    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;

        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;

            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));

                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}
__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHeader(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHeader, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }

    uintptr_t selfAddr = (uintptr_t)&_findOwnHeader;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;

        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);

        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }

    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calculateTextHash(void) {
    const struct mach_header_64* header = _findOwnHeader();
    if (!header) {
        return nil;
    }

    const struct segment_command_64* textSeg = _findSegment(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }

    const struct section_64* textSect = _findTextSection(header);
    if (!textSect) {
        return nil;
    }

    if (textSeg->vmsize == 0) {
        return nil;
    }


    uint64_t slide = (uint64_t)header - textSeg->vmaddr;

    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;

    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }

    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);

    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);

    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}
__attribute__((visibility("hidden")))
static void off_8386(void) {
    @autoreleasepool {

        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }

        NSString* currentHash = _calculateTextHash();
        if (!currentHash) {
            return;
        }

        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }

        if (![currentHash isEqualToString:storedHash]) {

            NSString* discordUrlStr = getAesKeyUrls();

            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _a1b2c3d4(const unsigned char *p) {
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

__attribute__((visibility("hidden")))
static NSString* getUrls_v1(void) { return _a1b2c3d4(_urlds); }

static const struct segment_command_64* _findSeg_v1(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v1(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v1(void);
static NSString* _calcTextHash_v1(void);
static void data_off_1(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v1(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v1(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v1(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v1, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v1;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v1(void) {
    const struct mach_header_64* header = _findOwnHdr_v1();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v1(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v1(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_1(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v1();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v1();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}


__attribute__((visibility("hidden")))
static NSString* _z9x8y7w6(const unsigned char *p) {
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

__attribute__((visibility("hidden")))
static NSString* getUrls_v2(void) { return _z9x8y7w6(_urlds); }

static const struct segment_command_64* _findSeg_v2(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v2(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v2(void);
static NSString* _calcTextHash_v2(void);
static void data_off_2(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v2(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v2(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v2(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v2, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v2;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v2(void) {
    const struct mach_header_64* header = _findOwnHdr_v2();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v2(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v2(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_2(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v2();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v2();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _m3n4b5v6(const unsigned char *p) {
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

__attribute__((visibility("hidden")))
static NSString* getUrls_v3(void) { return _m3n4b5v6(_urlds); }

static const struct segment_command_64* _findSeg_v3(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v3(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v3(void);
static NSString* _calcTextHash_v3(void);
static void data_off_3(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v3(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v3(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v3(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v3, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v3;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v3(void) {
    const struct mach_header_64* header = _findOwnHdr_v3();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v3(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v3(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_3(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v3();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v3();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _q1w2e3r4(const unsigned char *p) {
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

__attribute__((visibility("hidden")))
static NSString* getUrls_v4(void) { return _q1w2e3r4(_urlds); }

static const struct segment_command_64* _findSeg_v4(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v4(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v4(void);
static NSString* _calcTextHash_v4(void);
static void data_off_4(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v4(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v4(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v4(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v4, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v4;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v4(void) {
    const struct mach_header_64* header = _findOwnHdr_v4();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v4(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v4(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_4(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v4();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v4();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}

__attribute__((visibility("hidden")))
static NSString* _h6g5f4d3(const unsigned char *p) {
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

__attribute__((visibility("hidden")))
static NSString* getUrls_v5(void) { return _h6g5f4d3(_urlds); }

static const struct segment_command_64* _findSeg_v5(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSec_v5(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHdr_v5(void);
static NSString* _calcTextHash_v5(void);
static void data_off_5(void);

__attribute__((visibility("hidden")))
static const struct segment_command_64* _findSeg_v5(const struct mach_header_64* header, const char* segname) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, segname) == 0) {
                return seg;
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct section_64* _findTextSec_v5(const struct mach_header_64* header) {
    if (!header || header->magic != MH_MAGIC_64) return NULL;
    const uint8_t* cmd_ptr = (const uint8_t*)(header + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        const struct load_command* cmd = (const struct load_command*)cmd_ptr;
        if (cmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
            if (strcmp(seg->segname, "__TEXT") == 0) {
                const struct section_64* sections = (const struct section_64*)(cmd_ptr + sizeof(struct segment_command_64));
                for (uint32_t j = 0; j < seg->nsects; j++) {
                    if (strcmp(sections[j].sectname, "__text") == 0) {
                        return &sections[j];
                    }
                }
            }
        }
        cmd_ptr += cmd->cmdsize;
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHdr_v5(void) {
    Dl_info info;
    if (dladdr((const void*)&_findOwnHdr_v5, &info) != 0 && info.dli_fbase != NULL) {
        const struct mach_header* h = (const struct mach_header*)info.dli_fbase;
        if (h->magic == MH_MAGIC_64) {
            return (const struct mach_header_64*)h;
        }
    }
    uintptr_t selfAddr = (uintptr_t)&_findOwnHdr_v5;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const struct mach_header* h = _dyld_get_image_header(i);
        if (!h || h->magic != MH_MAGIC_64) continue;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        const struct mach_header_64* h64 = (const struct mach_header_64*)h;
        const uint8_t* cmd_ptr = (const uint8_t*)(h64 + 1);
        for (uint32_t j = 0; j < h64->ncmds; j++) {
            const struct load_command* cmd = (const struct load_command*)cmd_ptr;
            if (cmd->cmd == LC_SEGMENT_64) {
                const struct segment_command_64* seg = (const struct segment_command_64*)cmd_ptr;
                uintptr_t segStart = (uintptr_t)seg->vmaddr + (uintptr_t)slide;
                uintptr_t segEnd = segStart + (uintptr_t)seg->vmsize;
                if (selfAddr >= segStart && selfAddr < segEnd) {
                    return h64;
                }
            }
            cmd_ptr += cmd->cmdsize;
        }
    }
    return NULL;
}

__attribute__((visibility("hidden")))
static NSString* _calcTextHash_v5(void) {
    const struct mach_header_64* header = _findOwnHdr_v5();
    if (!header) {
        return nil;
    }
    const struct segment_command_64* textSeg = _findSeg_v5(header, "__TEXT");
    if (!textSeg) {
        return nil;
    }
    const struct section_64* textSect = _findTextSec_v5(header);
    if (!textSect) {
        return nil;
    }
    if (textSeg->vmsize == 0) {
        return nil;
    }
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;
    if (hashEndFileOff <= hashStartFileOff) {
        return nil;
    }
    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, hashStartPtr, (CC_LONG)hashSize);
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(hash, &ctx);
    NSMutableString* result = [NSMutableString string];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", hash[i]];
    }
    return result;
}

__attribute__((visibility("hidden")))
static void data_off_5(void) {
    @autoreleasepool {
        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSString* currentHash = _calcTextHash_v5();
        if (!currentHash) {
            return;
        }
        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }
        if (![currentHash isEqualToString:storedHash]) {
            NSString* discordUrlStr = getUrls_v5();
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:discordUrlStr];
                if (discordUrl && [[UIApplication sharedApplication] canOpenURL:discordUrl]) {
                    [[UIApplication sharedApplication] openURL:discordUrl
                                                       options:@{}
                                             completionHandler:^(BOOL success) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                            exit(0);
                        });
                    }];
                } else {
                    exit(0);
                }
            });
        } else {
            NSLog(@"");
        }
    }
}
