############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

COLORECHO      := $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)

ifneq ($(ENV_BUILD_MODE), yocto)
WORKDIR        := $(ENV_CFG_ROOT)
CONF_OUT       := $(WORKDIR)
KCONFIG        := $(WORKDIR)/Kconfig
CONF_SAVE_PATH := $(ENV_TOP_DIR)/configs
CONF_HEADER    := __CBUILD_GLOBAL_CONFIG__
CONF_MFLAG     := -s $(ENV_BUILD_JOBS)
DEF_CONFIG     := def_config

IGNORE_DIRS    := .git:.svn:scripts:output:build:configs:examples:notes
KEYWORDS       := none
MAXLEVEL       := 3
TIME_OUTPUT    := $(WORKDIR)/time_statistics/$(shell date +"%Y-%m-%d--%H-%M-%S.%N")
TIME_FORMAT    := /usr/bin/time -a -o $(TIME_OUTPUT) -f \"%e\\t\\t%U\\t\\t%S\\t\\t\$$@\"

# if PGTOUT is set to '!', it will show stdout; if it is set to ' ', it doesn't show stdout
PGTOUT         ?=
PGPATH         := $(WORKDIR)/log/objs
PGPORT         := $(if $(PGCMD),$(shell cat $(WORKDIR)/log/port))

.PHONY: all clean distclean toolchain host-toolchain deps all-deps \
	time_statistics progress progress_init

all: export MFLAG ?= -s
all: loadconfig progress
	@$(PRECMD)$(PGPATH)/progress $(PGTOUT)$(WORKDIR)/log make $(MFLAG) $(if $(filter y,$(tsflag)),,$(ENV_BUILD_JOBS)) \
		MAKEFLAGS= PGCMD="$(PGPATH)/progress \$$(PGPORT)" all_targets
	@echo "Build done!"

time_statistics: export MFLAG ?= -s
time_statistics: export tsflag := y
time_statistics:
	@mkdir -p $(shell dirname $(TIME_OUTPUT))
	@$(COLORECHO) "real\t\tuser\t\tsys\t\tpackage" > $(TIME_OUTPUT)
	@make $(MFLAG) PRECMD="$(TIME_FORMAT) "
	@$(COLORECHO) "\033[34mtime statistics file is $(TIME_OUTPUT)\033[0m"

progress:
	@mkdir -p $(PGPATH)
	@make -s -C $(ENV_TOP_DIR)/scripts/progress NATIVE_BUILD=y O=$(PGPATH)

-include $(WORKDIR)/.config
-include $(WORKDIR)/auto.mk
-include $(ENV_MAKE_DIR)/inc.conf.mk

clean:
	@rm -rf $(ENV_CROSS_ROOT)/objects $(ENV_CROSS_ROOT)/sysroot $(WORKDIR)/log $(ENV_NATIVE_ROOT)
	@echo "Clean Done."

distclean:
	@rm -rf $(ENV_CROSS_ROOT) $(ENV_NATIVE_ROOT)
	@echo "Distclean Done."

toolchain:
	@make $(MFLAG) $(ENV_BUILD_JOBS) -C $(ENV_TOP_DIR)/scripts/toolchain

host-toolchain:
	@make $(MFLAG) $(ENV_BUILD_JOBS) -C $(ENV_TOP_DIR)/scripts/toolchain HOST_TOOLCHAIN=y

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

PKGS_DIR ?= $(ENV_CROSS_ROOT)/packages
%-pkgs: export MFLAG ?= -s
%-pkgs:
	@make $(MFLAG) $(ENV_BUILD_JOBS) MAKEFLAGS= $(patsubst %-pkgs,%,$@)
	@rm -rf $(PKGS_DIR)/$(patsubst %-pkgs,%,$@)
	@mkdir -p $(PKGS_DIR)/$(patsubst %-pkgs,%,$@)
	@$(ENV_TOOL_DIR)/gen_depends_image.sh $(patsubst %-pkgs,%,$@) $(PKGS_DIR)/$(patsubst %-pkgs,%,$@) $(WORKDIR)/Target $(WORKDIR)/.config
	@echo "----------------------------------------"
	@make -s --no-print-directory -C $(ENV_TOP_DIR) CROSS_DESTDIR=$(PKGS_DIR)/$(patsubst %-pkgs,%,$@) INSTALL_OPTION=release $(patsubst %-pkgs,%,$@)_release
	@echo "----------------------------------------"
	@rm -rf $(addprefix $(PKGS_DIR)/$(patsubst %-pkgs,%,$@),/include/* /usr/include/* /usr/local/include/*)
	@libs=$$(find $(PKGS_DIR)/$(patsubst %-pkgs,%,$@) -name "*.a" -o -name "*.la" | xargs); \
	if [ ! -z "$${libs}" ]; then \
		rm -rf $${libs}; \
	fi
	@elfs=$$(find $(PKGS_DIR)/$(patsubst %-pkgs,%,$@) -type f -exec sh -c "file '{}' | grep -q -e 'not stripped'" \; -print | grep -v gdb | xargs); \
	if [ ! -z "$${elfs}" ]; then \
		$(if $(ENV_BUILD_TOOL),$(ENV_BUILD_TOOL)strip,$(if $(CROSS_COMPILE),$(CROSS_COMPILE)strip,strip)) -s $${elfs}; \
	fi
	@$(COLORECHO) "\033[34mRelease $(patsubst %-pkgs,%,$@) in $(PKGS_DIR)/$(patsubst %-pkgs,%,$@)\033[0m"

ifneq ($(PGCMD), )

progress_init:
	@$(PGCMD) total=$(words $(ALL_TARGETS))

$(ALL_TARGETS): progress_init

all_targets:
	@$(PGCMD) stop

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
IMAGE_PKG_PATH := $(WORKDIR)/cbuild-image.inc
PATCH_PKG_PATH := $(WORKDIR)/prepare-patch.inc
USER_METAS     := meta-example

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
