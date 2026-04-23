############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
# https://github.com/lengjingzju/cbuild-ng #
############################################

ifneq ($(KERNELRELEASE), )

MOD_NAME       ?= hello
obj-m          := $(patsubst %,%.o,$(MOD_NAME))

imake_ccflags  := $(patsubst %,-I%,$(src) $(src)/include $(obj))
imake_ccflags  += $(call link_hdrs)
imake_ccflags  += $(OPTIMIZER_FLAG)
imake_ccflags  += $(IMAKE_CCFLAGS)

ccflags-y      += $(imake_ccflags)

define translate_obj
$(patsubst $(src)/%,%,$(patsubst %,%.o,$(basename $(1))))
endef

define set_flags
$(foreach v,$(2),$(eval $(1)_$(call translate_obj,$(v)) = $(3)))
endef

ifeq ($(words $(MOD_NAME)),1)

IGNORE_PATH    ?= .git .pc scripts out output obj objects
REG_SUFFIX     ?= c S

ifeq ($(SRCS), )
SRCS           := $(filter-out %.mod.c,$(shell find $(src) \
                          $(patsubst %,-path '*/%' -prune -o,$(IGNORE_PATH)) \
                          $(shell echo '$(patsubst %,-o -name "*.%" -print,$(REG_SUFFIX))' | sed 's/^...//') \
                     | xargs))
endif
OBJS           := $(call translate_obj,$(SRCS))

ifneq ($(words $(OBJS))-$(OBJS),1-$(MOD_NAME).o)
$(MOD_NAME)-y  := $(OBJS)
endif

else

# If multiple modules are compiled at the same time, user should
# set objs under every module himself.

endif

#
# Starting from kernel version 6.10(9a0ebe5011f4), the compilation dependency rule has been changed
# from "$(obj)/%.o: $(src)/%.c" to "$(obj)/%.o: $(obj)/%.c", the original method of separating
# compilation output from source code has failed, so the following rules has been added.
#
ifneq ($(obj), $(src))
$(obj)/%.c : $(src)/%.c
	$(PREAT)mkdir -p $(shell dirname $@)
	$(PREAT)ln -sfT $< $@

$(obj)/%.rs : $(src)/%.rs
	$(PREAT)mkdir -p $(shell dirname $@)
	$(PREAT)ln -sfT $< $@

$(obj)/%.S : $(src)/%.S
	$(PREAT)mkdir -p $(shell dirname $@)
	$(PREAT)ln -sfT $< $@
endif

else # KERNELRELEASE

KERNEL_SRC     ?= /lib/modules/$(shell uname -r)/build
MOD_PATH       ?= $(shell realpath $(shell pwd))

ifeq ($(MOD_MAKES), )
MOD_MAKES      := -C $(KERNEL_SRC)
else
MOD_MAKES      += -C $(KERNEL_SRC)
endif

ifneq ($(ENV_BUILD_MODE),yocto)
MOD_MAKES      += $(if $(KERNEL_OUT),O=$(KERNEL_OUT),O=)
endif

ifneq ($(filter $(OBJ_PREFIX),. $(MOD_PATH)), )
MOD_OPATH      ?= $(shell realpath -m $(OBJ_PREFIX))
MOD_MAKES      += M=$(MOD_PATH)

modules_install_prepend:
	@

else

MOD_OPATH      ?= $(shell realpath -m $(OBJ_PREFIX))
MOD_MAKES      += M=$(MOD_OPATH) src=$(MOD_PATH)

#
# Starting from kernel version 6.13(13b25489b6f8b), the variable value of `build-dir` has
# been changed from `$(KBUILD_EXTMOD)` to `.`, so the following variable setting has been added.
#
MOD_MAKES      += build-dir=$(MOD_OPATH)

#
# Note:
# Users should copy the Kbuild or Makefile to avoid compilation failures.
# If they don't want to copy it, they should modify the
# "$(KERNEL_SRC)/scripts/Makefile.modpost" as follow:
#   -include $(if $(wildcard $(KBUILD_EXTMOD)/Kbuild), \
#   -             $(KBUILD_EXTMOD)/Kbuild, $(KBUILD_EXTMOD)/Makefile)
#   +include $(if $(wildcard $(src)/Kbuild), $(src)/Kbuild, $(src)/Makefile)
#
KBUILD_MK      := $(if $(wildcard $(MOD_PATH)/Kbuild),Kbuild,Makefile)
modules modules_clean modules_install: $(OBJ_PREFIX)/$(KBUILD_MK)
$(OBJ_PREFIX)/$(KBUILD_MK): $(MOD_PATH)/$(KBUILD_MK)
	$(PREAT)-mkdir -p $(dir $@)
	$(PREAT)-cp -f $< $@

#
# Starting from kernel version 6.13(13b25489b6f8b and bad6beb2c0bb9), the variable value of `extmod_prefix`
# has been removed, module will be install to `$(INS_PREFIX)/lib/modules/<full_ver>/updates/$(MOD_OPATH)`.
# To avoid installation in this directory, so the following rule has been added.
#
modules_install_prepend:
	$(PREAT)full_ver=$$($(MAKE) -s $(MOD_MAKES) kernelversion); \
		major_ver=$$(echo $${full_ver} | cut -d. -f 1); \
		minor_ver=$$(echo $${full_ver} | cut -d. -f 2); \
		if [ $${major_ver} -gt 6 ] || ([ $${major_ver} -eq 6 ] && [ $${minor_ver} -ge 13 ]); then \
			sed -i "s@$(MOD_OPATH)/@@g" $(MOD_OPATH)/modules.order; \
		fi

endif

export SEARCH_HDRS PACKAGE_NAME

.PHONY: modules modules_clean modules_install symvers_install

modules:
	$(PREAT)$(MAKE) $(MOD_MAKES) $(if $(SEARCH_HDRS), KBUILD_EXTRA_SYMBOLS="$(wildcard $(patsubst %,$(DEP_PREFIX)/usr/include/%/Module.symvers,$(SEARCH_HDRS)))") modules

modules_clean:
	$(PREAT)$(MAKE) $(MOD_MAKES) clean
ifeq ($(filter $(MOD_OPATH)/% $(MOD_OPATH),$(MOD_PATH)), )
	$(PREAT)rm -rf $(MOD_OPATH)
endif

modules_install: modules_install_prepend
	$(PREAT)$(MAKE) $(MOD_MAKES) $(if $(INS_PREFIX), INSTALL_MOD_PATH=$(INS_PREFIX)) modules_install

symvers_install:
	$(PREAT)install -d $(INS_PREFIX)/usr/include/$(INSTALL_HDR)
	$(PREAT)sed -i "s@$(MOD_OPATH)/@@g" $(OBJ_PREFIX)/Module.symvers
	$(PREAT)cp -drf --preserve=mode,timestamps $(OBJ_PREFIX)/Module.symvers $(INS_PREFIX)/usr/include/$(INSTALL_HDR)

install_hdrs: symvers_install

endif
