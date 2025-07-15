/*******************************************
* SPDX-License-Identifier: MIT             *
* Copyright (C) 2023-.... Jing Leng        *
* Contact: Jing Leng <lengjingzju@163.com> *
* https://github.com/lengjingzju/cbuild-ng *
*******************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include "socket_api.h"
#include "jlog.h"

#define LOCAL_IP_ADDR   "127.0.0.1"
#define BUF_SIZE        65536
#define TMP_SIZE        128
#define MAX_LOG_SIZE    (128u<<10)

struct pkg_list {
    struct pkg_list *next;
};

struct pkg_list_head {
    struct pkg_list *next, *prev;
};

struct pkg_node {
    struct pkg_list list;
    char *name;
    int len;
};

/* args of pkg_list_entry is different to list_entry of linux */
#define pkg_list_entry(ptr, type)  ((type *)(ptr))

#define pkg_list_for_each_entry(pos, head, member)             \
    for (pos = pkg_list_entry((head)->next, typeof(*pos));     \
        &pos->member != (struct pkg_list *)(head);             \
        pos = pkg_list_entry(pos->member.next, typeof(*pos)))

#define pkg_list_for_each_entry_safe(p, pos, n, head, member)  \
    for (p = pkg_list_entry((head), typeof(*pos)),             \
        pos = pkg_list_entry((head)->next, typeof(*pos)),      \
        n = pkg_list_entry(pos->member.next, typeof(*pos));    \
        &pos->member != (struct pkg_list *)(head);             \
        p = pos, pos = n, n = pkg_list_entry(n->member.next, typeof(*n)))

static inline void INIT_PKG_LIST_HEAD(struct pkg_list_head *head)
{
    head->next = (struct pkg_list *)head;
    head->prev = (struct pkg_list *)head;
}

static inline void pkg_list_add_tail(struct pkg_list *list, struct pkg_list_head *head)
{
    list->next = head->prev->next;
    head->prev->next = list;
    head->prev = list;
}

static inline void pkg_list_del(struct pkg_list *list, struct pkg_list *prev, struct pkg_list_head *head)
{
    if (list->next == (struct pkg_list *)head) {
        head->prev = prev;
    }
    prev->next = list->next;
    list->next = NULL;
}

static int create_dir(char *dir)
{
    char *s = dir;

    ++s;
    while (*s) {
        if (*s == '/') {
            *s = '\0';
            if (access(dir, F_OK) < 0) {
                if (mkdir(dir, 0775) < 0) {
                    LLOG_ERRNO("mkdir(%s) failed!\n", dir);
                    *s = '/';
                    return -1;
                }
            }
            *s = '/';
        }
        ++s;
    }

    if (*(s-1) != '/') {
        if (access(dir, F_OK) < 0) {
            if (mkdir(dir, 0775) < 0) {
                LLOG_ERRNO("mkdir(%s) failed!\n", dir);
                return -1;
            }
        }
    }

    return 0;
}

static int process_handler(int pfdout, int pfderr, const char* logpath, bool logout)
{
    int ret = 0;
    bool running = true;
    int result, index, percent = 0, ccnt = 0;
    int logcnt = 0;
    int total_pkg = 0, finished_pkg = 0, live_pkg = 0;
    int sfd, rfd, wfd, maxfd;
    unsigned int total_size = 0;
    unsigned short port;
    ssize_t num, tnum;
    fd_set rfds;
    struct timeval timeout;
    char *buf;
    char *dir;
    char tmp[TMP_SIZE];
    char space[52];
    time_t s;
    struct tm t;
    struct timespec ts;
    struct pkg_list_head pkghead;
    struct pkg_node *p, *pos, *n;

    INIT_PKG_LIST_HEAD(&pkghead);

    buf = malloc(BUF_SIZE);
    if (!buf) {
        LLOG_ERRNO("malloc(%d) failed!\n", BUF_SIZE);
        return -1;
    }

    sfd = ipv4_udp_server(LOCAL_IP_ADDR, 0, 0);
    if (sfd < 0) {
        LLOG_ERROR("\n");
        ret = -1;
        goto exit0;
    }

    ipv4_sockaddr_get(sfd, NULL, &port);
    tnum = snprintf(tmp, TMP_SIZE, "%u", port);
    snprintf(buf, BUF_SIZE, "%s/port", logpath);
    wfd = open(buf, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (wfd < 0) {
        LLOG_ERROR("open(%s) failed!\n", buf);
        ret = -1;
        goto exit1;
    }
    write(wfd, tmp, tnum);
    close(wfd);

    clock_gettime(CLOCK_MONOTONIC, &ts);
    s = time(NULL);
    localtime_r(&s, &t);
    strftime(tmp, TMP_SIZE, "%Y-%m-%d--%H-%M-%S", &t);
    if (logpath[strlen(logpath) - 1] == '/' )
        snprintf(buf, BUF_SIZE, "%s%s.%09ld/", logpath, tmp, ts.tv_nsec);
    else
        snprintf(buf, BUF_SIZE, "%s/%s.%09ld/", logpath, tmp, ts.tv_nsec);

    dir = strdup(buf);
    if (!dir) {
        LLOG_ERRNO("strdup(%lu) failed!\n", strlen(buf));
        goto exit1;
    }
    if (create_dir(dir) < 0) {
        LLOG_ERROR("mkdir(%s) failed!\n", dir);
        goto exit2;
    }
    num = snprintf(buf, BUF_SIZE, "\033[34mlog path is %s\033[0m\n", dir);
    write(STDERR_FILENO, buf, num);

    snprintf(buf, BUF_SIZE, "%s%04d-%s.log", dir, logcnt++, tmp);
    wfd = open(buf, O_WRONLY | O_CREAT, 0644);
    if (wfd < 0) {
        LLOG_ERROR("open(%s) failed!\n", buf);
        ret = -1;
        goto exit2;
    }

    maxfd = pfdout > pfderr ? pfdout : pfderr;
    maxfd = maxfd > sfd ? maxfd : sfd;
    memset(space, ' ', 51);
    space[51] = '\0';

    while (running) {
        if (total_size > MAX_LOG_SIZE) {
            total_size = 0;
            close(wfd);

            s = time(NULL);
            localtime_r(&s, &t);
            strftime(tmp, TMP_SIZE, "%Y-%m-%d--%H-%M-%S", &t);
            snprintf(buf, BUF_SIZE, "%s%04d-%s.log", dir, logcnt++, tmp);
            wfd = open(buf, O_WRONLY | O_CREAT, 0644);
            if (wfd < 0) {
                LLOG_ERROR("open(%s) failed!\n", buf);
                ret = -1;
                goto exit3;
            }
        }

        FD_ZERO(&rfds);
        FD_SET(pfdout, &rfds);
        FD_SET(pfderr, &rfds);
        FD_SET(sfd, &rfds);

        timeout.tv_sec = 1;
        timeout.tv_usec = 0;
        result = select(maxfd + 1, &rfds, NULL, NULL, &timeout);
        if (result <= 0) {
            snprintf(buf, BUF_SIZE, "%s/port", logpath);
            rfd = open(buf, O_RDONLY, 0644);
            if (rfd < 0) {
                LLOG_ERROR("open(%s) failed!\n", buf);
                ret = -1;
                goto exit3;
            }
            num = read(rfd, buf, BUF_SIZE);
            close(rfd);
            buf[num] = '\0';
            if (port != atoi(buf)) {
                LLOG_INFO("No port file, exit!\n");
                goto exit3;
            }

            if (!live_pkg)
                continue;

            if (ccnt >= 3) {
                ccnt = 0;
                tnum = snprintf(tmp, TMP_SIZE, "%120s\r", " ");
                write(STDOUT_FILENO, tmp, tnum);
            } else {
                ++ccnt;
                if (ccnt != 1)
                    continue;
                tnum = snprintf(tmp, TMP_SIZE, "%120s\r", " ");
                write(STDOUT_FILENO, tmp, tnum);
                num = snprintf(buf, BUF_SIZE, "\033[32m[%2d%%][%d/%d] \033[0mjobs(%d):",
                        percent, finished_pkg, total_pkg, live_pkg);
                pkg_list_for_each_entry(pos, &pkghead, list) {
                    if (num + pos->len >= 116) {
                        break;
                    }
                    buf[num++] = ' ';
                    memcpy(buf + num, pos->name, pos->len);
                    num += pos->len;
                }
                memcpy(buf + num, "...\r", 4);
                num += 4;
                write(STDOUT_FILENO, buf, num);
            }

            continue;
        }

        if (FD_ISSET(pfdout, &rfds)) {
            num = read(pfdout, buf, BUF_SIZE);
            if (num == -1) {
                LLOG_ERRNO("read PIPE failed!\n");
                ret = -1;
                running = false;
            } else if (num == 0) {
                running = false;
            } else {
                if (logout) {
                    if (ccnt) {
                        tnum = snprintf(tmp, TMP_SIZE, "%120s\r", " ");
                        write(STDOUT_FILENO, tmp, tnum);
                        ccnt = 0;
                    }
                    write(STDOUT_FILENO, buf, num);
                }

                total_size += write(wfd, buf, num);
            }
        }

        if (FD_ISSET(pfderr, &rfds)) {
            num = read(pfderr, buf, BUF_SIZE);
            if (num == -1) {
                LLOG_ERRNO("read PIPE failed!\n");
                ret = -1;
                running = false;
            } else if (num == 0) {
                running = false;
            } else {
                if (ccnt) {
                    tnum = snprintf(tmp, TMP_SIZE, "%120s\r", " ");
                    write(STDOUT_FILENO, tmp, tnum);
                    ccnt = 0;
                }
                write(STDERR_FILENO, buf, num);

                total_size += write(wfd, buf, num);
            }
        }

        if (FD_ISSET(sfd, &rfds)) {
            num = ipv4_recvfrom(sfd, buf, BUF_SIZE, NULL);
            if (num == -1) {
                LLOG_ERRNO("read PIPE failed!\n");
                ret = -1;
                running = false;
            } else if (num == 0) {
                running = false;
            } else {
                if (strncmp(buf, "stop", 4) == 0) {
                    running = false;
                } else if (strncmp(buf, "total=", 6) == 0) {
                    buf[num] = '\0';
                    total_pkg = atoi(buf + 6);

                } else if (strncmp(buf, "begin=", 6) == 0) {
                    tnum = num - 6 < TMP_SIZE - 1 ? num - 6 : TMP_SIZE - 1;
                    memcpy(tmp, buf + 6, tnum);
                    tmp[tnum] = '\0';
                    if (tnum > 7) {
                        if (strncmp(tmp + tnum - 7, "_single", 7) == 0) {
                            tnum -= 7;
                            tmp[tnum] = '\0';
                        }
                    }
                    pos = malloc(sizeof(struct pkg_node));
                    pos->name = strdup(tmp);
                    pos->len = tnum;
                    pkg_list_add_tail(&pos->list, &pkghead);
                    ++live_pkg;

                } else if (strncmp(buf, "end=", 4) == 0) {
                    if (total_pkg != 0) {
                        if (finished_pkg < total_pkg)
                            ++finished_pkg;

                        if (ccnt) {
                            tnum = snprintf(tmp, TMP_SIZE, "%120s\r", " ");
                            write(STDOUT_FILENO, tmp, tnum);
                        }
                        ccnt = 1;

                        tnum = num - 4 < TMP_SIZE - 1 ? num - 4 : TMP_SIZE - 1;
                        memcpy(tmp, buf + 4, tnum);
                        tmp[tnum] = '\0';
                        if (tnum > 7) {
                            if (strncmp(tmp + tnum - 7, "_single", 7) == 0) {
                                tnum -= 7;
                                tmp[tnum] = '\0';
                            }
                        }
                        pkg_list_for_each_entry_safe(p, pos, n, &pkghead, list) {
                            if (strcmp(pos->name, tmp) == 0) {
                                pkg_list_del(&pos->list, &p->list, &pkghead);
                                free(pos->name);
                                free(pos);
                                pos = p;
                                --live_pkg;
                                break;
                            }
                        }

                        percent = 100 * finished_pkg / total_pkg;
                        if (percent == 0) {
                            num = snprintf(buf, BUF_SIZE, "[%2d%%]%50s[%3d/%3d] %s\r",
                                percent, " ", finished_pkg, total_pkg, tmp);
                        } else if (percent == 100) {
                            num = snprintf(buf, BUF_SIZE, "[%d%%]\033[42m%50s\033[0m[%3d/%3d] %s\n",
                                percent, " ", finished_pkg, total_pkg, tmp);
                        } else {
                            index = percent / 2;
                            space[index] = '\0';
                            num = snprintf(buf, BUF_SIZE, "[%2d%%]\033[42m%s\033[0m%s[%3d/%3d] %s\r",
                                percent, space, space + index + 1, finished_pkg, total_pkg, tmp);
                            space[index] = ' ';
                        }
                        write(STDOUT_FILENO, buf, num);
                    }
                }
            }
        }
    }


exit3:
    pkg_list_for_each_entry_safe(p, pos, n, &pkghead, list) {
        pkg_list_del(&pos->list, &p->list, &pkghead);
        free(pos->name);
        free(pos);
        pos = p;
    }
    if (wfd < 0)
        close(wfd);
exit2:
    free(dir);
exit1:
    close(sfd);
exit0:
    free(buf);

    return ret;
}

int main(int argc, char *argv[])
{
    int pfdout[2], pfderr[2];
    const char *logpath = NULL;
    bool logout = false;
    int index = 0;
    int status = 0;
    int ret = 0;

    if (argc < 3) {
        fprintf(stderr, "\033[31mUsage: %s <logpath> <command...>\033[0m\n", argv[0]);
        fprintf(stderr, "\033[31m       %s !<logpath> <command...>\033[0m\n", argv[0]);
        fprintf(stderr, "\033[31m       %s <port> <description>\033[0m\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    if (argv[1][0] == '/') {
        logpath = argv[1];
        logout = false;
        index = 2;
    } else if (argv[1][0] == '!') {
        logpath = argv[1] + 1;
        logout = true;
        index = 2;
    } else {
        ret = ipv4_udp_sendmsg(LOCAL_IP_ADDR, atoi(argv[1]), 2, argv[2], strlen(argv[2]));
        exit(ret >= 0 ? EXIT_SUCCESS : EXIT_FAILURE);
    }

    if (pipe(pfdout) == -1) {
        exit(EXIT_FAILURE);
    }
    if (pipe(pfderr) == -1) {
        close(pfdout[0]);
        close(pfdout[1]);
        exit(EXIT_FAILURE);
    }

    switch (fork()) {
        case -1:
            close(pfdout[0]);
            close(pfdout[1]);
            close(pfderr[0]);
            close(pfderr[1]);
            exit(EXIT_FAILURE);

        case 0: /* Child */
            close(pfdout[0]);
            close(pfderr[0]);
            dup2(pfdout[1], STDOUT_FILENO);
            dup2(pfderr[1], STDERR_FILENO);
            setenv("MAKE", argv[index], 1);
            usleep(10000);
            ret = execvp(argv[index], argv + index + 1);
            close(pfdout[1]);
            close(pfderr[1]);
            exit(ret == 0 ? EXIT_SUCCESS : EXIT_FAILURE);

        default: /* Parent */
            close(pfdout[1]);
            close(pfderr[1]);
            ret = process_handler(pfdout[0], pfderr[0], logpath, logout);
            close(pfdout[0]);
            close(pfderr[0]);
            wait(&status);
            exit(ret == 0 ? (WEXITSTATUS(status) ? EXIT_FAILURE : EXIT_SUCCESS) : EXIT_FAILURE);
    }
}

