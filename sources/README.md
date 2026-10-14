# Corresponding source assets

This directory contains the source materials for the current portable binaries:

| File | Contents |
| --- | --- |
| `tricore-toolchain-source.tar.gz` | Actual GCC, binutils and Newlib component trees, including applied GCC patches; Git administration data and caches excluded |
| `gmp-6.3.0.tar.xz` | GMP upstream source |
| `mpfr-4.2.2.tar.xz` | MPFR upstream source |
| `mpc-1.4.1.tar.xz` | MPC upstream source |
| `isl-0.28.tar.xz` | ISL upstream source |
| `homebrew-formulas/` | Exact formula files captured from the installed Homebrew bottles |
| `SHA256SUMS.txt` | SHA-256 checksums for the five source archives |

Git checkouts omit large archives. Obtain all five source assets from the same
release as the binary package and put them in this directory. The files are present
in the locally prepared distribution. Source URLs and pinned revisions are in
`../sources.lock.json`; local GCC modifications are in `../patches/`.

Verify downloads:

```bash
cd sources
shasum -a 256 -c SHA256SUMS.txt
```

Binary recipients need access to these source materials, the license texts,
build/packaging scripts and patches. Keep them available for every release in which
the corresponding binaries are available. A checksum manifest or upstream homepage
alone does not supply the modified toolchain source.
