# Kconfig 语法简介

* 参考资料: Linux 内核官方文档的 [kconfig-language](https://www.kernel.org/doc/html/latest/kbuild/kconfig-language.html) 和 [kconfig-macro-language](https://www.kernel.org/doc/html/latest/kbuild/kconfig-macro-language.html)
* 界面操作: Kconfig 界面一般是使用 `方向键` 移动选项，`空格键` 改变选项，`回车键` 进入子菜单，`ESC键` 返回或退出
* 注释: Kconfig 使用 `#` 作为单行注释

## mainmenu 主菜单语法

```
mainmenu "主菜单名"
```

* mainmenu 标志 Kconfig 开始，是输入 `make menuconfig` 后打开的默认界面

```
mainmenu "Test Configuration"
```

## config 模块语法

```
config 配置项
    配置项类型 "配置项名"
    其它选项

config 配置项
    配置项类型
    prompt "配置项名"
    其它选项
```

* 配置项: 决定保存在 .config 文件中的键值对的键名(`CONFIG_配置项`)
* 配置项类型: 决定保存在 .config 文件中的键值对的键值类型，可选的类型有 bool tristate string int hex
    * bool    : 布尔型，在 .config 中以 `y n` 表示
    * tristate: 三态型，在 .config 中以 `y n m` 表示，
        * 在内核驱动中: y表示将驱动编译进内核镜像，n表示不编译，m表示将驱动编译为ko形式
    * string  : 字符串型，在 .config 中以 `"原样"` 表示
    * int     : 数字型(十进制)，在 .config 中以 `原样` 表示
    * hex     : 数字型(十六进制)，在 .config 中以 `原样` 表示
* 配置项名: 显示在界面上的配置项名称，可以和配置项类型合并写，也可以使用关键字 `prompt` 分开写，prompt 提示最多只有一条有效
* 其它选项: 见子段落说明

```
config KCONFIG_BOOL_ITEM1
    bool "kconfig bool item1 learning"

config KCONFIG_BOOL_ITEM2
    bool
    prompt "kconfig bool item2 learning"

config KCONFIG_TRISTATE_ITEM
    tristate "kconfig tristate item learning"

config KCONFIG_STRING_ITEM
    string "kconfig string item learning"

config KCONFIG_INT_ITEM
    int "kconfig int item learning"

config KCONFIG_HEX_ITEM
    hex "kconfig hex item learning"
```

### depends on / visible 依赖项语法

```
config 配置项
    配置项类型 "配置项名"
    depends on 依赖的配置项

config 配置项
    配置项类型 "配置项名"
    visible if 依赖的配置项
```

* depends on 依赖的配置项设为 y 时，本设置项才会显示，才可以被设置为 y
* visible 条件为真时该设置项才显示，即使不显示也可以被其他设置项 select 将该设置项的值设为 y

```
config DEPEND_BOOL_ITEM
    bool "depends on bool item1 learning"
    depends on KCONFIG_BOOL_ITEM1

config DEPEND_STRING_ITEM
    string "depends on bool item2 learning"
    depends on KCONFIG_BOOL_ITEM2

config DEPEND_AND_ITEM
    bool "depends on bool item1 and item2 learning"
    depends on (KCONFIG_BOOL_ITEM1 && KCONFIG_BOOL_ITEM2)

config DEPEND_OR_ITEM
    bool "depends on bool item1 or item2 learning"
    depends on (KCONFIG_BOOL_ITEM1 || KCONFIG_BOOL_ITEM2)
```

### select / imply 选择项语法

```
config 配置项
    bool "配置项名"
    select 选择的配置项
```
```
config 配置项
    bool "配置项名"
    imply 选择的配置项
```

* 设置项设置 y 时，select 选择的选项也会设为 y，且无法修改为 n
* 设置项设置 y 时，imply 选择的选项也会设为 y，但可以显式修改为 n

```
config SELECT_BOOL_ITEM1
    bool "select bool item1 and item2 learning"
    select KCONFIG_BOOL_ITEM1
    select KCONFIG_BOOL_ITEM2

config SELECT_BOOL_ITEM2
    bool "imply bool item1 learning"
    imply KCONFIG_BOOL_ITEM1
```

### default 默认值语法

```
config 配置项
    配置项类型 "配置项名"
    default 配置项值
```

* 给配置项默认值

```
config DEFAULT_BOOL_ITEM
    bool "bool item default y learning"
    default y

config DEFAULT_STRING_ITEM
    string "string item default lengjing learning"
    default "lengjing"

config DEFAULT_INT_ITEM
    int "int item default 100 learning"
    default 100
```

### range 范围值语法

```
config 配置项
    配置项类型 "配置项名"
    range 值1 值2
```

* 限制 int 和 hex 类型符号的输出值的范围(含)

```
config RANGE_INT_ITEM
    int "int item range 0~127 learning"
    range 0 127
````

### help 帮助信息语法

```
config 配置项
    配置项类型 "配置项名"
    help
    帮助信息语句1
    帮助信息语句2
```

* 移动到该配置项后，按 `H键` 显示帮助信息

```
config HELP_BOOL_ITEM
    bool "item help information learning"
    help
    This item has help information,
    It is a bool item.
```

### comment 注释信息语法

```
comment "注释信息"
```

* 注释信息会在界面显示，也会写入到 .config 文件中

```
comment "comment item learning"
```

### if 表达式语法

* `if` / `depends on` 可使用 `表达式语法`
* `类型关键字` / `prompt` / `default` / `select` / `imply` / `visible` / `range` 关键字可使用 `if 表达式语法`
* 表达式语法
    * `配置项`              : bool 和 tristate 简单转换为相应配置项的值，其他类型转换为 n
    * `配置项 = 配置项/值 ` : 两个配置项相等返回 y，否则返回 n 
    * `!=` `<` `<=` `>` `>=`: 使用方法参考相等
    * `(表达式)`            : 改变计算优先级
    *  `! 表达式`           : 逻辑非
    * `表达式 && 表达式`    : 逻辑与
    * `表达式 || 表达式`    : 逻辑或

## menu 模块语法

```
menu "配置项名"
    其它选项

子配置模块1

...

子配置模块n

endmenu
```

* 移动到menu配置项后，按 `回车键` 可以进入子菜单界面
* menu 配置项名会作为注释写入 .config 文件中

```
menu "menu item learning"

config MENU_BOOL_SUBITEM
    bool "bool subitem in menu learning"

config MENU_STRING_SUBITEM
    string "string subitem in menu learning"

endmenu
```

## menuconfig 模块语法

```
menuconfig 配置项
    bool "配置项名"
    其它选项

if 配置项

子配置模块1

...

子配置模块n

endif
```

* 配置项名可以和配置项类型合并写，也可以使用关键字 prompt 分开写
* `空格键` 选中 menuconfig 配置项后，按 `回车键` 可以进入子菜单界面

```
menuconfig MENUCONFIG_ITEM
    bool "menuconfig item learning"

if MENUCONFIG_ITEM

config MENUCONFIG_BOOL_SUBITEM
    bool "bool subitem in menuconfig learning"

config MENUCONFIG_STRING_SUBITEM
    string "string subitem in menuconfig learning"

endif
```

## choice 模块语法

```
choice 配置项
    prompt "配置项名"
    其它选项

bool子配置模块1

...

bool子配置模块n

endchoice
```

* 移动到 choice 配置项后，按 `回车键` 可以进入子菜单界面，只能选中其中一个选项

```
choice CHOICE_ITEM
    prompt "choice item learning"
    default CHOICE_SUBITEM2

config CHOICE_SUBITEM1
    bool "choice subitem1"

config CHOICE_SUBITEM2
    bool "choice subitem2"

endchoice
```

## source 包含文件语法

```
source "文件路径名"
```

* Kconfig 文件中 source 子 Kconfig 文件的相对路径默认是 mconf/conf 运行时的路径，而不是当前 Kconfig 文件的路径
* 运行 Kconfig 时可以使用 srctree 修改此默认值，例如 `srctree=路径名 mconf 顶层Kconfig路径名`

## Kconfig变量和函数

* 变量或函数定义
    * `val := value`                : 简单扩展变量，读到该行时，它的右边立刻扩展
    * `val  = value`                : 递归扩展变量，当变量使用时才真正扩展
    * `val += value`                : 向变量追加文本，不改变符号的扩展属性
* 调用变量
    * `$(val)`                      : 调用变量
* 调用函数
    * `$(func,arg1,arg2...)`        : 调用函数，参数与函数名/参数之间使用逗号隔开，逗号之间无空格
        * 和 Makefile 不同，逗号始终是函数的分隔符，要使用逗号，请使用变量替换
        * 变量不能跨标记扩展(例如一个变量不能作为 range 关键字的两个参数)
        * 变量不能扩展为 Kconfig 中的任何关键字
* 内建函数
    * `$(shell,command)`            : 扩展为执行的子命令 command 的标准输出
    * `$(info,text)`                : 发送一段文本 text 到标准输出
    * `$(warning-if,condition,text)`: 如果条件为真，则发送文本 text 和当前 Kconfig 文件名以及行号到错误输出
    * `$(error-if,condition,text)`  : 如果条件为真，则发送文本 text 和当前 Kconfig 文件名以及行号到错误输出，并立刻终止解析
    * `$(filename)`                 : 扩展为被解析的文件名
    * `$(lineno)`                   : 扩展为被解析的行号

```
$(shell, echo hello, world) # 是一个错误
comma := ,
$(shell, echo hello$(comma) world) # 变量替换方法
```

## Kconfig常用运行参数

```
CONF_OPTIONS      = $(KCONFIG) \
					--configpath $(CONFIG_PATH) \
					--autoconfigpath $(AUTOCONFIG_PATH) \
					--autoheaderpath $(AUTOHEADER_PATH)
mconf $(CONF_OPTIONS)
conf $(CONF_OPTIONS) --silent --syncconfig
conf $(CONF_OPTIONS) --defconfig <conf_name>
conf $(CONF_OPTIONS) --savedefconfig <conf_name>
```

* `KCONFIG`: 顶层 Kconfig 路径名
* 变量设置
    * `CONFIG_PATH`     : 设置 .config 文件的保存路径，不设置时是 .config
    * `AUTOCONFIG_PATH` : 设置 auto.conf 文件的保存路径，不设置时是 include/config/auto.conf
        * 注意指定此项的值时请指定一个带文件夹路径的值，它会在这个文件夹下生成一系列的以配置项作为文件名的文件
    * `AUTOHEADER_PATH` : 设置 autoconf.h 文件的保存路径，不设置时是 include/generated/autoconf.h
    * 注: `--configpath / --autoconfigpath / --autoheaderpath` 是本工程加的设置参数，原始 Kconfig 工程是通过导出环境变量 `CONFIG_PATH / AUTOCONFIG_PATH / AUTOHEADER_PATH` 来设置的
* 运行参数
    * `mconf $(CONF_OPTIONS)`                             : 打开 menuconfig 菜单
    * `conf $(CONF_OPTIONS) --silent --syncconfig`        : 根据当前文件解析生成 conf 文件和 C 头文件
    * `conf $(CONF_OPTIONS) --defconfig <conf_name>`      : 加载 conf_name 指定的配置到当前配置
    * `conf $(CONF_OPTIONS) --savedefconfig <conf_name>`  : 保存当前配置到 conf_name 指定的配置
