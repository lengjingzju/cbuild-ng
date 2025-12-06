# kconfig

This kconfig is from the Linux kernel, retaining only the menuconfig implementation and adding configuration to specify the output locations.

* The additional configurations are as follows:
    * `--configpath`     : Specify the config path, default is '.config'
    * `--autoconfigpath` : Specify the auto config path, default is 'include/config/auto.conf'
    * `--autoheaderpath` : Specify the auto header path, default is 'include/generated/autoconf.h'
    * `--rustccfgpath`   : Specify the rustc config path, default is 'include/generated/rustc_cfg'

By adding configurations, it is possible to support the separation of configuration output and source code.

Users can refer to [inc.conf.mk](https://github.com/lengjingzju/cbuild-ng/blob/main/scripts/core/inc.conf.mk) of cbuild-ng to use the project.

The compile commands are as follows:

```sh
# users should install "flex, bison, libncurses-dev" first.
make O=<output_path> && make O=<output_path> DESTDIR=<install_path> install
```
