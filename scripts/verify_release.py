#!/usr/bin/env python3
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parent.parent
for line in (root/'RELEASE_SHA256SUMS').read_text().splitlines():
    expected,name=line.split('  ',1)
    p=root/name
    if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=expected:
        raise SystemExit('RELEASE_HASH_MISMATCH: '+name)
print('PUBLICATION_FILE_HASHES=PASS')
