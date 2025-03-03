module top_test (
    input  [3:0]  sw,
    output [7:4]  ld,
);

    always_comb begin
        ld[7:4] = sw;
    end

endmodule
