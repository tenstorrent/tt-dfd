include bender-targets.mk


DFD_DIR = rtl/dfd
CUSTOM_RTL_DIR = scripts/cust_rtl
CLAC_DIR = scripts/cla

.PHONY: tests top_test apb_test clean build

tests: top_test apb_test

build: cust_rtl.stamp tt_dfd.f

cust_rtl.stamp: $(DFD_DIR)/dfd_top.sv $(CUSTOM_RTL_DIR)/process_all.sh
	./$(CUSTOM_RTL_DIR)/process_all.sh
	touch cust_rtl.stamp

cust_rtl: cust_rtl_stamp
	
tt_dfd.f: Bender.yml Bender.lock bender-targets.mk cust_rtl.stamp
	bender update
	bender script flist-plus $(BENDER_TARGETS) $(BENDER_SIMULATION_TARGETS) > tt_dfd.f


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

clean:
	git clean -fXd