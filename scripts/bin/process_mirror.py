############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

import sys, os

DEF_MIRROR_DICT = {
    "https://ftp.gnu.org/gnu/": [
        "https://mirrors.ustc.edu.cn/gnu/",
        "https://mirrors.aliyun.com/gnu/"
    ],
    "https://www.kernel.org/pub/": [
        "https://mirrors.ustc.edu.cn/kernel.org/"
    ]
}

def get_mirror_urls(url, cfg = ""):
    ulist = []
    udict = {}

    if cfg:
        if os.path.exists(cfg):
            with open(cfg, "r") as fp:
                try:
                    udict = eval(fp.read())
                except:
                    pass
    else:
        udict = DEF_MIRROR_DICT

    for key in udict.keys():
        num = len(key)
        if key == url[:num]:
            t = url[num:]
            ulist += [v + t for v in udict[key]]

    ulist.append(url)
    print(' '.join(ulist))


if __name__ == '__main__':
    if len(sys.argv) == 2:
        get_mirror_urls(sys.argv[1])
    elif len(sys.argv) == 3:
        get_mirror_urls(sys.argv[1], cfg = sys.argv[2])
    else:
        print("Usage: %s <url> [cfg_file]" % (sys.argv[0]))

