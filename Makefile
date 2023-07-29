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
TIME_OUTPUT    := $(WORKDIR)/time_statistics.$(shell date +"%Y-%m-%d.%H-%M-%S.%N")
TIME_FORMAT    := /usr/bin/time -a -o $(TIME_OUTPUT) -f \"%e\\t\\t%U\\t\\t%S\\t\\t\$$@\"
PROGRESS_SCRIPT:= python3 $(ENV_TOOL_DIR)/show_progress.py
MAKESILENT     ?= $(if $(filter y,$(BUILDVERBOSE)),,-s)

.PHONY: all clean distclean toolchain deps all-deps total_time time_statistics progress_init

all: loadconfig
	@$(PROGRESS_SCRIPT) start &
	@sleep 1
	@make $(MAKESILENT) $(ENV_BUILD_JOBS) MAKEFLAGS= progress_cmd="$(PROGRESS_SCRIPT) $$(cat $(WORKDIR)/pg.port) \$$@" all_targets
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
	@$(PRECMD)make $(MAKESILENT) $(ENV_BUILD_JOBS) -C $(ENV_TOP_DIR)/scripts/toolchain

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
	@$(PROGRESS_SCRIPT) start &
	@sleep 1
	@$(PRECMD)make $(MAKESILENT) progress_cmd="$(PROGRESS_SCRIPT) $$(cat $(WORKDIR)/pg.port) \$$@" all_targets
	@echo "Build done!"

time_statistics:
	@mkdir -p $(WORKDIR)
	@$(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e) "real\t\tuser\t\tsys\t\tpackage" > $(WORKDIR)/$@
	@make $(MAKESILENT) PRECMD="$(TIME_FORMAT) " total_time
	@echo "time statistics file is $(TIME_OUTPUT)"

ifneq ($(progress_cmd), )

progress_init:
	@$(PROGRESS_SCRIPT) $$(cat $(WORKDIR)/pg.port) total=$(words $(ALL_TARGETS))

$(ALL_TARGETS): progress_init

all_targets:
	@$(PROGRESS_SCRIPT) stop

endif

else # ENV_BUILD_MODE=yocto

WORKDIR        := $(ENV_CFG_ROOT)
CONF_PATH      := $(WORKDIR)/objs/kconfig
CONF_OUT       := $(WORKDIR)
KCONFIG        := $(WORKDIR)/Kconfig
CONF_SAVE_PATH := $(ENV_TOP_DIR)/configs
CONF_HEADER    := __CBUILD_GLOBAL_CONFIG__
DEF_CONFIG     := yocto_config
CONF_MAKES      = -s O=$(CONF_PATH) -C $(CONF_SRC)

IGNORE_DIRS    := .git:.svn
IGNORE_RECIPES := none
KEYWORDS       := none
MAXLEVEL       := 3

IMAGE_NAME     ?= $(if $(i),$(i),cbuild-image)
IMAGE_PKG_PATH  = $(WORKDIR)/cbuild-image.inc
PATCH_PKG_PATH  = $(WORKDIR)/prepare-patch.inc
USER_METAS     ?= meta-example

.PHONY: all clean incs deps

all: incs
	@bitbake prepare-patch
	@bitbake $(IMAGE_NAME)
	@echo "Build done!"

include $(ENV_MAKE_DIR)/inc.conf.mk

clean:
	@bitbake $(IMAGE_NAME) -c clean
	@echo "Clean done!"

incs: loadconfig
	@python3 $(ENV_TOOL_DIR)/gen_build_chain.py -t $(WORKDIR)/Target -c $(CONFIG_PATH) \
		-o $(IMAGE_PKG_PATH) -p $(PATCH_PKG_PATH) -i $(IGNORE_RECIPES)

deps:
	@mkdir -p $(shell dirname $(KCONFIG))
	@python3 $(ENV_TOOL_DIR)/gen_build_chain.py -k $(WORKDIR)/Kconfig -t $(WORKDIR)/Target \
		-v mk.vdeps -c mk.kconf -i $(IGNORE_DIRS) -l $(MAXLEVEL) -w $(KEYWORDS) -u $(USER_METAS)

buildkconfig: deps
ifeq ($(wildcard $(CONF_PATH)/mconf), )
	@$(MAKE) $(CONF_MAKES)
endif

cleankconfig:
	@-$(MAKE) $(CONF_MAKES) clean

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
