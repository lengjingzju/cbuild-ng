############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

inherit terminal

export CONF_PATH = "${STAGING_BINDIR_NATIVE}"
DEPENDS:append = " coreutils-native kconfig-native"

KCONFIG_CONFIG_COMMAND ??= "menuconfig"
KCONFIG_DEFCONFIG_COMMAND ??= "defconfig"
KCONFIG_CONFIG_PATH ??= "${WORKDIR}/build/.config"

python do_setrecompile () {
    if hasattr(bb.build, 'write_taint'):
        bb.build.write_taint('do_compile', d)
}

do_setrecompile[nostamp] = "1"
addtask setrecompile

python do_menuconfig() {
    config = d.getVar('KCONFIG_CONFIG_PATH')

    try:
        mtime = os.path.getmtime(config)
    except OSError:
        mtime = 0

    oe_terminal("sh -c \"make %s; if [ \\$? -ne 0 ]; then echo 'Command failed.'; printf 'Press any key to continue... '; read r; fi\"" % d.getVar('KCONFIG_CONFIG_COMMAND'),
        d.getVar('PN') + ' Configuration', d)

    if hasattr(bb.build, 'write_taint'):
        try:
            newmtime = os.path.getmtime(config)
        except OSError:
            newmtime = 0

        if newmtime != mtime:
            bb.build.write_taint('do_compile', d)
}

do_menuconfig[depends] += "kconfig-native:do_populate_sysroot"
do_menuconfig[nostamp] = "1"
do_menuconfig[dirs] = "${B}"
addtask menuconfig after do_configure

run_defconfig() {
    oe_runmake ${KCONFIG_DEFCONFIG_COMMAND}
}

python do_defconfig() {
    bb.build.exec_func("run_defconfig", d)
    if hasattr(bb.build, 'write_taint'):
        bb.build.write_taint('do_compile', d)
}

do_defconfig[depends] += "kconfig-native:do_populate_sysroot"
do_defconfig[nostamp] = "1"
do_defconfig[dirs] = "${B}"
addtask defconfig
