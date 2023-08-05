############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
# https://github.com/lengjingzju/cbuild-ng #
############################################

ifeq ($(KERNELRELEASE), )

# Defines the compatible variables with previous inc.ins.mk

INSTALL_BASE_BINARIES  ?= $(INSTALL_BINARIES)
INSTALL_BASE_BINS      ?= $(INSTALL_BASE_BINARIES)
INSTALL_BINS           ?= $(INSTALL_BINARIES)
INSTALL_BASE_LIBRARIES ?= $(INSTALL_LIBRARIES)
INSTALL_BASE_LIBS      ?= $(INSTALL_BASE_LIBRARIES)
INSTALL_LIBS           ?= $(INSTALL_LIBRARIES)
INSTALL_HDRS           ?= $(INSTALL_HEADERS)

# Defines the installation functions and targets

define install_obj
.PHONY: install_$(1)s
install_$(1)s:
	@install -d $$(INS_PREFIX)$$($(1)dir)
	@cp -drf --preserve=mode,timestamps $$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')) $$(INS_PREFIX)$$($(1)dir)
endef

define install_ext
install_$(1)s_%:
	@ivar="$$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')$$(patsubst install_$(1)s%,%,$$@))"; \
	isrc="$$$$(echo $$$${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$$$//g')"; \
	idst="$$(INS_PREFIX)$$($(1)dir)$$$$(echo $$$${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$$$/\1/g')"; \
	install -d $$$${idst} && cp -drf --preserve=mode,timestamps $$$${isrc} $$$${idst}
endef

$(eval $(call install_obj,base_bin))
$(eval $(call install_obj,base_sbin))
$(eval $(call install_obj,base_lib))
$(eval $(call install_obj,bin))
$(eval $(call install_obj,sbin))
$(eval $(call install_obj,lib))
$(eval $(call install_obj,libexec))
$(eval $(call install_obj,hdr))
$(eval $(call install_obj,include))
$(eval $(call install_obj,data))
$(eval $(call install_obj,info))
$(eval $(call install_obj,locale))
$(eval $(call install_obj,man))
$(eval $(call install_obj,doc))
$(eval $(call install_obj,sysconf))
$(eval $(call install_obj,service))
$(eval $(call install_obj,sharedstate))
$(eval $(call install_obj,localstate))
$(eval $(call install_obj,runstate))

$(eval $(call install_ext,include))
$(eval $(call install_ext,data))
$(eval $(call install_ext,sysconf))

install_todir_%:
	@ivar="$($(shell echo install_todir | tr 'a-z' 'A-Z')$(patsubst install_todir%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	install -d $${idst} && cp -drf --preserve=mode,timestamps $${isrc} $${idst}

install_tofile_%:
	@ivar="$($(shell echo install_tofile | tr 'a-z' 'A-Z')$(patsubst install_tofile%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	install -d $$(dirname $${idst}) && cp -drf --preserve=mode,timestamps $${isrc} $${idst}

ifneq ($(ENV_BUILD_MODE),yocto)
ifneq ($(DIS_LICENSE),y)
.PHONY: license
SYSROOT_SCRIPT  := $(ENV_TOOL_DIR)/process_sysroot.sh
SRC_PATH        ?= .

install release: license
license:
	@$(call install_lics)
endif
endif

endif # KERNELRELEASE
