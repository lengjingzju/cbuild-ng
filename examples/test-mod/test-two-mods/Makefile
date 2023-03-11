$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_op hello_sec
hello_op-y = hello_main.o hello_add.o hello_sub.o hello_mul.o hello_div.o

else

PACKAGE_NAME    = test-two-mods

all: modules
	@echo "Build $(PACKAGE_NAME) Done."

clean: modules_clean
	@echo "Clean $(PACKAGE_NAME) Done."

install: modules_install

endif

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.mod.mk
