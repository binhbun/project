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

// ===== Forward declarations =====
static const struct segment_command_64* _findSegment(const struct mach_header_64* header, const char* segname);
static const struct section_64* _findTextSection(const struct mach_header_64* header);
static const struct mach_header_64* _findOwnHeader(void);
static NSString* _calculateTextHash(void);
static void _verifyIntegrity(void);
// =================================

// Tìm 1 segment theo tên (vd "__TEXT")
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

// Tìm section __text bên trong segment __TEXT (dùng để lấy offset bắt đầu thật,
// bỏ qua header + load commands nằm phía trước — vùng hay bị codesign/esign đụng vào)
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

// Tìm header của chính dylib này (GMV.dylib), fallback về main executable
__attribute__((visibility("hidden")))
static const struct mach_header_64* _findOwnHeader(void) {
    uint32_t imageCount = _dyld_image_count();

    for (uint32_t i = 0; i < imageCount; i++) {
        const char* imageName = _dyld_get_image_name(i);
        if (imageName && strstr(imageName, "GMV.dylib") != NULL) {
            const struct mach_header* h = _dyld_get_image_header(i);
            if (h->magic == MH_MAGIC_64) {
                return (const struct mach_header_64*)h;
            }
        }
    }

    const struct mach_header* h = _dyld_get_image_header(0);
    if (h && h->magic == MH_MAGIC_64) {
        return (const struct mach_header_64*)h;
    }
    return NULL;
}

// Hash từ offset của __text (bỏ header + load commands) đến hết segment __TEXT
// (vẫn bao gồm __cstring, __const, __objc_methname... mọi thứ trừ header/load-commands)
__attribute__((visibility("hidden")))
static NSString* _calculateTextHash(void) {
    const struct mach_header_64* header = _findOwnHeader();
    if (!header) {
        NSLog(@"⚠️ GMVHASH: Cannot find own header");
        return nil;
    }

    const struct segment_command_64* textSeg = _findSegment(header, "__TEXT");
    if (!textSeg) {
        NSLog(@"⚠️ GMVHASH: Cannot find __TEXT segment");
        return nil;
    }

    const struct section_64* textSect = _findTextSection(header);
    if (!textSect) {
        NSLog(@"⚠️ GMVHASH: Cannot find __text section");
        return nil;
    }

    if (textSeg->vmsize == 0) {
        NSLog(@"⚠️ GMVHASH: __TEXT segment vmsize is 0");
        return nil;
    }

    NSLog(@"🔍 GMVHASH: Header address: %p", header);
    NSLog(@"🔍 GMVHASH: __TEXT vmaddr: 0x%llX, vmsize: 0x%llX, fileoff: 0x%llX",
          textSeg->vmaddr, textSeg->vmsize, textSeg->fileoff);
    NSLog(@"🔍 GMVHASH: __text offset: 0x%X", textSect->offset);

    // slide = địa chỉ header đã load trong tiến trình - vmaddr gốc của __TEXT trong file
    uint64_t slide = (uint64_t)header - textSeg->vmaddr;

    // Bắt đầu hash từ offset của __text (bỏ qua header + load commands),
    // kết thúc ở cuối segment __TEXT (vẫn gồm __cstring, __const...)
    uint64_t hashStartFileOff = textSect->offset;
    uint64_t hashEndFileOff   = textSeg->fileoff + textSeg->vmsize;

    if (hashEndFileOff <= hashStartFileOff) {
        NSLog(@"⚠️ GMVHASH: Invalid hash range (start=0x%llX end=0x%llX)", hashStartFileOff, hashEndFileOff);
        return nil;
    }

    uint64_t hashSize = hashEndFileOff - hashStartFileOff;
    const uint8_t* hashStartPtr = (const uint8_t*)(textSeg->vmaddr + hashStartFileOff + slide);

    NSLog(@"🔍 GMVHASH: Hash range fileoff 0x%llX -> 0x%llX (size 0x%llX)",
          hashStartFileOff, hashEndFileOff, hashSize);

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
static void _verifyIntegrity(void) {
    @autoreleasepool {
        NSLog(@"🔍 GMVHASH: ===== START INTEGRITY CHECK =====");
        NSLog(@"🔍 GMVHASH: Reserve address: %p", &g_integrityReserve);

        NSMutableString *debugBytes = [NSMutableString string];
        unsigned char *debugPtr = (unsigned char *)&g_integrityReserve;
        for (int i = 0; i < 64; i++) {
            [debugBytes appendFormat:@"%02x", debugPtr[i]];
        }
        NSLog(@"🔍 GMVHASH: Reserve bytes (64): %@", debugBytes);

        NSString* currentHash = _calculateTextHash();
        if (!currentHash) {
            NSLog(@"⚠️ GMVHASH: Cannot calculate hash");
            return;
        }

        NSMutableString* storedHash = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [storedHash appendFormat:@"%02x", g_integrityReserve.signature[i]];
        }

        NSLog(@"🔍 GMVHASH Current hash: %@", currentHash);
        NSLog(@"🔍 GMVHASH Stored hash: %@", storedHash);
        NSLog(@"🔍 GMVHASH Hash match: %@", [currentHash isEqualToString:storedHash] ? @"YES" : @"NO");

        if (![currentHash isEqualToString:storedHash]) {
            NSLog(@"⚠️ GMVHASH INTEGRITY FAILED! Opening Discord...");

            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* discordUrl = [NSURL URLWithString:@"https://discord.com/invite/ceSbaMnaaG"];
                if ([[UIApplication sharedApplication] canOpenURL:discordUrl]) {
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
            NSLog(@"✅ GMVHASH Integrity check PASSED");
        }
    }
}
