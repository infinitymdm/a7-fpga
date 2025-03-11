module top_sha3 (
    input  logic       gclk,
    input  logic [3:0] sw,
    input  logic [3:0] btn,
    input  logic       uart_rx_in,
    output logic       uart_tx_out,
    output logic [2:0] ld3, ld2, ld1, ld0,
    output logic [7:4] ld
);

    // Goal: Test the SHA3 algorithm in hardware
    //  - Load a ROM with a message we want to hash (something we can easily check with openssl)
    //  - Hash the message using SHA3 hardware
    //  - Display the result over UART simplex

    localparam D = 512;
    localparam L = 6;
    localparam S = 4;
    localparam R = 1600 - 2*D;
    localparam message_file = "top/sha3_512_padded.bin";
    localparam chunk_count = 29; // = $ceil(8*(wc -c message_file)/R)
    localparam baud = 9600;
    localparam gclk_freq = 100000000;
    localparam cycles_per_tx_bit = gclk_freq/baud;

    // Load test message into ROM
    // TODO: Figure out padding (currently pre-padded)
    logic [$clog2(chunk_count)-1:0] chunk_addr;
    logic [R-1:0] chunk;
    sp_rom #(.binfile(message_file), .width(R), .depth(chunk_count)) msg_rom (
        .clk(gclk), .addr(chunk_addr), .data(chunk)
    );

    // Feed message by chunks into dut, one chunk every S cycles
    // Keep track of progress with a cycle counter
    logic [$clog2(S)-1:0] cycle;
    logic [D-1:0] digest;
    logic enable_hash;
    keccak #(D, L, S) dut (
        .clk(gclk), .reset(btn[0]), .enable(enable_hash),
        .message(chunk), .digest
    );
    always_ff @(posedge gclk) begin: cycle_counter
        if (btn[0]) begin: reset
            cycle <= 0;
            chunk_addr <= 0;
            enable_hash <= 1;
        end else if (cycle < S-1) begin: inc_cycle
            cycle <= cycle + 1;
            chunk_addr <= chunk_addr;
            enable_hash <= 1;
        end else begin: inc_chunk
            cycle <= 0;
            chunk_addr <= chunk_addr + 1;
            if (chunk_addr == chunk_count)
                enable_hash <= 0;
            else
                enable_hash <= 1;
        end
    end

    // Use UART to display the hashed value
    // Don't start until enable_hash goes low
    logic [7:0] digest_char;
    logic [$clog2(R/4)-1:0] digest_index;
    logic [$clog2(cycles_per_tx_bit)-1:0] clk_count;
    always @(posedge gclk) begin: get_digest_char
        if (btn[0]) begin: reset
            clk_count <= 0;
            digest_index <= 0;
        end else if (enable_hash) begin: wait_for_hashing
            clk_count <= 0;
            digest_index <= 0;
        end else begin: get_digest_char
            if (clk_count < cycles_per_tx_bit) begin: inc_clk_count
                clk_count <= clk_count + 1;
                digest_index <= digest_index;
            end else begin: inc_dgst_index
                clk_count <= 0;
                digest_index <= digest_index + 1;
            end
        end
    end
    always_comb begin: ascii_lookup
        case(digest[4*digest_index+:4])
            4'h0:    digest_char = 8'h30;
            4'h1:    digest_char = 8'h31;
            4'h2:    digest_char = 8'h32;
            4'h3:    digest_char = 8'h33;
            4'h4:    digest_char = 8'h34;
            4'h5:    digest_char = 8'h35;
            4'h6:    digest_char = 8'h36;
            4'h7:    digest_char = 8'h37;
            4'h8:    digest_char = 8'h38;
            4'h9:    digest_char = 8'h39;
            4'ha:    digest_char = 8'h61;
            4'hb:    digest_char = 8'h62;
            4'hc:    digest_char = 8'h63;
            4'hd:    digest_char = 8'h64;
            4'he:    digest_char = 8'h65;
            4'hf:    digest_char = 8'h66;
            default: digest_char = 8'h3F; // ?
        endcase
    end
    uart_tx uart_simplex_tx (
        .clk(gclk),
        .data_ready(~enable_hash),
        .data(digest_char),
        .rx_ready(1'b1),
        .tx_busy(),
        .tx(uart_tx_out)
    );

    // Assign otherwise unused hardware
    assign ld = sw;
    generate
        for (genvar i = 0; i < 3; i++) begin: rgb_leds
            assign ld3[i] = sw[i] & btn[3];
            assign ld2[i] = sw[i] & btn[2];
            assign ld1[i] = sw[i] & btn[1];
        end
    endgenerate

endmodule
