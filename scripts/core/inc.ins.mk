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
	@cp $(2) $$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')) $$(INS_PREFIX)$$($(1)dir)
endef

define install_ext
install_$(1)s_%:
	@ivar="$$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')$$(patsubst install_$(1)s%,%,$$@))"; \
	isrc="$$$$(echo $$$${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$$$//g')"; \
	idst="$$(INS_PREFIX)$$($(1)dir)$$$$(echo $$$${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$$$/\1/g')"; \
	install -d $$$${idst} && cp $(2) $$$${isrc} $$$${idst}
endef

$(eval $(call install_obj,base_bin,-drf))
$(eval $(call install_obj,base_sbin,-drf))
$(eval $(call install_obj,base_lib,-drf))
$(eval $(call install_obj,bin,-drf))
$(eval $(call install_obj,sbin,-drf))
$(eval $(call install_obj,lib,-drf))
$(eval $(call install_obj,libexec,-drf))
$(eval $(call install_obj,hdr,-drfp))
$(eval $(call install_obj,include,-drfp))
$(eval $(call install_obj,data,-drf))
$(eval $(call install_obj,info,-drf))
$(eval $(call install_obj,locale,-drf))
$(eval $(call install_obj,man,-drf))
$(eval $(call install_obj,doc,-drf))
$(eval $(call install_obj,sysconf,-drf))
$(eval $(call install_obj,service,-drf))
$(eval $(call install_obj,sharedstate,-drf))
$(eval $(call install_obj,localstate,-drf))
$(eval $(call install_obj,runstate,-drf))

$(eval $(call install_ext,include,-drfp))
$(eval $(call install_ext,data,-drf))
$(eval $(call install_ext,sysconf,-drf))

install_todir_%:
	@ivar="$($(shell echo install_todir | tr 'a-z' 'A-Z')$(patsubst install_todir%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	iopt="-drf"; \
	if [ $$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g' | grep -c '/include') -eq 1 ]; then \
		iopt="-drfp"; \
	fi; \
	install -d $${idst} && cp $${iopt} $${isrc} $${idst}

install_tofile_%:
	@ivar="$($(shell echo install_tofile | tr 'a-z' 'A-Z')$(patsubst install_tofile%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	iopt="-drf"; \
	if [ $$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g' | grep -c '/include') -eq 1 ]; then \
		iopt="-drfp"; \
	fi; \
	install -d $$(dirname $${idst}) && cp $${iopt} $${isrc} $${idst}

ifneq ($(ENV_BUILD_MODE), yocto)
ifneq ($(DIS_LICENSE), y)
.PHONY: license
SYSROOT_SCRIPT  := $(ENV_TOOL_DIR)/process_sysroot.sh
SRC_PATH        ?= .

install release: license
license:
	$(call install_lics)
endif
endif

endif # KERNELRELEASE
