#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

mirrortool=${ENV_TOOL_DIR}/process_mirror.py

method=$1
urls=$2
url=$2
branch=
tag=
rev=
md5=
package=$3
outdir=$4
outname=$5
checktool=md5sum
checksuffix=src.hash

urln=$(echo "$urls" | grep -o ';' | wc -l)
if [ $urln -ne 0 ]; then
    url=$(echo "$urls" | cut -d ';' -f 1)
    for i in $(seq 2 $(( $urln+1 ))); do
        item=$(echo "$urls" | cut -d ';' -f $i)
        if [ $(echo "$item" | grep -c '^branch=') -ne 0 ]; then
            branch=$(echo "$item" | sed "s/^branch=//g")
        elif [ $(echo "$item" | grep -c '^tag=') -ne 0 ]; then
            tag=$(echo "$item" | sed "s/^tag=//g")
        elif [ $(echo "$item" | grep -c '^rev=') -ne 0 ]; then
            rev=$(echo "$item" | sed "s/^rev=//g")
        elif [ $(echo "$item" | grep -c '^md5=') -ne 0 ]; then
            md5=$(echo "$item" | sed "s/^md5=//g")
        fi
    done
fi

usage() {
    echo "Usage: $0 method url package -- only fetch package"
    echo "       $0 method url package outdir outname -- fetch and unpack package"
    echo "       method can be 'zip / tar / git / svn'"
}

do_check() {
    if [ -z $method ] || [ -z "$url" ] || [ -z $package ]; then
        usage
        echo "ERROR: Invalid options." >&2
        exit 1
    fi

    if [ -z "$(which wget)" ]; then
        echo "ERROR: please install wget first." >&2
        exit 1
    fi

    case $method in
        zip|tar)
            ;;
        git)
            if [ -z "$(which git)" ]; then
                echo "ERROR: please install git first." >&2
                exit 1
            fi
            ;;
        svn)
            if [ -z "$(which svn)" ]; then
                echo "ERROR: please install svn first." >&2
                exit 1
            fi
            ;;
        *)
            echo "ERROR: Invalid method($method)." >&2
            usage
            exit 1
            ;;
    esac
}

do_fetch() {
    packname=$package
    if [ $method = git ]; then
        packname=$package-$method-br.$branch-rev.$tag$rev.tar.gz
    elif [ $method = svn ]; then
        packname=$package-$method-rev.$rev.tar.gz
    fi

    if [ ! -e ${ENV_DOWN_DIR}/$package ] || [ ! -e ${ENV_DOWN_DIR}/$package.$checksuffix ]; then
        download_req=1
        if [ "$packname" != "$package" ] && [ -e ${ENV_DOWN_DIR}/$packname ] && [ -e ${ENV_DOWN_DIR}/$package.$checksuffix ]; then
            cd ${ENV_DOWN_DIR}
            tar -xf $packname || rm -rf $packname $package
            if [ -e ${ENV_DOWN_DIR}/$packname ]; then
                download_req=0
                rm -f ${ENV_DOWN_DIR}/$package.$checksuffix
            fi
        fi

        if [ $download_req -eq 1 ]; then
            rm -rf ${ENV_DOWN_DIR}/$package ${ENV_DOWN_DIR}/$packname ${ENV_DOWN_DIR}/$package.$checksuffix
            mkdir -p ${ENV_DOWN_DIR}

            # download package from mirror
            mirror_url=${ENV_MIRROR_URL}/downloads/$packname
            if [ ! -z "${ENV_MIRROR_URL}" ] && [ "$(wget --spider -nv ${mirror_url} 2>&1 | grep -wc 200)" = "1" ]; then
                echo -e "\033[32mwget ${mirror_url} to ${ENV_DOWN_DIR}/$packname\033[0m"
                wget -q ${mirror_url} -O ${ENV_DOWN_DIR}/$packname --no-check-certificate
                if [ "$packname" != "$package" ]; then
                    cd ${ENV_DOWN_DIR}
                    tar -xf $packname || rm -rf $packname $package
                else
                    if [ ! -z "$md5" ]; then
                        rmd5=$(md5sum ${ENV_DOWN_DIR}/$packname | cut -d ' ' -f 1)
                        if [ "$md5" != "$rmd5" ]; then
                            rm -f ${ENV_DOWN_DIR}/$packname
                        fi
                    fi
                fi
            fi
        fi

        case $method in
            zip|tar)
                if [ ! -e ${ENV_DOWN_DIR}/$package ]; then
                    for murl in $(python3 $mirrortool $url); do
                        echo -e "\033[32mwget $murl to ${ENV_DOWN_DIR}/$package\033[0m"
                        wget -q -t 3 -T 15 $murl -O ${ENV_DOWN_DIR}/$package --no-check-certificate
                        if [ $? -ne 0 ]; then
                            rm -f ${ENV_DOWN_DIR}/$package
                            echo "Failed to download $murl"
                        else
                            break
                        fi
                    done

                    if [ ! -e ${ENV_DOWN_DIR}/$package ]; then
                        echo "ERROR: failed to download $url" >&2
                        exit 1
                    fi
                fi

                if [ ! -z "$md5" ]; then
                    rmd5=$(md5sum ${ENV_DOWN_DIR}/$package | cut -d ' ' -f 1)
                    if [ "$md5" != "$rmd5" ]; then
                        rm -f ${ENV_DOWN_DIR}/$package
                        echo "ERROR: md5sum of $package: set($md5)!=actual($rmd5)" >&2
                        exit 1
                    fi
                fi
                $checktool ${ENV_DOWN_DIR}/$package | cut -d ' ' -f 1 > ${ENV_DOWN_DIR}/$package.$checksuffix
                ;;

            git)
                if [ ! -e ${ENV_DOWN_DIR}/$packname ]; then
                    echo -e "\033[32mgit clone $url to ${ENV_DOWN_DIR}/$package\033[0m"
                    git clone $url ${ENV_DOWN_DIR}/$package
                    if [ $? -ne 0 ]; then
                        rm -rf ${ENV_DOWN_DIR}/$package
                        echo "ERROR: failed to clone git $url" >&2
                        exit 1
                    fi
                    if [ "$branch-$tag-$rev" != "--" ]; then
                        cd ${ENV_DOWN_DIR}/$package
                        if [ ! -z "$branch" ]; then
                            git checkout -q $branch
                            if [ $? -ne 0 ]; then
                                echo "ERROR: failed to checkout branch ($branch) of $package." >&2
                                exit 1
                            fi
                        fi
                        if [ ! -z "$tag" ]; then
                            git reset -q --hard $tag
                            if [ $? -ne 0 ]; then
                                echo "ERROR: failed to reset tag ($tag) of $package." >&2
                                exit 1
                            fi
                        fi
                        if [ ! -z "$rev" ]; then
                            git reset -q --hard $rev
                            if [ $? -ne 0 ]; then
                                echo "ERROR: failed to reset rev ($rev) of $package." >&2
                                exit 1
                            fi
                        fi
                    fi
                    cd ${ENV_DOWN_DIR} && tar -zcf $packname $package
                else
                    if [ "$tag-$rev" = "-" ]; then
                        cd ${ENV_DOWN_DIR}/$package
                        rev1=$(git log -1 --pretty=format:%H)
                        git pull -q
                        rev2=$(git log -1 --pretty=format:%H)
                        if [ "$rev1" != "$rev2" ]; then
                            cd ${ENV_DOWN_DIR} && rm -f $packname && tar -zcf $packname $package
                        fi
                    fi
                fi
                echo -n "$(cd ${ENV_DOWN_DIR}/$package && git log -1 --pretty=format:%H)" > ${ENV_DOWN_DIR}/$package.$checksuffix
                ;;

            svn)
                if [ ! -e ${ENV_DOWN_DIR}/$packname ]; then
                    echo -e "\033[32msvn checkout $url to ${ENV_DOWN_DIR}/$package\033[0m"
                    svn checkout -q $url ${ENV_DOWN_DIR}/$package
                    if [ $? -ne 0 ]; then
                        rm -rf ${ENV_DOWN_DIR}/$package
                        echo "ERROR: failed to checkout svn $url" >&2
                        exit 1
                    fi
                    if [ ! -z "$rev" ]; then
                        svn update -q -r $rev
                        if [ $? -ne 0 ]; then
                            echo "ERROR: failed to update rev ($rev) of $package." >&2
                            exit 1
                        fi
                    fi
                    cd ${ENV_DOWN_DIR} && tar -zcf $packname $package
                else
                    if [ -z "$rev" ]; then
                        cd ${ENV_DOWN_DIR}/$package
                        rev1=$(svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')
                        svn update -q
                        rev2=$(svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')
                        if [ "$rev1" != "$rev2" ]; then
                            cd ${ENV_DOWN_DIR} && rm -f $packname && tar -zcf $packname $package
                        fi
                    fi
                fi
                echo -n "$(cd ${ENV_DOWN_DIR}/$package && svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')" > ${ENV_DOWN_DIR}/$package.$checksuffix
                ;;

            *)
                ;;
        esac

    else

        case $method in
            git)
                cd ${ENV_DOWN_DIR}/$package
                if [ -z "$branch" ]; then
                    branch=$(git branch -a | grep 'HEAD' | awk -F '/' '{print $NF}')
                fi
                rbranch=$(git symbolic-ref -q --short HEAD)

                changed=0
                if [ "$branch" != "$rbranch" ]; then
                    changed=1
                    rm -rf ${ENV_DOWN_DIR}/$packname ${ENV_DOWN_DIR}/$package.$checksuffix
                    git pull -q
                    git checkout -q $branch
                    if [ $? -ne 0 ]; then
                        echo "ERROR: failed to checkout branch ($branch) of $package." >&2
                        exit 1
                    fi
                fi

                if [ "$tag-$rev" = "-" ]; then
                    rev1=$(git log -1 --pretty=format:%H)
                    git pull -q
                    rev2=$(git log -1 --pretty=format:%H)
                    if [ "$rev1" != "$rev2" ]; then
                        changed=1
                        rm -rf ${ENV_DOWN_DIR}/$packname ${ENV_DOWN_DIR}/$package.$checksuffix
                    fi
                else
                    rrev=$(git log -1 --pretty=format:%H)
                    rtag=$(git show-ref --tags -d | grep "$rrev" | cut -d ' ' -f 2 | sed -e 's:^refs/tags/::g' -e 's:\^{}::g')
                    if [ ! -z "$tag" ] && [ "$tag" != "$rtag" ]; then
                        changed=1
                        rm -rf ${ENV_DOWN_DIR}/$packname ${ENV_DOWN_DIR}/$package.$checksuffix
                        git pull -q
                        git reset -q --hard $tag
                        if [ $? -ne 0 ]; then
                            echo "ERROR: failed to reset tag ($tag) of $package." >&2
                            exit 1
                        fi
                    elif [ ! -z "$rev" ] && [ "$rev" != "$rrev" ]; then
                        changed=1
                        rm -rf ${ENV_DOWN_DIR}/$packname ${ENV_DOWN_DIR}/$package.$checksuffix
                        git pull -q
                        git reset -q --hard $rev
                        if [ $? -ne 0 ]; then
                            echo "ERROR: failed to reset tag ($tag) of $package." >&2
                            exit 1
                        fi
                    fi
                fi

                if [ $changed -ne 0 ]; then
                    cd ${ENV_DOWN_DIR} && tar -zcf $packname $package
                    echo -n "$(cd ${ENV_DOWN_DIR}/$package && git log -1 --pretty=format:%H)" > ${ENV_DOWN_DIR}/$package.$checksuffix
                fi
                ;;

            svn)
                if [ ! -z "$rev" ]; then
                    cd ${ENV_DOWN_DIR}/$package
                    rrev=$(svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')

                    if [ "$rev" != "$rrev" ]; then
                        rm -rf ${ENV_DOWN_DIR}/$packname ${ENV_DOWN_DIR}/$package.$checksuffix
                        svn update -q
                        svn update -q -r $rev
                        if [ $? -ne 0 ]; then
                            echo "ERROR: failed to update rev ($rev) of $package." >&2
                            exit 1
                        fi
                        cd ${ENV_DOWN_DIR} && tar -zcf $packname $package
                        echo -n "$(cd ${ENV_DOWN_DIR}/$package && svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')" > ${ENV_DOWN_DIR}/$package.$checksuffix
                    fi
                else
                    cd ${ENV_DOWN_DIR}/$package
                    rev1=$(svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')
                    svn update -q
                    rev2=$(svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')
                    if [ "$rev1" != "$rev2" ]; then
                        cd ${ENV_DOWN_DIR} && rm -f $packname && tar -zcf $packname $package
                        echo -n "$(cd ${ENV_DOWN_DIR}/$package && svn log -l 1 | sed -n '2p' | sed -E 's/^r([0-9]+)\s.*/\1/g')" > ${ENV_DOWN_DIR}/$package.$checksuffix
                    fi
                fi
                ;;
            *)
                ;;
        esac
    fi
}

do_unpack() {
    if [ ! -e $outdir/$outname ] || [ ! -e $outdir/$outname.$checksuffix ] || \
        [ "$(cat ${ENV_DOWN_DIR}/$package.$checksuffix)" != "$(cat $outdir/$outname.$checksuffix)" ]; then
            rm -rf $outdir/$outname $outdir/$outname.$checksuffix
            mkdir -p $outdir

            case $method in
                zip)
                    echo -e "\033[32munzip ${ENV_DOWN_DIR}/$package to $outdir\033[0m"
                    unzip -q ${ENV_DOWN_DIR}/$package -d $outdir
                    if [ $? -ne 0 ]; then
                        rm -rf ${ENV_DOWN_DIR}/$package ${ENV_DOWN_DIR}/$package.$checksuffix
                        echo "ERROR: ${ENV_DOWN_DIR}/$package is invalid zip file." >&2
                        exit 1
                    fi
                    ;;
                tar)
                    echo -e "\033[32muntar ${ENV_DOWN_DIR}/$package to $outdir\033[0m"
                    tar -xf ${ENV_DOWN_DIR}/$package -C $outdir
                    if [ $? -ne 0 ]; then
                        rm -rf ${ENV_DOWN_DIR}/$package ${ENV_DOWN_DIR}/$package.$checksuffix
                        echo "ERROR: ${ENV_DOWN_DIR}/$package is invalid tar file." >&2
                        exit 1
                    fi
                    ;;
                git|svn)
                    echo -e "\033[32mcopy ${ENV_DOWN_DIR}/$package to $outdir\033[0m" >&2
                    cp -rfp ${ENV_DOWN_DIR}/$package $outdir
                    ;;
                *)
                    ;;
            esac

            cp -fp ${ENV_DOWN_DIR}/$package.$checksuffix $outdir/$outname.$checksuffix
    fi
}

exec_main() {
    do_check
    do_fetch
    if [ ! -z $outdir ] && [ ! -z $outname ]; then
        do_unpack
    fi
}

exec_main
