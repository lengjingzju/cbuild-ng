############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
# https://github.com/lengjingzju/cbuild-ng #
############################################

ifeq ($(KERNELRELEASE), )

CONF_WORKDIR     ?= $(ENV_NATIVE_ROOT)/objects/kconfig
CONF_SRC         ?= $(ENV_MAKE_DIR)/../kconfig
CONF_PATH        ?= $(CONF_WORKDIR)/image/usr/bin
CONF_OUT         ?= $(if $(OBJ_PREFIX),$(OBJ_PREFIX),.)
KCONFIG          ?= Kconfig
CONF_SAVE_PATH   ?= config
CONF_PREFIX      ?= srctree=$(shell pwd)
CONF_HEADER      ?= $(shell echo __$(PACKAGE_NAME)_CONFIG_H__ | tr '[:lower:]' '[:upper:]')
CONF_APPEND_CMD  ?=

CONFIG_PATH       = $(CONF_OUT)/.config
AUTOCONFIG_PATH   = $(CONF_OUT)/autoconfig/auto.conf
AUTOHEADER_PATH   = $(CONF_OUT)/config.h
CONF_OPTIONS      = $(KCONFIG) --configpath $(CONFIG_PATH) \
					--autoconfigpath $(AUTOCONFIG_PATH) \
					--autoheaderpath $(AUTOHEADER_PATH)

define gen_config_header
	$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --silent --syncconfig && \
		sed -i -e "1 i #ifndef $(CONF_HEADER)" -e "1 i #define $(CONF_HEADER)" -e '1 i \\' \
		-e '$$ a \\' -e "\$$ a #endif" $(AUTOHEADER_PATH) && \
		$(if $(CONF_APPEND_CMD),$(CONF_APPEND_CMD),:)
endef

define sync_config_header
	if [ -e $(CONFIG_PATH) ]; then \
		if [ -e $(AUTOHEADER_PATH) ]; then \
			if [ $$(stat -c %Y $(CONFIG_PATH)) -gt $$(stat -c %Y $(AUTOHEADER_PATH)) ]; then \
				$(call gen_config_header); \
			fi; \
		else \
			$(call gen_config_header); \
		fi; \
	fi
endef

ifneq ($(DEF_CONFIG), )
config_hash_file  = $(CONFIG_PATH)-md5-$(shell md5sum $(CONF_SAVE_PATH)/$(DEF_CONFIG) | cut -d ' ' -f 1)
define process_config_hash
	rm -f $(CONFIG_PATH)-md5-* && echo > $(config_hash_file)
endef
else
define process_config_hash
	rm -f $(CONFIG_PATH)-md5-*
endef
endif

define load_specific_config
	mkdir -p $(CONF_OUT); \
	cp -f $1 $(CONFIG_PATH); \
	$(call process_config_hash); \
	$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --silent --defconfig $1; \
	$(call gen_config_header); \
	echo Load $1 to $(CONFIG_PATH)
endef

.PHONY: buildkconfig cleankconfig menuconfig loadconfig defconfig cleanconfig

ifneq ($(ENV_BUILD_MODE),yocto)

CONF_MAKES       ?= -s O=$(CONF_WORKDIR)/build DESTDIR=$(CONF_WORKDIR)/image -C $(CONF_SRC)

buildkconfig:
ifeq ($(wildcard $(CONF_PATH)/mconf), )
	@unset PKG_CONFIG_LIBDIR PKG_CONFIG_PATH; $(MAKE) $(CONF_MAKES) && $(MAKE) $(CONF_MAKES) install
endif

cleankconfig:
	@-$(MAKE) $(CONF_MAKES) clean

else

buildkconfig cleankconfig:

endif

menuconfig: buildkconfig
	@mkdir -p $(CONF_OUT)
	@mtime="$(if $(wildcard $(CONFIG_PATH)),$(if $(wildcard $(AUTOHEADER_PATH)),$$(stat -c %Y $(CONFIG_PATH)),0),0)"; \
		$(CONF_PREFIX) $(CONF_PATH)/mconf $(CONF_OPTIONS); \
		if [ "$${mtime}" != "$$(stat -c %Y $(CONFIG_PATH))" ]; then \
			$(call gen_config_header); \
		else \
			$(call sync_config_header); \
		fi

ifneq ($(DEF_CONFIG), )
menuconfig: loadconfig

loadconfig: buildkconfig
	@if [ ! -e $(CONFIG_PATH) ] || [ ! -e $(config_hash_file) ]; then \
		$(call load_specific_config,$(CONF_SAVE_PATH)/$(DEF_CONFIG)); \
	else \
		$(call sync_config_header); \
	fi

defconfig: buildkconfig
	@$(call load_specific_config,$(CONF_SAVE_PATH)/$(DEF_CONFIG))
endif

%_config: $(CONF_SAVE_PATH)/%_config buildkconfig
	@$(call load_specific_config,$<)

%_defconfig: $(CONF_SAVE_PATH)/%_defconfig buildkconfig
	@$(call load_specific_config,$<)

%_saveconfig: $(CONFIG_PATH) buildkconfig
	@$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --savedefconfig=$(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)
	@echo Save $(CONFIG_PATH) to $(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)

%_savedefconfig: $(CONFIG_PATH) buildkconfig
	@$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --savedefconfig=$(CONF_SAVE_PATH)/$(subst _savedefconfig,_defconfig,$@)
	@echo Save $(CONFIG_PATH) to $(CONF_SAVE_PATH)/$(subst _savedefconfig,_defconfig,$@)

cleanconfig: cleankconfig
	@rm -rf $(CONFIG_PATH) $(CONFIG_PATH).old $(CONFIG_PATH)-md5-* $(dir $(AUTOCONFIG_PATH)) $(AUTOHEADER_PATH)

endif
