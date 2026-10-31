#!/usr/bin/env python3
"""bin -> $readmemh word file (little-endian 32-bit words, one per line)."""
import sys, struct
data = open(sys.argv[1], 'rb').read()
data += b'\0' * (-len(data) % 4)
with open(sys.argv[2], 'w') as f:
    for (w,) in struct.iter_unpack('<I', data):
        f.write(f'{w:08x}\n')
