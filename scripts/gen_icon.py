#!/usr/bin/env python3
"""Generate a minimal app icon PNG for NoiseCancelToggle."""
import struct, zlib, os, sys

output_path = sys.argv[1] if len(sys.argv) > 1 else "icon.png"
width, height = 120, 120

# Solid blue (52, 152, 219)
raw = b""
for y in range(height):
    raw += b"\x00"  # filter byte (none)
    for x in range(width):
        raw += b"\x34\x98\xDB\xFF"  # RGBA

def chunk(chunk_type, data):
    c = chunk_type + data
    return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(raw))
png += chunk(b"IEND", b"")

os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
with open(output_path, "wb") as f:
    f.write(png)
print(f"Icon written: {output_path}")