############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

ifneq ($(ENV_BUILD_MODE), yocto)

WORKDIR        := $(ENV_CFG_ROOT)
CONF_OUT       := $(WORKDIR)
KCONFIG        := $(WORKDIR)/Kconfig
CONF_SAVE_PATH := $(ENV_TOP_DIR)/configs
CONF_HEADER    := __CBUILD_GLOBAL_CONFIG__
DEF_CONFIG     := def_config

IGNORE_DIRS    := .git:.svn:scripts:output:build:configs:examples:notes
KEYWORDS       := none
MAXLEVEL       := 3
TIME_FORMAT    := /usr/bin/time -a -o $(WORKDIR)/time_statistics -f \"%e\\t\\t%U\\t\\t%S\\t\\t\$$@\"

.PHONY: all clean distclean toolchain deps all-deps total_time time_statistics

all: loadconfig
	@make $(ENV_BUILD_JOBS) $(ENV_BUILD_FLAGS) MAKEFLAGS= all_targets
	@echo "Build done!"

-include $(WORKDIR)/.config
-include $(WORKDIR)/auto.mk
-include $(ENV_MAKE_DIR)/inc.conf.mk

clean:
	@rm -rf $(ENV_CROSS_ROOT)/objects $(ENV_CROSS_ROOT)/sysroot $(ENV_NATIVE_ROOT)
	@echo "Clean Done."

distclean:
	@rm -rf $(ENV_CROSS_ROOT) $(ENV_NATIVE_ROOT)
	@echo "Distclean Done."

toolchain:
	@$(PRECMD)make -C $(ENV_TOP_DIR)/scripts/toolchain

buildkconfig: deps
deps:
	@mkdir -p $(WORKDIR)
	@$(PRECMD)python3 $(ENV_TOOL_DIR)/gen_build_chain.py -m $(WORKDIR)/auto.mk -k $(WORKDIR)/Kconfig -t $(WORKDIR)/Target \
		-d mk.deps -v mk.vdeps -c mk.kconf -s $(ENV_TOP_DIR) -i $(IGNORE_DIRS) -l $(MAXLEVEL) -w $(KEYWORDS)

%-deps:
	@$(ENV_TOOL_DIR)/gen_depends_image.sh $(patsubst %-deps,%,$@) $(WORKDIR)/depends $(WORKDIR)/Target  $(WORKDIR)/.config

all-deps:
	@for package in $$(cat $(WORKDIR)/Target  | cut -d '=' -f 1); do \
		$(ENV_TOOL_DIR)/gen_depends_image.sh $${package} $(WORKDIR)/depends $(WORKDIR)/Target  $(WORKDIR)/.config; \
	done

total_time: loadconfig
	@$(PRECMD)make $(ENV_BUILD_FLAGS) all_targets
	@echo "Build done!"

time_statistics:
	@mkdir -p $(WORKDIR)
	@$(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e) "real\t\tuser\t\tsys\t\tpackage" > $(WORKDIR)/$@
	@make $(ENV_BUILD_FLAGS) PRECMD="$(TIME_FORMAT) " total_time

else # ENV_BUILD_MODE=yocto

WORKDIR        := $(ENV_CFG_ROOT)
CONF_PATH      := $(shell pwd)/tmp/work/$(shell uname -m)-linux/kconfig-native/1.0-r0/build
CONF_OUT       := $(WORKDIR)
KCONFIG        := $(WORKDIR)/Kconfig
CONF_SAVE_PATH := $(ENV_TOP_DIR)/configs
CONF_HEADER    := __CBUILD_GLOBAL_CONFIG__
DEF_CONFIG     := yocto_config

IGNORE_DIRS    := .git:.svn
IGNORE_RECIPES := none
KEYWORDS       := none
MAXLEVEL       := 3

IMAGE_NAME     ?= $(if $(i),$(i),cbuild-image)
IMAGE_PKG_PATH  = $(WORKDIR)/cbuild-image.inc
PATCH_PKG_PATH  = $(WORKDIR)/prepare-patch.inc
USER_METAS     ?= meta-example

.PHONY: all clean incs deps kconfig-native

all: incs
	@bitbake prepare-patch
	@bitbake $(IMAGE_NAME)
	@echo "Build done!"

include $(ENV_MAKE_DIR)/inc.conf.mk

all: incs
buildkconfig: deps

clean:
	@bitbake $(IMAGE_NAME) -c clean
	@echo "Clean done!"

incs: loadconfig
	@python3 $(ENV_TOOL_DIR)/gen_build_chain.py -t $(WORKDIR)/Target -c $(CONFIG_PATH) \
		-o $(IMAGE_PKG_PATH) -p $(PATCH_PKG_PATH) -i $(IGNORE_RECIPES)

deps: kconfig-native
	@mkdir -p $(shell dirname $(KCONFIG))
	@python3 $(ENV_TOOL_DIR)/gen_build_chain.py -k $(WORKDIR)/Kconfig -t $(WORKDIR)/Target \
		-v mk.vdeps -c mk.kconf -i $(IGNORE_DIRS) -l $(MAXLEVEL) -w $(KEYWORDS) -u $(USER_METAS)

kconfig-native:
	@if [ ! -e $(CONF_PATH)/conf ] || [ ! -e $(CONF_PATH)/mconf ]; then \
		bitbake kconfig-native; \
	fi

%_clean:
	@bitbake $(patsubst %_clean,%,$@) -c clean

%_menuconfig:
	@bitbake $(patsubst %_menuconfig,%,$@) -c menuconfig

%_defconfig:
	@bitbake $(patsubst %_defconfig,%,$@) -c defconfig

%-deps:
	@$(ENV_TOOL_DIR)/gen_depends_image.sh $(patsubst %-deps,%,$@) $(WORKDIR)/depends $(WORKDIR)/Target $(WORKDIR)/.config

%:
	@bitbake $@ $(if $(c),-c $(c))

endif
