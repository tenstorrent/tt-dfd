// SPDX-License-Identifier: Apache-2.0
// Open-source, parallel N-priority encoder (tree-based)
// Finds the first N set bits in a request vector, outputs their data, one-hot, and encoded positions.
// Generic, synthesizable SystemVerilog.

module generic_ffs_ignore_N #(
    parameter DIR_L2H    = 1,              // Direction of Priority (1 = LSB first, 0 = MSB first)
    parameter WIDTH      = 8,              // Number of inputs
    parameter SIZE       = ($clog2(WIDTH) > 1 ? $clog2(WIDTH) : 1), // Log2 Number of inputs
    parameter DATA_WIDTH = 4,              // Width of data
    parameter NUM_SEL    = 3               // Number of outputs (N)
) (
    input  [WIDTH-1:0]                         req_in,    // Request vector
    input  [WIDTH-1:0][DATA_WIDTH-1:0]         data_in,   // Data array
    output logic [NUM_SEL-1:0]                 req_sum,   // Valid flag for each output
    output logic [NUM_SEL-1:0][DATA_WIDTH-1:0] data_out,  // Data for each output
    output logic [NUM_SEL-1:0][WIDTH-1:0]      req_out,   // One-hot for each output
    output logic [NUM_SEL-1:0][SIZE-1:0]       enc_req_out// Encoded index for each output
);
    // Pad input vectors to the next power of 2 for a complete binary tree
    localparam PAD_WIDTH = 1 << SIZE;
    logic [PAD_WIDTH-1:0][DATA_WIDTH-1:0] pad_data;
    logic [PAD_WIDTH-1:0]                 pad_req;

    // Pad with zeros (avoid X to prevent propagation in formal/LEC)
    always_comb begin
        for (int i = 0; i < PAD_WIDTH; i++) begin
            pad_data[i] = (i < WIDTH) ? data_in[i] : '0;
            pad_req[i]  = (i < WIDTH) ? req_in[i]  : 1'b0;
        end
    end

    // Tree arrays for each level (double-buffered)
    logic [2][PAD_WIDTH-1:0][NUM_SEL-1:0][DATA_WIDTH-1:0] tree_data;
    logic [2][PAD_WIDTH-1:0][NUM_SEL-1:0][PAD_WIDTH-1:0]  tree_mask;
    logic [2][PAD_WIDTH-1:0][NUM_SEL-1:0][SIZE-1:0]       tree_enc;
    logic [2][PAD_WIDTH-1:0][NUM_SEL-1:0]                 tree_valid;

    // Output assignment from root
    // assign data_out    = tree_data[0][0];
    // slice PAD_WIDTH mask to WIDTH
    always_comb for (int oi = 0; oi < NUM_SEL; oi++) req_out[oi] = tree_mask[0][0][oi][WIDTH-1:0];
    // assign enc_req_out = tree_enc[0][0];
    // assign req_sum     = tree_valid[0][0];

    always_comb begin
        // Temporary indices and holders (declare once for tool compatibility)
        integer i0, n0, lvl_i, node_i, curr, prev, nodes_v, left_i, right_i, idx_i, n1;
        integer max_lower_i, max_curr_i, bkts_i;
        // predeclare per-iteration updated masks/encodings
        logic [NUM_SEL-1:0][PAD_WIDTH-1:0] r_mask_upd, l_mask_upd;
        logic [NUM_SEL-1:0][SIZE-1:0]      r_enc_upd,  l_enc_upd;
        logic [NUM_SEL-1:0][DATA_WIDTH-1:0] merged_data;
        logic [NUM_SEL-1:0][WIDTH-1:0]      merged_mask;
        logic [NUM_SEL-1:0][SIZE-1:0]       merged_enc;
        logic [NUM_SEL-1:0]                 merged_valid;

        // Clear tree buffers to avoid X propagation
        tree_data  = '0;
        tree_mask  = '0;
        tree_enc   = '0;
        tree_valid = '0;

        // Initialize leaves
        for (i0 = 0; i0 < PAD_WIDTH; i0 = i0 + 1) begin
            for (n0 = 0; n0 < NUM_SEL; n0 = n0 + 1) begin
                tree_data[1][i0][n0]  = (n0 == 0) ? pad_data[i0] : '0;
                // seed mask with LSB bit only; path bits added by shifts at upper levels
                tree_mask[1][i0][n0]  = '0;
                if (n0 == 0 && pad_req[i0]) tree_mask[1][i0][n0][0] = 1'b1;
                tree_enc[1][i0][n0]   = (n0 == 0) ? SIZE'(i0) : '0;
                tree_valid[1][i0][n0] = (n0 == 0) ? pad_req[i0] : 1'b0;
            end
        end
        // Build tree upwards
        for (lvl_i = SIZE-1; lvl_i >= 0; lvl_i = lvl_i - 1) begin
            curr    = lvl_i % 2;
            prev    = (lvl_i + 1) % 2;
            nodes_v = 1 << lvl_i;
            // bucket limits per level (mirror reference)
            // declare as pre-declared temps (tools may not allow inline integer decls)
            max_lower_i = (((1 << (SIZE - lvl_i - 1)) > NUM_SEL) ? NUM_SEL : (1 << (SIZE - lvl_i - 1)));
            max_curr_i  = (((max_lower_i * 2) > NUM_SEL) ? NUM_SEL : (max_lower_i * 2));
            for (node_i = 0; node_i < nodes_v; node_i = node_i + 1) begin
                // Merge left and right children
                left_i  = 2*node_i + (DIR_L2H ? 0 : 1);
                right_i = 2*node_i + (DIR_L2H ? 1 : 0);
                // Initialize merged slots to defaults
                merged_data  = '0;
                merged_mask  = '0;
                merged_enc   = '0;
                merged_valid = '0;

                // Prepare updated right/left with path bit and mask shift for this level
                for (n1 = 0; n1 < NUM_SEL; n1 = n1 + 1) begin
                    r_mask_upd[n1] = tree_mask[prev][right_i][n1] << (DIR_L2H << (SIZE - lvl_i - 1));
                    r_enc_upd [n1] = tree_enc [prev][right_i][n1] | (SIZE'(DIR_L2H) << (SIZE - 1 - lvl_i));
                    l_mask_upd[n1] = tree_mask[prev][left_i ][n1] << ((DIR_L2H ? 0 : 1) << (SIZE - lvl_i - 1));
                    l_enc_upd [n1] = tree_enc [prev][left_i ][n1] | (SIZE'(!DIR_L2H) << (SIZE - 1 - lvl_i));
                end

                // Base: copy RIGHT buckets up to max_lower
                for (n1 = 0; n1 < NUM_SEL; n1 = n1 + 1) begin
                    if (n1 < max_lower_i) begin
                        merged_mask [n1] = r_mask_upd[n1];
                        merged_data [n1] = tree_data[prev][right_i][n1];
                        merged_enc  [n1] = r_enc_upd[n1];
                        merged_valid[n1] = tree_valid[prev][right_i][n1];
                    end
                end
                // Overlay LEFT at bucket n1 when valid, and shift RIGHT entries
                for (n1 = 0; n1 < NUM_SEL; n1 = n1 + 1) begin
                    if (n1 < max_lower_i && tree_valid[prev][left_i][n1]) begin
                        // place left at n1
                        merged_mask [n1] = l_mask_upd[n1];
                        merged_data [n1] = tree_data[prev][left_i][n1];
                        merged_enc  [n1] = l_enc_upd[n1];
                        merged_valid[n1] = 1'b1;
                        // shift right for bktsft=bktl+1.. up to max_curr-1
                        for (bkts_i = n1 + 1; bkts_i < NUM_SEL; bkts_i = bkts_i + 1) begin
                            if (bkts_i < max_curr_i) begin
                                merged_mask [bkts_i] = r_mask_upd[bkts_i - n1 - 1];
                                merged_data [bkts_i] = tree_data[prev][right_i][bkts_i - n1 - 1];
                                merged_enc  [bkts_i] = r_enc_upd [bkts_i - n1 - 1];
                                merged_valid[bkts_i] = tree_valid[prev][right_i][bkts_i - n1 - 1];
                            end
                        end
                    end
                end
                // Assign merged results to current node
                for (n1 = 0; n1 < NUM_SEL; n1 = n1 + 1) begin
                    tree_data [curr][node_i][n1]  = merged_data [n1];
                    tree_mask [curr][node_i][n1]  = merged_mask [n1];
                    tree_enc  [curr][node_i][n1]  = merged_enc  [n1];
                    tree_valid[curr][node_i][n1]  = merged_valid[n1];
                end
            end
        end

        data_out = tree_data[0][0];
        enc_req_out = tree_enc[0][0];
        req_sum = tree_valid[0][0];
    end
endmodule