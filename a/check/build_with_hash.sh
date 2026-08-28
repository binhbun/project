#!/bin/bash

echo "🔨 Building with hash protection..."
echo "===================================="

# Build
make clean
make

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

DYLIB=".theos/obj/arm64/GMV.dylib"

if [ ! -f "$DYLIB" ]; then
    echo "❌ Dylib not found!"
    exit 1
fi

# Patch
echo "🔐 Patching hash..."
python3 patch_hash.py "$DYLIB" "$DYLIB.patched"

if [ $? -eq 0 ]; then
    cp "$DYLIB.patched" "$DYLIB"
    echo "✅ Hash patched!"
    
    # Package
    echo "📦 Packaging..."
    make package FINALPACKAGE=1
    
    echo "✅ Done!"
    echo "📁 Package: $(ls packages/*.deb)"
else
    echo "❌ Patch failed!"
    exit 1
fi