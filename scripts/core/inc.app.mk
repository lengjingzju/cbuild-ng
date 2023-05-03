############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
# https://github.com/lengjingzju/cbuild-ng #
############################################

ifeq ($(KERNELRELEASE), )

COLORECHO      ?= $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
SRC_PATH       ?= .
IGNORE_PATH    ?= .git .pc scripts output
REG_SUFFIX     ?= c cpp S
ifeq ($(USING_CXX_BUILD_C), y)
CXX_SUFFIX     ?= c cc cp cxx cpp CPP c++ C
else
CXX_SUFFIX     ?= cc cp cxx cpp CPP c++ C
endif
ASM_SUFFIX     ?= S s asm

SRCS           ?= $(shell find $(SRC_PATH) $(patsubst %,-path '*/%' -prune -o,$(IGNORE_PATH)) \
                      $(shell echo '$(patsubst %,-o -name "*.%" -print,$(REG_SUFFIX))' | sed 's/^...//') \
                  | sed "s/^\(\.\/\)\(.*\)/\2/g" | xargs)

CPFLAGS        += -I. -I./include $(patsubst %,-I%,$(filter-out .,$(SRC_PATH))) $(patsubst %,-I%/include,$(filter-out .,$(SRC_PATH))) -I$(OBJ_PREFIX)

ifneq ($(SEARCH_HDRS), )
CPFLAGS        += $(call link_hdrs)
LDFLAGS        += $(call link_libs)
endif

CPFLAGS        += -Wall # This enables all the warnings about constructions that some users consider questionable.
CPFLAGS        += -Wextra # This enables some extra warning flags that are not enabled by -Wall (This option used to be called -W).
CPFLAGS        += -Wlarger-than=$(if $(object_byte_size),$(object_byte_size),1024) # Warn whenever an object is defined whose size exceeds object_byte_size.
CPFLAGS        += -Wframe-larger-than=$(if $(frame_byte_size),$(frame_byte_size),8192) # Warn if the size of a function frame exceeds frame_byte_size.
#CPFLAGS       += -Wdate-time #Warn when macros __TIME__, __DATE__ or __TIMESTAMP__ are encountered as they might prevent bit-wise-identical reproducible compilations.

CPFLAGS        += $(CC_OPT_VALUE)
ifeq ($(CC_OPT_OPTION),release)
CPFLAGS        += -ffunction-sections -fdata-sections
LDFLAGS        += -Wl,--gc-sections
endif
#LDFLAGS       += -static

define translate_obj
$(patsubst %,$(OBJ_PREFIX)/%.o,$(basename $(1)))
endef

define set_flags
$(foreach v,$(2),$(eval $(1)_$(patsubst %,%.o,$(basename $(v))) = $(3)))
endef

define all_ver_obj
$(strip \
	$(if $(word 4,$(1)), \
		$(if $(word 4,$(1)),$(word 1,$(1)).$(word 2,$(1)).$(word 3,$(1)).$(word 4,$(1))) \
		$(if $(word 2,$(1)),$(word 1,$(1)).$(word 2,$(1))) \
		$(word 1,$(1)) \
		,\
		$(if $(word 3,$(1)),$(word 1,$(1)).$(word 2,$(1)).$(word 3,$(1))) \
		$(if $(word 2,$(1)),$(word 1,$(1)).$(word 2,$(1))) \
		$(word 1,$(1)) \
	)
)
endef

define compile_tool
$(if $(filter $(patsubst %,\%.%,$(CXX_SUFFIX)),$(1)),$(CXX),$(CC))
endef

define compile_obj
ifeq ($(filter $(1),$(REG_SUFFIX)),$(1))
ifneq ($(filter %.$(1),$(SRCS)), )
$$(patsubst %.$(1),$$(OBJ_PREFIX)/%.o,$$(filter %.$(1),$$(SRCS))): $$(OBJ_PREFIX)/%.o: %.$(1)
	@mkdir -p $$(dir $$@)
ifeq ($(filter $(1),$(ASM_SUFFIX)), )
	@$(2) -c $(if $(filter $(1),$(CXX_SUFFIX)),$$(CXXFLAGS),$$(CFLAGS)) $$(CPFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) -MM -MT $$@ -MF $$(patsubst %.o,%.d,$$@) $$<
endif
	@$(COLORECHO) "\033[032m$(2)\033[0m	$$<" $(LOGOUTPUT)
ifneq ($(2),$(AS))
	@$(2) -c $(if $(filter $(1),$(CXX_SUFFIX)),$$(CXXFLAGS),$$(CFLAGS)) $$(CPFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) -fPIC -o $$@ $$<
else
	@$(2) $$(AFLAGS) $$(AFLAGS_$$(patsubst %.$(1),%.o,$$<)) -o $$@ $$<
endif
endif
endif
endef

ifeq ($(USING_CXX_BUILD_C), y)
$(eval $(call compile_obj,c,$$(CXX)))
else
$(eval $(call compile_obj,c,$$(CC)))
endif
$(eval $(call compile_obj,cc,$$(CXX)))
$(eval $(call compile_obj,cp,$$(CXX)))
$(eval $(call compile_obj,cxx,$$(CXX)))
$(eval $(call compile_obj,cpp,$$(CXX)))
$(eval $(call compile_obj,CPP,$$(CXX)))
$(eval $(call compile_obj,c++,$$(CXX)))
$(eval $(call compile_obj,C,$$(CXX)))
$(eval $(call compile_obj,S,$$(CC)))
$(eval $(call compile_obj,s,$$(AS)))
$(eval $(call compile_obj,asm,$$(AS)))

OBJS            = $(call translate_obj,$(SRCS))
DEPS            = $(patsubst %.o,%.d,$(OBJS))
$(OBJS): $(MAKEFILE_LIST)
-include $(DEPS)

.PHONY: clean_objs

clean_objs:
	@-rm -rf $(OBJS) $(DEPS)

define add-liba-build
LIB_TARGETS += $$(OBJ_PREFIX)/$(1)
$$(OBJ_PREFIX)/$(1): $$(call translate_obj,$(2))
	@$(COLORECHO) "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(AR) r $$@ $$(call translate_obj,$(2)) -c
endef

define add-libso-build
libso_names := $(call all_ver_obj,$(1))
LIB_TARGETS += $(patsubst %,$(OBJ_PREFIX)/%,$(call all_ver_obj,$(1)))

$$(OBJ_PREFIX)/$$(firstword $$(libso_names)): $$(call translate_obj,$(2))
	@$(COLORECHO) "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(call compile_tool,$(2)) -shared -fPIC -o $$@ $$(call translate_obj,$(2)) $$(LDFLAGS) $(3) \
		$$(if $$(findstring -soname=,$(3)),,-Wl$$(comma)-soname=$$(if $$(word 2,$(1)),$$(firstword $(1)).$$(word 2,$(1)),$(1)))

ifneq ($$(word 2,$$(libso_names)), )
$$(OBJ_PREFIX)/$$(word 2,$$(libso_names)): $$(OBJ_PREFIX)/$$(word 1,$$(libso_names))
	@cd $$(OBJ_PREFIX) && ln -sf $$(patsubst $$(OBJ_PREFIX)/%,%,$$<) $$(patsubst $$(OBJ_PREFIX)/%,%,$$@)
endif

ifneq ($$(word 3,$$(libso_names)), )
$$(OBJ_PREFIX)/$$(word 3,$$(libso_names)): $$(OBJ_PREFIX)/$$(word 2,$$(libso_names))
	@cd $$(OBJ_PREFIX) && ln -sf $$(patsubst $$(OBJ_PREFIX)/%,%,$$<) $$(patsubst $$(OBJ_PREFIX)/%,%,$$@)
endif

ifneq ($$(word 4,$$(libso_names)), )
$$(OBJ_PREFIX)/$$(word 4,$$(libso_names)): $$(OBJ_PREFIX)/$$(word 3,$$(libso_names))
	@cd $$(OBJ_PREFIX) && ln -sf $$(patsubst $$(OBJ_PREFIX)/%,%,$$<) $$(patsubst $$(OBJ_PREFIX)/%,%,$$@)
endif

endef

define add-bin-build
BIN_TARGETS += $$(OBJ_PREFIX)/$(1)
$$(OBJ_PREFIX)/$(1): $$(call translate_obj,$(2))
	@$(COLORECHO) "\033[032mbin:\033[0m	\033[44m$$@\033[0m"
	@$$(call compile_tool,$(2)) -o $$@ $$(call translate_obj,$(2)) $$(LDFLAGS) $(3)
endef

ifneq ($(LIBA_NAME), )
$(eval $(call add-liba-build,$(LIBA_NAME),$(SRCS)))
endif

ifneq ($(LIBSO_NAME), )
$(eval $(call add-libso-build,$(LIBSO_NAME),$(SRCS)))
endif

ifneq ($(BIN_NAME), )
$(eval $(call add-bin-build,$(BIN_NAME),$(SRCS)))
endif

INSTALL_LIBRARIES ?= $(LIB_TARGETS)
INSTALL_BINARIES  ?= $(BIN_TARGETS)

endif
