#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

opt=$1
src=$2
dst=$3
pkg=$4
lic="$5"

usage() {
    echo "Usage: $0 <opt> <src> <dst> <pkg> <lic>; and opt can be:"
    echo "    link: link all files in src sysroot to dst sysroot"
    echo "    install: copy all files in src sysroot to dst sysroot"
    echo "    release: copy all files except headers and static libraries in src sysroot to dst sysroot"
    echo "    replace: replace \${src} to \${DEP_PREFIX} of all pkgconfig files in src sysroot"
    echo "    license: cp license files to dst sysroot, <pkg> and <lic> are only for license"
}

link_sysroot() {
    local s=$1
    local d=$2
    local v=

    mkdir -p $d
    for v in $(ls $s); do
        if [ -d $s/$v ] && [ ! -L $s/$v ]; then
            case $v in
                locale|man|info|doc)
                    if [ $(echo $s | grep -c '/share$') -eq 1 ]; then
                        continue
                    fi
                    ;;
                terminfo)
                    if [ $(echo $s | grep -c '/share$\|/lib$') -eq 1 ]; then
                        ln -sfT $s/$v $d/$v
                        continue
                    fi
                    ;;
            esac
            link_sysroot $s/$v $d/$v
        else
            if [ $(echo $v | grep -c '\.pc$') -eq 1 ]; then
                cp -df $s/$v $d/$v
                sed -i "s@\${DEP_PREFIX}@${dst}@g" $d/$v
            else
                ln -sfT $s/$v $d/$v
            fi
        fi
    done
}

install_sysroot() {
    local s=$1
    local d=$2
    local v=

    mkdir -p $d
    for v in $(ls $s); do
        if [ -d $s/$v ] && [ ! -L $s/$v ]; then
            case $v in
                include)
                    mkdir -p $d/$v
                    cp -drfp $s/$v/* $d/$v
                    ;;
                bin|sbin|libexec)
                    mkdir -p $d/$v
                    cp -drf $s/$v/* $d/$v
                    ;;
                etc|srv|com|var|run)
                    if [ "$s" == "$src" ]; then
                        mkdir -p $d/$v
                        cp -drf $s/$v/* $d/$v
                    else
                        install_sysroot $s/$v $d/$v
                    fi
                    ;;
                locale|man|info|doc)
                    if [ $(echo $s | grep -c '/share$') -eq 1 ]; then
                        mkdir -p $d/$v
                        cp -drf $s/$v/* $d/$v
                    else
                        install_sysroot $s/$v $d/$v
                    fi
                    ;;
                terminfo)
                    # for ncurses
                    if [ $(echo $s | grep -c '/share$\|/lib$') -eq 1 ]; then
                        mkdir -p $d/$v
                        cp -drf $s/$v/* $d/$v
                    else
                        install_sysroot $s/$v $d/$v
                    fi
                    ;;
                *)
                    install_sysroot $s/$v $d/$v
                    ;;
            esac
        else
            cp -df $s/$v $d/$v
            if [ $(echo $v | grep -c '\.pc$') -eq 1 ]; then
                sed -i "s@\${DEP_PREFIX}@${dst}@g" $d/$v
            fi
        fi
    done
}

release_sysroot_with_check() {
    local s=$1
    local d=$2
    local v=

    mkdir -p $d
    for v in $(ls $s); do
        if [ -d $s/$v ] && [ ! -L $s/$v ]; then
            case $v in
                include)
                    continue
                    ;;
                pkgconfig|aclocal|cmake)
                    continue
                    ;;
                locale|man|info|doc)
                    if [ $(echo $s | grep -c '/share$') -eq 1 ]; then
                        continue
                    fi
                    ;;
            esac
            release_sysroot_with_check $s/$v $d/$v
        else
            if [ $(echo $v | grep -Ec '\.l?a$') -eq 0 ]; then
                if [ -e $d/$v ]; then
                    echo "        $d/$v # already existed"
                else
                    echo "        $d/$v"
                fi
                cp -df $s/$v $d/$v
            fi
        fi
    done
}

release_sysroot_without_check() {
    local s=$1
    local d=$2
    local v=

    mkdir -p $d
    for v in $(ls $s); do
        if [ -d $s/$v ] && [ ! -L $s/$v ]; then
            case $v in
                include)
                    ;;
                pkgconfig|aclocal|cmake)
                    ;;
                bin|sbin|libexec)
                    mkdir -p $d/$v
                    cp -drf $s/$v/* $d/$v
                    ;;
                etc|srv|com|var|run)
                    if [ "$s" == "$src" ]; then
                        mkdir -p $d/$v
                        cp -drf $s/$v/* $d/$v
                    else
                        release_sysroot_without_check $s/$v $d/$v
                    fi
                    ;;
                locale|man|info|doc)
                    if [ $(echo $s | grep -c '/share$') -eq 1 ]; then
                        mkdir -p $d/$v
                        cp -drf $s/$v/* $d/$v
                    else
                        release_sysroot_without_check $s/$v $d/$v
                    fi
                    ;;
                terminfo)
                    # for ncurses
                    if [ $(echo $s | grep -c '/share$\|/lib$') -eq 1 ]; then
                        mkdir -p $d/$v
                        cp -drf $s/$v/* $d/$v
                    else
                        release_sysroot_without_check $s/$v $d/$v
                    fi
                    ;;
                *)
                    release_sysroot_without_check $s/$v $d/$v
                    ;;
            esac
        else
            if [ $(echo $v | grep -Ec '\.l?a$') -eq 0 ]; then
                if [ -e $d/$v ]; then
                    echo "        WARNING: $d/$v is already existed"
                fi
                cp -df $s/$v $d/$v
            fi
        fi
    done
}

release_sysroot() {
    if [ -z "${ENV_BUILD_FLAGS}" ]; then
        release_sysroot_with_check $1 $2
    else
        release_sysroot_without_check $1 $2
    fi
}

replace_pkgconfig() {
    pcs="$(find $src -name '*.pc' | xargs)"
    if [ ! -z "$pcs" ]; then
        sed -i "s@${src}@\${DEP_PREFIX}@g" $pcs
    fi
}

install_license() {
    lic_srcdir=$1
    lic_dstdir=$2/usr/share/license
    package=$3
    license=$(echo "$4" | sed 's/;/@semicolon@/g')

    for item in ${license}; do
        if [ $(echo "${item}" | grep -c '^file://') -eq 1 ]; then
            lic_src=''
            lic_dst=''
            lic_begin=0
            lic_end=0

            for slice in $(echo "${item}" | sed 's/@semicolon@/ /g'); do
                if [ $(echo "${slice}" | grep -c '^file://') -eq 1 ]; then
                    lic_src=$(echo "${slice}" | sed 's|^file://||g')
                    lic_dst=$(echo "${slice}" | xargs basename)
                elif [ $(echo "${slice}" | grep -c '^line=') -eq 1 ]; then
                    lic_begin=$(echo "${slice}" | sed 's|^line=||g' | cut -d '-' -f 1)
                    lic_end=$(echo "${slice}" | sed 's|^line=||g' | cut -d '-' -f 2)
                fi
            done

            mkdir -p ${lic_dstdir}/${package}
            if [ ${lic_begin} -eq 0 ] || [ ${lic_end} -eq 0 ]; then
                cp -df ${lic_srcdir}/${lic_src} ${lic_dstdir}/${package}/${lic_dst}
            else
                sed -n "${lic_begin},${lic_end} p" ${lic_srcdir}/${lic_src} > ${lic_dstdir}/${package}/${lic_dst}
            fi

        elif [ $(echo "${item}" | grep -c '^common://') -eq 1 ]; then
            lic_src=$(echo "${item}" | sed 's|common://||g')
            mkdir -p ${lic_dstdir}
            ln -sf common/${lic_src} ${lic_dstdir}/${package}
        fi
    done
}

if [ -z "$src" ]; then
    usage
    exit 1
fi

if [ ! -e $src ]; then
    exit 0
fi

case $opt in
    link) link_sysroot $src $dst;;
    install) install_sysroot $src $dst;;
    release) release_sysroot $src $dst;;
    replace) replace_pkgconfig;;
    license) install_license $src $dst $pkg "$lic";;
    *) usage; exit 1;;
esac
