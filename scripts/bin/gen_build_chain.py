############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

import sys, os, re, copy, subprocess
from argparse import ArgumentParser

debug_mode = False
host_mode = False if os.getenv('ENV_BUILD_TOOL') or os.getenv('CROSS_COMPILE') else True
dis_isysroot = True
dis_gsysroot = False

def escape_toupper(var):
    return var.replace('.', '__dot__').replace('+', '__plus__').replace('-', '_').upper()


def escape_tolower(var):
    return var.lower().replace('_', '-').replace('__dot__', '.').replace('__plus__', '+')


def re_replace_env(matchobj):
    return os.getenv(matchobj.group(0)[2:-1])


class Deps:
    def __init__(self):
        self.RegexDict = {}
        self.VarDict = {}
        self.InfoDict = {}
        self.KconfigDict = {}
        self.PathList = []
        self.PokyList = []
        self.PokyMoved = []
        self.ItemList = []
        self.ActualList = []
        self.VirtualList = []
        self.FinallyList = []

        self.conf_name = ''
        self.conf_str = ''
        self.uni_packages = []
        self.user_metas = []
        self.keywords = []
        self.prepend_flag = 0
        self.yocto_flag = False


    def __init_item(self, item):
        item['path'] = ''
        item['mpath'] = ''
        item['spath'] = ''
        item['src'] = ''
        item['make'] = ''
        item['vtype'] = ''
        item['member'] = []
        item['target'] = ''
        item['targets'] = []
        item['asdeps'] = []     # actual stong dependence
        item['vsdeps'] = []     # virtual strong dependences
        item['awdeps'] = []     # actual weak dependence
        item['vwdeps'] = []     # virtual weak dependence
        item['ideps'] = []      # condition weak dependence
        item['wrule'] = []      # weak dependence rules
        item['cdeps'] = []      # conflict dependences
        item['edeps'] = []      # env dependences
        item['acount'] = 0      # actual dependence items count
        item['select'] = []
        item['imply'] = []
        item['default'] = True
        item['conf'] = ''


    def get_env_vars(self, local_config):
        regex = re.compile(r'([\w\-\./]+)\s*=\s*"(.*)"')
        with open(local_config, 'r') as fp:
            for per_line in fp.read().splitlines():
                ret = regex.match(per_line)
                if ret:
                    self.VarDict[ret.groups()[0]] = ret.groups()[1]


    def get_search_dirs(self, layer_config):
        dirs = []
        flag = False
        with open(layer_config, 'r') as fp:
            for per_line in fp.read().splitlines():
                if not flag:
                    if 'BBLAYERS ?=' in per_line:
                        flag = True
                else:
                    if '"' in per_line:
                        break
                    else:
                        print("\033[032mSearch Layer:\033[0m \033[44m%s\033[0m" % per_line[0:-2].strip())
                        dirs.append(per_line[0:-2].strip())
        return dirs


    def __get_append_flag(self, item, check_append):
        if not check_append:
            return True
        for vitem in self.VirtualList:
            if 'choice' == vitem['vtype'] and item['target'] in vitem['targets']:
                vitem['member'].append(item)
                return False
        return True


    def __set_item_deps(self, deps, item, check_append):
        if deps:
            for dep in deps:
                sdeps = 'asdeps'
                wdeps = 'awdeps'
                if dep[0] == '*':
                    dep = dep[1:]
                    sdeps = 'vsdeps'
                    wdeps = 'vwdeps'

                if dep == 'kconfig':
                    if item['conf'] not in self.KconfigDict.keys():
                        self.KconfigDict[item['conf']] = []
                    self.KconfigDict[item['conf']].append(item['target'])
                    item['conf'] = 'kconfig'
                elif dep == 'nokconfig':
                    item['conf'] = ''
                elif dep == 'unselect':
                    item['default'] = False
                elif dep[0] == '!':
                    item['cdeps'].append(dep[1:])
                elif '@' in dep:
                    item['ideps'].append(dep)
                elif dep[0] == '&' or dep[0] == '?':
                    amp_num = 0
                    que_num = 0
                    for i in range(len(dep)):
                        if dep[i] == '&':
                            amp_num += 1
                        elif dep[i] == '?':
                            que_num += 1
                        else:
                            break

                    dep = dep[amp_num + que_num:]
                    if amp_num == 2 or amp_num == 1:
                        if '|' in dep:
                            split_str = '||' if '||' in dep else '|'
                            subdeps = dep.split(split_str)
                            if not subdeps[0]:
                                subdep = subdeps[1]
                                subdeps[0] = '*build-%s' % (subdep)
                                subdeps[1] = 'prebuild-%s' % (subdep)
                                subdeps.append(subdep)
                                dep = split_str.join(subdeps)

                            for subdep in subdeps:
                                if subdep[0] == '*':
                                    item['vwdeps'].append(dep[1:])
                                else:
                                    item['awdeps'].append(dep)
                        item['select' if amp_num == 2 else 'imply'].append(dep)
                    if que_num:
                        item[wdeps].append(dep)
                elif '=' in dep:
                    item['edeps'].append(dep)
                elif '|' in dep:
                    subdeps = dep.split('||') if '||' in dep else dep.split('|')
                    if not subdeps[0]:
                        subdeps[0] = 'prebuild-' + subdeps[1]
                    item[wdeps] += subdeps
                    item['wrule'].append(subdeps)
                else:
                    item[sdeps].append(dep)

        return self.__get_append_flag(item, check_append)


    def __switch_native_dep(self, nitem, item, deptype):
        nitem[deptype] = []
        for dep in item[deptype]:
            if not dep.endswith('-native') and dep not in self.uni_packages:
                dep = dep + '-native'
            if dep != nitem['target'] and dep not in nitem[deptype]:
                nitem[deptype].append(dep)


    def __get_native_deps(self, item):
        nitem = copy.deepcopy(item)

        nitem['target'] = item['target'] + '-native'

        if item['vtype']:
            self.__switch_native_dep(nitem, item, 'targets')
        else:
            nitem['targets'] = []
            for target in item['targets']:
                if ':' in target:
                    deps = []
                    targets_pair = target.split('::')
                    targets_deps = targets_pair[1].split(':')
                    for dep in targets_deps:
                        if not dep.endswith('-native') and dep not in self.uni_packages:
                            dep = dep + '-native'
                        if dep != nitem['target'] and dep not in deps:
                            deps.append(dep)
                    if deps:
                        nitem['targets'].append(targets_pair[0] + '::')
                    else:
                        nitem['targets'].append(targets_pair[0] + '::' + ':'.join(deps))
                elif target != 'release':
                    nitem['targets'].append(target)

        self.__switch_native_dep(nitem, item, 'asdeps')
        self.__switch_native_dep(nitem, item, 'vsdeps')
        self.__switch_native_dep(nitem, item, 'awdeps')
        self.__switch_native_dep(nitem, item, 'vwdeps')
        self.__switch_native_dep(nitem, item, 'cdeps')
        self.__switch_native_dep(nitem, item, 'select')
        self.__switch_native_dep(nitem, item, 'imply')

        nitem['ideps'] = []
        ideps = []
        for idep in item['ideps']:
            dep,cond = re.split(r'@+', idep)
            split_str = '@@' if '@@' in idep else '@'
            if not dep.endswith('-native') and dep not in self.uni_packages:
                dep = dep + '-native'
            if dep != nitem['target'] and dep not in ideps:
                ideps.append(dep)
                if nitem['conf'] == 'kconfig':
                    nitem['ideps'].append(dep + split_str + '%s' % (cond))
                else:
                    nitem['ideps'].append(dep + split_str + '%s_NATIVE' % (cond))

        nitem['wrule'] = []
        for wrule in item['wrule']:
            ndeps = []
            for dep in wrule:
                if not dep.endswith('-native') and dep not in self.uni_packages:
                    dep = dep + '-native'
                if dep != nitem['target'] and dep not in ndeps:
                    ndeps.append(dep)
            if ndeps:
                nitem['wrule'].append(ndeps)

        if nitem['conf']:
            if nitem['conf'] == 'kconfig':
                for kconf_path in self.KconfigDict.keys():
                    if item['target'] in self.KconfigDict[kconf_path]:
                        self.KconfigDict[kconf_path].append(nitem['target'])
                        break
            else:
                baseconf = os.path.basename(item['conf'])
                if item['target'] in baseconf:
                    dirconf = os.path.dirname(item['conf'])
                    nativeconf = os.path.join(dirconf, baseconf.replace(item['target'], nitem['target']))
                    if os.path.exists(nativeconf):
                        nitem['conf'] = nativeconf
                    else:
                        nitem['conf'] = ''
                else:
                    nitem['conf'] = ''

        nitem['member'] = []
        nitem['edeps'] = []
        nitem['acount'] = 0
        nitem['default'] = False

        return nitem


    def __add_virtual_deps(self, vir_name, root, rootdir):
        target_list = []
        vir_path = os.path.join(root, vir_name)
        match_type = ''
        last_group = ''
        ret = None

        with open(vir_path, 'r') as fp:
            for per_line in fp.read().splitlines():
                per_line = per_line.strip()
                if match_type:
                    if per_line and per_line[-1] == '\\':
                        last_group = '%s %s' % (last_group, per_line[:-1].strip())
                        continue
                    else:
                        last_group = '%s %s' % (last_group, per_line.strip())
                else:
                    ret = self.RegexDict['VDEPS'].match(per_line)
                    if ret:
                        match_type = 'VDEPS'
                        if ret.groups()[3] and ret.groups()[3][-1] == '\\':
                            last_group = ret.groups()[3][:-1].strip()
                            continue
                        else:
                            last_group = ret.groups()[3].strip()
                    else:
                        continue

                if match_type == 'VDEPS':
                    match_type = ''
                    item = {}
                    self.__init_item(item)

                    item['path'] = root
                    item['spath'] = root.replace(rootdir, '', 1)
                    if self.yocto_flag:
                        item['make'] = vir_name

                    item['vtype'] = ret.groups()[0]
                    if item['vtype'] != 'menuconfig' and item['vtype'] != 'config' and \
                            item['vtype'] != 'menuchoice' and item['vtype'] != 'choice':
                        print('ERROR: Invalid virtual dep type (%s) in %s' % (item['vtype'], item['path']))
                        print('       Only support menuconfig config menuchoice choice')
                        sys.exit(1)

                    item['target'] = ret.groups()[1]
                    if item['target'] in target_list:
                        print('ERROR: Repeated virtual dep %s:%s' % (item['target'], item['path']))
                        sys.exit(1)

                    targets = ret.groups()[2].strip().split()
                    if targets:
                        for t in targets:
                            if t[0] == '/':
                                item['spath'] += t
                            elif 'choice' in item['vtype']:
                                item['targets'].append(t)
                            else:
                                if debug_mode:
                                    print('WARNING: Only menuchoice and choice have groups[2] field in %s:%s' % (item['target'], item['path']))

                    target_list.append(item['target'])
                    self.__set_item_deps(last_group.strip().split(), item, False)
                    self.VirtualList.append(item)
                    self.PathList.append((item['path'], item['spath'], item['target']))

                    if 'native' in item['targets']:
                        item['targets'].remove('native')
                        if 'menu' not in item['vtype']:
                            nitem = self.__get_native_deps(item)
                            target_list.append(nitem['target'])
                            self.VirtualList.append(nitem)
                            self.PathList.append((nitem['path'], nitem['spath'], nitem['target']))


    def search_normal_depends(self, dep_name, vir_name, search_dirs, ignore_dirs = [], go_on_dirs = []):
        root_change = False if len(search_dirs) == 1 else True
        for rootdir in search_dirs:
            if rootdir[-1] == '/':
                rootdir = rootdir[:-1]

            root_dir = ''
            if root_change:
                root_dir = os.path.dirname(rootdir) + '/'
            else:
                root_dir = rootdir + '/'

            for root, dirs, files in os.walk(rootdir):
                if ignore_dirs and dirs:
                    for idir in ignore_dirs:
                        if idir in dirs:
                            dirs.remove(idir)

                if debug_mode:
                    if not dirs and dep_name not in files:
                        print('WARNING: No Rule Path: %s' % (root))

                if dirs:
                    dirs.sort()

                if vir_name and vir_name in files:
                    self.__add_virtual_deps(vir_name, root, root_dir)

                if dep_name in files:
                    self.PathList.append((root, root.replace(root_dir, '', 1), ''))
                    if 'continue' not in files:
                        if not go_on_dirs or root not in go_on_dirs:
                            dirs.clear() # don't continue to search sub dirs.


    def search_yocto_depends(self, vir_name, search_dirs, ignore_dirs = []):
        poky_targets = []
        for rootdir in search_dirs:
            if rootdir[-1] == '/':
                rootdir = rootdir[:-1]

            root_dir = os.path.dirname(rootdir) + '/'

            user_flag = False
            if self.user_metas and rootdir.split('/')[-1] in self.user_metas:
                user_flag = True

            for root, dirs, files in os.walk(rootdir):
                if ignore_dirs and dirs and user_flag:
                    for idir in ignore_dirs:
                        if idir in dirs:
                            dirs.remove(idir)

                if dirs:
                    dirs.sort()
                if files:
                    files.sort()

                if vir_name and vir_name in files:
                    self.__add_virtual_deps(vir_name, root, root_dir)

                for fname in files:
                    if fname.endswith('.bb') and '-native' not in fname:
                        item = {}
                        self.__init_item(item)

                        fullname = os.path.join(root, fname)
                        item['path'] = os.path.dirname(fullname)
                        item['spath'] = os.path.dirname(fullname.replace(root_dir, '', 1))
                        item['make'] = fname
                        item['target'] = fname[0:fname.rindex('_') if '_' in fname else fname.rindex('.')]

                        if not user_flag:
                            if item['target'] not in poky_targets:
                                item['default'] = False
                                self.PokyList.append(item)
                                poky_targets.append(item['target'])
                        else:
                            self.PathList.append((item['path'], item['spath'], '', item['make']))


    def __add_item_to_list(self, item, refs):
        ipath = item['path']
        ilen = len(ipath)
        ispath = item['spath']
        islen = len(ispath)
        item_list = {}

        while refs:
            for ref in refs[-1]:
                rspath = ref['spath']
                rslen = len(rspath)
                if islen >= rslen and ispath[:rslen] == rspath and (islen == rslen or ispath[rslen] == '/'):
                    item_list = ref
                    break

            if item_list:
                break
            else:
                rpath = refs[-1][-1]['path']
                rlen = len(rpath)
                if ilen >= rlen and ipath[:rlen] == rpath and (ilen == rlen or ipath[rlen] == '/'):
                    if 'menu' in item['vtype']:
                        if ipath == rpath:
                            refs[-1].append(item)
                        else:
                            for ref in refs[-1]:
                                rspath = ref['spath']
                                rslen = len(rspath)
                                if islen >= rslen and ispath[:rslen] == rspath and (islen == rslen or ispath[rslen] == '/'):
                                    ref['member'].append(item)
                                    break
                            else:
                                refs.pop()
                                continue
                            break

                    if len(refs) == 1:
                        self.ItemList.append(item)
                    else:
                        for ref in refs[-2]:
                            rspath = ref['spath']
                            rslen = len(rspath)
                            if islen >= rslen and ispath[:rslen] == rspath and (islen == rslen or ispath[rslen] == '/'):
                                ref['member'].append(item)
                                break
                        else:
                            refs.pop()
                            continue
                    return
                else:
                    refs.pop()

        if item_list:
            item_list['member'].append(item)
        else:
            self.ItemList.append(item)

        if 'menu' in item['vtype']:
            refs.append([item])


    def add_normal_item(self, pathpair, dep_name, refs):
        if pathpair[2]:
            for item in self.VirtualList:
                if pathpair[2] == item['target']:
                    if self.__get_append_flag(item, True):
                        self.__add_item_to_list(item, refs)
                    break
            return

        dep_path = os.path.join(pathpair[0], dep_name)
        with open(dep_path, 'r') as fp:
            dep_flag = False
            ItemDict = {}
            items = []
            attrs = set()
            package = ''
            match_type = ''
            last_group = ''
            ret = None

            VARS = ['VERSION', 'LICENSE', 'LICFILE', 'HOMEPAGE', 'DESCRIPTION']
            LINE_MATCHES = ['DESCRIPTION']

            for per_line in fp.read().splitlines():
                per_line = per_line.strip()
                if match_type:
                    split_str = '\n' if match_type in LINE_MATCHES else ' '
                    if per_line and per_line[-1] == '\\':
                        last_group = '%s%s%s' % (last_group, split_str, per_line[:-1].strip())
                        continue
                    else:
                        last_group = '%s%s%s' % (last_group, split_str, per_line.strip())
                else:
                    ret = self.RegexDict['DEPS'].match(per_line)
                    if ret:
                        match_type = 'DEPS'
                        if ret.groups()[3] and ret.groups()[3][-1] == '\\':
                            last_group = ret.groups()[3][:-1].strip()
                            continue
                        else:
                            last_group = ret.groups()[3].strip()

                    if not ret:
                        ret = self.RegexDict['INCDEPS'].match(per_line)
                        if ret:
                            match_type = 'INCDEPS'
                            if ret.groups()[0] and ret.groups()[0][-1] == '\\':
                                last_group = ret.groups()[0][:-1].strip()
                                continue
                            else:
                                last_group = ret.groups()[0].strip()

                    if not ret:
                        ret = self.RegexDict['CACHE'].match(per_line)
                        if ret:
                            attrs.add('cache')
                            continue
                    if not ret:
                        ret = self.RegexDict['URL'].match(per_line)
                        if ret:
                            attrs.add('url')
                            continue
                    if not ret:
                        ret = self.RegexDict['INCRULE'].match(per_line)
                        if ret:
                            attrs.add('unified')
                            continue

                    if not ret:
                        ret = self.RegexDict['PACKAGE'].match(per_line)
                        if ret:
                            package = ret.groups()[0].strip('"').strip()
                            if package not in self.InfoDict.keys():
                                self.InfoDict[package] = {}
                                self.InfoDict[package]['NAME'] = package
                            continue

                    if package and not ret:
                        ret = self.RegexDict['VARS'].match(per_line)
                        if ret and ret.groups()[0] in VARS:
                            match_type = ret.groups()[0]
                            if ret.groups()[1] and ret.groups()[1][-1] == '\\':
                                last_group = ret.groups()[1][:-1].strip()
                                continue
                            else:
                                last_group = ret.groups()[1].strip()

                    if not match_type:
                        continue

                if match_type == 'DEPS':
                    match_type = ''
                    dep_flag = True
                    item = {}
                    self.__init_item(item)

                    item['target'] = ret.groups()[1]
                    if item['target'] == 'ignore':
                        continue

                    makestr = ret.groups()[0]
                    real_makstr = makestr
                    if makestr and '${' in makestr:
                        real_makstr = re.sub(r'(\$\{[\w\-]+\})', re_replace_env, makestr)

                    if real_makstr and '/' in real_makstr:
                        makes = os.path.split(real_makstr)
                        if makestr[0] == '$':
                            item['path'] = pathpair[0]
                            item['spath'] = pathpair[1]
                            item['mpath'] = makes[0]
                            item['make'] = makes[1]
                        else:
                            item['path'] = os.path.join(pathpair[0], makes[0])
                            item['spath'] = os.path.join(pathpair[1], makes[0])
                            item['mpath'] = item['path']
                            item['make'] = makes[1]
                    else:
                        item['path'] = pathpair[0]
                        item['spath'] = pathpair[1]
                        item['mpath'] = item['path']
                        item['make'] = makestr

                    targets = ret.groups()[2].strip()
                    if not targets:
                        item['targets'] = []
                    else:
                        item['targets'] = targets.split()
                        if 'finally' in item['targets']:
                            item['acount'] = 1
                            self.FinallyList.append(item['target'])

                    depends = last_group.strip().split()

                    if self.conf_name and 'nokconfig' not in depends:
                        conf_paths = []
                        conf_paths.append(os.path.join(item['path'], '%s.%s' % (item['target'], self.conf_name.split('.')[-1])))
                        conf_paths.append(os.path.join(item['path'], self.conf_name))
                        if item['mpath'] != item['path']:
                            conf_paths.append(os.path.join(item['mpath'], '%s.%s' % (item['target'], self.conf_name.split('.')[-1])))
                            conf_paths.append(os.path.join(item['mpath'], self.conf_name))
                        for conf_path in conf_paths:
                            if os.path.exists(conf_path):
                                item['conf'] = conf_path
                                break

                    if self.__set_item_deps(depends, item, True):
                        if makestr and '/' in makestr:
                            ItemDict[makestr] = item
                        else:
                            self.__add_item_to_list(item, refs)
                    self.ActualList.append(item)
                    items.append(item)

                    if host_mode and not item['target'].endswith('-native'):
                        host_dep = '%s-native' % (item['target'])
                        if host_dep in item['asdeps']:
                            item['asdeps'].remove(host_dep)
                        if host_dep in item['awdeps']:
                            item['awdeps'].remove(host_dep)

                    if 'native' in item['targets']:
                        item['targets'].remove('native')
                        nitem = self.__get_native_deps(item)
                        if self.__get_append_flag(nitem, True):
                            if makestr and '/' in makestr:
                                ItemDict[makestr + '.native'] = nitem
                            else:
                                self.__add_item_to_list(nitem, refs)
                        self.ActualList.append(nitem)
                        items.append(nitem)
                    continue

                elif match_type == 'INCDEPS':
                    match_type = ''
                    dep_flag = True
                    sub_paths = last_group.split()
                    sub_paths.sort()

                    for sub_path in sub_paths:
                        real_sub_path = sub_path
                        if '${' in sub_path:
                            real_sub_path = re.sub(r'(\$\{[\w\-]+\})', re_replace_env, sub_path)
                        sub_pathpair = (os.path.join(pathpair[0], real_sub_path), os.path.join(pathpair[1], real_sub_path), '')
                        sub_dep_path = os.path.join(sub_pathpair[0], dep_name)

                        if os.path.exists(sub_dep_path):
                            self.add_normal_item(sub_pathpair, dep_name, refs)
                        else:
                            if debug_mode and '${' not in sub_path:
                                print('WARNING: ignore: %s' % sub_pathpair[0])

                elif match_type == 'VERSION':
                    match_type = ''
                    version = last_group.strip('"').strip()
                    vname = '%s_version' % (package)
                    if vname in version:
                        version = subprocess.getoutput('bash %s %s' % (os.path.join(os.getenv('ENV_TOOL_DIR'), 'process_machine.sh'), vname))
                    self.InfoDict[package]['VERSION'] = version
                elif match_type:
                    self.InfoDict[package][match_type] = last_group.strip('"').strip()
                    match_type = ''

            if ItemDict:
                keys = [t for t in ItemDict.keys()]
                keys.sort()
                for key in keys:
                    self.__add_item_to_list(ItemDict[key], refs)
            if items:
                if package and 'HOMEPAGE' not in self.InfoDict[package].keys():
                    self.InfoDict[package]['LOCATION'] = items[0]['mpath'].replace(os.getenv('ENV_TOP_DIR'), 'TOPDIR', 1)

                for item in items:
                    if 'empty' in item['targets']:
                        item['targets']  = ['empty', 'psysroot', 'norelease']
                        continue

                    if 'unified' not in item['targets'] and 'direct' not in item['targets']:
                        if 'unified' in attrs:
                            item['targets'].append('unified')
                        else:
                            item['targets'].append('direct')
                    if 'cache' in attrs:
                        if 'cache' not in item['targets']:
                            item['targets'].append('cache')
                    if 'url' in attrs:
                        if 'url' not in item['targets']:
                            item['targets'].append('url')

                    if 'unified' in item['targets']:
                        if 'distclean' not in item['targets']:
                            item['targets'].append('distclean')
                    else:
                        if 'isysroot' not in item['targets'] and 'noisysroot' not in item['targets']:
                            item['targets'].append('isysroot')

            if debug_mode and not dep_flag:
                print('WARNING: ignore: %s' % pathpair[0])


    def add_yocto_item(self, pathpair, refs):
        if pathpair[2]:
            for item in self.VirtualList:
                if pathpair[2] == item['target']:
                    if self.__get_append_flag(item, True):
                        self.__add_item_to_list(item, refs)
                    break
            return

        extra_deps = []
        item = {}
        self.__init_item(item)

        item['path'] = pathpair[0]
        item['spath'] = pathpair[1]
        item['make'] = pathpair[3]
        item['target'] = item['make'] [0:item['make'].rindex('_') if '_' in item['make'] else item['make'].rindex('.')]

        fullname = os.path.join(pathpair[0], pathpair[3])
        with open(fullname, 'r') as fp:
            for per_line in fp.read().splitlines():
                ret = self.RegexDict['DEPENDS'].match(per_line)
                if ret:
                    item['asdeps'] += [dep for dep in ret.groups()[0].strip().split() if '-native' not in dep]
                ret = self.RegexDict['EXTRADEPS'].match(per_line)
                if ret:
                    extra_deps += [dep for dep in ret.groups()[0].strip().split() if '-native' not in dep]

        bbappend_path = '%sappend' % (fullname)
        if os.path.exists(bbappend_path):
            with open(bbappend_path, 'r') as fp:
                for per_line in fp.read().splitlines():
                    ret = self.RegexDict['EXTERNALSRC'].match(per_line)
                    if ret:
                        src = ret.groups()[0]
                        for key in self.VarDict.keys():
                            var = '${%s}' % (key)
                            if var in src:
                                src = src.replace(var, self.VarDict[key])
                                if '$' not in src:
                                    break
                        item['src'] = src
                        break

        bbconfig_path = ''
        conf_pri_path = ''
        conf_pub_path = ''

        if 'nokconfig' not in extra_deps:
            bbconfig_path = os.path.join(item['path'], item['target'] + '.bbconfig')
            if self.conf_name and item['src']:
                if '.' in self.conf_name:
                    conf_pri_path = os.path.join(item['src'], '%s.%s' % (item['target'], self.conf_name.split('.')[-1]))
                conf_pub_path = os.path.join(item['src'], self.conf_name)

        if bbconfig_path and os.path.exists(bbconfig_path):
            item['conf'] = bbconfig_path
        elif conf_pri_path and os.path.exists(conf_pri_path):
            item['conf'] = conf_pri_path
        elif conf_pub_path and os.path.exists(conf_pub_path):
            item['conf'] = conf_pub_path
        else:
            item['conf'] = ''

        if self.__set_item_deps(extra_deps, item, True):
            self.__add_item_to_list(item, refs)

        self.ActualList.append(item)


    def check_item(self, item_list, target_list, poky_list = []):
        for item in item_list[:]:
            if item['wrule']:
                for rule in item['wrule'][:]:
                    deps = []
                    for dep in rule[:]:
                        deps.append(dep)
                        if dep not in target_list:
                            rule.remove(dep)
                    if not rule:
                        item['wrule'].remove(rule)
                        if not item['vtype'] and deps[0] in item['awdeps']:
                            print('ERROR: All weak rule deps (%s) in %s:%s are not found' % ( \
                                ' '.join(deps), item['target'], item['path']))
                            sys.exit(1)

            if item['ideps']:
                deps = item['ideps']
                item['ideps'] = [dep for dep in deps if re.split(r'@+', dep)[0] in target_list]

            for depid in ['asdeps', 'vsdeps', 'awdeps', 'vwdeps', 'cdeps', 'select', 'imply']:
                if not debug_mode and not self.yocto_flag and 'asdeps' == depid:
                    continue
                if item[depid]:
                    deps = item[depid]
                    item[depid] = [dep for dep in deps if dep in target_list]
                    if 'select' == depid or 'imply' == depid:
                        for dep in deps:
                            if '|' in dep:
                                subdeps = dep.split('||' if '||' in dep else '|')
                                for subdep in subdeps:
                                    if subdep[0] == '*':
                                        subdep = subdep[1:]
                                    if subdep in target_list:
                                        item[depid].append(subdep)
                                        break
                    if debug_mode and not self.yocto_flag:
                        rmdeps = [dep for dep in deps if dep not in item[depid]]
                        if rmdeps:
                            level = 'WARNING' if not item['vtype'] and 'asdeps' == depid else 'DEBUG'
                            print('%s: deps (%s) in %s:%s are not found' % (level, ' '.join(rmdeps), item['target'], item['path']))
            item['acount'] += len(item['asdeps']) + len(item['awdeps']) + len(item['ideps'])

            if 'choice' in item['vtype']:
                depid = 'targets'
                if item[depid]:
                    deps = item[depid]
                    item[depid] = []
                    for dep in deps:
                        if dep in target_list:
                            item[depid].append(dep)
                        elif dep in poky_list:
                            for poky_item in self.PokyList:
                                if dep == poky_item['target']:
                                    item[depid].append(dep)
                                    item['member'].append(poky_item)
                                    self.PokyMoved.append(poky_item)
                                    self.PokyList.remove(poky_item)
                                    break

                if item['select']:
                    item['select'] = []
                    if debug_mode:
                        print('WARNING: choice item in %s:%s has "select" attr' % (item['target'], item['path']))
                if item['imply']:
                    item['imply'] = []
                    if debug_mode:
                        print('WARNING: choice item in %s:%s has "imply" attr' % (item['target'], item['path']))

            if item['member']:
                self.check_item(item['member'], target_list, poky_list)
            else:
                if 'choice' in item['vtype'] or 'menu' in item['vtype']:
                    item_list.remove(item)
                    if item['target'] in target_list:
                        target_list.remove(item['target'])
                    self.VirtualList.remove(item)
                    if debug_mode:
                        print('WARNING: There is no members in virtual choice dep %s:%s' % (item['target'], item['path']))


    def check_repeat_package(self):
        package_set = set()
        for item in self.ActualList + self.VirtualList:
            if item['target'] not in package_set:
                package_set.add(item['target'])
            else:
                print('WARNING: repeated package: %s:%s' % (item['target'], item['path']))


    def check_circular_dep(self, target_list):
        temp = self.ActualList
        self.ActualList = []
        finally_flag = True
        while temp:
            lista = []
            listb = []
            for item in temp:
                if item['acount'] == 0:
                    lista.append(item)
                else:
                    listb.append(item)

            if lista:
                for itema in lista:
                    for itemb in listb:
                        if itemb['asdeps'] and itema['target'] in itemb['asdeps']:
                            itemb['acount'] -= 1
                        if itemb['awdeps'] and itema['target'] in itemb['awdeps']:
                            itemb['acount'] -= 1
                        if itemb['ideps'] and itema['target'] in [re.split(r'@+', dep)[0] for dep in itemb['ideps']]:
                            itemb['acount'] -= 1
                self.ActualList += lista
                temp = listb
            elif finally_flag:
                finally_flag = False
                for itemb in listb:
                    if itemb['target'] in self.FinallyList:
                        itemb['acount'] -= 1
                temp = listb
            else:
                print('--------ERROR: circular deps--------')
                for itemb in listb:
                    print('%s: %s: %s' % (itemb['path'], itemb['target'], ' '.join(itemb['asdeps'] + itemb['awdeps'] + itemb['ideps'])))
                print('------------------------------------')
                return -1

        return 0


    def __check_shared_kconfig(self, target):
        for kconf_path in self.KconfigDict.keys():
            if target in self.KconfigDict[kconf_path]:
                return kconf_path,self.KconfigDict[kconf_path]
        return '',[]


    def __write_one_kconfig(self, fp, item, choice_flag, max_depth):
        config_prepend = ''
        if self.prepend_flag:
            config_prepend = 'CONFIG_'
        target = '%s%s' % (config_prepend, escape_toupper(item['target']))

        if 'choice' in item['vtype']:
            fp.write('choice\n')
            fp.write('\tprompt "[v]-%s (%s)"\n' % (item['target'], item['spath']))
            if item['targets']:
                fp.write('\tdefault %s%s\n' % (config_prepend, escape_toupper(item['targets'][0])))
        elif 'menuconfig' == item['vtype']:
            fp.write('menuconfig %s\n' % (target))
            fp.write('\tbool "[v]-%s (%s)"\n' % (item['target'], item['spath']))
            fp.write('\tdefault %s\n' % ('y' if item['default'] else 'n'))
        elif 'config' == item['vtype']:
                fp.write('config %s\n' % (target))
                if not choice_flag:
                    fp.write('\tbool "[v]-%s (%s)"\n' % (item['target'], item['spath']))
                    fp.write('\tdefault %s\n' % ('y' if item['default'] else 'n'))
                else:
                    fp.write('\tbool "[v]-%s"\n' % (item['target']))
        else:
            if not choice_flag and item['conf'] and item['conf'] != 'kconfig':
                fp.write('menuconfig %s\n' % (target))
            else:
                fp.write('config %s\n' % (target))
            if not choice_flag:
                fp.write('\tbool "%s (%s)"\n' % (item['target'], item['spath']))
                fp.write('\tdefault %s\n' % ('y' if item['default'] else 'n'))
            else:
                fp.write('\tbool "%s"\n' % (item['target']))

        deps = []
        if item['asdeps']:
            deps += ['%s%s' % (config_prepend, escape_toupper(t)) for t in item['asdeps']]
        if item['vsdeps']:
            deps += ['%s%s' % (config_prepend, escape_toupper(t)) for t in item['vsdeps']]
        if item['cdeps']:
            deps += ['!%s%s' % (config_prepend, escape_toupper(t)) for t in item['cdeps']]

        if item['wrule']:
            bracket_flag = True if deps or len(item['wrule']) > 1 or item['edeps'] else False
            for rule in item['wrule']:
                if len(rule) == 1:
                    deps.append('%s%s' % (config_prepend, escape_toupper(rule[0])))
                elif bracket_flag:
                    deps.append('(%s)' % (' || '.join(['%s%s' % (config_prepend, escape_toupper(t)) for t in rule])))
                else:
                    deps.append('%s' % (' || '.join(['%s%s' % (config_prepend, escape_toupper(t)) for t in rule])))

        if item['edeps']:
            bracket_flag = True if deps or len(item['edeps']) > 1 else False
            for dep in item['edeps']:
                if '!=' in dep:
                    env_pair = dep.split('!=')
                    env_name = env_pair[0]
                    env_vals = env_pair[1].split(',')
                    deps += ['"$(%s)"!="%s"' % (env_name, t) for t in env_vals]
                else:
                    env_pair = dep.split('=')
                    env_name = env_pair[0]
                    env_vals = env_pair[1].split(',')
                    if bracket_flag:
                        deps.append('(%s)' % (' || '.join(['"$(%s)"="%s"' % (env_name, t) for t in env_vals])))
                    else:
                        deps.append('%s' % (' || '.join(['"$(%s)"="%s"' % (env_name, t) for t in env_vals])))

        if item['src'] and not os.path.exists(item['src']):
            deps.append('%s%s' % (config_prepend, escape_toupper("src-path-existed")))
            if debug_mode:
                print('WARNING: %s: Invalid src path %s' % (item['target'], item['src']))

        if deps:
            fp.write('\tdepends on %s\n' % (' && '.join(deps)))

        if item['select']:
            for t in item['select']:
                fp.write('\tselect %s%s\n' % (config_prepend, escape_toupper(t)))
        if item['imply']:
            for t in item['imply']:
                fp.write('\timply %s%s\n' % (config_prepend, escape_toupper(t)))


        package = item['target'].replace('-native', '').replace('prebuild-', '')
        if package in self.InfoDict.keys():
            package_keys = self.InfoDict[package].keys()
            fp.write('\thelp\n')
            fp.write('\tName        : %s\n' % (self.InfoDict[package]['NAME']))
            if 'VERSION' in package_keys:
                fp.write('\tVersion     : %s\n' % (self.InfoDict[package]['VERSION']))
            if 'LICENSE' in package_keys:
                fp.write('\tLicense     : %s\n' % (self.InfoDict[package]['LICENSE']))
            if 'HOMEPAGE' in package_keys:
                fp.write('\tHomepage    : %s\n' % (self.InfoDict[package]['HOMEPAGE']))
            if 'LOCATION' in package_keys:
                fp.write('\tLocation    : %s\n' % (self.InfoDict[package]['LOCATION']))
            if 'DESCRIPTION' in package_keys:
                fp.write('\tDescription : %s\n' % (self.InfoDict[package]['DESCRIPTION'].replace('\n', '\n\t              ')))
        fp.write('\n')

        if item['conf']:
            if item['conf'] == 'kconfig':
                kconf_path,shared_targets = self.__check_shared_kconfig(item['target'])
                if shared_targets and shared_targets[-1] == item['target']:
                    conf_str = 'if %s\nmenu "%s configuration (%s)"\nsource "%s"\nendmenu\nendif\n\n' % (
                            ' || '.join(['%s%s' % (config_prepend, escape_toupper(v)) for v in shared_targets]),
                            shared_targets[0], item['spath'], kconf_path)
                    if choice_flag:
                        self.conf_str += conf_str
                    else:
                        fp.write('%s' % (conf_str))
            elif choice_flag:
                conf_str = 'if %s\nmenu "%s (%s)"\nsource "%s"\nendmenu\nendif\n\n' % (target,
                        item['target'], item['spath'], item['conf'])
                self.conf_str += conf_str
            else:
                conf_str = 'if %s\nsource "%s"\nendif\n\n' % (target, item['conf'])
                fp.write('%s' % (conf_str))

        if 'choice' in item['vtype']:
            self.gen_kconfig(fp, item['member'], True, max_depth, item['spath'])
            fp.write('endchoice\n\n')
            if self.conf_str:
                fp.write('%s\n' % (self.conf_str))
                self.conf_str = ''
        elif 'menuconfig' == item['vtype']:
            fp.write('if %s\n\n' % (target))
            self.gen_kconfig(fp, item['member'], False, max_depth, item['spath'])
            fp.write('endif\n\n')
        else:
            pass


    def gen_kconfig(self, fp, item_list, choice_flag, max_depth, prefix_str):
        if choice_flag:
            for item in item_list:
                self.__write_one_kconfig(fp, item, choice_flag, max_depth)
            return

        cur_dirs = []
        cur_depth = -1

        for item in item_list:
            depth = 0
            spath = ''
            dirs = []

            if prefix_str:
                spath = spath.replace(prefix_str + '/', '', 1)
            else:
                spath = item['spath']
            if self.keywords:
                dirs = [t for t in spath.split('/') if t not in self.keywords]
            else:
                dirs = spath.split('/')
            depth = len(dirs) - 1

            while cur_depth >= 0:
                back_flag = False
                if depth < cur_depth:
                    back_flag = True
                else:
                    for i in range(cur_depth, -1, -1):
                        if dirs[i] != cur_dirs[i]:
                            back_flag = True
                            break

                if back_flag:
                    cur_dirs.pop()
                    cur_depth -= 1
                    fp.write('endmenu\n\n')
                else:
                    break

            while depth > cur_depth + 1 and cur_depth < max_depth - 1:
                cur_depth += 1
                cur_dirs.append(dirs[cur_depth])
                fp.write('menu "%s"\n\n' % (dirs[cur_depth]))

            tmp_depth = 0
            if item['vtype']:
                tmp_depth = max_depth - cur_depth
                if tmp_depth < 0:
                    tmp_depth = 0
            self.__write_one_kconfig(fp, item, False, tmp_depth)

        while cur_depth >= 0:
            cur_dirs.pop()
            cur_depth -= 1
            fp.write('endmenu\n\n')

    def gen_info(self, filename):
        with open(filename, 'w') as fp:
            fp.write(str(self.InfoDict))

    def gen_normal_target(self, filename):
        with open(filename, 'w') as fp:
            for item in self.ActualList:
                dvars = []
                rules = []

                if item['wrule']:
                    for rule in item['wrule']:
                        rules += rule
                rules += item['select']

                if item['awdeps']:
                    awdeps = item['awdeps'][:]
                    for dep in item['awdeps']:
                        if 'prebuild-' in dep:
                            if dep.replace('prebuild-', '', 1) in item['awdeps']:
                                awdeps.remove(dep)
                            elif dep in rules:
                                self.__replace_list(awdeps, dep, '+' + dep)
                            else:
                                self.__replace_list(awdeps, dep, '?' + dep)
                        elif 'prebuild-' + dep in item['awdeps']:
                            self.__replace_list(awdeps, dep, '|' + dep)
                        elif '-unpatch-' in dep:
                            if dep.replace('-unpatch-', '-patch-', 1) in item['awdeps']:
                                awdeps.remove(dep)
                            elif dep in rules:
                                self.__replace_list(awdeps, dep, '+' + dep)
                            else:
                                self.__replace_list(awdeps, dep, '?' + dep)
                        elif '-patch-' in dep:
                            if dep.replace('-unpatch-', '-patch-', 1) in item['awdeps']:
                                self.__replace_list(awdeps, dep, '|' + dep)
                            elif dep in item['select']:
                                self.__replace_list(awdeps, dep, '+' + dep)
                            else:
                                self.__replace_list(awdeps, dep, '?' + dep)
                        else:
                            if dep in rules:
                                self.__replace_list(awdeps, dep, '+' + dep)
                            else:
                                self.__replace_list(awdeps, dep, '?' + dep)

                    for dep in awdeps:
                        if dep[0] == '+':
                            dvars.append(dep[1:])
                        else:
                            dvars.append(dep)

                if item['ideps']:
                    for dep in item['ideps']:
                        dvars.append(dep.replace('@@', '@'))

                if item['asdeps']:
                    dvars += item['asdeps']

                if dvars:
                    fp.write('%s="%s" # %s\n' % (item['target'], ' '.join(dvars), item['path']))
                else:
                    fp.write('%s="" # %s\n' % (item['target'], item['path']))


    def gen_yocto_target(self, filename):
        with open(filename, 'w') as fp:
            for item in self.PokyList + self.PokyMoved:
                fp.write('%s="" # localsrc\n' % (item['target']))
            for item in self.ActualList:
                fp.write('%s="%s" # %s\n' % (item['target'], ' '.join(item['asdeps'] + item['awdeps']), item['src']))


    def gen_make(self, filename, target_list):
        # package types
        ignore_targets  = ['unified', 'direct', 'empty']
        # special package targets
        ignore_targets += ['prepare', 'all', 'clean', 'distclean', 'install', 'release']
        # special package attributes
        ignore_targets += ['norelease', 'psysroot', 'isysroot', 'noisysroot', 'finally']
        ignore_targets += ['union', 'native', 'cache', 'url', 'singletask', 'jobserver']

        with open(filename, 'w') as fp:
            fp.write('INSTALL_OPTION ?= link\n')
            fp.write('SYSROOT_SCRIPT := $(ENV_TOOL_DIR)/process_sysroot.sh\n')
            fp.write('PREAT          ?= @\n')
            fp.write('\n')

            if self.FinallyList:
                for dep in target_list:
                    if dep not in self.FinallyList and not dep.endswith('-native'):
                        fp.write('ifeq ($(CONFIG_%s), y)\n' % (escape_toupper(dep)))
                        fp.write('finaldeps: %s\n' % (dep))
                        fp.write('endif\n')
                fp.write('.PHONY: finaldeps\n\n')

            for item in self.ActualList:
                #### process variables #####
                real_targets = [t for t in item['targets'] if t not in ignore_targets]
                ideps = [re.split(r'@+', dep)[0] for dep in item['ideps']]

                MAKEA = '$(PREAT)make $(MFLAG)'
                if 'singletask' not in item['targets']:
                    MAKEA += ' $(ENV_BUILD_JOBS)'
                MAKEB = '$(PREAT)make $(MFLAG)'

                makes = ''
                makes += ' -C $(%s-path)' % (item['target'])
                if item['make']:
                    makes += ' -f $(%s-make)' % (item['target'])

                if item['asdeps'] or item ['awdeps'] or item ['ideps']:
                    if 'psysroot' not in item['targets']:
                        if dis_gsysroot:
                            item['targets'].append('psysroot')
                        else:
                            makes += ' GLOBAL_SYSROOT=y'
                else:
                    if 'psysroot' in item['targets']:
                        item['targets'].remove('psysroot')

                if 'isysroot' in item['targets']:
                    if dis_isysroot:
                        item['targets'].remove('isysroot')

                if item['target'].endswith('-native'):
                    makes += ' NATIVE_BUILD=y'
                elif item['asdeps'] or item['awdeps'] or item ['ideps']:
                    for dep in item['asdeps'] + item['awdeps'] + ideps:
                        if dep.endswith('-native'):
                            makes += ' NATIVE_DEPEND=y'
                            break

                pkg_flags = {}
                pkg_flags['finally']  = False if item['target'] not in self.FinallyList else True
                pkg_flags['unified']  = False if 'unified' not in item['targets'] else True
                pkg_flags['empty']    = False if 'empty' not in item['targets'] else True
                pkg_flags['psysroot'] = False if 'psysroot' not in item['targets'] else True
                pkg_flags['isysroot'] = False if 'isysroot' not in item['targets'] else True
                pkg_flags['cache']    = False if 'cache' not in item['targets'] else True
                pkg_flags['url']      = False if 'url' not in item['targets'] else True
                pkg_flags['native']   = False if not item['target'].endswith('-native') else True
                pkg_flags['deps']     = False
                pkg_flags['reldeps']  = False
                pkg_flags['release']  = False if pkg_flags['native'] or pkg_flags['finally'] else True

                phony = []
                unionstr = '%s-' % (item['target']) if 'union' in item['targets'] else ''

                psysroot_target = '%s_psysroot'  % (item['target'])
                package_name = item['target']
                if package_name.endswith('-native'):
                    package_name = package_name[:-len('-native')]
                psys_make = '$(PREAT)%s -s INSTALL_OPTION=$(INSTALL_OPTION) CROSS_DESTDIR=$(ENV_CROSS_ROOT)/objects/%s/sysroot NATIVE_DESTDIR=$(ENV_NATIVE_ROOT)/objects/%s/sysroot-native' \
                            % ('make', package_name, package_name)

                gsys_dir = ''
                isys_dir = ''
                isys_cmd = ''
                if pkg_flags['native'] :
                    gsys_dir = '$(ENV_NATIVE_ROOT)/sysroot'
                    isys_dir = '$(ENV_NATIVE_ROOT)/objects/%s/image' % (item['target'].replace('-native', ''))
                    isys_cmd = '$(PREAT)$(SYSROOT_SCRIPT) $(INSTALL_OPTION) %s $(NATIVE_DESTDIR)' % (isys_dir)
                else:
                    gsys_dir = '$(ENV_CROSS_ROOT)/sysroot'
                    isys_dir = '$(ENV_CROSS_ROOT)/objects/%s/image' % (item['target'])
                    isys_cmd = '$(PREAT)$(SYSROOT_SCRIPT) $(INSTALL_OPTION) %s $(CROSS_DESTDIR)' % (isys_dir)

                gsys_make = '$(PREAT)flock %s -c "%s%s INSTALL_OPTION=$(INSTALL_OPTION) CROSS_DESTDIR=$(ENV_CROSS_ROOT)/sysroot NATIVE_DESTDIR=$(ENV_NATIVE_ROOT)/sysroot %s%s"' \
                            % (gsys_dir, MAKEA[8:], makes, unionstr, 'install')
                gsys_cmd = '$(PREAT)flock %s -c "bash $(SYSROOT_SCRIPT) $(INSTALL_OPTION) %s %s"' % (gsys_dir, isys_dir, gsys_dir)

                cache_str = ''
                if pkg_flags['cache']:
                    cache_str = '\t%s%s %s%s\n' % (MAKEA, makes, unionstr, 'checksum')

                #### process dependencies #####
                fp.write('ifeq ($(CONFIG_%s), y)\n\n' % (escape_toupper(item['target'])))
                fp.write('%s-path := %s\n' % (item['target'], item['mpath']))
                if item['make']:
                    fp.write('%s-make := %s\n' % (item['target'], item['make']))
                fp.write('%s-deps :=\n' % (item['target']))
                fp.write('%s-reldeps :=\n' % (item['target']))
                fp.write('\n')

                if item['awdeps'] or item['ideps']:
                    pkg_flags['deps'] = True
                    for dep in item['awdeps'] + item['ideps']:
                        if '@' in dep:
                            dep,cond = re.split(r'@+', dep)
                            fp.write('ifeq ($(CONFIG_%s)-$(%s), y-y)\n' % (escape_toupper(dep), cond))
                        else:
                            fp.write('ifeq ($(CONFIG_%s), y)\n' % (escape_toupper(dep)))
                        fp.write('%s-deps += %s\n' % (item['target'], dep))
                        if pkg_flags['release'] and not dep.endswith('-native'):
                            pkg_flags['reldeps'] = True
                            fp.write('%s-reldeps += %s\n' % (item['target'], dep))
                        fp.write('endif\n')
                    fp.write('\n')

                if item['asdeps']:
                    tmp_deps = item['asdeps']
                    pkg_flags['deps'] = True
                    fp.write('%s-deps += %s\n' % (item['target'], ' '.join(tmp_deps)))
                    if pkg_flags['release']:
                        tmp_deps = [dep for dep in item['asdeps'] if not dep.endswith('-native')]
                        if tmp_deps:
                            pkg_flags['reldeps'] = True
                            fp.write('%s-reldeps += %s\n' % (item['target'], ' '.join(tmp_deps)))
                    fp.write('\n')

                #### process necessary targets #####

                # psysroot_target
                phony.append(psysroot_target)
                if pkg_flags['deps']:
                    fp.write('%s: $(addsuffix _isysroot,$(%s-deps))\n\n' % (psysroot_target, item['target']))
                else:
                    fp.write('%s:\n\t@\n\n' % (psysroot_target))

                if not pkg_flags['empty'] and pkg_flags['deps'] and pkg_flags['psysroot']:
                    phony.append('%s_single' % (psysroot_target))
                    fp.write('%s_single:\n' % (psysroot_target))
                    if pkg_flags['unified'] and pkg_flags['cache']:
                        fp.write('%s\t%s%s %s%s\n\n' % (cache_str, MAKEA, makes, unionstr, 'psysroot'))
                    else:
                        fp.write('%s\t%s %s\n\n' % (cache_str, psys_make, psysroot_target))

                # all
                compile_str = '\t$(PREAT)$(if $(PGCMD),$(PGCMD) begin=$@)\n'
                if 'prepare' in item['targets']:
                    compile_str += '\t%s%s %s%s\n' % (MAKEA, makes, unionstr, 'prepare')
                compile_str += '\t%s%s%s\n' % (MAKEA.replace('@', '@$(PRECMD)', 1), makes, ' %s%s' % (unionstr, 'all') if unionstr else '')
                if pkg_flags['isysroot']:
                    compile_str += '\t$(PREAT)install -d %s\n' % (isys_dir)
                    compile_str += '\t%s%s %s%s\n' % (MAKEA, makes, unionstr, 'install')
                compile_str += '\t$(PREAT)$(if $(PGCMD),$(PGCMD) end=$@,echo "Build %s Done.")\n' % (item['target'])

                phony.append(item['target'])
                if pkg_flags['empty']:
                    if pkg_flags['deps']:
                        fp.write('%s: $(%s-deps)\n' % (item['target'], item['target']))
                    else:
                        fp.write('%s:\n' % (item['target']))
                    fp.write('\t$(PREAT)$(if $(PGCMD),$(PGCMD) begin=$@)\n')
                    fp.write('\t$(PREAT)$(if $(PGCMD),$(PGCMD) end=$@,echo "Build %s Done.")\n\n' % (item['target']))
                else:
                    if pkg_flags['finally']:
                        fp.write('%s: finaldeps\n' % (item['target']))
                    if pkg_flags['deps']:
                        if pkg_flags['psysroot']:
                            fp.write('%s: $(%s-deps)\n' % (item['target'], item['target']))
                            if pkg_flags['unified'] and pkg_flags['cache']:
                                fp.write('%s\t%s%s %s%s\n' % (cache_str, MAKEA, makes, unionstr, 'psysroot'))
                            else:
                                fp.write('%s\t%s %s\n' % (cache_str, psys_make, psysroot_target))
                            fp.write('%s\n' % (compile_str))
                        else:
                            fp.write('%s: $(addsuffix _install,$(%s-deps))\n' % (item['target'], item['target']))
                            fp.write('%s%s\n' % (cache_str, compile_str))

                        phony.append('%s_single' % (item['target']))
                        fp.write('%s_single:\n' % (item['target']))
                    elif pkg_flags['finally']:
                        phony.append('%s_single' % (item['target']))
                        fp.write('%s %s_single:\n' % (item['target'], item['target']))
                    else:
                        fp.write('%s:\n' % (item['target']))
                    fp.write('%s%s\n' % (cache_str, compile_str))

                # install
                phony.append(item['target'] + '_install')
                phony.append(item['target'] + '_install_single')
                fp.write('%s_install: %s $(addsuffix _install,$(%s-deps))\n' % (item['target'], item['target'], item['target']))
                fp.write('%s_install %s_install_single:\n' % (item['target'], item['target']))
                if pkg_flags['empty']:
                    fp.write('\t@\n\n')
                else:
                    fp.write('\t$(PREAT)install -d %s\n' % (gsys_dir))
                    if pkg_flags['isysroot']:
                        fp.write('\t%s\n\n' % (gsys_cmd))
                    else:
                        fp.write('\t%s\n\n' % (gsys_make))

                # isysroot
                phony.append(item['target'] + '_isysroot')
                if pkg_flags['deps']:
                    fp.write('%s_isysroot: %s\n' % (item['target'], psysroot_target))
                else:
                    fp.write('%s_isysroot:\n' % (item['target']))
                if pkg_flags['empty']:
                    fp.write('\t@\n\n')
                else:
                    if pkg_flags['isysroot']:
                        fp.write('\t%s\n\n' % (isys_cmd))
                    else:
                        fp.write('\t%s%s %s%s\n\n' % (MAKEB, makes, unionstr, 'install'))

                # release
                if pkg_flags['release']:
                    phony.append(item['target'] + '_release')
                    release = 'release' if 'release' in item['targets'] else 'install'
                    if pkg_flags['reldeps']:
                        fp.write('%s_release: $(addsuffix _release,$(%s-reldeps))\n' % (item['target'], item['target']))
                    else:
                        fp.write('%s_release:\n' % (item['target']))
                    if 'norelease' in item['targets']:
                        fp.write('\t@\n\n')
                    else:
                        fp.write('\t$(PREAT)echo "    %s" >&2 \n' % (item['target']))
                        if pkg_flags['isysroot']:
                            fp.write('\t%s\n\n' % (isys_cmd.replace('$(INSTALL_OPTION)', 'release', 1)))
                        else:
                            fp.write('\t%s%s %s%s\n\n' % (MAKEA, makes, unionstr, release))

                # clean distclean
                phony.append(item['target'] + '_clean')
                fp.write('%s_clean:\n' % (item['target']))
                if pkg_flags['empty']:
                    fp.write('\t@\n\n')
                else:
                    fp.write('\t%s%s %s%s\n\n' % (MAKEB, makes, unionstr, 'clean'))
                if 'distclean' in item['targets']:
                    phony.append(item['target'] + '_distclean')
                    fp.write('%s_distclean:\n' % (item['target']))
                    fp.write('\t%s%s %s%s\n\n' % (MAKEB, makes, unionstr, 'distclean'))

                # cache
                if 'cache' in item['targets']:
                    phony.append(item['target'] + '_setforce')
                    phony.append(item['target'] + '_set1force')
                    phony.append(item['target'] + '_unsetforce')
                    fp.write('%s_setforce %s_set1force %s_unsetforce:\n' % \
                            (item['target'], item['target'], item['target']))
                    fp.write('\t%s%s $(patsubst %s_%%,%%,$@)\n\n' % (MAKEB, makes, item['target']))

                if 'url' in item['targets']:
                    phony.append(item['target'] + '_dofetch')
                    phony.append(item['target'] + '_status')
                    phony.append(item['target'] + '_setdev')
                    phony.append(item['target'] + '_unsetdev')
                    fp.write('%s_dofetch %s_status %s_setdev %s_unsetdev:\n' % \
                            (item['target'], item['target'], item['target'], item['target']))
                    fp.write('\t%s%s $(patsubst %s_%%,%%,$@)\n\n' % (MAKEB, makes, item['target']))


                #### process other targets #####
                other_targets = []
                tmp_targets = [t for t in real_targets if ':' not in t]
                if tmp_targets:
                    other_targets.append([tmp_targets, True])
                for tmp_targets in [t for t in real_targets if ':' in t]:
                    pairs = tmp_targets.split('::')
                    other_targets.append([pairs[0].split(':'), pairs[1].split(':') if pairs[1] else []])

                for targets in other_targets:
                    sub_targets = []
                    tmp_targets = ['%s_%s' % (item['target'], t) for t in targets[0] if '%' not in t]
                    if tmp_targets:
                        sub_targets.append(tmp_targets)
                    tmp_targets = ['%s_%s' % (item['target'], t) for t in targets[0] if '%' in t]
                    if tmp_targets:
                        sub_targets += tmp_targets

                    for tmp_targets in sub_targets:
                        targets_depstr = ''
                        targets_psysroot = ''
                        if isinstance(targets[1], bool):
                            if pkg_flags['deps']:
                                if pkg_flags['psysroot']:
                                    targets_depstr = '$(%s-deps)' % (item['target'])
                                    targets_psysroot = psysroot_target
                                else:
                                    targets_depstr = '$(addsuffix _install,$(%s-deps))' % (item['target'])
                        else:
                            if targets[1]:
                                if pkg_flags['psysroot']:
                                    targets_depstr = ' '.join(targets[1])
                                    targets_psysroot = '%s-sub-%s_psysroot' % (item['target'], '-'.join(targets[1]))
                                    phony.append(targets_psysroot)
                                    fp.write('%s: $(addsuffix _isysroot,%s)\n\n' % (targets_psysroot, targets_depstr))
                                else:
                                    targets_depstr = ' '.join(['%s_install' % (t) for t in targets[1]])

                        if isinstance(tmp_targets, list):
                            phony += tmp_targets

                        if targets_depstr:
                            if isinstance(tmp_targets, list):
                                fp.write('%s: %s\n' % (' '.join(tmp_targets), targets_depstr))
                            else:
                                fp.write('%s: %s\n' % (tmp_targets, targets_depstr))
                            if pkg_flags['psysroot']:
                                if pkg_flags['unified'] and pkg_flags['cache'] and isinstance(targets[1], bool):
                                    fp.write('\t%s%s %s%s\n' % (MAKEA, makes, unionstr, 'psysroot'))
                                else:
                                    fp.write('\t%s %s\n' % (psys_make, targets_psysroot))
                            fp.write('\t%s%s $(patsubst %s_%%,%%,$@)\n\n' % (MAKEA, makes, item['target']))

                            if isinstance(tmp_targets, list):
                                single_targets = ['%s_single' % (t) for t in tmp_targets]
                                phony += single_targets
                                fp.write('%s:\n' % (' '.join(single_targets)))
                            else:
                                fp.write('%s_single:\n' % (tmp_targets))
                            fp.write('\t%s%s $(patsubst %s_%%,%%,$(patsubst %%_single,%%,$@))\n\n' % (MAKEA, makes, item['target']))
                        else:
                            if isinstance(tmp_targets, list):
                                fp.write('%s:\n' % (' '.join(tmp_targets)))
                            else:
                                fp.write('%s:\n' % (tmp_targets))
                            fp.write('\t%s%s $(patsubst %s_%%,%%,$@)\n\n' % (MAKEA, makes, item['target']))

                #### system level variables #####
                if pkg_flags['finally']:
                    fp.write('ALL_TARGETS  += %s_install\n' % (item['target']))
                else:
                    fp.write('ALL_TARGETS  += %s\n' % (item['target']))
                if 'cache' in item['targets']:
                    fp.write('ALL_CACHES   += %s\n' % (item['target']))
                if 'url' in item['targets']:
                    fp.write('ALL_FETCHES  += %s_dofetch\n' % (item['target']))
                    fp.write('ALL_STATUSES += %s_status\n' % (item['target']))
                if pkg_flags['release']:
                    fp.write('ALL_RELEASES += %s_release\n' % (item['target']))
                fp.write('ALL_CLEANS   += %s_clean\n' % (item['target']))
                fp.write('.PHONY: %s\n\n' % (' '.join(phony)))
                fp.write('else\n\n')

                fp.write('%s:\n' % (item['target']))
                fp.write('\t$(PREAT)echo "%s is not enabled!" >&2 && exit 1\n\n' % (item['target']))
                fp.write('%s_%%:\n' % (item['target']))
                fp.write('\t$(PREAT)echo "%s is not enabled!" >&2 && exit 1\n\n' % (item['target']))
                fp.write('.PHONY: %s\n\n' % (item['target']))
                fp.write('endif\n\n')

            fp.write('%s: %s\n\n' % ('all_targets',  '$(ALL_TARGETS)'))
            fp.write('%s: %s\n\n' % ('all_caches',   '$(ALL_CACHES)'))
            fp.write('%s: %s\n\n' % ('all_fetches',  '$(ALL_FETCHES)'))
            fp.write('%s: %s\n'   % ('all_statuses',  'export MFLAG ?= -s'))
            fp.write('%s: %s\n\n' % ('all_statuses',  '$(ALL_STATUSES)'))
            fp.write('%s: %s\n\n' % ('all_releases', '$(ALL_RELEASES)'))
            fp.write('%s: %s\n\n' % ('all_cleans',   '$(ALL_CLEANS)'))
            fp.write('.PHONY: all_targets all_caches all_fetches all_releases all_cleans\n\n')


    def __replace_list(self, rlist, ori, rep):
        for i in range(len(rlist)):
            if rlist[i] == ori:
                rlist[i] = rep
                break


def parse_options():
    parser = ArgumentParser( description='''
            Tool to generate build chain.
            do_normal_analysis must set options (-m -k -d -s) and can set options (-v -c -t -i -g -l -w -p -u).
            do_yocto_analysis must set options (-t -k) and can set options (-v -c -i -l -w -p -u).
            do_image_analysis must set options (-o -t -c) and can set options (-i -p).
            ''')

    parser.add_argument('-m', '--makefile',
            dest='makefile_out',
            help='Specify the output Makefile path.')

    parser.add_argument('-o', '--image',
            dest='image_out',
            help='Specify the output image recipe path.')

    parser.add_argument('-k', '--kconfig',
            dest='kconfig_out',
            help='Specify the path to store Kconfig items.')

    parser.add_argument('-t', '--target',
            dest='target_out',
            help='Specify the out target file path to store package names.')

    parser.add_argument('-d', '--dep',
            dest='dep_name',
            help='Specify the search dependence filename.')

    parser.add_argument('-c', '--conf',
            dest='conf_name',
            help='Specify the search config filename or .config path.')

    parser.add_argument('-v', '--virtual',
            dest='vir_name',
            help='Specify the virtual dependence filename.')

    parser.add_argument('-s', '--search',
            dest='search_dirs',
            help='Specify the search directories.')

    parser.add_argument('-i', '--ignore',
            dest='ignore_dirs',
            help='Specify the ignore directories.')

    parser.add_argument('-g', '--go-on',
            dest='go_on_dirs',
            help='Specify the go on directories.')

    parser.add_argument('-u', '--usermeta',
            dest='user_metas',
            help='Specify the user metas whose recipes will be selected by default (Yocto Build);' + '\n' +
            'Specify the packages which do not have native-compilation when they are dependencies of native package (Normal Build)')

    parser.add_argument('-l', '--maxlayer',
            dest='max_depth',
            help='Specify the max layer depth for menuconfig')

    parser.add_argument('-w', '--keyword',
            dest='keywords',
            help='Specify the filter keywords to decrease menuconfig depth')

    parser.add_argument('-p', '--prepend',
            dest='prepend_flag',
            help='Specify the prepend CONFIG_ in items of kconfig_out or path to store patch/unpatch recipe list')

    args = parser.parse_args()
    analysis_choice = ''
    success_flag = True

    if args.makefile_out:
        analysis_choice = 'normal'
        if not args.kconfig_out or not args.dep_name or not args.search_dirs:
            success_flag = False
    elif args.image_out:
        analysis_choice = 'image'
        if not args.target_out or not args.conf_name:
            success_flag = False
    elif args.target_out:
        analysis_choice = 'yocto'
        if not args.kconfig_out:
            success_flag = False
    else:
        success_flag = False

    if not success_flag:
        print('\033[31mERROR: Invalid parameters.\033[0m\n')
        parser.print_help()
        sys.exit(1)

    return (args, analysis_choice)


def do_normal_analysis(args):
    makefile_out = args.makefile_out
    info_out = os.path.join(os.path.dirname(args.makefile_out), 'info.txt')
    kconfig_out = args.kconfig_out
    target_out = args.target_out
    dep_name = args.dep_name
    conf_name = args.conf_name
    vir_name = ''
    if args.vir_name:
        vir_name = args.vir_name

    search_dirs = [s.strip() for s in args.search_dirs.split(':')]
    ignore_dirs = []
    if args.ignore_dirs:
        ignore_dirs = [s.strip() for s in args.ignore_dirs.split(':')]
    go_on_dirs = []
    if args.go_on_dirs:
        go_on_dirs = [s.strip() for s in args.go_on_dirs.split(':')]

    uni_packages = []
    if args.user_metas:
        uni_packages = [s.strip() for s in args.user_metas.split(':')]

    max_depth = 0
    if args.max_depth:
        max_depth = int(args.max_depth)

    keywords = []
    if args.keywords:
        keywords = [s.strip() for s in args.keywords.split(':')]

    prepend_flag = 0
    if args.prepend_flag:
        prepend_flag = int(args.prepend_flag)

    deps = Deps()
    deps.conf_name = conf_name
    deps.uni_packages = uni_packages
    deps.keywords = keywords
    deps.prepend_flag = prepend_flag

    deps.RegexDict['VDEPS'] = re.compile(r'#VDEPS\s*\(\s*(\w+)\s*\)\s*([\w\-]+)\s*\(([\s\w\-\./]*)\)\s*:([\s\w\\\|\-\.\?\*&!=,]*)')
    deps.RegexDict['DEPS'] = re.compile(r'#DEPS\s*\(\s*([\w\-\./${}]*)\s*\)\s*([\w\-\.]+)\s*\(([\s\w\-\.%:]*)\)\s*:([\s\w\\\|\-\.\?\*&!=,@]*)')
    deps.RegexDict['INCDEPS'] = re.compile(r'#INCDEPS\s*:\s*([\s\w\\\-\./${}]+)')
    deps.RegexDict['CACHE'] = re.compile(r'CACHE_BUILD\s*[\?:]*=\s*y')
    deps.RegexDict['URL'] = re.compile(r'SRC_URL\s*[\?:]*=.*')
    deps.RegexDict['INCRULE'] = re.compile(r'include\s+.*inc\.rule\.mk')
    deps.RegexDict['PACKAGE'] = re.compile(r'PACKAGE_NAME\s*[\?:]*=\s*([\w\-\.]+)')
    deps.RegexDict['VARS'] = re.compile(r'(\w+)\s*[\?:]*=\s*(.+)')

    deps.search_normal_depends(dep_name, vir_name, search_dirs, ignore_dirs, go_on_dirs)
    if not deps.PathList:
        print('ERROR: can not find any %s in %s.' % (dep_name, ':'.join(search_dirs)))
        sys.exit(1)

    refs = []
    for pathpair in deps.PathList:
        deps.add_normal_item(pathpair, dep_name, refs)
    if not deps.ItemList:
        print('ERROR: can not find any targets in %s in %s.' % (dep_name, ':'.join(search_dirs)))
        sys.exit(1)

    target_list = [item['target'] for item in deps.ActualList] \
                + [item['target'] for item in deps.VirtualList if 'choice' not in item['vtype']]
    deps.check_item(deps.ItemList, target_list)
    if debug_mode:
        deps.check_repeat_package()

    with open(kconfig_out, 'w') as fp:
        fp.write('mainmenu "Build Configuration"\n\n')
        deps.gen_kconfig(fp, deps.ItemList, False, max_depth, '')
    print('\033[32mGenerate %s OK.\033[0m' % kconfig_out)

    target_list = [item['target'] for item in deps.ActualList]
    if target_out:
        deps.gen_normal_target(target_out)
        print('\033[32mGenerate %s OK.\033[0m' % target_out)

    if debug_mode:
        if deps.check_circular_dep(target_list) == -1:
            print('ERROR: check_circular_dep() failed.')
            sys.exit(1)

    deps.gen_make(makefile_out, target_list)
    print('\033[32mGenerate %s OK.\033[0m' % makefile_out)

    deps.gen_info(info_out)
    print('\033[32mGenerate %s OK.\033[0m' % info_out)


def do_yocto_analysis(args):
    kconfig_out = args.kconfig_out
    target_out = args.target_out
    conf_name = args.conf_name
    vir_name = ''
    if args.vir_name:
        vir_name = args.vir_name

    ignore_dirs = []
    if args.ignore_dirs:
        ignore_dirs = [s.strip() for s in args.ignore_dirs.split(':')]

    user_metas = []
    if args.user_metas:
        user_metas = [s.strip() for s in args.user_metas.split(':')]

    max_depth = 0
    if args.max_depth:
        max_depth = int(args.max_depth)

    keywords = []
    if args.keywords:
        keywords = [s.strip() for s in args.keywords.split(':')]

    prepend_flag = 0
    if args.prepend_flag:
        prepend_flag = int(args.prepend_flag)

    deps = Deps()
    deps.conf_name = conf_name
    deps.user_metas = user_metas
    deps.keywords = keywords
    deps.prepend_flag = prepend_flag
    deps.yocto_flag = True

    deps.RegexDict['VDEPS'] = re.compile(r'#VDEPS\s*\(\s*(\w+)\s*\)\s*([\w\-]+)\s*\(([\s\w\-\./]*)\)\s*:([\s\w\\\|\-\.\?\*&!=,]*)')
    deps.RegexDict['DEPENDS'] = re.compile(r'DEPENDS\s*\+?=\s*"(.*)"')
    deps.RegexDict['EXTRADEPS'] = re.compile(r'EXTRADEPS\s*\+?=\s*"(.*)"')
    deps.RegexDict['EXTERNALSRC'] = re.compile(r'EXTERNALSRC\s*=\s*"(.*)"')

    deps.get_env_vars('conf/local.conf')
    search_dirs = deps.get_search_dirs('conf/bblayers.conf')
    if not search_dirs:
        print('ERROR: can not find any metas in %s.' % ('conf/bblayers.conf'))
        sys.exit(1)

    deps.search_yocto_depends(vir_name, search_dirs, ignore_dirs)
    if not deps.PathList and not deps.PokyList:
        print('ERROR: can not find any recipes in %s.' % (':'.join(search_dirs)))
        sys.exit(1)

    refs = []
    for pathpair in deps.PathList:
        deps.add_yocto_item(pathpair, refs)
    target_list = [item['target'] for item in deps.ActualList] \
                + [item['target'] for item in deps.VirtualList if 'choice' not in item['vtype']]
    poky_list = [item['target'] for item in deps.PokyList]
    deps.check_item(deps.ItemList, target_list, poky_list)

    with open(kconfig_out, 'w') as fp:
        fp.write('mainmenu "Build Configuration"\n\n')
        if deps.PokyList:
            deps.gen_kconfig(fp, deps.PokyList, False, max_depth, '')
        if deps.ItemList:
            deps.gen_kconfig(fp, deps.ItemList, False, max_depth, '')
    deps.gen_yocto_target(target_out)
    print('\033[32mGenerate %s OK.\033[0m' % kconfig_out)


def do_image_analysis(args):
    target_out = args.target_out
    conf_name = args.conf_name
    image_out = args.image_out
    patch_out = args.prepend_flag
    ignore_recipes = []
    if args.ignore_dirs:
        ignore_recipes = [s.strip() for s in args.ignore_dirs.split(':')]

    regex = re.compile(r'CONFIG_(.*)=y')
    recipe_list = []
    config_list = []

    with open(target_out, 'r') as rfp:
        for per_line in rfp.read().splitlines():
            recipe = per_line.split('=')[0].strip()
            recipe_list.append(recipe)

    with open(conf_name, 'r') as rfp:
        for per_line in rfp.read().splitlines():
            ret = regex.match(per_line)
            if ret:
                item = escape_tolower(ret.groups()[0])
                if item in recipe_list:
                    config_list.append(item)

    with open(image_out, 'w') as wfp:
        wfp.write('IMAGE_INSTALL:append = " \\\n')
        for item in config_list:
            if item not in ignore_recipes:
                wfp.write('\t\t\t%s \\\n' % item)
        wfp.write('\t\t\t"\n')
    print('\033[32mGenerate %s OK.\033[0m' % image_out)

    if patch_out:
        with open(patch_out, 'w') as wfp:
            wfp.write('DEPENDS += " \\\n')
            for item in config_list:
                if '-patch-' in item or '-unpatch-' in item:
                    wfp.write('\t\t\t%s \\\n' % item)
            wfp.write('\t\t\t"\n')
        print('\033[32mGenerate %s OK.\033[0m' % patch_out)


if __name__ == '__main__':
    args, analysis_choice = parse_options()
    if 'normal' == analysis_choice:
        do_normal_analysis(args)
    elif 'yocto' == analysis_choice:
        do_yocto_analysis(args)
    else:
        do_image_analysis(args)

