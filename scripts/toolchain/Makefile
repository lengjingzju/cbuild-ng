############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

ifeq ($(ENV_TOP_DIR), )
$(error Please souce env first.)
endif

########## Required host tools ##########
# binutils: texinfo
# glibc: gawk
#########################################

COLORECHO      := $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
TOLOG          ?= $(if $(filter -s,$(MFLAG)),1>/dev/null)

FETCH_SCRIPT   := $(ENV_TOOL_DIR)/fetch_package.sh
PATCH_SCRIPT   := $(ENV_TOOL_DIR)/exec_patch.sh
CACHE_SCRIPT   := $(ENV_TOOL_DIR)/process_cache.sh
MACHINE_SCRIPT := $(ENV_TOOL_DIR)/process_machine.sh

GMP_VER        ?= 6.3.0
MPFR_VER       ?= 4.2.1
MPC_VER        ?= 1.3.1
ISL_VER        ?= 0.26
BINUTILS_VER   ?= 2.41
GCC_VER        ?= $(shell $(MACHINE_SCRIPT) gcc_version)
GDB_VER        ?= 14.1
ifneq ($(HOST_TOOLCHAIN),y)
LINUX_VER      ?= $(shell $(MACHINE_SCRIPT) linux_version)
GLIBC_VER      ?= 2.38
endif

GMP_URL        := https://ftp.gnu.org/gnu/gmp/gmp-$(GMP_VER).tar.xz
MPFR_URL       := https://ftp.gnu.org/gnu/mpfr/mpfr-$(MPFR_VER).tar.xz
MPC_URL        := https://ftp.gnu.org/gnu/mpc/mpc-$(MPC_VER).tar.gz
ISL_URL        := https://libisl.sourceforge.io/isl-$(ISL_VER).tar.xz
BINUTILS_URL   := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VER).tar.xz
GCC_URL        := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VER)/gcc-$(GCC_VER).tar.xz
GDB_URL        := https://ftp.gnu.org/gnu/gdb/gdb-$(GDB_VER).tar.xz
ifneq ($(HOST_TOOLCHAIN),y)
LINUX_URL      := https://www.kernel.org/pub/linux/kernel/v$(shell echo $(LINUX_VER) | cut -d '.' -f 1).x/linux-$(LINUX_VER).tar.xz
GLIBC_URL      := https://ftp.gnu.org/gnu/glibc/glibc-$(GLIBC_VER).tar.xz
endif

BUILD_TARGET   := $(shell uname -m)-linux-gnu
ifneq ($(HOST_TOOLCHAIN),y)
LINUX_ARCH     := $(shell $(MACHINE_SCRIPT) linux_arch)
DEST_TARGET    := $(shell $(MACHINE_SCRIPT) cross_target)
TOOLCHAIN_DIR  := $(shell $(MACHINE_SCRIPT) toolchain_dir)
else
DEST_TARGET    := $(BUILD_TARGET)
TOOLCHAIN_DIR  := host-toolchain-gcc$(GCC_VER)
endif

TOOLCHAIN_PATH := $(shell $(MACHINE_SCRIPT) toolchain_path)
DEST_SYSROOT   := $(TOOLCHAIN_PATH)/$(TOOLCHAIN_DIR)
LIBS_SYSROOT   := $(DEST_SYSROOT)/host
ifneq ($(HOST_TOOLCHAIN),y)
GLIBC_SYSROOT  := $(DEST_SYSROOT)/$(DEST_TARGET)/libc
endif

OUT_PATH       ?= $(ENV_NATIVE_ROOT)/toolchain/$(TOOLCHAIN_DIR)
SRCS_PATH       = $(OUT_PATH)/srcs
OBJS_PATH       = $(OUT_PATH)/objs

CACHE_APPENDS   = \
	$(CONFIG_ENABLE_LANGUAGES) \
	$(GCC_COMMON_OPTIONS) $(GCC_EXTRA_OPTIONS) \
	$(BINUTILS_COMMON_OPTIONS) $(BINUTILS_EXTRA_OPTIONS) \
	$(GDB_COMMON_OPTIONS) $(GDB_EXTRA_OPTIONS)

ifneq ($(HOST_TOOLCHAIN),y)
CACHE_APPENDS  += linux-$(LINUX_VER) $(GLIBC_COMMON_OPTIONS) $(GLIBC_EXTRA_OPTIONS)
CACHE_STATUS    = $(TOOLCHAIN_PATH)/MATCH-CROSS.status
else
CACHE_STATUS    = $(TOOLCHAIN_PATH)/MATCH-HOST.status
endif

define do_cache
	$(CACHE_SCRIPT) -m $1 -r $(CACHE_STATUS) -p $(TOOLCHAIN_DIR) -v $(GCC_VER) -n \
		-o $(TOOLCHAIN_PATH) -i $(DEST_SYSROOT) -g 2 -V 0 -d none \
		-c $(shell pwd)/Makefile -a '$(CACHE_APPENDS)'
endef

.PHONY: all cachebuild clean fetch-all \
	fetch-gmp fetch-mpfr fetch-mpc fetch-isl \
	fetch-binutils fetch-gcc fetch-gdb \
	fetch-linux fetch-glibc \
	build-gmp build-mpfr build-mpc build-isl \
	build-binutils-initial build-gcc-initial \
	build-linux-headers build-glibc \
	build-binutils build-gcc build-gdb \
	install-append

all:
	@$(call do_cache,check)
	@$(MAKE) cachebuild

cachebuild:
ifeq ($(wildcard $(CACHE_STATUS)), )
	@$(MAKE) fetch-all
	@$(MAKE) build-gmp
	@$(MAKE) build-mpfr
	@$(MAKE) build-mpc
	@$(MAKE) build-isl
ifneq ($(HOST_TOOLCHAIN),y)
	@$(MAKE) build-binutils-initial
	@$(MAKE) build-gcc-initial
	@$(MAKE) build-linux-headers
	@$(MAKE) build-glibc
endif
	@$(MAKE) build-binutils
	@$(MAKE) build-gcc
	@$(MAKE) build-gdb
	@$(MAKE) install-append
	@$(call do_cache,push)
	@echo "Update $(TOOLCHAIN_DIR) Cache."
else
	@$(call do_cache,pull)
	@echo "Match $(TOOLCHAIN_DIR) Cache."
endif
	rm -f $(CACHE_STATUS)
	@echo "Build $(TOOLCHAIN_DIR) Done."

clean:
	@rm -rf $(DEST_SYSROOT) $(OUT_PATH)
	@echo "Clean $(TOOLCHAIN_DIR) Done."

########## Fetch packages ##########

fetch-all: fetch-gmp fetch-mpfr fetch-mpc fetch-isl \
	fetch-binutils fetch-gcc fetch-gdb
ifneq ($(HOST_TOOLCHAIN),y)
fetch-all: fetch-linux fetch-glibc
endif

fetch-gmp:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(GMP_URL)" gmp-$(GMP_VER).tar.xz $(SRCS_PATH) gmp-$(GMP_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

fetch-mpfr:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(MPFR_URL)" mpfr-$(MPFR_VER).tar.xz $(SRCS_PATH) mpfr-$(MPFR_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

fetch-mpc:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(MPC_URL)" mpc-$(MPC_VER).tar.gz $(SRCS_PATH) mpc-$(MPC_VER)
	$(PATCH_SCRIPT) patch patch/mpc $(SRCS_PATH)/mpc-$(MPC_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

fetch-isl:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(ISL_URL)" isl-$(ISL_VER).tar.xz $(SRCS_PATH) isl-$(ISL_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

fetch-binutils:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(BINUTILS_URL)" binutils-$(BINUTILS_VER).tar.xz $(SRCS_PATH) binutils-$(BINUTILS_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

fetch-gcc:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(GCC_URL)" gcc-$(GCC_VER).tar.xz $(SRCS_PATH) gcc-$(GCC_VER)
	sed -i 's@print-multi-os-directory@print-multi-directory@g' \
		`find $(SRCS_PATH)/gcc-$(GCC_VER) -name configure -o -name configure.ac -o -name Makefile.in | xargs`
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

fetch-gdb:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(GDB_URL)" gdb-$(GDB_VER).tar.xz $(SRCS_PATH) gdb-$(GDB_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

ifneq ($(HOST_TOOLCHAIN),y)
fetch-linux:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(LINUX_URL)" linux-$(LINUX_VER).tar.xz $(SRCS_PATH) linux-$(LINUX_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

fetch-glibc:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(FETCH_SCRIPT) tar "$(GLIBC_URL)" glibc-$(GLIBC_VER).tar.xz $(SRCS_PATH) glibc-$(GLIBC_VER)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"
endif

########## Build dependency libraries ##########

build-gmp:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/gmp && cd $(OBJS_PATH)/gmp; \
		$(SRCS_PATH)/gmp-$(GMP_VER)/configure --prefix=$(LIBS_SYSROOT) --disable-shared $(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

build-mpfr:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/mpfr && cd $(OBJS_PATH)/mpfr; \
		$(SRCS_PATH)/mpfr-$(MPFR_VER)/configure --prefix=$(LIBS_SYSROOT) --disable-shared \
			--with-gmp=$(LIBS_SYSROOT) $(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

build-mpc:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/mpc && cd $(OBJS_PATH)/mpc; \
		$(SRCS_PATH)/mpc-$(MPC_VER)/configure --prefix=$(LIBS_SYSROOT) --disable-shared \
			--with-gmp=$(LIBS_SYSROOT) --with-mpfr=$(LIBS_SYSROOT) $(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

build-isl:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/isl && cd $(OBJS_PATH)/isl; \
		$(SRCS_PATH)/isl-$(ISL_VER)/configure --prefix=$(LIBS_SYSROOT) --disable-shared \
			--with-gmp-prefix=$(LIBS_SYSROOT) $(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

########## Configure toolchain ##########

CONFIG_ENABLE_LANGUAGES ?= c,c++

TOOLCHAIN_COMMON_OPTIONS = \
	--build=$(BUILD_TARGET) \
	--host=$(BUILD_TARGET) \
	--target=$(DEST_TARGET) \

TOOLCHAIN_COMMON_OPTIONS+= \
	--prefix=$(DEST_SYSROOT) \
	--with-gmp=$(LIBS_SYSROOT) \
	--with-mpfr=$(LIBS_SYSROOT) \
	--with-mpc=$(LIBS_SYSROOT) \
	--with-isl=$(LIBS_SYSROOT)

ifneq ($(HOST_TOOLCHAIN),y)
GCC_COMMON_OPTIONS      += $(shell $(MACHINE_SCRIPT) gcc_arch_option)
endif

CONFIG_ENABLE_BOOTSTRAP ?= n
ifeq ($(CONFIG_ENABLE_BOOTSTRAP), y)
BINUTILS_COMMON_OPTIONS += --enable-bootstrap
GCC_COMMON_OPTIONS      += --enable-bootstrap
GDB_COMMON_OPTIONS      += --enable-bootstrap
else
BINUTILS_COMMON_OPTIONS += --disable-bootstrap
GCC_COMMON_OPTIONS      += --disable-bootstrap
GDB_COMMON_OPTIONS      += --disable-bootstrap
endif

CONFIG_ENABLE_MULTILIB ?= n
ifeq ($(CONFIG_ENABLE_MULTILIB), y)
BINUTILS_COMMON_OPTIONS += --enable-multilib
GCC_COMMON_OPTIONS      += --enable-multilib
GDB_COMMON_OPTIONS      += --enable-multilib
else
BINUTILS_COMMON_OPTIONS += --disable-multilib
GCC_COMMON_OPTIONS      += --disable-multilib
GDB_COMMON_OPTIONS      += --disable-multilib
endif

CONFIG_ENABLE_MULTIARCH ?= y
ifeq ($(CONFIG_ENABLE_MULTIARCH), y)
GCC_COMMON_OPTIONS      += --enable-multiarch
GLIBC_COMMON_OPTIONS    += --enable-multi-arch
GDB_COMMON_OPTIONS      += gl_cv_c_multiarch=yes
else
GCC_COMMON_OPTIONS      += --disable-multiarch
GLIBC_COMMON_OPTIONS    += --disable-multi-arch
GDB_COMMON_OPTIONS      += gl_cv_c_multiarch=no
endif

GLIBC_COMMON_OPTIONS    += --enable-crypt # from glibc 2.38

ifneq ($(HOST_TOOLCHAIN),y)
BINUTILS_SYSROOT_OPTIONS = --with-sysroot=$(GLIBC_SYSROOT) \
	--with-build-sysroot=$(GLIBC_SYSROOT)
GCC_SYSROOT_OPTIONS      = --with-sysroot=$(GLIBC_SYSROOT) \
	--with-build-sysroot=$(GLIBC_SYSROOT) \
	--with-toolexeclibdir=$(GLIBC_SYSROOT)/lib
else
BINUTILS_SYSROOT_OPTIONS =
GCC_SYSROOT_OPTIONS      =
endif

GCC_EXTRA_OPTIONS       ?= \
	--enable-nls \
	--without-included-gettext \
	--enable-clocale=gnu \
	--enable-lto \
	--enable-linker-build-id \
	--enable-gnu-unique-object \
	--enable-libstdcxx-debug \
	--enable-libstdcxx-time=yes

GDB_EXTRA_OPTIONS       ?= \
	--enable-lto \

########## Build binutils / gcc without glibc ##########

ifneq ($(HOST_TOOLCHAIN),y)
build-binutils-initial:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/binutils-initial && cd $(OBJS_PATH)/binutils-initial; \
		$(SRCS_PATH)/binutils-$(BINUTILS_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			$(BINUTILS_COMMON_OPTIONS) \
			$(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

build-gcc-initial:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/gcc-initial && cd $(OBJS_PATH)/gcc-initial; \
		$(SRCS_PATH)/gcc-$(GCC_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			--enable-languages=c,c++ \
			--with-newlib \
			--without-headers \
			--disable-shared \
			--disable-threads \
			--disable-nls \
			--disable-libatomic \
			$(GCC_COMMON_OPTIONS) \
			$(TOLOG) && \
		$(MAKE) all-gcc all-target-libgcc $(TOLOG) && $(MAKE) install-gcc install-target-libgcc $(TOLOG)
	cd $(DEST_SYSROOT)/lib/gcc/$(DEST_TARGET)/$(GCC_VER) && rm -f libgcc_eh.a && ln -sf libgcc.a libgcc_eh.a
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"
endif

########## Build glibc ##########

ifneq ($(HOST_TOOLCHAIN),y)
build-linux-headers:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	$(MAKE) ARCH=$(LINUX_ARCH) INSTALL_HDR_PATH=$(GLIBC_SYSROOT)/usr -C $(SRCS_PATH)/linux-$(LINUX_VER) headers_install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

build-glibc:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/glibc && cd $(OBJS_PATH)/glibc; \
		export PATH=$(DEST_SYSROOT)/bin:$(PATH); \
		$(SRCS_PATH)/glibc-$(GLIBC_VER)/configure \
			--build=$(BUILD_TARGET) \
			--host=$(DEST_TARGET) \
			--target=$(DEST_TARGET) \
			--prefix=/usr \
			--with-binutils=$(DEST_SYSROOT)/bin \
			--with-headers=$(GLIBC_SYSROOT)/usr/include \
			--enable-shared \
			libc_cv_slibdir=/lib \
			$(GLIBC_COMMON_OPTIONS) \
			$(GLIBC_EXTRA_OPTIONS) \
			$(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install_root=$(GLIBC_SYSROOT) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"
endif

########## Build binutils / gcc / gdb ##########

build-binutils:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/binutils && cd $(OBJS_PATH)/binutils; \
		export PATH=$(DEST_SYSROOT)/bin:$(PATH); \
		$(SRCS_PATH)/binutils-$(BINUTILS_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			$(BINUTILS_SYSROOT_OPTIONS) \
			$(BINUTILS_COMMON_OPTIONS) \
			$(BINUTILS_EXTRA_OPTIONS) \
			$(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

build-gcc:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/gcc && cd $(OBJS_PATH)/gcc; \
		export PATH=$(DEST_SYSROOT)/bin:$(PATH); \
		$(SRCS_PATH)/gcc-$(GCC_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			$(GCC_SYSROOT_OPTIONS) \
			--enable-languages=$(CONFIG_ENABLE_LANGUAGES) \
			--enable-shared \
			--enable-threads=posix \
			--enable-checking=release \
			$(GCC_COMMON_OPTIONS) \
			$(GCC_EXTRA_OPTIONS) \
			$(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

build-gdb:
	@$(COLORECHO) "\033[034m++++++++++ $@ ... ++++++++++\033[0m"
	mkdir -p $(OBJS_PATH)/gdb && cd $(OBJS_PATH)/gdb; \
		export PATH=$(DEST_SYSROOT)/bin:$(PATH); \
		$(SRCS_PATH)/gdb-$(GDB_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			--with-libgmp-prefix=$(LIBS_SYSROOT) \
			$(GDB_COMMON_OPTIONS) \
			$(GDB_EXTRA_OPTIONS) \
			$(TOLOG) && \
		$(MAKE) $(TOLOG) && $(MAKE) install $(TOLOG)
	@$(COLORECHO) "\033[032m++++++++++ $@ done. ++++++++++\033[0m"

########## Remove same files  ##########

define link_bin
rm -f $(DEST_SYSROOT)/bin/$(1) && ln -sf $(2) $(DEST_SYSROOT)/bin/$(1)
endef

define link_tbin
rm -f $(DEST_SYSROOT)/$(DEST_TARGET)/bin/$(1) && ln -sf $(2) $(DEST_SYSROOT)/$(DEST_TARGET)/bin/$(1)
endef

install-append:
	rm -rf $(LIBS_SYSROOT)
ifneq ($(HOST_TOOLCHAIN),y)
	$(call link_bin,$(DEST_TARGET)-c++,$(DEST_TARGET)-g++)
	$(call link_bin,$(DEST_TARGET)-gcc-$(GCC_VER),$(DEST_TARGET)-gcc)
	$(call link_bin,$(DEST_TARGET)-ld.bfd,$(DEST_TARGET)-ld)
	$(call link_tbin,ld.bfd,ld)
else
	$(call link_bin,c++,g++)
	$(call link_bin,$(DEST_TARGET)-g++,g++)
	$(call link_bin,$(DEST_TARGET)-c++,g++)
	$(call link_bin,$(DEST_TARGET)-gcc,gcc)
	$(call link_bin,$(DEST_TARGET)-gcc-$(GCC_VER),gcc)
	$(call link_bin,$(DEST_TARGET)-gcc-ar,gcc-ar)
	$(call link_bin,$(DEST_TARGET)-gcc-nm,gcc-nm)
	$(call link_bin,$(DEST_TARGET)-gcc-ranlib,gcc-ranlib)
	$(call link_bin,ld.bfd,ld)
	$(call link_tbin,ld.bfd,ld)
endif

