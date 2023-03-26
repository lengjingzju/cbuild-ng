############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

import sys, os, re
from argparse import ArgumentParser

def escape_tolower(var):
    return var.lower().replace('_', '-').replace('__dot__', '.').replace('__plus__', '+')


def parse_options():
    parser = ArgumentParser( description='''
            Tool to generate license information file.
            ''')

    parser.add_argument('-c', '--conf',
            dest='conf_file',
            help='Specify the .config file path.')

    parser.add_argument('-i', '--info',
            dest='info_file',
            help='Specify the information file path.')

    parser.add_argument('-o', '--out',
            dest='out_file',
            help='Specify the output file path.')

    args = parser.parse_args()
    if not args.conf_file or not args.info_file or not args.out_file:
        print('\033[31mERROR: Invalid parameters.\033[0m\n')
        parser.print_help()
        sys.exit(1)

    return args


def gen_license(args):
    configs = []
    with open( args.conf_file, 'r') as fp:
        for per_line in fp.read().splitlines():
            ret = re.match(r'CONFIG_(.*)=y', per_line)
            if ret:
                configs.append(escape_tolower(ret.groups()[0]))

    infos = {}
    with open(args.info_file, 'r') as fp:
        infos = eval(fp.read())

    if not configs or not infos:
        return

    with open(args.out_file, 'w') as fp:
        for package in sorted(infos):
            package_keys = infos[package].keys()
            if package not in configs or 'LICENSE' not in package_keys:
                continue

            fp.write('Name        : %s\n' % (infos[package]['NAME']))
            fp.write('License     : %s\n' % (infos[package]['LICENSE']))
            if 'VERSION' in package_keys:
                fp.write('Version     : %s\n' % (infos[package]['VERSION']))
            if 'HOMEPAGE' in package_keys:
                fp.write('Homepage    : %s\n' % (infos[package]['HOMEPAGE']))
            if 'LOCATION' in package_keys:
                fp.write('Location    : %s\n' % (infos[package]['LOCATION']))
            if 'DESCRIPTION' in package_keys:
                fp.write('Description : %s\n' % (infos[package]['DESCRIPTION'].replace('\n', '\n              ')))
            fp.write('\n')
    print('\033[32mGenerate %s OK.\033[0m' % args.out_file)


if __name__ == '__main__':
    args = parse_options()
    gen_license(args)
