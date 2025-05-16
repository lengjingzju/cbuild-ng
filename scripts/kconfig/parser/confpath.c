/* SPDX-License-Identifier: GPL-2.0-only */
#include <stdlib.h>
#include <string.h>
#include "confpath.h"

#define path_template(pathname)				\
static char *s_##pathname = NULL;			\
							\
const char *set_##pathname(const char *path)	\
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

path_template(configpath)
path_template(autoconfigpath)
path_template(autoheaderpath)
path_template(rustccfgpath)
