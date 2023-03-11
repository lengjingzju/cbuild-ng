# Yocto 常见问题

## 怎么学习 Yocto 官方文档

答：如下列表：三颗星需要详细了解，两颗星只要大概了解，一颗星需要时去查阅，其它文档需要深入学习 Yocto 时再了解

* 入门知识
    * [快速构建★★★](https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html)
    * [使用建议★★☆](https://docs.yoctoproject.org/what-i-wish-id-known.html)
    * [项目介绍★★☆](https://docs.yoctoproject.org/overview-manual/yp-intro.html)
    * [项目概念★★★](https://docs.yoctoproject.org/overview-manual/concepts.html)
* [参考手册](https://docs.yoctoproject.org/ref-manual/index.html)
    * [目录结构★★★](https://docs.yoctoproject.org/ref-manual/structure.html)
    * [配方类★☆☆](https://docs.yoctoproject.org/ref-manual/classes.html)
        * [QA检查★★☆](https://docs.yoctoproject.org/ref-manual/classes.html#insane-bbclass)
    * [任务简介★★★](https://docs.yoctoproject.org/ref-manual/tasks.html)
    * [devtool命令★☆☆](https://docs.yoctoproject.org/ref-manual/devtool-reference.html)
    * [QA问题★★☆](https://docs.yoctoproject.org/ref-manual/qa-checks.html)
    * [变量词汇表★☆☆](https://docs.yoctoproject.org/ref-manual/variables.html)
* 开发手册
    * [BSP开发★★☆](https://docs.yoctoproject.org/bsp-guide/bsp.html)
    * [内核开发★★☆](https://docs.yoctoproject.org/kernel-dev/index.html)
    * [常见任务★★☆](https://docs.yoctoproject.org/dev-manual/common-tasks.html)
        * [编写meta★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#understanding-and-creating-layers)
        * [编写image★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#customizing-images)
        * [编写recipe★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#writing-a-new-recipe)
        * [编写machine★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#adding-a-new-machine)
        * [了解package★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#working-with-pre-built-libraries)
* [语法手册](https://docs.yoctoproject.org/bitbake/2.0/index.html)
    * [基本概念★★☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-intro.html)
    * [执行简介★☆☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-execution.html)
    * [语法运算★★★](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-metadata.html)
    * [文件获取★☆☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-fetching.html)
    * [变量词汇表★☆☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-ref-variables.html)
    * [打印调试★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#recipe-logging-mechanisms)

## Yocto 配方模板

### 编写类文件 (xxx.bbclass)

* 可以在类文件中 `meta-xxx/classes/xxx.bbclass` 定义环境变量，在配方文件中继承 `inherit xxx`

* 例如 cbuild.bbclass

    ```sh
    export WORKDIR
    export ENV_TOP_DIR
    export ENV_MAKE_DIR = "${ENV_TOP_DIR}/scripts/core"
    export ENV_TOOL_DIR = "${ENV_TOP_DIR}/scripts/bin"
    export ENV_CFG_ROOT = "${TOPDIR}/config"

    export ENV_BUILD_MODE = "yocto"
    NATIVE_BUILD:class-target = "n"
    NATIVE_BUILD:class-native = "y"
    export NATIVE_BUILD
    ```

### 编写配方文件 (xxx.bb)

* `recipetool create -o <xxx.bb> <package_src_dir>` 创建一个基本配方，例子中手动增加的条目说明如下
<br>

* 包依赖
    * 包依赖其他包时需要使用 `DEPENDS += "package1 package2"` 说明
    * 链接其它包时 (`LDFLAGS += -lname1 -lname2`) 的动态库，需要增加 `RDEPENDS:${PN} += "package1 package2"` 说明
        * 不写可能编译失败或动态库没有安装到 rootfs
    * 依赖主机工具时需要使用 `DEPENDS += "package3-native"` 说明
<br>

* 编译继承类
    * 使用 menuconfig 需要继承 `inherit kconfig`
        * 如果命令是 `make -f wrapper.mk menuconfig`
            * 需要设置 `KCONFIG_CONFIG_COMMAND = "-f wrapper.mk menuconfig"`
            * 需要设置 `KCONFIG_DEFCONFIG_COMMAND = "-f wrapper.mk defconfig"`
        * 如果 .config 输出目录是编译输出目录，需要设置 `KCONFIG_CONFIG_PATH = "${WORKDIR}/build/.config"`
    * 使用 Makefile 编译应用继承 `inherit sanity`，使用 cmake 编译应用继承 `inherit cmake`
    * 编译外部内核模块继承 `inherit module`
    * 编译主机本地工具继承 `inherit native`
    * 一个配方同时支持交叉编译和本地编译需要声明 `BBCLASSEXTEND = "native"`，无需继承 `inherit native`
        * 如果变量值在交叉编译和本地编译不同时，使用下面覆盖语法
            * `somevar:class-target = "some value"`
            * `somevar:class-native = "some value"`
<br>

* 安装和打包
    * 设置的变量
        * includedir 指 xxx/usr/include
        * base_libdir 指 xxx/lib;  libdir指 xxx/usr/lib;  bindir指 xxx/usr/bin; datadir 指 xxx/usr/share
        * 有时候需要精确指定打包的文件而不是目录，防止多个打包的目录有重合导致打包出错
        * 更多目录信息参考 Poky 工程的 `meta/conf/bitbake.conf` 文件
        ```
        FILES:${PN}-dev = "${includedir}"
        FILES:${PN} = "${base_libdir} ${libdir} ${bindir} ${datadir}"
        ```
    * 继承 `inherit sanity` 或 `inherit cmake` 时需要按实际情况指定打包的目录，否则 do_package 任务出错
    * 继承 `inherit module` 不需要指定头文件和模块文件的打包的目录，但如果安装其它文件时，需要指定这个文件的打包目录
    * 忽略某些警告和错误
        * `ALLOW_EMPTY:${PN} = "1"` 忽略包安装的文件只有头文件或为空，生成镜像时 do_rootfs 错误
        * `INSANE_SKIP:${PN} += "dev-so"` 忽略安装的文件是符号链接的错误
            * 更多信息参考 [insane.bbclass](https://docs.yoctoproject.org/ref-manual/classes.html?highlight=sanity#insane-bbclass)
<br>

* 配方模板

    ```
    LICENSE = "CLOSED"
    LIC_FILES_CHKSUM = ""
    SRC_URI = ""

    #DEPENDS += "package1 package2"
    #RDEPENDS:${PN} += "package1 package2"

    inherit cbuild

    #KCONFIG_CONFIG_COMMAND = "-f wrapper.mk menuconfig"
    #KCONFIG_DEFCONFIG_COMMAND = "-f wrapper.mk defconfig"
    #KCONFIG_CONFIG_PATH = "${WORKDIR}/build/.config"
    #inherit kconfig

    inherit sanity
    #inherit cmake
    #inherit module
    #inherit native

    do_configure () {
        :
    }

    do_compile () {
        oe_runmake
    }

    do_install () {
        oe_runmake install
    }

    ALLOW_EMPTY:${PN} = "1"
    INSANE_SKIP:${PN} += "dev-so"
    FILES:${PN}-dev = "${includedir}"
    FILES:${PN} = "${base_libdir} ${libdir} ${bindir} ${datadir}"

    #BBCLASSEXTEND = "native"
    ```

注: [从3.4版本开始，对变量的覆盖样式语法由下滑线 `_` 变成了冒号 `:`](https://docs.yoctoproject.org/migration-guides/migration-3.4.html#override-syntax-changes)


### 编写配方附加文件 (xxx.bbappend)

* 配方附加文件在 cbuild 的实现中，主要作用是指示包的源码路径和 Makefile 路径，一般这两个路径一样
<br>

* EXTERNALSRC: 源码目录，编译会对这个目录做校验决定是否重新编译
    * 如果源码不全在 EXTERNALSRC 目录内，我们需要追加文件或目录做校验，追加任务的 `file-checksums` 标记，否则源码修改后没有重新编译
    * 用户可以继承类 `extrasrc.bbclass` 来做追加，可设置的变量
        * EXTRASRC_CONFIGURE: 追加做 do_configure 任务校验的文件或目录
        * EXTRASRC_COMPILE: 追加做 do_compile 任务校验的文件或目录
        * EXTRASRC_INSTALL: 追加做 do_install 任务校验的文件或目录

        ```py
        python () {
            tasks = ['configure', 'compile', 'install']

            for task in tasks:
                task_name = 'do_%s' % (task)
                src_name = 'EXTRASRC_%s' % (task.upper())
                src_str = d.getVar(src_name)

                if src_str:
                    srcs = src_str.split()
                    for src in srcs:
                        if os.path.exists(src):
                            if os.path.isdir(src):
                                d.appendVarFlag(task_name, 'file-checksums', ' %s/*:True' % (src))
                            else:
                                d.appendVarFlag(task_name, 'file-checksums', ' %s:True' % (src))
                            #bb.warn('%s is appended in %s of %s\n' % (d.getVarFlag(task_name, 'file-checksums'), task_name, d.getVar('PN')))
                        else:
                            bb.warn('%s is not existed in %s of %s\n' % (src, task_name, d.getVar('PN')))
        }
        ```
<br>

* EXTERNALSRC_BUILD: 运行 make 命令的目录，可以和 EXTERNALSRC 不同
<br>

* 本地源码的配方附加文件模板

```
inherit externalsrc
EXTERNALSRC = "${ENV_TOP_DIR}/<package_src>"
EXTERNALSRC_BUILD = "${ENV_TOP_DIR}/<package_src>"
```

## Yocto 编译打补丁

### Yocto 官方打补丁

* 方法
    * 配方文件的当前目录新建名为 `配方名` 或 `files` 的文件夹，补丁放在此文件夹内
        * 注：查找补丁文件的文件夹不止上面这些，但我们一般使用名为 `配方名` 的文件夹
    * 配方中加上补丁文件名声明，无需文件夹路径 `SRC_URI += "file://0001-xxx.patch"`
    * 如果配方继承了 `externalsrc` 类，还要设置变量 `RCTREECOVEREDTASKS = "do_unpack do_fetch"`
        * 注：`externalsrc` 类默认会把 `do_patch` 任务删除，所以要设置 `RCTREECOVEREDTASKS`
<br>

* 优点
    * 实现简单
<br>

* 缺点
    * 无法选择补丁是否打上
    * 打补丁默认只会运行一次，如果其它方法去掉了补丁，重新编译，补丁不会被打上
    * 会在源码目录生成临时文件夹，污染源码目录，例如生成了 `.pc/` `patches/`


### 自定义打补丁 externalpatch.bbclass

* 方法
    * 每类补丁建立两个包，打补丁包和去补丁包，配方名格式必须为 `xxx-patch-xxx` 和 `xxx-unpatch-xxx`
    * 源码包弱依赖这两个包 `EXTRADEPS = "xxx-patch-xxx|xxx-unpatch-xxx"` `inherit weakdep`
    * 建立虚依赖规则文件 `#VDEPS(choice) xxx-patch-xxx-choice(xxx-unpatch-xxx xxx-patch-xxx):`
    * 补丁包设置变量并继承外部补丁类 `inherit externalpatch`
        * `externalpatch` 类的作用是检查补丁是否打上，从而决定是否打补丁或去补丁强制运行
        ```sh
        EXTERNALPATCH_SRC = "带路径的补丁文件名，可以是多个文件或目录"
        EXTERNALPATCH_DST = "要打补丁的源码目录"
        EXTERNALPATCH_OPT = "patch 或 unpatch"
        inherit externalpatch
        ```
<br>

* 缺点
    * 实现稍显复杂
    * 因为动态修改了配方，补丁选项改变时需要重新编译打/去补丁包两次
<br>

* 优点
    * 可以选择补丁是否打上
    * 可以保证打补丁或去补丁正确运行，无论是否在其它地方做了打补丁或去补丁的操作
    * 源码目录只有补丁的修改，无临时文件或文件夹
    * 补丁可以放在任意目录

## Yocto 编译和普通编译最大不同是什么

答：普通编译使用的是主机的编译环境；
Yocto 编译则每个包都有自已的输出目录 [WORKDIR](https://docs.yoctoproject.org/ref-manual/variables.html#term-WORKDIR) ，在 WORKDIR 自己复制需要的主机工具和依赖文件到自己的工作目录，然后创建一个干净的shell环境执行任务。

* `${WORKDIR}/build`：仅适用于源代码与编译输出分开的编译输出目录
* `${WORKDIR}/recipe-sysroot`：依赖的根文件目录
* `${WORKDIR}/recipe-sysroot-native`：主机工具的根文件目录
* `${WORKDIR}/image`：安装的根文件目录
* `${WORKDIR}/temp`：自动生成的日志和脚本的文件目录

## Yocto 怎么导出环境变量

答：Yocto 是无法使用在shell中导出的环境变量的，Yocto 中的环境变量可以在输出目录的 `conf/local.conf` 中定义，在recipe文件中通过 `export <varname>` 一条一条导出。
编译时可以从 `${WORKDIR}/temp/run.do_compile` 文件知道导出了哪些变量。
详情参考 [将变量导出到环境](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=nostamp#exporting-variables-to-the-environment)

## Yocto 常用命令有哪些

答：主要命令如下所示

* [bitbake 命令](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-intro.html#the-bitbake-command)
    * `bitbake packagename` 编译 packagename
    * `bitbake -c taskname packagename` 执行 packagename 的 taskname 任务
    * `bitbake -e packagename` 显示生成的执行脚本，从中可以看到变量和函数的定义
* [recipetool 命令](https://docs.yoctoproject.org/dev-manual/common-tasks.html#locate-or-automatically-create-a-base-recipe)
    * `recipetool create -o xxx.bb src_path` 根据源码生成一个模板
* [bitbake-layers 命令](https://docs.yoctoproject.org/bsp-guide/bsp.html?highlight=bitbake+layers#creating-a-new-bsp-layer-using-the-bitbake-layers-script)
    * `bitbake-layers create-layer xxx && mv xxx meta-xxx` 新建一个层
    * `bitbake-layers add-layer meta-xxx` 添加一个层到当前配置

## Yocto 需要注意哪些配置文件

答：主要配置文件如下所示

* [TOPDIR 目录](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-ref-variables.html#term-TOPDIR) : 输出顶层目录
* [poky/meta/conf/bitbake.conf](https://docs.yoctoproject.org/ref-manual/structure.html?highlight=bitbake+conf#meta-conf) : 默认配置，大多数变量词汇在此定义
* [${TOPDIR}/conf/local.conf](https://docs.yoctoproject.org/ref-manual/structure.html?highlight=local+conf#build-conf-local-conf) : 本地配置，可以覆盖默认配置和定义自定义的环境变量
* [${TOPDIR}/conf/bblayers.conf](https://docs.yoctoproject.org/ref-manual/structure.html?highlight=local+conf#build-conf-bblayers-conf) : 配置使用的层
* [meta-xxx/conf/layer.conf 配置](https://docs.yoctoproject.org/dev-manual/common-tasks.html?highlight=layer+conf#creating-your-own-layer) : 层配置，可以看到层下的配方文件如何找到
* [meta-xxx/conf/machine/xxx.conf 配置](https://docs.yoctoproject.org/bsp-guide/bsp.html?highlight=machine+conf#hardware-configuration-options) : 机器配置，有机器配置的层是BSP层， `${TOPDIR}/conf/local.conf` 里面的 `MACHINE` 设置的值的机器配置文件 `值.conf` 必须存在

## Yocto 怎么使用变量

答：详细信息参考 [基本语法](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#basic-syntax) 和 [条件语法](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#conditional-syntax-overrides) ，如下总结：

* 获取变量的值必须使用大括号 `${var}`
* 赋给变量的值可以用单引号也可以用双引号，单引号和双引号作用一样，不会抑制变量扩展(和shell不一样)
* 定义或修改变量的操作符有:
    * 赋值 `=` `:=` `?=` `??=`
        * 值中有变量时， `=` `?=` `??=` 值中的变量是最后扩展(变量的最终值)，`:=` 值中的变量是立即扩展(当前位置的变量值)
        * `?=` 设置默认值(在解析到当前语句时，当前变量未定义时才保留该值)
        * `??=` 设置弱默认值(在解析过程结束后再解析该语句，此时变量未定义时才保留该值，多个 `??=` 存在时保留最后一个值)
    * 追加 `+=` `=+` `.=` `=.` `:append` `:prepend`  删除 `:remove`
        * `+=`  `.=`  `:append` 是后置追加(新值放在原值的后面)； `=+` `=.` `:prepend` 是前置追加(新值放在原值的前面)
        * `+=` `=+` 会在新值和原值之间自动加上空格；`.=` `=.` `:append` `:prepend` 新值和原值之间不会加上空格，需要手动增加
        * `+=` `=+` `.=` `=.` 是立即解析(在解析到当前语句时立即追加)，`:append` `:prepend` 是最后解析(在解析过程结束后再解析该语句时追加)
        * `:remove` 是删除所有已有值(空格隔开多个值)中和设定值相同的值
    * 条件 `OVERRIDES`
        * 条件声明使用 `OVERRIDES` 关键字，条件名只能使用小写字符、数字和短划线，多个条件使用冒号隔开
            * `OVERRIDES = "cond1:cond2"`
            * `OVERRIDES:append = ":cond3"`
        * 当条件定义时才定义或修改对应的变量  `var:cond1:append = " xxx"`
* 使用 `unset` 取消设置变量
* 可以使用中括号 `var[flag_name]` 定义变量的标志
    * 理解为创建一个新变量，类似把变量当作字典的概念
    * task变量有一些 [公有的flag](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#variable-flags)
    * 定义或修改变量的操作符和取消设置 `unset` 都可以用在变量的标志中

## Yocto 怎么包含共享功能的文件

答：包含共享功能总共有 [4种方法](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#sharing-functionality) ：

* 继承类 : `inherit <class_name>` 和 `INHERIT += <class_name>`
    * 继承的文件只能是类 `*.bbclass`
    * inherit指令只能用在配方和类文件中 `*.bb` / `*.bbappend` / `*.bbclass` ，INHERIT指令只能用在配置文件中 `*.conf`
    * `<class_name>.bbclass` 在输出目录的 `conf/bblayers.conf` 的 [BBLAYERS](https://docs.yoctoproject.org/ref-manual/variables.html?highlight=bblayers#term-BBLAYERS) 变量上定义的所有 meta-xxx 目录的 classes 子目录找到，而不仅仅是当前的层目录
* 包含文件:  `include <file_path>` 和 `require <file_path>`
    * 包含的文件可以是任意类型的文件，但是我们一般命名为 `*.inc`
    * include指令和require指令可以用在任意类型的文件中
    * **include指令包含的文件不存在时不会报错，而require指令会报错**
    * `<file_path>` 如果是相对路径，它的基准是输出目录的 `conf/bblayers.conf` 的 BBLAYERS 变量上定义的所有 meta-xxx 目录，从中找到第一个匹配的文件
    * 配方文件 `*.bb` 可以使用 [THISDIR](https://docs.yoctoproject.org/ref-manual/variables.html?highlight=thisdir#term-THISDIR) 表示配方文件的所在目录，例如包含usertask.inc: `include ${THISDIR}/usertask.inc`

## Yocto 如何在NFS下编译

答：Yocto 默认是不支持在NFS下编译的，因为编译速度较慢且可能存在权限问题，请参考 [官方issue](https://bugzilla.yoctoproject.org/show_bug.cgi?id=5442#c8) ,
我们可以使用如下方法禁用poky官方工程的NFS检查使得编译成功，但无法保证不出现其它问题：

```
diff --git a/meta/classes/sanity.bbclass b/meta/classes/sanity.bbclass
index b1fac107d5..afbafe2382 100644
--- a/meta/classes/sanity.bbclass
+++ b/meta/classes/sanity.bbclass
@@ -722,7 +722,7 @@ def check_sanity_version_change(status, d):
     status.addresult(check_path_length(tmpdir, "TMPDIR", 410))

     # Check that TMPDIR isn't located on nfs
-    status.addresult(check_not_nfs(tmpdir, "TMPDIR"))
+    #status.addresult(check_not_nfs(tmpdir, "TMPDIR"))

     # Check for case-insensitive file systems (such as Linux in Docker on
     # macOS with default HFS+ file system)
```

## Yocto 的目录结构在哪里定义

答：查看官方文档 [源目录结构](https://docs.yoctoproject.org/ref-manual/structure.html) 了解目录的作用；
查看 poky 的 `meta/conf/bitbake.conf` 源码了解目录变量的详细定义

## downloads 和 sstate-cache 存储了什么

答：downloads 存储了源码， sstate-cache 存储了编译生成的文件，他们可以分别使用 [DL_DIR](https://docs.yoctoproject.org/ref-manual/variables.html?highlight=dl_dir#term-DL_DIR) 和 [SSTATE_DIR](https://docs.yoctoproject.org/ref-manual/variables.html#term-SSTATE_DIR) 指定保存目录，
如下所示，把 downloads 和 sstate-cache 保存在某个公共位置下，多个编译可以共享一份资源

```sh
DL_DIR = "${TOPDIR}/../downloads"
SSTATE_DIR = "${TOPDIR}/../sstate-cache"
```

## 如何在本地搭建镜像服务器加速构建

答：将第一次构建生成的 downloads 和 sstate-cache 复制到一个特定的目录，例如 mirror，
在 mirror 目录运行 http 服务器，例如 `python -m http.server 8080`，
然后在输出目录的 `conf/local.conf` 加上设置，例如

```sh
SSTATE_MIRRORS = "file://.* http://127.0.0.1:8080/sstate-cache/PATH;downloadfilename=PATH"
SOURCE_MIRROR_URL = "http://127.0.0.1:8080/downloads"
INHERIT += "own-mirrors"
```

## Yocto 获取源码和不重新编译的规则

答：
Yocto不重新编译的判断规则是(参考 [共享状态缓存](https://docs.yoctoproject.org/overview-manual/concepts.html#shared-state-cache) )：
1. 本地的 SSTATE_DIR 是否存在编译好的包且时间戳相同，如果是，[不用重新编译](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-execution.html#setscene)；否则下一条
2. 网络的 SSTATE_MIRRORS 是否存在编译好的包且时间戳相同，如果是，不用重新编译，直接将网络上的编译好的包复制到本地的 SSTATE_DIR；否则下一条
3. 获取源码编译并将编译好的包复制到本地的 SSTATE_DIR

Yocto获取源码的规则是(参考 [文件下载](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-fetching.html) )：
1. 本地的 DL_DIR 是否存在下载好的源码且hash值相同，如果是，直接从本地解压；否则下一条
2. 网络的 SOURCE_MIRROR_URL 是否存在下载好的源码且hash值相同，如果是，下载到本地 DL_DIR 再解压；否则下一条
3. 从配方文件指定的 SRC_URI 链接下载源码，如果下载失败下一条
4. 从Yocto官方镜像下载源码

## 出现官方自带开源包编译错误如何处理

答：开源包的编译是Yocto官方配方，个人猜测是缓存导致了此错误(系统内存不足也会导致编译出错)，运行清理一般可以解决此问题，例如出现如下错误：

```sh
ERROR: Task (.../poky/meta/recipes-connectivity/openssl/openssl_3.0.4.bb:do_package_write_rpm) failed with exit code '1'
ERROR: Task (.../poky/meta/recipes-devtools/gcc/gcc_11.3.bb:do_compile) failed with exit code '1'
```

解决方法

```sh
bitbake -c clean openssl && bitbake openssl	# 取自 openssl_3.0.4.bb 的 openssl
bitbake -c clean gcc && bitbake gcc	# 取自 gcc_11.3.bb 的 gcc
```

也可能是内存不足，通常出现在编译大型软件，例如 gcc / rust 等的时候，请加大内存(8G内存不够的)，或者单独编这个包


## 为什么外部linux模块的配方文件名以 `kernel-module-` 开头

答：查看 poky 的 `meta/classes/module.bbclass` 源码：

```py
python __anonymous () {
depends = d.getVar('DEPENDS')
extra_symbols = []
for dep in depends.split():
	if dep.startswith("kernel-module-"):
		extra_symbols.append("${STAGING_INCDIR}/" + dep + "/Module.symvers")
d.setVar('KBUILD_EXTRA_SYMBOLS', " ".join(extra_symbols))
}
```

module类自动将依赖模块的符号导出文件 Module.symvers 加入到了 [KBUILD_EXTRA_SYMBOLS](https://www.kernel.org/doc/html/latest/kbuild/kbuild.html?highlight=kbuild_extra_symbols) 变量。
Module.symvers 含有 EXPORT_SYMBOL(func) 导出的符号列表等，如果没有指定依赖包的这个文件，编译会失败。
也可以设置变量 [PROVIDES](https://docs.yoctoproject.org/ref-manual/variables.html#term-PROVIDES) 为配方设置别名，此时配方文件名不命名为 `kernel-module-` 开头也行
inc.mod.mk 模板也会自动加上 Module.symvers ，所以配方文件名不命名为 `kernel-module-` 开头也行。

## 配方中如何支持menuconfig

答：直接加上一个自定义任务运行 `oe_runmake menuconfig` 是没有效果的。

查看poky工程的 `meta/classes/cml1.bbclass` 的源码有个 do_menuconfig 的任务，核心语句如下：

```py
KCONFIG_CONFIG_COMMAND ??= "menuconfig"
KCONFIG_CONFIG_ROOTDIR ??= "${B}"
python do_menuconfig() {
    ...
    oe_terminal("sh -c \"make %s; if [ \\$? -ne 0 ]; then echo 'Command failed.'; printf 'Press any key to continue... '; read r; fi\"" % d.getVar('KCONFIG_CONFIG_COMMAND'),
    ...
}
```

所以我们需要继承cml1类 `inherit cml1` 来加上 menuconfig 任务，如果我们的 Makefile 不是默认名称，我们还需要修改 `KCONFIG_CONFIG_COMMAND` 变量，例如 `KCONFIG_CONFIG_COMMAND = "-f wrapper.mk menuconfig"`。

但是cml1类不支持 `.config` 文件放在和运行编译的工作目录的不同的目录，如果 `.config` 文件和运行编译的工作目录不同，包不会使用新的参数重新编译，此种情况我们可以继承自定义的类 `inherit kconfig`

## 如何禁止编译在源码创建 oe-workdir 和 oe-logs 符号链接

答：查看Poky工程的 meta/classes/externalsrc.bbclass 的源码有个 `EXTERNALSRC_SYMLINKS ?= "oe-workdir:${WORKDIR} oe-logs:${T}"` 的变量，在输出目录的 `conf/local.conf` 将此变量置空 `EXTERNALSRC_SYMLINKS ?= ""` 即可禁止创建。
* oe-workdir: 指向包输出的根目录 `${WORKDIR}`
* oe-logs: 指向包输出的日志和脚本目录 `${WORKDIR}/temp`

## `Please use a umask which allows a+rx and u+rwx` 怎么解决

答：Yocto 编译要求创建的文件夹的权限至少是 755，创建的文件的权限至少是 644，如果出现的如下错误，请检查你是 shell 环境配置的 umask 值，可以运行 `umask 022` 解决此问题
对目录来说，拥有的最大默认权限是 777，对文件来说，可拥有的最大默认权限是 666，文件和目录的初始权限，通过计算得到：`初始权限 = 最大默认权限 - umask权限`

```
$ make
Clean done!
/usr/lib/python3/dist-packages/html5lib/_trie/_base.py:3: DeprecationWarning: Using or importing the ABCs from 'collections' instead of from 'collections.abc' is deprecated since Python 3.3, and in 3.10 it will stop working
  from collections import Mapping
WARNING: You are using a local hash equivalence server but have configured an sstate mirror. This will likely mean no sstate will match from the mirror. You may wish to disable the hash equivalence use (BB_HASHSERVE), or use a hash equivalence server alongside the sstate mirror.
ERROR:  OE-core's config sanity checker detected a potential misconfiguration.
    Either fix the cause of this error or at your own risk disable the checker (see sanity.conf).
    Following is the list of potential problems / advisories:

    Please use a umask which allows a+rx and u+rwx
```

## `aarch64-poky-linux-ld.bfd: cannot find libgcc.a: No such file or directory` 怎么解决

答：说明用户没有使用 Yocto 导出的交叉编译编译变量等 `CC` `LD` ...，请明确下面规则:

* Yocto 编译相当于一个容器或虚拟机，它无法直接获取本地主机的命令和环境变量
    * Yocto 自动依赖了一些基本包，例如 gcc / ls / cp / sed / grep / awk 等，这些不需要填写依赖，但还有一些主机包需要自己在配方文件中声明 DEPENDS += "xxxx-native"，例如包里面运行 bash 脚本需要设置 DEPENDS += "bash-native"
   * Yocto 在输出目录的 conf/local.conf 自定义的环境变量，在配方文件中导出，cbuild的做法是配方继承 cbuild.bbclass 里面导出的环境变量

* Yocto 编译和普通的交叉编译完全不一样
    * 普通编译的交叉编译器会编译交叉编译器时固化了 sysroot arch 等变量，而 Yocto 的交叉编译器没有这些变量，它在导出的 CC 、CFLAGS 变量里面设置，这意味着你使用自己定义的 CC 而不是 Yocto 导出的 CC ，你就要自己关心和设置各种导出的变量，例如不设置 `--sysroot` 可能 C 标准库和头文件都找不到
    * Yocto 编译每个包都有自己的工作目录，称为 WORKDIR https://docs.yoctoproject.org/ref-manual/structure.html#build-tmp-work-tunearch-recipename-version，他的编译输出、安装、依赖等目录都有固定的定义，而不是想怎么用就怎么用，bitbake 解释器会检查各种情况看符不符合他的规则，不符合规则他也就只能拒绝执行，也没办法执行。例如每个包的依赖都是在各自包的工作目录下，由 bitbake 解释器为每个包根据依赖关系准备好，目录都不对就无法准备
    * 普通编译一般每个包只有配置、编译、安装三个任务，Yocto 编译有远远比这多的任务，主要的任务有 准备编译环境 、下载、 解包、 补丁 、配置、编译、安装、打包、部属等
    * 某些子目录的定义要符合linux标准，而不是随便定义，一般是符合 GNUInstallDirs 标准，可以查看下面的链接，都是符合标准定义的
        * GNUInstallDirs/Autotools: https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
        * CMake: https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
        * Meson: https://mesonbuild.com/Builtin-options.html#directories
        * Yocto: https://git.yoctoproject.org/poky/tree/meta/conf/bitbake.conf

## `QA Issue [ldflags]` 怎么解决

答：该错误的打印是 `File '<file>' in package '<package>' doesn't have GNU_HASH (didn't pass LDFLAGS?) [ldflags]`，
错误原因是LDFLAGS默认传了链接参数 `-Wl,--hash-style=gnu`，而编译的库没有使用这个链接参数，解决方法有3个：
* a. 编译动态库时加上链接参数链接参数 `-Wl,--hash-style=gnu`
* b. 修改默认链接参数为sysv，在输出目录的 `conf/local.conf` 加上 `LINKER_HASH_STYLE = "sysv"`
* c. 忽略错误，在recipe文件加上 `INSANE_SKIP:${PN} += "ldflags"`

关于 gnu 和 sysv 的区别请参考 [ld-hash-style](https://answerywj.com/2020/05/14/ld-hash-style/)

## `QA Issue [dev-so]` 怎么解决

答：该错误的打印是 `non -dev/-dbg/nativesdk- package contains symlink .so: <packagename> path '<path>' [dev-so]`，
错误原因是发布包打包了符号链接，具体参考 [打包规则](https://docs.yoctoproject.org/dev-manual/common-tasks.html#working-with-pre-built-libraries) ，解决方法有两个：
* a. 忽略错误，在recipe文件加上 `INSANE_SKIP:${PN} += "dev-so"`  (目前使用方法)
* b. 更细致的打包，如下所示：

```sh
FILES:${PN}-dev = "${includedir} ${libdir}/lib*.so"
FILES:${PN} = "${libdir}/lib*.so.*.*.*"
```

## `QA Issue [file-rdeps]` 怎么解决

答：该错误的打印是 `<packagename> requires <files>, but no providers in its RDEPENDS [file-rdeps]`，
如果编译时LDFLAGS指定了 `-lsonamea`，必须在配方文件加上 `RDEPENDS:${PN} += "packagename1 packagename2"`;
如果还是报此错误，并且依赖的动态库是带版本的，那么编译依赖的动态库时需要加上链接参数 `-Wl,-soname=libxxx.so`

关于链接参数的说明，请查看 [linux下动态库中的soname](https://www.cnblogs.com/wangshaowei/p/11285332.html)


## `QA Issue [already-stripped]` 怎么解决

答：该错误的打印是 `File '<file>' from <recipename> was already stripped, this will prevent future debugging! [already-stripped]`，
错误原因是安装的可执行文件或动态库使用了 strip 命令删除了调试信息，所以我们安装的文件不应该先运行 `$(STRIP) 文件`，
如果我们无法重新构建库，也可以通过忽略错误解决此问题，在recipe文件加上 `INSANE_SKIP:${PN} += "already-stripped"`

## `Error: Unable to find a match: <packagename>` 怎么解决

答：该错误的打印出现在do_rootfs时，错误原因是某个包没有任何输出，或输出只有头文件 或/和 静态库文件，
解决方法有两个
* a. 忽略错误，在recipe文件加上 `ALLOW_EMPTY:${PN} = "1"` (目前使用方法)
* b. 不要将此包加入到do_rootfs变量 `IMAGE_INSTALL:append` ，修改 `build/bin/yocto/inc-yocto-build.mk` 的 IGNORES_RECIPES 变量

## Yocto 官方明明提供了某个包，为什么 bitbake 这个包还是报找不到这个包

答：有多种原因，如下我遇到的几种：
* 配方设置的打包规则没有加上配方名的打包规则，见变量 [PACKAGES](https://docs.yoctoproject.org/ref-manual/variables.html#term-PACKAGES) 说明，例如 `glibc-locale`
* 配方的法律声明没有接受，例如 `ffmpeg`，需要在 `local.conf` 文件加上 `LICENSE_FLAGS_ACCEPTED = "commercial"`
* 配方限制了本包适配的 HOST / MACHINE 等，见变量 [COMPATIBLE_HOST](https://docs.yoctoproject.org/ref-manual/variables.html#term-COMPATIBLE_HOST) [COMPATIBLE_MACHINE](https://docs.yoctoproject.org/ref-manual/variables.html#term-COMPATIBLE_MACHINE)，例如 `x265`

## `Error: Transaction test error:` 怎么解决

答：该错误的打印出现在do_rootfs时，打印信息 `"xxx do_rootfs: Could not invoke dnf. Command..."`， 然后一连串的包列表，然后 `"Error: Transaction test error: file xxx conflicts between attempted installs of xxx and xxx"`。
错误原因是某个包安装的文件和其它包安装的文件路径名相同，此时只能改变其中一个包安装的文件。

有时候我们使用自己的配方编译开源包，Yocto 也有对应的默认配方，此时do_rootfs的时候也可能报错。
例如如果我们使用了自己的配方编译zlib开源库，do_rootfs就报了下面错误
```
Error:
 Problem: package libkmod2-29-r0.cortexa53 requires libz1 >= 1.2.11, but none of the providers can be installed
  - package systemd-1:250.5-r0.cortexa53 requires libkmod.so.2()(64bit), but none of the providers can be installed
  - package systemd-1:250.5-r0.cortexa53 requires libkmod.so.2(LIBKMOD_5)(64bit), but none of the providers can be installed
  - package systemd-1:250.5-r0.cortexa53 requires libkmod2 >= 29, but none of the providers can be installed
  - cannot install both libz1-1.2.11-r0.cortexa53 and libz1-1.0-r0.cortexa53
  - package packagegroup-core-boot-1.0-r17.v5 requires systemd, but none of the providers can be installed
  - conflicting requests
(try to add '--allowerasing' to command line to replace conflicting packages or '--skip-broken' to skip uninstallable packages)
```
此时我们只能删除自定义的配方转而使用官方的配方。

## `do_deploy_source_date_epoch PermissionError`  怎么解决

答: 检查下变量 `EXTERNALSRC_BUILD`，他设错了

```
ERROR: kconfig-native-1.0-r0 do_deploy_source_date_epoch: PermissionError(13, 'Permission denied')
ERROR: Logfile of failure stored in: /home/lengjing/data/cbuild-ng/build/tmp/work/x86_64-linux/kconfig-native/1.0-r0/temp/log.do_deploy_source_date_epoch.27600
Log data follows:
| DEBUG: Executing python function create_source_date_epoch_stamp
| DEBUG: No tarball or git repo found to determine SOURCE_DATE_EPOCH
| DEBUG: Using SOURCE_DATE_EPOCH_FALLBACK
| DEBUG: SOURCE_DATE_EPOCH: 1302044400
| DEBUG: Python function create_source_date_epoch_stamp finished
| DEBUG: Executing python function sstate_task_prefunc
| DEBUG: Python function sstate_task_prefunc finished
```

## 怎么设置使包每次编译都重新编译

答：如果某个包每次编译都要重新编译，用户可以使用 `bitbake -f packagename` 强制编译，但是会有警告 `WARNING: xxx.bb:do_build is tainted from a forced run`, 如果不强制编译又要求每次编译都要重新编译，用户需要在配方文件中 [设置任务属性](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=nostamp#variable-flags) ：
 `do_compile[nostamp] = "1"`

## 如何自定义任务

答：自定义任务至少需要3个内容：任务函数、执行目录和任务声明。如果任务依赖其它包，还需要设置依赖。

* dirs 、depends 和 postfuncs 属性参考  [设置任务属性](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=nostamp#variable-flags) ，其中dirs列出的最后一个目录用作任务的 [当前工作目录](https://docs.yoctoproject.org/ref-manual/variables.html#term-B)
* [addtask](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=addtask#promoting-a-function-to-a-task) 还可以增加 `before` （执行其它任务时先执行此任务） 和 `after` （执行此任务时先执行其它任务） 说明

```sh
do_${task_name} () {
	oe_runmake ${task_name}
}
do_${task_name}[dirs] = "${B}"
do_${task_name}[depends] += "depend_package_name1:task_name depend_package_name2:task_name"
addtask ${task_name}
```

例如增加自定义任务：加载特定Kconfig配置 user_defined_config 到当前配置的任务

```sh
do_user_defined_config () {
	oe_runmake user_config
}
do_user_defined_config[dirs] = "${B}"
do_user_defined_config[nostamp] = "1"
do_user_defined_config[depends] += "kconfig-native:do_populate_sysroot"
do_user_defined_config[postfuncs] += "do_setrecompile"
addtask user_defined_config
```
