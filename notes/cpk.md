# CPK: A Philosophical Practice of Returning to the Essence of Software Packaging and Distribution

> **In Linux’s complex distribution ecosystem, have we forgotten the pure form of software? As containers, sandboxes, and daemons become the norm, CPK—guided by a philosophy of simplicity, transparency, and freedom—launches a thought-provoking technical practice.**

---

## Introduction: The Essence of Software Lost in “Progress”

The Linux world has never lacked innovation, especially in application distribution. We’ve moved from `deb`/`rpm` to Snap, Flatpak, and AppImage—each evolution aiming to solve dependency, isolation, and cross-platform compatibility issues. Yet, as these solutions stack abstraction upon abstraction, we’ve quietly lost something: **system simplicity, complete knowability of software behavior, and direct control without intermediaries**.

It feels like we’ve replaced one form of complexity with another. Is there a way to return to software’s most authentic state—a **complete, self-contained digital artifact that can run anywhere**?

The open-source build system CBuild-ng offers an answer: **CPK (CBuild/Compressed Package)**. More than a technical format, it’s a philosophical practice rooted in **Simplicity, Sovereignty, and Mobility**.

---

## 1. Simplicity — Stripping Away All Unnecessary Complexity

CPK’s design philosophy is grounded in the classic Unix credo: KISS (Keep It Simple, Stupid). True universality, it holds, should be built on the most solid, ubiquitous foundations—not on yet another complex middleware layer.

**What is CPK?**

- A **self-extracting shell script** followed by a standard **tar archive**.
- **Its only dependencies** are Python, `sh`, `file`, `tar`, `gcc`, `readelf`, and `patchelf`. These tools exist on virtually every Linux machine (with `patchelf` needing a one-time static build). No extra frameworks or daemons (like `snapd` or `flatpak`) are required.

This radical minimalism delivers unmatched **transparency**. You can open a CPK in a text editor to inspect its install logic, or extract and audit its contents with `tar`. No black boxes, no hidden magic—everything is knowable, predictable, and auditable. CPK uses the most primitive tools to solve the most modern problems, offering an elegant rejection of over-engineering.

---

## 2. Sovereignty — Returning Full Control

CPK makes a bold statement: it restores **full software sovereignty** to both creators and users.

- **For developers**, CPK enables *delivery certainty*.
  They can choose any modern toolchain (e.g., the latest glibc from AlmaLinux 10), bundle the application with **all dependencies** (down to the C library), and freeze it into a known-good runtime. They can then confidently declare: *“This is my work and everything it needs; it runs perfectly in this environment.”* This ends the age-old “dependency hell” and “works on my machine” problem.

- **For users**, CPK means *complete control and transparency*.
  A `.cpk` file can be installed in the user’s home directory (`~/.cpk/`) without root privileges, leaving no stray files deep in the system. Users can inspect the install script, dissect the package contents, and decide when to run or update. No forced background services, no unsolicited auto-updates—just a trust relationship built on openness and respect.

---

## 3. Mobility — Creating Freely Migrating Digital Lifeforms

CPK’s ultimate vision is to make Linux applications **truly portable digital lifeforms**, able to cross the chasms between distributions.

Its core technique: **it carries not only user-space dependencies but also the lowest-level C library (e.g., glibc) and interpreter (ld.so)**, and rewrites the binary’s interpreter path to form a perfect internal loop. This allows an application built on the latest distro to **fully “revive”** on any older host.

By decoupling applications from their environments, CPK achieves the long-sought Linux ideal of *“build once, run anywhere”*. Applications are freed from system constraints, becoming truly independent, migratable digital entities.

---

## 4. A Horizontal View — CPK’s Unique Position in the Ecosystem

CPK’s philosophy differs sharply from mainstream solutions. It doesn’t aim to replace them all, but instead strikes a unique balance between **radical simplification**, **control**, and **cross-distro deployment**.

| Dimension | **CPK (CBuild-ng)** | **Snap** | **Flatpak** | **AppImage** | **Traditional (deb/rpm)** |
|-----------|--------------------|----------|-------------|--------------|---------------------------|
| **Core Philosophy** | **The app is the package**: a self-contained, portable environment with binary path isolation. | **Sandboxed app container**: security isolation, auto-updates, store-distributed. | **Desktop app sandbox**: portable, sandboxed desktop apps. | **Single-file app**: extreme simplicity—download, chmod, run. | **System integration**: software as part of the OS. |
| **Package Format** | Self-extracting shell script + tar archive; fully transparent. | Read-only SquashFS image; mounted at runtime. | OCI image + metadata; relatively complex. | ISO 9660 filesystem image; mountable. | Custom archive (deb = ar archive with control/data tarballs). |
| **Dependency Handling** | Strong isolation, bundles all libs (glibc, ld.so), modifies interpreter & rpath with `patchelf`. | Strong isolation, bundles deps, fixed runtime. | Strong isolation, shared runtime (e.g., Freedesktop SDK). | Optional isolation; may bundle or use system libs. | No isolation; relies on system libs. |
| **Cross-Distro Support** | ✅ Perfect | ✅ Perfect | ✅ Perfect | ✅ Perfect | ❌ Poor |
| **Installation** | No install or user-space install; no root needed. | Requires `snapd` daemon; root needed. | User/system install; needs `flatpak` framework. | No install; run directly. | System install via package manager; root needed. |
| **Performance Overhead** | Very low (near-native). | Higher (namespaces, AppArmor, SquashFS). | Medium (bubblewrap, OCI runtime). | Low (tmpfs extraction). | Native. |
| **Security** | Relies on host security; no sandbox. | High (strict sandbox, AppArmor/seccomp). | High (bubblewrap sandbox). | Relies on host security; no sandbox. | Relies on system security. |
| **Updates** | Manual by developer. | Automatic via `snapd`. | Auto/manual via `flatpak`. | Manual (download new file). | System-wide via package manager. |
| **Desktop Integration** | Manual (scripts/tools). | Excellent (auto desktop entries). | Excellent. | Good (may need extra tools). | Excellent. |
| **Core Dependencies** | Minimal (common system tools). | Heavy (`snapd` daemon). | Medium (`flatpak` framework). | None. | None (built-in). |

---

**CPK’s Niche:**

1. **For developers and power users**: Transparency (viewable scripts), control (self-managed deps), and minimal dependencies make it ideal for distributing complex toolchains, internal tools, CI/CD artifacts, or fixed-version commercial software.
2. **For embedded and edge computing**: Low overhead and no resident daemons are huge advantages in constrained or highly customized environments, enabling reliable deployment of complex runtimes to any Linux device.
3. **For those who value simplicity and transparency**: CPK rejects “magic.” Built from the most basic components, every step is auditable and debuggable—no sandbox, no forced store—standing in stark contrast to the heavier frameworks of Snap and Flatpak.

---

## 5. Hands-On — Experiencing the Elegance of CPK

### Example: CPK Packaging Integrated with CBuild-ng

With the `make xxx-cpk` command, you can automatically compile the software and generate a `.cpk` package. The line `ELFs copied from system:` clearly shows which binaries were copied from the host system.

```sh
lengjing@lengjing:~/data/cbuild-ng$ source scripts/build.env host generic
lengjing@lengjing:~/data/cbuild-ng$ make loadconfig
lengjing@lengjing:~/data/cbuild-ng$ make tcpdump-cpk
Match patchelf-native Cache.
Build patchelf-native Done.
Match patchelf Cache.
Build patchelf Done.
log path is /home/lengjing/data/cbuild-ng/output/x86_64-host/config/log/2025-09-04--08-15-58.068091488/
[100%]                                                  [  2/  2] tcpdump
----------------------------------------
    libpcap
    tcpdump
----------------------------------------
Generate /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/share/license/index.txt OK.
Generate /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/share/license/index.html OK.
Note: tcpdump.dot tcpdump.svg and tcpdump.png are generated in the /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/share/license folder.
Interpreter path       : /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/syslib/ld-linux-x86-64.so.2
ELFs with interpreter  : [('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/syslib', ['libc-2.31.so', 'libpthread-2.31.so'])]
ELFs with rpath        : [('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/usr/lib', ['libpcap.so.1.10.5']), ('/home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump/syslib', ['libcrypto.so.1.1', 'libc-2.31.so', 'libdl-2.31.so', 'libpthread-2.31.so'])]
ELFs copied from system: ['libcrypto.so.1.1', 'libc.so.6', 'ld-linux-x86-64.so.2']
CPK SUCCESS: /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump
CPK is packed to /home/lengjing/data/cbuild-ng/output/x86_64-host/packages/tcpdump.cpk
```

---

### CPK Packaging Command and Principles

```makefile
%-cpk:
	@$(MAKE) $(MFLAG) CONFIG_PATCHELF_NATIVE=y patchelf-native
	@$(MAKE) $(MFLAG) CONFIG_PATCHELF=y patchelf
	@$(MAKE) $(MFLAG) $(patsubst %-cpk,%-pkg,$@)
	@PATH=$(ENV_NATIVE_ROOT)/objects/patchelf/image/usr/bin:$(PATH) \
		python3 $(ENV_TOOL_DIR)/gen_cpk_package.py -r $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@) \
		-i include:share:etc:srv:com:var:run $(if $(PKG_EOS),-o $(PKG_EOS)) \
		-c $(ENV_BUILD_TOOL)gcc -t $(ENV_BUILD_TOOL)readelf $(if $(CPK_EXTRA_PATH),-e $(CPK_EXTRA_PATH))
	@cp -fp $(ENV_CROSS_ROOT)/objects/patchelf/image/usr/bin/patchelf $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
ifneq ($(PKG_EOS),y)
	@cp -fp $(ENV_TOOL_DIR)/gen_cpk_package.py $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
	@ush=$(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)/update.sh && \
		echo '#!/bin/sh' > $${ush} && \
		echo 'curdir=$$(dirname $$(realpath $$0))' >> $${ush} && \
		echo 'PATH=$$curdir:$$PATH python3 $$curdir/gen_cpk_package.py -r $$curdir -i include:share:etc:srv:com:var:run' >> $${ush} && \
		chmod +x $${ush}
endif
	@bash $(ENV_TOOL_DIR)/gen_cpk_binary.sh pack $(ENV_CROSS_ROOT)/packages/$(patsubst %-cpk,%,$@)
```

This snippet from the top-level Makefile defines the CPK packaging target. It primarily uses the `gen_cpk_package.py` and `gen_cpk_binary.sh` scripts, which can also be run independently to package software outside of CBuild-ng.

- Statically compile `patchelf` (**note:** some distro-provided versions may be problematic—choose an appropriate one).
- Run `gen_cpk_package.py` (use `-h` for help):
  - Analyze dynamically linked executables and libraries in the `-r` specified directory.
  - Use `file` to get file attributes, then `readelf` (via `-t`) to inspect dependencies.
  - Use `gcc` (via `-c`) to locate dependent libraries not in the package dir and copy them into `syslib`.
  - Use `patchelf` to rewrite `rpath` and `interpreter` to point inside the package.
- Run `gen_cpk_binary.sh` to compress the package directory and append it to the script, producing a single-file `.cpk`.

---

### Example: Installing a CPK Package

Below is an example of running a CPK built on AlmaLinux 10 on Ubuntu 20.04. It demonstrates that a tcpdump binary (and all its complex dependencies) compiled against a newer glibc 2.41 can run seamlessly on a system with an older glibc 2.31. Note also the `usr/share/license` directory—`index.html`/`index.txt` list licenses, and the included diagrams visualize dependencies, supporting enterprise compliance.

```sh
lengjing@lengjing:~/Downloads$ ./tcpdump.cpk
Please set the installation directory (/home/lengjing/.cpk/tcpdump):
Delete the original app [/home/lengjing/.cpk/tcpdump] first? (y or n): y
-e Your choice is y
Interpreter path       : /home/lengjing/.cpk/tcpdump/syslib/ld-linux-x86-64.so.2
ELFs with interpreter  : [('/home/lengjing/.cpk/tcpdump/syslib', ['libc.so.6']), ('/home/lengjing/.cpk/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/.cpk/tcpdump/syslib', [])]
ELFs with rpath        : [('/home/lengjing/.cpk/tcpdump/syslib', ['libc.so.6', 'libz.so.1.3.1.zlib-ng', 'libcrypto.so.3.2.4']), ('/home/lengjing/.cpk/tcpdump/usr/bin', ['tcpdump']), ('/home/lengjing/.cpk/tcpdump/usr/lib', ['libpcap.so.1.10.5']), ('/home/lengjing/.cpk/tcpdump/syslib', [])]
ELFs copied from system: []
CPK SUCCESS: /home/lengjing/.cpk/tcpdump
-e Successfully installed to /home/lengjing/.cpk/tcpdump
lengjing@lengjing:~/Downloads$ cd /home/lengjing/.cpk/tcpdump
lengjing@lengjing:~/.cpk/tcpdump$ tree
.
├── gen_cpk_package.py
├── patchelf
├── syslib
│     ├── ld-linux-x86-64.so.2
│     ├── libcrypto.so.3 -> libcrypto.so.3.2.4
│     ├── libcrypto.so.3.2.4
│     ├── libc.so.6
│     ├── libz.so.1 -> libz.so.1.3.1.zlib-ng
│     └── libz.so.1.3.1.zlib-ng
├── update.sh
└── usr
    ├── bin
    │     ├── pcap-config
    │     ├── tcpdump
    │     └── tcpdump.4.99.5 -> tcpdump
    ├── lib
    │     ├── libpcap.so -> libpcap.so.1
    │     ├── libpcap.so.1 -> libpcap.so.1.10.5
    │     └── libpcap.so.1.10.5
    └── share
        └── license
            ├── common
            │     └── MIT-LENGJING
            │         └── LICENSE
            ├── index.html
            ├── index.txt
            ├── libpcap
            │     └── LICENSE
            ├── spdx-licenses.html
            ├── tcpdump
            │     └── LICENSE
            ├── tcpdump.dot
            ├── tcpdump.png
            └── tcpdump.svg

10 directories, 24 files
lengjing@lengjing:~/.cpk/tcpdump$ file usr/bin/tcpdump
usr/bin/tcpdump: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /home/lengjing/.cpk/tcpdump/syslib/ld-linux-x86-64.so.2, BuildID[sha1]=ccfe1b6660bd62cd643fe2746464872074e651ee, for GNU/Linux 3.2.0, not stripped
lengjing@lengjing:~/.cpk/tcpdump$ ./syslib/libc.so.6
GNU C Library (GNU libc) stable release version 2.41.
Copyright (C) 2025 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
Compiled by GNU CC version 15.1.1 20250521 (Red Hat 15.1.1-2).
libc ABIs: UNIQUE IFUNC ABSOLUTE
Minimum supported kernel: 3.2.0
For bug reporting instructions, please see:
<https://www.gnu.org/software/libc/bugs.html>.
lengjing@lengjing:~/.cpk/tcpdump$ /usr/lib/x86_64-linux-gnu/libc.so.6
GNU C Library (Ubuntu GLIBC 2.31-0ubuntu9.18) stable release version 2.31.
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
Compiled by GNU CC version 9.4.0.
libc ABIs: UNIQUE IFUNC ABSOLUTE
For bug reporting instructions, please see:
<https://bugs.launchpad.net/ubuntu/+source/glibc/+bugs>.
lengjing@lengjing:~/.cpk/tcpdump$ ./usr/bin/tcpdump -h
tcpdump version 4.99.5
libpcap version 1.10.5 (with TPACKET_V3)
OpenSSL 3.2.4 11 Feb 2025
64-bit build, 64-bit time_t
Usage: tcpdump [-AbdDefhHIJKlLnNOpqStuUvxX#] [ -B size ] [ -c count ] [--count]
		[ -C file_size ] [ -E algo:secret ] [ -F file ] [ -G seconds ]
		[ -i interface ] [ --immediate-mode ] [ -j tstamptype ]
		[ -M secret ] [ --number ] [ --print ] [ -Q in|out|inout ]
		[ -r file ] [ -s snaplen ] [ -T type ] [ --version ]
		[ -V file ] [ -w file ] [ -W filecount ] [ -y datalinktype ]
		[ --time-stamp-precision precision ] [ --micro ] [ --nano ]
		[ -z postrotate-command ] [ -Z user ] [ expression ]
```

---

## Conclusion: A Choice, An Attitude

In technology, there is no single truth. Snap and Flatpak aim to build secure, controlled ecosystems—an undeniably valuable goal.

CPK, however, is for a different audience: **minimalists, control-seekers, and idealists who want software to remain in its purest form**. It’s a way to express a technical stance—choosing simplicity over complexity, transparency over opacity, and freedom over constraint.

CPK does not seek to replace Snap, Flatpak, or AppImage. They serve different visions: Snap/Flatpak focus on secure, manageable ecosystems; AppImage pursues extreme single-file portability.

**CPK is more than a format—it’s a philosophical practice of returning to software’s essence. With elegant engineering and minimal overhead, it precisely addresses pain points in specific scenarios, embodying the engineering ethos that “simple is beautiful.”**
