############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

ifeq ($(KERNELRELEASE), )
COLORECHO       ?= $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
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

BUILD_JOBS      ?= $(ENV_BUILD_JOBS)
ifneq ($(COMPILE_TOOL), meson)
MAKES           ?= make $(BUILD_JOBS) $(ENV_BUILD_FLAGS) $(MAKES_FLAGS)
else
MAKES           ?= ninja $(BUILD_JOBS) $(MAKES_FLAGS)
endif

INS_FULLER      ?= n
ifeq ($(INS_FULLER), y)
define ins_common_cfg
--$(1)dir=$(INS_TOPDIR)$(if $(filter $(1),bin sbin lib),$(INS_SUBDIR)$(base_$(1)dir),$($(1)dir))
endef

define ins_cmake_cfg
-DCMAKE_INSTALL_FULL_$(shell echo $(1)dir | tr [:lower:] [:upper:])=$(INS_TOPDIR)$(if $(filter $(1),bin sbin lib),$(INS_SUBDIR)$(base_$(1)dir),$($(1)dir))
endef
endif

ifeq ($(COMPILE_TOOL), autotools)
AUTOTOOLS_CROSS ?= $(shell $(MACHINE_SCRIPT) autotools_cross)
ifeq ($(INS_FULLER), y)
INS_CONFIG      ?= --prefix=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include dataroot runstate,$(call ins_common_cfg,$(v)))
else
INS_CONFIG      ?= --prefix=$(INS_TOPDIR)$(INS_SUBDIR)
endif

else ifeq ($(COMPILE_TOOL), cmake)
CMAKE_CROSS     ?= $(shell $(MACHINE_SCRIPT) cmake_cross)
ifeq ($(INS_FULLER), y)
INS_CONFIG      ?= -DCMAKE_INSTALL_PREFIX=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include dataroot runstate,$(call ins_cmake_cfg,$(v)))
else
INS_CONFIG      ?= -DCMAKE_INSTALL_PREFIX=$(INS_TOPDIR)$(INS_SUBDIR)
endif

else ifeq ($(COMPILE_TOOL), meson)
MESON_WRAP_MODE ?= --wrap-mode=nodownload
ifeq ($(INS_FULLER), y)
INS_CONFIG      ?= --prefix=$(INS_TOPDIR) $(foreach v,bin sbin lib libexec include data info locale man,$(call ins_common_cfg,$(v)))
else
INS_CONFIG      ?= --prefix=$(INS_TOPDIR)$(INS_SUBDIR) --libdir=$(INS_TOPDIR)$(INS_SUBDIR)/lib
endif

else
INS_CONFIG      ?=
endif

ifeq ($(CACHE_BUILD), y)
CACHE_OUTPATH   ?= $(WORKDIR)
CACHE_INSPATH   ?= $(INS_TOPDIR)
CACHE_GRADE     ?= 2
CACHE_CHECKSUM  += $(wildcard $(shell pwd)/mk.deps)
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

ifeq ($(do_compile), )
define do_compile
	set -e; \
	$(if $(SRC_URLS),$(call do_fetch),true); \
	$(if $(PATCH_FOLDER),$(call do_patch),true); \
	mkdir -p $(OBJ_PREFIX); \
	$(if $(do_prepend),$(call do_prepend),true); \
	if [ "$(COMPILE_TOOL)" = "cmake" ]; then \
		cd $(OBJ_PREFIX) && cmake $(SRC_PATH) $(if $(CROSS_COMPILE),$(CMAKE_CROSS)) \
			$(INS_CONFIG) $(CMAKE_FLAGS) $(LOGOUTPUT); \
	elif [ "$(COMPILE_TOOL)" = "autotools" ]; then \
		cd $(OBJ_PREFIX) && $(SRC_PATH)/configure $(if $(CROSS_COMPILE),$(AUTOTOOLS_CROSS)) \
			$(INS_CONFIG) $(AUTOTOOLS_FLAGS) $(LOGOUTPUT); \
	elif [ "$(COMPILE_TOOL)" = "meson" ]; then \
		$(if $(CROSS_COMPILE),$(MESON_SCRIPT) $(OBJ_PREFIX),true); \
		$(if $(do_meson_cfg),$(call do_meson_cfg),true); \
		cd $(SRC_PATH) && meson $(if $(CROSS_COMPILE),--cross-file $(OBJ_PREFIX)/cross.ini) \
			$(INS_CONFIG) $(MESON_WRAP_MODE) $(MESON_FLAGS) $(OBJ_PREFIX) $(LOGOUTPUT); \
		cd $(OBJ_PREFIX); \
	fi; \
	rm -rf $(INS_TOPDIR) && $(MAKES) $(LOGOUTPUT) && $(MAKES) install $(LOGOUTPUT); \
	$(call install_lics); \
	$(SYSROOT_SCRIPT) replace $(INS_TOPDIR); \
	$(if $(do_append),$(call do_append),true); \
	set +e
endef
endif

ifeq ($(do_clean), )
define do_clean
	$(MAKES) clean && rm -rf $(INS_TOPDIR)
endef
endif

ifeq ($(do_distclean), )
define do_distclean
	rm -rf $(WORKDIR)
endef
endif

ifeq ($(do_install), )
define do_install
	$(SYSROOT_SCRIPT) $(INSTALL_OPTION) $(INS_TOPDIR) $(INS_PREFIX)
endef
endif

ifeq ($(CACHE_BUILD), y)

define do_check
	$(CACHE_SCRIPT) -m check -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)') \
		$(if $(CACHE_URL),-u '$(CACHE_URL)')
endef

define do_pull
	$(CACHE_SCRIPT) -m pull  -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) && \
	$(COLORECHO) "\033[33mUse $(PACKAGE_ID) Cache in $(ENV_CACHE_DIR).\033[0m"
endef

define do_push
	$(CACHE_SCRIPT) -m push  -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)') && \
	$(COLORECHO) "\033[33mPush $(PACKAGE_ID) Cache to $(ENV_CACHE_DIR).\033[0m"
endef

define do_setforce
	$(CACHE_SCRIPT) -m setforce -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -v $(CACHE_VERBOSE) && \
	echo "Set $(PACKAGE_ID) Force Build."
endef

define do_set1force
	$(CACHE_SCRIPT) -m set1force -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -v $(CACHE_VERBOSE) && \
	echo "Set $(PACKAGE_ID) Force Build."
endef

define do_unsetforce
	$(CACHE_SCRIPT) -m unsetforce -p $(PACKAGE_NAME) $(if $(filter y,$(NATIVE_BUILD)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -v $(CACHE_VERBOSE) && \
	echo "Unset $(PACKAGE_ID) Force Build."
endef

endif

ifneq ($(USER_DEFINED_TARGET), y)

.PHONY: all install clean distclean

ifeq ($(CACHE_BUILD), y)
all: cachebuild
else
all: nocachebuild
endif

clean:
	@$(call do_clean)
	@echo "Clean $(PACKAGE_ID) Done."

distclean:
	@$(call do_distclean)
	@echo "Distclean $(PACKAGE_ID) Done."

install:
	@$(call do_install)

endif # USER_DEFINED_TARGET

ifeq ($(CACHE_BUILD), y)

.PHONY: cachebuild psysroot setforce set1force unsetforce

cachebuild:
	@checksum=$$($(call do_check)); \
	matchflag=$$(echo "$${checksum}" | grep -wc MATCH); \
	errorflag=$$(echo "$${checksum}" | grep -c ERROR); \
	checkinfo=$$(echo "$${checksum}" | sed '/MATCH/ d'); \
	if [ ! -z "$${checkinfo}" ]; then \
		echo "$${checkinfo}"; \
	fi; \
	if [ $${matchflag} -ne 0 ]; then \
		$(call do_pull); \
	elif [ $${errorflag} -ne 0 ]; then \
		exit 1; \
	else \
		$(call do_compile); \
		$(call do_push); \
	fi
	@echo "Build $(PACKAGE_ID) Done."

psysroot:
	@checksum=$$($(call do_check)); \
	matchflag=$$(echo "$${checksum}" | grep -wc MATCH); \
	checkinfo=$$(echo "$${checksum}" | sed '/MATCH/ d'); \
	if [ ! -z "$${checkinfo}" ]; then \
		echo "$${checkinfo}"; \
	fi; \
	if [ $${matchflag} -eq 0 ]; then \
		$(MAKE) $(PREPARE_SYSROOT); \
	fi

setforce:
	@$(call do_setforce)

set1force:
	@$(call do_set1force)

unsetforce:
	@$(call do_unsetforce)

else

.PHONY: nocachebuild psysroot

nocachebuild:
	@$(call do_compile)
	@echo "Build $(PACKAGE_ID) Done."

psysroot:
	@$(MAKE) $(PREPARE_SYSROOT)

endif

.PHONY: dofetch

dofetch:
ifneq ($(SRC_URLS), )
	@mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock
	@flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME) $(if $(filter -s,$(ENV_BUILD_FLAGS)),,$(WORKDIR) $(SRC_DIR))"
else
	@
endif

%:
	@$(MAKES) $@

endif
