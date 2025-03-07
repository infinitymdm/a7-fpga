module top_sha3 (
    input  logic       gclk,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    input  logic       uart_rx_in,
    output logic       uart_tx_out,
    output logic [2:0] ld3, ld2, ld1, ld0,
    output logic [7:4] ld
);

    assign ld = sw;
    generate
        for (genvar i = 0; i < 3; i++) begin: rgb_leds
            assign ld3[i] = sw[i] & btn[3];
            assign ld2[i] = sw[i] & btn[2];
            assign ld1[i] = sw[i] & btn[1];
        end
    endgenerate

    localparam D = 512;
    localparam L = 6;
    localparam S = 4;
    localparam R = 1600 - 2*D;

    logic [R-1:0] message_chunk;
    logic [D-1:0] digest;
    logic enable_sha;
    logic uart_byte_ready;

    // TODO: Figure out timing for this
    keccak #(D, L, S) dut (
        .clk(gclk), .reset(btn[0]), .enable(enable_sha),
        .message(message_chunk), .digest
    );

    // Use UART to display the hashed value
    // TODO: Use str.hextoa(i) to convert digest bytes to text
    uart_tx uart_simplex_tx (
        .clk(gclk),
        .data_ready(1'b1),
        .data(8'h2b), // ASCII "+"
        .rx_ready(1'b1),
        .tx_busy(),
        .tx(uart_tx_out)
    );

    // Goal: Test the SHA3 algorithm in hardware
    //  - Load a ROM with a message we want to hash (something we can easily check with openssl)
    //  - Hash the message using SHA3 hardware
    //  - Display the result (over UART simplex? verify against ROM and light an LED?)

endmodule
