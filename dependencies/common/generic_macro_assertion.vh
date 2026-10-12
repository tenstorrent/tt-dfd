`ifndef GENERIC_MACRO_ASSERTION_VH
`define GENERIC_MACRO_ASSERTION_VH

`define ASSERT_MACRO(assertion_name, clk, rst_n, en, expression, error_message) \
    `ifdef ASSERTION_ENABLE \
        always @(posedge clk) begin \
            if (!(rst_n)) begin \
            end else begin \
                en_x_``assertion_name: assert(!$isunknown(en)) else $error("%m: Xs in assertion en"); \
                if (en) begin \
                    x_``assertion_name: assert(!$isunknown(expression)) else $error("%m: Xs in assertion"); \
                    assertion_name: assert(expression) else $error("%m: %s", error_message); \
                end \
            end \
        end \
    `endif

`define ASSERT_MACRO_ONE_HOT(assertion_name, clk, rst_n, en, expression, error_message) \
    `ifdef ASSERTION_ENABLE \
        always @(posedge clk) begin \
            if (!(rst_n)) begin \
            end else begin \
                en_x_``assertion_name: assert(!$isunknown(en)) else $error("%m: Xs in assertion en"); \
                if (en) begin \
                    x_``assertion_name: assert(!$isunknown($onehot(expression))) else $error("%m: Xs in assertion"); \
                    assertion_name: assert($onehot(expression)) else $error("%m: %s", error_message); \
                end \
            end \
        end \
    `endif

`endif
