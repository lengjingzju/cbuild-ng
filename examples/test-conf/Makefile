PACKAGE_NAME    = test-conf


include $(ENV_MAKE_DIR)/inc.env.mk

-include $(OUT_PREFIX)/.config
DEF_CONFIG      = $(if $(CONFIG_DEF_TEST_CFG),$(CONFIG_DEF_TEST_CFG),def_config)

.PHONY: all clean install

all: defconfig
	@

clean:
	@

install:
	@

include $(ENV_MAKE_DIR)/inc.conf.mk
