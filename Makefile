include bender-targets.mk


CLAC_DIR = scripts/cla
BENDER = bender
BUILD_DIR ?= build
TOP ?= dfd_top_cla_dst_ntrace_axi
COMPILER ?= vcs

SUPPORTED_COMPILERS := vcs verilator

# Multi-target builds (build-all, build-all-compat, compat) keep each top's
# compiler output in $(LOG_DIR)/<compiler>_<top>.log and print one status line
# per top. Every top is attempted; the exit status is non-zero if any failed.
LOG_DIR ?= $(BUILD_DIR)/logs

define run_tops
	@mkdir -p $(LOG_DIR); \
	fail=0; total=0; \
	for top in $(1); do \
		total=$$((total + 1)); \
		log=$(LOG_DIR)/$(COMPILER)_$$top.log; \
		printf '%-45s' "$$top"; \
		if $(MAKE) --no-print-directory build TOP=$$top COMPILER=$(COMPILER) > $$log 2>&1; then \
			echo "PASS"; \
		else \
			echo "FAIL  (log: $$log)"; fail=$$((fail + 1)); \
		fi; \
	done; \
	echo "$$((total - fail))/$$total builds passed ($(COMPILER)); logs in $(LOG_DIR)/"; \
	[ $$fail -eq 0 ]
endef

GENERATED_TOPS := \
	dfd_top_cla_dst_apb \
	dfd_top_cla_dst_axi \
	dfd_top_cla_dst_ntrace_apb \
	dfd_top_cla_dst_ntrace_apb_no_trace_top \
	dfd_top_cla_dst_ntrace_axi \
	dfd_top_cla_dst_ntrace_axi_no_trace_top \
	dfd_top_cla_dstx_ntracex_apb \
	dfd_top_cla_ntrace_apb \
	dfd_top_dstx_ntracex_apb \
	dfd_top_dstx_ntracex_axi \
	dfd_top_cla_dst_apb_no_trace_top \
	dfd_top_cla_ntrace_apb_no_trace_top \
	dfd_top_dst_apb \
	dfd_top_dst_apb_no_trace_top \
	dfd_top_dst_ntrace_apb \
	dfd_top_dst_ntrace_apb_no_trace_top \
	dfd_top_ntrace_apb \
	dfd_top_ntrace_apb_no_trace_top

# Legacy-interface compatibility wrappers (rtl/compat). Each presents the port
# and parameter list of the pre-v2 top of the same name and instantiates the
# generated top above it, so an existing integration builds unchanged.
COMPAT_TOPS := \
	dfd_top_cla_dst_mmr \
	dfd_top_cla_ntrace_mmr \
	dfd_top_cla_dst_ntrace_mmr \
	dfd_top_tnif \
	dfd_top_cla_tnif \
	dfd_top_cla_dst_notrace_mmr \
	dfd_top_cla_dst_ntrace_notrace_mmr \
	dfd_top_cla_ntrace_notrace_mmr \
	dfd_top_dst_mmr \
	dfd_top_dst_notrace_mmr \
	dfd_top_dst_ntrace_mmr \
	dfd_top_dst_ntrace_notrace_mmr \
	dfd_top_ntrace_mmr \
	dfd_top_ntrace_notrace_mmr

ALL_TOPS := $(GENERATED_TOPS) $(COMPAT_TOPS)

vcs_FLIST = tt_dfd.f
verilator_FLIST = tt_dfd.verilator.f

vcs_BUILD = vcs -timescale=1ns/1ns -full64 -f $(vcs_FLIST) -sverilog -top $(TOP) \
	-debug_access+all -lca -kdb -o $(BUILD_DIR)/vcs/$(TOP)

verilator_BUILD = verilator --cc --build -Wno-fatal -f $(verilator_FLIST) \
	--top-module $(TOP) --Mdir $(BUILD_DIR)/verilator/$(TOP)

.PHONY: tests top_test apb_test clean build build-all build-all-compat check-compat compat list-tops list-compilers

tests: top_test apb_test

build: $($(COMPILER)_FLIST)
	@if ! echo " $(ALL_TOPS) " | grep -q " $(TOP) "; then \
		echo "Unknown top: $(TOP)"; \
		echo "Run 'make list-tops' to see valid values."; \
		exit 1; \
	fi
	@if ! echo " $(SUPPORTED_COMPILERS) " | grep -q " $(COMPILER) "; then \
		echo "Unsupported compiler: $(COMPILER)"; \
		echo "Run 'make list-compilers' to see valid values."; \
		exit 1; \
	fi
	mkdir -p $(BUILD_DIR)/$(COMPILER)
	$($(COMPILER)_BUILD)

build-all: $($(COMPILER)_FLIST)
	$(call run_tops,$(ALL_TOPS))

# Legacy wrappers only, for checking drop-in compatibility on its own.
build-all-compat: $($(COMPILER)_FLIST)
	$(call run_tops,$(COMPAT_TOPS))

# Fail unless every legacy wrapper is present: each COMPAT_TOPS entry must have
# rtl/compat/<top>.sv declaring module <top> and be listed in Bender.yml, and
# rtl/compat must not hold a wrapper that COMPAT_TOPS does not know about.
check-compat:
	@missing=""; \
	for top in $(COMPAT_TOPS); do \
		f=rtl/compat/$$top.sv; \
		if [ ! -f $$f ]; then missing="$$missing $$f"; continue; fi; \
		grep -Eq "^module[[:space:]]+$$top([[:space:]]|$$)" $$f || missing="$$missing $$f(module $$top)"; \
		grep -q "rtl/compat/$$top.sv" Bender.yml || missing="$$missing Bender.yml($$top)"; \
	done; \
	for f in rtl/compat/dfd_top_*.sv; do \
		top=$$(basename $$f .sv); \
		echo " $(COMPAT_TOPS) " | grep -q " $$top " || missing="$$missing COMPAT_TOPS($$top)"; \
	done; \
	if [ -n "$$missing" ]; then \
		echo "compat: missing or unregistered:$$missing"; \
		exit 1; \
	fi; \
	echo "compat: all $(words $(COMPAT_TOPS)) wrappers present"

# Check that every wrapper is there, then build each one with $(COMPILER).
compat: check-compat
	@$(MAKE) --no-print-directory build-all-compat COMPILER=$(COMPILER)

list-tops:
	@printf '%s\n' $(ALL_TOPS)

list-compilers:
	@printf '%s\n' $(SUPPORTED_COMPILERS)

tt_dfd.f: Bender.yml Bender.lock bender-targets.mk
	$(BENDER) update
	$(BENDER) script flist-plus $(BENDER_TARGETS) $(BENDER_SIMULATION_TARGETS) > tt_dfd.f

tt_dfd.verilator.f: Bender.yml Bender.lock bender-targets.mk
	$(BENDER) update
	$(BENDER) script flist-plus $(BENDER_TARGETS) $(BENDER_SYNTHESIS_TARGETS) \
		-t verilator > tt_dfd.verilator.f


top_test: tt_dfd.f
	vcs -timescale=1ns/1ns -full64 -f tt_dfd.f -sverilog -top dfd_tb -debug_access+all -lca -kdb
	./simv

apb_test: tt_dfd.f
	vcs -timescale=1ns/1ns -full64 -f tt_dfd.f -sverilog -top dfd_mmrs_tb -debug_access+all -lca -kdb
	./simv > apb_test.log
	cat apb_test.log
	@value=$$(grep -c "Error:" apb_test.log); \
	if [ $$value -gt 0 ]; then \
		echo "$$value ERRROR(S) FOUND IN APB TEST"; \
		exit 1; \
	else \
		echo "APB TEST PASSED"; \
		exit 0; \
	fi

tt_dfd_lint: tt_dfd.f
	spyglass -project lint/tt_dfd.prj -batch -goals lint/lint_rtl

tt_dfd_lint_enhanced: tt_dfd.f
	spyglass -project lint/tt_dfd.prj -batch -goals lint/lint_rtl_enhanced

clean:
	git clean -fXd
