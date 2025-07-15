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
ifneq ($(filter $(FETCH_METHOD),git svn), )
SRC_SHARED      ?= y
else
SRC_SHARED      := n
endif
SRC_URLS        ?= $(SRC_URL)$(if $(SRC_MD5),;md5=$(SRC_MD5))$(if $(SRC_BRANCH),;branch=$(SRC_BRANCH))$(if $(SRC_TAG),;tag=$(SRC_TAG))$(if $(SRC_REV),;rev=$(SRC_REV))
ifneq ($(SRC_SHARED),y)
SRC_PATH        ?= $(WORKDIR)/$(SRC_DIR)
else
SRC_PATH        ?= $(ENV_DOWN_DIR)/$(SRC_DIR)
endif
PATCH_FOLDER    ?= $(if $(wildcard $(shell pwd)/patch/*.patch),$(shell pwd)/patch)
else
SRC_PATH        ?= $(shell pwd)
endif

BUILD_DEVF      ?= $(WORKDIR)/$(PACKAGE_NAME)-dev
BUILD_MARK      ?= $(PACKAGE_NAME)-$(VERSION)-mark
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

ifeq ($(CC_TOOL),clang)
CFLAGS          += $(clang_cpflags)
CPPFLAGS        += $(clang_cpflags)
CXXFLAGS        += $(clang_cpflags)
LDFLAGS         += $(clang_ldflags)
endif

ifeq ($(COMPILE_TOOL),autotools)
AUTOTOOLS_CROSS ?= $(shell $(MACHINE_SCRIPT) autotools_cross)
ifeq ($(INS_FULLER),y)
INS_CONFIG      ?= --prefix=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include dataroot $(if $(filter y,$(INS_HASRUN)),runstate),$(call ins_common_cfg,$(v)))
else
INS_CONFIG      ?= --prefix=$(INS_TOPDIR)$(INS_SUBDIR)
endif

rel_cpflags     += $(OPTIMIZER_FLAG)
ifneq ($(ENV_BUILD_TYPE),debug)
rel_cpflags     += -ffunction-sections -fdata-sections
rel_ldflags     += -Wl,--gc-sections
else
rel_ldflags     += -Wl,-O1
endif
REL_CONFIG      ?= CFLAGS="$(rel_cpflags) $(CFLAGS)" \
                   CPPFLAGS="$(rel_cpflags) $(CPPFLAGS)" \
                   CXXFLAGS="$(rel_cpflags) $(CXXFLAGS)" \
                   LDFLAGS="$(rel_ldflags) $(LDFLAGS)"

else ifeq ($(COMPILE_TOOL),cmake)
CMAKE_CROSS     ?= $(shell $(MACHINE_SCRIPT) cmake_cross)
ifeq ($(INS_FULLER),y)
INS_CONFIG      ?= -DCMAKE_INSTALL_PREFIX=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include dataroot $(if $(filter y,$(INS_HASRUN)),runstate),$(call ins_cmake_cfg,$(v)))
else
INS_CONFIG      ?= -DCMAKE_INSTALL_PREFIX=$(INS_TOPDIR)$(INS_SUBDIR)
endif
dep_config      ?=$(shell echo $(wildcard $(DEP_PREFIX) $(DEP_PREFIX)/usr) | sed 's@ @;@g')
DEP_CONFIG      ?=$(if $(dep_config),-DCMAKE_PREFIX_PATH="$(dep_config)")

ifeq ($(ENV_BUILD_TYPE),debug)
REL_CONFIG      ?= -DCMAKE_BUILD_TYPE=Debug -DCMAKE_VERBOSE_MAKEFILE=ON --debug-output --trace --trace-expand
else ifeq ($(ENV_BUILD_TYPE),release)
REL_CONFIG      ?= -DCMAKE_BUILD_TYPE=Release
else ifeq ($(ENV_BUILD_TYPE),minsize)
REL_CONFIG      ?= -DCMAKE_BUILD_TYPE=MinSizeRel
else
REL_CONFIG      ?= -DCMAKE_BUILD_TYPE=RelWithDebInfo
endif

ifneq ($(CFLAGS), )
REL_CONFIG      += -DCMAKE_C_FLAGS="$(CFLAGS)"
endif
ifneq ($(CXXFLAGS), )
REL_CONFIG      += -DCMAKE_CXX_FLAGS="$(CXXFLAGS)"
endif
ifneq ($(LDFLAGS), )
REL_CONFIG      += -DCMAKE_SHARED_LINKER_FLAGS="$(LDFLAGS)" -DCMAKE_EXE_LINKER_FLAGS="$(LDFLAGS)"
endif

ifeq ($(CMAKE_NINJA),y)
REL_CONFIG      += -G 'Ninja'
endif

else ifeq ($(COMPILE_TOOL),meson)
MESON_WRAP_MODE ?= --wrap-mode=nodownload
ifeq ($(INS_FULLER),y)
INS_CONFIG      ?= --prefix=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include data info locale man,$(call ins_common_cfg,$(v)))
else
INS_CONFIG      ?= --prefix=$(INS_TOPDIR)$(INS_SUBDIR) --libdir=$(INS_TOPDIR)$(INS_SUBDIR)/lib
endif

ifeq ($(ENV_BUILD_TYPE),debug)
REL_CONFIG      ?= -Dbuildtype=debug --debug
else ifeq ($(ENV_BUILD_TYPE),release)
REL_CONFIG      ?= -Dbuildtype=release
else ifeq ($(ENV_BUILD_TYPE),minsize)
REL_CONFIG      ?= -Dbuildtype=minsize
else
REL_CONFIG      ?= -Dbuildtype=debugoptimized
endif

ifneq ($(CFLAGS), )
REL_CONFIG      += -Dc_args="$(CFLAGS)"
endif
ifneq ($(CXXFLAGS), )
REL_CONFIG      += -Dcpp_args="$(CXXFLAGS)"
endif
ifneq ($(LDFLAGS), )
REL_CONFIG      += -Dc_link_args="$(LDFLAGS)" -Dcpp_link_args="$(LDFLAGS)"
endif

else
INS_CONFIG      ?=
endif

ifeq ($(CACHE_BUILD),y)
CACHE_OUTPATH   ?= $(WORKDIR)
CACHE_INSPATH   ?= $(INS_TOPDIR)
CACHE_STATUS    ?= $(WORKDIR)/MATCH.status
CACHE_GRADE     ?= 2
CACHE_CHECKSUM  += $(wildcard $(shell pwd)/$(MAKE_FNAME)) $(if $(PATCH_FOLDER),$(PATCH_FOLDER))

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

ifneq ($(SRC_SHARED),y)
define do_fetch
	if [ -e $(BUILD_DEVF) ]; then \
		$(COLORECHO) "\033[33mWARNING: Develop Build $(PACKAGE_NAME).\033[0m" >&2; \
	fi; \
	if [ ! -e $(BUILD_DEVF) ] || [ ! -e $(WORKDIR)/$(SRC_DIR) ]; then \
		mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock && \
		flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME) $(WORKDIR) $(SRC_DIR)"; \
	fi
endef
else
define do_fetch
	if [ -e $(BUILD_DEVF) ]; then \
		$(COLORECHO) "\033[33mWARNING: Develop Build $(PACKAGE_NAME).\033[0m" >&2; \
	fi; \
	if [ ! -e $(BUILD_DEVF) ] || [ ! -e $(ENV_DOWN_DIR)/$(SRC_DIR) ]; then \
		mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock && \
		flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME)"; \
	fi
endef
endif

define do_patch
	$(PATCH_SCRIPT) patch $(PATCH_FOLDER) $(SRC_PATH)
endef

.PHONY: all build prepend compile append install clean distclean

all: $(if $(filter y,$(CACHE_BUILD)),cachebuild,nocachebuild)

ifeq ($(filter build,$(CUSTOM_TARGETS)), )
build:
	$(PREAT)if [ "$(OBJ_DISRM)" != "y" ] && [ ! -e $(OBJ_PREFIX)/$(BUILD_MARK) ]; then \
		rm -rf $(OBJ_PREFIX); \
		if [ "$(findstring $(OBJ_PREFIX),$(SRC_PATH))" = "" ]; then \
			mkdir -p $(OBJ_PREFIX); \
		fi; \
	else \
		rm -f $(OBJ_PREFIX)/$(BUILD_MARK); \
	fi
	$(PREAT)$(if $(SRC_URLS),$(call do_fetch))
	$(PREAT)$(if $(PATCH_FOLDER),$(call do_patch))
ifneq ($(filter prepend,$(CUSTOM_TARGETS)), )
	$(PREAT)$(MAKE) -f $(MAKE_FNAME) prepend
endif
ifeq ($(COMPILE_TOOL),autotools)
	$(PREAT)cd $(OBJ_PREFIX) && \
		$(SRC_PATH)/configure $(if $(CROSS_COMPILE),$(AUTOTOOLS_CROSS)) $(INS_CONFIG) $(AUTOTOOLS_FLAGS) $(FT_CONFIG) $(REL_CONFIG) $(TOLOG)
else ifeq ($(COMPILE_TOOL),cmake)
	$(PREAT)cd $(OBJ_PREFIX) && \
		cmake $(SRC_PATH) $(if $(CROSS_COMPILE),$(CMAKE_CROSS)) $(INS_CONFIG) $(DEP_CONFIG) $(CMAKE_FLAGS) $(FT_CONFIG) $(REL_CONFIG) $(TOLOG)
else ifeq ($(COMPILE_TOOL),meson)
	$(PREAT)$(if $(CROSS_COMPILE),$(MESON_SCRIPT) $(OBJ_PREFIX) $(CC_TOOL))
	$(PREAT)$(if $(do_meson_cfg),$(call do_meson_cfg))
	$(PREAT)cd $(SRC_PATH) && \
		meson $(if $(CROSS_COMPILE),--cross-file $(OBJ_PREFIX)/cross.ini) $(INS_CONFIG) $(MESON_WRAP_MODE) $(MESON_FLAGS) $(FT_CONFIG) $(OBJ_PREFIX) $(REL_CONFIG) $(TOLOG)
endif
	$(PREAT)rm -rf $(INS_TOPDIR)
ifneq ($(filter compile,$(CUSTOM_TARGETS)), )
	$(PREAT)$(MAKE) -f $(MAKE_FNAME) compile
else
ifeq ($(COMPILE_TOOL),autotools)
	$(PREAT)cd $(OBJ_PREFIX) && $(MAKE) $(MAKE_FLAGS) $(TOLOG) && $(MAKE) $(MAKE_FLAGS) install $(TOLOG)
else ifeq ($(COMPILE_TOOL),cmake)
ifneq ($(CMAKE_NINJA),y)
	$(PREAT)cd $(OBJ_PREFIX) && $(MAKE) $(MAKE_FLAGS) $(TOLOG) && $(MAKE) $(MAKE_FLAGS) install $(TOLOG)
else
	$(PREAT)cd $(OBJ_PREFIX) && ninja $(BUILD_JOBS) $(MAKE_FLAGS) $(TOLOG) && ninja $(BUILD_JOBS) $(MAKE_FLAGS) install $(TOLOG)
endif
else ifeq ($(COMPILE_TOOL),meson)
	$(PREAT)cd $(OBJ_PREFIX) && ninja $(BUILD_JOBS) $(MAKE_FLAGS) $(TOLOG) && ninja $(BUILD_JOBS) $(MAKE_FLAGS) install $(TOLOG)
else
	$(PREAT)$(MAKE) $(MAKE_FLAGS) $(TOLOG) && $(MAKE) $(MAKE_FLAGS) install $(TOLOG)
endif
endif
	$(PREAT)$(call install_lics)
	$(PREAT)$(SYSROOT_SCRIPT) replace $(INS_TOPDIR)
ifneq ($(filter append,$(CUSTOM_TARGETS)), )
	$(PREAT)$(MAKE) -f $(MAKE_FNAME) append
endif
	$(PREAT)echo > $(OBJ_PREFIX)/$(BUILD_MARK)
endif

ifeq ($(filter clean,$(CUSTOM_TARGETS)), )
clean:
	$(PREAT)rm -rf $(OBJ_PREFIX)
	$(PREAT)echo "Clean $(PACKAGE_ID) Done."
endif

ifeq ($(filter distclean,$(CUSTOM_TARGETS)), )
distclean:
	$(PREAT)rm -rf $(WORKDIR)
	$(PREAT)echo "Distclean $(PACKAGE_ID) Done."
endif

ifeq ($(filter install,$(CUSTOM_TARGETS)), )
install:
	$(PREAT)$(SYSROOT_SCRIPT) $(INSTALL_OPTION) $(INS_TOPDIR) $(INS_PREFIX)
endif

ifneq ($(LICFILE), )
define release_lics
	$(SYSROOT_SCRIPT) $(INSTALL_OPTION) $(INS_TOPDIR)/usr/share/license $(INS_PREFIX)/usr/share/license
endef
endif

ifeq ($(CACHE_BUILD),y)

define do_checksum
	$(CACHE_SCRIPT) -m check -p $(PACKAGE_NAME) $(if $(VERSION),-v $(VERSION)) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -V $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)') \
		$(if $(CACHE_URL),-u '$(CACHE_URL)') -r $(CACHE_STATUS)
endef

define do_pushcache
	$(CACHE_SCRIPT) -m push -p $(PACKAGE_NAME) $(if $(VERSION),-v $(VERSION)) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -V $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)')
endef

define do_pullcache
	$(CACHE_SCRIPT) -m pull -p $(PACKAGE_NAME) $(if $(VERSION),-v $(VERSION)) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -V $(CACHE_VERBOSE)
endef

define do_setforce
	$(CACHE_SCRIPT) -m setforce -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -V $(CACHE_VERBOSE)
endef

define do_set1force
	$(CACHE_SCRIPT) -m set1force -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -V $(CACHE_VERBOSE)
endef

define do_unsetforce
	$(CACHE_SCRIPT) -m unsetforce -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -V $(CACHE_VERBOSE)
endef

.PHONY: checksum psysroot cachebuild setforce set1force unsetforce

checksum:
	$(PREAT)$(call do_checksum)

psysroot:
	$(PREAT)$(if $(wildcard $(CACHE_STATUS)),,$(MAKE) $(PREPARE_SYSROOT))

cachebuild:
ifeq ($(wildcard $(CACHE_STATUS)), )
	$(PREAT)$(MAKE) -f $(MAKE_FNAME) build
	$(PREAT)$(call do_pushcache)
	$(PREAT)$(COLORECHO) "\033[33mUpdate $(PACKAGE_ID) Cache.\033[0m"
else
	$(PREAT)$(call do_pullcache)
	$(PREAT)$(COLORECHO) "\033[33mMatch $(PACKAGE_ID) Cache.\033[0m"
endif
	$(PREAT)rm -f $(CACHE_STATUS)

setforce:
	$(PREAT)$(call do_setforce)
	$(PREAT)$(COLORECHO) "\033[33mSet $(PACKAGE_ID) Force Build.\033[0m"

set1force:
	$(PREAT)$(call do_set1force)
	$(PREAT)$(COLORECHO) "\033[33mSet $(PACKAGE_ID) Force Build Once.\033[0m"

unsetforce:
	$(PREAT)$(call do_unsetforce)
	$(PREAT)$(COLORECHO) "\033[33mUnset $(PACKAGE_ID) Force Build.\033[0m"

else # CACHE_BUILD

.PHONY: nocachebuild psysroot

nocachebuild:
	$(PREAT)$(MAKE) -f $(MAKE_FNAME) build

psysroot:
	$(PREAT)$(MAKE) $(PREPARE_SYSROOT)

endif # CACHE_BUILD

.PHONY: setdev unsetdev dofetch

setdev:
	$(PREAT)mkdir -p $(shell dirname $(BUILD_DEVF))
	$(PREAT)echo > $(BUILD_DEVF)
ifeq ($(CACHE_BUILD),y)
	$(PREAT)$(call do_setforce)
endif
	$(PREAT)$(COLORECHO) "\033[33mSet $(PACKAGE_ID) Development Mode.\033[0m"

unsetdev:
	$(PREAT)rm -f $(BUILD_DEVF)
ifeq ($(CACHE_BUILD),y)
	$(PREAT)$(call do_unsetforce)
endif
	$(PREAT)$(COLORECHO) "\033[33mUnset $(PACKAGE_ID) Development Mode.\033[0m"

dofetch:
ifneq ($(SRC_URLS), )
	$(PREAT)mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock
	$(PREAT)flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME)"
else
	@
endif

ifneq ($(SRC_URLS), )
status:
	$(PREAT)status=""; \
		if [ -e $(BUILD_DEVF) ]; then \
			status=" dev"; \
		fi; \
		if [ -e $(CACHE_OUTPATH)/$(PACKAGE_NAME)-force ]; then \
			status="$${status} force"; \
		fi; \
		if [ ! -z "$${status}" ]; then \
			$(COLORECHO) "\033[31mSTATUS ($(PACKAGE_ID)):$${status}\033[0m"; \
		fi
ifeq ($(FETCH_METHOD),git)
	$(PREAT)srcpath=""; \
		if [ "$(SRC_SHARED)" != "y" ]; then \
			srcpath=$(WORKDIR)/$(SRC_DIR); \
		else \
			srcpath=$(ENV_DOWN_DIR)/$(SRC_DIR); \
		fi; \
		if [ -e $${srcpath} ]; then \
			cd $${srcpath}; \
			info1=$$(echo $${srcpath} | sed "s:$(ENV_TOP_DIR)/::g"); \
			info2=$$(git symbolic-ref -q --short HEAD); \
			info3=$$(git log -1 --pretty='format:%h: %s (%cs) (%an)'); \
			$(COLORECHO) "\033[32m$(PACKAGE_ID): \033[33m$${info1} \033[34m$${info2} \033[35m$${info3}\033[0m"; \
			git status -s; \
		fi
endif
endif

%:
	$(PREAT)$(MAKE) $(MAKE_FLAGS) $@

endif
