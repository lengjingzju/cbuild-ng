#!/bin/bash

if [ "$1" = "pack" ]; then
    rm -f $2.cpk $2.tar
    tar -cf $2.tar -C $2 .
    if [ $? -ne 0 ]; then
        echo -e "\033[31mERROR: tar $2 failed.\033[0m"
        exit 1
    fi

    sed "s/^#pkgdir=sed_cmd$/pkgdir=$(basename $2)/g" $0 | cat - $2.tar > $2.cpk
    chmod +x $2.cpk
    rm -f $2.tar

    echo -e "\033[32mCPK is packed to $2.cpk\033[0m"
    exit 0
fi

pkgdir=`basename $0`
if [ $(echo $pkgdir | grep -c '_') -ne 0 ]; then
    pkgdir=$(echo $pkgdir | cut -d '_' -f 1)
else
    pkgdir=$(echo $pkgdir | cut -d '.' -f 1)
fi
#pkgdir=sed_cmd

defdir=/home/$USER/.cpk/$pkgdir
insdir=$1

if [ -z "$insdir" ]; then
    read -p "Please set the installation directory ($defdir): " insdir
    if [ -z "$insdir" ]; then
        insdir=$defdir
    fi
fi
if [ "$insdir" = "def" ] ||  [ "$insdir" = "default" ]; then
    insdir=$defdir
fi

if [ -e $insdir ]; then
    if [ "$(basename $insdir)" == "$pkgdir" ]; then
        choice=$2
        if [ -z "$choice" ]; then
            read -p "Delete the original app [$insdir] first? (y or n): " choice
            if [ -z "$choice" ]; then
                choice=n
            fi
            echo -e "\033[43mYour choice is $choice\033[0m"
        fi
        if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
            rm -rf $insdir/*
        fi
    fi
fi

if [ ! -e $insdir ]; then
    mkdir -p $insdir
    if [ $? -ne 0 ]; then
        echo -e "\033[31mERROR: mkdir $insdir failed.\033[0m"
        exit 1
    fi
fi

sed '1,/^#END$/d' $0 > $insdir/tmp.tar
tar -xf $insdir/tmp.tar -C $insdir
if [ $? -ne 0 ]; then
    rm -f $insdir/tmp.tar
    echo -e "\033[31mERROR: untar $0 failed.\033[0m"
    exit 1
fi
rm -f $insdir/tmp.tar

if [ -e $insdir/update.sh ]; then
    bash $insdir/update.sh
    if [ $? -ne 0 ]; then
        echo -e "\033[31mERROR: run $insdir/update.sh failed.\033[0m"
        exit 1
    fi
fi

echo -e "\033[32mSuccessfully installed to $insdir\033[0m"
exit 0
#END
