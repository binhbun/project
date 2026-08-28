#!/usr/bin/env python3
import sys
import hashlib
import os
import shutil
import subprocess
import re

def get_segment_info(dylib_path, segname):
    """Lấy fileoff và filesize của 1 segment (vd __TEXT) qua otool -l"""
    result = subprocess.run(['otool', '-l', dylib_path], capture_output=True, text=True)
    lines = result.stdout.split('\n')

    fileoff = -1
    filesize = -1

    i = 0
    while i < len(lines):
        line = lines[i]
        if re.search(r'^\s*segname\s+' + re.escape(segname) + r'\s*$', line):
            for j in range(i, min(len(lines), i + 15)):
                if re.search(r'^\s*fileoff\s+\d+', lines[j]):
                    m = re.search(r'fileoff\s+(\d+)', lines[j])
                    if m:
                        fileoff = int(m.group(1))
                if re.search(r'^\s*filesize\s+\d+', lines[j]):
                    m = re.search(r'filesize\s+(\d+)', lines[j])
                    if m:
                        filesize = int(m.group(1))
                if fileoff != -1 and filesize != -1:
                    break
            break
        i += 1

    return fileoff, filesize


def get_section_offset(dylib_path, segname, sectname):
    """Lấy offset của 1 section cụ thể (dùng cho __reserved và __text)"""
    result = subprocess.run(['otool', '-l', dylib_path], capture_output=True, text=True)
    lines = result.stdout.split('\n')

    current_segname = None
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.search(r'^\s*segname\s+' + re.escape(segname) + r'\s*$', line):
            current_segname = segname
        if current_segname == segname and re.search(r'^\s*sectname\s+' + re.escape(sectname) + r'\s*$', line):
            for j in range(i, min(len(lines), i + 10)):
                if re.search(r'^\s*offset\s+\d+', lines[j]):
                    m = re.search(r'offset\s+(\d+)', lines[j])
                    if m:
                        return int(m.group(1))
            break
        i += 1
    return -1


def patch_hash(dylib_path, output_path):
    print(f"📖 Reading: {dylib_path}")

    if not os.path.exists(dylib_path):
        print(f"❌ File not found: {dylib_path}")
        return False

    with open(dylib_path, 'rb') as f:
        data = bytearray(f.read())

    # Offset của __reserved (nơi ghi hash vào) — nằm trong __DATA
    reserve_offset = get_section_offset(dylib_path, '__DATA', '__reserved')
    if reserve_offset == -1:
        print("❌ Cannot find __reserved section")
        return False
    print(f"✅ __reserved at offset: {reserve_offset} (0x{reserve_offset:X})")

    # fileoff + filesize của segment __TEXT (điểm kết thúc vùng hash)
    text_fileoff, text_filesize = get_segment_info(dylib_path, '__TEXT')
    if text_fileoff == -1 or text_filesize == -1:
        print("❌ Cannot find __TEXT segment")
        return False
    print(f"✅ __TEXT segment: fileoff={text_fileoff} (0x{text_fileoff:X}), "
          f"filesize={text_filesize} (0x{text_filesize:X})")

    # Offset thật của section __text (điểm BẮT ĐẦU vùng hash —
    # bỏ qua header + load commands, vùng hay bị codesign/esign chèn thêm)
    text_section_offset = get_section_offset(dylib_path, '__TEXT', '__text')
    if text_section_offset == -1:
        print("❌ Cannot find __text section")
        return False
    print(f"✅ __text section offset: {text_section_offset} (0x{text_section_offset:X})")

    hash_start = text_section_offset
    hash_end = text_fileoff + text_filesize

    if hash_end <= hash_start:
        print(f"❌ Invalid hash range: 0x{hash_start:X} -> 0x{hash_end:X}")
        return False

    print(f"✅ Hash range: 0x{hash_start:X} -> 0x{hash_end:X} ({hash_end - hash_start} bytes)")

    # HASH TỪ __text ĐẾN HẾT SEGMENT __TEXT (gồm __text, __cstring, __const...)
    print("📊 Calculating SHA-256...")
    hash_obj = hashlib.sha256()
    hash_obj.update(data[hash_start:hash_end])
    hash_value = hash_obj.hexdigest()
    print(f"✅ SHA-256: {hash_value}")

    # Ghi hash vào reserve
    hash_bytes = bytes.fromhex(hash_value)
    data[reserve_offset:reserve_offset + 32] = hash_bytes

    # Backup
    backup_path = dylib_path + '.backup'
    if not os.path.exists(backup_path):
        shutil.copy2(dylib_path, backup_path)
        print(f"📁 Backup: {backup_path}")

    # Ghi file
    with open(output_path, 'wb') as f:
        f.write(data)

    print(f"✅ Patched: {output_path}")
    print(f"📊 Hash written to reserve: {hash_value[:32]}...")
    return True


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 patch_hash.py <input.dylib> <output.dylib>")
        sys.exit(1)

    if patch_hash(sys.argv[1], sys.argv[2]):
        print("\n✅ SUCCESS!")
        sys.exit(0)
    else:
        print("\n❌ FAILED!")
        sys.exit(1)
