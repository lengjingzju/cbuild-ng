# Shell 笔记

* 本笔记的 shell 为 bash
* `cat /etc/shells` 可获取系统当前安装的 shell
* `echo $SHELL` 或 `echo $0` 可获知当前用户的默认 shell (即 `cat /etc/passwd` 对应用户的最后一列)，一般是 `bash`
    * 修改用户默认 shell 可以使用以下3种方法: 修改 `/etc/passwd` 文件最后一列，`sudo usermod --shell shell命令路径 用户名` 或 `sudo chsh --shell shell命令路径 用户名`
* Makefile 使用的默认 shell 是 `/bin/sh` 指向的 shell (即 `readlink /bin/sh`)，Ubuntu 一般是 `dash`
    * 修改 Makefile 默认 shell 可以重新设置符号链接 `cd /bin && sudo ln -sf shell名称 sh`，例如 `cd /bin && sudo ls -sf bash sh`

## 用户和配置

* 在 Linux 当中，有三种用户: root 用户、一般用户、虚拟用户
    * root 用户的默认 shell 提示符是井号 `#`，UID(用户ID)是0，可以执行所有命令
        * `sudo -i`             : Ubuntu 切换到 root 用户且切换到它的家目录，不需要先启用和添加 root 用户密码
        * `sudo su`             : Ubuntu 切换到 root 用户且停留在当前目录，不需要先启用和添加 root 用户密码
        * `su`                  : 切换到 root 用户且停留在当前目录，Ubuntu 需要 `sudo passwd root` 先添加 root 用户密码才能使用 su
        * `su <user>`           : 切换到 user 用户，例如: `su lengjing`
        * `exit`                : 返回切换前的用户，如果是最后一个用户会关闭终端(也可以 `CTRL + d` )
    * 一般用户的默认 shell 提示符是美元符号 `$`，不可以执行特权命令，需要在命令前面加 `sudo` 才可以执行特权命令
        * `sudo <command>`      : 加上 sudo 运行特权命令
    * 虚拟用户无法登陆终端执行命令，主要用于文件服务器权限的设置
<br>

* Ubuntu 进入单人维护模式
    * 系统重新启动，在读秒时按下任意键，再按下 `e键` 就能够进入 grub 编辑模式
    * 将光标移动到 kernel 那一行，再按一次 `e键` 进入行编辑，行的最后输入 `single`
    * 再按下 `回车键` 确定之后，按下 `b键` 就会启动进入单人维护模式
    * 在单人维护模式下，tty1 终端不需要输入密码即可取得控制权，例如: 输入 `passwd <username>` 修改密码
<br>

* 帐号管理
    * `passwd <username>`               : 修改密码 `/etc/passwd`
        * `sudo passwd root`            : 添加或修改 root 用户密码
        * `sudo passwd -l root`         : 使 root 用户密码过期(禁用 root 用户)
        * `sudo passwd -u root`         : 使 root 用户密码有效(启用 root 用户)
    * `useradd  / usermod  / userdel`   : 增加/删除/修改用户
        * `useradd -m <username>`       : 为用户创建相应的帐号和用户家目录 `/home/username`
        * `userdel -r <username>`       : 删除用户账号和用户家目录
        * `usermod -a -G <groupname> <username>` : 将用户追加到用户组(例如串口组 dialout)
    * `groupadd / groupmod / groupdel`  : 增加/删除/修改组 `/etc/group`
<br>

* 配置文件
    * `/etc/profile` `~/.bash_profile` `~/.bash_login` `~/.profile` : 登录时自动 source 此类脚本
        * 命令行登入时，会 source 系统登录配置 `/etc/profile` 和用户登录配置(三选一，前面优先) `~/.bash_profile` `~/.bash_login` `~/.profile`
            * source `/etc/profile` 时会 source 其它脚本 `/etc/bash.bashrc` `/etc/profile.d/*.sh` 等
        * 打开新终端时不会再 source 登录配置脚本
    * `/etc/bash.bashrc` `~/.bashrc`    : 打开新终端时自动 source 此类脚本
        * 用户一般会在 `~/.bashrc` 改变环境变量 `PATH` 和 定义别名 `alias` 等
    * `~/.bash_logout`                  : 登出时自动 source 此脚本
    * `~/.bash_history`                 : 记录之前输入的命令，也可以 `history` 命令列出

## 命令和帮助

* 命令格式: `command [-options] parameter1 parameter2 ...`
    * command                   : 命令名、脚本名或可运行程序名, 例如: ./configure 执行当前文件夹下的 configure 文件
        * 执行当前路径下的命令需要加上 `./`
    * options                   : 可选选项，短选项前通常会带 `-` ，长选项前通常会带 `--` ，有的选项前可能什么都不带
    * parameter                 : 可能参数，多个参数用空格隔开
<br>

* 命令别名: `alias new_command='command sequence'`
    * 单独 `alias` 表示列出所有已定义的别名
    * `command sequence` 中可以使用 `$@` 表示命令参数
    * 取消别名用 `unalias new_command`
    * 要使别名永久有效，需要写入 `~/.bashrc` 配置文件
    * 要使用别名的原始命令，需要对使用的命令进行转义 `\command`
    * 创建别名时，如果已经有同名的别名存在，那么原有的别名设置将被新的设置取代
    * 例如: 定义别名 `alias ll='ls -al'` 和取消别名 `unalias ll`
<br>

* 命令帮助: `man <num> command`
    * `num` : 查看对应类型的手册(不加 num 时表示找到第1个有效的章节)
        * `1`                   : 可执行程序或 shell 命令，例如: `man stat` or `man 1 stat`
        * `2`                   : 系统调用(内核提供的函数)，例如: `man 2 stat`
        * `3`                   : 库调用(程序库中的函数)，例如: `man fopen` or `man 3 fopen`
        * ...                   : ...
    * 命令选项
        * `-f`                  : 等同于 `whatis`，显示来自手册页的简短说明(若有)，command 必须精确匹配命令
            * `whatis -w`       : 支持通配符，例如: `whatis -w loc*`
        * `-k`                  : 等同于 `apropos`，搜索关键词对应的手册概述并显示所有匹配结果，command 可以是命令的一部分
    * 搜索选项                  : `/string` 向下搜 ; `?string` 向上搜 ; `n` 继续 ; `N` 反向继续
    * 翻页选项                  : `[空格键]` 向下翻页 ; `[PgUp]` `[PgDn]` `[Home]` `[End]` 翻上/下/首/尾页
    * 注: 一般命令的 `--help` 或 `-h` 选项可显示命令帮助
<br>

* 中文版 man
    * [下载](https://src.fedoraproject.org/repo/pkgs/man-pages-zh-CN/)和编译安装
        ```sh
        wget https://src.fedoraproject.org/repo/pkgs/man-pages-zh-CN/v1.6.3.6.tar.gz/sha512/dc9ecd461eba41fc30658e028f853e3664fc6ce27c5b48c3159c5c8a452ad6d71730e0e5f551efa7b4c358baf010ba27a855457ae69b21e9637af326044dcca8/v1.6.3.6.tar.gz
        tar -xvf  v1.6.3.6.tar.gz 
        cd manpages-zh-1.6.3.6/
        sudo apt install autotools-dev opencc
        autoreconf --install --force
        ./configure --disable-zhtw --prefix=/usr/local/zhman
        make && sudo make install
        ```
    * 定义别名 cman
        * 在 `~/.bashrc` 中加入下面的内容
            ```sh
            cman() {
                man -M /usr/local/zhman/share/man/zh_CN $@ || man $@
            }
            export -f cman
            ```
        * `cman <cmd>`: cmd 有中文说明时查看中文手册，没有中文时查看 man 原始的英文手册

* 命令位置
    * `which`                   : 查找命令
        * 命令选项
            * `-a`              : 将所有由 `PATH` 定义的目录中找到的命令均分行列出，而不是第1个被找到的命令
    * `whereis`                 : 查找特定文件(二进制文件、源码文件、说明文件等)，同一行列出
    * `locate`                  : 依据 `/var/lib/mlocate` 内的数据库记载，找出使用者输入的关键字档名(需要安装 `mlocate`)
        * 命令选项
            * `-i`              : 忽略大小写的差异
            * `-r`              : 使用正则表达式查找
        * `updatedb` 根据 `/etc/updatedb.conf` 的配置去更新 `/var/lib/mlocate` 数据库
<br>

* 特殊符号
    * `cmd1 ; cmd2`             : 同一行的多个命令可以用分号分隔
    * `cmd1 | cmd2`             : 管道命令，上一个命令的输出 stdout 作为下一个命令的输入 stdin，常与 `xargs` 连用
    * `cmd1 || cmd2`            : 命令序列短路或执行: 若 cmd1 正确执行完毕，则不再执行 cmd2 ; 否则继续运行 cmd2
    * `cmd1 && cmd2`            : 命令序列短路与执行: 若 cmd1 正确执行完毕，则继续运行 cmd2 ; 否则不再执行 cmd2
    * `cmd &`                   : 后台运行命令
    * `$(cmd)`                  : 获取命令的输出值，也可以使用 <code>\`cmd\`</code>
    * `(cmd)`                   : 子 shell 命令组，当命令在子 shell 中执行时，不会对当前 shell 有任何影响，所有的改变仅限于子 shell 内
        * 小括号中多个命令之间用分号隔开，最后一个命令可以没有分号，各命令和括号之间不必有空格
        * 例如:  `pwd; cd ..;pwd`当前目录改变了，加小括号后 `pwd;(cd ..);pwd` 当前目录没改变
    * `{cmd}`                   : 命令区块
    * `$?`                      : 最后运行的命令的结束代码(返回值)，成功值为0

## 变量和数组

* 变量
    * 变量赋值: `var=value`
        * var 是变量名
            * 变量名只能是字母、数字和下划线 `_`，且头字符不能是数字
            * 通常全大写字符的变量名为系统环境变量
                * 常用的环境变量: `PWD` 当前目录、`USER` 当前用户名、`HOME` 当前用户家目录、`SHELL` 当前 shell、`PATH` 命令搜索路径
                * `cat /proc/$PID/environ | tr '\0' '\n'` 可查看进程相关的环境变量
        * value 是赋给变量的值
            * 如果 value 不包含任何空白字符和 `;` 等特殊符号，那么它就不需要使用引号进行引用，否则必须使用单引号或双引号
            * 单引号中的变量引用不会扩展，双引号的会扩展为它的值
        * **等号前后不能有空格**，`var = value` 不是赋值而是比较的意思
        * 定义局部变量前面加 `local`
    * 变量引用: `$var` or `${var}`
        * 获取变量的值时如果变量名后面不是字母、数字和下划线，可以不加大括号
    * 变量值长度: `${#var}`
        * 获取变量值的长度，即字符串包含的字符数
<br>

* 数组
    * 普通数组(数字作为数组索引)
        * `array=(test0 test1)`             : 定义一个普通数组
            * 也可以单个定义或修改数组元素的值 `array[0]=test0; array[1]=test1`
        * `array[n]`                        : 取数组的第n个元素的值，n从0开始
    * 关联数组(文本作为数组索引)
        * `declare -A array`                : 声明一个关联数组
        * `array=([ia]=test0 [ib]=test1)`   : 将元素添加到关联数组中
            * 也可以一个一个元素地添加到关联数组中 `array[ia]=test0; array[ib]=test1`
        * `array[index]`                    : 取关联数组的索引文本为 `index` 的元素的值
    * 数组遍历
        * `${array[*]}` or `${array[@]}`    : 数组所有元素值组成的列表
        * `${!array[*]}` or `${!array[@]}`  : 数组所有元素索引组成的列表
        * `${#array[*]}` or `${#array[@]}`  : 数组元素个数
    * 注: dash 中不支持数组
<br>

* 变量命令
    * `eval`                    : 变量引用前加 `eval` 会把变量字符串当作命令执行
    * `env`                     : 查看所有的环境变量
    * `set`                     : 查看所有的环境变量和自定义变量
    * `unset var`               : 删除变量定义
    * `export var`              : 导出变量，可同时导出多个变量(空格分隔)，则从当前 shell 执行的任何程序都会继承这个变量
        * `export var=value`    : 定义并导出变量
        * 例如: `export PATH=$PATH:/home/user/bin` 会将 `/home/user/bin` 添加到了环境变量 `PATH` 中
<br>

* 变量切片 `${var:start:length}`
    * 说明
        * `var` 是变量名，`start` 是开始位置，`length` 是切片的长度
        * `start` 序号从 `0` 开始，也可以使用负数，`-1` 是最后一个字符
        * `start` 是负数时必须在 `var` 的冒号后加空格或用小括号把数值括起来
        * 可以省略 `:length`，此时表示切片到字符串结尾
        * `length` 可以使用负数，此时不再表示长度的意思，而是切片到索引(不含)的意思
        * 注: dash 中不支持变量切片
    * 例子(定义 `var=www.google.com`)
        * `${var: -3}`          : 提取最后3个字符，也可以写成 `${var:(-3)}` ，不可以写成 `${var:-3}`，例子值为 "com"
        * `${var:4}`            : 提取第4个(不含)字符之后的所有字符，也可以写成 `${var: 4}`，例子值为 "google.com"
        * `${var:4:6}`          : 提取第4个(不含)字符之后的6个字符，也可以写成 `${var:4:-4}`，例子值为 "google"
<br>

* 变量提取
    * 变量提取中 `.` 表示定界作用，可换成其它的定界符，也可以使用多个字符
    * 通配符:  `*` 星号表示匹配任意数量(含0个)的任意字符，`?` 问号表示匹配单个任意字符
    * 例子(定义 `var=www.google.com`)
        * `${var#*.}`           : 从左边开始，去掉第一个符号'.'左边的所有字符，例子值为 "google.com"
        * `${var##*.}`          : 从右边开始，去掉第一个符号'.'左边的所有字符，例子值为 "com"
        * `${var%.*}`           : 从右边开始，去掉第一个符号'.'右边的所有字符，例子值为 "www.google"
        * `${var%%.*}`          : 从左边开始，去掉第一个符号'.'右边的所有字符，例子值为 "www"
        * `${var#????}`         : 表示删除前面4个字符，例子值为 "google.com"
        * `${var%????}`         : 表示删除后面4个字符，例子值为 "www.google"
<br>

* 变量计算
    * 整数计算: 不支持浮点型，`expression` 的运算符和表达式符合C语言运算规则即可
        * `${var:+expression}`  : 如果 var 有值且不为空，则使用 `expression` 的值
        * `$[ expression ]`     : 取运算 `expression` 的值(注意 `expression` 前后有空格)，出现在 `[  ]` 中的变量名之前可加可不加 `$`
        * `$(( expression ))`   : 取运算 `expression` 的值(注意 `expression` 前后有空格)，出现在 `((  ))` 中的变量名之前可加可不加 `$`
        * `$(expr expression)`  : 取运算 `expression` 的值，出现在 `(  )` 中的变量名之前要加 `$`
        * `let expression`      : 进行 `expression` 运算更新值，例如: `let num++ ; let num-- ; let num+=1 ; let num-=1 ; let num=1+1`
    * 高级计算: `echo "expression" | bc`
        * 设定小数精度，例如: `echo "scale=2;22/7" | bc` 将输出 3.14
        * 进制转换，`echo "obase=2;10" | bc` 将输出 1010 ; `echo "obase=10;ibase=2;1010" | bc` 将输出 10
        * 计算平方以及平方根，`echo "10^2" | bc` 将输出 100 ; `echo "sqrt(100)" | bc` 将输出 10

## 输入和输出

* 打印输出
    * `echo [options] expression`: 通用打印
        * 打印屏幕，后面的字符串(即使有空格)可以不用引号，也可以用单引号或双引号
            * 不带引号时，没法在所要显示的文本中使用分号 `;` ，即使加 `-e` 也无法打印转义，例如: `echo -e \t` 会打印`\t`
            * 带单引号时，特殊字符和字面义相同，变量替换无效，例如: `echo '$SHELL'` 打印 `$SHELL`
            * 带双引号时，变量替换有效， 例如: `echo "$SHELL"` 或 `echo $SHELL` 打印 `/bin/bash`
            * 不带引号时，echo 会把输出的换行符换成空格，而带双引号不会，例如: `echo $(ls -l)` 输出没有换行，`echo "$(ls -l)"` 输出有换行
        * 命令参数
            * `-n`              : 不换行，后面输出紧接着这行(echo 默认会将一个换行符追加到输出文本的尾部)
            * `-e`              : 启用 `ASCII-C 转义字符` 的解释，例如: `echo -e "\t"` 或 `echo -e '\t'` 会打印 tab，不加 -e 直接打印`\t`
        * 颜色打印: `echo -e "\033[背景色;前景色m字符串\033[0m"` ，例如: `echo -e "\033[41;37m红底白字\033[0m"`
            * `\033[0m`         : 关闭所有属性(注: `\033` 可以写成 `\e`)
            * `\033[4x;3xm`     : 同时设置背景色和前景色(x是数字代表: `0` 黑 `1` 红 `2` 绿 `3` 黄 `4` 蓝 `5` 紫 `6` 天蓝 `7` 白)
            * `\033[4xm`        : 只设置背景色
            * `\033[3xm`        : 只设置前景色
            * 注: dash 中颜色打印不需要 `-e`
        * `echo { .. }`         : 生成值序列，例如: `echo {a..z}` `echo {0..100}`
            * 注: dash 不支持这种语法
    * `printf FORMAT [ARGUMENT]`: 格式化打印
        * printf 使用格式化字符，空格分隔的打印的参数，例如: `printf "%3.2f %s\n" 3.1415926 $PATH`
        * printf 默认并不像 echo 命令一样会自动添加换行符
<br>

* 读取输入
    * `read [options] var1 var2 ...` : 读取来自键盘输入的变量
        * 命令参数
            * `-p tip_str`      : 提示
            * `-t sec`          : 最多等待 sec 秒
            * `-n num`          : 最多读取的 num 个字符
            * `-d separator`    : 特定定界符 separator 作为输入行的结束，默认结束符是换行符，变量的输入分隔符是空格
            * `-s`              : 无回显读取，用于读取密码

```sh
$ read -p "Please keyin your name and age: " your_name your_age
Please keyin your name and age: lengjing 30
$ echo "The age of $your_name is $your_age."
The age of lengjing is 30.
```

* 重定向
    * `>  >>  <`                : 重定向文件
        * `>` 清空文件再输入(`>`等同于`1>`); `>>` 追加到文件; `<` 从文件中读取
            * `0` stdin(标准输入) `1` stdout(标准输出) `2` stderr(标准错误)
        * `:> file`             : 清空文件，例如: `:> a.txt`
        * `cmd 2> stderr.txt 1> stdout.txt`
            * 将 stderr 单独重定向到一个文件，将 stdout 重定向到另一个文件，
        * `cmd 2>&1 output.txt` or `cmd &> output.txt`
            * stderr 和 stdout 都被重定向到同一个文件中
            * 注: dash 中不支持这种写法，替代写法 `cmd > output.txt 2>&1`
        * `cmd 2> /dev/null`
            * 将 stderr 输出丢弃
    * `cmd | tee output.txt`    : tee只能从stdin中读取，终端中打印，并复制一份输出将它重定向到一个文件中
        * tee 命令默认会将文件覆盖，可以使用  `-a` 选项追加内容

## shell 脚本

### 执行脚本

* 执行和调试
    * 执行方式
        * `./script_name.sh` or `bash script_name.sh`   : 启用新的 sub-shell (新的子进程) 执行命令脚本
        * `. script_name.sh` or `source script_name.sh` : 在当前 shell 下执行脚本，此时执行新的程序还可以访问脚本导出的变量等
    * 执行过程
        * shell 脚本需要添加运行权限 `chmod +x script_name.sh` 才可以执行
        * 命令的运行是从上而下、从左而右的分析与运行
        * 第1行 `#!/bin/bash` 在宣告这个 script 使用的 shell 类型
        * 命令、选项与参数间的多个空白都会被忽略掉，空白行也将被忽略掉
        * 如果读取到一个换行符，就尝试开始运行该行(或该串)命令
        * 如果一行的内容太多，可以使用 `\` 来延伸至下一行
        * 可以用 `sleep 整数或浮点数` 在脚本中延时一段时间(秒)
    * 调试脚本
        * `-n` 标志运行脚本只是读一遍脚本中的命令但不执行，用于检查脚本中的语法错误，例如: `bash -n ./configure`
        * `-x` 标志运行脚本可以打印出所执行的每一行命令以及当前状态，例如: `bash -x ./configure`
        * 脚本内部使用 `set -x` (在执行时显示参数和命令) 和 `set +x` (禁止调试) ，对包起来的命令进行调试
        * 脚本内部使用 `set –v` (当命令进行读取时显示输入) 和 `set +v` (禁止打印输入)，对包起来的命令进行调试
        * 脚本第一行写成 `#!/bin/bash -xv`，启用全程调试功能
    * 退出执行 `exit` `return`
       * 后面可以加数字指定退出状态码
       * `source script_name.sh` 时 `exit` 会退出当前终端，而 `return` 不会
<br>

* 特殊变量
    * `$$`                      : shell 本身的 PID (ProcessID)
    * `$!`                      : shell 最后运行的后台进程的 PID
    * `$?`                      : 最后运行的命令的结束代码(返回值)，成功值为0
    * `$*`                      : 所有参数列表，以 `"$1 $2 … $n"` 的形式输出所有参数，`$*` 不被双引号包围时，效果同 `$@`; 被双引号包围时，将所有的参数看做一份数据
    * `$@`                      : 所有参数列表，以 `"$1" "$2" … "$n"` 的形式输出所有参数，将每个参数都看做一份数据
    * `$#`                      : shell 的参数个数
    * `${BASH_SOURCE[0]}`       : source 脚本时脚本的路径名
    * `$0`                      : 普通执行脚本时脚本的路径名
    * `$1~$n`                   : shell 脚本的各参数值，`$1` 是第1参数、`$2` 是第2参数 ... ，当n>=10时，需要使用 `${n}` 来获取参数

### 命令选项

* 声明和使用
    * 短命令选项
        * 必带参数的选项: 参数声明背后会带1个冒号，类似 `a:`; 使用时参数和值之间可选是否带空格，类似 `-a valuea` or `-avaluea`
        * 可选带参数的选项: 参数声明背后会带2个冒号，类似 `b::`; 使用时参数和值之间不能带空格，类似 `-bvalueb`
        * 不带参数的选项: 参数声明背后没有冒号，类似 `c`; 使用时没有参数，类似 `-c`
    * 长命令选项
        * 必带参数的选项: 参数声明背后会带1个冒号，类似 `long-a:`; 使用时参数和值之间可选是等号还是空格，类似 `--long-a=valuea` or `--long-a valuea`
        * 可选带参数的选项: 参数声明背后会带2个冒号，类似 `long-b::`; 使用时参数和值之间只能是等号，类似 `--long-b=valueb`
        * 不带参数的选项: 参数声明背后没有冒号，类似 `long-c`; 使用时没有参数，类似 `--long-c`
<br>

* `getopts`                     : bash 的内部命令
    * `"a:c"`                   : 声明命令选项，`getopts` 只支持短命令选项且不支持可选带参数的选项
    * `OPTARG`                  : 特殊变量，自动设置此变量的值为当前命令选项的值(确切的说是下一个参数)
    * `OPTIND`                  : 特殊变量，自动设置此变量的值为下一个参数的序号

```sh
#!/bin/bash

while getopts "a:c" opt; do
	case $opt in
		a) printf "%-40s%s\n" "option: -$opt" "parameter: $OPTARG";;
		c) printf "%-40s%s\n" "option: -$opt" "parameter: None";;
		*) echo "Error option: -$opt"; exit 1;;
	esac
done
```

* `getopt`                      : 规范化命令参数
    * getopt 参数说明
        * `-o shortopts`        : 声明短命令选项，只有长命令选项时此选项的值必须置空 `-o ''`，不能省略
        * `-l longopts`         : 声明长命令选项，多个长命令选项使用逗号 `,` 分隔
        * `--`                  : 固定写法，它的后面是原始的命令参数，getopt 生成的新的命令参数的最后一项是 `--`
    * `eval set -- "str"`       : 将 str 替换为当前脚本的参数集
    * `shift num`               : 丢弃前面 num 个参数，不加 num 时丢弃一个，例如: 运行 `shift`，`$1` 被丢弃，`$2` 变成了 `$1`

```sh
#!/bin/bash

eval set -- "$(getopt -o a:b::c -l long-a:,long-b::,long-c -- $@)"

while :; do
	case $1 in
		-a|--long-a)
			printf "%-40s%s\n" "option: $1" "parameter: $2"
			shift 2
			;;
		-b|--long-b)
			if [[ -z $2 ]]; then
				printf "%-40s%s\n" "option: $1" "parameter: None"
			else
				printf "%-40s%s\n" "option: $1" "parameter: $2"
			fi
			shift 2
			;;
		-c|--long-c)
			printf "%-40s%s\n" "option: $1" "parameter: None"
			shift
			;;
		--)
			shift
			break
			;;
		*)
			echo "Error option: $1"
			exit 1
			;;
	esac
done
```

### 函数语句

* 定义函数
    * `function` 可以省略
        * 注: dash 中没有 `function` 这个关键字
    * 函数括号里面不写参数
    * 函数里面参数用 `$1 $2 ...` 表示，注意函数里面的这些值不再是脚本的参数(`$0` 还是脚本名)

```sh
function fname() {
    expression
}
```
or
```sh
fname() {
    expression
}
```

* 调用函数
    * 直接 `fname` 或 `fname arg1 arg2 ...` ，不需要括号
    * `export -f fname` 用来导出函数

### 条件测试

**注意条件测试语句的条件和中括号之间是有空格的，不能省略空格**

* 数值比较
    * `[ $var -eq value ]`
        * `-eq` 相等; `-ne` 不等; `-gt` 大于; `-ge` 大于等于; `-lt` 小于; `-le` 小于等于

* 文件系统测试
    * `[ -f $var ]` :
        * `-f` 是文件; `-d` 是目录; `-e` 文件存在; `-s` 非空文件
        * `-r` 文件可读; `-w` 文件可写; `-x` 文件可执行
        * `-u SUID`; `-g SGID`; `-k SBIT`
        * `-c` 是字符设备; `-b` 是块设备; `-L` 是符号链接; `-S` 是socket; `-p` 是FIFO/pipe
    * `[ file1 -nt file2 ]`
        * `-nt` 新; `-ot` 旧; `-ef` 指向同一inode

* 字符串比较
    * `[[ $str1 = $str2 ]]`
        * `=` 相等; `==` 相等; `!=` 不等; `<` 小于; `>` 大于
        * 注1: 使用字符串比较时，最好用双中括号，因为有时候采用单个中括号会产生错误
        * 注2: dash 中只能用 `=` 表示相等
    * `[[ -z $var ]]`
        * `-z` 空字符串; `-n` 非空字符串
        * 注: `[ -n $var ]` 表示是否定义，变量赋值为空也是定义了

* 多条件组合
    * `[[ -n $var ]] && [[ $str1 = $str2 ]]`
        * 使用逻辑运算符 `&&` 和 `||` 能够很容易地将多个条件组合起来
    * `[[ -n $var -a $str1 = $str2 ]]` `[ $var -lt minvalue -o $var -gt maxvalue ]`
        * `-a` 逻辑与; `-o` 逻辑或
    * `[[ ! -z $var ]]`
        * `!` 条件取反

* 单/双中括号区别
    * 单括号的 TEST 命令要对变量进行单词分离，当变量值包含空白符时，要用双引号将变量括起来；而双括号的 TEST 命令不会对变量进行单词分离
    * 单括号的 TEST 命令不会对 `*` 进行扩展，而双括号 TEST 命令则会对 `*` 进行扩展
    * 单括号的 TEST 命令需要对大于号 `<` 和 小于号 `>` 加转义符 `\`，直接而双括号 TEST 命令不需要
    * `test` 指令相当于单中括号，即 `test condition` 相当于 `[ condition ]`
    * 注: dash 中只能用单中括号
<br>

* 例子: 测试单双中括号

```sh
lengjing@lengjing:~$ var="a b"
lengjing@lengjing:~$ [ $var = "a b" ]; echo $?
bash: [: 参数太多
2
lengjing@lengjing:~$ [[ $var = "a b" ]]; echo $?
0
lengjing@lengjing:~$ [ "$var" = "a b" ]; echo $?
0
lengjing@lengjing:~$ [[ "$var" = "a b" ]]; echo $?
0
lengjing@lengjing:~$ var="a b"
lengjing@lengjing:~$ [ $var = a* ]; echo $?
bash: [: 参数太多
lengjing@lengjing:~$ [[ $var = a* ]]; echo $?
0
lengjing@lengjing:~$ [[ "$var" = a* ]]; echo $?
0
lengjing@lengjing:~$ [ "$var" = "a*" ]; echo $?
1
lengjing@lengjing:~$ [[ "$var" = "a*" ]]; echo $?
1
lengjing@lengjing:$ [ a < b ]; echo $?
bash: b: 没有那个文件或目录
lengjing@lengjing:$ [ a \< b ]; echo $?
0
lengjing@lengjing:$ [[ a < b ]]; echo $?
0
lengjing@lengjing:$ [ a > b ]; echo $?
0
lengjing@lengjing:$ [ a \> b ]; echo $?
1
lengjing@lengjing:$ [[ a > b ]]; echo $?
1
```

### 条件语句

* if 命令语句: 命令运行成功，则运行条件后的命令

```sh
if command; then
    expression
elif command; then
    expression
else
    expression
fi
```

* if 条件语句: 条件成立，则运行条件后的命令

```sh
if [ condition ]; then
    expression
elif [ condition ]; then
    expression
else
    expression
fi
```

* case 语句: case 语句中如果 pattern 后的命令成立，则运行 pattern 后的语句
    * 每个变量内容建议用 `双引号` 括起来，关键字则为 `右圆括号`
    * 每个类别结尾使用 `两个连续的分号` 来处理
    * 最后一个变量内容会用 `*` 来代表所有其他值，
    * 最终以 `esac` 关键字结尾
    * pattern可使用 `|` 表示两个值，例如: `H264 | HEVC)`
    * pattern可使用范围表示，例如: `[a-z])`

```sh
case $var in
    pattern1)
        expression
        ;;
    pattern2 | pattern3)
        expression
        ;;
    [pattern4-patternn])
        expression
        ;;
    *)
        expression
        ;;
esac
```

### 循环语句

* for-in 语句: 对 list 中的每一项进行迭代
    * list 可以是一个字符串，也可以是一个序列，也可以是一个数组
    * 例如: `for i in $( seq 1 10 )`  or `for i in {1..10}`
    * 定界符 `IFS` 的默认值为空白字符(空格符 换行符 制表符)，可修改此变量从而使序列发生变化
    * 例如: `bIFS=$IFS; IFS=':'; for i in $(cat /etc/passwd); do echo $i;done`

```sh
for var in list; do
    expression
done
```

* for 语句: 类似C语言的 for 循环，注意空格
    * 注: dash 中不支持此种 for 循环
    * 例如: `for (( i=0; i<10; i++ ))`

```sh
for (( original; limit; step )); do
    expression
done
```

* while 语句: 条件为真时一直执行循环，直到条件为假
    * 注: `while true` 或 `while :` 表示死循环，只是 `while :` 不会每次执行循环内的命令时生成子进程
        * `true`是作为一个二进制文件实现的，`:` 是 shell 的内建命令，它的退出状态总是为0

```sh
while [ condition ]; do
    expression
done
```

* until 语句: 条件为假时一直执行循环，直到条件为真

```sh
until [ condition ]; do
    expression
done
```

注: 循环也有 `break` `continue` 关键字

## 正则表达式

* [图形工具](https://regexper.com/)

### 通配符匹配

* bash 通配符
    * `*`                       : 匹配任意个(含0个)任意字符
    * `?`                       : 匹配1个任意字符
    * `[ - ]`                   : 匹配1个中括号内的字符，例如: [a-b] 匹配1个小写字母
    * `[^ ]`                    : 匹配1个非中括号内的字符，例如: [^0-9] 匹配1个除了数字外的字符
    * `{ , }`                   : 匹配1个大括号的字符或字符串，例如: `{ab,ba}` 匹配 ab 或 ba

注: 通配符主要用于匹配完整文件名，正则表达式主要用于匹配文件中的行的部分文本

### 正则匹配

* 重复(标准正则表达式)
    * `.`                       : 匹配任意1个字符(是且只是1个)，一般不会匹配换行符
    * `*`                       : 匹配前1个字符任意次(包括0次)，例如: `co*l` 表示匹配 cl、col、coool ...
    * `{n}`                     : 匹配前面字符出现n次
    * `{n,}`                    : 匹配前面字符至少出现n次
    * `{n,m}`                   : 匹配前面字符出现n到m次

* 重复(扩展正则表达式)
    * `+`                       : 匹配前1个字符至少1次，例如: `co+l` 表示匹配 col、coool ... (不包括 cl)
    * `?`                       : 匹配前1个字符0次或1次，例如: `co?l` 表示匹配 cl、col

注: 重复匹配符默认是贪婪匹配(尽可能匹配多的字符)，可以在匹配符后加问号 `?` 表示非贪婪匹配(尽可能匹配少的字符)
<br>

* 定界(标准正则表达式)
    * `\< \>`                   : 精确匹配，如: `\<the\>` 表示精确匹配the这个单词，而不匹配包含the字符的单词
    * `^`                       : 匹配字符串开头，一般工具都是读取每行作为字符串，即 `^` 看做匹配行首
    * `$`                       : 匹配字符串结尾，即 `$` 看做匹配行尾，例如: `^$` 表示匹配空行 (注意 win 下的换行字符是 `^M$`，即 `\r\n`)
<br>

* 集合(标准正则表达式)
    * `[ ]`                     : 匹配字符集，`[]` 里面不管有几个字符，他都只代表1个字符，字符集里面的特殊字符加不加转义斜杠 `\` 都可以，例如: `[ab]`表示匹配a或匹配b
    * `[ - ]`                   : 匹配字符集(连续编码使用减号连接)，例如: 大写字母 `[a-z]`，小写字母 `[a-z]`，数字 `[0-9]`
    * `[^ ]`                    : 字符集的反向选择，例如: 非数字和英文 `[^a-zA-Z0-9]`

* 集合(扩展正则表达式)
    * `|`                       : 匹配用或的方式找出数个字符串, 例如: `ma(tri)|(ilbo)x` 表示匹配 matrix 或 mailbox
    * `(pattern)`               : 匹配子串，例如: `ma(tri)?x` 表示匹配 max 或 matrix

* 高级扩展(一般 Python 可用)
    * `\num`                    : 子串回溯匹配，`\0` 一般表示正则表达式本身，`\1` 表示第1个子项，`\2` 表示第2个....，例如: `([0-9])\1([0-9])\2` 表示匹配 `mmnn` 格式的数字
    * `(?:pattern)`             : 匹配子串，但子串不能回溯匹配
    * `(?aiLmsux)`              : 设置正则表达式标记，可同时设置多个，标记前面加减号 `-` 表示关闭标记
        * `i` 忽略大小写        : 进行忽略大小写匹配，例如: `(?i)b(?-i)ook`表示匹配 Book 或 book
        * `m` 多行模式          : 设置以后，`^` 匹配字符串的开始，和每一行的开始（换行符后面紧跟的符号）；`$` 匹配字符串尾，和每一行的结尾（换行符前面那个符号）
        * `s` 点号匹配全部字符  : 让 `.` 特殊字符匹配任何字符，包括换行符; 如果没有这个标记，`.` 匹配除了换行符的其他任意字符
        * `x` 冗长模式          : 注释(`#` 后面的到行尾)和空白符号会被忽略
        * `a` 只匹配 ASCII 字符 : 让 `\w`, `\W`, `\b`,` \B`, `\d`, `\D`, `\s` 和 `\S` 只匹配 ASCII，而不是 Unicode，只对 Unicode 样式有效
        * `L` 语言依赖          : 由当前语言区域决定 `\w`, `\W`, `\b`, `\B` 和大小写敏感匹配，这个标记只能对 byte 样式有效
        * `u` Unicode 匹配
    * `(?#annotation)`          : 注释；里面的内容会被忽略
    * `(?P<name>pattern)`       : 匹配 pattern 并为这个模式定义一个名字 name
    * `(?P=name)`               : 匹配前面 name 定义的 pattern，例如: `(?P<quote>['"]).*?(?P=quote)` 表示匹配单引号或者双引号括起来的字符串
    * `patterna(?=patternb)`    : 前视，只在后面是 patternb 的情况下匹配 patterna
    * `patterna(?!patternb)`    : 前视取反，只在后面不是 patternb 的情况下匹配 patterna
    * `(?<=patternb)patterna`   : 后视，只在前面是 patternb 的情况下匹配 patterna，例如: `(?<=a)[0-9](?=b)` 表示匹配处于ab之间的一个数字
    * `(?<!patternb)patterna`   : 后视取反，只在前面不是 patternb 的情况下匹配 patterna

### 字符集合

* 转义特殊字符(转义后表示字符本身)
    * `\.` `\*` `\+` `\-` `\?` `\[` `\]` `\{` `\}` `\(` `\)` `\\` `\|`
<br>

* ASCII C 转义字符
    * `\0`                      : 空字符，十进制为 0，十六进制为 0x00
    * `\a`                      : 响铃，十进制为 7，十六进制为 0x07
    * `\b`                      : 退格符，十进制为 8，十六进制为 0x08
    * `\t`                      : 水平制表符，十进制为 9，十六进制为 0x09
    * `\n`                      : 换行符，十进制为 10，十六进制为 0x0A
    * `\v`                      : 垂直制表符，十进制为 11，十六进制为 0x0B
    * `\f`                      : 换页符，十进制为 12，十六进制为 0x0C
    * `\r`                      : 回车符，十进制为 13，十六进制为 0x0D
    * `\"`                      : 双引号，十进制为 34，十六进制为 0x22
    * `\'`                      : 单引号，十进制为 39，十六进制为 0x27
    * `\?`                      : 问号，十进制为 63，十六进制为 0x3F
    * `\\`                      : 反斜杠，十进制为 92，十六进制为 0x5C
    * `\nnn`                    : 1~3位八进制数字表示的字符
    * `\xHH`                    : 1~2位十六进制数字表示的字符
    * `\uHHHH`                  : 1~4位十六进制数字表示的 Unicode (ISO/IEC 10646) 字符
    * `\UHHHHHHHH`              : 1~8位十六进制数字表示的 Unicode (ISO/IEC 10646) 字符
<br>

* 元字符
    * `\d`                      : 匹配数字 `[0-9]`
    * `\D`                      : 匹配非数字 `[^0-9]`
    * `\w`                      : 匹配字母数字下划线 `[a-zA-Z0-9_]`
    * `\W`                      : 匹配非字母数字下划线 `[^a-zA-Z0-9_]`
    * `\s`                      : 匹配空白字符 `[\r\n\f\t\v ]`
    * `\S`                      : 匹配非空白字符 `[^\r\n\f\t\v ]`
    * `\b`                      : 匹配单词边界(单词边界为字母数字下划线之间)
    * `\B`                      : 匹配非单词边界(单词边界为字母数字下划线之间)
    * `\A`                      : 匹配字符串开始
    * `\Z`                      : 匹配字符串结尾
<br>

* POSIX 字符类 (在正则表达式中POSIX字符类一般是2个连续的方括号，外层方括号表示集合，例如 `[[:digit:]]`)
    * `[:digit:]`               : 表示数字 `[0-9]`
    * `[:xdigit:]`              : 表示十六进制数 `[a-fA-F0-9]`
    * `[:lower:]`               : 表示小写字母 `[a-z]`
    * `[:upper:]`               : 表示大写字符 `[A-Z]`
    * `[:alpha:]`               : 表示大小写字母 `[a-zA-Z]`
    * `[:alnum:]`               : 表示大小写字母和数字 `[a-zA-Z0-9]`
    * `[:blank:]`               : 表示空格或 Tab `[\t ]`
    * `[:space:]`               : 表示空白字符 `[\r\n\f\t\v ]`
    * `[:cntrl:]`               : 表示 ASCII 控制字符，ASCII 码 0-31 和 ASCII 码 127
    * `[:print:]`               : 表示 ASCII 码 32-126
    * `[:graph:]`               : 表示 ASCII 码 33-126，比 `[:print:]` 少了空格
    * `[:punct:]`               : 表示 ASCII 码 32-47 和 58-64 和 91-96 和 123-126，`[:print:]`除去 `[:alnum:]`

## 文本处理

### 文件查找 find

* `find [path] [options] [action]`
    * 功能
        * 查找文件，默认会遍历完所有的子目录
        * path 省略时默认查找当前目录，path 也可以指定为多个目录
        * options 前可以加 `!空格` 否定某项参数，例如: `find . ! -name "*.o"`
    * 查找参数(通过文件名查找)
        * `-name filename`      : 搜寻文件名称为 filename 的文件，可以使用**通配符**
        * `-iname filename`     : 搜寻文件名称为 filename 的文件，忽略大小写
        * `-regex pattern`      : 正则搜寻文件名称匹配 pattern 的文件
        * `-iregex pattern`     : 正则搜寻文件名称匹配 pattern 的文件，忽略大小写
    * 查找参数(通过文件类型查找)
        * `-type typename`      : 搜寻文件的类型为 typename 的文件，
            * 类型主要有: `f` 一般文件 `d` 目录 `l` 符号链接 `c` 字符设备 `b` 块设备文件 `s` socket `p` FIFO
    * 查找参数(通过文件大小查找)
        * `-size +value`        : 搜寻比 value 还要大的文件
            * 单位有: `c` 1 byte; `w` 2 bytes; `b` 512 bytes; `k` 1024 bytes; `M` 1024k bytes; `G` 1024M bytes
        * `-size -value`        : 搜寻比 value 还要小的文件，例如: 查找比1MB小的文件 `find -size -1M`
    * 查找参数(通过文件时间查找)
        * `-newer filename`     : 列出比 filename 文件还要新的文件
        * `-mtime num`          : 列出在 num 天之前的那一天内被更改过内容的文件
            * num 前加加号 `+` 表示 num 天之前(不含)改动，num 前加减号 `-` 表示 num 天之内(含)改动，ctime 和 atime 同理
        * `-ctime num`          : 列出在 num 天之前的这一天内被更改过属性的文件
        * `-atime num`          : 列出在 num 天之前的这一天内被访问过的文件
    * 查找参数(通过文件用户查找)
        * `-user username`      : 文件所属用户为 username 的文件
        * `-group groupname`    : 文件所属组为 groupname 的文件
        * `-perm xyz`           : 文件属性为 xyz 的文件
    * 限定参数
        * `-L`                  : 如果符号链接指向了目录，默认不会查找指向的目录，该选项改变此默认值
        * `-maxdepth num`       : 搜索最大深度为 num , num=1 时只在当前目录搜索
        * `-mindepth num`       : 搜索最小深度为 num
        * `-a` or `-and `       : 逻辑与(AND)操作，例如: `find . \( -name '*e*' -and -name 's*' \)`
        * `-o` or `-or`         : 逻辑或(OR)操作，例如: `find . \( -name '*.c' -o -name '*.h' \)`
        * `-path GLOB -prune`   : 排除某些文件夹，例如: `find -path 'linux-*' -prune -o -path '.git'  -prune -o -iname "*.c" -print` 整条语句理解为当 prune 执行为 true 时，那么就不再执行后面的选项
    * 动作参数
        * `-print`              : 打印找到的文件的文件名，默认动作
        * `-delete`             : 删除找到的文件
        * `-exec command`       : 对找到的文件执行 command
            * command 中的 `{}` 表示对于每一个相应的匹配文件的文件名，例如: `find -name *.html -exec cp {} ../html \;`
<br>

* 例子 find.sh: 查找指定目录下的指定文件名的文件
    * 用法: `./find.sh [find_str]` or `./find.sh [options]`，可使用 `./find.sh -h` 查看详细帮助信息
    * 用户可以修改 `ignore_path` `used_path` 对应他自己的工程

```sh
#!/bin/bash

find_str=
find_path=
ignore_path="arch-v1 arch-v2 arch-v3 arch-v4 arch-v5 armv7-a-hf armv8-a dsp-v1 dsp-v2 dsp-v3 ai-v1 ai-v2 linux* out"
used_path="arch-v5 armv8-a dsp-v3 ai-v2"

usage() {
	echo "========================================"
	echo -e "\033[34mUsage: '$0 find_str' or '$0 [options]'\033[0m"
	echo -e "\033[34moptions:\033[0m"
	echo -e "\033[34m-s find_str\033[0m     : Specify the find string."
	echo -e "\033[34m-p find_path\033[0m    : Specify the find path."
	echo                   "                  The default value is current dir."
	echo -e "\033[34m-i ignore_path\033[0m  : Specify the ignore dir names to process."
	echo                   "                  The default value is all the dir names related to version."
	echo -e "\033[34m-u used_path\033[0m    : Specify the dir names which will be removed from the ignored dir names."
	echo                   "                  The default value is 'arch-v5 armv8-a dsp-v3 ai-v2'."
	echo "========================================"
}

if [ $# -eq 0 ]; then
	usage
	exit 1
elif [ $# -eq 1 ] && [[ $1 != '-h' ]]; then
	find_str=$1
else
	while getopts "s:p:i:u:h" opt; do
		case $opt in
			s) find_str=$OPTARG;;
			p) find_path=$OPTARG;;
			i) ignore_path=$OPTARG;;
			u) used_path=$OPTARG;;
			h) usage; exit 0;;
			*) echo "Error option: -$opt"; usage; exit 1;;
		esac
	done
fi

for i in ${used_path}; do
	ignore_path=$(echo "${ignore_path}" | sed -e "s:^${i} ::" -e "s: ${i} : :"  -e "s: ${i}$::")
done

start_time_sec=`date +%s`

cmd=$(echo find ${find_path} -path \'*/.git\' -prune \
	$(echo "${ignore_path}" | sed "s:\([*a-zA-Z0-9_\-]\+\):-o -path '*/\1' -prune:g") \
	-o -name \"${find_str}\" -print)

cd `pwd`
eval $cmd

end_time_sec=`date +%s`
echo -e "\033[34mCost $(( $end_time_sec - $start_time_sec )) seconds.\033[0m"
echo -e "\033[32m$cmd\033[0m"
```

* 例子 ctags.sh: 对指定目录下的源码文件生成 ctags 索引文件
    * 用法: `./ctags.sh` or `./ctags.sh [options]`，可使用 `./ctags.sh -h` 查看详细帮助信息
    * 用户可以修改 `ignore_path` `used_path` 对应他自己的工程


```sh
#!/bin/bash

# ctags和omnicppcomplete配合自动补全 ctags --c++-kinds=+p --fields=+ialS --extra=+q
# --c++-kinds=+p  : 为C++文件增加函数原型的标签
# --fields=+ialS  : 在标签文件中加入继承信息(i)、类成员的访问控制信息(a)、 源文件语言包含信息(l)、以及函数的指纹(S)
# --extra=+q      : 为标签增加类修饰符，如果没有此选项，将不能对类成员补全

ctags=ctags
more_options="--c++-kinds=+p --fields=+ialS --extra=+q"
find_path=
ignore_path="arch-v1 arch-v2 arch-v3 arch-v4 arch-v5 armv7-a-hf armv8-a dsp-v1 dsp-v2 dsp-v3 ai-v1 ai-v2 linux* out"
used_path="arch-v5 armv8-a dsp-v3 ai-v2"
find_suffix="c h cc cpp c++ hh hpp hxx"

usage() {
	echo "========================================"
	echo -e "\033[34mUsage: '$0' or '$0 [options]'\033[0m"
	echo -e "\033[34moptions:\033[0m"
	echo -e "\033[34m-m\033[0m              : Specify using 'ctags ${more_options}'."
	echo -e "\033[34m-p find_path\033[0m    : Specify the find path."
	echo                   "                  The default value is current dir."
	echo -e "\033[34m-i ignore_path\033[0m  : Specify the ignore dir names to process."
	echo                   "                  The default value is all the dir names related to version."
	echo -e "\033[34m-u used_path\033[0m    : Specify the dir names which will be removed from the ignored dir names."
	echo                   "                  The default value is 'arch-v5 armv8-a dsp-v3 ai-v2'."
	echo "========================================"
}

while getopts "mp:i:u:h" opt; do
	case $opt in
		m) ctags="ctags ${more_options}";;
		p) find_path=$OPTARG;;
		i) ignore_path=$OPTARG;;
		u) used_path=$OPTARG;;
		h) usage; exit 0;;
		*) echo "Error option: -$opt"; usage; exit 1;;
	esac
done

for i in ${used_path}; do
	ignore_path=$(echo "${ignore_path}" | sed -e "s:^${i} ::" -e "s: ${i} : :"  -e "s: ${i}$::")
done

start_time_sec=`date +%s`

cmd=$(echo ${ctags} \$\(find ${find_path} -path \'*/.git\' -prune \
	$(echo "${ignore_path}" | sed "s:\([*a-zA-Z0-9_\-]\+\):-o -path '*/\1' -prune:g") \
	$(echo "${find_suffix}" | sed 's:\([*a-zA-Z0-9_+\-]\+\):-o -iname "*.\1" -print:g')\))

cd `pwd`
eval $cmd

end_time_sec=`date +%s`
echo -e "\033[34mCost $(( $end_time_sec - $start_time_sec )) seconds.\033[0m"
echo -e "\033[32m$cmd\033[0m"
```

### 文本搜索 [grep](https://www.gnu.org/software/grep/manual/grep.html)

* `grep [options] [grep_str] [file1] [file2] ...`
    * 功能
        * 搜索文件中正则匹配的行，默认输出 `文件名: 匹配行`
        * 搜索的字符串使用正则表达式，包含空格时，必须用单引号或双引号括起来，双引号会对表达式求值
        * 不使用文件名时，一般与 `-r` 选项合用，表示递归搜索当前文件夹下的所有字符串
    * 处理参数
        * `grep -G`             : 表示使用基本正则表达式，**默认行为**
        * `grep -E` or `egrep`  : 表示使用扩展正则表达式
        * `grep -P`             : 表示使用 Perl 正则表达式
        * `grep -F`             : 表示不使用正则表达式
        * `grep -f file`        : 从文件中获取搜索的字符串的样式，每个样式一行，相当于与逻辑
        * `grep -e "pattern1" -e "pattern2"` : 同时匹配，等价于 `grep "pattern1" | grep "pattern2"`
    * 范围参数
        * `-r` or `-R`          : 递归搜索，`-r` 不会解符号链接，而 `-R` 会
        * `--include=GLOB`      : 包含某些文件，GLOB 表示可使用通配符，例如: `grep -rn "\<malloc\> *(" ./  --include=*.{c,cpp,h}`
        * `--exclude=GLOB`      : 排除某些文件
        * `--exclude-dir=GLOB`  : 排除某些文件夹
    * 控制参数
        * `-i`                  : 忽略大小写
        * `-v`                  : 反向匹配
        * `-w`                  : 精确匹配单词
        * `-x`                  : 精确匹配行
    * 输出参数
        * `-n`                  : 输出匹配行的行号，输出 `文件名:行号: 匹配行`
        * `-c`                  : 只列出匹配多少行，并不是匹配的次数，相当于 `grep -x "xxx" | wc -l`
        * `-l`                  : 只输出有匹配的文件列表，而不是匹配的行，`-L` 相反
        * `-o`                  : 只输出匹配部分的字符串，一行有多个匹配会输出多行，例如: `echo this is a line. | egrep -o "[a-z]+\."` 输出 `line.`
        * `-q`                  : 静默模式，无任何输出，命令运行结果 `$?`: 匹配到会返回 0，否则返回 1
        * `-A` / `-B` / `-C`    : 输出匹配行的周边行，选项后面可加数字，`A / B / C` 分别表示除了列出匹配行外，`后面 / 前面 / 两面` 的n行也列出来
<br>

* `ag [options] pattern [path ...]`
    * 功能
        * 递归搜索目录中文件(默认不搜索二进制文件)匹配的行，类似 `grep -rni` ，但执行效率比 grep 高
        * 安装方法 `sudo apt install silversearcher-ag`
    * 命令参数
        * `-a`                  : 搜索(不包括隐藏文件和忽略文件的)全部文件
        * `-s`                  : 大小写敏感
        * `-f`                  : 解符号链接
        * `--workers NUM`       : 多线程搜索
        * `-g GLOB`             : 打印和 GLOB 匹配(匹配一部分即可)的文件路径名
        * `-G GLOB`             : 仅搜索与 GLOB 匹配(匹配一部分即可)的文件名中的内容
        * `--ignore GLOB`       : 搜索排除与 GLOB 匹配文件或文件夹
        * 注: `-v` `-w` `-c` `-l` `-L` `-o` `-A` `-B` `-C` 等选项意义同 grep
<br>

* 例子 grep.sh: 搜索指定目录下的指定后缀的文件中的字符串
    * 用法: `./grep.sh [grep_str]` or `./grep.sh [options]`，可使用 `./grep.sh -h` 查看详细帮助信息
    * 用户可以修改 `ignore_path` `used_path` 对应他自己的工程

```sh
#!/bin/bash

grep_option=
grep_str=
grep_path=
ignore_path="arch-v1 arch-v2 arch-v3 arch-v4 arch-v5 armv7-a-hf armv8-a dsp-v1 dsp-v2 dsp-v3 ai-v1 ai-v2 linux* out"
used_path="arch-v5 armv8-a dsp-v3 ai-v2"
grep_suffix="c cc cp cxx cpp CPP c++ C h hh hp hxx hpp HPP h++ H"

usage() {
	echo "========================================"
	echo -e "\033[34mUsage: '$0 grep_str' or '$0 [options]'\033[0m"
	echo -e "\033[34moptions:\033[0m"
	echo -e "\033[34m-o grep_option\033[0m  : Specify the additional grep options. for example: -o '-w'."
	echo -e "\033[34m-s grep_str\033[0m     : Specify the grep string."
	echo -e "\033[34m-p grep_path\033[0m    : Specify the grep path."
	echo                   "                  The default value is current dir."
	echo -e "\033[34m-i ignore_path\033[0m  : Specify the ignore dir names to process."
	echo                   "                  The default value is all the dir names related to version."
	echo -e "\033[34m-u used_path\033[0m    : Specify the dir names which will be removed from the ignored dir names."
	echo                   "                  The default value is 'arch-v5 armv8-a dsp-v3 ai-v2'."
	echo -e "\033[34m-x grep_suffix\033[0m  : Specify the filename suffix to grep."
	echo                   "                  The default value is the C/C++ source code suffix."
	echo "========================================"
}

if [ $# -eq 0 ]; then
	usage
	exit 1
elif [ $# -eq 1 ] && [[ $1 != '-h' ]]; then
	grep_str=$1
else
	while getopts "o:s:p:i:u:x:h" opt; do
		case $opt in
			o) grep_option=$OPTARG;;
			s) grep_str=$OPTARG;;
			p) grep_path=$OPTARG;;
			i) ignore_path=$OPTARG;;
			u) used_path=$OPTARG;;
			x) grep_suffix=$OPTARG;;
			h) usage; exit 0;;
			*) echo "Error option: -$opt"; usage; exit 1;;
		esac
	done
fi

for i in ${used_path}; do
	ignore_path=$(echo "${ignore_path}" | sed -e "s:^${i} ::" -e "s: ${i} : :"  -e "s: ${i}$::")
done

start_time_sec=`date +%s`

cmd=$(echo grep -rn --color=auto ${grep_option} \"${grep_str}\" ${grep_path} --exclude-dir=.git \
	$(echo "${ignore_path}" | sed 's:\([*a-zA-Z0-9_\-]\+\):--exclude-dir=\1:g') \
	$(echo "${grep_suffix}" | sed 's:\([*a-zA-Z0-9_+\-]\+\):--include=*.\1:g'))

cd `pwd`
eval $cmd

end_time_sec=`date +%s`
echo -e "\033[34mCost $(( $end_time_sec - $start_time_sec )) seconds.\033[0m"
echo -e "\033[32m$cmd\033[0m"
```

### 流编辑器 [sed](https://www.gnu.org/software/sed/manual/sed.html)

* `sed [options] 'pattern command' [file1] [file2] ...`
    * 功能
        * 编辑流中的匹配的行，如果不指定文件，需要从管道读取输入
        * `pattern command` 必须用单引号或双引号括起来，双引号会对表达式求值
        * 临时缓冲区
            * 模式空间: 模式空间中的内容会主动打印到标准输出，并自动清空
            * 保持空间: 保持空间内容不会主动清空，也不会主动打印到标准输出，而是需要 sed 命令来进行处理
        * 工作流程
            1. 模式空间初始化为空，保持空间初始化为一个空行，也就是默认带一个 `\n`
            2. 读取文件的一行，存入模式空间，检查该行和提供的样式 `pattern`(可选) 是否匹配，如果没有提供样式，那么所有的行都是匹配的
            3. 如果匹配，(在模式空间)对匹配的行进行命令处理
            4. 不管是否匹配，sed 默认会将模式空间的内容输出打印到标准输出(`-n` 取消此默认行为)，接着清空模式空间
            5. 然后继续读取下一行的内容到模式空间，继续处理，依次循环处理
    * 命令参数
        * `sed -e 'pattern command'` : 从命令行获取命令的样式，默认选项，只有一个命令时可以省略 `-e`
            * 可同时使用多个样式 `sed -e 'expression' -e 'expression'` or `sed 'expression' | sed 'expression'` or `sed 'expression; expression'`
        * `sed -f file`         : 从文件中获取命令的样式
        * `sed -E` or `sed -r`  : 支持扩展正则表达式，**不加此选项时扩展正则表达式符号要加反斜杠 `\` 转义**
        * `--debug`             : 调试 sed
        * `-n`                  : 不打印模式空间的行，例如: `sed -n '2p' filename` 表示只打印 filename 文件的第2行
        * `-i`                  : 在文件中直接修改文件内容，不加此选项时默认打印到屏幕
<br>

* 匹配样式(pattern)
    * 行号匹配
        * `n`                   : 匹配第n行，其中 `1` 是首行，`$` 是尾行
        * `n,m`                 : 匹配第n行(含)到第m行(含)之间的行
        * `n,+m`                : 匹配第n行(含)之后的共m行
        * `n,~m`                : 匹配第n行(含)直到到后面第一个行号被m整除(含)之间的行
    * 正则匹配
        * `/regexp/`            : 匹配包含正则表达式 regexp 的行
        * `\cregexpc`           : 匹配包含正则表达式 regexp 的行，c是定界符，可换成其它字符
    * 混合匹配
        * `/regexp/,n`          : 匹配从与 regexp 匹配的行(含)到第n行(含)之间的行，可以匹配多次
        * `n,/regexp/`          : 匹配从第n行(含)到第一个与 regexp 匹配的行(含)之间的行，如果第n行后的行都与 regexp 不匹配，将匹配到文件结尾
    * 匹配取反
        * `n,m!`                : 匹配不是第n行到第m行之间的行，上面的匹配都可以加感叹号 `!` 匹配取反

* 执行命令(command)
    * 编辑命令(常用)
        * `p`                   : 打印行，打印模式空间，通常 `p` 会与参数 `sed -n` 一起运行
        * `d`                   : 删除行，清空模式空间，模式空间只有一行时 `d` `D` 作用相同
        * `i text`              : 插入行，在当前行的上一行插入内容为 text 的行
        * `a text`              : 追加行，在当前行的下一行追加内容为 text 的行
        * `c text`              : 取代行, 使用内容为 text 的行取代当前行(`i` `a` `c` 命令可写成两行，第一行加 `\` 转义换行)
    * 编辑命令(不常用)
        * `D`                   : 删除行，删除模式空间中的内容直到第一个换行符，并使用生成的模式空间重新开始循环，而不读取新的输入行
        * `e`                   : 执行命令，执行在模式空间中找到的命令并用输出替换模式空间(不带尾随换行符被抑制)
        * `e command`           : 执行命令，执行命令并将其输出发送到输出流，该命令可以跨多行运行，除了最后一行以反斜杠结尾
        * `F`                   : 打印文件名，打印当前输入文件的文件名(带尾随换行符)
        * `=`                   : 打印行号，打印当前输入的行号(带尾随换行符)
        * `P`                   : 打印行，打印模式空间中的内容直到第一个换行符
        * `r file`              : 追加文件，在当前行的下一行追加 file 文件的内容
        * `R file`              : 追加文件行，在当前循环结束时或在读取下一个输入行时，将要读取的文件的一行插入到输出流中
        * `w file`              : 另存文件，将当前模式空间的内容写入到另外的文件
        * `W file`              : 另存文件，将当前模式空间空间中的内容直到第一个换行符写入到另外的文件
    * 空间置换命令
        * `h`                   : 把模式空间内容覆盖到保持空间中
        * `H`                   : 把模式空间内容追加到保持空间中
        * `g`                   : 把保持空间内容覆盖到模式空间中
        * `G`                   : 把保持空间内容追加到模式空间中
        * `x`                   : 交换模式空间与保持空间的内容
        * `z`                   : 情况模式空间的内容
<br>

* 取代匹配 `sed -i 's/regexp/replace/g'`
    * 使用说明
        * 取代匹配的关键字是 `s`，关键字前面还可以加行范围
        * 一般使用 `/` 作为区域分隔字符，也可以使用其他任意字符
        * sed 默认只会打印替换后的文本，如果要在替换的同时保存更改到原文件，可以使用 `-i` 选项
        * sed 默认会将每一行中第一处符合模式的内容替换掉，如果要替换该行的所有匹配，需要在命令尾部加上参数 `g`, 如果要替换该行的第n处匹配开始之后所有的匹配，需要在命令尾部加上参数 `ng`
        * 例如: `sed -i .bak 's/regexp/replace/g' filename` 保存更改到原文件，并创建备份文件 filename.bak
        * 例如: `sed -i '1,10s/\<malloc\>[ \t]*([ \t]*/calloc(1, /g' file` # 表示 file 文件的前10行的所有 malloc 函数替换成 calloc 函数
    * 已匹配字符串标记 `&`
        * replace 中的 `&` 是已匹配字符串标记，代表前面匹配的字符串
        * 例如: `echo Leng Jing | sed 's/\w\+/[&]/g'` 输出为 `[Leng] [Jing]`
    * 子串匹配标记 `\n`
        * 子串匹配标记 `\n`，`\1` 表示第1个子串，`\2` 表示第2个子串，依此类推...
        * 子串是圆括号括起来的字符串
        * 例如: `echo Leng Jing | sed 's/\(\w\+\) \(\w\+\)/\2 \1/'` or `echo Leng Jing | sed -E 's/(\w+) (\w+)/\2 \1/'` 输出为 `Jing Leng`
<br>

* 简单例子
    * `sed -n '/\<malloc\>/p' file` : 表示打印 file 文件含有 malloc 单词的行
    * `sed -n '1,10p' file`         : 表示打印 file 文件的前10行
    * `sed -i '1,10d' file`         : 表示删除 file 文件的前10行
    * `sed -i '/^[ \t]*$/d' file`   : 表示删除空白行
    * `sed -i 'a \\' file`          : 表示 file 文件的每一行之后都增加新的空行
    * `sed -i '$ a abcdsfg' file`   : 表示 file 文件的最后一行之后增加新的行 "abcdsfg"
    * `sed -i '1i #!/bin/bash' file`: 表示 file 文件第1行之前增加新行，该行字符串为 "#!/bin/bash"
    * `sed -i 'c hello' file`       : 表示 file 文件的每一行都替换成了 "hello"
<br>

* 例子 rename.sh: 替换掉源码中的符号定义
    * 用法: `./rename.sh [replace] [olddefs] [defvars]`，例如: `./rename.sh "ENV_ARCH" "CONFIG_ARCH CONFIG_VERSION" "V1 V2"`
        * replace               : 新的定义名字
        * olddefs               : 旧的定义名字
        * defvars               : 该变量可以被赋予的值
    * 例子说明:
        * 配置文件中使用了 `CONFIG_ARCH` `CONFIG_VERSION`
        * Makefile 中使用了 `CONFIG_ARCH` `CONFIG_VERSION` `-DCONFIG_ARCH_$(CONFIG_ARCH)` `-DCONFIG_VERSION_$(CONFIG_VERSION)`
        * 源码文件中使用了 `CONFIG_ARCH_V1` `CONFIG_ARCH_V2` `CONFIG_VERSION_V1` `CONFIG_VERSION_V2`
        * 本例子把上面所有的字符串中的 CONFIG_ARCH 和 CONFIG_VERSION 换成了 ENV_ARCH

```sh
#!/bin/bash

do_rename() {
	replace=$1
	olddefs=$2
	defvars=$3

	for i in ${olddefs}; do
		for j in ${defvars}; do
			str=${i}_${j}
			files=$(grep -rwl "${str}" | xargs)
			if [ ! -z "${files}" ]; then
				echo -e "\033[32mRename ${str}\033[0m"
				echo ${files}
				sed -i "s/\<${str}\>/${replace}_${j}/g" ${files}
			fi
		done

		str=D${i}_
		files=$(grep -rwl "${str}" | xargs)
		if [ ! -z "${files}" ]; then
			echo -e "\033[32mRename ${str}\033[0m"
			echo $files
			sed -i "s/\<${str}\>/D${replace}_/g" ${files}
		fi

		str=${i}
		files=$(grep -rwl "${str}" | xargs)
		if [ ! -z "${files}" ]; then
			echo -e "\033[32mRename ${str}\033[0m"
			echo $files
			sed -i "s/\<${str}\>/${replace}/g" ${files}
		fi
	done
}

do_rename "$1" "$2" "$3"
```

### 文本编辑语言 [awk](https://www.gnu.org/software/gawk/manual/gawk.html)

* `awk [options] 'BEGIN{commands} pattern{commands} END{commands}' [file1] [file2] ...`
    * 功能
        * awk 是一个强大的文本分析语言(数据驱动)，有它自己的一套脚本语法(类似C语言，换行又是脚本形式)
        * 程序一般使用单引号包含，由3个块组成: 开始块 `BEGIN{commands}`、主体块 `pattern{commands}`、结束块 `END{commands}`，都是可选的
        * `BEGIN` 和 `END` 是关键字，匹配样式 `pattern` 可以是正则表达式、条件语句以及行匹配范围等
        * commands 中多个命令使用分号 `;` 分隔，支持条件语句和循环语句，支持各种运算，**变量引用不需要加美元符 `$`**
        * 工作流程
            * 从输入流中读取行之前执行 `BEGIN {commands}` 语句块(可选)中的语句
            * 从文件或 stdin 中每读取一行，awk 就会检查该行和提供的样式 `pattern`(可选) 是否匹配，如果没有提供样式，那么 awk 就认为所有的行都是匹配的
            * 如果当前行匹配该样式，则执行 `{commands}` 中的语句(可选)，如果不提供该语句块，则默认执行 `{ print }` ，即打印所读取到的每一行
            * 读取完所有的行之后执行 `END {commands}` 语句块(可选)中的语句
        * 打印
            * `print var1,var2` or `print var1 var2` : print 会自动增加换行符 ，参数以逗号进行分隔时，打印后多个参数间是空格分隔；以空格进行分隔时，打印后多个参数间没有分隔
            * `printf "format",var1,var2` : printf 不会自动增加换行符，是格式化打印
            * 例如: `echo abc | awk '{print 100 ":" $0}'` or `echo abc | awk '{printf "%d:%s\n",100,$0}'` or `echo abc | awk '{print sprintf("%d:%s",100,$0)}'` 都输出 `100:abc`
    * 命令参数
        * `awk -f awk_script`   : 执行 awk_script 脚本文件
        * `-F separator`        : 指定分隔符，可以是字符串或正则表达式，默认分隔符是(1个或多个)空格，分隔符分开的每一项称为一个域(字段)
        * `-v var1=value1 var2=value2 ...` : 定义用户变量
<br>

* 匹配样式
    * 行号匹配
        * `NR==n`               : 匹配第n行，还支持 `!=` `<` `<=` `>` `>=` 等其它运算符，也可以使用运算再条件判断，例如: `awk 'NR % 2 == 0'`
        * `NR==n,NR==m`         : 匹配第n行(含)到第m行(含)之间的行
    * 正则匹配
        * `/regexp/`            : 匹配包含正则表达式 regexp 的行
        * `/regexpn/,/regexpm/` : 匹配包含正则表达式 regexpn(含) 到 regexpm(含)之间的行
    * 混合匹配
        * `/regexp/,n`          : 匹配从与 regexp 匹配的行(含)到第n行(含)之间的行，可以匹配多次
        * `n,/regexp/`          : 匹配从第n行(含)到第一个与 regexp 匹配的行(含)之间的行，如果第n行后的行都与 regexp 不匹配，将匹配到文件结尾
    * 匹配取反
        * `!/regexp/`           : 匹配不包含正则表达式 regexp 的行，上面的匹配都可以加感叹号 `!` 匹配取反
<br>

* 运算符
    * `=` `+=` `-=` `*=` `/=` `%=` `^=` `**=`   : 赋值
    * `?:`                      : C条件表达式
    * `||`                      : 逻辑或
    * `&&`                      : 逻辑与
    * `~` `!~`                  : 判断匹配/不匹配后面的正则表达式 `/regexp/`
    * `<` `<=` `>` `>=` `!=` `==` : 关系运算符
    * ` `                       : 空格，连接符，可连接字符串
    * `+` `-`                   : 加 减
    * `*` `/` `%`               : 乘 除 余
    * `+` `-` `!`               : 一元加 减 逻辑非
    * `^` `***`                 : 求幂
    * `++` `--`                 : 自增 自减，作为前缀或后缀
    * `$`                       : 字段引用
    * `in`                      : 是否是数组成员
<br>

* 条件和循环(类似C语言，循环语句也有 `break` 和 `continue`)
    * `if (condition) { commands } else if (condition) { commands } else { commands }` : if 条件语句
    * `for (init_clause; cond_expression; iteration_expression)` : for 循环语句，例如: `len = length(array); for (i=1; i<=len; i++) {print array[i]}`
    * `for (var in array) { commands }` : for-in 循环语句，例如: `for (i in array) {print array[i]}`
    * `while (condition) { commands }`  : while 循环语句
    * `do { commands } while (condition)` : do-while 循环语句
<br>

* 内置变量
    * `FILENAME`                : 当前处理的文件名，没有文件时值是 `-`
    * `NR`                      : Number of Record，已经读出的记录数，即行号，从1开始
    * `FNR`                     : 多文件操作时，新打开文件时 FNR 会重新从1开始，而 NR 则不会
    * `NF`                      : Number for Field，当前记录中的字段个数
    * `$0`                      : 当前记录，即当前行的文本内容
    * `$1` `$2` `...`           : 当前记录中的第 `1 / 2 /...` 个字段的文本内容，最后一个字段用 `$NF`， 倒数第2个字段用 `$(NF‐1)`
    * `RS`                      : Record Separator，输入记录的分隔符，默认是换行符
    * `FS`                      : Field Separator，输入字段的分隔符，默认是空格符
    * `ORS`                     : Out of Record Separator，输出记录的分隔符，默认是换行符
    * `OFS`                     : Out of Field Separator，输出字段的分隔符，默认是空格符
    * `IGNORECASE`              : 设为1时忽略大小写
<br>

* 内建函数
    * [字符串函数](https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html)
        * `asort(source[,dest[,how ]])` `asorti(source[,dest[,how ]])`
            * `asort` 按数组 `source` 的值排序，且将数组的索引替换为从1开始的连续整数，数组的值还是原来的值
            * `asorti` 按数组 `source` 的索引排序，且将数组的索引替换为从1开始的连续整数，数组的值是原来的索引
            * 有 `dest` 参数时，将排序后的值保存到 `dest`，否则直接在 `source` 上排序保存
            * `how` 使用自定义函数排序，使用时函数名要用双引号包含，函数定义为 `function cmp_name(i1, v1, i2, v2)`，其中 `i` 表示索引，`v` 表示值
            * 例如: `echo | awk '{a[1]="orange"; a[3]="apple"; a[4]="pear"; asort(a); for (i in a) printf "[%d:%s]",i,a[i]} END{print ""}'` 输出 `[1:apple][2:orange][3:pear]`
            * 例如: `echo | awk '{a[1]="orange"; a[3]="apple"; a[4]="pear"; asorti(a); for (i in a) printf "[%d:%s]",i,a[i]} END{print ""}'` 输出 `[1:1][2:3][3:4]`
        * `sub(regexp,replace[,str])` `gsub(regexp,replace[,str])` `gensub(regexp,replace,how[,str])`
            * `sub` 将字符串 `str` 中正则表达式 `regexp` 匹配到的第1处内容替换成字符串 `replace`
            * `gsub` 将字符串 `str` 中正则表达式 `regexp` 所有匹配到的内容替换成字符串 `replace`
            * `gensub` 将字符串 `str` 中正则表达式 `regexp` 匹配到的指定位置的内容替换成字符串 `replace`
            * 函数返回值是替换的个数
            * `replace` 中可用 `&` 表示匹配到的字符串
            * 不指定 `str` 时缺省值是当前记录 `$0`
            * `gensub` 中的 `how` 为 `g` / `G` 时替换所有匹配到内容，为数字时替换匹配到的第 `how` 处内容
            * 例如: `echo axbxc | awk '{var=gsub(/x/,"|&|"); print var ":" $0}'` 输出 `2:a|x|b|x|c`
        * `length([str])`
            * 返回字符串 `str` 的长度
            * 不指定 `str` 时缺省值是当前记录 `$0`，也可以省略小括号
            * 例如: `echo abcdefg | awk '{print length}'` 输出 `7`
        * `substr(str,start[,len])`
            * 提取字符串 `str` 的子串
            * 位置从1开始编号，从位置 `start`(含)，提取 `len` 个字符
            * 不指定 `len` 时输出直到结尾
            * 例如: `df -h | awk '{if (int(substr($5,1,length($5)-1)) > 80) print $0}'` 输出空间占用大于 80 的磁盘
        * `index(str,substr)`
            * 返回字符串 `substr` 在字符串 `str` 出现的位置
            * 位置从1开始编号，找到时返回位置编号，没找到时返回0
            * 例如: `echo abcdefg | awk '{print index($0,"cd"),index($0,"hi")}'` 输出 `3 0`
        * `match(str,regexp)`
            * 返回正则表达式 `regexp` 在字符串 `str` 首次匹配的位置
            * 位置从1开始编号，匹配时返回首次匹配的位置编号，没找到时返回0
            * 匹配同时 `RSTART` 特殊变量设置为位置编号，否则设置为 0
            * 匹配同时 `RLENGTH` 特殊变量设置为匹配的字符串的长度，否则设置为 -1
            * 例如: `echo 'Hello World!' | awk '{ret=match($0,/\w+/); print ret,RSTART,RLENGTH}'` 输出 `1 1 5`
            * 例如: `echo 'Hello World!' | awk '{ret=match($0,/abc/); print ret,RSTART,RLENGTH}'` 输出 `0 0 -1`
        * `split(str,array[,delimiter[,seps]])` `patsplit(str,array[,regexp[,seps]])`
            * `split` 使用定界符 `delimiter` 将字符串 `str` 切割成子字符串数组存入 `array`，返回分割后的元素总数
            * `patsplit` 使用正则表达式 `regexp` 提取字符串 `str` 匹配的子字符串数组存入 `array`，返回提取后的元素总数
            * `split` 不指定 `delimiter` 时默认使用输入字段的分隔符 `FS`
            * `seps` 是 gawk 扩展，保存 `str` 中的分隔的/不匹配的字符串为数组
            * 例如: `echo a:b:c | awk '{split($0,array,":"); for (i in array) printf "%s",array[i]} END{print ""}'` 输出 `abc`
            * 例如: `echo ab:cd:ef:g | awk '{patsplit($0,array,/\w+/); for (i in array) printf "(%s)",array[i]} END{print ""}'` 输出 `(ab)(cd)(ef)(g)`
        * `sprintf(format,var1,var2,...)`
            * 格式化字符串
            * 例如: `echo | awk '{var=sprintf("%s = %lf","PI",3.1415926);print var}'` 输出 `PI = 3.141593`
        * `tolower(str)` `toupper(str)`
            * 大小写转换
            * 例如: `echo aXbXc | awk '{print tolower($0) " | " toupper($0)}'` 输出 `axbxc | AXBXC`
        * `strtonum(str)`
            * 检查 `str` 并返回其数值，`0` 开头是八进制数，`0x` `0X` 开头是八进制数
    * [算术函数](https://www.gnu.org/software/gawk/manual/html_node/Numeric-Functions.html)
        * `int(x)`              : 取整，也可以转化 `"strnum"` 型的字符串
        * `srand([x])`          : 将生成随机数的种子设置为值 x，x被省略则当前日期和时间用于种子
        * `rand()`              : 随机数，返回0到1之间的随机数，例如: `echo | awk '{srand();print rand()}'`
        * `sin(x)`              : 正弦
        * `cos(x)`              : 余弦
        * `atan2(y, x)`         : 反正切
        * `sqrt(x)`             : 平方根
        * `log(x)`              : 对数
        * `exp(x)`              : e指数 `e ^ x`
    * [位函数](https://www.gnu.org/software/gawk/manual/html_node/Bitwise-Functions.html#Bitwise-Functions)
        * `lshift(val,count)`   : 左移
        * `rshift(val,count)`   : 右移
        * `compl(val)`          : 补码
        * `and(v1,v2[,…])`      : 位与
        * `or(v1,v2[,…])`       : 位或
        * `xor(v1,v2[,…])`      : 位异或
    * [类型函数](https://www.gnu.org/software/gawk/manual/html_node/Type-Functions.html#Type-Functions)
        * `isarray(x)`          : 是数组
        * `typeof(x)`           : 返回类型字符串 `"number"` `"strnum"` `"string"` `"array"` `"regexp"` `"unassigned"` `"untyped"`
    * [I/O 函数](https://www.gnu.org/software/gawk/manual/html_node/I_002fO-Functions.html#I_002fO-Functions)
        * `close(filename[,how])`       : 关闭文件或管道
        * `fflush([filename])`          : 刷新缓冲
    * [时间函数](https://www.gnu.org/software/gawk/manual/html_node/Time-Functions.html#Time-Functions)
        * `systime()`                   : 返回 UTC 时间戳
        * `mktime(datespec[,utc-flag])` : 字符串转换为时间戳，`utc-flag` 为时区
        * `strftime([format[,timestamp[,utc-flag]]])`: 时间戳格式化为字符串
    * 特殊函数
        * `system(command)`
            * 调用子 shell
            * 例如: `awk 'BEGIN{var=system("ls -al");print var}'`
<br>

* `[expression |] getline [var]` or `getline [var] [< file]` : 设置变量
    * 把管道 `expression` 输出或文件 `file` 内容的下一个记录赋值给变量 `var`
    * 不指定管道和不指定文件时，读取的是当前输入文件
    * 不指定变量时，则当前记录 `$0` 记录变量设置为该记录的值，还将设置 `NF`、`NR` 和 `FNR` 特殊变量
    * 例如: `awk 'BEGIN{while ("cat /etc/passwd"|getline) {print $0}; close("/etc/passwd")}'`
    * 例如: `awk 'BEGIN{while (getline < "/etc/passwd") {print $0}; close("/etc/passwd")}'`
<br>

* awk 脚本
    * 使用 `awk -f awk_script [file1] [file2] ...` 执行 awk_script 脚本文件
    * 使用 `#` 作为注释
    * 行尾不需要使用分号，一行多条命令可以使用分号分隔
    * 可以在 `BEGIN` 前自定义函数 `function fname(param1,param2) { commands }`
    * 支持普通数组和关联数组，对数组名 `for-in` 遍历的是数组的索引
<br>

* 简单例子
    * 打印例子
        * `echo | awk '{var1="v1"; var2="v2"; var3="v3"; print var1,var2,var3}'` : 输出 `v1 v2 v3`
        * `echo | awk 'BEGIN{OFS="_"} {var1="v1"; var2="v2"; var3="v3"; print var1,var2,var3}'` : 输出 `v1_v2_v3`
        * `echo | awk '{var1="v1"; var2="v2"; var3="v3"; print var1 "-" var2 "-" var3}'` : 输出 `v1-v2-v3`
    * 打印匹配和非匹配行
        * `awk 'NR < 3'` : 打印行号小于3的行，即第1行和第2行
        * `awk '!/linux/'` : 打印不包含 linux 的行
    * 删除某个字段
        * `echo "a.o: a.c a.h b.h" | awk '{$2="\b";print $0}'` : 输出 `a.o: a.h b.h`，即删除了第2个字段
    * 指定分隔符
        * `cat /etc/passwd | awk -F ':' '{print $1"\t"$7}'` : 输出账户名和对应的 shell，以制表符分隔
    * 传递外部变量
        * `var1="Variable1" ; var2="Variable2"; echo | awk '{print v1,v2}' v1=$var1 v2=$var2` : 输出 `Variable1 Variable2`
    * 复杂用法
        * `echo -e "1\n 2\n 3\n 4" | awk 'BEGIN{num=0;} {sum+=$1; print $1" +"} END{print "="; print sum}' | xargs echo | sed 's/+ =/=/g'` : 输出 `1 + 2 + 3 + 4 = 10`
        * `ls -l | awk 'BEGIN{size=0;} {size=size+$5;} END{print "Total size is",size/1024,"KB"}'` : 统计当前文件夹所有文件的总大小
<br>

* 例子 words.sh: 统计文件中单词出现的次数
    * 用法: `./words.sh [filename] [sortop]`
        * filename              : 要统计的文件
        * sortop                : 排序方法: 0 单词排序，1 出现次数由多到少排序，2 出现次数由少到多排序

```sh
#!/bin/bash

if [ $# -ne 1 ] && [ $# -ne 2 ] ; then
	echo "Usage: $0 filename"
	echo "       $0 filename sort_option"
	exit -1
fi

filename=$1
egrep -o '\b\w+\b' $filename | \
	awk -v opt=$2 '
		function cmp_num(i1, v1, i2, v2)
		{
			return (v1 - v2)
		}

		function rcmp_num(i1, v1, i2, v2)
		{
			return (v2 - v1)
		}

		{
			count[$0]++
		}

		END {
			if (opt == 1) {
				asorti(count,dst,"rcmp_num")
			} else if (opt == 2) {
				asorti(count,dst,"cmp_num")
			} else {
				asorti(count,dst)
			};

			printf("%-20s%s\n","Word","Count");
			for (i in dst) {
				printf("%-20s%d\n",dst[i],count[dst[i]])
			}
		}
	'
```

### 其它处理

* `xargs`                       : 定界符转换
    * 功能
        * xargs 默认使用空白字符分割输入并执行 `/bin/echo`
        * xargs 命令把从 stdin 接收到的数据重新格式化(默认会把换行符转换为空格)，再将其作为参数提供给其他命令
        * xargs 命令应该紧跟在管道操作符之后，把标准输入转换为命令行参数来执行其他命令
        * 有些命令只能以命令行参数的形式接受数据，例如: `find -name *.o | xargs rm -f`
    * 命令参数
        * `-n num`              : 表示 num 个元素之后另起一行
        * `-d separator`        : separator 是单个字符，表示这个字符作为定界符，例如: `echo "AXBXCX" | xargs -d X`
        * `-i`                  : 表示在 `{}` 表示的指定位置替换参数，否则参数位置是末尾
<br>

* `tr set1 set2`                : 字符映射
    * 功能
        * 将来自 stdin 的输入字符从 set1 映射到 set2，然后将输出写入 stdout
        * set1 和 set2 是字符类或字符集
            * 如果 set1 比 set2 大，那么 set2 会不断复制其最后一个字符,直到长度与 set1 相同
            * 如果 set1 比 set2 小，那么 set2 中超出 set1 长度的那部分字符全部被忽略
    * 例子
        * 例如: `cat a.txt | tr 'A-Z' 'a-z' > a.txt` or `tr '[:upper:]' '[:lower:]'` 将输入字符由大写转换成小写
        * 例如: `cat a.txt | tr '\t' '    ' > a.txt` 将制表符转化为四个空格
        * 例如: `cat test.txt | tr 'a-zA-Z' 'n-za-mN-ZA-M' > encryption.txt; cat encryption.txt | tr 'n-za-mN-ZA-M' 'a-zA-Z' > decryption.txt`  ROT13 加解密
* `tr [options] set`            : 字符处理
    * 命令参数
        * `-d`                  : 后面接要删除的字符集合
        * `-c`                  : 后面接要保留的字符集合
        * `-s`                  : 后面接要压缩的字符集合
    * 例子
        * 例如: `echo "Hello 123 world   456" | tr -d '0-9' | tr -s ' '` 删除数字压缩空格
        * 例如: `cat file | tr -c '0-9'` 获取文件中所有数字
* `col [options]`               : 字符转换
    * 命令参数
        * `-x`                  : 将 tab 键转换成对等的空格键
        * `-b`                  : 在文字内有反斜杠时，仅保留反斜杠接的那个字符
<br>

* `cut [options] [filename]`    : 切割文本
    * 功能
        * 按列切分文件，在 cut 的术语中，每列被称为一个字段
    * 命令参数
        * 提取参考
            * `-c filed`        : 提取特定范围的字符
            * `-b filed`        : 提取特定范围的字节，这些字节位置将忽略多字节字符边界，除非也指定了 `-n` 标志
            * `-f filed`        : 提取特定范围的字段
            * `-d separator`    : 指定字段的分隔符，默认的字段分隔符为 **Tab**
        * 提取范围
            * `N1,N2,N3...`     : 提取第N1,N2,N3...个字符、字节或字段，例如: `cut -f 2,3 filename` 表示提取第2列和第3列
            * `N-`              : 从第N个(含)字符、字节或字段到行尾，序号从1开始
            * `N-M `            : 从第N个(含)字符、字节或字段到第M个(含)字符、字节或字段
            * `-M`              : 从第1个(含)字符、字节或字段到第M个(含)字符、字节或字段
        * `--complement`        : 对提取的字段进行补集运算
        * `--output-delimiter`  : 后面接新的分割字符，输出使用新的分割字符
<br>

* `sort [options] [filename]`   : 排序
    * 功能
        * 以文件行为单位进行排序，如果文件已经排序，sort 会返回为0的退出码，否则返回非0
    * 命令参数
        * `-r`                  : 逆序
        * `-n`                  : 按数字顺序排序
        * `-d`                  : 以字典序进行排序
        * `-t separator`        : 指定排序时所用的栏位分隔字符，默认情况下，键就是文本文件中的列，列与列之间用空格分隔
        * `-k num`              : 按第 num 列参数的值进行排序
        * `-m`                  : 排序合并文件
        * `-b`                  : 忽略文件中的前导空白行
<br>

* `uniq [options]`              : 消除相邻的重复行，常和 `sort` 连用
    * 命令参数
        * `-u`                  : 只显示唯一的行
        * `-d`                  : 找出重复的行
        * `-c`                  : 统计各行出现的次数
        * `-s num`              : 指定可以跳过前 num 个字符
        * `-w num`              : 指定用于比较的最大字符数
<br>

* `comm [options] file1 file2`  : 求集合，常和 `sort` 连用
    * 功能
        * 两个文件当中行求集合，输出制表符分隔的3列，第1列放置 file1 独有的行， 第2列放置 file2 独有的行，第3列放置共有的行
        * 命令参数可用 `-1` 删除 file1 独有的行，`-2` 删除 file2 独有的行， `-3` 删除 file1 共有的行
<br>

* `join [options] file1 file2`  : 联合，常和 `sort` 连用
    * 功能
        * 两个文件当中，有 "相同数据" 的那一行，才将他加在一起
        * join 默认以空格符分隔数据并且比对第1个字段的数据，如果两个文件相同，则将两笔数据联成一行，且第一个字段放在第一个
    * 命令参数
        * `-t separator`        : 指定栏位分隔字符
        * `-i`                  : 忽略大小写的差异
        * `-1 num`              : 代表第1个文件要用哪个字段来分析的意思
        * `-2 num`              : 代表第2个文件要用哪个字段来分析的意思
<br>

* `paste [options] file1 file2` : 拼接
    * 功能
        * 将两行贴在一起，且中间以 TAB 键隔开
    * 命令参数
        * `-d separator`        : 后面可以接分隔字符，默认是以 TAB 来分隔
        * `-`                   : 如果 file 部分写成 `-` ，表示来自 stdin 的数据的意思
<br>

* `wc`                          : 统计
    * 功能
        * 当不使用任何选项执行 wc 时，它会分别打印出文件的行数、单词数和字符数
    * 命令参数
        * `-l`                  : 统计行数
        * `-w`                  : 统计单词数
        * `-c`                  : 统计字符数
        * `-L`                  : 打印出文件中最长一行的长度，例如: `wc -L file`

## 目录和文件

### 查看文件

* `cat`
    * 功能
        * `cat file `: 显示全部文件内容
        * `cat file1 file2 file3 > file` : 拼接文件
        * `echo 'Text through stdin' | cat - file1 > file` : 拼接输入和文件，减号 `-` 被作为 stdin 文本的文件名
        * 导入多行到文件
            * `EOF` 是标识符，也可以使用其它任意字符串作为标识符，导入的文件内容直到某行字符串等于标志符结束
            * 标识符不加单引号，文件内容中的变量会替换成它的值; 标识符加单引号，文件内容原样导入
            * 保存文件前 `>` 表示清空文件再写，`>>` 表示追加到文件
            ```sh
            cat <<EOF> file
            ...
            EOF

            cat <<EOF>> file
            ...
            EOF

            cat <<'EOF'> file
            ...
            EOF

            cat <<'EOF'>> file
            ...
            EOF
            ```
    * 命令参数
        * `-s`                  : 压缩空行，连续空行合并为一行
        * `-b`                  : 列出行号，空白行不列出
        * `-n`                  : 列出行号，空白行也列出
        * `-A`                  : 相当于 `-vET`
        * `-v`                  : 列出特殊字符
        * `-E`                  : 显示结尾断行字符 `$`
        * `-T`                  : 制表符以 `^I` 显示
<br>

* `tac`
    * 功能
        * 从最后一行开始反向显示全部文件内容
* `nl`
    * 功能
        * 从第一行开始显示全部文件内容(非空行会加上行号)
* `od`
    * 功能
        * 以二进位的方式读取文件内容
<br>

* `more` / `less`
    * 功能
        * 一页一页的显示文件内容，`more` 只能向后翻页，`less` 可以向前向后翻页
        * `[Space]` 向下翻一页; `[Enter]` 向下翻一行; `b` 或 `[Ctrl]+b` 往回翻(不适用于管道文件); `q` 离开
        * `/string` 向下搜这个字符串; `?string` 向上搜这个字符串; `n` 继续搜索; `N` 反向继续搜索
* `head`
    * 功能
        * 只看头几行
    * 命令参数
        * `-n num`              : 列出前面 num 行，数字为负数为后面 num 行不列出
* `tail`
    * 功能
        * 只看尾几行
    * 命令参数
        * `-n num`              : 列出后面 num 行，数字为负数为前面 num 行不列出
        * `-f`                  : 持续监测文件，例如: `tail -f /var/log/syslog` 等效 `dmesg -w`

### 操作文件

* `pwd`                         : 显示当前目录
* `ls [options] [filename]`     : 文件清单
    * 命令参数
        * `-l`                  : 详细信息
        * `-a`                  : 隐藏文件也列出，包括 `.` 和 `..`
        * `-A`                  : 隐藏文件也列出，不包括 `.` 和 `..`
        * `-d`                  : 不列出目录内容
        * `-R`                  : 递归式操作
        * `-h`                  : 将文件容量以 GB MB KB 等列出
        * `-t`                  : 按时间排序，新的在前
     * 例如: `ls -d */` or `ls -F | grep "/$"` or `ls -l | grep "^d"` or `find . -maxdepth 1  -type d -print` 列出当前目录下的目录
* `cd [dirname]`                : 切换目录
    * 功能
        * `/` 根目录 `.` 当前目录 `..` 上一层目录 `-` 前一工作目录 `~` 当前用户家目录 `~lengjing` 用户 lengjing 家目录
        * `cd /xxx/xxx/...` 进绝对路径目录 ; `cd ./xxx/xxx/...` 进相对路径目录
* `mkdir [options] [dirname]`   : 创建目录
    * 命令参数
        * `-m n1n2n3`           : 设权限
        * `-p`                  : 上层目录没有也会递归创建，文件存在也不报错
* `rmdir [options] [dirname]`   : 删除空目录，目录有文件要用 `rm -r`
    * 命令参数
        * `-p`                  : 连上一层空目录也删除，一直到不是空目录停止

* `stat [filename]`             : 显示文件信息
* `file [filename]`             : 查看文件类型
* `touch [filename]`            : 新建空文件
    * 说明
        * 如果文件已经存在，那么 touch 命令会将与该文件相关的所有时间戳都更改为当前时间
            * `touch -a` 只更改文件访问时间，`touch -m` 只更改文件修改时间。
* `mktemp`                      : 生成一个临时文件并返回其文件名
    * 说明
        * 如果提供了定制模板(至少3个 `X`)，`X` 会被随机的字符(字母或数字)替换
    * 命令参数
        * `-d`                  : 生成一个临时目录并返回其文件名
        * `-u`                  : 生成文件名，不创建实际的文件或目录
<br>

* `cp [options] [srcs] [dst]`   : 复制文件，srcs 可以是多个项目
    * 命令参数
        * `-r`                  : 递归复制
        * `-f`                  : dst 无法打开时，删除 dst 再试复制
        * `-d`                  : 符号链接指向的文件不存在时也可以复制
        * `-p`                  : 连同属性也复制(备份常用)，包含 `-d` 作用
        * `-i`                  : 询问是否覆盖
        * `-a`                  : 保留属性，递归的复制
        * `-s`                  : 创建符号链接，也可以用  `ln -s` 创建符号链接
* `mv [options] [srcs] [dst]`   : 移动文件，可以用来重命名，srcs 可以是多个项目
    * 命令参数
        * `-f`                  : 同名档案直接覆盖
        * `-p`                  : 保持权限
        * `-i`                  : 询问是否覆盖
        * `-u`                  : 比已有文件新则覆盖(update)
* `rm [options] [filename]`     : 删除文件，命令删除是没有回收站的
    * 命令参数
        * `-r`                  : 递归地删除(常用于删除有文件的目录)
        * `-f`                  : 忽略文件不存在时的警告信息
        * `-i`                  : 询问是否删除
* `ln [options] [src] [dst]`    : 给文件或目录创建链接
    * 说明
        * 不指定 dst 时 dst 的名字取 `basename $src`
        * Hard Link (实体链接, 硬链接或实际链接)，多个档名连结到同一个 inode，hard link 是有限制的: 不能跨 Filesystem，不能 link 目录
        * Symbolic Link (符号链接，软链接或快捷方式)，创建一个独立的文件，而这个文件会让数据的读取指向他 link 的那个文件的档名
    * 命令参数
        * `-f`                  : 如果目标文件存在时，就主动的将目标文件直接移除后再创建，文件夹还要加上 `-T`
        * `-s`                  : 添加符号链接，如果不加任何参数就进行硬链接

### 压缩打包

* `gzip/gunzip/zcat` `bzip2/bunzip2/bzcat` `xz/unxz/xzcat`
    * 功能
        * gzip 默认压缩 / gunzip 默认解压 / zcat 默认查看
        * bzip2 默认压缩 / bunzip2 默认解压 / bzcat 默认查看
        * xz 默认压缩 / unxz 默认解压 / xzcat 默认查看
        * 通过选项可以改变默认行为: `-z` 强制压缩 / `-d` 强制解压 / `-t` 测试压缩文件 / `-l` 列出压缩信息
        * 注: gzip 族不支持 `-z` 选项
    * 命令参数
        * `-1` ...`-9`          : 设置压缩等级，默认是 -6，压缩最高是 -9
        * `-k`                  : 保留输入文件(压缩解压默认会删除原文件)
        * `-f`                  : 强制覆盖输出文件
        * `-h`                  : 帮助信息
        * `-v`                  : 显示进度等信息
        * `-T <num>`            : 多线程支持(仅 xz 族命令)
<br>

* `tar`
    ```
    tar -[Jjz] -c -f [tarname] -C [dir] [objects]
    tar        -x -f [tarname] -C [dir]
    tar        -t -f [tarname]
    ```
    * 使用说明
        * 可以将选项写在一起 (UNIX-style)，例如: `tar -Jcvf test.tar.xz test`
        * 可以省略横线 `-`(Traditional Style)，例如: `tar Jcvf test.tar.xz test`
    * 压缩类型选项
        * `-J`                  : xz   打包压缩，此时 tarname 需要命名为 `*.tar.xz`
        * `-j`                  : bz2  打包压缩，此时 tarname 需要命名为 `*.tar.bz2`
        * `-z`                  : gzip 打包压缩，此时 tarname 需要命名为 `*.tar.gz`
    * 处理方式选项
        * `-c`                  : 压缩
        * `-x`                  : 解压
        * `-t`                  : 查看
    * 其它选项
        * `-f [tarname]`        : 打包文件名
        * `-C [dir]`            : 进入指定目录打包(否则包含路径)或解压到指定目录(否则当前目录)
        * `-P`                  : 保留绝对路径
        * `-v`                  : 显示处理信息
        * `-p`                  : 保留属性
        * `-P`                  : 保留绝对路径

### 分割文件

* `split [options] [filename] [prefix]`  : 分割文件
    * 命令参数
        * `-x`                  : 以数字命名后缀而不是字母命名
        * `-a num`              : 指定分割的后缀的位数 `num`，默认2位，`prefix` 为前缀名称
        * `-b value`            : 多大一个文件，单位有: `c` 1 byte; `w` 2 bytes; `b` 512 bytes; `k` 1024 bytes; `M` 1024k bytes; `G` 1024M bytes
        * `-l num`              : 多少行一个文件
        * `-n CHUNKS`           : 分割成指定个文件
            * `N`               : 均分为 N 个文件
            * `l/N`             : 约均分为 N 个文件，但分割位置不会拆分行
            * `K/N`             : 打印均分为 N 份时的第 K 份内容到屏幕
            * `l/K/N`           : 打印约均分为 N 份时的第 K 份内容到屏幕
            * `r/N`             : 类似 `l/N`，但是使用 `round robin distribution`
            * `r/K/N`           : 类似 `l/K/N`，但是使用 `round robin distribution`

* `csplit [options] [filename] [pattern...]`  : 匹配分割文件
    * 命令参数
        * `-b suffix`           : 设置后缀格式，可用格式化输出符，例如 `%04d.txt`
        * `-f prefix`           : 设置前缀字符串，默认是 `xx`
        * `-n num`              : 指定分割的后缀的位数 `num`，默认2位
        * `-s`                  : 静默模式，不显示输出文件的尺寸计数
    * 匹配模式 pattern
        * `N`                   : 复制至指定行(不含)一个文件，其它又一个文件
        * `/regexp/offset`      : 复制至匹配行(不含)一个文件，其它又一个文件，`offset` 可选，可用正 `+N` 负 `-N` 整数
        * `%regexp%offset`      : 跳过直至匹配行(不含)丢弃内容，其它又一个文件
        * `{N}`                 : 将之前指定的模式重复 N 次
        * `{*}`                 : 将之前指定的模式重复尽可能多的次数

### 档案属性

* 档案属性: `drwxr-xr-x 34 lengjing lengjing  4096 Aug 20 10:07 lengjing/`
    * 第一个字符表示 `档案类型`
        * `d` 目录 `-` 文件 `l` 链接
        * `b` 区块设备(硬盘等) `c` 字符设备(键盘鼠标等) `s` 数据接口文件(sockets) `p` 数据输送文件(FIFO)
    * 随后每三个字符表示 `所有者权限` `所属群组权限` `其他用户权限`
        * `r` 可读(read) `w` 可写(write) `x` 可执行(execute) `-` 无权限
        * 权限对文件的重要性
            * r(read): 可读取此一文件的实际内容，如读取文本文件的文字内容等
            * w(write): 可以编辑、新增或者是修改该文件的内容(但不含删除该文件)
            * x(execute): 该文件具有可以被系统执行的权限
        * 权限对目录的重要性
            * r(read contents in directory): 具有读取目录结构列表的权限(ls指令可用)
            * w(modify contents of directory): 具有改变该目录结构列表的权限
                * 建立新的文件与目录
                * 删除已经存在的文件与目录(不管对文件权限如何)
                * 将已存在的文件或目录进行更名
                * 搬移该目录内的文件、目录位置
            * x(access directory): 进入该目录的权限(cd指令可用)
            * 开放目录给任何人浏览时，应该至少也要给予 **r x** 的权限
    * 然后是 `连接数`，表示有多少档名连结到此节点(i-node)(目录下文件数，包括 `.` 和 `..`)
    * 接着是 `所有者` `所属群组` `容量大小`(默认单位为 bytes) `最后修改时间`
    * 最后是 `档案名称`
        * 使用 `Ext4` / `Ext3` 文件系统，单一档名可达 255 字符，完整文件名(包含路径)可达 4096 个字符
        * 点号 `.` 开头的档名，表示这个档案为隐藏档案
<br>

* 特殊权限
    * `4` 为 `SUID` (Set UID)
        * 档案所有者的可执行权限位显示为 `s` 时为 `SUID` 权限
        * SUID 目前只针对文件有效，使用者运行此程序时，在运行过程中 (run-time) 用户会暂时具有程序拥有者 (owner) 的权限
        * SUID 只能应用在 Linux ELF 格式的二进制文件上，你不能对脚本设置 SUID
    * `2` 为 SGID` (Set GID)
        * 档案所属群组的可执行权限位显示为 `s` 时为 `SGID` 权限
        * 对文件来说，使用者运行此程序时(需具备 x 的权限)，在运行过程中 (run-time) 用户会暂时具有程序所属群组 (owner) 的权限
        * 对目录来说，使用者在此目录下创建的新档案时(需具备 r x 的权限)，新档案的群组与此目录的群组相同
    * `1` 为 `SBIT` (Sticky Bit)
        * 档案其他用户的可执行权限位显示为 `t` 或 `T` 时为 `SBIT` 权限(粘滞位)，典型例子就是 `/tmp`
        * SBIT 目前只针对目录有效，使用者在此目录下创建的新档案时(需具备 w x 的权限)，仅有自己与 root 才有权力删除该文件
    ```
    $ ls -ld /tmp /usr/bin/passwd
    drwxrwxrwt 13 root root  4096 8月   9 11:27 /tmp
    -rwsr-xr-x  1 root root 59640 3月  23  2019 /usr/bin/passwd
    ```
<br>

* 修改属性
    * `chmod`                               : 更改权限
        * 对符号链接来说，一般不考虑它的权限，而考虑它引用的文件的权限。
        * 例如: `chmod u+x configure` 或 `chmod 744 configure`  给 configure 文件加上可执行权限
        * 例如: `chmod a+t dir` 设置 SBIT
        * 例如: `chmod +s binname` 设置 SUID
        * 例如: `chattr +i file` `chattr -i file` 设置文件不可修改和取消设置
        ```
        chmod [usertype sign type] [filename]  或 chmod [n1n2n3] [filename]
               u用户  +添加  r可读                    r=4 w=2 x=1
               g同组  -取消  w可写
               o其他  =赋予  x可执行
               a所有(可省略)
        ```
    * `chown [owner] [filename]`            : 修改所有者
    * `chown [owner:grouper] [filename]`    : 同时修改所有者和组
    * `chgrp [grouper] [filename]`          : 修改所有组

注: 这四个 `chxxx` 命令都可以用 `-R` 选项进行递归式操作

### 文件系统

* 文件系统层次
    * `superblock`      : 记录此 filesystem 的整体信息
        * block 与 inode 的总量
        * 未使用与已使用的 inode / block 数量
        * block 与 inode 的大小 (block 为 1, 2, 4K， inode 为 128 bytes)
        * filesystem 的挂载时间、最近一次写入数据的时间、最近一次检验磁盘 (fsck) 的时间等文件系统的相关信息
        * 一个 valid bit 数值，若此文件系统已被挂载，则 valid bit 为 0 ，若未被挂载，则 valid bit 为 1 。
        * 一般来说 superblock 的大小为 1024bytes
    * `inode`           : 记录文件的属性
        * 该文件的数据所在的 block 号码
        * 该文件的存取模式 (read/write/excute)
        * 该文件的拥有者与群组 (owner/group)
        * 该文件的容量
        * 最近一次的读取时间 (atime)
        * 最近创建或状态改变的时间 (ctime)
        * 最近修改的时间 (mtime)
        * 定义文件特性的标志 (flag)，如 SetUID ...
        * 该文件真正内容的指向 (pointer)
        * inode 属性说明:
            * 每个 inode 大小均固定为 128 bytes
            * 每笔 block 号码的记录会花去 4bytes
            * inode 记录 block 号码的区域定义为12个直接，1个间接, 1个双间接与1个三间接记录区。总额: 将直接、间接、双间接、三间接加总
            * 每个文件都仅会占用一个 inode，因此文件系统能够创建的文件数量与 inode 的数量有关
            * 系统读取文件时需要先找到 inode，并分析 inode 所记录的权限与用户是否符合，若符合才能够开始实际读取 block 的内容
            * **文件名只与目录有关，但是文件内容则与 inode 有关**
    * `block`           : 实际记录文件的内容
        * 若文件太大时，会占用多个block，每个 block 内最多只能够放置一个文件的数据

注: 可以将一个分割槽格式化为多个文件系统(LVM)，也能够将多个分割槽合成一个文件系统(RAID)，linux 采用索引式文件系统，基本上不太需要常常进行碎片整理
<br>

* 文件系统操作
    * `df [options] [filename or dirname]`
        * 功能
            * 列出文件系统的信息，不加名字时列出所有文件系统
        * 命令参数
            * `-a`              : 列出所有的文件系统，包括系统特有的 `/proc` 等文件系统
            * `-h`              : 以人们较易阅读的 GBytes, MBytes, KBytes 等格式自行显示容量
            * `-k`              : 以 KBytes 列出容量显示
            * `-m`              : 以 MBytes 列出容量显示
            * `-H`              : 以 M=1000K 取代 M=1024K 的进位方式
            * `-T`              : 连同文件系统类型也列出
            * `-i`              : 不用容量，而以 inode 的数量来显示

    * `du [options] [filename or dirname]`
        * 功能
            * 统计文件或文件夹的磁盘使用量，不加名字时默认是当前文件系统
        * 命令参数
            * `-a`              : 列出所有的文件与目录容量，默认仅统计当前目录底下的文件量而已
            * `-h`              : 以人们较易读的容量格式 (G/M) 显示
            * `-k`              : 以 KBytes 列出容量显示
            * `-m`              : 以 MBytes 列出容量显示
            * `-s`              : 列出总量而已，而不列出每个各别的目录占用容量
            * `-S`              : 不包括子目录下的总计
    * `mount [-t fstype] [-L Label ] [-o extra_options] [-n] [devname] [mountdir]`
        * 功能
            * 磁盘挂载
            * 例如: 重新挂载根目录 `sudo mount -o remount,rw,auto /`
            * 例如: 手动挂载 ntfs: `sudo mount -t ntfs /dev/sda2 /home/ntfspd`
            * 例如: 手动挂载 nfs: `sudo mount -t nfs <ip_addr>:<path> <mount_path> -o nolock -o tcp -o rsize=32768,wsize=32768`
            * 例如: 手动挂载 smb: `sudo mount -t cifs //<ip_addr>/<path> <mount_path> -o domain=<str1>,username=<str2>,password=<str3>,vers=1.0,uid=1000,gid=1000`
            * 进行挂载前，你最好先确定几件事:
                1. 单一文件系统不应该被重复挂载在不同的挂载点(目录)中
                2. 单一目录不应该重复挂载多个文件系统
                3. 要作为挂载点的目录，理论上应该存在且是空目录
    * `umount [options] [devname or mountdir]`
        * 功能
            * 磁盘卸载
        * 命令参数
            * `-f`              : 强制卸载，可用在类似网络文件系统 (NFS) 无法读取到的情况下
            * `-n`              : 不升级 /etc/mtab 情况下卸除
    * `fdisk [options] [devname]`
        * 功能
            * 磁盘分区相关操作，需要 root 权限
            * fdisk 没有办法处理大于 2TB 以上的磁盘分区槽，此时得使用 `parted`，例如: 查看你的磁盘的分区类型 `sudo parted /dev/sda print`
        * 命令参数
            * `-l`              : 列出指定分区信息，若仅有 `fdisk -l` 时，则全部 partition 均列出来
    * `dumpe2fs [options] [devname]`
        * 功能
            * 列出区段与 superblock 的信息，需要 root 权限
            * devname 是文件系统设备，例如: `/dev/sda1`
        * 命令参数
            * `-h`              : 仅列出 superblock 的数据，不会列出其他的区段内容
            * `-b`              : 列出保留为坏轨的部分
    * `mkfs [-t fstype] [options] [devname]`
        * 功能
            * 磁盘格式化
        * 命令参数
            * `-b`              : 可以配置每个 block 的大小，目前支持 1024, 2048, 4096 bytes 三种
            * `-i`              : 多少容量给予1个 inode
            * `-c`              : 检查磁盘错误，仅下达一次 `-c` 时，会进行快速读取测试；如果下达两次 `-c` `-c` 的话，会测试读写(read-write)，会很慢
    * `fsck [-t fstype] [options] [devname]`
        * 功能
            * 磁盘检验，运行 fsck 时， 被检查的 partition 需要在卸载的状态
        * 命令参数
            * `-A`              : 依据 /etc/fstab 的内容，将需要的装置扫瞄一次
            * `-a` or `-y`      : 自动修复检查到的有问题的扇区，不用一直按 y
            * `-f`              : 强制细部检查
            * `-D`              : 针对文件系统下的目录进行优化配置
    * `dd if=src of=dst bs=size count=num`
        * 功能
            * 读取、转换并输出数据，源和目标可以是是文件或设备
            * `if=`             : 源，两个常用的源: `/dev/zero` 返回全0，`/dev/random` 返回随机数
            * `of=`             : 目标
            * `bs=`             : 每次复制的大小，单位有: `c` 1 byte; `w` 2 bytes; `b` 512 bytes; `k` 1024 bytes; `M` 1024k bytes; `G` 1024M bytes
            * `count=`          : 复制的次数
<br>

* 例子: U盘的某些命令
    * 格式化
    ```sh
    sudo fdisk -l               # 查看挂载
    sudo umount /dev/sdb1       # 必须先卸载该分区
    sudo mkfs.vfat -F 32 /dev/sdb1 # -F 参数必须大写，参数有 12，16 和 32，分别对应FATxx
    ```
    * 检测U盘坏块
    ```sh
    badblocks -b 4096 -sv /dev/sdb
    ```
    * 只读修复
    ```sh
    ll /dev/disk/by-id/         # 查看对应的硬盘
    sudo fsck -a /dev/disk/by-id/devname # fsck命令进行硬盘修复
    ```
