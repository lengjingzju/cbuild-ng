############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

WORKDIR        := $(ENV_CFG_ROOT)
CONF_SRC       := $(shell realpath $(ENV_TOP_DIR)/../../scripts/kconfig)
CONF_OUT       := $(WORKDIR)
KCONFIG        := $(WORKDIR)/Kconfig
CONF_SAVE_PATH := $(ENV_TOP_DIR)/configs
CONF_HEADER    := __CBUILD_GLOBAL_CONFIG__
CONF_MFLAG     := -s $(ENV_BUILD_JOBS)
DEF_CONFIG     := def_config
export CONF_SRC

IGNORE_DIRS    := .git:.svn:scripts:output:configs
KEYWORDS       := none
MAXLEVEL       := 2
TIME_FORMAT    := /usr/bin/time -a -o $(WORKDIR)/time_statistics -f \"%e\\t\\t%U\\t\\t%S\\t\\t\$$@\"

.PHONY: all clean distclean deps all-deps time_statistics

all: export MFLAG ?= -s
all: loadconfig
	@$(PRECMD)make $(MFLAG) $(if $(filter y,$(tsflag)),,$(ENV_BUILD_JOBS)) MAKEFLAGS= all_targets
	@echo "Build done!"

time_statistics: export MFLAG ?= -s
time_statistics: export tsflag := y
time_statistics:
	@mkdir -p $(WORKDIR)
	@$(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e) "real\t\tuser\t\tsys\t\tpackage" > $(WORKDIR)/$@
	@make $(MFLAG) PRECMD="$(TIME_FORMAT) "

-include $(WORKDIR)/.config
-include $(WORKDIR)/auto.mk
-include $(ENV_MAKE_DIR)/inc.conf.mk

clean:
	@rm -rf $(ENV_CROSS_ROOT)/objects $(ENV_CROSS_ROOT)/sysroot $(ENV_NATIVE_ROOT)
	@echo "Clean Done."

distclean:
	@rm -rf $(ENV_CROSS_ROOT) $(ENV_NATIVE_ROOT)
	@echo "Distclean Done."

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
