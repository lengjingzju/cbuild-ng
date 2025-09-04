# IMake: Bringing Builds Back to Makefile’s Essence — An Unprecedentedly Simple Experience

---

## The Modern Build System Dilemma and the Birth of IMake

In today’s software development landscape, the build system has become a critical factor in project success. From the classic Makefile to modern tools like Autotools, CMake, and Meson, developers have been searching for more efficient and flexible build solutions. However, these tools often come with steep learning curves and complex configuration syntaxes:

- **Autotools** requires writing complex `configure.ac` and `Makefile.am` files using the M4 macro language, making configuration cumbersome.
- **CMake**, while powerful, demands learning its own `CMakeLists.txt` syntax, and the generated Makefiles are often hard to read and debug.
- **Meson**, a newer entrant with modern design concepts, still requires learning a new configuration language.

In their pursuit of power, these tools have drifted away from the essence of a build system—simplicity, intuitiveness, and control. Against this backdrop, IMake (Include Makefile) was born, bringing builds back to the Makefile’s essence while offering the advanced features of modern build systems.

---

## IMake’s Core Strength: Simplicity Without Sacrificing Power

IMake is a pure Makefile-based build template system. Through modular design, it encapsulates complex build logic into reusable templates. By simply including the relevant template files and setting a few variables, you can easily configure builds ranging from simple applications to complex systems.

### Key Advantages

- **Minimal Configuration:** Say goodbye to complex `configure.ac`, `CMakeLists.txt`, and `meson.build` files—just define a few variables to compile.
- **Native Makefile Experience:** 100% Makefile-based—no new syntax to learn, existing knowledge applies directly.
- **menuconfig GUI:** Familiar Kconfig interface for easy build option management.
- **Versatile Support:** Local and cross-compilation, classic and Yocto builds, static/shared libraries, executables, and kernel modules—all supported.
- **Toolchain Flexibility:** Supports GCC and Clang with easy switching.
- **Smart Dependency Handling:** Automatically analyzes header dependencies, detects environment changes, and triggers rebuilds to ensure correct build order.
- **Predefined Build Options:** Common options like optimization levels, security hardening, sanitizers, static analysis, and profiling are built in.
- **Standards Compliance:** Supports `O=` for out-of-tree builds, `DESTDIR` for install paths (GNUInstallDirs-compliant), and custom `DEPDIR` for dependency roots.

### Comparison with Other Build Systems

| Feature            | IMake (Makefile) | CMake           | Autotools       | Meson           |
|--------------------|------------------|-----------------|-----------------|-----------------|
| Learning Curve     | Gentle           | Steep           | Steep           | Moderate        |
| Config Simplicity  | ★★★★★             | ★★★☆☆           | ★★☆☆☆           | ★★★★☆           |
| Debug Friendliness | ★★★★★             | ★★★☆☆           | ★★☆☆☆           | ★★★☆☆           |
| Cross-Platform     | Linux-focused    | All platforms   | Unix-like       | All platforms   |
| Visual Config      | Built-in menuconfig | Extra tools needed | None         | Limited         |
| Ecosystem Integration | Complete     | Rich            | Mature          | Growing         |

---

## Ideal Use Cases and Target Users

### Ideal Scenarios

1. **Embedded Linux Development:** Full-featured cross-compilation with simple configuration.
2. **System-Level Software:** Strong kernel module support, Linux standards-compliant.
3. **Open-Source Libraries:** GNU-compliant, easy integration into other projects.
4. **Large-Scale Projects:** Modular design, component-based development, intuitive menuconfig interface.

### Target Users

- Developers who value simplicity and transparency in build systems.
- Linux-focused software engineers.
- Those frustrated by the complexity of Autotools/CMake/Meson.
- Experienced programmers seeking deep control over the build process.

---

## Build Template Features in Detail

IMake can be used independently of CBuild-ng. It’s recommended to use the `inc.makes` template and set `INC_MAKES` to enable the desired templates.

- `inc.makes` by default enables only `inc.env.mk` and `inc.ins.mk`.
- `INC_MAKES` can be a combination of:
  - `disenv`: Disable `inc.env.mk`
  - `conf`: Enable `inc.conf.mk`
  - `app`: Enable `inc.app.mk`
  - `mod`: Enable `inc.mod.mk`
  - `disins`: Disable `inc.ins.mk`


Template specific instructions refer to [compilation-template](https://github.com/lengjingzju/cbuild-ng?tab=readme-ov-file#compilation-template) .

---

## Usage Examples

**Real-World Projects**

- [LJSON](https://gitee.com/lengjingzju/json)
- [JCore](https://gitee.com/lengjingzju/jcore)

---

### Header-Only Application Project

- A header-only project only needs an install step.
- Headers are installed into an `include/$(PACKAGE_NAME)` subdirectory to avoid name collisions in large projects.

```makefile
PACKAGE_NAME    = xxx

INSTALL_HEADERS:= $(wildcard src/*.h)

.PHONY: all clean install
all:
	@echo "Build $(PACKAGE_NAME) Done!"

include inc.makes

clean:
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_hdrs
	@echo "Install $(PACKAGE_NAME) to $(INS_PREFIX) Done."
```

---

### Single-Library Application Project

- Specify the static library name via `LIBA_NAME` and the shared library name via `LIBSO_NAME`.
- Automatically extract the version from `VERSION_FILE` using the macro `VERSION_NAME` to produce a shared library like `libxxx.so.x.y.z`.

```makefile
PACKAGE_NAME    = xxx

VERSION_FILE   := xxx.hpp
VERSION_NAME   := XXX_VERSION

LIBA_NAME      := libxxx.a
LIBSO_NAME     := libxxx.so
CPFLAGS        += -I./src

INSTALL_HEADERS:= $(wildcard src/*.hpp)

.PHONY: all clean install
all:
	@echo "Build $(PACKAGE_NAME) Done!"

INC_MAKES      := app
include inc.makes

all: $(LIB_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_hdrs install_libs
	@echo "Install $(PACKAGE_NAME) to $(INS_PREFIX) Done."
```

---

### Multi-Library and Executable Mixed Project

- `SEARCH_HDRS` specifies subpaths for header search so code can use `#include "aaa.h"` instead of `#include "mmm/aaa.h"`.
- `object_byte_size` / `frame_byte_size` set maximum object and stack frame sizes; exceeding these triggers compile warnings to help debug large local variables (optional).
- `ENV_BUILD_TYPE` sets optimization level: `release` = `-O3`, default is `-O2`.
- `set_flags` applies compile flags to specific files (like kernel build per-file flags), while `CPFLAGS` is global.

```makefile
PACKAGE_NAME    = xxx
SEARCH_HDRS    := mmm nnn

INSTALL_HEADERS:= $(wildcard src/*.hpp)

CPFLAGS        += -Isrc -Wno-unused-parameter

.PHONY: all clean install
all:
	@echo "Build $(PACKAGE_NAME) Done!"

INC_MAKES      := app
object_byte_size= 65536
frame_byte_size = 16384
ENV_BUILD_TYPE := release
include inc.makes

staticlib      := libxxx.a
sharedlib      := libxxx.so $(call get_version,src/xxx.hpp,JXXX_VERSION, )
libsrcs        := $(wildcard src/*.cpp)
$(call set_flags,CFLAGS,src/xxx_message.cpp,-Wno-missing-field-initializers)
LLIBS          := $(addprefix -l,jcore ljson g711 g722 bcg729 opus fdk-aac)
$(eval $(call add-liba-build,$(staticlib),$(libsrcs)))
$(eval $(call add-libso-build,$(sharedlib),$(libsrcs),$(LLIBS)))

server_srcs    := test/xxx_server.cpp
server_libs    := $(addprefix -l,jcore ljson $(PACKAGE_NAME))
$(eval $(call add-bin-build,xxx_server,$(server_srcs),$(server_libs),,$(OBJ_PREFIX)/lib$(PACKAGE_NAME).so))

client_srcs    := test/xxx_client.cpp
client_libs    := $(LLIBS) -l$(PACKAGE_NAME)
$(eval $(call add-bin-build,xxx_client,$(client_srcs),$(client_libs),,$(OBJ_PREFIX)/lib$(PACKAGE_NAME).so))

all: $(BIN_TARGETS) $(LIB_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS) $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_hdrs install_libs install_bins
	@echo "Install $(PACKAGE_NAME) to $(INS_PREFIX) Done."
```

---

### Single Driver Project

```makefile
ifneq ($(KERNELRELEASE),)
MOD_NAME = xxx

INC_MAKES      := mod
include $(src)/inc.makes

else

PACKAGE_NAME    = xxx
SEARCH_HDRS     = mmm nnn

all: modules

clean: modules_clean

install: modules_install

INC_MAKES      := mod
include inc.makes
endif
```

---

### Single Driver with Test Program

- Uses the `KERNELRELEASE` macro to distinguish between Kbuild compilation and application compilation.

```makefile
ifneq ($(KERNELRELEASE),)
MOD_NAME       := xxx
SRCS           := $(wildcard $(src)/src/*.c)

INC_MAKES      := mod
include $(src)/inc.makes
ccflags-y      += -I$(src)/src

else

PACKAGE_NAME    = xxx
CPFLAGS        += -Isrc
INSTALL_HEADERS:= src/xxx.h

all: modules

clean: modules_clean

install: modules_install

INC_MAKES      := app mod
include inc.makes

$(eval $(call add-bin-build,xxx_test,test/xxx_test.c))

all: $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_bins install_hdrs
	@echo "Install $(PACKAGE_NAME) to $(INS_PREFIX) Done."

endif
```

---

## Conclusion: Back to the Essence, Simplifying Builds

The emergence of IMake is a thoughtful response to today’s overly complex build system ecosystem. It proves a simple truth: powerful capabilities don’t require convoluted configuration, and elegant design can handle complex build needs.

**Explore IMake and experience the beauty of simplicity in build systems!** If you’re looking for a build solution that’s both powerful and straightforward, IMake is worth your time.
