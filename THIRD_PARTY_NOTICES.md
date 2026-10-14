# Third-party notices

This is a mixed-license toolchain distribution. The repository MIT license
applies only to independently authored scripts/configuration/documentation.
Copyright notices and file-level license grants in upstream source remain intact.
The list below summarizes major components; it does not replace their license texts.

| Component | Source / version | License summary | Texts |
| --- | --- | --- | --- |
| TriCore GCC | NoMore201/tricore-gcc, `59834f272d9c0d051329195c867341238b0c6a86`, version 13.4.1 | GCC compiler primarily GPL-3.0-or-later; file-level grants apply | `licenses/tricore-gcc/` |
| libgcc / libstdc++ | Same GCC tree | GPL-3.0-or-later with GCC Runtime Library Exception 3.1 for files carrying the exception | `COPYING3`, `COPYING.RUNTIME`, and source-file headers |
| TriCore binutils | NoMore201/tricore-binutils-gdb, `78ccc076bc8cad0f9e08c81ca1c89b5e89dfb8f3` | Distributed tools primarily GPL-3.0-or-later; auxiliary components retain their own grants | `licenses/tricore-binutils-gdb/` |
| Newlib / libgloss | EEESlab/tricore-newlib-cygwin, `240a8f676ea923c703824e996fbe88ac4a302e17` | Multiple BSD/permissive and other file-specific grants; do not classify the whole libc as GPL | `licenses/tricore-newlib-cygwin/COPYING.NEWLIB`, `COPYING.LIBGLOSS`, source headers |
| GMP | 6.3.0 | LGPL-3.0-or-later OR GPL-2.0-or-later for the library; other programs have their own grants | `licenses/gmp/` |
| MPFR | 4.2.2 | LGPL-3.0-or-later | `licenses/mpfr/` |
| MPC | 1.4.1 | LGPL-3.0-or-later | `licenses/libmpc/` |
| ISL | 0.28 | MIT | `licenses/isl/` |
| Bundled manuals | GCC/binutils manual notices retained | GNU Free Documentation License where specified by each manual | `licenses/documentation/` and embedded manual notices |
| Homebrew recipes | Exact installed `.brew/*.rb` recipes | Homebrew BSD 2-clause license; upstream library licenses remain applicable | `licenses/homebrew-LICENSE.txt` |

## Upstream attribution

- Toolchain integration: https://github.com/NoMore201/tricore-gcc-toolchain
- Earlier upstream: https://github.com/EEESlab/tricore-gcc-toolchain-11.3.0
- GCC: https://github.com/NoMore201/tricore-gcc
- Binutils: https://github.com/NoMore201/tricore-binutils-gdb
- Newlib: https://github.com/EEESlab/tricore-newlib-cygwin
- GMP: https://gmplib.org/
- MPFR: https://www.mpfr.org/
- MPC: https://www.multiprecision.org/mpc/
- ISL: https://libisl.sourceforge.io/
- Homebrew: https://github.com/Homebrew/brew and https://github.com/Homebrew/homebrew-core

The upstream toolchain integration repository is recorded for attribution and
revision provenance. Its unlicensed top-level wrapper/docs are not republished
as project-owned MIT code. The source archive contains the three component trees.

## Local changes

- `patches/gcc-tricore-data-sections.patch`: adjust the TriCore unique data
  section lookup. Licensed under the original GCC file's GPL terms.
- `patches/libstdcxx-tricore-format.patch`: avoid a 60-bit bit-field unsupported
  by the TriCore EABI. Retains the original libstdc++ file's license and exception.
- Host library code is unchanged; Mach-O install names were changed to relative
  paths and modified images were ad-hoc signed. The packaging script is included.
- GCC build options and the default/tc161 C++ multilib installation procedure
  are recorded in `scripts/build-toolchain.sh`.
- GDB, QEMU and Infineon iLLD are not shipped by this distribution. Source trees
  may contain upstream code for additional targets/tools; only the documented
  binaries were built. Such source files retain their own original grants.

## Corresponding source and rebuilding

The `sources/` archives, exact version lock, GCC patches, build scripts,
Homebrew recipes and portable packaging script accompany the current binaries.
Preserve these files and make them available alongside binary downloads.
Full upstream source-file notices are preserved in the source archives.
The GNU license copies in `licenses/` are verbatim originals, not paraphrases.

GMP's dual-license options are retained. MPFR/MPC/GMP license directories include
GPLv3 and the corresponding LGPLv3 supplement. Do not remove the original grants.
The dynamically linked libraries remain separate files and can be replaced by
interface-compatible rebuilt versions; re-sign changed Mach-O files on arm64.

Providing a GCC toolchain does not by itself require all user application code
to use GPL. Runtime exception conditions and any separately linked component
licenses still apply to the resulting applications.
