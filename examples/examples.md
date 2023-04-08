# CBuild-ng Test Cases

[中文版](./examples_zh-cn.md)

## Test Templates

### Test Application Compilation Template inc.app.mk

* Sets some variables
    * `export LOGOUTPUT=`: Outputs more detailed compilation information

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app$ export LOGOUTPUT=
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app$ export ENV_MAKE_DIR=/home/lengjing/data/cbuild-ng/scripts/core
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app$ export outroot=`pwd`/output/objects
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app$ export insroot=`pwd`/output/sysroot
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app$ export deproot=$insroot
    ```

* Tests generating shared libraries, static libraries, and executables

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app$ cd test-app1
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app1$ make O=$outroot/test-app1
    gcc	sub.c
    gcc	main.c
    gcc	add.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app1/libtest.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app1/libtest.so.1.2.3
    bin:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app1/test
    ```

* Tests that if the header file is changed, the c files that depend on it are also re-compiled

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app1$ echo >> include/sub.h
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app1$ make O=$outroot/test-app1
    gcc	sub.c
    gcc	main.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app1/libtest.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app1/libtest.so.1.2.3
    bin:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app1/test
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app1$ make O=$outroot/test-app1 DESTDIR=$insroot install
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app1$ tree $insroot
    /home/lengjing/data/cbuild-ng/examples/test-app/output/sysroot
    `-- usr
        |-- bin
        |   `-- test
        |-- include
        |   `-- test-app1
        |       |-- add.h
        |       `-- sub.h
        `-- lib
            |-- libtest.a
            |-- libtest.so -> libtest.so.1
            |-- libtest.so.1 -> libtest.so.1.2.3
            `-- libtest.so.1.2.3

    5 directories, 7 files
    ```

* Tests dependency (`test-app2` depends on `test-app`)

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app1$ cd ../test-app2
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app2$ make O=$outroot/test-app2
    In file included from main.c:2:0:
    main.h:1:10: fatal error: sub.h: No such file or directory
     #include "sub.h"
              ^~~~~~~
    compilation terminated.
    /home/lengjing/data/cbuild-ng/scripts/core/inc.app.mk:86: recipe for target '/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app2/main.o' failed
    make: *** [/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app2/main.o] Error 1
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app2$ make O=$outroot/test-app2 DEPDIR=$deproot
    gcc	main.c
    bin:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app2/test2
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app2$ make O=$outroot/test-app2 DESTDIR=$insroot install
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app2$ tree $insroot
    /home/lengjing/data/cbuild-ng/examples/test-app/output/sysroot
    `-- usr
        |-- bin
        |   |-- test
        |   `-- test2
        |-- include
        |   `-- test-app1
        |       |-- add.h
        |       `-- sub.h
        `-- lib
            |-- libtest.a
            |-- libtest.so -> libtest.so.1
            |-- libtest.so.1 -> libtest.so.1.2.3
            `-- libtest.so.1.2.3

    5 directories, 8 files
    ```

* Tests generating multiple shared libraries in one Makefile

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app2$ cd ../test-app3
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app3$ make O=$outroot/test-app3
    gcc	add.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libadd.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libadd.so.1.2.3
    gcc	sub.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libsub.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libsub.so.1.2
    gcc	mul.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libmul.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libmul.so.1
    gcc	div.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libdiv.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libdiv.so
    lib:	/home/lengjing/data/cbuild-ng/examples/test-app/output/objects/test-app3/libadd2.so.1.2.3
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app3$ make O=$outroot/test-app3 DESTDIR=$insroot install
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app3$ tree $insroot
    /home/lengjing/data/cbuild-ng/examples/test-app/output/sysroot
    `-- usr
        |-- bin
        |   |-- test
        |   `-- test2
        |-- include
        |   |-- test-app1
        |   |   |-- add.h
        |   |   `-- sub.h
        |   `-- test-app3
        |       |-- add.h
        |       |-- div.h
        |       |-- mul.h
        |       `-- sub.h
        `-- lib
            |-- libadd.a
            |-- libadd.so -> libadd.so.1
            |-- libadd.so.1 -> libadd.so.1.2.3
            |-- libadd.so.1.2.3
            |-- libadd2.so -> libadd2.so.1
            |-- libadd2.so.1 -> libadd2.so.1.2.3
            |-- libadd2.so.1.2.3
            |-- libdiv.a
            |-- libdiv.so
            |-- libmul.a
            |-- libmul.so -> libmul.so.1
            |-- libmul.so.1
            |-- libsub.a
            |-- libsub.so -> libsub.so.1
            |-- libsub.so.1 -> libsub.so.1.2
            |-- libsub.so.1.2
            |-- libtest.a
            |-- libtest.so -> libtest.so.1
            |-- libtest.so.1 -> libtest.so.1.2.3
            `-- libtest.so.1.2.3

    6 directories, 28 files
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app3$ readelf -d $insroot/usr/lib/libadd.so.1.2.3 | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libadd.so.1]
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app3$ readelf -d $insroot/usr/lib/libsub.so.1.2 | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libsub.so.1]
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app3$ readelf -d $insroot/usr/lib/libmul.so.1 | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libmul.so.1]
    lengjing@lengjing:~/data/cbuild-ng/examples/test-app/test-app3$ readelf -d $insroot/usr/lib/libdiv.so | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libdiv.so]
    ```


### Test Driver Compilation Template inc.mod.mk

* Sets some variables

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod$ export LOGOUTPUT=
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod$ export ENV_MAKE_DIR=/home/lengjing/data/cbuild-ng/scripts/core
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod$ export outroot=`pwd`/output/objects
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod$ export insroot=`pwd`/output/sysroot
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod$ export deproot=$insroot
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod$
    ```

* Tests compiling drivers

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod$ cd test-hello-add
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello-add$ make O=$outroot/test-hello-add
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-add/hello_add.o
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add
      Building modules, stage 2.
      MODPOST 1 modules
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-add/hello_add.mod.o
      LD [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-add/hello_add.ko
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello-add$ make O=$outroot/test-hello-add DESTDIR=$insroot install
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
      INSTALL /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-add/hello_add.ko
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
      DEPMOD  5.4.0-144-generic
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello-add$ cd ../test-hello-sub
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello-sub$ make O=$outroot/test-hello-sub
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-sub/hello_sub.o
      Building modules, stage 2.
      MODPOST 1 modules
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-sub/hello_sub.mod.o
      LD [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-sub/hello_sub.ko
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello-sub$ make O=$outroot/test-hello-sub DESTDIR=$insroot install
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
      INSTALL /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello-sub/hello_sub.ko
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
      DEPMOD  5.4.0-144-generic
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello-sub$ tree $insroot
    /home/lengjing/data/cbuild-ng/examples/test-mod/output/sysroot
    |-- lib
    |   `-- modules
    |       `-- 5.4.0-144-generic
    |           `-- extra
    |               |-- hello_add.ko
    |               `-- hello_sub.ko
    `-- usr
        `-- include
            |-- test-hello-add
            |   |-- Module.symvers
            |   `-- hello_add.h
            `-- test-hello-sub
                |-- Module.symvers
                `-- hello_sub.h

    8 directories, 6 files
    ```

* Tests dependency (`test-hello` depends on `test-hello-add` and `test-hello-sub`)

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello-sub$ cd ../test-hello
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello$ make O=$outroot/test-hello
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_mul.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_div.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_main.o
    In file included from /home/lengjing/data/cbuild-ng/examples/test-mod/test-hello/hello_main.c:3:0:
    /home/lengjing/data/cbuild-ng/examples/test-mod/test-hello/hello_main.h:1:10: fatal error: hello_add.h: No such file or directory
     #include "hello_add.h"
              ^~~~~~~~~~~~~
    compilation terminated.
    scripts/Makefile.build:270: recipe for target '/home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_main.o' failed
    make[2]: *** [/home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_main.o] Error 1
    Makefile:1767: recipe for target '/home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello' failed
    make[1]: *** [/home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello] Error 2
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    /home/lengjing/data/cbuild-ng/scripts/core/inc.mod.mk:87: recipe for target 'modules' failed
    make: *** [modules] Error 2
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello$ make O=$outroot/test-hello DEPDIR=$insroot
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_mul.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_div.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_main.o
      LD [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_dep.o
      Building modules, stage 2.
      MODPOST 1 modules
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_dep.mod.o
      LD [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_dep.ko
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello$ make O=$outroot/test-hello DESTDIR=$insroot install
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
      INSTALL /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-hello/hello_dep.ko
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
      DEPMOD  5.4.0-144-generic
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello$ tree $insroot
    /home/lengjing/data/cbuild-ng/examples/test-mod/output/sysroot
    |-- lib
    |   `-- modules
    |       `-- 5.4.0-144-generic
    |           `-- extra
    |               |-- hello_add.ko
    |               |-- hello_dep.ko
    |               `-- hello_sub.ko
    `-- usr
        `-- include
            |-- test-hello-add
            |   |-- Module.symvers
            |   `-- hello_add.h
            `-- test-hello-sub
                |-- Module.symvers
                `-- hello_sub.h

    8 directories, 7 files
    ```

* Tests generating multiple kernel modules (hello_op and hello_sec) in one Makefile

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-hello$ cd ../test-two-mods/
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-two-mods$ make O=$outroot/test-two-mods
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_main.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_add.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_sub.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_mul.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_div.o
      LD [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_op.o
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_sec.o
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods
      Building modules, stage 2.
      MODPOST 2 modules
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_op.mod.o
      LD [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_op.ko
      CC [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_sec.mod.o
      LD [M]  /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_sec.ko
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    Build test-two-mods Done.
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-two-mods$ make O=$outroot/test-two-mods DESTDIR=$insroot install
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods PWD=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods
    make[1]: Entering directory '/usr/src/linux-headers-5.4.0-144-generic'
      INSTALL /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_op.ko
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
      INSTALL /home/lengjing/data/cbuild-ng/examples/test-mod/output/objects/test-two-mods/hello_sec.ko
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
      DEPMOD  5.4.0-144-generic
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    make[1]: Leaving directory '/usr/src/linux-headers-5.4.0-144-generic'
    lengjing@lengjing:~/data/cbuild-ng/examples/test-mod/test-two-mods$ tree $insroot
    /home/lengjing/data/cbuild-ng/examples/test-mod/output/sysroot
    |-- lib
    |   `-- modules
    |       `-- 5.4.0-144-generic
    |           `-- extra
    |               |-- hello_add.ko
    |               |-- hello_dep.ko
    |               |-- hello_op.ko
    |               |-- hello_sec.ko
    |               `-- hello_sub.ko
    `-- usr
        `-- include
            |-- test-hello-add
            |   |-- Module.symvers
            |   `-- hello_add.h
            `-- test-hello-sub
                |-- Module.symvers
                `-- hello_sub.h

    8 directories, 9 files
    ```


### Test Kconfig Configuration Template inc.conf.mk

* Sets some variables

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ export LOGOUTPUT=
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ export ENV_MAKE_DIR=/home/lengjing/data/cbuild-ng/scripts/core
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ export outroot=`pwd`/output/objects
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ export CONF_SRC=/home/lengjing/data/cbuild-ng/scripts/kconfig
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ export CONF_WORKDIR=$outroot/kconfig-native
    ```

* Tests loading the default config to the current config

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ ls config
    def_config
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ make O=$outroot/test-conf def_config
    make[1]: Entering directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    bison	/home/lengjing/data/cbuild-ng/examples/test-conf/output/objects/kconfig-native/build/autogen/parser.tab.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-conf/output/objects/kconfig-native/build/autogen/parser.tab.c
    flex	/home/lengjing/data/cbuild-ng/examples/test-conf/output/objects/kconfig-native/build/autogen/lexer.lex.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-conf/output/objects/kconfig-native/build/autogen/lexer.lex.c
    gcc	parser/confdata.c
    gcc	parser/menu.c
    gcc	parser/util.c
    gcc	parser/preprocess.c
    gcc	parser/expr.c
    gcc	parser/symbol.c
    gcc	conf.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-conf/output/objects/kconfig-native/build/conf
    gcc	lxdialog/checklist.c
    gcc	lxdialog/inputbox.c
    gcc	lxdialog/util.c
    gcc	lxdialog/textbox.c
    gcc	lxdialog/yesno.c
    gcc	lxdialog/menubox.c
    gcc	mconf.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-conf/output/objects/kconfig-native/build/mconf
    make[1]: Leaving directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Entering directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Leaving directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    Load config/def_config to .config
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ ls -a $outroot/test-conf
    .  ..  .config  .config.old  autoconfig  config.h
    ```

* Tests saving the current config to the specific config

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ make O=$outroot/test-conf menuconfig
    make[1]: Entering directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Nothing to be done for 'all'.
    make[1]: Leaving directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Entering directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Leaving directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'


    *** End of the configuration.
    *** Execute 'make' to start the build or try 'make help'.

    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ make O=$outroot/test-conf def2_saveconfig
    make[1]: Entering directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Nothing to be done for 'all'.
    make[1]: Leaving directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Entering directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    make[1]: Leaving directory '/home/lengjing/data/cbuild-ng/scripts/kconfig'
    Save .config to config/def2_config
    lengjing@lengjing:~/data/cbuild-ng/examples/test-conf$ ls config
    def2_config  def_config
    ```


## Test Classic Build

* Exports environment variables

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ export LOGOUTPUT=
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ source scripts/test.env
    ============================================================
    ENV_BUILD_MODE   : classic
    ENV_BUILD_JOBS   : -j8
    ENV_TOP_DIR      : /home/lengjing/data/cbuild-ng/examples/test-cbuild
    ENV_MAKE_DIR     : /home/lengjing/data/cbuild-ng/scripts/core
    ENV_TOOL_DIR     : /home/lengjing/data/cbuild-ng/scripts/bin
    ENV_DOWN_DIR     : /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/mirror-cache/downloads
    ENV_CACHE_DIR    : /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/mirror-cache/build-cache
    ENV_MIRROR_URL   : http://127.0.0.1:8888
    ENV_TOP_OUT      : /home/lengjing/data/cbuild-ng/examples/test-cbuild/output
    ENV_CROSS_ROOT   : /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch
    ENV_CFG_ROOT     : /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/config
    ENV_NATIVE_ROOT  : /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native
    ============================================================
    ```

* Builds all packages

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ make time_statistics
    Generate /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/config/Kconfig OK.
    Generate /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/config/Target OK.
    Generate /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/config/auto.mk OK.
    bison	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/kconfig/build/autogen/parser.tab.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/kconfig/build/autogen/parser.tab.c
    flex	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/kconfig/build/autogen/lexer.lex.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/kconfig/build/autogen/lexer.lex.c
    gcc	parser/confdata.c
    gcc	parser/menu.c
    gcc	parser/util.c
    gcc	parser/preprocess.c
    gcc	parser/expr.c
    gcc	parser/symbol.c
    gcc	conf.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/kconfig/build/conf
    gcc	lxdialog/checklist.c
    gcc	lxdialog/inputbox.c
    gcc	lxdialog/util.c
    gcc	lxdialog/textbox.c
    gcc	lxdialog/yesno.c
    gcc	lxdialog/menubox.c
    gcc	mconf.c
    gcc	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/kconfig/build/mconf
    Load /home/lengjing/data/cbuild-ng/examples/test-cbuild/configs/def_config to .config
    gcc	sub.c
    gcc	add.c
    gcc	main.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/build/libtest.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/build/libtest.so.1.2.3
    bin:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/build/test
    Build test-app1 Done.
    gcc	main.c
    bin:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app2/build/test2
    Build test-app2 Done.
    gcc	add.c
    gcc	sub.c
    gcc	mul.c
    gcc	div.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libadd.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libadd.so.1.2.3
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libsub.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libsub.so.1.2
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libmul.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libmul.so.1
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libdiv.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libdiv.so
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/build/libadd2.so.1.2.3
    Load config/def_config to .config
    Build test-conf Done.
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild/test-mod/test-hello-add
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild/test-mod/test-hello-add
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild/test-mod/test-hello-add
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-hello-add PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild/test-mod/test-hello-add
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    Build test-hello-add Done.
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    Build test-hello-sub Done.
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    Build test-hello Done.
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild
    KERNELRELEASE=5.4.0-144-generic pwd=/usr/src/linux-headers-5.4.0-144-generic PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild
    Build test-two-mods Done.
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild-ng/examples/test-mod/test-two-mods PWD=/home/lengjing/data/cbuild-ng/examples/test-cbuild
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    At main.c:167:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    Build done!
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ cat output/noarch/config/time_statistics
    real		user		sys		package
    0.03		0.02		0.00		deps
    0.20		0.24		0.04		test-app1
    0.03		0.02		0.00		test-app1
    0.18		0.18		0.03		test-app2
    0.01		0.00		0.00		test-app2
    0.08		0.13		0.03		test-app3
    0.07		0.06		0.01		test-app3
    0.01		0.01		0.00		test-conf
    0.00		0.00		0.00		test-conf
    1.53		1.28		0.27		test-hello-add
    0.02		0.02		0.00		test-hello-add
    1.51		1.20		0.33		test-hello-sub
    0.02		0.02		0.00		test-hello-sub
    0.04		0.03		0.01		test-hello
    1.51		1.53		0.33		test-hello
    0.01		0.01		0.00		test-hello
    0.97		1.57		0.31		test-two-mods
    0.56		0.43		0.13		test-two-mods
    6.83		6.82		1.56		total_time
    ```

* Runs the specific task (menuconfig) of the specific package (test-conf)
    ```sh

    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ make test-conf_menuconfig


    *** End of the configuration.
    *** Execute 'make' to start the build or try 'make help'.
    ```

* The files in global / local dependency sysroot are basically symbolic links, it greatly saves storage space

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ tree output/noarch/sysroot/
    output/noarch/sysroot/
    |-- lib
    |   `-- modules
    |       `-- 5.4.0-144-generic
    |           `-- extra
    |               |-- hello_add.ko -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-hello-add/image/lib/modules/5.4.0-144-generic/extra/hello_add.ko
    |               |-- hello_dep.ko -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-hello/image/lib/modules/5.4.0-144-generic/extra/hello_dep.ko
    |               `-- hello_sub.ko -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-hello-sub/image/lib/modules/5.4.0-144-generic/extra/hello_sub.ko
    `-- usr
        |-- bin
        |   |-- test -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/image/usr/bin/test
        |   `-- test2 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app2/image/usr/bin/test2
        |-- include
        |   |-- test-app1
        |   |   |-- add.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/image/usr/include/test-app1/add.h
        |   |   `-- sub.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/image/usr/include/test-app1/sub.h
        |   |-- test-app3
        |   |   |-- add.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/include/test-app3/add.h
        |   |   |-- div.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/include/test-app3/div.h
        |   |   |-- mul.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/include/test-app3/mul.h
        |   |   `-- sub.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/include/test-app3/sub.h
        |   |-- test-hello-add
        |   |   |-- Module.symvers -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-hello-add/image/usr/include/test-hello-add/Module.symvers
        |   |   `-- hello_add.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-hello-add/image/usr/include/test-hello-add/hello_add.h
        |   `-- test-hello-sub
        |       |-- Module.symvers -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-hello-sub/image/usr/include/test-hello-sub/Module.symvers
        |       `-- hello_sub.h -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-hello-sub/image/usr/include/test-hello-sub/hello_sub.h
        `-- lib
            |-- libadd.a -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libadd.a
            |-- libadd.so -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libadd.so
            |-- libadd.so.1 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libadd.so.1
            |-- libadd.so.1.2.3 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libadd.so.1.2.3
            |-- libadd2.so -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libadd2.so
            |-- libadd2.so.1 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libadd2.so.1
            |-- libadd2.so.1.2.3 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libadd2.so.1.2.3
            |-- libdiv.a -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libdiv.a
            |-- libdiv.so -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libdiv.so
            |-- libmul.a -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libmul.a
            |-- libmul.so -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libmul.so
            |-- libmul.so.1 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libmul.so.1
            |-- libsub.a -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libsub.a
            |-- libsub.so -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libsub.so
            |-- libsub.so.1 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libsub.so.1
            |-- libsub.so.1.2 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app3/image/usr/lib/libsub.so.1.2
            |-- libtest.a -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/image/usr/lib/libtest.a
            |-- libtest.so -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/image/usr/lib/libtest.so
            |-- libtest.so.1 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/image/usr/lib/libtest.so.1
            `-- libtest.so.1.2.3 -> /home/lengjing/data/cbuild-ng/examples/test-cbuild/output/noarch/objects/test-app1/image/usr/lib/libtest.so.1.2.3

    12 directories, 35 files
    ```

* Tests building native packages, enables `test-app1-native` `test-app2-native` `test-app3-native` with the command `make menuconfig`

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ make menuconfig
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ make test-app2-native
    gcc	sub.c
    gcc	main.c
    gcc	add.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app1/build/libtest.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app1/build/libtest.so.1.2.3
    bin:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app1/build/test
    Build test-app1-native Done.
    gcc	main.c
    bin:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app2/build/test2
    Build test-app2-native Done.
    lengjing@lengjing:~/data/cbuild-ng/examples/test-cbuild$ make test-app3-native
    gcc	add.c
    gcc	sub.c
    gcc	mul.c
    gcc	div.c
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libadd.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libadd.so.1.2.3
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libsub.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libsub.so.1.2
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libmul.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libmul.so.1
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libdiv.a
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libdiv.so
    lib:	/home/lengjing/data/cbuild-ng/examples/test-cbuild/output/x86_64-native/objects/test-app3/build/libadd2.so.1.2.3
    ```


## Test Yocto Build

### Yocto Quick Start

* Install compilation environment

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/scripts$ sudo apt install gawk wget git diffstat unzip \
        texinfo gcc build-essential chrpath socat cpio \
        python3 python3-pip python3-pexpect xz-utils \
        debianutils iputils-ping python3-git python3-jinja2 \
        libegl1-mesa libsdl1.2-dev pylint3 xterm \
        python3-subunit mesa-common-dev zstd liblz4-tool qemu
    ```

* Pulls Poky, version can be get from [Yocto Releases Wiki](https://wiki.yoctoproject.org/wiki/Releases)

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/scripts$ git clone git://git.yoctoproject.org/poky
    lengjing@lengjing:~/data/cbuild-ng/scripts$ cd poky
    lengjing@lengjing:~/data/cbuild-ng/scripts/poky$ git branch -a
    lengjing@lengjing:~/data/cbuild-ng/scripts/poky$ git checkout -t origin/kirkstone -b my-kirkstone
    lengjing@lengjing:~/data/cbuild-ng/scripts/poky$ cd ../../
    ```

* Builds the image

    ```sh
    lengjing@lengjing:~/data/cbuild-ng$ source scripts/poky/oe-init-build-env
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake core-image-minimal
    lengjing@lengjing:~/data/cbuild-ng/build$ ls -al tmp/deploy/images/qemux86-64/
    lengjing@lengjing:~/data/cbuild-ng/build$ runqemu qemux86-64
    ```


### Test Yocto Cases

* Adds some definitions to the configuration `conf/local.conf`

    ```sh
    echo "ENV_TOP_DIR = \"$(realpath ..)\"" >> conf/local.conf
    ```

* Adds meta to test

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake-layers add-layer ../scripts/meta-cbuild
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake-layers add-layer ../examples/meta-example
    ```

* Tests compilation with bitbake

    ```sh
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-app2         # Compile Application
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-app3         # Compile Application
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-hello        # Compile Driver
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-two-mods     # Compile Driver
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-conf         # Compile native tool `kconfig`
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-conf -c menuconfig # Modify configuration
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-app2-native  # Compile native Application
    lengjing@lengjing:~/data/cbuild-ng/build$ bitbake test-app3-native  # Compile native Application
    ```
