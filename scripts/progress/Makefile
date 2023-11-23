############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

PACKAGE_NAME    = progress

BIN_NAME = progress
CFLAGS += -Wno-unused-result

.PHONY: all clean install
all:

INC_MAKES      := app
include inc.makes

all: $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(BIN_TARGETS)

install: install_bins
