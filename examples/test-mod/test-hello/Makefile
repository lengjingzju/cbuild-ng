ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_dep

else

PACKAGE_NAME    = test-hello
SEARCH_HDRS     = test-hello-add test-hello-sub

all: modules

clean: modules_clean

install: modules_install
endif

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.mod.mk
