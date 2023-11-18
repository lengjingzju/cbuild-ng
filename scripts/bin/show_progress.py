############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

import os, sys, socket, signal

port_dir = os.getenv('ENV_CFG_ROOT')
port_file = os.path.join(port_dir, 'pg.port')

def signal_handler(signum, frame):
    do_stop()

def do_start():
    count = 0
    total = 0
    port  = 0
    jobs = []
    flag = False

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(1)
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]

    with open(port_file, 'w') as fp:
        fp.write('%d' % (port))

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGHUP, signal_handler)

    while True:
        data = ''
        job = ''

        try:
            data, addr = s.recvfrom(1024)
            data = data.decode()
        except:
            portf = 0
            if os.path.exists(port_file):
                with open(port_file, 'r') as fp:
                    portf = int(fp.read())
            if port != portf:
                print('progress socket(port=%d) exit!' % (port))
                break
            else:
                if jobs and jobs[0] != 'rootfs':
                    if flag:
                        info = 'jobs(%d): %s' % (len(jobs), ' '.join(jobs))
                        if len(info) > 77:
                            info = info[:77] + '...'
                        print('\033[44m%s\033[0m\r' % (info), end='', flush=True)
                    else:
                        print('%s\r' % (' ' * 80), end='', flush=True)
                    flag = not flag
                continue

        if data == 'stop':
            break
        elif data[:6] == 'total=':
            total = int(data[6:])
        elif data[:6] == 'begin=':
            job = data[6:].replace('_single', '')
            jobs.append(job)
        elif data[:4] == 'end=':
            job = data[4:].replace('_single', '')
            jobs.remove(job)

            if total == 0:
                continue
            if count < total:
                count += 1
            percent = count * 100 // total

            progress = ''
            if percent == 0:
                progress = '[%2d%%]%s' % (percent, ' ' * 50)
            elif percent == 100:
                progress = '[%3d%%]\033[42m%s\033[0m' % (percent, ' ' * 50)
            else:
                progress = '[%2d%%]\033[42m%s\033[0m%s' % (percent,
                    ' ' * (percent // 2), ' ' * (50 - percent // 2))
            print('%s[%3d/%3d] %s' % (progress, count, total, job))

    s.close()


def send_msg(port, data):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.sendto(data.encode(), ('127.0.0.1', port))
    s.close()


def do_stop():
    if os.path.exists(port_file):
        with open(port_file, 'r') as fp:
            send_msg(int(fp.read()), 'stop')
        os.remove(port_file)


if __name__ == '__main__':
    if sys.argv[1] == 'start':
        do_stop()
        do_start()
    elif sys.argv[1] == 'stop':
        do_stop()
    else:
        send_msg(int(sys.argv[1]), sys.argv[2])

