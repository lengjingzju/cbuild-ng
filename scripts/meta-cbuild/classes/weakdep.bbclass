############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

python() {
    import re

    dotconfig = os.path.join(d.getVar('TOPDIR'), 'config', '.config')
    extradeps = d.getVar('EXTRADEPS').split()
    weakdeps = []
    weakrdeps = []
    appenddeps = []
    appendrdeps = []
    ideps = []

    for dep in extradeps:
        if dep[0] == '&' or dep[0] == '?':
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

                    for subdep in subdeps:
                        if subdep[0] != '*':
                            weakdeps.append(subdep)
                            if split_str == '||':
                                weakrdeps.append(subdep)

            if que_num == 2:
                weakdeps.append(dep)
                weakrdeps.append(dep)
            elif que_num == 1:
                weakdeps.append(dep)
            else:
                pass

        elif '|' in dep:
            split_str = '||' if '||' in dep else '|'
            subdeps = dep.split(split_str)
            if not subdeps[0]:
                subdeps[0] = 'prebuild-' + subdeps[1]
            weakdeps += subdeps
            if split_str == '||':
                weakrdeps += subdeps

        elif '@' in dep:
            ideps.append(dep)

    if os.path.exists(dotconfig):
        all_lines = []
        with open(dotconfig, 'r') as fp:
            all_lines = fp.read().splitlines()

        for dep in weakdeps:
            depname = dep.replace('.', '__dot__').replace('+', '__plus__').replace('-', '_').upper()
            for per_line in all_lines:
                ret = re.match(r'CONFIG_%s=y' % (depname), per_line)
                if ret:
                    appenddeps.append(dep)
                    if dep in weakrdeps:
                        appendrdeps.append(dep)
                    break

        for idep in ideps:
            matched = 0
            dep,condition = re.split(r'@+', idep)
            depname = dep.replace('.', '__dot__').replace('+', '__plus__').replace('-', '_').upper()
            for per_line in all_lines:
                ret = re.match(r'CONFIG_%s=y' % (depname), per_line)
                if ret:
                    matched += 1
                ret = re.match(r'%s=y' % (condition), per_line)
                if ret:
                    matched += 1

                if matched == 2:
                    appenddeps.append(dep)
                    if '@@' in idep:
                        appendrdeps.append(dep)
                    break

    if appenddeps:
        d.appendVar('DEPENDS', ' %s' % (' '.join(appenddeps)))
    if appendrdeps:
        d.appendVar('RDEPENDS:%s' % (d.getVar('PN')), ' %s' % (' '.join(appendrdeps)))
}
