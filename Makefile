BENDER_TARGETS ?= -t dfd_rtl -t dfd_dv -t rtl -t dfd_cust_rtl
BENDER_SIMULATION_TARGETS ?= -t simulation
BENDER_SYNTHESIS_TARGETS ?= -t synthesis

BENDER_TARGETS += -t common_cells_rtl
BENDER_TARGETS += -t apb_rtl
BENDER_TARGETS += -t axi_rtl

DFD_DIR = rtl/dfd
CUSTOM_RTL_DIR = scripts/cust_rtl
CLAC_DIR = scripts/cla

.PHONY: tests top_test apb_test clean build cust_rtl

tests: top_test apb_test

build: cust_rtl.stamp tt_dfd.f

cust_rtl.stamp: $(DFD_DIR)/dfd_top.sv $(CUSTOM_RTL_DIR)/process_all.sh $(CUSTOM_RTL_DIR)/process_sv.py
	./$(CUSTOM_RTL_DIR)/process_all.sh
	touch cust_rtl.stamp

cust_rtl: cust_rtl.stamp
	
tt_dfd.f: Bender.yml Bender.lock cust_rtl.stamp
	bender update
	bender script flist-plus $(BENDER_TARGETS) $(BENDER_SIMULATION_TARGETS) > tt_dfd.f


top_test: build
	vcs -timescale=1ns/1ns -full64 -f tt_dfd.f -sverilog -top dfd_tb -debug_access+all -lca -kdb
	./simv

apb_test: build
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

tt_dfd_lint: build
	spyglass -project lint/tt_dfd.prj -batch -goals lint/lint_rtl

tt_dfd_lint_enhanced: build
	spyglass -project lint/tt_dfd.prj -batch -goals lint/lint_rtl_enhanced

clean:
	git clean -fXd