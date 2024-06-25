############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

import sys, os, re, shutil, subprocess
from argparse import ArgumentParser

syslib_dir = 'syslib'

class Cbuild_Package:
    def __init__(self, args):
        self.rootfs = os.path.realpath(args.rootfs)
        self.compiler = args.compiler
        self.elftool = args.elftool

        self.ldso = ""
        self.pathes = []
        self.process_ldso = []
        self.process_rpath = []
        self.process_libs = []
        self.system_ldso = []
        self.system_rpath = []
        self.system_libs = []
        self.existed_libs = []
        self.unknown_libs = []
        self.wanted_libs = []


    def process_needed(self, filepath):
        cmd = "LANG=en_US %s -d %s |grep '(NEEDED)' | cut -d '[' -f 2 | cut -d ']' -f 1" % (self.elftool, filepath)
        ret, info = subprocess.getstatusoutput(cmd)
        if ret != 0:
            print('\033[31mERROR: run (%s) failed.\033[0m' % (cmd))
            sys.exit(1)

        needed = []
        if info:
            needed = re.split(r'\s+', info)
        return needed


    def process_rootfs(self, ignore):
        all_pathes = []
        ignore_dirs = ignore.split(':') if ignore else []
        for root, dirs, files in os.walk(self.rootfs):
            if dirs and ignore_dirs:
                for idir in dirs:
                    if idir in ignore_dirs:
                        dirs.remove(idir)
            if dirs:
                dirs.sort()

            root = os.path.realpath(root)
            if root in all_pathes:
                continue
            all_pathes.append(root)

            ldso_item = (root, [])
            rpath_item = (root, [])
            lib_item = (root, [])

            for ifile in files:
                filepath = os.path.join(root, ifile)
                info = subprocess.getoutput('LANG=en_US file %s' % (filepath))

                if 'dynamically linked' in info:
                    if 'interpreter' in info:
                        ldso_item[1].append(ifile)
                        if not self.ldso:
                            regex = re.compile(r'.*interpreter ([^,]*),.*')
                            ret = regex.match(info)
                            if ret:
                                self.ldso= os.path.basename(ret.groups()[0].strip())

                    needed = self.process_needed(filepath)
                    if needed:
                        rpath_item[1].append(ifile)
                        for rlib in needed:
                            if rlib not in self.wanted_libs:
                                self.wanted_libs.append(rlib)

                    if ifile.endswith('.so') or '.so.' in ifile:
                        lib_item[1].append(ifile)
                        self.existed_libs.append(ifile)

                elif 'symbolic link' in info:
                    if ifile.endswith('.so') or '.so.' in ifile:
                        lib_item[1].append(ifile)
                        self.existed_libs.append(ifile)

            if ldso_item[1]:
                self.process_ldso.append(ldso_item)
            if rpath_item[1]:
                self.process_rpath.append(rpath_item)
            if lib_item[1]:
                self.process_libs.append(lib_item)
                self.pathes.append(root)

        if self.ldso and self.ldso not in self.wanted_libs:
            self.wanted_libs.append(self.ldso)
        libs = [lib for lib in self.wanted_libs if lib not in self.existed_libs]
        self.wanted_libs = libs

        syslib = os.path.join(self.rootfs, syslib_dir)
        if syslib not in self.pathes:
            self.pathes.append(syslib)

        self.process_ldso.append((syslib, self.system_ldso))
        self.process_rpath.append((syslib, self.system_rpath))


    def process_system(self, extra):
        tmp_pathes = extra.split(':') if extra else []

        cmd = "LANG=en_US %s --print-search-dirs | grep 'libraries: =' |sed -e 's/libraries: =//g'" % (self.compiler)
        ret, info = subprocess.getstatusoutput(cmd)
        if ret != 0:
            print('\033[31mERROR: run (%s) failed.\033[0m' % (cmd))
            sys.exit(1)
        if info:
            tmp_pathes += info.split(':')

        sys_pathes = []
        for path in tmp_pathes:
            if not os.path.isdir(path):
                continue
            path = os.path.realpath(path)
            if path in sys_pathes:
                continue
            sys_pathes.append(path)

            item = (path, [])
            for ifile in os.listdir(path):
                if ifile.endswith('.so') or '.so.' in ifile:
                    item[1].append(ifile)

            if item[1]:
                self.system_libs.append(item)


    def process_syslib(self):
        syslib = os.path.join(self.rootfs, syslib_dir)
        if not os.path.exists(syslib):
            os.mkdir(syslib)

        libs = self.wanted_libs[:]
        while libs:
            lib = libs[0]
            for item in self.system_libs:
                if lib in item[1]:
                    libpath = os.path.join(item[0], lib)
                    if os.path.islink(libpath):
                        realpath = os.path.realpath(libpath)
                        reallib = os.path.basename(realpath)
                    else:
                        realpath = libpath
                        reallib = lib

                    if reallib not in self.existed_libs and reallib not in self.unknown_libs:
                        info = subprocess.getoutput('LANG=en_US file %s' % (realpath))
                        if 'interpreter' in info:
                            self.system_ldso.append(reallib)
                            if not self.ldso:
                                regex = re.compile(r'.*interpreter ([^,]*),.*')
                                ret = regex.match(info)
                                if ret:
                                    self.ldso= os.path.basename(ret.groups()[0].strip())
                                    if self.ldso not in self.existed_libs and self.ldso not in self.unknown_libs \
                                        and self.ldso not in libs:
                                        libs.append(self.ldso)

                        needed = self.process_needed(realpath)
                        if needed:
                            if reallib not in self.system_rpath:
                                self.system_rpath.append(reallib)
                            for rlib in needed:
                                if rlib not in self.existed_libs and rlib not in self.unknown_libs \
                                    and rlib not in libs:
                                    libs.append(rlib)

                        dstfile = os.path.join(syslib, reallib)
                        shutil.copy(realpath, dstfile)
                        self.existed_libs.append(reallib)
                        if reallib in libs:
                            libs.remove(reallib)

                    if lib != reallib:
                        cmd = 'cd %s && ln -sfT %s %s' % (syslib, reallib, lib)
                        ret = subprocess.call(cmd, shell = True)
                        if ret != 0:
                            print('\033[31mERROR: run (%s) failed.\033[0m' % (cmd))
                            sys.exit(1)
                        self.existed_libs.append(lib)
                        libs.remove(lib)
                    break
            else:
                self.unknown_libs.append(lib)
                libs.remove(lib)


    def process_patchelf(self):
        syslib = os.path.join(self.rootfs, syslib_dir)
        ldpath = ''
        if self.ldso:
            if self.ldso in self.wanted_libs:
                ldpath = os.path.join(self.rootfs, syslib_dir, self.ldso)
            else:
                for item in self.process_libs:
                    if self.ldso in item[1]:
                        ldpath = os.path.join(item[0], self.ldso)
                        break
                else:
                    ldpath = os.path.join(self.rootfs, syslib_dir, self.ldso)


        print('Interpreter path       : ' + str(ldpath))
        print('ELFs with interpreter  : ' + str(self.process_ldso))
        print('ELFs with rpath        : ' + str(self.process_rpath))
        print('ELFs copied from system: ' + str(self.wanted_libs))

        if self.ldso:
            interpreter = ldpath
            for item in self.process_ldso:
                #interpreter = '\$ORIGIN/' + os.path.relpath(ldpath, item[0])
                for var in item[1]:
                    varpath = os.path.join(item[0], var)
                    cmd = 'patchelf --set-interpreter %s %s' % (interpreter, varpath)
                    ret = subprocess.call(cmd, shell = True)

                    if ret != 0:
                        print('\033[31mERROR: run (%s) failed.\033[0m' % (cmd))
                        sys.exit(1)

        #rpath = ':'.join(self.pathes)
        for item in self.process_rpath:
            rpath = ':'.join(['\$ORIGIN/%s' % (os.path.relpath(path, item[0])) for path in self.pathes])
            for var in item[1]:
                varpath = os.path.join(item[0], var)
                cmd = 'patchelf --set-rpath %s %s' % (rpath, varpath)
                ret = subprocess.call(cmd, shell = True)
                if ret != 0:
                    print('\033[31mERROR: run (%s) failed.\033[0m' % (cmd))
                    sys.exit(1)


def parse_options():
    parser = ArgumentParser( description="Tool to generate CPK (Cbuild Application Package).")

    parser.add_argument('-r', '--rootfs',
            dest='rootfs',
            help='Specify the input rootfs to process.')

    parser.add_argument('-i', '--ignore',
            dest='ignore',
            help='Specify the ignored directories that are not processed.')

    parser.add_argument('-c', '--compiler',
            dest='compiler',
            help='Specify the compiler, for example: gcc.')

    parser.add_argument('-t', '--elftool',
            dest='elftool',
            help='Specify the ELF tool, for example: readelf.')

    parser.add_argument('-e', '--extra',
            dest='extra',
            help='Specify the extra directories to get system dynamic libraries.')

    args = parser.parse_args()
    if not args.rootfs:
        print('\033[31mERROR: Please set rootfs to process.\033[0m')
        parser.print_help()
        sys.exit(1)
    if not os.path.isdir(args.rootfs):
        print('\033[31mERROR: Rootfs (%s) is not a folder.\033[0m' % (args.rootfs))
        sys.exit(1)

    if not args.compiler:
        args.compiler = 'gcc'
    if not args.elftool:
        args.elftool = 'readelf'

    return args


if __name__ == '__main__':
    args = parse_options()
    cpk = Cbuild_Package(args)

    cpk.process_rootfs(args.ignore)
    cpk.process_system(args.extra)
    cpk.process_syslib()
    cpk.process_patchelf()

    if cpk.unknown_libs:
        print('\033[31mERROR: These shared libs (%s) can not be found, please set "-e <extra searched pathes>".\033[0m' % (str(cpk.unknown_libs)))
        sys.exit(1)
    print('\033[32mCPK SUCCESS: %s\033[0m' % (cpk.rootfs))

