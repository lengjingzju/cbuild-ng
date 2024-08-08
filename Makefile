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
CONF_SAVE_PATH := $(ENV_TOP_DIR)/board/$(if $(ENV_BUILD_SOC),$(ENV_BUILD_SOC),generic)/configs
CONF_HEADER    := __CBUILD_GLOBAL_CONFIG__
CONF_MFLAG     := -s $(ENV_BUILD_JOBS)
DEF_CONFIG     := def_config

IGNORE_DIRS    := .git:.svn:scripts:output:build:configs:examples:notes
KEYWORDS       := none
MAXLEVEL       := 3
CORE_PKGS      :=
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
	@$(ENV_TOOL_DIR)/gen_depends_image.sh $(patsubst %-deps,%,$@) $(WORKDIR)/depends $(WORKDIR)/Target  $(WORKDIR)/.config $(CORE_PKGS)

all-deps:
	@for package in $$(cat $(WORKDIR)/Target  | cut -d '=' -f 1); do \
		$(ENV_TOOL_DIR)/gen_depends_image.sh $${package} $(WORKDIR)/depends $(WORKDIR)/Target  $(WORKDIR)/.config $(CORE_PKGS); \
	done

LICS_DIR       := $(ENV_TOP_DIR)/system/rootfs/licenses
define pkg_dst
$(ENV_CROSS_ROOT)/packages/$(patsubst %-pkg,%,$1)
endef
define pkg_lic_dst
$(ENV_CROSS_ROOT)/packages/$(patsubst %-pkg,%,$1)/usr/share/license
endef
PKG_BUILD      ?= y
PKG_STRIP      ?= y
ifneq ($(ENV_BUILD_TOOL), )
PKG_EOS        ?= y
endif

%-pkg: export MFLAG ?= -s
%-pkg: progress
ifeq ($(PKG_BUILD),y)
	@$(PGPATH)/progress $(PGTOUT)$(WORKDIR)/log make $(MFLAG) $(ENV_BUILD_JOBS) \
		pg_total_pkgs=$(shell make -n $(patsubst %-pkg,%,$@) | grep -c '^echo "Build .* Done\."$$') \
		MAKEFLAGS= PGCMD="$(PGPATH)/progress \$$(PGPORT)" $(patsubst %-pkg,%,$@)
	@$(PGPATH)/progress $$(cat $(WORKDIR)/log/port) stop
endif
	@rm -rf $(call pkg_dst,$@)
	@mkdir -p $(call pkg_dst,$@)
	@echo "----------------------------------------"
	@$(MAKE) -s --no-print-directory -C $(ENV_TOP_DIR) CROSS_DESTDIR=$(call pkg_dst,$@) INSTALL_OPTION=release $(patsubst %-pkg,%,$@)_release
	@echo "----------------------------------------"
	@rm -rf $(addprefix $(call pkg_dst,$@),/include/* /usr/include/* /usr/local/include/*)
	@libs=$$(find $(call pkg_dst,$@) -name "*.a" -o -name "*.la" | xargs); \
	if [ ! -z "$${libs}" ]; then \
		rm -rf $${libs}; \
	fi
ifeq ($(PKG_STRIP),y)
	@elfs=$$(find $(call pkg_dst,$@) -type f -exec sh -c "file '{}' | grep -q -e 'not stripped'" \; -print | grep -v gdb | xargs); \
	if [ ! -z "$${elfs}" ]; then \
		$(if $(ENV_BUILD_TOOL),$(ENV_BUILD_TOOL)strip,$(if $(CROSS_COMPILE),$(CROSS_COMPILE)strip,strip)) -s $${elfs}; \
	fi
endif
	@mkdir -p $(call pkg_lic_dst,$@)
	@cp -drf $(LICS_DIR)/* $(call pkg_lic_dst,$@)
	@python3 $(ENV_TOOL_DIR)/gen_package_infos.py -c $(WORKDIR)/.config -i $(WORKDIR)/info.txt \
		-t $(WORKDIR)/Target -p $(patsubst %-pkg,%,$@) -s $(LICS_DIR)/spdx-licenses.html \
		-o $(call pkg_lic_dst,$@)/index.txt -w $(call pkg_lic_dst,$@)/index.html -f 0:0
	@$(ENV_TOOL_DIR)/gen_depends_image.sh $(patsubst %-pkg,%,$@) $(call pkg_lic_dst,$@) $(WORKDIR)/Target $(WORKDIR)/.config $(CORE_PKGS)


%-cpk: export MFLAG ?= -s
%-cpk:
	@$(MAKE) $(MFLAG) CONFIG_PATCHELF_NATIVE=y patchelf-native
	@$(MAKE) $(MFLAG) CONFIG_PATCHELF=y patchelf
	@$(MAKE) $(MFLAG) $(patsubst %-cpk,%-pkg,$@)
	@PATH=$(ENV_NATIVE_ROOT)/objects/patchelf/image/usr/bin:$(PATH) \
		python3 $(ENV_TOOL_DIR)/gen_cpk_package.py -r $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@) \
		-i include:share:etc:srv:com:var:run $(if $(PKG_EOS),-o $(PKG_EOS)) \
		-c $(ENV_BUILD_TOOL)gcc -t $(ENV_BUILD_TOOL)readelf $(if $(CPK_EXTRA_PATH),-e $(CPK_EXTRA_PATH))
	@cp -fp $(ENV_CROSS_ROOT)/objects/patchelf/image/usr/bin/patchelf $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
ifneq ($(PKG_EOS),y)
	@cp -fp $(ENV_TOOL_DIR)/gen_cpk_package.py $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
	@ush=$(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)/update.sh && \
		echo '#!/bin/sh' > $${ush} && \
		echo 'curdir=$$(dirname $$(realpath $$0))' >> $${ush} && \
		echo 'PATH=$$curdir:$$PATH python3 $$curdir/gen_cpk_package.py -r $$curdir -i include:share:etc:srv:com:var:run' >> $${ush} && \
		chmod +x $${ush}
endif
	@bash $(ENV_TOOL_DIR)/gen_cpk_binary.sh pack $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)


ifneq ($(PGCMD), )

progress_init:
	@$(PGCMD) total=$(if $(pg_total_pkgs),$(pg_total_pkgs),$(words $(ALL_TARGETS)))

$(ALL_TARGETS): progress_init

all_targets:
	@$(PGCMD) stop

endif

else # ENV_BUILD_MODE=yocto

WORKDIR        := $(ENV_CFG_ROOT)
CONF_PATH      := $(WORKDIR)/objs/kconfig
CONF_OUT       := $(WORKDIR)
KCONFIG        := $(WORKDIR)/Kconfig
CONF_SAVE_PATH := $(ENV_TOP_DIR)/board/$(if $(ENV_BUILD_SOC),$(ENV_BUILD_SOC),generic)/configs
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
