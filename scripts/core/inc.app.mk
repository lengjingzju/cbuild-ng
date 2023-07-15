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

CPFLAGS        += $(OPTIMIZATION_FLAG)
LDFLAGS        += -Wl,-O1
ifeq ($(ENV_OPTIMIZATION),release)
CPFLAGS        += -ffunction-sections -fdata-sections
LDFLAGS        += -Wl,--gc-sections
endif
#LDFLAGS       += -static

# For more description, refer to https://gcc.gnu.org/onlinedocs/gcc-13.1.0/gcc/Instrumentation-Options.html
ifeq ($(ENV_SANITIZER),1)
# Enable AddressSanitizer, a fast memory error detector to detect out-of-bounds and use-after-free bugs.
SANITIZER_FLAG ?= -fsanitize=address
else ifeq ($(ENV_SANITIZER),2)
# Enable ThreadSanitizer, a fast data race detector.
# Memory access instructions are instrumented to detect data race bugs.
SANITIZER_FLAG ?= -fsanitize=thread
else ifeq ($(ENV_SANITIZER),3)
# Enable LeakSanitizer, a memory leak detector. This option only matters for linking of executables,
# and the executable is linked against a library that overrides malloc and other allocator functions.
SANITIZER_FLAG ?= -fsanitize=leak
else ifeq ($(ENV_SANITIZER),4)
# Enable UndefinedBehaviorSanitizer, a fast undefined behavior detector.
# Various computations are instrumented to detect undefined behavior at runtime.
SANITIZER_FLAG ?= -fsanitize=undefined
endif
CPFLAGS        += $(SANITIZER_FLAG)
LDFLAGS        += $(SANITIZER_FLAG)

# For more description, refer to https://gcc.gnu.org/onlinedocs/gcc-13.1.0/gcc/Static-Analyzer-Options.html
ifeq ($(ENV_ANALYZER)-$(shell expr `$(CC) -dumpversion` \>= 10),y-1)
CPFLAGS        += -fanalyzer
LDFLAGS        += -fanalyzer
endif

# Use https://github.com/slimm609/checksec.sh/ to check the secture
ifeq ($(ENV_SECURITY),y)
# NX(No-eXecute) or DEP(Data Execution Prevention)
#-z execstack # the default value is execstack, close it with noexecstack
# Canary
SECURITY_CPFLAGS   += -fstack-protector-strong  # check stack overflow
# Fortify
SECURITY_CPFLAGS   += -D_FORTIFY_SOURCE=2       # check string funcs overflow
SECURITY_CPFLAGS   += -Wformat -Werror=format-security
# PIC(Position Independent Code) / PIE(Position-Independent Executable) / ASLR(Address Space Layout Randomization)
#CPFLAGS: -fPIC for libraries, -fPIE for executables; LDFLAGS: -fPIC for shared libraries, -pie for executables
# Don't link unused shared libraries
SECURITY_LDFLAGS   += -Wl,--as-needed
# RELRO(Relocation Read-Only) https://www.redhat.com/en/blog/hardening-elf-binaries-using-relocation-read-only-relro
SECURITY_LDFLAGS   += -Wl,-z,relro,-z,now

CPFLAGS            += $(SECURITY_CPFLAGS)
PRE_LDFLAGS        += $(SECURITY_LDFLAGS)
endif

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
	@$(2) -c $(if $(filter $(1),$(CXX_SUFFIX)),$$(CXXFLAGS),$$(CFLAGS)) $$(CPFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) $$(PRIVATE_CPFLAGS) -MM -MT $$@ -MF $$(patsubst %.o,%.d,$$@) $$<
	@cat $$(patsubst %.o,%.d,$$@) | sed -e 's/#.*//' -e 's/^[^:]*:\s*//' -e 's/\s*\\$$$$//' -e 's/[ \t\v][ \t\v]*/\n/g' | sed -e '/^$$$$/ d' -e 's/$$$$/:/g' >> $$(patsubst %.o,%.d,$$@)
endif
	@$(COLORECHO) "\033[032m$(2)\033[0m	$$<" $(LOGOUTPUT)
ifneq ($(2),$(AS))
	@$(2) -c $(if $(filter $(1),$(CXX_SUFFIX)),$$(CXXFLAGS),$$(CFLAGS)) $$(CPFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) $$(PRIVATE_CPFLAGS) -o $$@ $$<
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
$$(OBJ_PREFIX)/$(1): PRIVATE_CPFLAGS := -fPIC $(4)
$$(OBJ_PREFIX)/$(1): $$(call translate_obj,$(2)) $(3)
	@$(COLORECHO) "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@rm -f $$@
	@$$(AR) r $$@ $$(call translate_obj,$(2)) -c
ifneq ($(3), )
	@echo OPEN $$@ > $$@.mri $(foreach lib,$(3),
	@echo ADDLIB $(lib) >> $$@.mri)
	@echo SAVE >> $$@.mri
	@echo END >> $$@.mri
	@$$(AR) -M < $$@.mri
	@rm -f $$@.mri
endif
endef

define add-libso-build
libso_names := $(call all_ver_obj,$(1))
LIB_TARGETS += $(patsubst %,$(OBJ_PREFIX)/%,$(call all_ver_obj,$(1)))

$$(OBJ_PREFIX)/$$(firstword $$(libso_names)): PRIVATE_CPFLAGS := -fPIC $(4)
$$(OBJ_PREFIX)/$$(firstword $$(libso_names)): $$(call translate_obj,$(2))
	@$(COLORECHO) "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(call compile_tool,$(2)) -shared -fPIC -o $$@ $$(call translate_obj,$(2)) $$(PRE_LDFLAGS) $$(LDFLAGS) $(3) \
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
$$(OBJ_PREFIX)/$(1): PRIVATE_CPFLAGS := $(if $(filter y,$(ENV_SECURITY)),-fPIE) $(4)
$$(OBJ_PREFIX)/$(1): $$(call translate_obj,$(2))
	@$(COLORECHO) "\033[032mbin:\033[0m	\033[44m$$@\033[0m"
	@$$(call compile_tool,$(2)) -o $$@ $$(call translate_obj,$(2)) $(if $(filter y,$(ENV_SECURITY)),-pie) $$(PRE_LDFLAGS) $$(LDFLAGS) $(3)
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
