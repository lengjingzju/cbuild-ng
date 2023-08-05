############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
# https://github.com/lengjingzju/cbuild-ng #
############################################

ifneq ($(KERNELRELEASE), )

MOD_NAME       ?= hello
obj-m          := $(patsubst %,%.o,$(MOD_NAME))

ccflags-y      += $(patsubst %,-I%,$(src) $(src)/include $(obj))
ccflags-y      += $(call link_hdrs)
ccflags-y      += $(OPTIMIZATION_FLAG)
ccflags-y      += $(IMAKE_CCFLAGS)

define translate_obj
$(patsubst $(src)/%,%,$(patsubst %,%.o,$(basename $(1))))
endef

define set_flags
$(foreach v,$(2),$(eval $(1)_$(call translate_obj,$(v)) = $(3)))
endef

ifeq ($(words $(MOD_NAME)),1)

IGNORE_PATH    ?= .git .pc scripts output
REG_SUFFIX     ?= c S
SRCS           ?= $(filter-out %.mod.c,$(shell find $(src) \
                          $(patsubst %,-path '*/%' -prune -o,$(IGNORE_PATH)) \
                          $(shell echo '$(patsubst %,-o -name "*.%" -print,$(REG_SUFFIX))' | sed 's/^...//') \
                     | xargs))
OBJS            = $(call translate_obj,$(SRCS))

ifneq ($(words $(OBJS))-$(OBJS),1-$(MOD_NAME).o)
$(MOD_NAME)-y  := $(OBJS)
endif

else

# If multiple modules are compiled at the same time, user should
# set objs under every module himself.

endif

else # KERNELRELEASE

KERNEL_SRC     ?= /lib/modules/$(shell uname -r)/build
MOD_PATH       ?= $(shell pwd)
MOD_MAKES      += -C $(KERNEL_SRC)

ifneq ($(ENV_BUILD_MODE),yocto)
MOD_MAKES      += $(if $(KERNEL_OUT),O=$(KERNEL_OUT),O=)
endif

ifneq ($(filter $(OBJ_PREFIX),. $(MOD_PATH)), )
MOD_MAKES      += M=$(MOD_PATH)
else

MOD_MAKES      += M=$(OBJ_PREFIX) src=$(MOD_PATH)
KBUILD_MK       = $(if $(wildcard $(MOD_PATH)/Kbuild),Kbuild,Makefile)

modules modules_clean modules_install: $(OBJ_PREFIX)/$(KBUILD_MK)

$(OBJ_PREFIX)/$(KBUILD_MK): $(MOD_PATH)/$(KBUILD_MK)
	@-mkdir -p $(dir $@)
	@-cp -f $< $@

#
# Note:
# Users should copy the Kbuild or Makefile to avoid compilation failures.
# If they don't want to copy it, they should modify the
# "$(KERNEL_SRC)/scripts/Makefile.modpost" as follow:
#   -include $(if $(wildcard $(KBUILD_EXTMOD)/Kbuild), \
#   -             $(KBUILD_EXTMOD)/Kbuild, $(KBUILD_EXTMOD)/Makefile)
#   +include $(if $(wildcard $(src)/Kbuild), $(src)/Kbuild, $(src)/Makefile)
#

endif

export SEARCH_HDRS PACKAGE_NAME

.PHONY: modules modules_clean modules_install symvers_install

modules:
	@$(MAKE) $(MOD_MAKES) $(if $(SEARCH_HDRS), KBUILD_EXTRA_SYMBOLS="$(wildcard $(patsubst %,$(DEP_PREFIX)/usr/include/%/Module.symvers,$(SEARCH_HDRS)))") modules

modules_clean:
	@$(MAKE) $(MOD_MAKES) clean

modules_install:
	@$(MAKE) $(MOD_MAKES) $(if $(INS_PREFIX), INSTALL_MOD_PATH=$(INS_PREFIX)) modules_install

symvers_install:
	@install -d $(INS_PREFIX)/usr/include/$(INSTALL_HDR)
	@cp -drf --preserve=mode,timestamps $(OBJ_PREFIX)/Module.symvers $(INS_PREFIX)/usr/include/$(INSTALL_HDR)

install_hdrs: symvers_install

endif
