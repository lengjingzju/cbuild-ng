############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

PACKAGE_NAME     = harfbuzz-without-freetype
MAKE_FNAME       = harfbuzz-without-freetype.mk

CACHE_CHECKSUM  += $(wildcard $(shell pwd)/mk.deps)
include mk.deps
