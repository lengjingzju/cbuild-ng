############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

PACKAGE_NAME = ljson

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.app.mk
include $(ENV_MAKE_DIR)/inc.ins.mk

$(eval $(call add-liba-build,libljson.a,json.c,-lm))
$(eval $(call add-libso-build,libljson.so,json.c,-lm))
$(eval $(call add-bin-build,ljson_test,json_test.c,-L $(OBJ_PREFIX) -lljson -lm))

INSTALL_HEADERS = json.h

all: $(BIN_TARGETS) $(LIB_TARGETS)

$(BIN_TARGETS): $(LIB_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS) $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_hdrs install_libs install_bins


