BENDER_TARGETS ?= -t dfd_rtl -t dfd_dv -t rtl -t dfd_cust_rtl
BENDER_SIMULATION_TARGETS ?= -t simulation
BENDER_SYNTHESIS_TARGETS ?= -t synthesis

BENDER_TARGETS += -t common_cells_rtl
BENDER_TARGETS += -t apb_rtl
BENDER_TARGETS += -t axi_rtl

