// Generic two-input combinational mux suitable for reset/test selection.
// Technology-specific flows may replace this module with an equivalent cell.
module generic_clkmux2 (
    input  logic in0,
    input  logic in1,
    input  logic select,
    output logic out
);
    assign out = select ? in1 : in0;
endmodule
