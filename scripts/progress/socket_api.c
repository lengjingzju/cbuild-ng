/*******************************************
* SPDX-License-Identifier: MIT             *
* Copyright (C) 2023-.... Jing Leng        *
* Contact: Jing Leng <lengjingzju@163.com> *
* https://github.com/lengjingzju/cbuild-ng *
*******************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include "socket_api.h"
#include "jlog.h"

#define IPV4_ADDR_LEN    32

/* 设置O_NONBLOCK(非阻塞模式)，读取不到数据时会立即返回-1，并且设置errno为EAGAIN */
int sfd_nonblock_set(int sfd)
{
    int flags = fcntl(sfd, F_GETFL, 0);

    return fcntl(sfd, F_SETFL, flags | O_NONBLOCK);
}

/* 设置connect/send/sendto的超时 */
int send_timeout_set(int sfd, int sec, long usec)
{
    struct timeval timeout;

    timeout.tv_sec = sec;
    timeout.tv_usec = usec;
    if (setsockopt(sfd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout)) < 0) {
        LLOG_ERRNO("fd=%d\n", sfd);
        return -1;
    }

    return 0;
}

/* 设置accept/recv/recvfrom的超时 */
int recv_timeout_set(int sfd, int sec, long usec)
{
    struct timeval timeout;

    timeout.tv_sec = sec;
    timeout.tv_usec = usec;
    if (setsockopt(sfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) < 0) {
        LLOG_ERRNO("fd=%d\n", sfd);
        return -1;
    }

    return 0;
}

/*
 * 设置SO_REUSEADDR
 * 作用:
 * 1. 重启服务时，即使以前建立的相同本地端口的连接仍存在(TIME_WAIT)，bind也不出错
 * 2. 允许bind相同的端口，只要ip不同即可
 * 3. 允许udp多播绑定相同的端口和ip
 * TIME_WAIT状态存在的理由:
 * 1. 可靠地实现TCP全双工连接的终止
 * 2. 允许老的重复分节在网络中消逝
 */
int so_reuseaddr_set(int sfd)
{
    int optval = 1;

    if (setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval)) < 0) {
        LLOG_ERRNO("fd=%d\n", sfd);
        return -1;
    }

    return 0;
}

/* TCP主动关闭的一方资源会延时释放，设置so_linger，主动关闭会立即释放资源
 * socket或accept后调用，正常关闭时主动关闭的这端有2MSL状态
 * // l_linger, "posix: The unit is 1 sec"; "bsd: The unit is 1 tick(10ms)"
 * l_onoff  l_linger  closesocket行为         发送队列          超时行为
 *   0         /      立即返回                保持直到发送完成  系统接管套接字并保证将数据发送到对端
 *   1         0      立即返回                直接丢弃          直接发送RST包，自身立即复位，跳过TIMEWAIT, 不用经过2MSL状态，对端收到RST错误
 *                                                              (Linux上只有可能只有在丢弃数据时才发送RST)
 *   1         >0     阻塞直到发送完成或超时  超时内超时发送    超时内发送成功正常关闭(FIN-ACK-FIN-ACK四次握手关闭)
 *                    (sfd需要设置为阻塞)  超时后直接丢弃    超时后同RST, 错误号 EWOULDBLOCK
 */
int tcp_nolinger_set(int sfd)
{
    struct linger so_linger;

    so_linger.l_onoff = 1;
    so_linger.l_linger = 0;
    if (setsockopt(sfd, SOL_SOCKET, SO_LINGER, &so_linger, sizeof(so_linger)) < 0) {
        LLOG_ERRNO("fd=%d\n", sfd);
        return -1;
    }

    return 0;
}

/* 启动TCP_NODELAY，就意味着禁用了Nagle算法，允许小包立即发送 */
int tcp_nodelay_set(int sfd)
{
    int optval = 1;

    if (setsockopt(sfd, IPPROTO_TCP, TCP_NODELAY, &optval, sizeof(optval)) < 0) {
        LLOG_ERRNO("fd=%d\n", sfd);
        return -1;
    }

    return 0;
}

/*
 * 判断TCP连接对端是否断开的方法有以下几种:
 * 1. select()测试到sfd可读，但read/recv读取返回的长度为0，并且(errno != EINTR)，对端TCP连接已经断开
 * 2. 向对方send发送数据，返回-1，并且(errno != EAGAIN || errno != EINTR)
 * 3. 判断TCP的状态，如函数tcp_connected_check
 * 4. 启用TCP心跳检测
 * 5. 使用自定义超时检测，一段时间没有数据交互就关闭，tcp_heart_beat_set
 */
int tcp_connected_check(int sfd)
{
    int flag = -1;
    struct tcp_info info;
    socklen_t len = sizeof(info);

    memset(&info, 0, sizeof(info));
    getsockopt(sfd, IPPROTO_TCP, TCP_INFO, &info, (socklen_t *)&len);
    flag = (info.tcpi_state == TCP_ESTABLISHED) ? 0 : -1;

    return flag;
}

/*
 * 启用TCP心跳检测，设置后，若断开，则在使用该socket读写时立即失败，并返回ETIMEDOUT错误
 * keep_idle: 如该连接在keep_idle秒内没有任何数据往来,则进行探测
 * keep_interval: 探测时发包的时间间隔为keep_interval秒
 * keep_count: 探测尝试的次数keep_count(如果第1次探测包就收到响应了,则后2次的不再发)
 */
int tcp_heart_beat_set(int sfd, int keep_idle, int keep_interval, int keep_count)
{
    int keep_alive = 1; // 开启keepalive属性
    setsockopt(sfd, SOL_SOCKET, SO_KEEPALIVE, (void *)&keep_alive, sizeof(int));
    setsockopt(sfd, SOL_TCP, TCP_KEEPIDLE, (void *)&keep_idle, sizeof(int));
    setsockopt(sfd, SOL_TCP, TCP_KEEPINTVL, (void *)&keep_interval, sizeof(int));
    setsockopt(sfd, SOL_TCP, TCP_KEEPCNT, (void *)&keep_count, sizeof(int));
    return 0;
}

/* 从 addr + port 填写sockaddr_in结构*/
int ipv4_addr_fill(struct sockaddr_in *serv, const char *addr, unsigned short port)
{
    memset(serv, 0, sizeof(struct sockaddr_in));
    serv->sin_family = AF_INET;
    serv->sin_port = htons(port);
    if (!addr || !addr[0] || (strlen(addr) == 1 && *addr == '0')) {
        serv->sin_addr.s_addr = htonl(INADDR_ANY);
    } else {
        if (inet_pton(AF_INET, addr, &serv->sin_addr) <= 0) {
            LLOG_ERRNO("addr=%s, port=%d\n", addr, port);
            return -1;
        }
    }

    return 0;
}

int ipv4_addr_parse(struct sockaddr_in *serv, char *addr, unsigned short *port)
{
    if (addr) {
        inet_ntop(AF_INET, &serv->sin_addr, addr, IPV4_ADDR_LEN);
    }
    if (port)
        *port = ntohs(serv->sin_port);

    return 0;
}

int ipv4_sockaddr_get(int sfd, char *addr, unsigned short *port)
{
    struct sockaddr_in serv;
    socklen_t len = sizeof(struct sockaddr_in);

    if (getsockname(sfd, (struct sockaddr *)&serv, &len)) {
        LLOG_ERRNO("\n");
        return -1;
    }

    if (addr) {
        inet_ntop(AF_INET, &serv.sin_addr, addr, IPV4_ADDR_LEN);
    }
    if (port) {
        *port = ntohs(serv.sin_port);
    }

    return 0;
}

int ipv4_peeraddr_get(int sfd, char *addr, unsigned short *port)
{
    struct sockaddr_in serv;
    socklen_t len = sizeof(struct sockaddr_in);

    if (getpeername(sfd, (struct sockaddr *)&serv, &len)) {
        LLOG_ERRNO("\n");
        return -1;
    }

    if (addr) {
        inet_ntop(AF_INET, &serv.sin_addr, addr, IPV4_ADDR_LEN);
    }
    if (port) {
        *port = ntohs(serv.sin_port);
    }

    return 0;
}

/* UDP加入某个广播组之后就可以向这个广播组发送/接收数据 */
int ipv4_udp_broadcast_join(int sfd, const char *addr)
{
    int optval = 1;
    struct ip_mreq mreq;

    if (setsockopt(sfd, SOL_SOCKET, SO_BROADCAST, &optval, sizeof(optval)) < 0) { // 允许发送广播
        LLOG_ERRNO("fd=%d, addr=%s\n", sfd, addr);
        return -1;
    }

    mreq.imr_interface.s_addr = htonl(INADDR_ANY);  // INADDR_ANY=0, 本机任意网卡IP地址
    if (inet_pton(AF_INET, addr, &mreq.imr_multiaddr.s_addr) <= 0) { // 广播组IP地址
        LLOG_ERRNO("fd=%d, addr=%s\n", sfd, addr);
        return -1;
    }
    if (setsockopt(sfd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(mreq)) < 0) { // 加入广播组
        LLOG_ERRNO("fd=%d, addr=%s\n", sfd, addr);
        return -1;
    }

    return 0;
}

int ipv4_udp_create(const char *addr, unsigned short port, int timeout)
{
    int sfd;
    struct sockaddr_in serv;

    if ((sfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        LLOG_ERRNO("\n");
        return -1;
    }

    if ((addr && addr[0]) || port) {
        if (ipv4_addr_fill(&serv, addr, port) < 0) {
            LLOG_ERROR("\n");
            goto err;
        }

        // ipv4 D类地址(224.0.0.0-239.255.255.255)为多播地址
        if (addr && atoi(addr) >= 224) {
            if (ipv4_udp_broadcast_join(sfd, addr) < 0) {
                LLOG_ERROR("\n");
                goto err;
            }
            // 嵌入式bsd_tcpip库不能直接绑定多播地址, 需要把ip地址变为0
            // Linux 不必做这一步，并且不做更好
            //serv.sin_addr.s_addr = htonl(INADDR_ANY);
        }

        if (so_reuseaddr_set(sfd) < 0) {
            LLOG_ERROR("\n");
            goto err;
        }
        if (bind(sfd, (struct sockaddr *)&serv, sizeof(serv)) < 0) {
            LLOG_ERRNO("addr=%s, port=%d\n", addr ? addr : "0", port);
            goto err;
        }
        LLOG_DEBUG("UDP %d bind on %s:%d\n", sfd, addr ? addr : "0", port);
    }

    if (timeout) {
        send_timeout_set(sfd, timeout, 0);
        recv_timeout_set(sfd, timeout, 0);
    }

    return sfd;
err:
    close(sfd);
    return -1;
}

int ipv4_tcp_create(const char *addr, unsigned short port, int timeout)
{
    int sfd;
    struct sockaddr_in serv;

    if ((sfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
        LLOG_ERRNO("\n");
        return -1;
    }

    if ((addr && addr[0]) || port) {
        if (ipv4_addr_fill(&serv, addr, port) < 0) {
            LLOG_ERROR("\n");
            goto err;
        }

        if (so_reuseaddr_set(sfd) < 0) {
            LLOG_ERROR("\n");
            goto err;
        }
        if (bind(sfd, (struct sockaddr *)&serv, sizeof(serv)) < 0) {
            LLOG_ERRNO("addr=%s, port=%d\n", addr ? addr : "0", port);
            goto err;
        }
        LLOG_DEBUG("TCP %d bind on %s:%d\n", sfd, addr ? addr : "0", port);
    }

    if (timeout) {
        send_timeout_set(sfd, timeout, 0);
        recv_timeout_set(sfd, timeout, 0);
    }

    return sfd;
err:
    close(sfd);
    return -1;
}

int ipv4_tcp_listen(int sfd, int num)
{
    if (listen(sfd, num) < 0) {
        LLOG_ERRNO("sfd=%d listen%d\n", sfd, num);
        return -1;
    }
    return 0;
}

int ipv4_tcp_accept(int sfd, char *addr, unsigned short *port, int timeout)
{
    int afd;
    struct sockaddr_in serv;
    socklen_t len = sizeof(struct sockaddr_in);

    if ((afd = accept(sfd, (struct sockaddr *)&serv, (socklen_t *)&len)) < 0) {
        LLOG_ERRNO("sfd=%d\n", sfd);
        return -1;
    }

    if (timeout) {
        send_timeout_set(afd, timeout, 0);
        recv_timeout_set(afd, timeout, 0);
    }
    ipv4_addr_parse(&serv, addr, port);

    LLOG_DEBUG("TCP %d accept %s:%d as %d\n", sfd, inet_ntoa(serv.sin_addr), ntohs(serv.sin_port), afd);
    return afd;
}

/*
 * TCP客户端必须调用connect连接到服务器，使用send/recv和服务器交互
 * UDP本端无需调用connect连接到对端，此时使用sendto/recvfrom和对端交互
 * 但UDP本端调用connect连接到对端后，此时可使用send/recv和对端交互
 */
int ipv4_connect(int sfd, const char *addr, unsigned short port)
{
    struct sockaddr_in serv;

    if ((ipv4_addr_fill(&serv, addr, port)) < 0) {
        LLOG_ERROR("\n");
        goto err;
    }
    if (connect(sfd, (struct sockaddr *)&serv, sizeof(struct sockaddr_in)) < 0) {
        LLOG_ERRNO("\n");
        goto err;
    }

    LLOG_DEBUG("SOCK %d connect to %s:%d\n", sfd, addr ? addr : "0", port);
    return 0;
err:
    return -1;
}

ssize_t ipv4_sendto(int sfd, const void *buf, ssize_t blen, const struct sockaddr_in *serv)
{
    ssize_t size = 0;
    int flag = 0; // Linux支持MSG_NOSIGNAL，作用是对端已经关闭再写，不产生SIGPIPE信号
    socklen_t slen = sizeof(struct sockaddr_in);

    size = sendto(sfd, buf, blen, flag, (const struct sockaddr *)serv, slen);
    if (size != blen) {
        LLOG_ERRNO("%ld!=%ld, sendto(%d) failed!\n", blen, size, sfd);
    }

    return size;
}

ssize_t ipv4_recvfrom(int sfd, void *buf, size_t blen, struct sockaddr_in *serv)
{
    ssize_t size = 0;
    struct sockaddr_in temp;
    socklen_t slen = sizeof(struct sockaddr_in);

    if (!serv)
        serv = &temp;
    size = recvfrom(sfd, buf, blen, 0, (struct sockaddr *)serv, &slen);
    if (size < 0) {
        LLOG_ERRNO("recvfrom(%d) failed!\n", sfd);
    }

    return size;
}

ssize_t ipvx_send(int sfd, const void *buf, ssize_t blen)
{
    ssize_t size = 0;
    int flag = 0; // Linux支持MSG_NOSIGNAL，作用是对端已经关闭再写，不产生SIGPIPE信号

    size = send(sfd, buf, blen, flag);
    if (size != blen) {
        if (size < 0 && (errno == EAGAIN || errno == EINTR || errno == ETIMEDOUT))
            return 0;
        LLOG_ERRNO("%ld!=%ld, send(%d) failed!\n", blen, size, sfd);
    }

    return size;
}

ssize_t ipvx_recv(int sfd, void *buf, size_t blen)
{
    ssize_t size = 0;

    size = recv(sfd, buf, blen, 0);
    if (size < 0) {
        LLOG_ERRNO("recv(%d) failed!\n", sfd);
    }

    return size;
}

int ipv4_udp_server(const char *addr, unsigned short port, int timeout)
{
    return ipv4_udp_create(addr, port, timeout);
}

int ipv4_tcp_server(const char *addr, unsigned short port, int timeout, int num)
{
    int sfd;

    sfd = ipv4_tcp_create(addr, port, timeout);
    if (sfd < 0) {
        LLOG_ERROR("\n");
        return -1;
    }

    if (ipv4_tcp_listen(sfd, num) < 0) {
        LLOG_ERROR("\n");
        goto err;
    }

    return sfd;
err:
    close(sfd);
    return -1;
}

int ipv4_udp_client(const char *addr, unsigned short port, int timeout)
{
    int sfd;

    sfd = ipv4_udp_create(NULL, 0, timeout);
    if (sfd < 0) {
        LLOG_ERROR("\n");
        return -1;
    }

    if (ipv4_connect(sfd, addr, port) < 0) {
        LLOG_ERROR("\n");
        goto err;
    }

    return sfd;
err:
    close(sfd);
    return -1;
}

int ipv4_tcp_client(const char *addr, unsigned short port, int timeout)
{
    int sfd;

    sfd = ipv4_tcp_create(NULL, 0, timeout);
    if (sfd < 0) {
        LLOG_ERROR("\n");
        return -1;
    }

    if (ipv4_connect(sfd, addr, port) < 0) {
        LLOG_ERROR("\n");
        goto err;
    }

    return sfd;
err:
    close(sfd);
    return -1;
}

ssize_t ipv4_udp_sendmsg(const char *addr, unsigned short port, int timeout,
        const void *buf, ssize_t blen)
{
    ssize_t ret;
    int sfd;
    struct sockaddr_in serv;

    sfd = ipv4_udp_create(NULL, 0, timeout);
    if (sfd < 0) {
        LLOG_ERROR("\n");
        return -1;
    }

    if ((ipv4_addr_fill(&serv, addr, port)) < 0) {
        LLOG_ERROR("\n");
        goto err;
    }

    ret = ipv4_sendto(sfd, buf, blen, &serv);
    close(sfd);
    return ret;
err:
    close(sfd);
    return -1;
}

ssize_t ipv4_tcp_sendmsg(const char *addr, unsigned short port, int timeout,
        const void *buf, ssize_t blen)
{
    ssize_t ret;
    int sfd;

    sfd = ipv4_tcp_client(addr, port, timeout);
    if (sfd < 0) {
        LLOG_ERROR("\n");
        return -1;
    }

    ret = ipvx_send(sfd, buf, blen);
    close(sfd);
    return ret;
}

