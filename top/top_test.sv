module top_test (
    input  logic       gclk,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    input  logic       uart_tx,
    output logic       uart_rx,
    output logic [2:0] ld3, ld2, ld1, ld0,
    output logic [7:4] ld
);

    assign ld = sw;
    generate
        for (genvar i = 0; i < 3; i++) begin: rgb_leds
            assign ld3[i] = sw[i] & btn[3];
            assign ld2[i] = sw[i] & btn[2];
            assign ld1[i] = sw[i] & btn[1];
            assign ld0[i] = sw[i] & btn[0];
        end
    endgenerate

    always @(posedge gclk) uart_rx = uart_tx;

endmodule
