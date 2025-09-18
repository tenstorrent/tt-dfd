/*************************************************************************
 *
 * Tenstorrent CONFIDENTIAL
 * __________________
 *
 *  Tenstorrent Inc.
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Tenstorrent Inc.  The intellectual
 * and technical concepts contained
 * herein are proprietary to Tenstorrent Inc.
 * and may be covered by U.S., Canadian and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Tenstorrent Inc.
 */
 
package example_dfd_pkg;

localparam L0_DBG_LANE_WIDTH = 16;
localparam L0_DBG_NUM_INPUT_LANES = 8;

localparam L1_DBG_LANE_WIDTH = 16;
localparam L1_DBG_NUM_INPUT_LANES = 9;
localparam FINE_GRAIN_TSTAMP_COUNTER_WIDTH = 8;

typedef struct packed {
  logic   [L0_DBG_LANE_WIDTH-1:0] data;
} hw_t;

endpackage
