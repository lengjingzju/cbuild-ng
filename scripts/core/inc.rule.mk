############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
# https://github.com/lengjingzju/cbuild-ng #
############################################

ifeq ($(KERNELRELEASE), )
COLORECHO       := $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
FETCH_SCRIPT    := $(ENV_TOOL_DIR)/fetch_package.sh
PATCH_SCRIPT    := $(ENV_TOOL_DIR)/exec_patch.sh
CACHE_SCRIPT    := $(ENV_TOOL_DIR)/process_cache.sh
MACHINE_SCRIPT  := $(ENV_TOOL_DIR)/process_machine.sh
SYSROOT_SCRIPT  := $(ENV_TOOL_DIR)/process_sysroot.sh
MESON_SCRIPT    := $(ENV_TOOL_DIR)/meson_cross.sh

ifneq ($(SRC_URL), )
FETCH_METHOD    ?= tar
SRC_URLS        ?= $(SRC_URL)$(if $(SRC_MD5),;md5=$(SRC_MD5))$(if $(SRC_BRANCH),;branch=$(SRC_BRANCH))$(if $(SRC_TAG),;tag=$(SRC_TAG))$(if $(SRC_REV),;rev=$(SRC_REV))
SRC_PATH        ?= $(WORKDIR)/$(SRC_DIR)
else
SRC_PATH        ?= $(shell pwd)
endif

BUILD_JOBS      ?= $(shell echo $(MAKEFLAGS) | grep -E '\-j[0-9]+' | sed -E 's/.*(-j[0-9]+).*/\1/g')
MAKE_FNAME      ?= mk.deps

INS_FULLER      ?= n
INS_HASRUN      ?= n
ifeq ($(INS_FULLER),y)
define ins_common_cfg
--$(1)dir=$(INS_TOPDIR)$(if $(filter $(1),bin sbin lib),$(INS_SUBDIR)$(base_$(1)dir),$($(1)dir))
endef

define ins_cmake_cfg
-DCMAKE_INSTALL_$(shell echo $(1)dir | tr [:lower:] [:upper:])=$(patsubst /%,%,$(if $(filter $(1),bin sbin lib),$(INS_SUBDIR)$(base_$(1)dir),$($(1)dir)))
endef
endif

ifeq ($(COMPILE_TOOL),autotools)
AUTOTOOLS_CROSS ?= $(shell $(MACHINE_SCRIPT) autotools_cross)
ifeq ($(INS_FULLER),y)
INS_CONFIG      ?= --prefix=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include dataroot $(if $(filter y,$(INS_HASRUN)),runstate),$(call ins_common_cfg,$(v)))
else
INS_CONFIG      ?= --prefix=$(INS_TOPDIR)$(INS_SUBDIR)
endif

else ifeq ($(COMPILE_TOOL),cmake)
CMAKE_CROSS     ?= $(shell $(MACHINE_SCRIPT) cmake_cross)
ifeq ($(INS_FULLER),y)
INS_CONFIG      ?= -DCMAKE_INSTALL_PREFIX=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include dataroot $(if $(filter y,$(INS_HASRUN)),runstate),$(call ins_cmake_cfg,$(v)))
else
INS_CONFIG      ?= -DCMAKE_INSTALL_PREFIX=$(INS_TOPDIR)$(INS_SUBDIR)
endif
dep_config      ?=$(shell echo $(wildcard $(DEP_PREFIX) $(DEP_PREFIX)/usr) | sed 's@ @;@g')
DEP_CONFIG      ?=$(if $(dep_config),-DCMAKE_PREFIX_PATH="$(dep_config)")

else ifeq ($(COMPILE_TOOL),meson)
MESON_WRAP_MODE ?= --wrap-mode=nodownload
ifeq ($(INS_FULLER),y)
INS_CONFIG      ?= --prefix=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include data info locale man,$(call ins_common_cfg,$(v)))
else
INS_CONFIG      ?= --prefix=$(INS_TOPDIR)$(INS_SUBDIR) --libdir=$(INS_TOPDIR)$(INS_SUBDIR)/lib
endif

else
INS_CONFIG      ?=
endif

ifeq ($(CACHE_BUILD),y)
CACHE_OUTPATH   ?= $(WORKDIR)
CACHE_INSPATH   ?= $(INS_TOPDIR)
CACHE_STATUS    ?= $(WORKDIR)/MATCH.status
CACHE_GRADE     ?= 2
CACHE_CHECKSUM  += $(wildcard $(shell pwd)/$(MAKE_FNAME))
CACHE_DEPENDS   ?=
ifneq ($(SRC_MD5)$(SRC_TAG)$(SRC_REV), )
CACHE_APPENDS   += $(SRC_MD5)$(SRC_TAG)$(SRC_REV)
CACHE_SRCFILE    =
CACHE_URL        =
else
CACHE_APPENDS   ?=
CACHE_SRCFILE   ?= $(SRC_NAME)
CACHE_URL       ?= $(if $(SRC_URLS),[$(FETCH_METHOD)]$(SRC_URLS))
endif
CACHE_VERBOSE   ?= 1
endif

define do_fetch
	mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock && \
	flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME) $(WORKDIR) $(SRC_DIR)"
endef

define do_patch
	$(PATCH_SCRIPT) patch $(PATCH_FOLDER) $(SRC_PATH)
endef

.PHONY: all build prepend compile append install clean distclean

all: $(if $(filter y,$(CACHE_BUILD)),cachebuild,nocachebuild)

ifeq ($(filter build,$(CUSTOM_TARGETS)), )
build:
	@mkdir -p $(OBJ_PREFIX)
	@$(if $(SRC_URLS),$(call do_fetch))
	@$(if $(PATCH_FOLDER),$(call do_patch))
ifneq ($(filter prepend,$(CUSTOM_TARGETS)), )
	@$(MAKE) -f $(MAKE_FNAME) prepend
endif
ifeq ($(COMPILE_TOOL),autotools)
	@cd $(OBJ_PREFIX) && \
		$(SRC_PATH)/configure $(if $(CROSS_COMPILE),$(AUTOTOOLS_CROSS)) $(INS_CONFIG) $(AUTOTOOLS_FLAGS) $(TOLOG)
else ifeq ($(COMPILE_TOOL),cmake)
	@cd $(OBJ_PREFIX) && rm -f CMakeCache.txt && \
		cmake $(SRC_PATH) $(if $(CROSS_COMPILE),$(CMAKE_CROSS)) $(INS_CONFIG) $(DEP_CONFIG) $(CMAKE_FLAGS) $(TOLOG)
else ifeq ($(COMPILE_TOOL),meson)
	@$(if $(CROSS_COMPILE),$(MESON_SCRIPT) $(OBJ_PREFIX))
	@$(if $(do_meson_cfg),$(call do_meson_cfg))
	@cd $(SRC_PATH) && \
		meson $(if $(CROSS_COMPILE),--cross-file $(OBJ_PREFIX)/cross.ini) $(INS_CONFIG) $(MESON_WRAP_MODE) $(MESON_FLAGS) $(OBJ_PREFIX) $(TOLOG)
endif
	@rm -rf $(INS_TOPDIR)
ifneq ($(filter compile,$(CUSTOM_TARGETS)), )
	@$(MAKE) -f $(MAKE_FNAME) compile
else
ifeq ($(COMPILE_TOOL),autotools)
	@cd $(OBJ_PREFIX) && $(MAKE) $(MAKE_FLAGS) $(TOLOG) && $(MAKE) $(MAKE_FLAGS) install $(TOLOG)
else ifeq ($(COMPILE_TOOL),cmake)
	@cd $(OBJ_PREFIX) && $(MAKE) $(MAKE_FLAGS) $(TOLOG) && $(MAKE) $(MAKE_FLAGS) install $(TOLOG)
else ifeq ($(COMPILE_TOOL),meson)
	@cd $(OBJ_PREFIX) && ninja $(BUILD_JOBS) $(MAKE_FLAGS) $(TOLOG) && ninja $(BUILD_JOBS) $(MAKE_FLAGS) install $(TOLOG)
else
	@$(MAKE) $(MAKE_FLAGS) $(TOLOG) && $(MAKE) $(MAKE_FLAGS) install $(TOLOG)
endif
endif
	@$(call install_lics)
	@$(SYSROOT_SCRIPT) replace $(INS_TOPDIR)
ifneq ($(filter append,$(CUSTOM_TARGETS)), )
	@$(MAKE) -f $(MAKE_FNAME) append
endif
endif

ifeq ($(filter clean,$(CUSTOM_TARGETS)), )
clean:
	@rm -rf $(OBJ_PREFIX)
	@echo "Clean $(PACKAGE_ID) Done."
endif

ifeq ($(filter distclean,$(CUSTOM_TARGETS)), )
distclean:
	@rm -rf $(WORKDIR)
	@echo "Distclean $(PACKAGE_ID) Done."
endif

ifeq ($(filter install,$(CUSTOM_TARGETS)), )
install:
	@$(SYSROOT_SCRIPT) $(INSTALL_OPTION) $(INS_TOPDIR) $(INS_PREFIX)
endif

ifneq ($(LICFILE), )
define release_lics
	$(SYSROOT_SCRIPT) $(INSTALL_OPTION) $(INS_TOPDIR)/usr/share/license $(INS_PREFIX)/usr/share/license
endef
endif

ifeq ($(CACHE_BUILD),y)

define do_checksum
	$(CACHE_SCRIPT) -m check -r $(CACHE_STATUS) -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)') \
		$(if $(CACHE_URL),-u '$(CACHE_URL)')
endef

define do_pushcache
	$(CACHE_SCRIPT) -m push -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)')
endef

define do_pullcache
	$(CACHE_SCRIPT) -m pull -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE)
endef

define do_setforce
	$(CACHE_SCRIPT) -m setforce -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -v $(CACHE_VERBOSE)
endef

define do_set1force
	$(CACHE_SCRIPT) -m set1force -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -v $(CACHE_VERBOSE)
endef

define do_unsetforce
	$(CACHE_SCRIPT) -m unsetforce -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -v $(CACHE_VERBOSE)
endef

.PHONY: checksum psysroot cachebuild setforce set1force unsetforce

checksum:
	@$(call do_checksum)

psysroot:
	@$(if $(wildcard $(CACHE_STATUS)),,$(MAKE) $(PREPARE_SYSROOT))

cachebuild:
ifeq ($(wildcard $(CACHE_STATUS)), )
	@$(MAKE) -f $(MAKE_FNAME) build
	@$(call do_pushcache)
	@$(COLORECHO) "\033[33mUpdate $(PACKAGE_ID) Cache.\033[0m"
else
	@$(call do_pullcache)
	@$(COLORECHO) "\033[33mMatch $(PACKAGE_ID) Cache.\033[0m"
endif
	@rm -f $(CACHE_STATUS)

setforce:
	@$(call do_setforce)
	@$(COLORECHO) "\033[33mSet $(PACKAGE_ID) Force Build.\033[0m"

set1force:
	@$(call do_set1force)
	@$(COLORECHO) "\033[33mSet $(PACKAGE_ID) Force Build Once.\033[0m"

unsetforce:
	@$(call do_unsetforce)
	@$(COLORECHO) "\033[33mUnset $(PACKAGE_ID) Force Build.\033[0m"

else # CACHE_BUILD

.PHONY: nocachebuild psysroot

nocachebuild:
	@$(MAKE) -f $(MAKE_FNAME) build

psysroot:
	@$(MAKE) $(PREPARE_SYSROOT)

endif # CACHE_BUILD

.PHONY: dofetch

dofetch:
ifneq ($(SRC_URLS), )
	@mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock
	@flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME)"
else
	@
endif

%:
	@$(MAKE) $(MAKE_FLAGS) $@

endif
