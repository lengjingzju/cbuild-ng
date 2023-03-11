LICENSE = "MIT"
LIC_FILES_CHKSUM = ""
SRC_URI = ""

inherit cbuild
inherit kconfig
inherit sanity

do_configure () {
	:
}

do_compile () {
	oe_runmake def_config
}

do_install () {
	:
}

ALLOW_EMPTY:${PN} = "1"
