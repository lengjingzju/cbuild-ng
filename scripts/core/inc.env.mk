############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
# https://github.com/lengjingzju/cbuild-ng #
############################################

COLORECHO      := $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
LOGOUTPUT      ?= $(if $(filter y,$(BUILDVERBOSE)),,1>/dev/null)

INSTALL_HDR    ?= $(PACKAGE_NAME)
SEARCH_HDRS    ?= $(PACKAGE_DEPS)
ifneq ($(NATIVE_BUILD),y)
PACKAGE_ID     := $(PACKAGE_NAME)
else
PACKAGE_ID     := $(PACKAGE_NAME)-native
endif

ENV_OPTIMIZATION    ?= release
ifeq ($(ENV_OPTIMIZATION),debug)
OPTIMIZATION_FLAG   ?= -O0 -g -ggdb
else ifeq ($(ENV_OPTIMIZATION),speed)
OPTIMIZATION_FLAG   ?= -O3
else
OPTIMIZATION_FLAG   ?= -O2
endif

ifneq ($(ENV_BUILD_MODE),yocto)

ifneq ($(NATIVE_BUILD),y)
ENV_CROSS_ROOT ?= $(shell pwd)
WORKDIR        ?= $(ENV_CROSS_ROOT)/objects/$(PACKAGE_NAME)
SYS_PREFIX     ?= $(ENV_CROSS_ROOT)/sysroot
ifneq ($(CROSS_DESTDIR), )
INS_PREFIX     := $(CROSS_DESTDIR)
endif
ifneq ($(GLOBAL_SYSROOT),y)
DEP_PREFIX     ?= $(WORKDIR)/sysroot
else
DEP_PREFIX     ?= $(SYS_PREFIX)
endif
else # NATIVE_BUILD
ENV_NATIVE_ROOT?= $(shell pwd)
WORKDIR        ?= $(ENV_NATIVE_ROOT)/objects/$(PACKAGE_NAME)
SYS_PREFIX     ?= $(ENV_NATIVE_ROOT)/sysroot
ifneq ($(NATIVE_DESTDIR), )
INS_PREFIX     := $(NATIVE_DESTDIR)
endif
ifneq ($(GLOBAL_SYSROOT),y)
DEP_PREFIX     ?= $(WORKDIR)/sysroot-native
else
DEP_PREFIX     ?= $(SYS_PREFIX)
endif
endif # NATIVE_BUILD

INS_SUBDIR     ?= /usr
INS_TOPDIR     ?= $(WORKDIR)/image
INS_PREFIX     ?= $(WORKDIR)/image
OBJ_SUBDIR     ?=
OBJ_PREFIX     ?= $(WORKDIR)/build$(OBJ_SUBDIR)
ifneq ($(GLOBAL_SYSROOT),y)
PATH_PREFIX    ?= $(WORKDIR)/sysroot-native
else
PATH_PREFIX    ?= $(ENV_NATIVE_ROOT)/sysroot
endif

else # ENV_BUILD_MODE

# WORKDIR should be exported by yocto recipe.
# Yocto doesn't have SYS_PREFIX INS_TOPDIR INS_SUBDIR
ifneq ($(NATIVE_BUILD),y)
INS_PREFIX     ?= $(WORKDIR)/image
DEP_PREFIX     ?= $(WORKDIR)/recipe-sysroot
else # NATIVE_BUILD
INS_PREFIX     ?= $(WORKDIR)/image/$(WORKDIR)/recipe-sysroot-native
DEP_PREFIX     ?= $(WORKDIR)/recipe-sysroot-native
endif # NATIVE_BUILD

OBJ_SUBDIR     ?=
OBJ_PREFIX     ?= $(WORKDIR)/build$(OBJ_SUBDIR)
PATH_PREFIX    ?= $(WORKDIR)/recipe-sysroot-native

endif # ENV_BUILD_MODE

ifneq ($(O), )
OBJ_PREFIX     := $(O)$(OBJ_SUBDIR)
endif

ifneq ($(DESTDIR), )
INS_PREFIX     := $(DESTDIR)
endif

ifneq ($(DEPDIR), )
DEP_PREFIX     := $(DEPDIR)
endif

define link_hdrs
$(addprefix -I,$(addprefix $(DEP_PREFIX),/include /usr/include /usr/local/include) \
	$(if $(SEARCH_HDRS),$(wildcard \
	$(addprefix $(DEP_PREFIX)/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/local/include/,$(SEARCH_HDRS)) \
)))
endef

ifeq ($(KERNELRELEASE), )

comma          :=,
define link_libs
$(addprefix -L,$(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib)) \
$(addprefix -Wl$(comma)-rpath-link=,$(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib))
endef

ifneq ($(filter y,$(NATIVE_DEPEND) $(NATIVE_BUILD)), )
export PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/bin /usr/bin /usr/local/bin /sbin /usr/sbin /usr/local/sbin)$(if $(PATH),:$(PATH)) | sed 's/ /:/g')
export LD_LIBRARY_PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/lib /usr/lib /usr/local/lib)$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH)) | sed 's/ /:/g')
endif

ifneq ($(LICFILE), )
ifneq ($(ENV_BUILD_MODE),yocto)
ifneq ($(NATIVE_BUILD),y)
LICPATH        ?= $(SRC_PATH)
LICDEST        ?= $(INS_PREFIX)
define install_lics
	$(ENV_TOOL_DIR)/process_sysroot.sh license $(LICPATH) $(LICDEST) $(PACKAGE_NAME) "$(LICFILE)"
endef
endif
endif
endif

ifeq ($(install_lics), )
define install_lics
	true
endef
endif

# yocto envs should be exported by yocto recipe.

ifneq ($(ENV_BUILD_MODE),yocto)

PREPARE_SYSROOT := -s CROSS_DESTDIR=$(WORKDIR)/sysroot NATIVE_DESTDIR=$(WORKDIR)/sysroot-native \
                  NATIVE_BUILD= INSTALL_OPTION=link -C $(ENV_TOP_DIR) $(PACKAGE_ID)_psysroot

ifneq ($(DIS_PC_EXPORT),y)
export PKG_CONFIG_LIBDIR:=$(DEP_PREFIX)/usr/lib/pkgconfig
export PKG_CONFIG_PATH:=$(shell echo $(wildcard $(addprefix $(DEP_PREFIX),$(addsuffix /pkgconfig,/lib /usr/lib /usr/local/lib))) | sed 's@ @:@g')
endif

ifneq ($(NATIVE_BUILD),y)

ifneq ($(ENV_BUILD_ARCH), )
ARCH           := $(ENV_BUILD_ARCH)
export ARCH
endif

ifneq ($(ENV_BUILD_TOOL), )
ifneq ($(findstring /,$(ENV_BUILD_TOOL)), )
CROSS_TOOLPATH := $(shell dirname $(ENV_BUILD_TOOL))
CROSS_COMPILE  := $(shell basename $(ENV_BUILD_TOOL))
export PATH:=$(CROSS_TOOLPATH):$(PATH)
else
CROSS_COMPILE  := $(ENV_BUILD_TOOL)
endif
export CROSS_COMPILE
endif

ifeq ($(COMPILER_COLLECTION),clang)
CC             := $(CROSS_COMPILE)clang
CPP            := $(CROSS_COMPILE)clang -E
CXX            := $(CROSS_COMPILE)clang++
AS             := $(CROSS_COMPILE)llvm-as
LD             := $(CROSS_COMPILE)lld
AR             := $(CROSS_COMPILE)llvm-ar
RANLIB         := $(CROSS_COMPILE)llvm-ranlib
OBJCOPY        := $(CROSS_COMPILE)llvm-objcopy
STRIP          := $(CROSS_COMPILE)llvm-strip
else
CC             := $(CROSS_COMPILE)gcc
CPP            := $(CROSS_COMPILE)gcc -E
CXX            := $(CROSS_COMPILE)g++
AS             := $(CROSS_COMPILE)as
LD             := $(CROSS_COMPILE)ld
AR             := $(CROSS_COMPILE)ar
RANLIB         := $(CROSS_COMPILE)ranlib
OBJCOPY        := $(CROSS_COMPILE)objcopy
STRIP          := $(CROSS_COMPILE)strip
endif
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

else # NATIVE_BUILD

undefine ARCH CROSS_COMPILE
unexport ARCH CROSS_COMPILE

ifeq ($(COMPILER_COLLECTION),clang)
CC             := clang
CPP            := clang -E
CXX            := clang++
AS             := llvm-as
LD             := lld
AR             := llvm-ar
RANLIB         := llvm-ranlib
OBJCOPY        := llvm-objcopy
STRIP          := llvm-strip
else
CC             := gcc
CPP            := gcc -E
CXX            := g++
AS             := as
LD             := ld
AR             := ar
RANLIB         := ranlib
OBJCOPY        := objcopy
STRIP          := strip
endif
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

endif # NATIVE_BUILD
endif # ENV_BUILD_MODE

# Defines the GNU standard installation directories
# Note: base_*dir and hdrdir are not defined in the GNUInstallDirs
# GNUInstallDirs/Autotools: https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
# CMake: https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
# Meson: https://mesonbuild.com/Builtin-options.html#directories
# Yocto: https://git.yoctoproject.org/poky/tree/meta/conf/bitbake.conf

base_bindir    := /bin
base_sbindir   := /sbin
base_libdir    := /lib
bindir         := /usr/bin
sbindir        := /usr/sbin
libdir         := /usr/lib
libexecdir     := /usr/libexec
hdrdir         := /usr/include/$(INSTALL_HDR)
includedir     := /usr/include
datarootdir    := /usr/share
datadir        := $(datarootdir)
infodir        := $(datadir)/info
localedir      := $(datadir)/locale
mandir         := $(datadir)/man
docdir         := $(datadir)/doc
sysconfdir     := /etc
servicedir     := /srv
sharedstatedir := /com
localstatedir  := /var
runstatedir    := /run

endif # KERNELRELEASE
