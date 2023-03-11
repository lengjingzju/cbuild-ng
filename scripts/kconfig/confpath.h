/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef CONFPATH_H
#define CONFPATH_H

#define path_template(pathname)				\
static char *s_##pathname = NULL;			\
							\
static const char *set_##pathname(const char *path)	\
{							\
	if (s_##pathname) {				\
		free(s_##pathname);			\
		s_##pathname = NULL;			\
	}						\
	if (path)					\
		s_##pathname = strdup(path);		\
	return s_##pathname;				\
}							\
							\
const char *get_##pathname(void)			\
{							\
	return s_##pathname;				\
}

const char *get_configpath(void);
const char *get_autoconfigpath(void);
const char *get_autoheaderpath(void);

#endif /* CONFPATH_H */

