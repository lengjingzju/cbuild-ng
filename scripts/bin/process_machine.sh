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
linux_arch=
cross_target=
gcc_arch_option=

linux_version=6.6.1
gcc_version=13.2.0

if [ ! -z $soc ]; then
    case $soc in
        'cortex-a78')
            machine=qemuarm64
            cpu=cortex-a78
            arch=armv8.2-a
            cpu_family=aarch64
            endian=little
            linux_arch=arm64
            cross_target=aarch64-linux-gnu
            gcc_arch_option="--with-arch=armv8.2-a --with-tune=cortex-a78 --with-cpu=cortex-a78+crypto+dotprod+fp16+rcpc"
            ;;
        'cortex-a76')
            machine=qemuarm64
            cpu=cortex-a76
            arch=armv8.2-a
            cpu_family=aarch64
            endian=little
            linux_arch=arm64
            cross_target=aarch64-linux-gnu
            gcc_arch_option="--with-arch=armv8.2-a --with-tune=cortex-a76 --with-cpu=cortex-a76+crypto+dotprod+fp16+rcpc"
            ;;
        'cortex-a53+crypto')
            machine=qemuarm64
            cpu=cortex-a53+crypto
            arch=armv8-a
            cpu_family=aarch64
            endian=little
            linux_arch=arm64
            cross_target=aarch64-linux-gnu
            gcc_arch_option="--with-arch=armv8-a --with-cpu=cortex-a53+crypto"
            ;;
        'cortex-a53')
            machine=qemuarm64
            cpu=cortex-a53
            arch=armv8-a
            cpu_family=aarch64
            endian=little
            linux_arch=arm64
            cross_target=aarch64-linux-gnu
            gcc_arch_option="--with-arch=armv8-a --with-cpu=cortex-a53"
            ;;
        'cortex-a9')
            machine=qemuarm
            cpu=cortex-a9
            arch=armv7-a
            cpu_family=arm
            endian=little
            linux_arch=arm
            cross_target=arm-linux-gnueabihf
            gcc_arch_option="--with-arch=armv7-a --with-tune=cortex-a9"
            ;;
        *)
            echo "ERROR: $0: Invalid soc $soc"
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
