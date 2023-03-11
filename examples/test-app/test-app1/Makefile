PACKAGE_NAME = test-app1

BIN_NAME = test
LIBA_NAME = libtest.a
LIBSO_NAME = libtest.so 1 2 3
INSTALL_HEADERS = include/add.h include/sub.h

.PHONY: all clean install

all:

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.app.mk
include $(ENV_MAKE_DIR)/inc.ins.mk

all: $(LIB_TARGETS) $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS) $(BIN_TARGETS)

install: install_libs install_bins install_hdrs
