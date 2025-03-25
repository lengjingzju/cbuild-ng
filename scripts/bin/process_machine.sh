#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

choice=$1
soc=${ENV_BUILD_SOC}
if [ -z "$soc" ]; then
    soc="$2"
fi

cpu=
machine=
arch=
cpu_family=
endian=
simd=

cross_target=
toolchain=
gcc_arch_option=

linux_arch=
linux_src=
linux_out=
linux_version=6.6.77

gcc_version=14.2.0

if [ ! -z $soc ]; then
    case $soc in
        'cortex-a76.cortex-a55' | 'cortex-a75.cortex-a55' | 'cortex-a78' | 'cortex-a77' | 'cortex-a76' | 'cortex-a75' | 'cortex-a55')
            machine=qemuarm64
            cpu=$soc
            arch=armv8.2-a
            gcc_arch_option="--with-arch=$arch --with-tune=$cpu --with-cpu=$cpu"
            ;;

        'cortex-a73.cortex-a53' | 'cortex-a72.cortex-a53' | 'cortex-a72.cortex-a35' | 'cortex-a57.cortex-a53' | 'cortex-a73' | 'cortex-a72' | 'cortex-a57' | 'cortex-a53' | 'cortex-a35')
            machine=qemuarm64
            cpu=$soc
            arch=armv8-a
            gcc_arch_option="--with-arch=$arch --with-cpu=$cpu"
            ;;

        'cortex-a17.cortex-a7' | 'cortex-a15.cortex-a7' | 'cortex-a17' | 'cortex-a15' | 'cortex-a9' | 'cortex-a7' | 'cortex-a5')
            machine=qemuarm
            cpu=$soc
            arch=armv7-a
            gcc_arch_option="--with-arch=$arch --with-tune=$cpu --with-fpu=neon --with-float=hard"
            ;;

        *)
            echo "ERROR: $0: Invalid soc ($soc)"
            exit 1;
            ;;
    esac


    case $arch in
        'armv8-a' | 'armv8.2-a')
            cpu_family=aarch64
            endian=little
            simd=neon
            linux_arch=arm64
            cross_target=aarch64-linux-gnu
            ;;
        'armv7-a')
            cpu_family=arm
            endian=little
            linux_arch=arm
            cross_target=arm-linux-gnueabihf
            ;;
        *)
            echo "ERROR: $0: Invalid arch ($arch) for soc ($soc)"
            exit 1;
            ;;
    esac
fi

get_build_jobs() {
    build_jobs=1
    total_cpus=`nproc`

    if [ ${total_cpus} -ge 32 ]; then
        build_jobs=$(( (${total_cpus} + 3) / 4 ))
    elif [ ${total_cpus} -ge 16 ]; then
        build_jobs=$(( (${total_cpus} + 1) / 2 ))
    elif [ ${total_cpus} -ge 8 ]; then
        build_jobs=8
    else
        build_jobs=${total_cpus}
    fi

    echo $build_jobs
}

case $choice in
    machine)
        echo "$machine"
        ;;
    cpu)
        echo "$cpu"
        ;;
    arch)
        echo "$arch"
        ;;
    cpu_family)
        echo "$cpu_family"
        ;;
    endian)
        echo "$endian"
        ;;
    simd)
        echo "$simd"
        ;;

    cross_target)
        echo "$cross_target"
        ;;
    cross_compile)
        echo "$cross_target-"
        ;;

    linux_arch)
        echo "$linux_arch"
        ;;
    linux_version)
        echo "$linux_version"
        ;;
    linux_src)
        if [ -z "$linux_src" ]; then
            echo "${ENV_TOP_OUT}/kernel/linux-$linux_version"
        else
            echo "$linux_src"
        fi
        ;;
    linux_out)
        if [ -z "$linux_out" ]; then
            echo "${ENV_TOP_OUT}/$soc/objects/linux-$linux_version/build"
        else
            echo "$linux_out"
        fi
        ;;

    gcc_version)
        echo "$gcc_version"
        ;;
    gcc_arch_option)
        echo "$gcc_arch_option"
        ;;
    toolchain_dir)
        echo "$cpu-toolchain-gcc$gcc_version-linux$(echo $linux_version | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)/\1.\2/g')"
        ;;
    toolchain_path)
        echo "${ENV_TOP_OUT}/toolchain"
        ;;
    toolchain)
        if [ -z "$toolchain" ]; then
            echo "${ENV_TOP_OUT}/toolchain/$cpu-toolchain-gcc$gcc_version-linux$(echo $linux_version | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)/\1.\2/g')/bin/$cross_target-"
        else
            echo "$toolchain"
        fi
        ;;

    autotools_cross)
        echo "--host=$cross_target"
        ;;
    cmake_cross)
        echo "-DCMAKE_SYSTEM_PROCESSOR=$cpu_family -DCMAKE_SYSTEM_NAME=Linux"
        ;;
    meson_cross)
        echo "$cross_target- $cpu_family $cpu $endian"
        ;;
    cache_grades)
        echo "$soc $cpu $arch $cpu_family"
        ;;
    build_jobs)
        get_build_jobs
        ;;
    *)
        echo "ERROR: $0: Invalid choice $choice"
        exit 1;
        ;;
esac
