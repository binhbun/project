#!/bin/bash

echo "🔨 Building GMV with integrity hash..."
echo "========================================="

# Clean và build
make clean
make

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful"

DYLIB=".theos/obj/arm64/GMV.dylib"
if [ ! -f "$DYLIB" ]; then
    echo "❌ Dylib not found: $DYLIB"
    exit 1
fi

echo "📁 Dylib: $DYLIB"

# Patch hash
echo ""
echo "🔐 Patching integrity hash..."
python3 patch_hash.py "$DYLIB" "$DYLIB.patched"

if [ $? -ne 0 ]; then
    echo "❌ Patch failed!"
    exit 1
fi

# Replace with patched version
cp "$DYLIB.patched" "$DYLIB"

# Verify patch
echo ""
echo "🔍 Verifying patch..."
RESERVED_OFFSET=$(otool -l "$DYLIB" | grep -A 5 "__reserved" | grep offset | awk '{print $2}')
if [ -n "$RESERVED_OFFSET" ]; then
    echo "✅ Reserved section found at offset: $RESERVED_OFFSET"
    echo "📊 First 32 bytes of reserved:"
    xxd -s $RESERVED_OFFSET -l 32 "$DYLIB"
fi

# ===== QUAN TRỌNG: Package THỦ CÔNG, không dùng make package =====
echo ""
echo "📦 Creating package manually (without rebuild)..."

# Tạo thư mục package
PACKAGE_DIR=".theos/obj/package"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/Library/MobileSubstrate/DynamicLibraries/"
mkdir -p "$PACKAGE_DIR/DEBIAN"

# Copy dylib đã patch (KHÔNG rebuild)
cp "$DYLIB" "$PACKAGE_DIR/Library/MobileSubstrate/DynamicLibraries/"

# Tạo control file
cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: com.gmvmoba.binhbun
Name: GMV
Version: 0.0.1
Architecture: iphoneos-arm
Description: GMV Tweak
Maintainer: binhbun
Author: binhbun
Section: Tweaks
Depends: firmware (>= 12.0)
EOF

# Copy các file khác nếu có
if [ -f "layout/DEBIAN/postinst" ]; then
    cp layout/DEBIAN/postinst "$PACKAGE_DIR/DEBIAN/"
    chmod 755 "$PACKAGE_DIR/DEBIAN/postinst"
fi
if [ -f "layout/DEBIAN/prerm" ]; then
    cp layout/DEBIAN/prerm "$PACKAGE_DIR/DEBIAN/"
    chmod 755 "$PACKAGE_DIR/DEBIAN/prerm"
fi

# Build deb
mkdir -p packages
dpkg-deb -b "$PACKAGE_DIR" "packages/"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Done! Package ready:"
    ls -la packages/*.deb
    
    # Kiểm tra lại hash trong file .deb
    echo ""
    echo "🔍 Verifying hash in .deb..."
    mkdir -p /tmp/extract_deb
    dpkg -x packages/com.gmvmoba.binhbun_0.0.1_iphoneos-arm.deb /tmp/extract_deb
    DEB_DYLIB="/tmp/extract_deb/Library/MobileSubstrate/DynamicLibraries/GMV.dylib"
    if [ -f "$DEB_DYLIB" ]; then
        RESERVED_OFFSET_DEB=$(otool -l "$DEB_DYLIB" | grep -A 5 "__reserved" | grep offset | awk '{print $2}')
        if [ -n "$RESERVED_OFFSET_DEB" ]; then
            echo "✅ Hash in .deb:"
            xxd -s $RESERVED_OFFSET_DEB -l 32 "$DEB_DYLIB"
        fi
    fi
    rm -rf /tmp/extract_deb
    
    echo ""
    echo "📝 To install:"
    echo "   scp packages/com.gmvmoba.binhbun_0.0.1_iphoneos-arm.deb root@<device_ip>:/tmp/"
    echo "   ssh root@<device_ip> dpkg -i /tmp/com.gmvmoba.binhbun_0.0.1_iphoneos-arm.deb"
else
    echo "❌ Package failed!"
    exit 1
fi