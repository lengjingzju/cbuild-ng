#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

out_path=$1
cc_tool=$2
cross_infos=$(${ENV_TOOL_DIR}/process_machine.sh meson_cross)

cross_compile=$(echo ${cross_infos} | cut -d ' ' -f 1)
cpu_family=$(echo ${cross_infos} | cut -d ' ' -f 2)
cpu=$(echo ${cross_infos} | cut -d ' ' -f 3)
endian=$(echo ${cross_infos} | cut -d ' ' -f 4)

mkdir -p ${out_path}

if [ "${cc_tool}" = "clang" ]; then

cat <<EOF> ${out_path}/cross.ini
[constants]
arch = '${cross_compile}'

[binaries]

c = 'clang'
cpp = 'clang++'
as = 'llvm-as'
ld = 'lld'
ar = 'llvm-ar'
ranlib = 'llvm-ranlib'
objcopy = 'llvm-objcopy'
strip = 'llvm-strip'
pkgconfig = 'pkg-config'

[host_machine]
system = 'linux'
cpu_family = '${cpu_family}'
cpu = '${cpu}'
endian = '${endian}'
EOF

else

cat <<EOF> ${out_path}/cross.ini
[constants]
arch = '${cross_compile}'

[binaries]
c = arch + 'gcc'
cpp = arch + 'g++'
as = arch + 'as'
ld = arch + 'ld'
ar = arch + 'ar'
ranlib = arch + 'ranlib'
objcopy = arch + 'objcopy'
strip = arch + 'strip'
pkgconfig = 'pkg-config'

[host_machine]
system = 'linux'
cpu_family = '${cpu_family}'
cpu = '${cpu}'
endian = '${endian}'
EOF

fi
