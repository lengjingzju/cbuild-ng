WORKDIR        := $(ENV_CFG_ROOT)
CONF_OUT       := $(WORKDIR)
KCONFIG        := $(WORKDIR)/Kconfig

.PHONY: deps all clean

all:

include $(ENV_MAKE_DIR)/inc.conf.mk
-include $(WORKDIR)/.config
-include $(WORKDIR)/auto.mk

all: $(ALL_TARGETS)

clean: cleanconfig $(ALL_CLEAN_TARGETS)
	@rm -f $(WORKDIR)

deps:
	@mkdir -p $(WORKDIR)
	@python3 $(ENV_TOOL_DIR)/gen_build_chain.py -m $(WORKDIR)/auto.mk -k $(KCONFIG) -d mk.deps -c mk.kconf -s test-hello:test-hello-add:test-hello-sub
