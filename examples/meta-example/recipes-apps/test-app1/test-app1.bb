LICENSE = "MIT"
LIC_FILES_CHKSUM = ""
SRC_URI = ""

inherit cbuild
inherit sanity

do_configure () {
	:
}

do_compile () {
	oe_runmake
}

do_install () {
	oe_runmake install
}

INSANE_SKIP:${PN} += "dev-so"
FILES:${PN}-dev = "${includedir}"
FILES:${PN} = "${libdir} ${bindir}"

BBCLASSEXTEND = "native"
