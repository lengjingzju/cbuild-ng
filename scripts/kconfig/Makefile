############################################
# SPDX-License-Identifier: GPL-2.0         #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

OBJ_PREFIX     ?= $(if $(O),$(O),./build)
INS_PREFIX     ?= $(if $(DESTDIR),$(DESTDIR),./image)

AUTOGEN_BISON   = $(OBJ_PREFIX)/autogen/parser.tab.c $(OBJ_PREFIX)/autogen/parser.tab.h
AUTOGEN_FLEX    = $(OBJ_PREFIX)/autogen/lexer.lex.c
AUTOGEN_OBJS    = $(OBJ_PREFIX)/autogen/parser.tab.o $(OBJ_PREFIX)/autogen/lexer.lex.o
PARSER_OBJS     = $(patsubst %.c,$(OBJ_PREFIX)/%.o,$(wildcard parser/*.c))
LXDIALOG_OBJS   = $(patsubst %.c,$(OBJ_PREFIX)/%.o,$(wildcard lxdialog/*.c))
CONF_OBJS       = $(patsubst %.c,$(OBJ_PREFIX)/%.o,conf.c)
MCONF_OBJS      = $(patsubst %.c,$(OBJ_PREFIX)/%.o,mconf.c)
DEPEND_OBJS     = $(patsubst %.o,%.d,$(AUTOGEN_OBJS) $(PARSER_OBJS) $(LXDIALOG_OBJS) $(CONF_OBJS) $(MCONF_OBJS))

CONF_CC         ?= gcc
CONF_CFLAGS      = -I. -I./parser -I./lxdialog
CONF_LDFLAGS     = -static $(EXTRA_LDFLAGS)

CONF_CFLAGS     += $(shell sh mconf-cfg.sh | grep "cflags=" | sed 's/cflags="\(.*\)"/\1/')
CONF_LDFLAGS    += $(shell sh mconf-cfg.sh | grep "libs=" | sed 's/libs="\(.*\)"/\1/')

COLORECHO       = $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)

.PHONY: all clean install

all: $(OBJ_PREFIX)/conf $(OBJ_PREFIX)/mconf

clean:
	@-rm -rf $(OBJ_PREFIX)/conf $(OBJ_PREFIX)/mconf $(DEPEND_OBJS) \
		$(AUTOGEN_BISON) $(AUTOGEN_FLEX) $(AUTOGEN_OBJS) \
		$(PARSER_OBJS) $(LXDIALOG_OBJS) $(CONF_OBJS) $(MCONF_OBJS)

install:
	@install -d $(INS_PREFIX)/usr/bin
	@cp -f $(OBJ_PREFIX)/conf $(OBJ_PREFIX)/mconf $(INS_PREFIX)/usr/bin

-include $(DEPEND_OBJS)

$(AUTOGEN_BISON): autogen/parser.y
	@-mkdir -p $(dir $@)
	@$(COLORECHO) "\033[32mbison\033[0m	$@"
	@bison -o $(basename $@).c --defines=$(basename $@).h -t -l $<

$(AUTOGEN_FLEX): autogen/lexer.l $(AUTOGEN_BISON)
	@-mkdir -p $(dir $@)
	@$(COLORECHO) "\033[32mflex\033[0m	$@"
	@flex -o $@ -L $<

$(AUTOGEN_OBJS) : %.o:%.c $(OBJ_PREFIX)/autogen/parser.tab.h
	@-mkdir -p $(dir $@)
	@$(CONF_CC) $(CONF_CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@$(COLORECHO) "\033[32m$(CONF_CC)\033[0m	$<"
	@$(CONF_CC) $(CONF_CFLAGS) -c -o $@ $<

$(PARSER_OBJS) $(LXDIALOG_OBJS) $(CONF_OBJS) $(MCONF_OBJS): $(OBJ_PREFIX)/%.o:%.c
	@-mkdir -p $(dir $@)
	@$(CONF_CC) $(CONF_CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@$(COLORECHO) "\033[32m$(CONF_CC)\033[0m	$<"
	@$(CONF_CC) $(CONF_CFLAGS) -c -o $@ $<

$(OBJ_PREFIX)/conf: $(AUTOGEN_OBJS) $(PARSER_OBJS) $(CONF_OBJS)
	@$(COLORECHO) "\033[32m$(CONF_CC)\033[0m	\033[44m$@\033[0m"
	@$(CONF_CC) -o $@ $^ $(CONF_LDFLAGS)

$(OBJ_PREFIX)/mconf: $(AUTOGEN_OBJS) $(PARSER_OBJS) $(LXDIALOG_OBJS) $(MCONF_OBJS)
	@$(COLORECHO) "\033[32m$(CONF_CC)\033[0m	\033[44m$@\033[0m"
	@$(CONF_CC) -o $@ $^ $(CONF_LDFLAGS)
