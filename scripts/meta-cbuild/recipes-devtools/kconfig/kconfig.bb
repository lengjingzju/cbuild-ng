LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://conf.c;md5=ea793329c506a2b13d09d6dafb0467c1;beginline=1;endline=4"

SRC_URI = ""

DEPENDS += "flex-native bison-native pkgconfig-native ncurses"

inherit cbuild

do_configure () {
	:
}

DEP_PREFIX:class-target = "${WORKDIR}/recipe-sysroot"
DEP_PREFIX:class-native = "${WORKDIR}/recipe-sysroot-native"

do_compile () {
	oe_runmake O=${WORKDIR}/build CONF_CC="${CC}" EXTRA_LDFLAGS="-L${DEP_PREFIX}/usr/lib"
}

do_install () {
	oe_runmake O=${WORKDIR}/build DESTDIR=${D}${base_prefix} install
}

BBCLASSEXTEND = "native"
INSANE_SKIP += "native-last"
