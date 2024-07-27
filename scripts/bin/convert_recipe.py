############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

import sys, os, re

class PkgInfo:
    def __init__(self):
        self.package = ""
        self.license = ""
        self.licfile = []
        self.homepage = ""
        self.description = ""
        self.srcuri = ""
        self.method = ""
        self.flags = ""
        self.depends = []
        self.pkgconfig = []
        self.statement = '''############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

'''


    def toupper(self, var):
        return var.replace('.', '__dot__').replace('+', '__plus__').replace('-', '_').upper()


    def tolower(self, var):
        return var.lower().replace('_', '-').replace('__dot__', '.').replace('__plus__', '+')


    def analyze_recipe(self, fname):
        package = os.path.basename(fname)
        self.package = package.split('_' if '_' in package else '.')[0]

        RES                 = {}
        RES['license']      = re.compile(r'LICENSE\s*=\s*"(.*)"')
        RES['licfile']      = re.compile(r'LIC_FILES_CHKSUM\s*=\s*"(.*)')
        RES['homepage']     = re.compile(r'HOMEPAGE\s*=\s*"(.*)"')
        RES['description']  = re.compile(r'DESCRIPTION\s*=\s*"(.*)')
        RES['srcuri']       = re.compile(r'SRC_URI\s*=\s*"(.*)')
        RES['flags']        = re.compile(r'EXTRA_OE(CONF|CMAKE|MESON)[=:+\s].*(?<==)\s*"(.*)')
        RES['depends']      = re.compile(r'R?DEPENDS[=:+\s].*(?<==)\s*"(.*)')
        RES['pkgconfig']    = re.compile(r'PACKAGECONFIG\[([\s\w\-\./]+)\]\s*=\s*"(.*)"')

        match_type = ''
        last_group = ''
        extra_line = False

        with open(fname, 'r') as fp:
            for per_line in fp.read().splitlines():
                extra_line = False
                if match_type:
                    val = per_line[:-1].strip()
                    if val:
                        if last_group:
                            last_group += ' %s' % (val)
                        else:
                            last_group = val
                    if per_line and per_line[-1] == '\\':
                        continue
                else:
                    while True:
                        ret = RES['license'].match(per_line)
                        if ret:
                            match_type = 'license'
                            last_group = ret.groups()[0].strip()
                            break

                        ret = RES['licfile'].match(per_line)
                        if ret:
                            match_type = 'licfile'
                            if ret.groups()[0] and ret.groups()[0][-1] == '\\':
                                last_group = ret.groups()[0][:-1].strip()
                                extra_line = True
                            else:
                                last_group = ret.groups()[0][:-1].strip()
                            break

                        ret = RES['homepage'].match(per_line)
                        if ret:
                            match_type = 'homepage'
                            last_group = ret.groups()[0].strip()
                            break

                        ret = RES['description'].match(per_line)
                        if ret:
                            match_type = 'description'
                            if ret.groups()[0] and ret.groups()[0][-1] == '\\':
                                last_group = ret.groups()[0][:-1].strip()
                                extra_line = True
                            else:
                                last_group = ret.groups()[0][:-1].strip()
                            break

                        ret = RES['srcuri'].match(per_line)
                        if ret:
                            match_type = 'srcuri'
                            last_group = ret.groups()[0][:-1].strip()
                            break

                        ret = RES['flags'].match(per_line)
                        if ret:
                            match_type = 'flags'
                            self.method = ret.groups()[0]
                            if ret.groups()[1] and ret.groups()[1][-1] == '\\':
                                last_group = ret.groups()[1][:-1].strip()
                                extra_line = True
                            else:
                                last_group = ret.groups()[1][:-1].strip()
                            break

                        ret = RES['depends'].match(per_line)
                        if ret:
                            match_type = 'depends'
                            if ret.groups()[0] and ret.groups()[0][-1] == '\\':
                                last_group = ret.groups()[0][:-1].strip()
                                extra_line = True
                            else:
                                last_group = ret.groups()[0][:-1].strip()
                            break

                        ret = RES['pkgconfig'].match(per_line)
                        if ret:
                            match_type = 'pkgconfig'
                            last_group = ret.groups()
                            break

                        extra_line = True
                        break

                if extra_line:
                    continue

                if match_type == 'license':
                    self.license = last_group
                elif match_type == 'licfile':
                    for item in re.split(r'\s+', last_group):
                        self.licfile.append(item.split(';')[0])
                elif match_type == 'homepage':
                    self.homepage = last_group
                elif match_type == 'description':
                    self.description = last_group
                elif match_type == 'srcuri':
                    self.srcuri = last_group
                elif match_type == 'flags':
                    if self.flags:
                        self.flags += ' %s' % (last_group)
                    else:
                        self.flags = last_group
                elif match_type == 'depends':
                    for item in re.split(r'\s+', last_group.replace('virtual/', '')):
                        if item not in self.depends:
                            self.depends.append(item)
                elif match_type == 'pkgconfig':
                    item = []
                    item.append(last_group[0].strip())
                    item += [v.strip() for v in last_group[1].replace('virtual/', '').strip().split(',')]
                    num = len(item)
                    while num < 4:
                        item.append('')
                        num += 1

                    self.pkgconfig.append(item)

                match_type = ''


    def write_mkdeps(self, dpath):
        dfile = os.path.join(dpath, 'mk.deps')
        with open(dfile, 'w') as fp:
            fp.write(self.statement)
            fp.write('#DEPS(mk.deps) %s(native psysroot): unselect' % (self.package))
            if self.depends:
                fp.write(' %s' % (' '.join(self.depends)))
            if self.pkgconfig:
                for item in self.pkgconfig:
                    if not item[3]:
                        item[3] = []
                        continue
                    pkgs = re.split(r'\s+', item[3])
                    item[3] = pkgs
                    for pkg in pkgs:
                        fp.write(' \\\n    %s@@CONFIG_%s_FT_%s' % (pkg, self.toupper(self.package), self.toupper(item[0])))
            fp.write('\n\n')

            fp.write('PACKAGE_NAME     = %s\n\n' % (self.package))
            fp.write('LICENSE          = %s\n'   % (self.license if self.license else 'xxxx'))
            fp.write('LICFILE          = %s\n'   % (' '.join(self.licfile) if self.licfile else 'xxxx'))
            fp.write('HOMEPAGE         = %s\n'   % (self.homepage if self.homepage else 'xxxx'))
            fp.write('DESCRIPTION      = %s\n\n' % (self.description if self.description else 'xxxx'))

            if self.pkgconfig:
                fp.write('-include $(ENV_CFG_ROOT)/.config\n')
            fp.write('include $(ENV_MAKE_DIR)/inc.env.mk\n\n')

            fp.write('FETCH_METHOD     = tar\n')
            fp.write('VERSION          = xxxx\n')
            fp.write('SRC_DIR          = $(PACKAGE_NAME)-$(VERSION)\n')
            fp.write('SRC_NAME         = $(SRC_DIR).tar.xz\n')
            fp.write('SRC_URL          = %s\n' % (self.srcuri if self.srcuri else 'https://xxxx/$(SRC_NAME)'))
            fp.write('#SRC_MD5          = xxxx\n\n')

            fp.write('CACHE_BUILD      = y\n')
            fp.write('CACHE_DEPENDS    =\n\n')

            if self.flags:
                if self.method == 'CONF':
                    fp.write('COMPILE_TOOL     = autotools\n')
                    fp.write('AUTOTOOLS_FLAGS += %s\n' % (self.flags))
                elif self.method == 'CMAKE':
                    fp.write('COMPILE_TOOL     = cmake\n')
                    fp.write('CMAKE_FLAGS     += %s\n' % (self.flags))
                elif self.method == 'MESON':
                    fp.write('COMPILE_TOOL     = meson\n')
                    fp.write('MESON_FLAGS     += %s\n' % (self.flags))
            else:
                    fp.write('#COMPILE_TOOL     = xxxx\n')
            fp.write('\n')

            if self.pkgconfig:
                for item in self.pkgconfig:
                    fp.write('$(eval $(call ft-config,CONFIG_%s_FT_%s,%s,%s))\n' % \
                            (self.toupper(self.package), self.toupper(item[0]), item[1], item[2]))
            fp.write('\n')

            fp.write('include $(ENV_MAKE_DIR)/inc.rule.mk\n')
        print('\033[32mGenerate %s OK.\033[0m' % dfile)


    def write_mkconf(self, dpath):
        if not self.pkgconfig:
            return

        dfile = os.path.join(dpath, '%s.kconf' % (self.package))
        with open(dfile, 'w') as fp:
            fp.write(self.statement)
            for item in self.pkgconfig:
                fp.write('config %s_FT_%s\n' % (self.toupper(self.package), self.toupper(item[0])))
                fp.write('    default n\n')
                fp.write('    bool "%s: Enable or disable %s"\n' % (self.package, item[0]))
                if item[3]:
                    pkgs = [self.toupper(v) for v in item[3]]
                    fp.write('    depends on %s\n' % (' && '.join(pkgs)))
                fp.write('\n')
        print('\033[32mGenerate %s OK.\033[0m' % dfile)


        dfile = os.path.join(dpath, '%s-native.kconf' % (self.package))
        with open(dfile, 'w') as fp:
            fp.write(self.statement)
            for item in self.pkgconfig:
                fp.write('config %s_FT_%s_NATIVE\n' % (self.toupper(self.package), self.toupper(item[0])))
                fp.write('    default n\n')
                fp.write('    bool "%s: Enable or disable %s"\n' % (self.package, item[0]))
                if item[3]:
                    pkgs = [ '%s_NATIVE' % (self.toupper(v)) for v in item[3]]
                    fp.write('    depends on %s\n' % (' && '.join(pkgs)))
                fp.write('\n')
        print('\033[32mGenerate %s OK.\033[0m' % dfile)


if __name__ == '__main__':
    argc = len(sys.argv)
    if argc != 2 and argc != 3:
        print('Usage: python3 %s <recipe pathname> <save path>' % (sys.argv[0]))
        sys.exit(1)

    info = PkgInfo()
    info.analyze_recipe(sys.argv[1])

    spath = ''
    if argc == 3 and sys.argv[2]:
        spath = os.path.join(sys.argv[2], info.package)
    else:
        spath = info.package

    if not os.path.exists(spath):
        os.mkdir(spath)

    info.write_mkdeps(spath)
    info.write_mkconf(spath)

