# TriCore GCC for macOS Apple Silicon

Native arm64 TriCore GCC builds for macOS, with bundled host libraries,
source patches and relocation checks.

本项目基于 [NoMore201/tricore-gcc-toolchain](https://github.com/NoMore201/tricore-gcc-toolchain)，
提供 macOS Apple Silicon 原生预编译工具链、构建补丁、宿主动态库打包和验证脚本。
这是社区构建与便携发行项目，不代表 Infineon 官方发行版。

## 当前版本和支持范围

| 项目 | 当前发行内容 |
| --- | --- |
| 编译器 | TriCore GCC / G++ 13.4.1，目标 `tricore-elf` |
| 宿主机 | Apple Silicon / arm64 |
| 系统要求 | 二进制加载命令标记最低 macOS 27.0；实际验证 macOS 27.0.1 |
| 已验证目标 | `-mcpu=tc26xx`，使用 TC1.6.1 目标运行库 |
| C++ 运行库 | 本次构建安装默认 ABI 和 `tc161`；其他 ABI 的 C++ 库不承诺可用 |
| 目标库 | Newlib、libgcc、libstdc++，具体文件保存在 `tools/tricore/` |
| 宿主依赖 | GMP 6.3.0、MPFR 4.2.2、MPC 1.4.1、ISL 0.28，均随包提供 |
| 未包含 | GDB、QEMU、iLLD、烧录器和具体板卡应用工程 |

直接使用预编译工具链不需要 Homebrew。CMake、Ninja 等工程构建系统按项目需要单独提供。
更早版本 macOS 需要重新构建并验证；本发行包没有修改二进制的最低系统要求。

## 快速使用

下载并解压便携二进制包，保留 `tricore/` 的完整目录结构和执行权限：

```bash
source "/你的路径/tricore/env.sh"
tricore-elf-gcc --version
tricore-elf-gcc -mcpu=tc26xx -O2 -c main.c -o main.o
```

如果使用当前工作目录中的工具链：

```bash
source ./tools/tricore/env.sh
tricore-elf-gcc --version
```

`env.sh` 支持 bash 和 zsh。也可以直接用绝对路径调用编译器。
只复制 `bin/` 会缺少内部编译程序、头文件和运行库；请完整复制 `tools/tricore/`。
不需要配置 `DYLD_LIBRARY_PATH`、`GCC_EXEC_PREFIX` 或 `LIBRARY_PATH`。

## 在 CMake 工程中使用

配套 `cmake/tricore-toolchain.cmake` 默认从本项目的 `tools/tricore/` 查找工具链，
也允许显式指定安装位置和 CPU：

```bash
cmake -S /你的工程 -B /你的构建目录   -DCMAKE_TOOLCHAIN_FILE=/本项目/cmake/tricore-toolchain.cmake   -DTRICORE_TOOLCHAIN_ROOT=/你的路径/tricore   -DTRICORE_CPU=tc26xx
cmake --build /你的构建目录
```

最终固件仍需工程自己的启动代码、芯片配置、内存布局/链接脚本和应用源码。
更换工具链安装路径时请使用新的 CMake 构建目录，避免复用旧编译器缓存。

## 便携处理和验证

GMP、MPFR、MPC、ISL 放在 `tools/tricore/lib/host/`。
`cc1`、`cc1plus`、`lto1`、`tricore-elf-lto-dump` 及四个动态库之间的依赖
已改为 `@loader_path` 相对路径；修改后的 Mach-O 文件使用 ad-hoc 签名。
除 macOS 系统库外，运行依赖从工具链内部加载。

在 Python 3 和 macOS `otool`、`codesign` 可用时执行：

```bash
python3 scripts/verify-portable.py tools/tricore
```

已经验证 C 编译/链接、C++17 编译及最小链接、LTO、静态归档、HEX/BIN 导出，
生成 ELF 的架构为 TC1.6.1 且没有未解析符号。
副本曾移动到包含空格和中文的目录，在禁止读取 Homebrew、原工具链卷和原工程目录、
清空编译器相关环境变量后完成测试。见 `docs/VALIDATION.json`。
路径在公开记录中已归一化，实际二进制哈希位于 `PORTABLE-MANIFEST.json`。
GCC `-v` 中的原构建路径是历史配置记录；当前工具和目标库按实际安装位置查找。

本次没有在另一台物理 Mac 或 TC264 板卡上验证。验证脚本生成的 ELF 不是板卡固件。

## 从源码构建

参见 [docs/BUILDING.md](docs/BUILDING.md)。
`sources.lock.json` 固定了三套工具链源码提交及四个宿主库的版本、URL、校验值。
`sources/tricore-toolchain-source.tar.gz` 保存了本次实际使用的工具链源码，已含两个 GCC 补丁。
`sources/` 中另附四个宿主库的原始源码包及安装时的 Homebrew 配方。

## 许可证和源码提供

本项目自行编写的独立脚本、配置和文档使用 [MIT](LICENSE)。
该许可证不替换 GCC、binutils、运行库、补丁或任何第三方组件的许可证。
GCC 源码补丁沿用被修改文件的原许可；libstdc++ 补丁涉及的运行库例外一并保留。
各组件版权和许可保存在 `licenses/`，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
便携二进制包内也包含这些许可文本。

公开提供 GPL/LGPL 二进制时，请同时提供对应源码及构建/打包材料。
本项目提供的 `sources/`、`patches/`、脚本和配方用于对应当前发行内容；
不要仅将仓库的自动源码 ZIP 作为第三方组件源码的替代品。
来源和下载说明见 [sources/README.md](sources/README.md)。
官方规则：[GNU GPL FAQ](https://www.gnu.org/licenses/gpl-faq.en.html#DistributeExtendedBinary)、
[LGPLv3](https://www.gnu.org/licenses/lgpl-3.0.html)、
[GCC Runtime Library Exception](https://www.gnu.org/licenses/gcc-exception-3.1.html)。

## GitHub 发布

Git 仓库保存 README、许可、固定版本清单、补丁、脚本和配置。
二进制和第三方源码压缩包作为同一 Release 的附件发布。
`tools/tricore/`、`sources/*.tar.*`、生成的源码/构建目录已在 `.gitignore` 中排除。
发布步骤和附件清单见 [docs/RELEASING.md](docs/RELEASING.md)。
