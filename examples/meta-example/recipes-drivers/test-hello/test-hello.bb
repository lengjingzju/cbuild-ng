LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = ""
SRC_URI = ""

DEPENDS += "test-hello-add test-hello-sub"

inherit cbuild
inherit module

do_configure () {
	:
}

do_compile () {
	oe_runmake
}

do_install () {
	oe_runmake install
}
