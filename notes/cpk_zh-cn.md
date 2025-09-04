# CPK：一场回归软件本真的打包分发哲学实践

> **在Linux复杂的分发生态中，我们是否已经忘记了软件的纯粹形态？当容器、沙箱和守护进程成为标配，CPK以其极简、透明和自由的哲学，发起了另一场值得深思的技术实践。**

## 引言：迷失在“进步”中的软件本真

Linux世界从不缺少创新，尤其是在应用分发领域。我们从`deb`/`rpm`走向了Snap、Flatpak和AppImage，每一次进化都试图解决依赖、隔离和跨平台兼容性问题。然而，在这些解决方案不断叠加抽象层的同时，我们也悄然失去了什么：**系统的简洁性、对软件行为的完全可知性、以及无需中间人介入的直接控制权。**

我们似乎在用一种复杂性去替代另一种复杂性。有没有一种方式，能够让我们回归到软件最本真的状态——**一份完整、自包含、可在任何地方直接运行的数字产物**？

开源构建系统CBuild-ng给出的答案是：**CPK (CBuild/Compressed Package)**。它不仅是一种技术格式，更是一场关乎**极简（Simplicity）、主权（Sovereignty）与自由（Mobility）** 的哲学实践。

## 一、极简（Simplicity）——剥离一切非必要复杂性

CPK的设计哲学根植于Unix的经典信条：KISS (Keep It Simple, Stupid)。它坚信，真正的通用性应建立在系统最坚实、最普遍的基础上，而非另一套复杂的中间件之上。

**CPK是什么？**

* 它是一个**自解压的Shell脚本**，后面紧跟着一个标准的**tar归档包**。
* **它的全部依赖，仅仅是 Python、sh、file、tar、gcc、readelf、patchelf**。这几个工具存在于任何一台Linux机器上（patchelf需要单独静态编译），无需安装任何额外的框架或守护进程（如snapd或flatpak）。

这种极简到极致的设计，带来了无与伦比的**透明性**。用户可以用文本编辑器直接查看CPK包的安装逻辑，用`tar`命令解压并审计其内容。没有黑盒子，没有隐藏的魔法，一切行为都是可知、可预测、可审计的。CPK用最原始的工具，解决了最现代的问题，完成了一次对过度工程化的优雅否定。

## 二、主权（Sovereignty）——将控制权彻底归还

CPK蕴含着一种强烈的主张：它要求将软件的**完整主权**归还给创造者和使用者。

* **对开发者而言，CPK赋予了「交付确定性」的能力。**
    * 开发者可以自由选用任何现代工具链（如AlmaLinux 10的最新glibc），将应用与其**全部依赖**（直至最底层的C库）一同封存，形成一个冻结的、已知良好的运行环境。从此，他可以庄严地向用户宣告：“这就是我的作品及其全部所需，它在此环境中完美运行。” 这彻底终结了“依赖地狱”和“在我机器上是好的”这一古老困境。

* **对用户而言，CPK意味着「完全的控制权和透明度」。**
    * 一个`.cpk`文件无需root权限即可安装于用户目录（`~/.cpk/`），不会向系统深处散落文件。用户可以审视安装脚本，可以自由剖析包内内容，可以决定何时运行与更新。没有强制的后台服务，没有不经同意的自动升级。CPK在开发者与用户之间，建立了一种基于透明和尊重的信任关系。

## 三、自由（Mobility）——构建可自由迁徙的数字生命体

CPK的终极理想，是让Linux应用成为一个**真正可自由迁徙的数字生命体**，获得跨越发行版鸿沟的能力。

其核心技术在于：**它不仅携带用户态依赖，更自带最底层的C库（如glibc）和解释器（ld.so）**，并通过修改二进制文件的解释器路径（Interpreter），使其形成一个完美的内部闭环。这使得一个在最新发行版上构建的应用，可以在任何旧版主机上**完整“复活”**。

它实现了应用与环境的标准脱钩，赋予了应用跨越发行版自由迁徙的能力，这正是Linux世界长期以来所追寻的“一次构建，到处运行”的优雅实现。CPK让应用摆脱了系统的束缚，成为了一个真正独立、可迁移的数字实体。

## 四、横向审视——CPK在生态中的独特定位

CPK 的设计哲学与主流方案有显著区别，它并非要取代所有现有方案，而是在 **“极致简化”、“可控性”** 和 **“跨发行版部署”** 之间找到了一个独特的平衡点。

以下是从多个维度的详细对比：

| 特性维度 | **CPK (CBuild-ng)** | **Snap** | **Flatpak** | **AppImage** | **传统包 (deb/rpm)** |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. 核心设计哲学** | **应用本身即包**。创建一个**自包含的、可移植的**应用环境，通过修改二进制路径实现隔离。 | **沙盒化的应用容器**。强调**安全隔离**和自动更新，由商店分发。 | **桌面应用沙盒**。专注于为**Linux桌面**提供沙盒化和可移植的应用。 | **单一文件即应用**。追求极致的简单性，“下载、设权、运行”。 | **系统集成**。软件作为**操作系统的一部分**，深度集成到系统中。 |
| **2. 打包格式** | **自解压Shell脚本 + tar归档**。极其简单透明，可直接查看内容。 | **只读SquashFS镜像**。是一个压缩的镜像文件，需要挂载。 | **OCI镜像 + 元数据**。结构相对复杂。 | **ISO 9660 文件系统镜像**。可挂载查看。 | **自定义归档格式**（deb为ar归档，内含debian-binary、control.tar、data.tar）。 |
| **3. 依赖管理** | **强隔离，自带依赖**。包内包含所有必要库（如glibc、ld.so），通过 `patchelf` **修改二进制**的 interpreter 和 rpath。 | **强隔离，自带依赖**。使用严格定义的基础运行时和接口。 | **强隔离，共享运行时**。应用共享通用的运行时（如Freedesktop SDK）。 | **可选隔离**。可自带依赖，也可依赖系统库（取决于打包者）。 | **无隔离，共享系统库**。完全依赖系统仓库提供的共享库。 |
| **4. 跨发行版支持** | **✅ 完美支持**。核心机制决定了其天然跨发行版。 | **✅ 完美支持**。 | **✅ 完美支持**。 | **✅ 完美支持**。 | **❌ 不支持**。严重依赖特定发行版的库版本。 |
| **5. 安装方式** | **无需安装**或**用户空间安装**。可直接运行 `.cpk` 文件，或“安装”到用户目录（`~/.cpk/`），**无需root权限**。 | **需系统安装**。需要安装 `snapd` 守护进程，安装应用需要root权限。 | **用户或系统安装**。需要 `flatpak` 框架，推荐用户级安装（无需root）。 | **无需安装**。直接下载文件，赋予执行权限即可运行。 | **需系统安装**。必须通过包管理器（apt/dnf）以root权限安装。 |
| **6. 性能开销** | **极低（近乎原生）**。无额外抽象层，直接执行包内二进制。 | **较高**。有mount命名空间、AppArmor约束、SquashFS解压等开销。 | **中等**。有bubblewrap沙箱和OCI运行时开销。 | **低**。启动时需解压到tmpfs，但运行后是原生代码。 | **原生**。 |
| **7. 安全性** | **依赖主机安全**。无内置沙箱，应用权限与启动它的用户相同。 | **高**。默认启用严格沙箱（AppArmor、seccomp），权限按需申请。 | **高**。使用bubblewrap沙箱，权限细粒度控制。 | **依赖主机安全**。无沙箱，权限与用户相同。 | **依赖系统安全**。软件拥有安装时所授权限。 |
| **8. 更新机制** | 由开发者分发新版本CPK。 | **自动**。由 `snapd` 守护进程自动从Snap商店后台更新。 | **自动/手动**。通过 `flatpak` 命令从远程仓库更新。 | **手动**。需要用户重新下载新的AppImage文件。 | **系统级**。通过系统包管理器（apt/dnf）统一更新。 |
| **9. 桌面集成** | **需手动处理**。需要额外脚本或工具创建桌面文件、图标等。 | **优秀**。自动生成桌面文件并集成。 | **优秀**。自动生成桌面文件并集成。 | **良好**。可捆绑桌面文件，但可能需要外部工具集成。 | **优秀**。深度集成到系统菜单中。 |
| **10. 核心依赖** | **极简**，使用系统常用工具 | **重**：必须安装并运行 `snapd` 守护进程。 | **中**：需要安装 `flatpak` 框架。 | **无**：无需安装任何特定框架。 | **无**：系统本身已具备。 |

**CPK 的独特定位：**

1. **面向开发者和专业用户**：CPK 的透明性（可查看脚本）、可控性（自己处理依赖）和极简依赖，使其特别适合**开发者分发复杂工具链、内部工具、CI/CD 构建产物**，以及专业用户部署特定版本的商业软件。
2. **嵌入式与边缘计算**：在资源受限或需要高度定制化的环境中，CPK 的**低开销**和**无需常驻守护进程**的特点是一个巨大优势。它允许将复杂的运行时环境可靠地分发到任何 Linux 设备上。
3. **追求简单和透明的哲学**：CPK 不相信“魔法”。它用最基础的组件构建了一套解决方案，所有步骤都是可审计、可调试的（无沙箱、无强制商店）。这与 Snap/Flatpak 引入的相对复杂的守护进程和框架形成鲜明对比。

## 五、实战——感受CPK的优雅体验

### 基于CBuild-ng集成的CPK打包示例

`make xxx-cpk` 命令即可自动编译软件并生成cpk包，`ELFs copied from system:` 清晰的显示了从系统复制的哪些包

```sh
lengjing@lengjing:~/data/cbuild-ng$ source scripts/build.env host generic
lengjing@lengjing:~/data/cbuild-ng$ make loadconfig
lengjing@lengjing:~/data/cbuild-ng$ make tcpdump-cpk
Match patchelf-native Cache.
Build patchelf-native Done.
Match patchelf Cache.
Build patchelf Done.
log path is /home/lengjing/data/cbuild-ng/output/x86_64-host/config/log/2025-09-04--08-15-58.068091488/
[100%]                                                  [  2/  2] tcpdump
----------------------------------------
    libpcap
    tcpdump
----------------------------------------
Generate /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/share/license/index.txt OK.
Generate /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/share/license/index.html OK.
Note: tcpdump.dot tcpdump.svg and tcpdump.png are generated in the /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/share/license folder.
Interpreter path       : /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/syslib/ld-linux-x86-64.so.2
ELFs with interpreter  : [('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/syslib', ['libc-2.31.so', 'libpthread-2.31.so'])]
ELFs with rpath        : [('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/lib', ['libpcap.so.1.10.5']), ('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/syslib', ['libcrypto.so.1.1', 'libc-2.31.so', 'libdl-2.31.so', 'libpthread-2.31.so'])]
ELFs copied from system: ['libcrypto.so.1.1', 'libc.so.6', 'ld-linux-x86-64.so.2']
CPK SUCCESS: /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump
CPK is packed to /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump.cpk
```

### CPK打包命令和原理

```makefile
%-cpk:
	@$(MAKE) $(MFLAG) CONFIG_PATCHELF_NATIVE=y patchelf-native
	@$(MAKE) $(MFLAG) CONFIG_PATCHELF=y patchelf
	@$(MAKE) $(MFLAG) $(patsubst %-cpk,%-pkg,$@)
	@PATH=$(ENV_NATIVE_ROOT)/objects/patchelf/image/usr/bin:$(PATH) \
		python3 $(ENV_TOOL_DIR)/gen_cpk_package.py -r $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@) \
		-i include:share:etc:srv:com:var:run $(if $(PKG_EOS),-o $(PKG_EOS)) \
		-c $(ENV_BUILD_TOOL)gcc -t $(ENV_BUILD_TOOL)readelf $(if $(CPK_EXTRA_PATH),-e $(CPK_EXTRA_PATH))
	@cp -fp $(ENV_CROSS_ROOT)/objects/patchelf/image/usr/bin/patchelf $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
ifneq ($(PKG_EOS),y)
	@cp -fp $(ENV_TOOL_DIR)/gen_cpk_package.py $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
	@ush=$(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)/update.sh && \
		echo '#!/bin/sh' > $${ush} && \
		echo 'curdir=$$(dirname $$(realpath $$0))' >> $${ush} && \
		echo 'PATH=$$curdir:$$PATH python3 $$curdir/gen_cpk_package.py -r $$curdir -i include:share:etc:srv:com:var:run' >> $${ush} && \
		chmod +x $${ush}
endif
	@bash $(ENV_TOOL_DIR)/gen_cpk_binary.sh pack $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
```

上述代码为顶层Makefile CPK打包的命令，主要使用 `gen_cpk_package.py` 和 `gen_cpk_binary.sh` 脚本完成处理，用户也可以独立使用这两个脚本，脱离CBuild-ng单独打包

* 静态编译`patchelf` ，**特别提醒，发行版本的patchelf可能有问题，请选用合适的patchelf**
* 运行`gen_cpk_package.py`脚本完成处理（`-h` 得到命令帮助）
    * 分析 `-r` 指定的打包目录下的动态链接的可执行程序和动态库
    * 使用 `file` 命令得到文件属性，再使用 `-t` 指定的readelf分析依赖的动态库
    * 使用 `-c` 指定的gcc从他的搜寻目录找到依赖的动态库（不在打包目录下）复制到syslib目录
    * 使用 `patchelf` 修改rpath和interpreter指向打包目录的文件
* 运行`gen_cpk_binary.sh`脚本将压缩打包目录并把压缩包追加到本脚本后面成为单文件


### 安装CPK包的示例

下面是AlmaLinux10下编译的CPK在ubuntu20.04下运行的例子，成功演示了：一个在AlmaLinux 10（基于较新的glibc 2.41）上编译的tcpdump及其所有复杂依赖，可以无缝地在Ubuntu 20.04（基于较旧的glibc 2.31）上运行。并且请看`usr/share/license` 目录，`index.html`/`index.txt` 提供了许可列表，图片可查看依赖关系，这是企业合规的特性。

```sh
lengjing@lengjing:~/Downloads$ ./tcpdump.cpk
Please set the installation directory (/home/lengjing/.cpk/tcpdump):
Delete the original app [/home/lengjing/.cpk/tcpdump] first? (y or n): y
-e Your choice is y
Interpreter path       : /home/lengjing/.cpk/tcpdump/syslib/ld-linux-x86-64.so.2
ELFs with interpreter  : [('/home/lengjing/.cpk/tcpdump/syslib', ['libc.so.6']), ('/home/lengjing/.cpk/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/.cpk/tcpdump/syslib', [])]
ELFs with rpath        : [('/home/lengjing/.cpk/tcpdump/syslib', ['libc.so.6', 'libz.so.1.3.1.zlib-ng', 'libcrypto.so.3.2.4']), ('/home/lengjing/.cpk/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/.cpk/tcpdump/usr/lib', ['libpcap.so.1.10.5']), ('/home/lengjing/.cpk/tcpdump/syslib', [])]
ELFs copied from system: []
CPK SUCCESS: /home/lengjing/.cpk/tcpdump
-e Successfully installed to /home/lengjing/.cpk/tcpdump
lengjing@lengjing:~/Downloads$ cd /home/lengjing/.cpk/tcpdump
lengjing@lengjing:~/.cpk/tcpdump$ tree
.
├── gen_cpk_package.py
├── patchelf
├── syslib
│     ├── ld-linux-x86-64.so.2
│     ├── libcrypto.so.3 -> libcrypto.so.3.2.4
│     ├── libcrypto.so.3.2.4
│     ├── libc.so.6
│     ├── libz.so.1 -> libz.so.1.3.1.zlib-ng
│     └── libz.so.1.3.1.zlib-ng
├── update.sh
└── usr
    ├── bin
    │     ├── pcap-config
    │     ├── tcpdump
    │     └── tcpdump.4.99.5 -> tcpdump
    ├── lib
    │     ├── libpcap.so -> libpcap.so.1
    │     ├── libpcap.so.1 -> libpcap.so.1.10.5
    │     └── libpcap.so.1.10.5
    └── share
        └── license
            ├── common
            │     └── MIT-LENGJING
            │         └── LICENSE
            ├── index.html
            ├── index.txt
            ├── libpcap
            │     └── LICENSE
            ├── spdx-licenses.html
            ├── tcpdump
            │     └── LICENSE
            ├── tcpdump.dot
            ├── tcpdump.png
            └── tcpdump.svg

10 directories, 24 files
lengjing@lengjing:~/.cpk/tcpdump$ file usr/bin/tcpdump
usr/bin/tcpdump: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /home/lengjing/.cpk/tcpdump/syslib/ld-linux-x86-64.so.2, BuildID[sha1]=ccfe1b6660bd62cd643fe2746464872074e651ee, for GNU/Linux 3.2.0, not stripped
lengjing@lengjing:~/.cpk/tcpdump$ ./syslib/libc.so.6
GNU C Library (GNU libc) stable release version 2.41.
Copyright (C) 2025 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
Compiled by GNU CC version 15.1.1 20250521 (Red Hat 15.1.1-2).
libc ABIs: UNIQUE IFUNC ABSOLUTE
Minimum supported kernel: 3.2.0
For bug reporting instructions, please see:
<https://www.gnu.org/software/libc/bugs.html>.
lengjing@lengjing:~/.cpk/tcpdump$ /usr/lib/x86_64-linux-gnu/libc.so.6
GNU C Library (Ubuntu GLIBC 2.31-0ubuntu9.18) stable release version 2.31.
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
Compiled by GNU CC version 9.4.0.
libc ABIs: UNIQUE IFUNC ABSOLUTE
For bug reporting instructions, please see:
<https://bugs.launchpad.net/ubuntu/+source/glibc/+bugs>.
lengjing@lengjing:~/.cpk/tcpdump$ ./usr/bin/tcpdump -h
tcpdump version 4.99.5
libpcap version 1.10.5 (with TPACKET_V3)
OpenSSL 3.2.4 11 Feb 2025
64-bit build, 64-bit time_t
Usage: tcpdump [-AbdDefhHIJKlLnNOpqStuUvxX#] [ -B size ] [ -c count ] [--count]
		[ -C file_size ] [ -E algo:secret ] [ -F file ] [ -G seconds ]
		[ -i interface ] [ --immediate-mode ] [ -j tstamptype ]
		[ -M secret ] [ --number ] [ --print ] [ -Q in|out|inout ]
		[ -r file ] [ -s snaplen ] [ -T type ] [ --version ]
		[ -V file ] [ -w file ] [ -W filecount ] [ -y datalinktype ]
		[ --time-stamp-precision precision ] [ --micro ] [ --nano ]
		[ -z postrotate-command ] [ -Z user ] [ expression ]
```

## 结语：一种选择，一种态度

在技术选择上，没有唯一的真理。Snap/Flatpak致力于构建一个安全可控的软件生态，其价值毋庸置疑。

而CPK，则是为另一群人准备的：他们是**极简主义的信徒，是掌控感的追求者，是希望软件保持纯粹形态的理想主义者**。CPK是他们表达技术态度的一种方式——选择简单而非复杂，选择透明而非遮蔽，选择自由而非约束。

CPK无意取代Snap、Flatpak或AppImage。它们服务于不同的愿景：Snap/Flatpak致力于构建一个安全、可控、便于管理的软件生态；AppImage追求极致的单一文件便携性。

**CPK，不仅仅是一种格式，更是一场回归软件本真的哲学实践。它用优雅的技术和最小的开销，精准地解决了特定场景下的痛点，体现了“简单即是美”的工程哲学。**



---


# 深度对比分析：CBuild-ng vs. Yocto vs. Buildroot vs. Bazel vs. Autotools vs. CMake vs. Meson

下表从设计哲学、架构模型、配置可视化、构建性能、跨发行版部署、生态合规与适用场景七大维度，对主要构建工具进行系统对比。

## 1. 设计哲学

- CBuild-ng
 以极简内核（≈7000 行）、机制与策略分层为核心（**模块化联邦**），提供包级依赖管理、Dual-Build（经典/Yocto）模式、三方工具集成（调用cmake、autotools、meson等）、IMake 模板化和 CPK 用户态打包，追求可读、可审计、可控。

- Yocto
 专注于嵌入式 Linux 发行版定制，提供 layer/recipe 机制和丰富的 BSP 支持，但依赖 BitBake DSL，学习曲线陡峭。

- Buildroot
 以 Makefile+Kconfig 为基础，快速生成目标板 rootfs，适合嵌入式场景，功能集中、上手快，但缺乏复杂包依赖管理。

- Bazel
 注重可复现性和大规模分布式构建，采用 Starlark 规则和三阶段执行，支持多语言，但需 JVM/Go 运行时和远程执行基础设施。

- Autotools
 采用 Autoconf/Automake/Libtool 组合，面向传统 Unix 平台，适用性广，但脚本繁复、调试困难。

- CMake
 DSL 简洁，支持多语言和 IDE 集成，生成 Ninja/Makefile，再加上 Ninja 提升性能，需开发者自行管理依赖和部署。

- Meson
 基于 Python 风格 DSL 与 Ninja 后端，配置简单、速度快，专注于库和应用的构建，但不提供系统级部署机制。

## 2. 架构模型

| 特性 | CBuild-ng | Yocto | Buildroot | Bazel | Autotools | CMake+Ninja | Meson |
| ---- | --------- | ----- | --------  | ----- | --------- | ----------- | ----- |
| 核心实现语言 | Python + Shell + Makefile | BitBake (Python DSL) | Makefile + Kconfig | Java/Go + Starlark | Shell + M4 + Makefile | CMakeLists + Ninja | Python DSL + Ninja |
| 执行流程 | 单体脚本 + 模块化 + 输入驱动缓存 | BitBake 引擎调度 | Make 调度 | Load → Analyze → Execution 三阶段 | configure → make → make | configure → ninja | configure → ninja |
| 扩展与插件 | IMake 模板 + Kconfig + Python 插件 | layer/recipe | 包含简单 mk 包 | Starlark 规则 + 远程执行插件 | m4 宏 + 自定义脚本 | 自定义模块和查找脚本 | 模块化脚本 |
| 运行时隔离 | CPK 用户态封装（无沙箱） | SDK 容器（可选 Yocto SDK 容器） | 无 | 强沙箱（namespace、exec root） | 无 | 无 | 无 |

## 3. 配置可视化

| 特性 | CBuild-ng | Yocto | Buildroot | Bazel | Autotools | CMake+Ninja | Meson |
| ---- | --------- | ----- | --------  | ----- | --------- | ----------- | ----- |
| 交互式配置 | 自动生成 Kconfig (`menuconfig`) | `bitbake-cursesconfig` | `make menuconfig` | 无 | `./configure` + 手动 | `cmake-gui`（可选） | 需第三方插件 |
| 依赖与说明嵌入 | 包元信息（版本/许可/依赖）直显界面 | recipe LICENSE/DEPENDS | LICENSE 标签 + 包选择 | BUILD 文件注明 | `AM_INIT_AUTOMAKE` | 手动书写 find_package | 手动书写 dependency |
| 可视化依赖图谱 | 自动生成 dot/svg/png | layer 依赖图 | 简易依赖列表 | 社区工具（bazel query） | 无 | 无 | 外部工具支持 |

## 4. 构建性能与增量

| 特性 | CBuild-ng | Yocto | Buildroot | Bazel | Autotools | CMake+Ninja | Meson |
| ---- | --------- | ----- | --------  | ----- | --------- | ----------- | ----- |
| 编译速度 | ✅ 快（原生 Makefile 速度，无额外中间产物） | ⚠️ 较慢（BitBake 调度和 Python DSL 开销） | ✅ 快（Makefile 原生速度） | ✅ 快（并行 + 本地/远程缓存加速） | ⚠️ 中等（Autotools configure 阶段有额外开销） | ⚠️ 中等（Ninja 执行快，但 CMake configure 和中间产物较多） | ⚠️ 中等（Ninja 执行快，但 Meson 配置阶段有 Python 开销） |
| 本地增量 | 输入驱动缓存精准重编 | 无本地缓存 | 部分缓存 | 严格声明 + 本地缓存 | 时间戳依赖 | 时间戳依赖 | 时间戳依赖 |
| 远程缓存 | 原生支持（NFS/S3/Artifactory） | 无 | 无 | 原生支持（Remote Build Execution） | 无 | 社区插件支持 | 社区插件支持 |
| 分布式执行 | 暂不支持 | 无 | 无 | 原生支持 | 无 | 无 | 无 |

## 5. 跨发行版部署

| 特性 | CBuild-ng | Yocto | Buildroot | Bazel | Autotools | CMake+Ninja | Meson |
| ---- | --------- | ----- | --------  | ----- | --------- | ----------- | ----- |
| 发行版兼容性 | ✅ 自带 glibc & ld.so，无需适配 | ❌ 通常只限目标板 | ❌ 通常只限目标板 | ✅ 多平台（需装 Bazel） | ❌ 依赖目标环境 | ❌ 依赖目标环境   | ❌ 依赖目标环境 |
| 安装与分发   | 单文件 `.cpk` 或 用户空间安装 | 镜像/SDK 安装 | 镜像/SDK 安装 | 二次封装（容器/脚本） | `make install` + 包管理器 | 手动或脚本分发 | 手动或脚本分发 |
| 运行时隔离   | 用户态闭环（无容器/守护进程） | Yocto SDK 容器（可选） | 无 | 沙箱（可选） | 无 | 无 | 无 |

## 6. 生态与合规

- CBuild-ng
 自动生成 SPDX 许可证清单、HTML/JSON 索引和依赖图，支持 GPLv2→MIT 双许可，CPK 内生合规。

- Yocto
 recipe 中强制 LICENSE 字段，社区工具支持 SPDX 报告。

- Buildroot
 简单 LICENSE 字段，需手动维护 SPDX。

- Bazel
 BUILD 文件可声明 license，需自行集成合规流程。

- Autotools
 通过 `configure.ac` 和 `Makefile.am` 嵌入许可证文本，需手动核对。

- CMake+Ninja / Meson
 无统一合规框架，项目自行管理 LICENSE 文件和依赖列表。

## 7. 适用场景

| 场景                             | 推荐工具 |
| -------------------------------- | ------------------------------- |
| 嵌入式 Linux 发行版定制          | CBuild-ng（Dual-Build + 包级依赖） / Yocto |
| 资源受限设备快速 rootfs 构建     | CBuild-ng / Buildroot |
| 大规模 SDK 和多机 CI/CD 并行构建 | CBuild-ng（本地+远程缓存） / Bazel（RBE） |
| 纯应用或库跨平台构建与 IDE 集成  | CMake+Ninja / Meson |
| 超大规模多语言分布式团队         | Bazel |
| 小型 C/C++ 工具链和脚本式构建    | CBuild-ng（IMake） |
| 需要严格 hermetic 构建与沙箱隔离 | Bazel |

# 总结

CBuild-ng 以**包级别的依赖管理**、**统一双模式**、**IMake 模板化**和**全链路可视化/合规**为核心，既覆盖了嵌入式发行版定制，也满足大规模 SDK、CI/CD 和小型工具链的多维需求（CBuild-ng是唯一完全支持这些需求的构建框架）。它在简洁性与功能性之间找到了独特平衡，成为多场景下的高效构建与分发平台。（CBuild-ng的短处是专注Linux不支持跨平台开发，且是新的工具生态还在建设。）
