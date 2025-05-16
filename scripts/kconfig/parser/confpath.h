/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef CONFPATH_H
#define CONFPATH_H

const char *set_configpath(const char *path);
const char *set_autoconfigpath(const char *path);
const char *set_autoheaderpath(const char *path);
const char *set_rustccfgpath(const char *path);

const char *get_configpath(void);
const char *get_autoconfigpath(void);
const char *get_autoheaderpath(void);
const char *get_rustccfgpath(void);

#endif /* CONFPATH_H */
