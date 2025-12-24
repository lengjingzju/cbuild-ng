# IMake: Reinventing Build Systems with Clarity and Efficiency for Native Linux Development

## Introduction: At the Crossroads of Build Systems

In the world of C/C++ engineering, the choice of build systems has long been a delicate balancing act. On one hand, "generator-style" build tools represented by **CMake**, with their powerful cross-platform abstraction capabilities, have nearly unified the build layer from desktop to mobile. On the other hand, many developers deeply involved in the **Linux platform**, especially in embedded systems, kernel, and foundational software, often feel a sense of alienation and efficiency loss within CMake's "black box magic." They yearn for a build experience more aligned with the Unix philosophy—"simple, clear, transparent."

The **IMake/CBuild-ng** project emerges precisely against this backdrop. It is not a simple improvement or reinvention of CMake, but rather a **return to fundamental principles coupled with a technical redesign**. It accurately targets the core pain points of CMake in deep Linux development scenarios, proposing and implementing a fundamentally different solution: not as an abstractor for all platforms, but as a deep cultivator within the Linux domain.

This article will delve into IMake's design philosophy, architectural innovations, and present an objective comparison through a detailed multi-dimensional table, showcasing the real strengths and weaknesses of IMake versus CMake in different scenarios. The goal is to provide engineers facing technology selection with a clear and comprehensive reference.

## Part 1: The Design Philosophy and Core Architecture of IMake

### 1.1 Philosophy: Returning to Transparency, Declarativeness, and Control

```
IMake Architecture (Declarative, Layered)
├── Core Layer: 3 Declarative Build Functions
│   ├── add-liba-build    # Static Library
│   ├── add-libso-build   # Shared Library
│   └── add-bin-build     # Executable
├── Module Layer: INC_MAKES System (Loaded on Demand)
│   ├── inc.env.mk        # Environment Detection
│   ├── inc.conf.mk       # Configuration Management
│   ├── inc.app.mk        # Application Building
│   ├── inc.mod.mk        # Kernel Module Building
│   └── inc.ins.mk        # Installation Rules
└── Ecosystem Layer: Integration with CBuild-ng
    ├── Unified Package Management
    ├── Multi-Build System Support
    ├── Multi-level Caching Acceleration
    └── Enterprise Compliance Features
```

IMake's core philosophy can be summarized in three points:

- **Transparency First**: The build process should be completely visible and understandable. Developers should be able to see and control every single parameter passed to the compiler directly, not converse with a generator.
- **Declarative over Imperative**: Developers should describe "what needs to be built" (e.g., a shared library named `libfoo`), rather than write a series of instructions for "how to build it." This greatly simplifies build description files.
- **Environment-Driven, Not Configuration-Driven**: Build modes (e.g., native/cross, GCC/Clang) should be switched instantly via environment variables, without needing a separate configuration phase, enabling seamless development workflows.

### 1.2 Architecture: The Synergy of the CBuild-ng Platform and the IMake Framework

The core architecture is "one concept, two layers of design," with clear division of labor. CBuild-ng serves as the integrated "platform layer," responsible for project management and dependency coordination; IMake serves as the focused "framework layer," providing core build logic.

- **CBuild-ng**: As the **upper-layer management and integration platform**, it handles the software package lifecycle, including source acquisition (supporting Git, SVN, HTTP), multi-level caching, dependency resolution and arbitration, and unified scheduling of different underlying build systems (like IMake, CMake, Meson). It solves the engineering problems of "where from and where to."
- **IMake**: As the **core, Linux-oriented build framework**, it provides a declarative Domain-Specific Language (DSL) based on GNU Make. It defines build targets with minimal syntax and has built-in deep support for complex scenarios common in Linux development (like cross-compilation, kernel modules). It solves the technical problem of "how to compile efficiently and clearly."

This architecture allows IMake-based projects to be embedded into existing projects as a standalone build tool or to gain enterprise-grade reusability and supply chain management capabilities through CBuild-ng.

If IMake is a sharp knife, CBuild-ng is the entire toolkit. It solves the full-chain problems from source code to finished product:
- **Unified Package Definition**: Declares project metadata, dependencies, and build methods via the `mk.deps` file.
- **Multi-Build Engine Support**: Can not only invoke IMake-based projects but also seamlessly manage traditional projects (CMake, Meson, Autotools, etc.), acting as an upper-level coordinator.
- **Enterprise-Grade Caching**: Supports caching mechanisms for source code (original URL, domestic mirror, LAN mirror, local mirror) and build artifacts (LAN mirror, local mirror), providing a complete solution for development within **physically isolated networks**, common in sectors like defense and finance.
- **Software Supply Chain Management**: Can generate Software Bill of Materials (SBOM), includes license checking, and can generate dependency graphs for visual management.

### 1.3 Systematic Package Management Solution

For dependency management in large-scale systems, IMake provides a unified management mechanism through collaboration with CBuild-ng:

*   **Unified Dependency Declaration File**: Each software package (whether a base library or an upper-layer application) declares its metadata and dependencies through an `mk.deps` file. For large systems, this forms a **global dependency graph**. CBuild-ng parses this graph to compute the build order and versions for all components.
*   **Packaging and Deployment of Build Artifacts**: CBuild-ng can package build artifacts (libraries, header files) into compressed archives, serving as deterministic dependency sources for other components, perfectly supporting offline development in physically isolated networks. It also supports packaging into the CPK format (essentially an installation script plus a compressed archive) for cross-platform deployment.
*   **Active Provisioning, Not Passive Searching**: When building component A, CBuild-ng will **actively prepare** the **precise versions** of its declared dependencies, libraries B and C (from cache or source build), based on its `mk.deps` file. Developers don't need to worry about where dependencies are located; the platform guarantees the provided versions are correct.

The core approaches of CMake and IMake (passive searching vs. active management) are fundamentally different, as compared below:

| Management Dimension | CMake (as a build tool) | CBuild-ng (as a build management platform) |
| :--- | :--- | :--- |
| **Core Philosophy** | **"Find and Use"**: **Search** for existing dependencies in the current system or specified directories. | **"Declare and Provide"**: **Declare** all dependencies and their precise versions at the top level, with the platform **responsible for providing** them. |
| **Dependency Source** | Dispersed and uncertain: System paths, `CMAKE_PREFIX_PATH`, external package managers like `vcpkg`/`conan`. | Centralized and deterministic: **Uniquely and controllably sourced from internal repositories, cache, or source builds**. |
| **Version Control** | Difficult: Subprojects may find inconsistent versions through different paths or package managers, easily leading to the "works on my machine" problem. | **Strictly Locked**: **Declare precise versions or Git commit hashes** in the top-level `mk.deps`, ensuring a completely consistent build environment across the entire system. |
| **Cross-Project Consistency** | **No native support**: Each CMake project manages dependencies independently, making it difficult to guarantee the entire system uses the same libraries. | **Core Design Goal**: Dependencies for all projects (whether IMake, CMake, or Autotools projects) are **unifiedly parsed, built, and supplied** by CBuild-ng. |
| **Enterprise Support** | Relies on combining external ecosystems; requires setting up private repositories, caches, and audit toolchains separately. | **Built-in Enterprise Features**: Multi-level caching, builds in physically isolated networks, Software Bill of Materials (SBOM) generation, etc., are available out-of-the-box. |

## Part 2: Analysis of IMake's Disruptive Features

### 2.1 Minimalist Declarative Build Scripts

IMake covers most build scenarios with three core functions, freeing developers from the burden of writing complex rules.

```makefile
# A complete definition for a static library, shared library, and executable
# INC_MAKES can be set to a combination of `disenv` `conf` `app` `mod` `disins`.
#   disenv: Excluding inc.env.mk
#   conf  : Including inc.conf.mk
#   app   : Including inc.app.mk
#   mod   : Including inc.mod.mk
#   disins: Excluding inc.ins.mk
INC_MAKES      := app
include inc.makes

SRCS = $(wildcard src/*.c)

# Declarative Build: One-line definitions, automatic handling of compilation, linking, dependency tracking
$(eval $(call add-liba-build,libmymath.a,$(SRCS)))              # Static Library
$(eval $(call add-libso-build,libmymath.so 1 0 0,$(SRCS)))      # Versioned Shared Library
$(eval $(call add-bin-build,calculator,app/main.c,-lmymath))    # Executable
```

The advantages of this design are immediately apparent:

- **Minimalist**: Work that traditionally requires dozens of lines in a Makefile or CMake often takes single-digit lines in IMake.
- **Transparent**: Executing `make PREAT= MFLAG=` shows the real commands passed to GCC/Clang—no magic.
- **Intelligent**: Version numbers can be automatically extracted from source headers; dependency relationships are automatically deduced.
- **Modular**: Allows developers to load features on demand (environment, configuration, installation, application compilation, driver compilation), keeping the build environment clean and efficient.

A real-world engineering example:

```makefile
# Dependency declaration in mk.deps file
#DEPS() jmixer(native psysroot): ljcore ljson jacodec jaalgo

# Compilation logic defined in the Makefile
PACKAGE_NAME    = jmixer
SEARCH_HDRS    := ljcore

INSTALL_HEADERS:= $(wildcard src/*.hpp)

CPFLAGS        += -Isrc

.PHONY: all clean install
all:
	@echo "Build $(PACKAGE_NAME) Done!"

INC_MAKES      := app
object_byte_size= 65536
frame_byte_size = 16384
ENV_BUILD_TYPE := release
include inc.makes

staticlib      := libjmixer.a
sharedlib      := libjmixer.so $(call get_version,src/audio_control.hpp,JMIXER_VERSION, )
libsrcs        := $(wildcard src/*.cpp)
$(call set_flags,CFLAGS,src/audio_message.cpp,-Wno-missing-field-initializers)
LLIBS          := $(addprefix -l,ljcore ljson g711 g722 bcg729 opus fdk-aac)
$(eval $(call add-liba-build,$(staticlib),$(libsrcs)))
$(eval $(call add-libso-build,$(sharedlib),$(libsrcs),$(LLIBS)))

server_srcs    := test/jmixer_server.cpp
server_libs    := $(addprefix -l,ljcore ljson $(PACKAGE_NAME))
$(eval $(call add-bin-build,jmixer_server,$(server_srcs),$(server_libs),,$(OBJ_PREFIX)/lib$(PACKAGE_NAME).so))

client_srcs    := test/jmixer_client.cpp
client_libs    := $(LLIBS) -l$(PACKAGE_NAME)
$(eval $(call add-bin-build,jmixer_client,$(client_srcs),$(client_libs),,$(OBJ_PREFIX)/lib$(PACKAGE_NAME).so))

command_srcs   := test/jmixer_command.cpp
command_libs   := $(addprefix -l,ljcore ljson $(PACKAGE_NAME))
$(eval $(call add-bin-build,jmixer_command,$(command_srcs),$(command_libs),,$(OBJ_PREFIX)/lib$(PACKAGE_NAME).so))

all: $(BIN_TARGETS) $(LIB_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS) $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_hdrs install_libs install_bins
	@echo "Install $(PACKAGE_NAME) to $(INS_PREFIX) Done."
```

### 2.2 Elegant Implementation of Six Build Modes

IMake precisely defines six build modes covering the entire Linux development workflow. Their switching method intuitively demonstrates the advantage of being environment-variable-driven:

```bash
# 【Mode 1 & 2】Classic Native Development
make                                           # Native GCC
make CC_TOOL=clang                             # Native Clang

# 【Mode 3 & 4】Classic Cross-Compilation (Core of Embedded Development)
make CROSS_COMPILE=aarch64-linux-gnu-          # ARM64 GCC Cross-Compilation
make CROSS_COMPILE=aarch64-linux-gnu- CC_TOOL=clang USING_CLANG_CXX_BUILD=y # ARM64 Clang Cross-Compilation
# Note: CROSS_COMPILE with a path should use ENV_BUILD_TOOL=/<toolchain path>/aarch64-linux-gnu-

# 【Mode 5 & 6】Deep Integration with Yocto Build System
# Seamlessly integrated within Yocto recipes via environment variables
export ENV_BUILD_MODE=yocto
# Export whether it's cross or native compilation
NATIVE_BUILD:class-target = "n"
NATIVE_BUILD:class-native = "y"
export NATIVE_BUILD
# Invoke the build
do_compile() {
    oe_runmake  # Internally adapts to the above modes automatically
}
```

The essence of these six modes lies in **"zero-cost switching"**. Developers do not need to modify any build files or execute time-consuming reconfiguration (`cmake -B build`). Seamless switching between development, testing, and production environments is achieved solely through environment variables, which is a huge efficiency boost for continuous integration and heterogeneous team collaboration.

### 2.3 Deep Integration with the Linux Ecosystem

- **Kernel-style Interactive Configuration**: IMake introduces the **Kconfig system** (kconfig, modified based on linux-6.18, adds configuration output and source separation features), which originates from the Linux kernel. Developers can use the familiar `make menuconfig` command to manage project configurations (e.g., `CONFIG_FEATURE_X=y`) in a terminal graphical interface. The generated `.config` file is clear, readable, and easy to manage with version control.
- **Kernel Module Build Support**: An innovation of IMake (driver compilation output and source separation) has been partially adopted by the Linux kernel community. The **framework for separate compilation of driver code and kernel source tree** allows kernel module development to enjoy an independent build experience similar to user-space programs, significantly lowering the barrier to entry.

## Part 3: Objective Dimensional Comparison – IMake vs. CMake

The following comparison table aims to objectively present the capabilities of both in different dimensions. **Five stars (★★★★★) indicate excellent or highly advantageous performance in that dimension; one star (★) indicates a significant shortcoming or that it is not a design goal.**

| Dimension | Evaluation Criteria | IMake | CMake | Advantage | Detailed Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Core Positioning** | Target Domain & Philosophy | **Deeply optimized for Linux native development**<br>Transparent, controllable, declarative | **Cross-platform abstraction and unification**<br>"Write once, run anywhere" | **Divergence** | IMake chooses to go deep and thorough in the Linux domain, sacrificing generality for ultimate experience. CMake pursues the broadest platform coverage, its abstraction being the foundation of generality. |
| **Build Model & Performance** | Build Process & Speed | **Direct Build Model**<br>No intermediate generation; incremental builds are precise and fast <br>★★★★★ | **Generator Model**<br>First `configure` to generate, then `build` <br>★★★☆☆ | **IMake** | IMake calls the compiler directly, with no configuration phase overhead, especially excelling at fast incremental compilation for large projects. CMake's generation phase becomes a performance bottleneck when projects are complex or configurations change. |
| **Cross-Compilation Experience** | Ease of Use & Integration | **Environment Variable Driven**<br>`CROSS_COMPILE=arm-` to switch <br>★★★★★ | **Independent Toolchain File**<br>Requires writing/finding `toolchain.cmake` and reconfiguring <br>★★☆☆☆ | **IMake** | IMake's approach is completely consistent with the workflow of Linux developers (e.g., kernel compilation), with zero learning cost and extremely simple integration into scripts and CI. CMake's approach is more formal but more cumbersome. |
| **Configuration Management** | Complexity & Interactivity | **Kconfig System Integration**<br>`make menuconfig` graphical interface <br>★★★★★ | **CMake Variables & `option()`**<br>Imperative setting, no standard interactive interface <br>★★★☆☆ | **IMake** | IMake provides an industry-standard interactive interface for managing complex projects with numerous optional features (e.g., media frameworks). CMake's approach becomes difficult to maintain as features multiply. |
| **Code Conciseness** | Build Description File Length | **Minimalist Declarative**<br>Typically **20-50 lines** to build a library <br>★★★★★ | **Imperative Scripting**<br>Same functionality typically requires **80-150 lines** <br>★★★☆☆ | **IMake** | IMake's three core functions abstract common build patterns, drastically reducing boilerplate code and repetitive work. |
| **Debugging & Transparency** | Build Process Control | **Fully Transparent**<br>`make PREAT= MFLAG=` outputs real compilation commands <br>★★★★★ | **Indirect Abstraction**<br>Need to trace commands within the generated build system <br>★★☆☆☆ | **IMake** | When link errors occur or flags don't take effect, IMake allows developers to see the root cause directly. CMake's abstraction layer makes debugging build issues themselves difficult. |
| **Linux Kernel Development** | Support Depth | **Deep Integration, Innovation Adopted**<br>Supports driver separation compilation <br>★★★★★ | **Virtually No Native Support**<br>Requires additional maintenance of Kbuild scripts <br>★☆☆☆☆ | **IMake** | This is IMake's **killer feature**. For kernel module developers, it provides the only modern, integrated build experience. |
| **Security & Compliance** | Built-in Capabilities | **One-Click Built-in Hardening**<br>`ENV_SECURITY=y` <br>★★★★☆ | **Depends on External Toolchain Integration**<br>Requires manual flag setting or finding packages <br>★★☆☆☆ | **IMake** | IMake integrates common secure compilation options and static analysis tools into the framework, lowering the barrier to secure development. CMake relies more on its ecosystem. |
| **Learning Curve** | Onboarding Difficulty | **Gentle**<br>Based on Makefile knowledge; core is just three functions <br>★★★★☆ | **Steep**<br>Requires mastering proprietary syntax, generator expressions, etc. <br>★★☆☆☆ | **IMake** | Engineers familiar with Linux development can get started with IMake at almost zero cost. CMake is a world of its own, requiring dedicated time to learn. |
| **Ecosystem Breadth** | Third-Party Library Support | **Focuses on Linux System Layer**<br>Covers kernel, embedded, foundational services <br>★★★☆☆ | **Extremely Broad**<br>Covers desktop, mobile, gaming, scientific computing, etc. <br>★★★★★ | **CMake** | **This is CMake's absolute strength.** Almost any well-known C/C++ library provides CMake support. IMake's ecosystem is more vertical and cannot compare in general library support. |
| **Cross-Platform Support** | Non-Linux Platforms | **Not a Primary Goal**<br>Can manage other build systems via CBuild-ng <br>★★☆☆☆ | **Core Strength**<br>Provides first-class support for Windows, macOS, iOS, Android <br>★★★★★ | **CMake** | If your project must target **Windows/macOS** for desktop application distribution, CMake is currently the only mature choice. |
| **Enterprise Features** <br>(provided by CBuild-ng) | Supply Chain, Cache, etc. | **Native Integrated Platform**<br>Built-in multi-level cache, offline builds, SBOM generation <br>★★★★☆ | **Relies on External Ecosystem Combination**<br>Requires Conan/vcpkg, etc., to achieve <br>★★★☆☆ | **IMake** | CBuild-ng packages source management, dependency resolution, build caching, and compliance checking into one tool, providing an out-of-the-box solution for enterprise scenarios like closed networks. |

## Part 4: Technology Selection Guide

### 4.1 When Should IMake/CBuild-ng Be Prioritized?

If your project aligns with the following characteristics, IMake will bring significant efficiency and experience improvements:

1.  **Pure Linux Project**: Especially **server backends, infrastructure software, high-performance computing** projects with high demands for build performance and transparency.
2.  **Embedded Linux Product**: Requires frequent **cross-compilation** between x86_64 development hosts and ARM/MIPS target boards. IMake's mode switching is revolutionary.
3.  **Linux Kernel Module or Driver Development**: IMake is currently the only tool providing a modern, integrated build experience.
4.  **Strict Requirements for Build Security & Compliance**: Need to conveniently enable a full set of secure compilation options or require reproducible builds within **physically isolated networks**.
5.  **Tired of CMake's Complexity and Black-Box Nature**: Craving a build system with simpler scripts and easier-to-debug issues.

### 4.2 When Should CMake Continue to Be Used?

In the following scenarios, CMake remains the safer or only choice:

1.  **Strictly Cross-Platform Project**: Must provide functionally identical binary distributions for **Windows, macOS, and Linux**, especially GUI applications.
2.  **Deep Integration with Specific IDE or Ecosystem**: Team development workflow is tightly built around **Visual Studio or Xcode**, or the project heavily relies on frameworks like **Unreal Engine** that are deeply integrated with CMake.
3.  **Dependency on Many Third-Party Libraries That Only Support CMake**: The project has a broad technology stack and does not want to bear the cost of porting or creating IMake build descriptions for these libraries.

### 4.3 Hybrid Architecture Strategy

For large, complex projects, a pragmatic layered strategy can be adopted:
- **Core Layer/Platform Layer**: Use **IMake**. This part is often the platform-dependent core algorithms, engine, or system services, benefiting from IMake's ultimate performance and transparency.
- **Upper Application/UI Layer**: Use **CMake**. This part might be cross-platform clients or tools, leveraging CMake's rich UI framework (e.g., Qt) support and mature packaging toolchains.
- **Unified Management with CBuild-ng**: Manage CMake projects also as "packages" within CBuild-ng, achieving top-level unification of dependencies and build processes.

## Part 5: Future Outlook and Conclusion

The emergence of IMake/CBuild-ng signifies an important differentiation and reflection within the domain of build systems. It proves that alongside the mainstream path of "generality," there exists a path towards **"expertise" and "excellent experience."**

Its future lies not in replacing CMake, but in becoming the **benchmark tool for core domains like Linux system programming, embedded development, and infrastructure software**. With the rise of cloud-native and edge computing, the demand for efficient, controllable, and reproducible build processes will only grow stronger, which is precisely the strength of IMake/CBuild-ng.

**Conclusion**: In an era of increasing software engineering complexity, IMake is like an invitation to re-examine tools taken for granted. It reminds us that sometimes the best way forward is to return to the roots—pursuing clarity, transparency, and complete mastery over the technology. For any engineer dedicated to building solid and reliable software in the Linux world, understanding and seriously evaluating IMake/CBuild-ng is a highly valuable technical investment.
