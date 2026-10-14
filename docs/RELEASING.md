# Preparing a public release

1. Commit repository-owned documentation, scripts/configuration, patches, exact
   version lock, third-party notices, license texts, source checksum list and recipes.
   Large toolchain/source archives are excluded by `.gitignore`.
2. Retain a matching source set for every binary release. Upload all five `sources/`
   archives, `sources/SHA256SUMS.txt`, and a source-materials package containing this
   repository's build scripts, packaging script, GCC patches, license texts and recipes.
3. Package `tools/tricore/` as a binary archive with its license directory, notices,
   README, environment helper, manifest and verification script. Do not include
   recovery backups, `.git`, `.DS_Store`, raw build directories or board project files.
4. Include `sources.lock.json`, archive SHA-256 checksums and current validation
   results. Regenerate hashes/validation if any binary is changed.
5. State Apple Silicon and minimum macOS 27.0, GCC version, tested tc26xx ABI,
   installed C++ ABIs, and that physical second-Mac/board testing was not performed.
6. Attach binary and corresponding source materials to the same GitHub Release,
   with clear README download instructions. The automatically generated GitHub
   repository source ZIP does not include the ignored third-party source assets.

GitHub documentation: https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
GNU corresponding source FAQ: https://www.gnu.org/licenses/gpl-faq.en.html#DistributeExtendedBinary

This local preparation does not create a GitHub repository, upload assets or publish a release.
