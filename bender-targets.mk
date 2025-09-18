# __________________
#
# Tenstorrent CONFIDENTIAL
# __________________
#
#  Tenstorrent Inc.
#  All Rights Reserved.
#
# NOTICE:  All information contained herein is, and remains
# the property of Tenstorrent Inc.  The intellectual
# and technical concepts contained
# herein are proprietary to Tenstorrent Inc.
# and may be covered by U.S., Canadian and Foreign Patents,
# patents in process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained
# from Tenstorrent Inc.

BENDER_TARGETS ?= -t dfd_rtl -t dfd_dv -t rtl -t dfd_cust_rtl
BENDER_SIMULATION_TARGETS ?= -t simulation
BENDER_SYNTHESIS_TARGETS ?= -t synthesis

BENDER_TARGETS += -t common_cells_rtl
BENDER_TARGETS += -t apb_rtl
BENDER_TARGETS += -t axi_rtl

