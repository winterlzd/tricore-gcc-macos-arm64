#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/.toolchain-src/tricore-gcc-toolchain"
PREFIX="$ROOT/tools/tricore"
BUILD="$ROOT/.toolchain-build"
JOBS="${JOBS:-4}"
BREW_PREFIX="$(brew --prefix)"
export PATH="$PREFIX/bin:$BREW_PREFIX/opt/make/libexec/gnubin:$PATH"
HOST_GCC_MAJOR="$(brew list --versions gcc | awk '{split($2, version, "."); print version[1]}')"
export CC="${HOST_CC:-$BREW_PREFIX/bin/gcc-$HOST_GCC_MAJOR}"
export CXX="${HOST_CXX:-$BREW_PREFIX/bin/g++-$HOST_GCC_MAJOR}"
# Older configure tests and libcody require these exact host language dialects.
export CFLAGS="-O2 -std=gnu11"
export CXXFLAGS="-O2 -std=gnu++11"
MAKE="$BREW_PREFIX/bin/gmake"
mkdir -p "$BUILD" "$PREFIX"
bash "$ROOT/scripts/apply-toolchain-patches.sh"
common=(--target=tricore-elf --prefix="$PREFIX" --disable-nls
        --disable-werror --with-gmp="$BREW_PREFIX/opt/gmp"
        --with-mpfr="$BREW_PREFIX/opt/mpfr" --with-mpc="$BREW_PREFIX/opt/libmpc"
        --with-isl="$BREW_PREFIX/opt/isl")
if [[ ! -f "$BUILD/binutils.done" ]]; then
    echo "Building native arm64 binutils"
    mkdir -p "$BUILD/binutils"
    cd "$BUILD/binutils"
    "$SRC/tricore-binutils-gdb/configure" "${common[@]}" --disable-gdb \
        --disable-sim --disable-gprofng --disable-shared --enable-static
    "$MAKE" -j"$JOBS" MAKEINFO=true all-binutils all-gas all-ld
    "$MAKE" MAKEINFO=true install-binutils install-gas install-ld
    touch "$BUILD/binutils.done"
fi
gcc_options=("${common[@]}" --enable-languages=c,c++ --disable-bootstrap
             --with-newlib --disable-shared --disable-threads --disable-libssp
             --disable-libsanitizer --disable-libquadmath --disable-libgomp
             --disable-libvtv --with-pkgversion=macOS-TriCore-local)
if [[ ! -f "$BUILD/gcc-stage1.done" ]]; then
    echo "Building native arm64 GCC stage 1"
    mkdir -p "$BUILD/gcc-stage1"
    cd "$BUILD/gcc-stage1"
    "$SRC/tricore-gcc/configure" "${gcc_options[@]}" --without-headers
    "$MAKE" -j"$JOBS" all-gcc
    "$MAKE" install-gcc
    touch "$BUILD/gcc-stage1.done"
fi
if [[ ! -f "$BUILD/newlib.done" ]]; then
    echo "Building TriCore newlib"
    mkdir -p "$BUILD/newlib"
    cd "$BUILD/newlib"
    CC_FOR_TARGET="$PREFIX/bin/tricore-elf-gcc" \
    CFLAGS_FOR_TARGET="-O2 -g -gdwarf-3 -ffunction-sections -fdata-sections" \
    "$SRC/tricore-newlib-cygwin/configure" --target=tricore-elf --prefix="$PREFIX" \
        --disable-newlib-supplied-syscalls --enable-newlib-io-long-long
    "$MAKE" -j"$JOBS" MAKEINFO=true
    "$MAKE" MAKEINFO=true install
    touch "$BUILD/newlib.done"
fi
if [[ ! -f "$BUILD/gcc-stage2.done" ]]; then
    echo "Building native arm64 GCC and target runtime libraries"
    mkdir -p "$BUILD/gcc-stage2"
    cd "$BUILD/gcc-stage2"
    CFLAGS_FOR_TARGET="-O2 -g -gdwarf-3 -ffunction-sections -fdata-sections" \
    CXXFLAGS_FOR_TARGET="-O2 -g -gdwarf-3 -ffunction-sections -fdata-sections" \
    "$SRC/tricore-gcc/configure" "${gcc_options[@]}"
    "$MAKE" -j"$JOBS" all-gcc all-target-libgcc
    "$MAKE" configure-target-libstdc++-v3
    # Install C++ runtimes for the default ABI and TC264's TriCore 1.6.1 ABI.
    # This old multilib helper clears MAKEOVERRIDES in recursive make calls.
    # Disable automatic traversal in its generated default Makefile instead.
    awk '/^MULTIDIRS =/ {print "MULTIDIRS ="; next} {print}' \
        tricore-elf/libstdc++-v3/Makefile > tricore-elf/libstdc++-v3/Makefile.tc264.tmp
    mv tricore-elf/libstdc++-v3/Makefile.tc264.tmp tricore-elf/libstdc++-v3/Makefile
    "$MAKE" -C tricore-elf/libstdc++-v3 -j"$JOBS" MULTIDIRS= all
    "$MAKE" -C tricore-elf/tc161/libstdc++-v3 -j"$JOBS" MULTIDIRS= all
    "$MAKE" install-gcc install-target-libgcc
    "$MAKE" -C tricore-elf/libstdc++-v3 MULTIDIRS= install
    "$MAKE" -C tricore-elf/tc161/libstdc++-v3 MULTIDIRS= install
    touch "$BUILD/gcc-stage2.done"
fi
"$PREFIX/bin/tricore-elf-gcc" --version
