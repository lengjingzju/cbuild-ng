#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

patch_opt=$1
patch_src=$2
patch_dst=$3
patch_arr=""

if [ -e ${patch_dst} ]; then
    for src in ${patch_src}; do
        if [ -d ${src} ]; then
            for ssrc in $(\ls ${src}); do
                if [ $(echo ${ssrc} | grep -c '\.patch$') -eq 1 ]; then
                    patch_arr="${patch_arr} ${src}/${ssrc}"
                fi
            done
        elif [ -f ${src} ]; then
            patch_arr="${patch_arr} ${src}"
        else
            echo "Warning: ${src} is unexisted."
        fi
    done

    for src in ${patch_arr}; do
        patch_state="$(patch -p1 -R  -s -f --dry-run -d ${patch_dst} < ${src})"
        if [ ${patch_opt} = "patch" ] && [ ! -z "${patch_state}" ]; then
            patch -p1 -b -d ${patch_dst} < ${src}
            echo "Patch ${src} to ${patch_dst} Done."
        elif [ ${patch_opt} = "unpatch" ] && [ -z "${patch_state}" ]; then
            patch -p1 -R -d ${patch_dst} < ${src}
            echo "Unpatch ${src} to ${patch_dst} Done."
        fi
    done
fi
