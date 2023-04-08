import os, sys, socket

port_dir = os.getenv('ENV_CFG_ROOT')
port_file = os.path.join(port_dir, 'pg.port')

def do_start():
    count = 0
    total = 0

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(('127.0.0.1', 0))
    with open(port_file, 'w') as fp:
        fp.write('%d' % (s.getsockname()[1]))

    while True:
        data, addr = s.recvfrom(1024)
        data = data.decode()

        if data == 'stop':
            break
        elif data[:6] == 'total=':
            total = int(data[6:])

        if total == 0:
            continue
        if count < total:
            count += 1
        percent = count * 100 // total
        print("[%3d%%]%-100s[%3d/%3d] %s" % (percent, '#' * percent, count, total, data.replace('_single', '')))

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
