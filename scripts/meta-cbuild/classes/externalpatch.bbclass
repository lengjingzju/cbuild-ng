############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

LICENSE ?= "CLOSED"
LIC_FILES_CHKSUM ?= ""
SRC_URI = ""
DEPENDS:append = " patch-native"

do_configure () {
    :
}

python do_compile () {
    import subprocess
    patch_opt = d.getVar('EXTERNALPATCH_OPT')
    patch_src = [t for t in d.getVar('EXTERNALPATCH_SRC').split() if os.path.exists(t)]
    patch_dst = d.getVar('EXTERNALPATCH_DST')
    patch_arr = []

    if os.path.exists(patch_dst):
        for src in patch_src:
            if os.path.isdir(src):
                patch_arr += [os.path.join(src, t) for t in os.listdir(src) if t.endswith('.patch')]
            else:
                patch_arr.append(src)

        for src in patch_arr:
            patch_state = subprocess.getstatusoutput('patch -p1 -R -s -f --dry-run -d %s < %s' % (patch_dst, src))[0]
            if (patch_opt == 'patch' and patch_state != 0) or (patch_opt == 'unpatch' and patch_state == 0):
                patch_cmd = 'patch -p1 -%s -d %s < %s' % ('b' if patch_opt == 'patch' else 'R', patch_dst, src)
                bb.plain('NOTE: %s %s to %s' % (patch_opt, src, patch_dst))
                subprocess.getstatusoutput(patch_cmd)
}

do_install () {
    :
}

python () {
    import subprocess
    patch_opt = d.getVar('EXTERNALPATCH_OPT')
    patch_src = [t for t in d.getVar('EXTERNALPATCH_SRC').split() if os.path.exists(t)]
    patch_dst = d.getVar('EXTERNALPATCH_DST')
    patch_arr = []

    if os.path.exists(patch_dst):
        for src in patch_src:
            if os.path.isdir(src):
                d.appendVarFlag('do_compile', 'file-checksums', ' %s/*:True' % (src))
                patch_arr += [os.path.join(src, t) for t in os.listdir(src) if t.endswith('.patch')]
            else:
                d.appendVarFlag('do_compile', 'file-checksums', ' %s:True' % (src))
                patch_arr.append(src)

        for src in patch_arr:
            patch_state = subprocess.getstatusoutput('patch -p1 -R -s -f --dry-run -d %s < %s' % (patch_dst, src))[0]
            if (patch_opt == 'patch' and patch_state != 0) or (patch_opt == 'unpatch' and patch_state == 0):
                d.setVarFlag('do_compile', 'nostamp', '1')
                break
}

ALLOW_EMPTY:${PN} = "1"
