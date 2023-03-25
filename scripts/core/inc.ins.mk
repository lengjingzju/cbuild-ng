############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

ifeq ($(KERNELRELEASE), )

# Defines the GNU standard installation directories
# Note: base_*dir and hdrdir are not defined in the GNUInstallDirs
# GNUInstallDirs/Autotools: https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
# CMake: https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
# Meson: https://mesonbuild.com/Builtin-options.html#directories
# Yocto: https://git.yoctoproject.org/poky/tree/meta/conf/bitbake.conf

base_bindir     = /bin
base_sbindir    = /sbin
base_libdir     = /lib
bindir          = /usr/bin
sbindir         = /usr/sbin
libdir          = /usr/lib
libexecdir      = /usr/libexec
hdrdir          = /usr/include/$(INSTALL_HDR)
includedir      = /usr/include
datarootdir     = /usr/share
datadir         = $(datarootdir)
infodir         = $(datadir)/info
localedir       = $(datadir)/locale
mandir          = $(datadir)/man
docdir          = $(datadir)/doc
sysconfdir      = /etc
servicedir      = /srv
sharedstatedir  = /com
localstatedir   = /var
runstatedir     = /run

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

SYSROOT_SCRIPT  := $(ENV_TOOL_DIR)/process_sysroot.sh
.PHONY: psysroot isysroot

psysroot:
	@$(MAKE) $(PREPARE_SYSROOT)

ifneq ($(filter $(INSTALL_OPTION),link release), )

isysroot:
	@install -d $(INS_PREFIX)
	@flock $(INS_PREFIX) -c "bash $(SYSROOT_SCRIPT) $(INSTALL_OPTION) $(INS_TOPDIR) $(INS_PREFIX)"

else # INSTALL_OPTION

isysroot: install
	@$(SYSROOT_SCRIPT) replace $(INS_TOPDIR)
	@install -d $(SYS_PREFIX)
	@flock $(SYS_PREFIX) -c "bash $(SYSROOT_SCRIPT) link $(INS_TOPDIR) $(SYS_PREFIX)"

endif # INSTALL_OPTION

endif # ENV_BUILD_MODE

endif # KERNELRELEASE
