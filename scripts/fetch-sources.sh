#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE="$ROOT/sources/tricore-toolchain-source.tar.gz"
if [[ ! -f "$ARCHIVE" ]]; then
    echo "Missing source asset: $ARCHIVE" >&2
    echo "Download the matching release source archives; see sources/README.md." >&2
    exit 1
fi
python3 - "$ROOT" <<'PY'
from pathlib import Path
import hashlib
import sys
root = Path(sys.argv[1])
name = 'tricore-toolchain-source.tar.gz'
entries = dict(line.split(None, 1)[::-1] for line in
               (root/'sources/SHA256SUMS.txt').read_text().splitlines() if line.strip())
path = root/'sources'/name
digest = hashlib.sha256()
with path.open('rb') as stream:
    for block in iter(lambda: stream.read(1024*1024), b''):
        digest.update(block)
if entries.get(name) != digest.hexdigest():
    raise SystemExit('Toolchain source SHA-256 verification failed')
PY
if [[ -d "$ROOT/.toolchain-src/tricore-gcc-toolchain" ]]; then
    echo 'Source directory already exists; leaving it unchanged.'
else
    mkdir -p "$ROOT/.toolchain-src"
    tar -xzf "$ARCHIVE" -C "$ROOT/.toolchain-src"
fi
bash "$ROOT/scripts/apply-toolchain-patches.sh"
