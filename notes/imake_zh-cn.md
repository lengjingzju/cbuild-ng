# IMake：让构建回归Makefile本质，前所未有的简单体验

## 现代构建系统的困境与IMake的诞生

在当今软件开发领域，构建系统已成为项目成功的关键因素。从经典的Makefile到现代的Autotools、CMake和Meson，开发者们一直在寻找更高效、更灵活的构建工具。然而，这些工具往往伴随着陡峭的学习曲线和复杂的配置语法：

- **Autotools** 需要编写复杂的configure.ac和Makefile.am文件，使用M4宏语言，配置过程繁琐
- **CMake** 虽然功能强大，但需要学习专属的CMakeLists.txt语法，生成的Makefile难以理解和调试
- **Meson** 作为后起之秀，设计理念先进但仍需学习新的配置语言

这些工具在追求功能强大的同时，却远离了构建系统的本质——简单、直观和可控。正是在这样的背景下，IMake（Include Makefile）应运而生，它让构建回归Makefile的本质，同时提供了现代构建系统的高级特性。

## IMake核心优势：简单而不失强大

IMake（Include Makefile）是一套基于纯Makefile实现的构建模板系统，它通过模块化的设计理念，将复杂的构建逻辑封装为可重用的模板。只需包含相应的模板文件并设置少量变量，您就能轻松完成从简单应用到复杂系统的构建配置。

### 核心优势

- **极简配置**：告别复杂的configure.ac、CMakeLists.txt、meson.build，只需定义几个变量即可完成编译
- **原生Makefile体验**：完全基于Makefile，无需学习新语法，现有知识完全适用
- **menuconfig图形化配置**：提供熟悉的Kconfig界面，轻松管理构建选项
- **多功能支持**：同时支持本地编译和交叉编译、经典编译和Yocto编译，静态库、动态库、可执行文件、内核模块一网打尽
- **工具链配置**：支持GCC和Clang，轻松切换编译环境
- **智能依赖处理**：自动分析头文件依赖，探测环境配置自动重新编译，确保正确的构建顺序
- **编译选项预置**：预置常用的可选编译选项：优化等级、安全增强、安全调试（sanitizer）、静态分析（analyzer）、性能分析（gprof）
- **符合标准规范**：符合通用的O指定编译输出（编译输出与源码分离），DESTDIR指定安装位置（安装目录符合GNUInstallDirs标准），自定义DEPDIR指定依赖根目录

### 优势对比

与其他构建系统相比，IMake具有独特优势：

| 特性 | IMake | CMake | Autotools | Meson |
|------|-------|-------|-----------|-------|
| 学习曲线 | 平缓（Makefile语法） | 陡峭（专属语法） | 陡峭（M4宏） | 中等（专属语法） |
| 配置简洁性 | ★★★★★ | ★★★☆☆ | ★★☆☆☆ | ★★★★☆ |
| 调试便利性 | ★★★★★ | ★★★☆☆ | ★★☆☆☆ | ★★★☆☆ |
| 跨平台支持 | Linux专注 | 全平台 | 类Unix | 全平台 |
| 可视化配置 | 内置menuconfig | 需额外工具 | 无 | 有限支持 |
| 生态集成 | 完善 | 丰富 | 成熟 | 成长中 |


## 适用场景与目标用户

### 理想应用场景

1. **嵌入式Linux开发**：交叉编译支持完善，配置简单
2. **系统级软件开发**：内核模块支持良好，符合Linux标准
3. **开源库开发**：符合GNU标准，易于其他项目集成
4. **大型项目构建**：模块化设计，支持组件化开发，menuconfig图形配置更直观

### 目标用户群体

- 追求构建系统简单性和透明度的开发者
- 主要工作在Linux环境的软件工程师
- 对Autotools/CMake/Meson复杂性感到沮丧的开发者
- 希望深度控制构建过程的资深程序员

## 编译模板功能特性详解

IMake可脱离CBuild-ng独立使用，建议用户使用模板 `inc.makes` 并设置 `INC_MAKES` 启用相应的模板

* `inc.makes` 默认只启用 inc.env.mk 和 inc.ins.mk
* `INC_MAKES` 的值可以是 `disenv` `conf` `app` `mod` `disins` 的组合
    * disenv: 不启用 inc.env.mk
    * conf  : 启用 inc.conf.mk
    * app   : 启用 inc.app.mk
    * mod   : 启用 inc.mod.mk
    * disins: 不启用 inc.ins.mk

模板详细说明参考 [编译模板](https://github.com/lengjingzju/cbuild-ng/blob/main/README_zh-cn.md#%E7%BC%96%E8%AF%91%E6%A8%A1%E6%9D%BF)

## 使用示例

**实际工程使用**

- [LJSON](https://gitee.com/lengjingzju/json)
- [JCore](https://gitee.com/lengjingzju/jcore)

### 纯头文件应用工程

* 纯头文件工程只有安装
* 头文件是安装在include的PACKAGE_NAME子目录下，防止大工程头文件重名

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

### 单库应用工程

* 指定生成的静态库LIBA_NAME和动态库LIBSO_NAME
* 从指定文件VERSION_FILE的指定版本宏VERSION_NAME自动提取版本，生成的动态库为libxxx.so.x.y.z

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

### 多库和可执行文件混合应用工程

* SEARCH_HDRS 指定头文件搜索的子路径，这样源代码可以写成 `#include "aaa.h"` 而不是 `#include "mmm/aaa.h"`
* object_byte_size/frame_byte_size 是指定最大对象和函数帧大小，大于该值时有编译警告，用于调试过大的局部变量，不是必需
* 可选ENV_BUILD_TYPE指定优化等级，release是 `-O3`，不指定时是 `-O2`
* set_flags是设置单个文件的编译标志，参考内核编译指定单文件的编译编译标志设置，而CPFLAGS是全局的

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

### 单驱动工程

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

### 单驱动含测试程序工程

* 通过KERNELRELEASE宏区分是Kbuild编译部分和应用编译部分

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

## 结语：回归本质，简化构建

IMake的出现是对当前复杂构建系统生态的一次重要反思。它证明了一个观点：强大的功能不一定需要复杂的配置，简单的设计也可以应对复杂的构建需求。

**探索IMake，体验构建系统的简单之美！** 如果您正在寻找一个既强大又简单的构建解决方案，IMake值得您的尝试。
