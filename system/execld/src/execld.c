/*******************************************
* SPDX-License-Identifier: MIT             *
* Copyright (C) 2024-.... Jing Leng        *
* Contact: Jing Leng <lengjingzju@163.com> *
* https://github.com/lengjingzju/cbuild-ng *
*******************************************/
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <limits.h>
#include <sys/stat.h>
#include <errno.h>

#ifndef EXECLD_DEBUG
#define EXECLD_DEBUG    0
#endif

#define EXECLD_FREE(p) do { if (p) { free(p); (p) = NULL; } } while (0)

/*------------------------------------------------------------
  打印系统调用错误（glibc/systemd 风格）
------------------------------------------------------------*/
static void print_syscall_error(const char *syscall, const char *path) {
    if (path)
        fprintf(stderr, "execld: %s() failed on '%s': %s (errno=%d)\n",
                syscall, path, strerror(errno), errno);
    else
        fprintf(stderr, "execld: %s() failed: %s (errno=%d)\n",
                syscall, strerror(errno), errno);
}

/*------------------------------------------------------------
  文件是否存在
------------------------------------------------------------*/
static int file_exists(const char *path) {
    return access(path, F_OK) == 0;
}

/*------------------------------------------------------------
  文件是可执行
------------------------------------------------------------*/
static int file_executable(const char *path) {
    return access(path, X_OK) == 0;
}

/*------------------------------------------------------------
  目录是否存在
------------------------------------------------------------*/
static int dir_exists(const char *path) {
    struct stat st;
    if (stat(path, &st) != 0) return 0;
    return S_ISDIR(st.st_mode);
}

/*------------------------------------------------------------
  strdup 包装
------------------------------------------------------------*/
static char *xstrdup(const char *s) {
    char *r = strdup(s);
    if (!r) {
        print_syscall_error("strdup", NULL);
        exit(1);
    }
    return r;
}

/*------------------------------------------------------------
  拼接路径：base + "/" + rel
------------------------------------------------------------*/
static char *join_path(const char *base, const char *rel) {
    if (!rel || !*rel) return xstrdup(base);
    if (rel[0] == '/') return xstrdup(rel);

    size_t bl = strlen(base), rl = strlen(rel);
    int need_slash = (bl > 0 && base[bl - 1] != '/');

    char *r = malloc(bl + need_slash + rl + 1);
    if (!r) {
        print_syscall_error("malloc", NULL);
        exit(1);
    }

    strcpy(r, base);
    if (need_slash) strcat(r, "/");
    strcat(r, rel);
    return r;
}

/*------------------------------------------------------------
  在 PATH 中查找可执行文件
------------------------------------------------------------*/
static char *resolve_program_in_path(const char *prog) {
    const char *path = getenv("PATH");
    if (!path || !*path) return NULL;

    char *path_copy = xstrdup(path);
    char *saveptr = NULL;
    char *result = NULL;

    for (char *dir = strtok_r(path_copy, ":", &saveptr);
         dir;
         dir = strtok_r(NULL, ":", &saveptr)) {

        char *candidate = join_path(dir, prog);
        if (file_executable(candidate)) {
            result = candidate;
            break;
        }
        free(candidate);
    }

    free(path_copy);
    return result;
}

/*------------------------------------------------------------
  解析程序路径（不做 realpath）
------------------------------------------------------------*/
static char *resolve_program_path(const char *prog) {
    if (strchr(prog, '/')) {
        return xstrdup(prog);
    }
    return resolve_program_in_path(prog);
}

/*------------------------------------------------------------
  dirname/basename 包装
------------------------------------------------------------*/
static char *get_dirname(const char *path) {
    char *tmp = xstrdup(path);
    char *d = dirname(tmp);
    char *res = xstrdup(d);
    free(tmp);
    return res;
}

static char *get_basename(const char *path) {
    char *tmp = xstrdup(path);
    char *b = basename(tmp);
    char *res = xstrdup(b);
    free(tmp);
    return res;
}

/*------------------------------------------------------------
  去除前后空白
------------------------------------------------------------*/
static void trim(char *s) {
    char *p = s;
    while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') p++;
    if (p != s) memmove(s, p, strlen(p) + 1);

    size_t len = strlen(s);
    while (len > 0 && (s[len - 1] == ' ' || s[len - 1] == '\t' ||
                       s[len - 1] == '\r' || s[len - 1] == '\n')) {
        s[--len] = '\0';
    }
}

/*------------------------------------------------------------
  配置结构体
------------------------------------------------------------*/
struct config {
    char *linker;
    char *rpath_raw;
};

/*------------------------------------------------------------
  解析配置文件
------------------------------------------------------------*/
static int parse_cfg_file(const char *cfg_path, struct config *cfg) {
    FILE *f = fopen(cfg_path, "r");
    if (!f) {
        print_syscall_error("fopen", cfg_path);
        return -1;
    }

    char line[4096];
    while (fgets(line, sizeof(line), f)) {
        trim(line);
        if (!line[0] || line[0] == '#') continue;

        char *eq = strchr(line, '=');
        if (!eq) continue;

        *eq = '\0';
        char *key = line;
        char *val = eq + 1;
        trim(key);
        trim(val);

        char *start = strchr(val, '"');
        char *end = strrchr(val, '"');
        if (!start || !end || start == end) continue;

        *end = '\0';
        start++;

        if (strcmp(key, "linker") == 0) {
            free(cfg->linker);
            cfg->linker = xstrdup(start);
        } else if (strcmp(key, "rpath") == 0) {
            free(cfg->rpath_raw);
            cfg->rpath_raw = xstrdup(start);
        }
    }

    fclose(f);
    return 0;
}

/*------------------------------------------------------------
  分割 rpath
------------------------------------------------------------*/
static char **split_rpath(const char *raw, int *count) {
    *count = 0;
    if (!raw || !*raw) return NULL;

    char *copy = xstrdup(raw);
    int cap = 8;
    char **list = malloc(sizeof(char *) * cap);
    if (!list) {
        print_syscall_error("malloc", NULL);
        exit(1);
    }

    char *saveptr = NULL;
    for (char *tok = strtok_r(copy, ";", &saveptr);
         tok;
         tok = strtok_r(NULL, ";", &saveptr)) {

        trim(tok);
        if (!*tok) continue;

        if (*count >= cap) {
            cap *= 2;
            char **tmp = realloc(list, sizeof(char *) * cap);
            if (!tmp) {
                print_syscall_error("realloc", NULL);
                exit(1);
            }
            list = tmp;
        }
        list[*count] = xstrdup(tok);
        (*count)++;
    }

    free(copy);
    if (*count == 0) {
        free(list);
        return NULL;
    }
    return list;
}

/*------------------------------------------------------------
  构造绝对路径（相对 base_dir）
------------------------------------------------------------*/
static char *make_abs(const char *base_dir, const char *rel) {
    char *joined = join_path(base_dir, rel);
    char real[PATH_MAX];

    if (realpath(joined, real)) {
        free(joined);
        return xstrdup(real);
    }

    /* realpath 失败不致命 */
#if EXECLD_DEBUG
    print_syscall_error("realpath", joined);
#endif
    return joined;
}

/*------------------------------------------------------------
  判断 program_dir/.. 是否为 usr
------------------------------------------------------------*/
static int parent_is_usr(const char *dir) {
    char *copy = xstrdup(dir);
    char *parent = dirname(copy);

    char *copy2 = xstrdup(parent);
    char *base = basename(copy2);

    int ok = (strcmp(base, "usr") == 0);

    free(copy);
    free(copy2);
    return ok;
}

/*------------------------------------------------------------
  构造 LD_LIBRARY_PATH
------------------------------------------------------------*/
static char *build_library_path(const char *prog_dir, char **rpaths, int rcount) {
    if (rcount <= 0) return NULL;

    char **abs_list = malloc(sizeof(char *) * rcount);
    if (!abs_list) {
        print_syscall_error("malloc", NULL);
        exit(1);
    }

    int used = 0;
    for (int i = 0; i < rcount; ++i) {
        char *abs = make_abs(prog_dir, rpaths[i]);
        if (dir_exists(abs)) {
            abs_list[used++] = abs;
        } else {
#if EXECLD_DEBUG
            fprintf(stderr,
                    "execld: warning: library path '%s' does not exist, skipping\n",
                    abs);
#endif
            free(abs);
        }
    }

    if (used == 0) {
        free(abs_list);
        return NULL;
    }

    size_t total = 0;
    for (int i = 0; i < used; ++i) total += strlen(abs_list[i]) + 1;

    const char *old = getenv("LD_LIBRARY_PATH");
    if (old && *old) total += strlen(old) + 1;

    char *res = malloc(total + 1);
    if (!res) {
        print_syscall_error("malloc", NULL);
        exit(1);
    }
    res[0] = '\0';

    for (int i = 0; i < used; ++i) {
        if (i > 0) strcat(res, ":");
        strcat(res, abs_list[i]);
        free(abs_list[i]);
    }
    free(abs_list);

    if (old && *old) {
        strcat(res, ":");
        strcat(res, old);
    }

    return res;
}

/*------------------------------------------------------------
  主程序
------------------------------------------------------------*/
int main(int argc, char **argv) {
    char *prog_path = NULL;
    char *prog_dir = NULL;
    char *prog_name = NULL;
    char *linker_path = NULL;
    char *libpath = NULL;
    char **rpaths = NULL;
    int rcount = 0;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <program> [args...]\n", argv[0]);
        return 1;
    }

    /*--------------------------------------------------------
      解析程序路径（可能是相对/绝对/通过 PATH 找到）
    --------------------------------------------------------*/
    prog_path = resolve_program_path(argv[1]);
    if (!prog_path) {
        fprintf(stderr, "execld: cannot find program '%s'\n", argv[1]);
        goto cleanup;
    }

    /*--------------------------------------------------------
      对 program 做 realpath 解析符号链接，完全替换原路径
    --------------------------------------------------------*/
    {
        char realbuf[PATH_MAX];
        if (!realpath(prog_path, realbuf)) {
            print_syscall_error("realpath", prog_path);
            goto cleanup;
        }
        free(prog_path);
        prog_path = xstrdup(realbuf);
    }

    prog_dir = get_dirname(prog_path);
    prog_name = get_basename(prog_path);

    /*--------------------------------------------------------
      尝试读取配置文件
    --------------------------------------------------------*/
    struct config cfg = {0};
    int have_cfg = 0;

    char cfg1[PATH_MAX], cfg2[PATH_MAX];
    snprintf(cfg1, sizeof(cfg1), "%s/%s.ld.cfg", prog_dir, prog_name);
    snprintf(cfg2, sizeof(cfg2), "%s/ld.cfg", prog_dir);

    if (file_exists(cfg1) && parse_cfg_file(cfg1, &cfg) == 0 &&
        (cfg.linker || cfg.rpath_raw)) {
        have_cfg = 1;
    } else if (file_exists(cfg2) && parse_cfg_file(cfg2, &cfg) == 0 &&
               (cfg.linker || cfg.rpath_raw)) {
        have_cfg = 1;
    }

    /*--------------------------------------------------------
      若配置文件存在
    --------------------------------------------------------*/
    if (have_cfg && cfg.linker) {
        linker_path = make_abs(prog_dir, cfg.linker);
        if (!file_exists(linker_path)) {
            print_syscall_error("access", linker_path);
#if EXECLD_DEBUG
            fprintf(stderr, "execld: invalid linker in config, ignoring config\n");
#endif
            free(linker_path);
            linker_path = NULL;
            have_cfg = 0;
        } else {
            rpaths = split_rpath(cfg.rpath_raw, &rcount);
        }
    }

    /*--------------------------------------------------------
      若无配置文件但存在 program_dir/ld.so
    --------------------------------------------------------*/
    if (!have_cfg) {
        char ldso[PATH_MAX];
        snprintf(ldso, sizeof(ldso), "%s/ld.so", prog_dir);

        if (file_executable(ldso)) {
            linker_path = xstrdup(ldso);

            const char *defaults[] = {".", "./lib", "../lib", "../../lib"};
            int def_count = 4;

            rpaths = malloc(sizeof(char *) * def_count);
            if (!rpaths) {
                print_syscall_error("malloc", NULL);
                goto cleanup;
            }

            int used = 0;
            for (int i = 0; i < def_count; ++i) {
                if (strcmp(defaults[i], "../../lib") == 0 &&
                    !parent_is_usr(prog_dir)) {
                    continue;
                }
                rpaths[used++] = xstrdup(defaults[i]);
            }
            rcount = used;
        }
    }

    /*--------------------------------------------------------
      若找到 linker，则构造 LD_LIBRARY_PATH 并 execv
    --------------------------------------------------------*/
    if (linker_path) {
        libpath = build_library_path(prog_dir, rpaths, rcount);
        if (libpath) {
            if (setenv("LD_LIBRARY_PATH", libpath, 1) != 0) {
                print_syscall_error("setenv", "LD_LIBRARY_PATH");
                goto cleanup;
            }
        }

        int total = 1 + (argc - 1) + 1;
        char **nargv = calloc(total, sizeof(char *));
        if (!nargv) {
            print_syscall_error("calloc", NULL);
            goto cleanup;
        }

        int idx = 0;
        nargv[idx++] = linker_path;  /* ld.so */
        nargv[idx++] = prog_path;    /* 实际 ELF 路径（已 realpath） */

        for (int i = 2; i < argc; ++i)
            nargv[idx++] = argv[i];

        nargv[idx] = NULL;

        execv(linker_path, nargv);
        print_syscall_error("execv", linker_path);
        free(nargv);
        goto cleanup;
    }

    /*--------------------------------------------------------
      否则按标准方式运行程序（使用真实路径）
    --------------------------------------------------------*/
    execvp(prog_path, &argv[1]);
    print_syscall_error("execvp", prog_path);

cleanup:
    EXECLD_FREE(prog_path);
    EXECLD_FREE(prog_dir);
    EXECLD_FREE(prog_name);
    EXECLD_FREE(linker_path);
    EXECLD_FREE(libpath);

    if (rpaths) {
        for (int i = 0; i < rcount; ++i)
            EXECLD_FREE(rpaths[i]);
        EXECLD_FREE(rpaths);
    }

    /* 实际 cfg 的释放 */
    EXECLD_FREE(cfg.linker);
    EXECLD_FREE(cfg.rpath_raw);

    return 1;
}

