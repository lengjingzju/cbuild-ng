#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

package=$1
outdir=$2
targetpath=$3
confpath=$4
if [ ! -z "$5" ]; then
    corepkgs=":$5:"
else
    corepkgs=""
fi
corecheck=1
coreexist=" "
dones=" "

if [ -z `which dot` ]; then
    echo -e "\033[31mERROR: Please install graphviz first (sudo apt install graphviz).\033[0m"
    exit 1
fi

if [ ! -e ${outdir} ]; then
    mkdir -p ${outdir}
fi

if [ ! -e ${targetpath} ]; then
    echo -e "\033[31mERROR: ${targetpath} is not existed.\033[0m"
    exit 1
fi

if [ ! -e ${confpath} ]; then
    echo -e "\033[31mERROR: ${confpath} is not existed.\033[0m"
    exit 1
fi

write_rule() {
    target=$1
    tofile=$2
    if [ ! -z "${target}" ]; then
        depstr=$(cat ${targetpath} | grep "^${target}=\".*\"")
        if [ ! -z "${depstr}" ]; then
            deps=$(echo "${depstr}" | sed -E "s/^${target}=\"(.*)\" # .*/\1/g")
            if [ ! -z "${deps}" ]; then
                for dep in ${deps}; do
                    style1=""
                    label1=""
                    color1=""
                    style2=""
                    label2=""
                    color2=""
                    headchar=${dep:0:1}
                    condition=""

                    if [ "${headchar}" = "?" ] || [ "${headchar}" = "|" ]; then
                        dep=${dep:1}
                    elif [ $(echo "${dep}" | grep -c "@") -ne 0 ]; then
                        headchar="@"
                        condition=$(echo "${dep}" | cut -d '@' -f 2)
                        dep=$(echo "${dep}" | cut -d '@' -f 1)
                    else
                        headchar=""
                    fi

                    DEP=$(echo "${dep}" | tr 'a-z-' 'A-Z_')
                    if [ $(grep -c "^CONFIG_${DEP}=y" ${confpath}) -eq 1 ]; then
                        style1="solid"
                        color1="green"
                    else
                        style1="dashed"
                        color1="red"
                    fi

                    if [ "${headchar}" = "?" ]; then
                        style1="dashed"
                    elif [ "${headchar}" = "|" ]; then
                        if [ $(echo "${dep}" | grep -c "\-patch\-") -eq 0 ]; then
                            label1="srcbuild"
                            label2="prebuild"
                            DEP="PREBUILD_${DEP}"
                        else
                            label1="patch"
                            label2="unpatch"
                            DEP=$(echo "${DEP}" | sed 's/_PATCH_/_UNPATCH_/g')
                        fi

                        if [ $(grep -c "^CONFIG_${DEP}=y" ${confpath}) -eq 1 ]; then
                            style2="solid"
                            color2="green"
                        else
                            style2="dashed"
                            color2="red"
                        fi
                    elif [ "${headchar}" = "@" ]; then
                        style1="dashed"
                        label1="${condition}"
                        if [ "${color1}" = "green" ] && [ $(grep -c "^${condition}=y" ${confpath}) -eq 0 ]; then
                            color1="red"
                        fi
                    else
                        style1="solid"
                    fi

                    if [ ! -z "${corepkgs}" ]; then
                        if [ $(echo "${corepkgs}" | grep -c ":${dep}:") -ne 0 ]; then
                            if [ ${corecheck} -eq 1 ]; then
                                if [ $(echo "${coreexist}" | grep -c " ${dep} ") -eq 0 ]; then
                                    coreexist="${coreexist}${dep} "
                                fi
                            else
                                continue
                            fi
                        fi
                    fi

                    attr="style = ${style1}, color = ${color1}"
                    if [ ! -z "${label1}" ]; then
                        attr="${attr}, label = \"${label1}\""
                    fi
                    echo "\"${target}\" -> \"${dep}\" [${attr}]" >> ${tofile}

                    if [ "${headchar}" = "|" ]; then
                        attr="style = ${style2}, color = ${color2}"
                        if [ ! -z "${label2}" ]; then
                            attr="${attr}, label = \"${label2}\""
                        fi
                        echo "\"${target}\" -> \"${dep}\" [${attr}]" >> ${tofile}
                    fi
                done

                for dep in ${deps}; do
                    if [ ${dep:0:1} = "?" ] || [ ${dep:0:1} = "|" ]; then
                        dep=${dep:1}
                    elif [ $(echo "${dep}" | grep -c "@") -ne 0 ]; then
                        dep=$(echo "${dep}" | cut -d '@' -f 1)
                    fi
                    if [ $(echo "${dones}" | grep -c " ${dep} ") -eq 0 ]; then
                        dones="${dones}${dep} "
                        if [ ! -z "${corepkgs}" ]; then
                            if [ $(echo "${corepkgs}" | grep -c ":${dep}:") -ne 0 ]; then
                                if [ ${corecheck} -eq 0 ]; then
                                    continue
                                fi
                            fi
                        fi
                        write_rule ${dep} ${tofile}
                    fi
                done
            fi
        fi
    fi
}

echo "digraph depends {" > ${outdir}/${package}.dot
echo "rankdir=LR" >> ${outdir}/${package}.dot
if [ "${ENV_BUILD_MODE}" = "yocto" ]; then
    bitbake -g -I .*-native$ ${package} || exit 1
    cat task-depends.dot | \
        grep '".*\.do_prepare_recipe_sysroot" -> ".*\.do_populate_sysroot"' | \
        grep -v gcc | \
        grep -v glibc | \
        sed -E 's/"(.*)\.do_prepare_recipe_sysroot" -> "(.*)\.do_populate_sysroot"/"\1" -> "\2"/g' > ${outdir}/${package}.dot.tmp

    items=" ${package} "
    for item in $(cat ${outdir}/${package}.dot.tmp | sed -E 's/"(.*)" -> "(.*)"/\1 \2/g' | xargs); do
        if [ $(echo "${items}" | grep -c " ${item} ") -eq 0 ]; then
            items="${items}${item} "
        fi
    done
    users=" $(cat ${targetpath} | grep -v "# localsrc$" | cut -d '=' -f 1 | xargs) "

    for item in ${items}; do
        if [ $(echo "${users}" | grep -c " ${item} ") -eq 0 ]; then
            echo "\"${item}\" [color = blue]" >> ${outdir}/${package}.dot
        else
            ITEM=$(echo "${item}" | tr 'a-z-' 'A-Z_')
            if [ $(grep -c "^CONFIG_${ITEM}=y" ${confpath}) -eq 1 ]; then
                echo "\"${item}\" [color = green]" >> ${outdir}/${package}.dot
            else
                echo "\"${item}\" [color = red]" >> ${outdir}/${package}.dot
            fi
        fi
    done
    cat ${outdir}/${package}.dot.tmp >> ${outdir}/${package}.dot
    rm ${outdir}/${package}.dot.tmp
else

    PACKAGE=$(echo "${package}" | tr 'a-z-' 'A-Z_')
    if [ $(grep -c "^CONFIG_${PACKAGE}=y" ${confpath}) -eq 1 ]; then
        echo "\"${package}\" [color = green]" >> ${outdir}/${package}.dot
    else
        echo "\"${package}\" [color = red]" >> ${outdir}/${package}.dot
    fi
    write_rule ${package} ${outdir}/${package}.dot
fi
echo "}" >> ${outdir}/${package}.dot

dot -Tsvg -o ${outdir}/${package}.svg ${outdir}/${package}.dot
dot -Tpng -o ${outdir}/${package}.png ${outdir}/${package}.dot
echo -e "\033[32mNote: ${package}.dot ${package}.svg and ${package}.png are generated in the ${outdir} folder.\033[0m"

if [ "${coreexist}" != " " ]; then
    corecheck=0
    dones=" "

    echo "digraph depends {" > ${outdir}/${package}.brief.dot
    echo "rankdir=LR" >> ${outdir}/${package}.brief.dot
    PACKAGE=$(echo "${package}" | tr 'a-z-' 'A-Z_')
    if [ $(grep -c "^CONFIG_${PACKAGE}=y" ${confpath}) -eq 1 ]; then
        echo "\"${package}\" [color = green]" >> ${outdir}/${package}.brief.dot
    else
        echo "\"${package}\" [color = red]" >> ${outdir}/${package}.brief.dot
    fi
    write_rule ${package} ${outdir}/${package}.brief.dot
    echo "label = \"Note: drop the relationships of " ${coreexist} "\"" >> ${outdir}/${package}.brief.dot
    echo "}" >> ${outdir}/${package}.brief.dot

    dot -Tsvg -o ${outdir}/${package}.brief.svg ${outdir}/${package}.brief.dot
    dot -Tpng -o ${outdir}/${package}.brief.png ${outdir}/${package}.brief.dot
    echo -e "\033[32mNote: ${package}.brief.dot ${package}.brief.svg and ${package}.brief.png are generated in the ${outdir} folder.\033[0m"
fi
