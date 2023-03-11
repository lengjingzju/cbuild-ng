# Makefile 笔记

* 参考文档
    * [GNU Make Manual](https://www.gnu.org/software/make/manual/make.html)
    * [Kernel Build System](https://www.kernel.org/doc/html/latest/kbuild/index.html)
    * [GCC 12.1 Manual](https://gcc.gnu.org/onlinedocs/gcc-12.1.0/gcc/)
    * [GNU ld Manual](https://sourceware.org/binutils/docs-2.39/ld/index.html)

## 编译基础知识

* 4个编译过程
    1. `gcc -E test.c -o test.i` : 预处理(Preprocessing)
        * 处理宏定义和 include，去除注释，不会对语法进行检查，生成的还是C代码，默认不生成文件，而是直接输出到终端
    2. `gcc -S test.i -o test.s` : 编译(Compilation)
        * 检查语法，生成汇编代码，默认生成 `*.s` 文件
    3. `gcc -c test.s -o test.o` or `as test.s -o test.o` : 汇编(Assembly)
        * 生成 ELF 格式的目标代码，默认生成 `*.o` 文件
    4. `gcc    test.o -o test` or `ld test.o -o test` : 链接(Linking)
        * 链接启动代码、库等，生成可执行文件，默认生成 `a.out` 文件
        * 只有在链接阶段才会检查所有函数是否已经定义，没有定义会报错找不到函数

* gcc 常用选项
    * 指定输出
        * `-o output`           : 指定编译生成的文件名为 output
    * 编译选项
        * `-c`                  : 编译生成 ELF 格式的目标代码，但不进行最后的链接
        * `-fPIC`               : 生成位置无关代码，编译动态库必须
        * `-Idir`               : 指定头文件的搜索路径
        * `--sysroot`           : 设置编译链接默认搜索头文件和库文件的根目录
        * `-ffunction-sections -fdata-sections` : 将每个函数和变量放入到各自独立的 section
    * 链接选项
        * `-static`             : 链接时强制链接静态库，单个文件即可执行，不依赖动态链接库，具有较好的兼容性，缺点是生成的程序比较大
        * `-shared`             : 编译生成动态库
        * `-lname`              : 链接库 libname.so 或 libname.a，例如 `-lpthread` 是链接 libpthread.so 库
        * `-Ldir`               : 指定库文件的搜索路径
        * `-Wl,-soname=name`    : 指定生成动态库的名称，可以使用 `readelf -d libxxx.so` 读到这个名称
        * `-Wl,-rpath-link=dir` : 指定子库文件链接的库文件的搜索路径
        * `-Wl,--gc-sections`   : 按 section 链接，和编译对应的选项合用，则链接器 ld 不会链接未使用的函数，从而减小可执行文件大小
    * 定义变量
        * `-Dname`              : 定义宏 name，默认定义内容为 `1`
        * `-Dname=value`        : 定义宏 name，值为 `value`，例如 `-DMAX_MUM=1024` 类似定义了 `#define MAX_MUM 1024`
        * `-Dname=\"value\"`    : 定义宏 name，值为 `字符串value`，例如 `-DAUTHOR=\"LengJing\"` 类似定义了`#define AUTHOR "LengJing"`
    * 优化等级，总共 `-O0 -O1 -O2 -Os -O3` 5个等级
            * `-O0`             : 默认优化等级，不优化用于调试
            * `-O1`             : 缺省优化等级 `-O`，编译器会尝试减少代码大小和执行时间的优化，而不执行任何需要大量编译时间的优化
            * `-O2`             : 增加了编译时间，编译器进一步优化了生成代码的性能，**一般用于发布的程序**
            * `-Os`             : 编译器禁用了 `-O2` 增加生成代码大小的优化，**强调大小而不是速度**
            * `-O3`             : 增加了生成代码的大小，编译器进行了函数展开和循环展开等优化，生成代码的性能不一定比 `-O2` 更好
            * `-g -ggdb`        : 生成带有调试信息的目标文件，可用于 gdb 调试
    * 警告选项
        * `-w`                  : 关闭所有警告
        * `-Wall`               : 使 gcc 产生尽可能多的警告信息
        * `-Wextra`             : 使 gcc 产生额外的警告信息，老的名称是 `-W`
        * `-Werror`             : 使 gcc 在产生警告的地方停止编译
        * `-Wxxx`               : 打开特定警告
        * `-Wno-xxx`            : 关闭特定警告
        * `-v`                  : 列出详细编译过程

* 链接过程
    * 链接分类
        * Linux 下的库文件分为两大类分别是动态链接库(通常以 `.so` 结尾)(运行时动态加载)和静态链接库(通常以 `.a` 结尾)(编译时静态加载)
        * 默认情况下，gcc 在链接时优先使用动态链接库，只有当动态链接库不存在时才考虑使用静态链接库，在编译时加上 `-static` 选项将强制使用静态链接库
        * 静态链接的可执行文件单文件即可执行，不依赖动态链接库，具有较好的兼容性，库的代码直接插入了可执行文件，生成的程序比较大
        * 动态链接的可执行文件需要把链接的动态库复制到 `/usr/lib` (或修改环境变量) 才可以执行，生成的程序比较小，多个程序共享同一个库，占用较少的内存，库有变化升级时也只需要重新编译库
    * 动态库链接和执行时搜索路径顺序
        1. 编译目标代码时指定的动态库搜索路径 `-L`
        2. 环境变量 `LD_LIBRARY_PATH` 指定的动态库搜索路径
        3. 配置文件 `/etc/ld.so.conf` 中指定的动态库搜索路径
        4. 默认的动态库搜索路径 `/lib` `/usr/lib`
    * 静态库链接时搜索路径顺序
        1. ld会去找GCC命令中的参数 `-L`
        2. 再找gcc的环境变量 `LIBRARY_PATH`
        3. 再找系统内定目录 `/lib` `/usr/lib` `/usr/local/lib`

## make 命令参数

* 常用命令
    * `make`            : 执行当前目录下的 Makefile 的默认目标 (Makefile 文件查找顺序: `GNUmakefile` `makefile` 和 `Makefile`)
    * `make <target>`   : 执行当前目录下的 Makefile 的指定目标 target，可以同时运行多个 target，但要注意多线程
    * `make -f <file>`  : `--file=file, --makefile=FILE`，执行当前目录下的指定 Makefile (file) 的默认目标
    * `make -C <dir>`   : `--directory=dir`，进入 dir 目录，然后执行其下的 Makefile 的默认目标，再返回当前目录，相当于 `cd dir && make && cd -`
    * `make -s`         : `-silent, --quiet`，静默模式，不要打印运行的命令，子 Makefile 会继承此参数
    * `make -j <jobs>`  : `--jobs=jobs`，使用多核编译，例如 `make -j8` 使用8核编译，注: `echo $(nproc)` 的输出结果为 cpu 线程数
    * `make var=value`  : 传入变量，在 Makefile 中使用变量 `$(var)` 的地方替换成它的值 `value`
        * Makefile 中对这个变量的赋值会被忽略，除非使用 override 关键字才能改变其值 `override var = newvalue` `override var += value2`
            * override 标记的赋值比所有其他赋值具有更高的优先级，除了另一个 override，未标记的后续赋值将被忽略

* 一般命令
    * `make -I <dir>`   : `--include-dir=dir`，为 Makefile 文件 include 指令包含的文件指定搜索路径
    * `make -e`         : `--environment-overrides`，默认 Makefile 文件定义的环境变量覆盖环境变量，此参数改为环境变量优先
    * `make -i`         : `--ignore-errors`，忽略错误继续执行
    * `make -k`         : `--keep-going`，忽略出错的目标和依赖它的目标，继续执行其它目标，子 Makefile 会继承此参数
    * `make -S`         : `--no-keep-going, --stop`，取消 `-k` 参数

* 调试命令
    * `make -n`         : `--just-print, --dry-run, --recon`，只打印不执行要执行的命令，可能命令还会执行，例如 shell 多条件判断
    * `make --trace`    : 打印并执行要执行的命令和打印执行的原因
    * `make -w`         : `--print-directory`，打印执行的 Makefile 的工作目录
    * `make -W <file>`  : `--what-if=file, --new-file=file, --assume-new=file`，假装文件被更新，和 `-n` 命令合用看看文件更新会发生什么
    * `make -p`         : `--print-database`，打印读取 Makefile 产生的数据库(规则和变量值)，然后照常执行
    * 注: Makefile 中可以使用 `$(info text)` `$(warning text)` `$(error text)` 打印信息，其中 error 会停止执行 Makefile

## make 执行过程

* 第一阶段: 解析，make 读取 Makefile、包含的子 Makefile 等，并解析所有变量及其值以及隐式和显式规则，并构建所有目标及其先决条件的依赖图
    * 读入完整的逻辑行，包括反斜杠转义的行，扫描该行以查找分隔符和关键字，以确定该行属性
        * 如果是注释行，删除该行
        * 如果是变量赋值行，定义的变量立即展开，赋值给变量的值有参考如下展开规则:
            * `= ?=`    : 延迟展开: 递归扩展，取最后的值
            * `:= ::=`  : 立即展开: 简单扩展，取当前位置的值
            * `+=`      : 如果该变量先前定义的是简单变量(使用 `:= ::= !=` 赋值的变量)则立即展开，否则延迟展开
            * `!=`      : shell 赋值运算符，立即展开
        * 如果是规则定义行，规则中的目标和依赖立即展开
        * 如果是规则下命令块的行，延迟展开，且将该行添加到当前规则
        * 如果是函数定义行(`define ... endef`)，函数名立即展开
        * 如果是条件指令行(`ifeq ... else ifeq ... else ... endif` `ifdef ... else ifdef ... else ... endif`)，条件立即展开
* 第二阶段: 执行，make 使用此内部化数据来确定需要更新哪些目标并运行更新它们所需的配方
    * 默认目标第一条规则的目标。如果第一条规则有多个目标，则仅将第一个目标作为默认目标，有2个例外:
        * 以点号`.`开头的目标不是默认目标，除非它包含一个或多个斜杠 '/'
        * 定义模式规则(含 `%` )的目标不是默认目标
    * 伪目标始终执行，使用标签 `.PHONY: target1 target2 ...` 避免与同名文件发生冲突，以及提高性能(为目标跳过隐式规则搜索)
        * 除了用标签 `.PHONY` 声明伪目标外，还可以定义一个不带依赖和命令块的规则，规则的目标是伪目标
    * 文件目标不存在，或目标依赖的文件比他新，或目标依赖了伪目标，此时文件目标才会执行
        * 先找到目标下依赖的伪目标和比它新的依赖文件定义的目标，同理递归，直到找到最终的原始文件和最基本的伪目标，从树叶到树干依次执行
        * 然后执行文件目标下的命令块 (依赖伪目标的目标的命令块会始终执行)
    * 如果找寻的过程中依赖找不到或某个依赖的命令执行出错，默认会终止退出执行

## Makefile 编译规则

* 例子: 常规写法

```makefile
main: main.o stack.o maze.o
	gcc main.o stack.o maze.o -o main
main.o: main.c main.h stack.h maze.h
	gcc -c main.c
stack.o: stack.c stack.h main.h
	gcc -c stack.c
maze.o: maze.c maze.h main.h
	gcc -c maze.c
.PHONY: clean
clean:
	-rm main main.o stack.o maze.o
	@echo "clean completed"
```

* 例子: 变量替换，多目标对应一组依赖，同一目标依赖写成多条

```makefile
objects = main.o stack.o maze.o
main: $(objects)
	gcc $(objects) -o main
$(objects): main.h
main.o stack.o: stack.h
main.o maze.o: maze.h
.PHONY: clean
clean:
	-rm main $(objects)
	@echo "clean completed"
```

* 例子: [隐式规则](https://www.gnu.org/software/make/manual/html_node/Catalogue-of-Rules.html#Catalogue-of-Rules)
    * 隐式规则会自动为 `xxx.o` 的目标推导 `$(CC) $(CPPFLAGS) $(CFLAGS) -c xxx.c` 的命令
    * 隐式规则会自动为 `xxx.o` 的目标推导 `$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c xxx.cpp` 的命令 (源文件也可能是 xxx.cc xxx.C)
```makefile
main: main.o stack.o maze.o
	gcc $^ -o $@
main.o: main.h stack.h maze.h
stack.o: stack.h main.h
maze.o: maze.h main.h
.PHONY: clean
clean:
	-rm main *.o
	@echo "clean completed"
```

* 例子: 静态模式规则，`%.o: %.c` 解释为取 `%.o` 的模式 `%`，并为其加上 `.c` 的后缀，即目标的 .o 换成 .c，这个 .c 文件当做该目标的依赖

```makefile
objects = $(patsubst %.c,%.o,$(wildcard *.c))
main: $(objects)
	gcc $^ -o $@
$(objects): %.o: %.c
	gcc -c $< -o $@
```

* 例子: 推导头文件依赖

```makefile
# 目录下对应的.c文件编译成.o
objects = $(patsubst %.c,%.o,$(wildcard *.c))
depends = $(patsubst %.o,%.d,$(objects))
main: $(objects)
	gcc $^ -o $@
$(objects): %.o: %.c
	gcc -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	gcc -c $< -o $@
-include $(depends)
```

* 规则语法

```makefile
# 基本规则格式
target ... : prerequisites ...
	command
	command
	...

# 静态模式规则
targets ...: target-pattern: dep-patterns ...
	commands
	...
```

* 规则说明
    * 元素组成
        * target        : 目标，多个目标可以用空格隔开，目标可以是文件(Object File)，也可以是标签(Label)
        * prerequisites : 依赖，多个依赖可以用空格隔开，生成 target 所需要的文件或目标
            * 一个目标的所有依赖不一定非得写在一条规则中，也可以拆开写
            * 多线程编译时依赖是并行执行的，所以注意依赖关系，写的不好就可能单线程编的过，多线程却失败
        * command       : 命令块，一般来说，make 会使用 sh 来执行命令
            * 命令行另起一行时，必须以制表符 TAB 开头，不能用空格
            * 命令前加 `@` 表示不显示命令本身而只显示它的结果
            * 命令前加 `-` 表示忽略命令执行失败
                * 通常执行的命令如果出错(该命令的退出状态非0)就立刻终止，不再执行后续命令
                * 如果命令前面加了 `-` 号，即使这条命令出错，make 也会继续执行后续命令
                * 还有一个全局的办法是 `make -i`
            * 如果一个目标有多条规则
                * 其中只有一条规则允许有命令块，其它规则不能有，否则 make 会报警告并且采用最后一条规则的命令块
                * 所有规则都没有命令块时，make 会尝试在内建的隐含规则(Implicit Rule)数据库中查找适用的规则
            * 同一行或多行
                * 命令块中的每一行调用一个新的子 shell 来执行，除非规则前加了 `.ONESHELL: `
                * 每行都是独立的作用域和环境，因此，相互之间变量不可以共享，且上一条命令产生的作用不会影响到下一行的，例如 `cd dir`
                * 命令后加 ` ;\` 表示下一行和当前行是同一作用域和环境，此时相互之间变量可以共享，上一条命令的结果会应用在下一条命令
                * 命令行和`目标: 依赖`在同一行时，可以使用分号 `;` 分隔；一行多个命令可以用分号 `;` 分隔，行尾有无分号均可
                * 在命令行之间中的空格或是空行会被忽略，但是如果该空格或空行是以制表符 TAB 开头的，那么 make 会认为其是一个空命令

    * [约定的标准目标](https://www.gnu.org/software/make/manual/html_node/Goals.html#Goals)
        * all       : 执行主要的编译工作，通常用作默认目标
        * install   : 执行编译后的安装工作，把可执行文件、配置文件和文档等分别拷到不同的安装目录
        * clean     : 删除编译生成的文件(二进制文件等)
        * distclean : 删除所有的生成文件(二进制文件和其它生成的文件，如配置文件和格式转换后的文档)
        * 注: Makefile 中可以使用 `$(MAKECMDGOALS)` 获取 make 命令运行的 target

    * [自动变量](https://www.gnu.org/software/make/manual/make.html#Automatic-Variables)
        * `$@`          : 表示规则中的目标
        * `$<`          : 表示规则中的第1个依赖
        * `$^`          : 表示规则中的所有依赖组成一个列表，以空格分隔
        * `$?`          : 表示规则中所有比目标新的依赖组成一个列表，以空格分隔
        * 以下是某些不常用的自动变量，不是全部
        * `$(@D)`       : 表示规则中的目标文件名的目录部分(末尾没有斜杠)，相当于 `$(patsubst %/,%,$(dir $@))`
        * `$(@F)`       : 表示规则中的目标文件名的文件部分，相当于 `$(notdir $@)`
        * `$(<D)` `$(<F)`: 表示规则中的第1个依赖的文件名的目录部分和文件部分，相当于 `$(patsubst %/,%,$(dir $<)) $(notdir $<)`
        * `$(^D)` `$(^F)`: 表示规则中的所有依赖的目录部分和文件部分，相当于 `$(foreach v,$^,$(patsubst %/,%,$(dir $v)) $(notdir $v))`
        * `$(?D)` `$(?F)`: 表示规则中的所有比目标新的依赖的目录部分和文件部分，相当于 `$(foreach v,$?,$(patsubst %/,%,$(dir $v)) $(notdir $v))`

    * [静态模式规则](https://www.gnu.org/software/make/manual/html_node/Static-Usage.html#Static-Usage)
        * 静态模式规则是指定多个目标并根据目标名为每个目标构造依赖名的规则
        * 每一条规则都精确的用于指定的目标上，可以重载隐式规则链，例如编译输出 `objects = $(patsubst %.c,$(outpath)/%.o,$(wildcard *.c))` 都放在 outpath 目录的规则: `$(objects): $(outpath)/%.o: %.c`
        * 隐式规则可以应用于与其模式匹配的任何目标，但它仅在目标没有另外指定的命令块时才适用，并且仅在可以找到依赖时才适用
    * 含模式规则(`%` )的目标名
        * 模式规则目标只有一条规则，即模式规则的依赖不能分成多条规则写，只能写在有命令块的那条规则的依赖中
        * 模式规则遵循最优规则，例如定义了 `%_config` `user_%_config` 两个规则，`make user_defaut_config` 运行的是 `user_%_config` 目标
        * 模式规则遵循先到先得规则，例如定义了 `%_config` `user_%` 两个规则，`make user_defaut_config` 运行的是 `%_config` 目标
        * 模式规则目标的目标的模式不能匹配 `/`，而其它地方却可以匹配

    * [自动推导依赖](https://www.gnu.org/software/make/manual/html_node/Automatic-Prerequisites.html#Automatic-Prerequisites)
        * `gcc -MM -MT xxx.o -MF xxx.d xxx.c`
            * `-MM` / `-M`  : 根据源代码中的 #include 语句推导出依赖，`-MM` / `-M` 分别表示依赖 `不包含/包含` 标准库的头文件
            * `-MT xxx.o`   : 指定规则中的目标
            * `-MT xxx.d`   : 指定规则保存的文件，不指定时输出到终端

    * 高级特性(很少用到)
        * [内建目标](https://www.gnu.org/software/make/manual/html_node/Special-Targets.html#Special-Targets)
            * 内建目标目标名是 `.大写字母单词`，有些特殊意义
        * [分组目标](https://www.gnu.org/software/make/manual/html_node/Multiple-Targets.html#Multiple-Targets)
            * 分组目标的目标和依赖使用 `&:` 分隔，和普通目标相比它要求该条规则下必须带命令块
        * [双冒号规则](https://www.gnu.org/software/make/manual/html_node/Double_002dColon.html#Double_002dColon)
            * 双冒号规则使用双冒号 `::` 替换了普通规则目标和依赖之间的的单冒号 `:`
            * 当一个目标出现在多个规则中时，所有的规则必须是相同的类型: 都是普通的，或者都是双冒号
            * 具有相同目标的双冒号规则实际上是完全分开的，每个双冒号规则都是单独处理的，就像处理具有不同目标的规则一样
            * 目标的双冒号规则按照它们在 makefile 中出现的顺序执行，某条双冒号规则是否执行取决于这条规则的依赖等
            * 每个双冒号规则都应该带命令块，如果不适用，则将使用隐含规则

* 例子: 在命令块中使用 shell 的条件语句和循环语句

```
strip_elfs:
	@dirs="/lib /bin /usr/lib /usr/bin /usr/local/lib /usr/local/bin"; \
		for vdir in $${dirs}; do \
			if [ -d $(FAKEROOT_DIR)$${vdir} ]; then \
				for vfile in $$(ls $(FAKEROOT_DIR)$${vdir}); do \
					if [ $$(file $(FAKEROOT_DIR)$${vdir}/$${vfile} | grep -c "not stripped") -eq 1 ]; then \
						$(STRIP) $(FAKEROOT_DIR)$${vdir}/$${vfile}; \
					fi; \
				done; \
			fi; \
		done
```

* 包含 `include`
    * 语法
        * `include x1.mk x2.mk ...` : 可以包含多个文件
        * `include *.mk` : 可以使用通配符 `*`
        * `include $(depends)` : 可以使用变量
        * `-include ...` : 文件不存在不报错退出
    * make 命令开始时，会查找 include 的其它文件并将其内容放在在当前的位置
    * 如果文件是相对路径，make 会在当前目录下首先寻找，如果没找到则在 `make -I <dir>` 指定的目录下去寻找，否则在系统目录下查找
        * 系统目录是 `prefix/include` `/usr/gnu/include` `/usr/local/include` `/usr/include`
    * 在 include 前面可以有一些空字符，但是绝不能是制表符开始

* 注释 `#`
    * `#` 号在 Makefile 中表示单行注释
        * 除在 `define` 指令内部外，注释可以出现在 Makefile 文件的任何地方，甚至在命令内部(这里 shell 决定什么是注释内容)

* 换行 `\`
    * 在规则的命令块之外，`\换行` 被转换为单个空格字符，完成后，`\换行` 周围的所有空格都会压缩为一个空格
        * 要去掉空格，请在上一行的字符串之后紧跟着 `$`，例如 var1 定义了 `one$ word`，`$ ` 的值为空，即定义了 `oneword`
    * 在规则的命令块内，`\换行` 都被保留并传递给 shell，如何解释 `\换行` 取决于您的 shell
        * 如果 `\换行` 之后的下一行的第一个字符是制表符，这个制表符将会删除

* 例子: 换行

``` makefile
var1 := one$\
        word
var2 := two \
        words

all:
	@echo $(var1)
	@echo $(var2)
	@echo no\
space
	@echo no\
	space
	@echo one \
	space
	@echo one\
	 space
	@echo 'hello \
	world'
	@echo "hello \
	world"
```

```
# 结果
oneword
two words
nospace
nospace
one space
one space
hello \
world
hello world
```

* 指定搜索目录
    * 目标和依赖列出的文件默认只会在当前目录中查找，如果指定搜索目录，还会在搜索目录查找，按顺序找到的第一个文件作为结果
    * `VPATH = dir1:dir2`   : `VPATH` 变量为所有类型的文件指定搜索目录，多个目录之间要使用 `空格` 或是 `:` 隔开
    * `vpath`               : `vpath` 指令为特定类型的文件创建搜索目录规则，文件类型使用 `%` 模式替换
        * `vpath pattern dir1:dir2`     : 为符合模式 pattern 的文件指定搜索目录 dir1 和 dir2，例如 `vpath %.h include:src`
        * `vpath dir1:dir2`             : 为所有类型的文件指定搜索目录 dir1 和 dir2
        * `vpath <pattern>`             : 清除符合模式 pattern 的文件的搜索目录
        * `vpath`                       : 清除所有类型的文件的搜索目录

* 使用条件
    * `ifdef` `ifndef` `ifeq` `ifneq` 和 `else` `endif` 类似C语言中的条件编译，这些关键字都要顶格写
    * ifdef 表示变量定义了(即使是空值)就使用其下语句块，ifndef 相反
    * ifeq 表示变量等于值就使用其下语句块，ifneq 相反
    * 在条件指令行的开头允许并忽略额外的空格，但不允许使用制表符

```makefile
ifdef CONFIG_NAME1
command or variable_definition
...
else ifdef CONFIG_NAME2
command or variable_definition
...
else
command or variable_definition
...
endif
```

```makefile
ifeq ($(CONFIG_NAME1),value1)
command or variable_definition
...
else ifeq ($(CONFIG_NAME2),value2)
command or variable_definition
...
else
command or variable_definition
...
endif
```

## Makefile 变量规则

* 变量定义 `变量名 赋值运算符 值`
    * 变量名可以由任何不是 `:` `#` `=` `空格` 的字符构成，且区分大小写
    * 变量名可以使用引用变量，**变量名中的变量简单扩展**
    * 变量在定义时需要给予初值，赋给变量的值是字符串，不需要使用引号包含值
    * 变量值左边的空格省略，右边的空格保留
    * 取消变量定义使用 `undefine 变量名`

* 变量使用 `$(变量名)`
    * 变量在使用时，需要给在变量名前加上 `$` 符号，最好用小括号 `()` 或是大括号 `{}` 把变量给包起来，否则只会将 `$` 后的单个字符视为变量名
    * 真实的 `$` 字符需要用 `$$` 来表示；如果启用了二次扩展真实的 `$` 字符需要用 `$$$$` 来表示
    * 变量可以使用在许多地方，如规则中的目标、依赖、命令块以及变量名、变量值、函数参数等

* 扩展方式
    * 递归扩展 : 引用变量时变量的值延迟展开，即取变量最终的值
        * 递归扩展不能将该变量的引用赋给该变量，即不能类似 `var = $(dirname $(var))` 这样的调用
    * 简单扩展 : 引用变量时变量的值立即展开，即取变量当前位置的值
    * [二次扩展](https://www.gnu.org/software/make/manual/html_node/Secondary-Expansion.html#Secondary-Expansion) : 要申明 `.SECONDEXPANSION:` 启用二次扩展，此时`$$(var)` 则可以扩展为变量 var 的值
    * 运行扩展 : 命令块中调用 shell 时获取结果是在运行到该语句时扩展的

* 变量赋值
    * `= `  : 延迟赋值，**递归扩展**
    * `?=`  : 默认赋值，变量如果先前没有被赋值才赋这个值
    * `:=`  : 立即赋值，**简单扩展**
    * `::=` : 同 `:=` ，于 2012 年被添加到 POSIX 标准中
    * `+=`  : 追加赋值，**扩展方式取决于前面赋值该变量的方式**

* 变量赋多行值 `define ... endef`
    * 值中的换行符保留，也称为定义函数
    * 赋值运算符可以省略，默认是 `=`

```makefile
define 变量名 赋值运算符
...
...
endef
```

* 例子: 赋值的变量

```makefile
a = 123
b := 456
c = 789

b += $(a)
c += $(a)
d := $(a)
e = $(a)
f = $(a) $(b)

$(a) = ABC
a = abc
$(a) = HIJ

all:
	@echo a = $(a)
	@echo b = $(b)
	@echo c = $(c)
	@echo d = $(d)
	@echo e = $(e)
	@echo f = $(f)
	@echo 123 = $(123)
	@echo abc = $(abc)
```

```
# 结果
a = abc
b = 456 123
c = 789 abc
d = 123
e = abc
f = abc 456 123
123 = ABC
abc = HIJ
```

* 目标专属变量
    * `VARIABLE-ASSIGNMENT` 可以使用任何一个有效的赋值方式 `=` `:=` `+=` `?=`
        * 例如: `A: var_private := var_public`
    * 目标专属变量有点类似于编程语言中的局部变量，其作用域仅限于特定的目标
    * 使用目标专属变量时，目标专属变量的值不会影响同名的那个全局变量的值
        * 要覆盖 `make var=value` 定义的变量，需要在 `VARIABLE-ASSIGNMENT` 前加关键字 `override`
    * 定义或修改目标专属变量时，必须单独的一行，后面不能有命令块
    * 目标可以是带模式规则 `%` 的目标
    * 该目标的依赖也会继承该目标专属变量，可以在 `VARIABLE-ASSIGNMENT` 前加关键字 `private` 抑制继承

```makefile
TARGET ... : VARIABLE-ASSIGNMENT
```

* 命令块中变量 `$${var}`
    * `$$var` 可以写成 `$${var}`，不可以写成 `$$(var)`
    * 引用命令块中 shell 定义的 shell 变量，需要用 `$$` 来表示
    * 下面例子的输出结果是 `2 4 6 8 10`

* 例子: 命令块中使用 shell 变量

```makefile
all:
	@var=1; \
	var=$$(( $$var + 10 )); \
	for i in $$(seq $$var); do \
		if [ $$(( $$i % 2 )) -eq 0 ]; then \
			echo -n "$$i "; \
		fi; \
	done; \
	echo
```

* 引用替换
    * `$(var:str1=str2)` `${var:str1=str2}` `{var:%str1=%str2}`
    * 把变量 var 中所有以 "str1" 结尾的 Word 中的 "str1" 替换成 "str2"
    * 第3个是静态模式，以 `%` 开头，`%` 的意思是匹配零或若干字符
    * 示例:  `var := file1.c file2.c file3.c` , 则 `$(var:.c=.o)` 的值为 `file1.o file2.o file3.o`

* 变量导出
    * `export var1 var2 ...`    : 传递变量到下级 Makefile 中，单独 `export` 表示传递所有变量
        * 注: export 不会覆盖下层的 Makefile 中所定义的变量，除非指定了 `make -e` 参数
        * 导出的变量会继续导出到下下级 Makefile 中
    * `export var = value` `export var := value` `export var += value` : 定义并导出变量
    * `unexport var1 var2 ...`  : 取消传递某些变量到下级 Makefile 中，单独 `unexport` 取消表示传递所有变量
    * SHELL 和 MAKEFLAGS 不管你是否 export，其总是要传递到下层 Makefile 中

* [隐式变量](https://www.gnu.org/software/make/manual/make.html)
    * 编译命令相关 `AR` `AS` `CC` `CXX` `CPP`(gcc -E) `LEX` `YACC`
    * 编译标志相关 `ASFLAGS`(as) `CFLAGS`(c) `CXXFLAGS`(c++) LDFLAGS(ld)
    * 其它 `RM`(rm -f)

* `MAKEFILE_LIST`
    * [特殊变量](https://www.gnu.org/software/make/manual/html_node/Special-Variables.html#Special-Variables) 一般只需要关心 `MAKEFILE_LIST`，其它的很少用到
    * make 在读取多个 Makefile 文件时，每个文件进行解析执行之前 make 会把读取的文件名依次追加到 `MAKEFILE_LIST` 中
    * Makefile 文件可能由环境变量 `MAKEFILES` 指定、命令行指定、当前工作下的默认的以及使用指示符 `include` 指定包含
    * 我们可以使用 `MAKEFILE_LIST` 作为目标的依赖，这样 Makefile 改变了就也可以重新编译

* 例子: 获取 Makefile 文件所在的目录

```makefile
#### Makefile 文件 ####
dir_name := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
all: cur_dir := $(dir_name)
all: a b
	@echo cur_dir in \"$@\" is: $(cur_dir)

include dira/inc.mk
include $(shell pwd)/dirb/inc.mk

#### dira/inc.mk 文件 ####
dir_name := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
a: cur_dir := $(dir_name)
a:
	@echo cur_dir in \"$@\" is: $(cur_dir)

#### dirb/inc.mk 文件 ####
dir_name := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
b: cur_dir := $(dir_name)
b:
	@echo cur_dir in \"$@\" is: $(cur_dir)
```

```
# 结果
cur_dir in "a" is: dira
cur_dir in "b" is: /home/lengjing/test/dirb
cur_dir in "all" is: .
```

* 获取当前目录
    * `$(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))`: 读取 Makefile 时此 Makefile 相对解析时所在目录的路径
    * `$(PWD)`: 运行 make 命令时的当前目录的绝对路径
    * `$(shell pwd)`: 解析 Makefile 时的此 Makefile 所在目录的绝对路径
        * 注: `$(shell pwd)` 会解析真实的文件路径(解符号链接)，而命令行直接运行 `pwd` 不会解析
        * 注: `$(shell pwd | other_cmd)` `make -C dir` 时会解符号链接，而直接 `make` 时不会解析

* 例子: 不同函数获取到的当前目录

```makefile
#### /tmp/Makefile 文件 ####
include test/Makefile

#### /tmp/test/Makefile`的内容 ####
DIR1 = $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
DIR2 = $(PWD)
DIR3 = $(shell pwd)

all:
	@echo DIR1 = $(DIR1)
	@echo DIR2 = $(DIR2)
	@echo DIR3 = $(DIR3)
```

```
# 结果
/tmp$ make
DIR1 = test
DIR2 = /tmp
DIR3 = /tmp

/tmp$ make -C test
make: Entering directory '/tmp/test'
DIR1 = .
DIR2 = /tmp
DIR3 = /tmp/test
make: Leaving directory '/tmp/test'

/tmp$ cd test && make && cd -
DIR1 = .
DIR2 = /tmp/test
DIR3 = /tmp/test
/tmp
```

## Makefile 函数调用

* 函数调用: `$(函数名 参数)` `${函数名 参数}`
    * 函数名和参数之间用一个或多个空格或制表符分隔，如果有多个参数，他们之间用逗号分隔
    * 逗号和不匹配的括号或大括号不能按书面形式出现在参数的文本中
    * 前导空格不能出现在第一个参数的文本中，这些字符可以通过变量替换放入参数值中
    * **空格出现在非第一个参数前，空格不会自动删除**
    * **Makefile 的函数都是解析时展开的**

* 例子: 替换空格为逗号

```
comma := ,
empty :=
space := $(empty) $(empty)
foo   := a b c
bar   := $(subst $(space),$(comma),$(foo))

# bar is now 'a,b,c'
```

* shell 函数: `$(shell cmdline)` `$$(cmdline)`
    * `$(shell cmdline)`: 解析时展开，不允许顶格(即命令没有所属 target)直接调用，但可以用在变量的值、目标、依赖、命令块、函数参数中
        * 此调用执行命令扩展，这意味着它将 shell 命令作为参数并计算命令的输出
        * 它对结果的唯一处理 make 是将每个(回车和)换行符转换为单个空格，如果有尾随(回车和)换行符，它将被简单地删除
    * `$$(cmdline)`: 运行时展开，只能用在命令块中

* 例子: 获取文件时间戳

```makefile
all:
	@echo $(shell stat -c %Y test)
	@echo a >> test && sleep 1
	@echo $(shell stat -c %Y test)
	@echo b >> test && sleep 1
	@echo $$(stat -c %Y test)
	@echo c >> test && sleep 1
	@echo `stat -c %Y test`

# 结果: 第2个时间戳和第1个相同，第3个和第4个的时间戳和前面的都不相同
```

* [自定义函数](https://www.gnu.org/software/make/manual/html_node/Call-Function.html#Call-Function): `define endef`
    * 如果 Makefile 中出现一些相同命令序列，那么我们可以为这些相同的命令序列定义一个变量(函数)
    * 定义这种命令序列的语法以 `define` 开始，以 `endef` 结束，注意 define 和 endef 是顶格，前面没有tab键
    * 函数体里面 `$(0)` 表示函数名，`$(1)` `$(2)` ... 表示第1个 、 第2个 ... 参数
    * `$(call funcname,var1,var2...)` : 调用自定义函数使用 `call`

* 例子: 自定义函数

```makefile
define My_name
	@echo "$(subst _, ,$(0)) is $(1) $(2)."
endef

all:
	$(call My_name,Leng,Jing)

# output is now 'My name is Leng Jing.'
```

* [eval 函数](https://www.gnu.org/software/make/manual/html_node/Eval-Function.html#Eval-Function)
    * `eval` 函数的功能主要是: 根据其参数的关系、结构，对它们进行替换展开(把它理解为C语言中的宏定义 `#define`)，它存在两次解析扩展
        * 第1次扩展的结果被解析为 Makefile 语法，作为 Makefile 的新的一部分
        * 第2次扩展对展开内容进行语法解析，展开的结果可以包含一个新变量、目标、隐含规则或者是明确规则等
    * 由于进行了两次扩展，如果在函数的展开结果中存在引用 `$(x)`，应该使用 `$$(x)` 替换
    * `eval` 函数的返回值是空，因此，它几乎可以放置在 Makefile 中的任何位置，而不会导致语法错误

* 例子: 调用 eval 函数
    * `my_dir` 函数获取被 include 的 Makefile 的当前位置
    * `set_flags` 函数批量定义了多个 `CFLAGS_xx.o = -DDEBUG` 变量，[为源码单独设置编译参数]( https://www.kernel.org/doc/html/latest/kbuild/makefiles.html#compilation-flags)

```makefile
define my_dir
$(strip \
	$(eval md_file_ := $$(lastword $$(MAKEFILE_LIST))) \
	$(patsubst %/,%,$(dir $(md_file_)))
 )
endef

local_dir := $(call my_dir)

define translate_obj
$(patsubst $(src)/%,%,$(patsubst %,%.o,$(basename $(1))))
endef

define set_flags
$(foreach v,$(2),$(eval $(1)_$(call translate_obj,$(v)) = $(3)))
endef

$(call set_flags,CFLAGS,a.c b.c,-DDEBUG)
```

## Makefile 内建函数

### 字符串函数

* `$(subst from,to,text)`               : 字符串替换
    * 功能: 在文本 text 中使用 "to" 替换每一处 "from"
* `$(patsubst pattern,replacement,text)`: 单词模式替换
    * 功能: 在文本 text 中查找匹配模式(`%`) "pattern" 的单词，用 "replacement" 替换它们，单词之间的空格被折叠成单个空格字符，前导和尾随空格被丢弃
    * 示例: `objects += $(patsubst %.c,%.o,$(wildcard *.c))` 返回值是当前目录下的所有.c文件后缀换成.o的列表
* `$(strip string)`                     : 空格删除压缩
    * 功能: 去掉前导和结尾空格，并将中间的多个空格压缩为单个空格
    * 示例: `$(strip   a   b   c  )` 返回值是 "a b c"
* `$(findstring find,in)`               : 字符串查找
    * 功能: 在字符串 "in" 中搜寻 "find"，找到则返回值是 "find" ，否则返回值为空
* `$(filter pattern ...,text)`          : 单词过滤
    * 功能: 返回 text 中匹配模式(`%`) "pattern..." 的单词，可以有多个模式
* `$(filter-out pattern ...,text)`      : 单词反过滤
    * 功能: 返回 text 中不匹配模式(`%`) "pattern..." 的单词，函数 filter 的反函数
* `$(sort list)`                        : 单词排序去重
    * 功能: 将 "list" 中的单词按字母顺序排序，并去除重复的单词，输出是由单个空格隔开的单词的列表
* `$(words text)`                       : 取单词总数
    * 功能: 返回 text 中单词的数目
    * 示例: `$(word $(words text),text)` 返回值是 text中的最后1个单词
* `$(word n,text)`                      : 取第n个单词
    * 功能: 返回 text 中的第n个单词，n的合法值从1开始，如果n比 text 中的单词的数目大则返回空值
* `$(wordlist s,e,text)`                : 取多个单词
    * 功能: 返回 text 中的第s个(含)到第e个(含)单词，如果s比 text 中的单词的数目大则返回空值，如果e比总数大，返回到最后一个单词截止
* `$(firstword text)`                   : 取第1个单词
    * 功能: 返回 text 中的第1个单词
    * 示例: `$(firstword foo bar)` 返回值是 `foo`
* `$(lastword text)`                    : 取最后1个单词
    * 功能: 返回 text 中的最后1个单词
    * 示例: `$(lastword foo bar)` 返回值是 `bar`

### 文件名函数

* `$(dir names ...`)                    : 取目录
    * 功能: 从文件名序列中取出目录部分。目录部分是指最后一个斜杠(含)之前的部分，如果没有斜杠，则返回 `./`
    * 示例: `$(dir src/foo.c main)` 返回值是 `src/ ./`
* `$(notdir names ...)`                 : 取文件名
    * 功能: 从文件名序列中取出非目录部分。非目录部分是指最后一个斜杠(不含)之后的部分，如果没有斜杠，则保持不变
    * 示例: `$(notdir src/foo.c main)` 返回值是 `foo.c main`
* `$(suffix names ...)`                 : 取后缀
    * 功能: 从文件名序列中取出各个文件名的后缀部分，如果没有后缀，则返回空字串
    * 示例: `$(suffix src/foo.c src-1.0/bar.c main)` 返回值是 `.c .c`
* `$(basename names ...)`               : 取前缀
    * 功能: 从文件名序列中取出各个文件名的前缀部分，如果没有前缀，则保持不变
    * 示例: `$(basename src/foo.c src-1.0/bar.c main)` 返回值是 `src/foo src-1.0/bar main`
* `$(addsuffix suffix,names ...)`       : 加后缀
    * 功能: 把后缀加到 names 中的每个单词后面
    * 示例: `$(addsuffix .c,foo bar)` 返回值是 `foo.c bar.c`
* `$(addprefix prefix,names ...)`       : 加前缀
    * 功能: 把前缀加到 names 中的每个单词前面
    * 示例: `$(addprefix src/,foo bar)` 返回值是 `src/foo src/bar`
* `$(join list1,list2)`                 : 连接函数
    * 功能: 把list2中的单词对应地加到list1的单词后面， 如果list1的单词个数多，那么多出来的单词将保持原样；如果list2的单词单词个数多，多出来的单词将被复制输出中。
    * 示例: `$(join aaa bbb,111 222 333)` 返回值是 "`aaa111 bbb222 333`"
* `$(wildcard pattern)`                 : 展开通配符
    * 功能: 返回一系列和格式匹配的且文件存在的文件名，文件名之间用一个空格隔开
    * 示例: `$(wildcard *.c)` 返回值是 "`foo.c bar.c`" (假设目录下有文件 foo.c bar.c foo.o bar.o Makefile)
    * 说明: make 中的通配符和 shell 中的相同，在 Makefile 规则中，通配符会被自动展开，但在变量的定义和函数引用时，通配符将失效，此时如果需要通配符有效，就需要使用函数 `wildcard`
* `$(realpath names ...`)               : 获取绝对路径
    * 功能: 返回 names 指定的绝对文件名序列，返回的文件名从根目录 `/` 开始，不含 `./` 和 `../`，文件不存在也正常返回，会对符号链接解引用
* `$(abspath names ...`)                : 获取绝对路径
    * 功能: 同 `realpath`，只是不对符号链接解引用

### 条件和循环函数

* `$(if condition,then-part[,else-part])` : 条件求值
    * 功能: 如果 `condition` 展开后非空，则条件为真，执行 `then-part` 部分，否则执行 `else-part` (如果有)部分，返回值是执行分支的表达式值，无此分支时返回空
* `$(or condition1[,condition2[,condition3…]])` : 短路或求值
    * 功能: 如果 `conditionN` 参数扩展为非空字符串，停止扩展且返回该值，否则继续 `conditionN+1` 参数扩展，所有 `condition` 都为空时返回空
* `$(or condition1[,condition2[,condition3…]])` : 短路与求值
    * 功能: 如果 `conditionN` 参数扩展为空字符串，停止扩展且返回空，否则继续 `conditionN+1` 参数扩展，直到最后的 `condition` 不为空时，返回最后的 `condition` 的值
* `$(foreach var,list,cmd)`             : 循环求值
    * 功能: 对 list 中的每一个单词赋值给变量 var ，var 作为 cmd 命令运行的变量循环执行 cmd，多次的运行结果使用空格相互连接
    * 示例: `files := $(foreach dir,$(dirs),$(wildcard $(dir)/*.c))` 返回值是 dirs 目录集下的所有 .c 文件列表

### 其它函数

* `$(file op filename[,text])`          : [文件操作](https://www.gnu.org/software/make/manual/html_node/File-Function.html#File-Function)
    * 功能: op 的值: `<` 读，此时没有 text ，`>` 清空写，`>>` 追加写
    * 如果 text 没有以换行符结尾，会自动写入换行符（即使text是空字符串），如果没有给出 text 参数，则不会写入任何内容
* `$(value variable)`                   : [获取变量不扩展的值](https://www.gnu.org/software/make/manual/html_node/Value-Function.html#Value-Function)
    * 功能: 获取变量的值，不会对变量的值中的变量引用进行扩展
* `$(origin variable)`                  : [获取变量的来源](https://www.gnu.org/software/make/manual/html_node/Origin-Function.html#Origin-Function)
    * 功能: 获取变量的来源，不会对变量进行扩展，来源有 `undefined` `default` `environment` `environment override` `file` `command line` `override` `automatic`
* `$(flavor variable)`                  : [获取变量的风格](https://www.gnu.org/software/make/manual/html_node/Flavor-Function.html#Flavor-Function)
    * 功能: 获取变量的风格，不会对变量进行扩展，风格有 `undefined` `recursive`(递归变量) `simple`(简单变量)

## 内核 Kbuild 系统

* Kernel Makefile

```makefile
KERN_MAKES := make $(BUILD_SILENT) $(BUILD_JOBS)
KERN_MAKES += $(if $(ARCH),ARCH=$(ARCH)) $(if $(CROSS_COMPILE),CROSS_COMPILE=$(CROSS_COMPILE))
KERN_MAKES += $(if $(KERNEL_OUT),O=$(KERNEL_OUT))

.PHONY: all clean install loadconfig menuconfig

all:
	@mkdir -p $(KERNEL_OUT)
	@$(KERN_MAKES) all
	@echo "Build linux-kernel Done."

clean:
	@$(KERN_MAKES) clean
	@echo "Clean linux-kernel Done."

install:
	@$(KERN_MAKES) $(if $(SYSROOT_DIR),INSTALL_MOD_PATH=$(SYSROOT_DIR)) modules_install
	@echo "Install linux-kernel Done."

loadconfig:
	@$(KERN_MAKES) $(KERNEL_CONF)

menuconfig:
	@$(KERN_MAKES) menuconfig
```

* Module Makefile

```makefile
MOD_MAKES := make $(BUILD_SILENT) $(BUILD_JOBS)
MOD_MAKES += -C $(KERNEL_SRC)
MOD_MAKES += $(if $(ARCH),ARCH=$(ARCH)) $(if $(CROSS_COMPILE),CROSS_COMPILE=$(CROSS_COMPILE))
MOD_MAKES += $(if $(KERNEL_OUT),O=$(KERNEL_OUT))
MOD_MAKES += $(if $(OUT_PATH),M=$(OUT_PATH) src=$(shell pwd),M=$(shell pwd))

.PHONY: all clean install

all:
	@$(MOD_MAKES) $(if $(MOD_DEPS), KBUILD_EXTRA_SYMBOLS="$(wildcard $(patsubst %,$(SYSROOT_DIR)/usr/include/%/Module.symvers,$(MOD_DEPS)))") modules
	@echo "Build $(MOD_NAME) Done."

clean:
	@$(MOD_MAKES) clean
	@echo "Clean $(MOD_NAME) Done."

install:
	@make $(MOD_MAKES) $(if $(SYSROOT_DIR), INSTALL_MOD_PATH=$(SYSROOT_DIR)) modules_install
ifneq ($(INSTALL_HEADER), )
	@mkdir -p $(SYSROOT_DIR)/usr/include/$(MOD_NAME)
	@cp -fp $(OUT_PATH)/Module.symvers $(SYSROOT_DIR)/usr/include/$(MOD_NAME)
	@cp -rfp $(INSTALL_HEADER) $(SYSROOT_DIR)/usr/include/$(MOD_NAME)
	@echo "Install $(MOD_NAME) Done."
endif
```

* Kbuild Makefile

```makefile
obj-m := $(moda).o $(modb).o ...
$(moda)-y := srca1.o srca2.o ...
$(modb)-y := srcb1.o srcb2.o ...
...
```

* Makefile 说明
    * 自定义的变量
        * `KERNEL_SRC`          : 内核的源码目录
            * 本机的内核源码目录是 `/lib/modules/$(shell uname -r)/build`
        * `KERNEL_OUT`          : 内核的编译输出目录
        * `SYSROOT_DIR`         : 安装文件的根目录
        * `KERNEL_CONF`         : 编译内核源码的配置，需要在 `$(KERNEL_SRC)/arch/$(ARCH)/configs` 找到此配置
        * `OUT_PATH`            : 模块的编译输出目录
        * `MOD_NAME`            : 当前模块的名字，决定头文件的安装位置
        * `MOD_DEPS`            : 当前模块依赖的其它模块的 MOD_NAME，多个名字使用空格隔开
        * `INSTALL_HEADER`      : 当前模块要安装的头文件
        * `modx`                : 编译生成的模块名 `modx.ko`
        * `srcxx.o`             : 编译对应模块需要的源码的后缀 `.c .S` 换成 `.o`
    * 参数说明
        * `BUILD_SILENT`        : 设置该变量的值为 `-s`，静默编译
        * `BUILD_JOBS`          : 设置该变量的值为 `-jn`，启用多线程编译，例如 `-j8` 启用8线程编译
        * `ARCH=xxx`            : 设置要构建的体系结构，例如 `arm64`，直接导出 `ARCH` 环境变量就不需要此设置
        * `CROSS_COMPILE=xxx`   : 设置构建的交叉编译器，例如 `arm-linux-`，直接导出 `CROSS_COMPILE` 环境变量就不需要此设置
        * `O=xxx`               : 构建内核时指定输出目录，编译输出和源码同目录或直接导出 `KBUILD_OUTPUT` 环境变量就不需要此设置，`O=xxx` 优先级更高
        * `INSTALL_MOD_PATH=xxx`: 指定安装模块的根目录，直接导出 `INSTALL_MOD_PATH` 环境变量就不需要此设置
            * linux 内核的模块默认安装到 `$(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)/linux`
            * 外部内核模块默认安装到 `$(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE)/extra`，可以使用 `INSTALL_MOD_DIR` 的值修改 `extra`
        * `M=xxx`               : 通知 kbuild 正在构建外部模块，设置编译输出目录，直接导出 `KBUILD_EXTMOD` 环境变量就不需要此设置，`M=xxx` 优先级更高
        * `src=xxx`             : 设置源码目录，不设置时源码目录同 `M=xxx` 设置的值
        * `KBUILD_EXTRA_SYMBOLS = xxx` : 设置查找的符号导出文件 `Module.symvers`，依赖其它模块时必须设置，没有依赖或直接导出 `KBUILD_EXTRA_SYMBOLS` 环境变量就不需要此设置

* 编译外部模块说明
    * Makefile 由2部分(3步骤)组成
        1. 在当前目录执行 Makefile，调用内核源码目录的 Makefile 的目标: `modules` 构建模块，`modules_install` 安装模块，`clean` 清理编译
        2. 在内核源码目录执行 `src` 目录下的 Kbuild(优先) 或 Makefile，源文件编译成目标文件 `*.o`
        3. 在内核源码目录执行 `src` 目录下的 Kbuild(优先) 或 Makefile，链接目标文件生成模块 `*.ko`
    * 特殊说明
        * 在 5.18 内核 [kbuild: Fix include path in scripts/Makefile.modpost](https://git.kernel.org/pub/scm/linux/kernel/git/masahiroy/linux-kbuild.git/commit/?h=fixes&id=23a0cb8e3225122496bfa79172005c587c2d64bf) 之前，在内核源码目录执行的是 `$(M)` 下的编译脚本， 所以编译输出到非源码目录时，需要先将 Kbuild 或 Makefile 复制到 OUT_PATH 目录
        * 由于执行 Kbuild 的当前目录是内核源码目录，所以在 Kbuild 文件使用 `find` 命令或 `wildcard` 函数查找源码时必须加上 `$(src)/` 前缀
            * `$(src)` 指向源码目录，`$(obj)` 指向编译输出目录
        * `KERNELRELEASE` 在当前目录执行时没有值，在内核源码目录执行时被赋值，所以我们可以把 Kbuild 和 Makefile 写成一个 Makefile
            ```
            ifneq ($(KERNELRELEASE),)
            Kbuild 文件内容
            else
            Makefile 文件内容
            endif
            ```
    * Kbuild 说明
        * `obj-m := modname.o` : 设置 `obj-m` 变量，指定要生成的模块名(注意后缀 `.o`)，生成 `modname.ko`，可以同时指定多个模块
        * `modname-y := src1.o src2.o ...` : 设置生成模块使用的目标文件，内核 Makefile 会在 `$(M)` 指定的目录生成目标文件
            * 如果生成模块使用的目标文件只有一个且等于 `modname.o`，那么这条语句要删除
    * 输出方式
        * 源码和编译输出同目录时编译命令: `make -C $(KERNEL_SRC) M=$(shell pwd) modules`
        * 源码和编译输出分离时编译命令: `make -C $(KERNEL_SRC) O=(KERNEL_OUT) M=$(OUT_PATH) src=$(shell pwd) modules`

* 编译标志说明
    * `ccflags-y` `asflags-y` `ldflags-y`   : 设置调用 cc(编译) as(汇编) ld(链接) 命令使用的标志
        * 老的名称是 `EXTRA_CFLAGS` `EXTRA_AFLAGS` `EXTRA_LDFLAGS`
    * `subdir-ccflags-y`` ubdir-asflags-y`  : 设置调用 cc(编译) as(汇编) 命令使用的标志，这些标志还会影响子目录的 Kbuild
    * `ccflags-remove-y` `asflags-remove-y` : 删除调用 cc(编译) as(汇编) 命令使用的某些标志
    * `CFLAGS_xxx.o` `AFLAGS_xxx.o`         : 为生成特定目标 xxx.o 指定 cc(编译) as(汇编) 命令使用的标志
