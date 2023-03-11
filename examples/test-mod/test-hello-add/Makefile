$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_add

else

PACKAGE_NAME    = test-hello-add
INSTALL_HEADERS = hello_add.h

all: modules

clean: modules_clean

install: modules_install install_hdrs

endif

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.mod.mk
include $(ENV_MAKE_DIR)/inc.ins.mk
