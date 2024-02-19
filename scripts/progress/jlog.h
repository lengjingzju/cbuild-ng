/*******************************************
* SPDX-License-Identifier: MIT             *
* Copyright (C) 2023-.... Jing Leng        *
* Contact: Jing Leng <lengjingzju@163.com> *
* https://github.com/lengjingzju/cbuild-ng *
*******************************************/
#pragma once
#include <string.h>
#include <stdio.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief   日志输出等级
 */
#define JLOG_LEVEL_OFF       0
#define JLOG_LEVEL_FATAL     1
#define JLOG_LEVEL_ERROR     2
#define JLOG_LEVEL_WARN      3
#define JLOG_LEVEL_INFO      4
#define JLOG_LEVEL_DEBUG     5
#define JLOG_LEVEL_TRACE     6

#ifndef JLOG_LEVEL_DEF
#define JLOG_LEVEL_DEF       JLOG_LEVEL_INFO
#endif

/**
 * @brief   输出到终端的最简宏，外部一般不要使用这些宏定义
 */
#if JLOG_LEVEL_DEF >= JLOG_LEVEL_FATAL
#define SLOG_FATAL(fmt, ...) fprintf(stderr, "F: " fmt, ##__VA_ARGS__)
#define LLOG_FATAL(fmt, ...) fprintf(stderr, "F: %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__)
#define LLOG_FATNO(fmt, ...) fprintf(stderr, "F: %s:%d (%d:%s) " fmt, __func__, __LINE__, errno, strerror(errno), ##__VA_ARGS__)
#else
#define SLOG_FATAL(fmt, ...) do { } while (0)
#define LLOG_FATAL(fmt, ...) do { } while (0)
#define LLOG_FATNO(fmt, ...) do { } while (0)
#endif

#if JLOG_LEVEL_DEF >= JLOG_LEVEL_ERROR
#define SLOG_ERROR(fmt, ...) fprintf(stderr, "E: " fmt, ##__VA_ARGS__)
#define LLOG_ERROR(fmt, ...) fprintf(stderr, "E: %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__)
#define LLOG_ERRNO(fmt, ...) fprintf(stderr, "E: %s:%d (%d:%s) " fmt, __func__, __LINE__, errno, strerror(errno), ##__VA_ARGS__)
#else
#define SLOG_ERROR(fmt, ...) do { } while (0)
#define LLOG_ERROR(fmt, ...) do { } while (0)
#define LLOG_ERRNO(fmt, ...) do { } while (0)
#endif

#if JLOG_LEVEL_DEF >= JLOG_LEVEL_WARN
#define SLOG_WARN(fmt, ...)  fprintf(stderr, fmt, ##__VA_ARGS__)
#define LLOG_WARN(fmt, ...)  fprintf(stderr, "W: %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__)
#else
#define SLOG_WARN(fmt, ...)  do { } while (0)
#define LLOG_WARN(fmt, ...)  do { } while (0)
#endif

#if JLOG_LEVEL_DEF >= JLOG_LEVEL_INFO
#define SLOG_INFO(fmt, ...)  fprintf(stdout, fmt, ##__VA_ARGS__)
#define LLOG_INFO(fmt, ...)  fprintf(stdout, "I: %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__)
#else
#define SLOG_INFO(fmt, ...)  do { } while (0)
#define LLOG_INFO(fmt, ...)  do { } while (0)
#endif

#if JLOG_LEVEL_DEF >= JLOG_LEVEL_DEBUG
#define SLOG_DEBUG(fmt, ...) fprintf(stdout, fmt, ##__VA_ARGS__)
#define LLOG_DEBUG(fmt, ...) fprintf(stdout, "D: %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__)
#else
#define SLOG_DEBUG(fmt, ...) do { } while (0)
#define LLOG_DEBUG(fmt, ...) do { } while (0)
#endif

#if JLOG_LEVEL_DEF >= JLOG_LEVEL_TRACE
#define SLOG_TRACE(fmt, ...) fprintf(stdout, fmt, ##__VA_ARGS__)
#define LLOG_TRACE(fmt, ...) fprintf(stdout, "T: %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__)
#else
#define SLOG_TRACE(fmt, ...) do { } while (0)
#define LLOG_TRACE(fmt, ...) do { } while (0)
#endif

#ifdef __cplusplus
}
#endif

