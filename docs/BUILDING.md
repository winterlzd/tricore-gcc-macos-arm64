# Building and portable packaging

## Current build provenance

The installed compiler was built from the component commits in `sources.lock.json`
with the two GCC patches in `patches/`. `sources/tricore-toolchain-source.tar.gz`
contains the actual component trees with those patches already applied.
The host libraries were obtained from Homebrew bottles: GMP 6.3.0, MPFR 4.2.2,
MPC 1.4.1 and ISL 0.28. Their source tarballs and exact installed recipes are included.
The packaged host-library machine code was not rebuilt during documentation cleanup.

## Toolchain build

Building requires Apple Silicon, Xcode Command Line Tools, Python 3, Homebrew,
and the following build dependencies. Running the prebuilt toolchain requires no Homebrew.

```bash
brew install gcc make gmp mpfr libmpc isl
bash scripts/fetch-sources.sh
bash scripts/build-toolchain.sh
```

`fetch-sources.sh` verifies and unpacks the supplied toolchain source archive into
`.toolchain-src/`. Download the source assets listed in `sources/README.md` first
when starting from a Git-only checkout. It does not fetch iLLD or a board project.
`apply-toolchain-patches.sh` is idempotent for the already-patched source archive.

Build stages are binutils, GCC stage 1, Newlib, GCC stage 2/libgcc, then C++ libraries
for the default ABI and tc161. GDB, simulator and QEMU are not built.
The build uses Homebrew GNU Make and host GCC, `gnu11` for host C, `gnu++11` for host C++.
The generated C++ Makefile's automatic multilib traversal is disabled and the
default/tc161 libraries are installed explicitly; this change is in the build script.

Optional environment overrides:

```bash
JOBS=4 HOST_CC=/path/to/gcc HOST_CXX=/path/to/g++   bash scripts/build-toolchain.sh
```

Build markers are kept in `.toolchain-build/`. Use a fresh build directory when
changing source, compiler versions, deployment target or configure options.
The existing build script is included as provenance; a complete new toolchain build
was not performed during this documentation/cleanup pass.

## Host library source

Verify `sources/SHA256SUMS.txt`, then unpack the four library tarballs into a
separate build directory. The copied Homebrew recipes specify source URLs, hashes,
configure flags and any regeneration steps used by their package definitions.
For example, the GMP recipe regenerates configure with autoreconf and enables
`--enable-cxx --with-pic`; MPC uses explicit GMP/MPFR prefixes; ISL uses system GMP.
Homebrew bottle build infrastructure may add compiler/deployment flags; exact
byte-for-byte reconstruction of those bottles is not asserted here.

Use an isolated prefix for rebuilt libraries, then ensure the new compiler loads
those versions before packaging. Replacing library binaries changes manifest hashes;
regenerate and verify the package rather than reusing the old validation record.

## Make the toolchain portable

For a fresh toolchain built into `tools/tricore/`:

```bash
python3 scripts/make-portable.py tools/tricore dist/tricore
python3 scripts/verify-portable.py dist/tricore --report dist/validation.json
```

The packaging script copies its input, recursively gathers non-system dylibs,
changes references to `@loader_path`, ad-hoc signs changed Mach-O images,
checks dependency closure, and records SHA-256 hashes and source paths.
It does not modify the input toolchain or installed Homebrew libraries.
For this project's license-complete release, also include `licenses/`, notices,
build scripts, patches and the matching source download assets as described in RELEASING.md.

## Minimum macOS version

The current binaries carry `minos 27.0` and were tested on macOS 27.0.1.
Supporting an earlier OS requires a suitable SDK/deployment target for both
the toolchain host programs and all bundled libraries, followed by tests on that OS.
Changing a load-command version alone is not a compatibility validation.
