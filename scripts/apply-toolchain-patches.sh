#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GCC_SRC="$ROOT/.toolchain-src/tricore-gcc-toolchain/tricore-gcc"
for PATCH_FILE in "$ROOT"/patches/*.patch; do
    if patch --dry-run --silent -R -p1 -d "$GCC_SRC" -i "$PATCH_FILE" >/dev/null 2>&1; then
        echo "Patch already applied: $(basename "$PATCH_FILE")"
    else
        patch --dry-run --silent -p1 -d "$GCC_SRC" -i "$PATCH_FILE"
        patch -p1 -d "$GCC_SRC" -i "$PATCH_FILE"
    fi
done
