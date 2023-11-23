/*******************************************
* SPDX-License-Identifier: MIT             *
* Copyright (C) 2023-.... Jing Leng        *
* Contact: Jing Leng <lengjingzju@163.com> *
* https://github.com/lengjingzju/cbuild-ng *
*******************************************/

#ifndef __SOCKET_API_H__
#define __SOCKET_API_H__
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

int sfd_nonblock_set(int sfd);
int send_timeout_set(int sfd, int sec, long usec);
int recv_timeout_set(int sfd, int sec, long usec);
int so_reuseaddr_set(int sfd);
int tcp_nolinger_set(int sfd);
int tcp_nodelay_set(int sfd);
int tcp_connected_check(int sfd);
int tcp_heart_beat_set(int sfd, int keep_idle, int keep_interval, int keep_count);
int ipv4_addr_fill(struct sockaddr_in *serv, const char *addr, unsigned short port);
int ipv4_addr_parse(struct sockaddr_in *serv, char *addr, unsigned short *port);
int ipv4_sockaddr_get(int sfd, char *addr, unsigned short *port);
int ipv4_peeraddr_get(int sfd, char *addr, unsigned short *port);
int ipv4_udp_broadcast_join(int sfd, const char *addr);
int ipv4_udp_create(const char *addr, unsigned short port, int timeout);
int ipv4_tcp_create(const char *addr, unsigned short port, int timeout);
int ipv4_tcp_listen(int sfd, int num);
int ipv4_tcp_accept(int sfd, char *addr, unsigned short *port, int timeout);
int ipv4_connect(int sfd, const char *addr, unsigned short port);
ssize_t ipv4_sendto(int sfd, const void *buf, ssize_t blen, const struct sockaddr_in *serv);
ssize_t ipv4_recvfrom(int sfd, void *buf, size_t blen, struct sockaddr_in *serv);
ssize_t ipvx_send(int sfd, const void *buf, ssize_t blen);
ssize_t ipvx_recv(int sfd, void *buf, size_t blen);
int ipv4_udp_server(const char *addr, unsigned short port, int timeout);
int ipv4_tcp_server(const char *addr, unsigned short port, int timeout, int num);
int ipv4_udp_client(const char *addr, unsigned short port, int timeout);
int ipv4_tcp_client(const char *addr, unsigned short port, int timeout);
ssize_t ipv4_udp_sendmsg(const char *addr, unsigned short port, int timeout,
        const void *buf, ssize_t blen);
ssize_t ipv4_tcp_sendmsg(const char *addr, unsigned short port, int timeout,
        const void *buf, ssize_t blen);

#endif
