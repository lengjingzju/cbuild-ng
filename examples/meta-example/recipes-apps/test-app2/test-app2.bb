LICENSE = "MIT"
LIC_FILES_CHKSUM = ""
SRC_URI = ""

DEPENDS += "test-app1"
RDEPENDS:${PN} += "test-app1"

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

FILES:${PN} = "${bindir}"

BBCLASSEXTEND = "native"
