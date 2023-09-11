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

FETCH_SCRIPT    := $(ENV_TOOL_DIR)/fetch_package.sh
PATCH_SCRIPT    := $(ENV_TOOL_DIR)/exec_patch.sh
CACHE_SCRIPT    := $(ENV_TOOL_DIR)/process_cache.sh
MACHINE_SCRIPT  := $(ENV_TOOL_DIR)/process_machine.sh

GMP_VER         ?= 6.3.0
MPFR_VER        ?= 4.2.1
MPC_VER         ?= 1.3.1
ISL_VER         ?= 0.26
LINUX_VER       ?= $(shell $(MACHINE_SCRIPT) linux_version)
BINUTILS_VER    ?= 2.41
GCC_VER         ?= $(shell $(MACHINE_SCRIPT) gcc_version)
GLIBC_VER       ?= 2.38
GDB_VER         ?= 13.2

GMP_URL         := https://ftp.gnu.org/gnu/gmp/gmp-$(GMP_VER).tar.xz
MPFR_URL        := https://ftp.gnu.org/gnu/mpfr/mpfr-$(MPFR_VER).tar.xz
MPC_URL         := https://ftp.gnu.org/gnu/mpc/mpc-$(MPC_VER).tar.gz
ISL_URL         := https://libisl.sourceforge.io/isl-$(ISL_VER).tar.xz
LINUX_URL       := https://cdn.kernel.org/pub/linux/kernel/v$(shell echo $(LINUX_VER) | cut -d '.' -f 1).x/linux-$(LINUX_VER).tar.xz
BINUTILS_URL    := https://ftp.gnu.org/gnu/binutils/binutils-$(BINUTILS_VER).tar.xz
GCC_URL         := https://ftp.gnu.org/gnu/gcc/gcc-$(GCC_VER)/gcc-$(GCC_VER).tar.xz
GLIBC_URL       := https://ftp.gnu.org/gnu/glibc/glibc-$(GLIBC_VER).tar.xz
GDB_URL         := https://ftp.gnu.org/gnu/gdb/gdb-$(GDB_VER).tar.xz

CROSS_TARGET     = $(shell $(MACHINE_SCRIPT) cross_target)
CROSS_DIR        = $(shell $(MACHINE_SCRIPT) toolchain_dir)
LINUX_ARCH       = $(shell $(MACHINE_SCRIPT) linux_arch)

OUT_PATH        ?= $(ENV_NATIVE_ROOT)/toolchain/$(CROSS_DIR)
SRCS_PATH        = $(OUT_PATH)/srcs
OBJS_PATH        = $(OUT_PATH)/objs

CROSS_OUTPATH    = $(shell $(MACHINE_SCRIPT) toolchain_path)
CROSS_SYSROOT    = $(CROSS_OUTPATH)/$(CROSS_DIR)
GLIBC_SYSROOT    = $(CROSS_SYSROOT)/$(CROSS_TARGET)/libc
HOST_SYSROOT     = $(CROSS_SYSROOT)/host

CACHE_APPENDS    = \
	$(CONFIG_ENABLE_LANGUAGES) \
	$(GCC_COMMON_OPTIONS) $(GCC_EXTRA_OPTIONS) \
	$(BINUTILS_COMMON_OPTIONS) $(BINUTILS_EXTRA_OPTIONS) \
	$(GLIBC_COMMON_OPTIONS) $(GLIBC_EXTRA_OPTIONS) \
	$(GDB_COMMON_OPTIONS) $(GDB_EXTRA_OPTIONS)
CACHE_STATUS     = $(CROSS_OUTPATH)/MATCH.status

define do_cache
	$(CACHE_SCRIPT) -m $1 -r $(CACHE_STATUS) -p $(CROSS_DIR) -n -o $(CROSS_OUTPATH) -i $(CROSS_SYSROOT) -g 2 -v 0 -d none \
		-c $(shell pwd)/Makefile -a '$(CACHE_APPENDS)'
endef

.PHONY: all cachebuild clean fetch-all \
	fetch-gmp fetch-mpfr fetch-mpc fetch-isl \
	fetch-linux fetch-binutils fetch-gcc fetch-glibc fetch-gdb \
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
	@$(MAKE) build-binutils-initial
	@$(MAKE) build-gcc-initial
	@$(MAKE) build-linux-headers
	@$(MAKE) build-glibc
	@$(MAKE) build-binutils
	@$(MAKE) build-gcc
	@$(MAKE) build-gdb
	@$(MAKE) install-append
	@$(call do_cache,push)
	@echo "Update $(CROSS_DIR) Cache."
else
	@$(call do_cache,pull)
	@echo "Match $(CROSS_DIR) Cache."
endif
	rm -f $(CACHE_STATUS)
	@echo "Build $(CROSS_DIR) Done."

clean:
	@rm -rf $(CROSS_SYSROOT) $(OUT_PATH)
	@echo "Clean $(CROSS_DIR) Done."

########## Fetch packages ##########

fetch-all: fetch-gmp fetch-mpfr fetch-mpc fetch-isl \
	fetch-linux fetch-binutils fetch-gcc fetch-glibc fetch-gdb

fetch-gmp:
	$(FETCH_SCRIPT) tar "$(GMP_URL)" gmp-$(GMP_VER).tar.xz $(SRCS_PATH) gmp-$(GMP_VER)

fetch-mpfr:
	$(FETCH_SCRIPT) tar "$(MPFR_URL)" mpfr-$(MPFR_VER).tar.xz $(SRCS_PATH) mpfr-$(MPFR_VER)

fetch-mpc:
	$(FETCH_SCRIPT) tar "$(MPC_URL)" mpc-$(MPC_VER).tar.gz $(SRCS_PATH) mpc-$(MPC_VER)
	$(PATCH_SCRIPT) patch patch/mpc $(SRCS_PATH)/mpc-$(MPC_VER)

fetch-isl:
	$(FETCH_SCRIPT) tar "$(ISL_URL)" isl-$(ISL_VER).tar.xz $(SRCS_PATH) isl-$(ISL_VER)

fetch-linux:
	$(FETCH_SCRIPT) tar "$(LINUX_URL)" linux-$(LINUX_VER).tar.xz $(SRCS_PATH) linux-$(LINUX_VER)

fetch-binutils:
	$(FETCH_SCRIPT) tar "$(BINUTILS_URL)" binutils-$(BINUTILS_VER).tar.xz $(SRCS_PATH) binutils-$(BINUTILS_VER)

fetch-gcc:
	$(FETCH_SCRIPT) tar "$(GCC_URL)" gcc-$(GCC_VER).tar.xz $(SRCS_PATH) gcc-$(GCC_VER)
	sed -i 's@print-multi-os-directory@print-multi-directory@g' \
		`find $(SRCS_PATH)/gcc-$(GCC_VER) -name configure -o -name configure.ac -o -name Makefile.in | xargs`

fetch-glibc:
	$(FETCH_SCRIPT) tar "$(GLIBC_URL)" glibc-$(GLIBC_VER).tar.xz $(SRCS_PATH) glibc-$(GLIBC_VER)

fetch-gdb:
	$(FETCH_SCRIPT) tar "$(GDB_URL)" gdb-$(GDB_VER).tar.xz $(SRCS_PATH) gdb-$(GDB_VER)

########## Build dependency libraries ##########

build-gmp:
	mkdir -p $(OBJS_PATH)/gmp && cd $(OBJS_PATH)/gmp; \
		$(SRCS_PATH)/gmp-$(GMP_VER)/configure --prefix=$(HOST_SYSROOT) --disable-shared && \
		$(MAKE) && $(MAKE) install

build-mpfr:
	mkdir -p $(OBJS_PATH)/mpfr && cd $(OBJS_PATH)/mpfr; \
		$(SRCS_PATH)/mpfr-$(MPFR_VER)/configure --prefix=$(HOST_SYSROOT) --disable-shared \
			--with-gmp=$(HOST_SYSROOT) && \
		$(MAKE) && $(MAKE) install

build-mpc:
	mkdir -p $(OBJS_PATH)/mpc && cd $(OBJS_PATH)/mpc; \
		$(SRCS_PATH)/mpc-$(MPC_VER)/configure --prefix=$(HOST_SYSROOT) --disable-shared \
			--with-gmp=$(HOST_SYSROOT) --with-mpfr=$(HOST_SYSROOT) && \
		$(MAKE) && $(MAKE) install

build-isl:
	mkdir -p $(OBJS_PATH)/isl && cd $(OBJS_PATH)/isl; \
		$(SRCS_PATH)/isl-$(ISL_VER)/configure --prefix=$(HOST_SYSROOT) --disable-shared \
			--with-gmp-prefix=$(HOST_SYSROOT) && \
		$(MAKE) && $(MAKE) install

########## Configure toolchain  ##########

TOOLCHAIN_COMMON_OPTIONS = \
	--target=$(CROSS_TARGET) \
	--prefix=$(CROSS_SYSROOT) \
	--with-gmp=$(HOST_SYSROOT) \
	--with-mpfr=$(HOST_SYSROOT) \
	--with-mpc=$(HOST_SYSROOT) \
	--with-isl=$(HOST_SYSROOT)

CONFIG_ENABLE_LANGUAGES ?= c,c++
GCC_COMMON_OPTIONS      += $(shell $(MACHINE_SCRIPT) gcc_arch_option)

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

########## Build binutils / gcc without glibc  ##########

build-binutils-initial:
	mkdir -p $(OBJS_PATH)/binutils-initial && cd $(OBJS_PATH)/binutils-initial; \
		CC_FOR_BUILD=gcc \
		$(SRCS_PATH)/binutils-$(BINUTILS_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			$(BINUTILS_COMMON_OPTIONS) \
			&& \
		$(MAKE) && $(MAKE) install

build-gcc-initial:
	mkdir -p $(OBJS_PATH)/gcc-initial && cd $(OBJS_PATH)/gcc-initial; \
		CC_FOR_BUILD=gcc \
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
			&& \
		$(MAKE) all-gcc all-target-libgcc && $(MAKE) install-gcc install-target-libgcc
	cd $(CROSS_SYSROOT)/lib/gcc/$(CROSS_TARGET)/$(GCC_VER) && rm -f libgcc_eh.a && ln -sf libgcc.a libgcc_eh.a

########## Build glibc  ##########

build-linux-headers:
	$(MAKE) ARCH=$(LINUX_ARCH) INSTALL_HDR_PATH=$(GLIBC_SYSROOT)/usr -C $(SRCS_PATH)/linux-$(LINUX_VER) headers_install

build-glibc:
	mkdir -p $(OBJS_PATH)/glibc && cd $(OBJS_PATH)/glibc; \
		export PATH=$(PATH):$(CROSS_SYSROOT)/bin; \
		BUILD_CC=gcc CC=$(CROSS_TARGET)-gcc AR=$(CROSS_TARGET)-ar RANLIB=$(CROSS_TARGET)-ranlib \
		$(SRCS_PATH)/glibc-$(GLIBC_VER)/configure \
			--host=$(CROSS_TARGET) \
			--prefix=/usr \
			--with-binutils=$(CROSS_SYSROOT)/bin \
			--with-headers=$(GLIBC_SYSROOT)/usr/include \
			--enable-shared \
			libc_cv_slibdir=/lib \
			$(GLIBC_COMMON_OPTIONS) \
			$(GLIBC_EXTRA_OPTIONS) \
			&& \
		$(MAKE) && $(MAKE) install_root=$(GLIBC_SYSROOT) install

########## Build binutils / gcc with glibc and gdb ##########

build-binutils:
	mkdir -p $(OBJS_PATH)/binutils && cd $(OBJS_PATH)/binutils; \
		export PATH=$(PATH):$(CROSS_SYSROOT)/bin; \
		CC_FOR_BUILD=gcc \
		$(SRCS_PATH)/binutils-$(BINUTILS_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			--with-sysroot=$(GLIBC_SYSROOT) \
			--with-build-sysroot=$(GLIBC_SYSROOT) \
			$(BINUTILS_COMMON_OPTIONS) \
			$(BINUTILS_EXTRA_OPTIONS) \
			&& \
		$(MAKE) && $(MAKE) install

build-gcc:
	mkdir -p $(OBJS_PATH)/gcc && cd $(OBJS_PATH)/gcc; \
		export PATH=$(PATH):$(CROSS_SYSROOT)/bin; \
		CC_FOR_BUILD=gcc \
		$(SRCS_PATH)/gcc-$(GCC_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			--with-sysroot=$(GLIBC_SYSROOT) \
			--with-build-sysroot=$(GLIBC_SYSROOT) \
			--with-toolexeclibdir=$(GLIBC_SYSROOT)/lib \
			--enable-languages=$(CONFIG_ENABLE_LANGUAGES) \
			--enable-shared \
			--enable-threads=posix \
			--enable-checking=release \
			$(GCC_COMMON_OPTIONS) \
			$(GCC_EXTRA_OPTIONS) \
			&& \
		$(MAKE) && $(MAKE) install

build-gdb:
	mkdir -p $(OBJS_PATH)/gdb && cd $(OBJS_PATH)/gdb; \
		export PATH=$(PATH):$(CROSS_SYSROOT)/bin; \
		CC_FOR_BUILD=gcc \
		$(SRCS_PATH)/gdb-$(GDB_VER)/configure \
			$(TOOLCHAIN_COMMON_OPTIONS) \
			--with-libgmp-prefix=$(HOST_SYSROOT) \
			$(GDB_COMMON_OPTIONS) \
			$(GDB_EXTRA_OPTIONS) \
			&& \
		$(MAKE) && $(MAKE) install

install-append:
	rm -rf $(HOST_SYSROOT)
	rm -f $(CROSS_SYSROOT)/bin/$(CROSS_TARGET)-c++
	ln -sf $(CROSS_TARGET)-g++ $(CROSS_SYSROOT)/bin/$(CROSS_TARGET)-c++
	rm -f $(CROSS_SYSROOT)/bin/$(CROSS_TARGET)-gcc-$(GCC_VER)
	ln -sf $(CROSS_TARGET)-gcc $(CROSS_SYSROOT)/bin/$(CROSS_TARGET)-gcc-$(GCC_VER)
	rm -f $(CROSS_SYSROOT)/bin/$(CROSS_TARGET)-ld.bfd
	ln -sf $(CROSS_TARGET)-ld $(CROSS_SYSROOT)/bin/$(CROSS_TARGET)-ld.bfd
	rm -f $(CROSS_SYSROOT)/$(CROSS_TARGET)/bin/ld.bfd
	ln -sf ld $(CROSS_SYSROOT)/$(CROSS_TARGET)/bin/ld.bfd

