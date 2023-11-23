/*******************************************
* SPDX-License-Identifier: MIT             *
* Copyright (C) 2023-.... Jing Leng        *
* Contact: Jing Leng <lengjingzju@163.com> *
* https://github.com/lengjingzju/cbuild-ng *
*******************************************/

#ifndef __JLOG_H__
#define __JLOG_H__

#include <string.h>
#include <errno.h>

#define LOG_LEVEL_CLOSE     0
#define LOG_LEVEL_ERROR     1
#define LOG_LEVEL_WARN      2
#define LOG_LEVEL_INFO      3
#define LOG_LEVEL_DEBUG     4
#define LOG_LEVEL_TRACE     5

#ifndef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF       LOG_LEVEL_INFO
#endif

#if LOG_LEVEL_DEF >= LOG_LEVEL_ERROR
#define SLOG_ERRNO(fmt, args...)  do {                      \
    fprintf(stderr, "E: (%d:%s) ", errno, strerror(errno)); \
    fprintf(stderr, fmt, ##args);                           \
} while (0)

#define LLOG_ERRNO(fmt, args...)  do {                      \
    fprintf(stderr, "E: %s:%d (%d:%s) ", __func__, __LINE__,\
            errno, strerror(errno));                        \
    fprintf(stderr, fmt, ##args);                           \
} while (0)

#define SLOG_ERROR(fmt, args...)  do {                      \
    fprintf(stderr, "E: ");                                 \
    fprintf(stderr, fmt, ##args);                           \
} while (0)

#define LLOG_ERROR(fmt, args...)  do {                      \
    fprintf(stderr, "E: %s:%d ", __func__, __LINE__);       \
    fprintf(stderr, fmt, ##args);                           \
} while (0)
#else
#define SLOG_ERRNO(fmt, args...)  do { } while (0)
#define LLOG_ERRNO(fmt, args...)  do { } while (0)
#define SLOG_ERROR(fmt, args...)  do { } while (0)
#define LLOG_ERROR(fmt, args...)  do { } while (0)
#endif

#if LOG_LEVEL_DEF >= LOG_LEVEL_WARN
#define SLOG_WARN(fmt, args...)  do {                       \
    fprintf(stderr, fmt, ##args);                           \
} while (0)

#define LLOG_WARN(fmt, args...)  do {                       \
    fprintf(stderr, "W: %s:%d ", __func__, __LINE__);       \
    fprintf(stderr, fmt, ##args);                           \
} while (0)
#else
#define SLOG_WARN(fmt, args...)  do { } while (0)
#define LLOG_WARN(fmt, args...)  do { } while (0)
#endif

#if LOG_LEVEL_DEF >= LOG_LEVEL_INFO
#define SLOG_INFO(fmt, args...)  do {                       \
    fprintf(stdout, fmt, ##args);                           \
} while (0)

#define LLOG_INFO(fmt, args...)  do {                       \
    fprintf(stdout, "I: %s:%d ", __func__, __LINE__);       \
    fprintf(stdout, fmt, ##args);                           \
} while (0)
#else
#define SLOG_INFO(fmt, args...)  do { } while (0)
#define LLOG_INFO(fmt, args...)  do { } while (0)
#endif

#if LOG_LEVEL_DEF >= LOG_LEVEL_DEBUG
#define SLOG_DEBUG(fmt, args...) do {                       \
    fprintf(stdout, fmt, ##args);                           \
} while (0)

#define LLOG_DEBUG(fmt, args...) do {                       \
    fprintf(stdout, "D: %s:%d ", __func__, __LINE__);       \
    fprintf(stdout, fmt, ##args);                           \
} while (0)
#else
#define SLOG_DEBUG(fmt, args...) do { } while (0)
#define LLOG_DEBUG(fmt, args...) do { } while (0)
#endif

#if LOG_LEVEL_DEF >= LOG_LEVEL_TRACE
#define SLOG_TRACE(fmt, args...) do {                       \
    fprintf(stdout, fmt, ##args);                           \
} while (0)

#define LLOG_TRACE(fmt, args...) do {                       \
    fprintf(stdout, "T: %s:%d ", __func__, __LINE__);       \
    fprintf(stdout, fmt, ##args);                           \
} while (0)
#else
#define SLOG_TRACE(fmt, args...) do { } while (0)
#define LLOG_TRACE(fmt, args...) do { } while (0)
#endif

#endif

