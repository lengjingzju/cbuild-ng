############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

export WORKDIR
export ENV_TOP_DIR
export ENV_MAKE_DIR = "${ENV_TOP_DIR}/scripts/core"
export ENV_TOOL_DIR = "${ENV_TOP_DIR}/scripts/bin"
export ENV_CFG_ROOT = "${TOPDIR}/config"

export ENV_BUILD_MODE = "yocto"
NATIVE_BUILD:class-target = "n"
NATIVE_BUILD:class-native = "y"
export NATIVE_BUILD
