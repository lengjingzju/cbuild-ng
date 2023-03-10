############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

COLORECHO      ?= $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
LOGOUTPUT      ?= $(if $(filter -s,$(ENV_BUILD_FLAGS)),1>/dev/null)

INSTALL_HDR    ?= $(PACKAGE_NAME)
SEARCH_HDRS    ?= $(PACKAGE_DEPS)
ifneq ($(NATIVE_BUILD), y)
PACKAGE_ID     := $(PACKAGE_NAME)
else
PACKAGE_ID     := $(PACKAGE_NAME)-native
endif

ifneq ($(ENV_BUILD_MODE), yocto)

ifneq ($(NATIVE_BUILD), y)
ENV_CROSS_ROOT ?= .
WORKDIR        ?= $(ENV_CROSS_ROOT)/objects/$(PACKAGE_NAME)
SYS_PREFIX     ?= $(ENV_CROSS_ROOT)/sysroot
ifneq ($(CROSS_DESTDIR), )
INS_PREFIX      = $(CROSS_DESTDIR)
endif
ifneq ($(GLOBAL_SYSROOT), y)
DEP_PREFIX     ?= $(WORKDIR)/sysroot
else
DEP_PREFIX     ?= $(SYS_PREFIX)
endif
else # NATIVE_BUILD
ENV_NATIVE_ROOT?= .
WORKDIR        ?= $(ENV_NATIVE_ROOT)/objects/$(PACKAGE_NAME)
SYS_PREFIX     ?= $(ENV_NATIVE_ROOT)/sysroot
ifneq ($(NATIVE_DESTDIR), )
INS_PREFIX      = $(NATIVE_DESTDIR)
endif
ifneq ($(GLOBAL_SYSROOT), y)
DEP_PREFIX     ?= $(WORKDIR)/sysroot-native
else
DEP_PREFIX     ?= $(SYS_PREFIX)
endif
endif # NATIVE_BUILD

INS_SUBDIR     ?= /usr
INS_TOPDIR     ?= $(WORKDIR)/image
INS_PREFIX     ?= $(WORKDIR)/image
OBJ_PREFIX     ?= $(WORKDIR)/build
ifneq ($(GLOBAL_SYSROOT), y)
PATH_PREFIX    ?= $(WORKDIR)/sysroot-native
else
PATH_PREFIX    ?= $(ENV_NATIVE_ROOT)/sysroot
endif

else # ENV_BUILD_MODE

# WORKDIR should be exported by yocto recipe.
# Yocto doesn't have SYS_PREFIX INS_TOPDIR INS_SUBDIR
ifneq ($(NATIVE_BUILD), y)
INS_PREFIX     ?= $(WORKDIR)/image
DEP_PREFIX     ?= $(WORKDIR)/recipe-sysroot
else # NATIVE_BUILD
INS_PREFIX     ?= $(WORKDIR)/image/$(WORKDIR)/recipe-sysroot-native
DEP_PREFIX     ?= $(WORKDIR)/recipe-sysroot-native
endif # NATIVE_BUILD

OBJ_PREFIX     ?= $(WORKDIR)/build
PATH_PREFIX    ?= $(WORKDIR)/recipe-sysroot-native

endif # ENV_BUILD_MODE

ifneq ($(O), )
OBJ_PREFIX      = $(O)
endif

ifneq ($(DESTDIR), )
INS_PREFIX      = $(DESTDIR)
endif

ifneq ($(DEPDIR), )
DEP_PREFIX      = $(DEPDIR)
endif

define link_hdrs
$(addprefix  -I,$(wildcard \
	$(addprefix $(DEP_PREFIX),/include /usr/include /usr/local/include) \
	$(addprefix $(DEP_PREFIX)/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/local/include/,$(SEARCH_HDRS)) \
))
endef

ifeq ($(KERNELRELEASE), )

comma          :=,
define link_libs
$(addprefix -L,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib))) \
$(addprefix -Wl$(comma)-rpath-link=,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib)))
endef

ifneq ($(filter y,$(NATIVE_DEPEND) $(NATIVE_BUILD)), )
export PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/bin /usr/bin /usr/local/bin /sbin /usr/sbin /usr/local/sbin)$(if $(PATH),:$(PATH)) | sed 's/ /:/g')
export LD_LIBRARY_PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/lib /usr/lib /usr/local/lib)$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH)) | sed 's/ /:/g')
endif

# yocto envs should be exported by yocto recipe.

ifneq ($(ENV_BUILD_MODE), yocto)

define prepare_sysroot
	make -s PRECMD= NATIVE_BUILD= CROSS_DESTDIR=$(WORKDIR)/sysroot NATIVE_DESTDIR=$(WORKDIR)/sysroot-native \
		INSTALL_OPTION=link -C $(ENV_TOP_DIR) $(PACKAGE_ID)_install_depends
endef

export PKG_CONFIG_LIBDIR=$(DEP_PREFIX)/usr/lib/pkgconfig
export PKG_CONFIG_PATH=$(shell echo $(wildcard $(addprefix $(DEP_PREFIX),$(addsuffix /pkgconfig,/lib /usr/lib /usr/local/lib))) | sed 's@ @:@g')

ifneq ($(NATIVE_BUILD), y)

ifneq ($(ENV_BUILD_ARCH), )
ARCH           := $(ENV_BUILD_ARCH)
export ARCH
endif

ifneq ($(ENV_BUILD_TOOL), )
ifneq ($(findstring /,$(ENV_BUILD_TOOL)), )
CROSS_TOOLPATH := $(shell dirname $(ENV_BUILD_TOOL))
CROSS_COMPILE  := $(shell basename $(ENV_BUILD_TOOL))
export PATH:=$(PATH):$(CROSS_TOOLPATH)
else
CROSS_COMPILE  := $(ENV_BUILD_TOOL)
endif
export CROSS_COMPILE
endif

CC             := $(CROSS_COMPILE)gcc
CPP            := $(CROSS_COMPILE)gcc -E
CXX            := $(CROSS_COMPILE)g++
AS             := $(CROSS_COMPILE)as
LD             := $(CROSS_COMPILE)ld
AR             := $(CROSS_COMPILE)ar
RANLIB         := $(CROSS_COMPILE)ranlib
OBJCOPY        := $(CROSS_COMPILE)objcopy
STRIP          := $(CROSS_COMPILE)strip
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

else # NATIVE_BUILD

undefine ARCH CROSS_COMPILE
unexport ARCH CROSS_COMPILE

CC             := gcc
CPP            := gcc -E
CXX            := g++
AS             := as
LD             := ld
AR             := ar
RANLIB         := ranlib
OBJCOPY        := objcopy
STRIP          := strip
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

endif # NATIVE_BUILD
endif # ENV_BUILD_MODE
endif # KERNELRELEASE
