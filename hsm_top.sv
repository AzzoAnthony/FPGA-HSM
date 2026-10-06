module hsm_top (
    input  logic clk,
    input  logic rst_n,
    input  logic uart_rxd,
    output logic uart_txd,
    input  logic tamper,
    output logic led_locked
);

    logic         rx_valid;
    logic [7:0]   rx_byte;
    logic         tx_start;
    logic [7:0]   tx_byte;
    logic         tx_busy;
    logic         aes_start;
    logic [127:0] aes_plaintext;
    logic         aes_valid_out;
    logic [127:0] aes_result;
    logic [127:0] round_keys [0:10];
    logic         lockout;

    logic         tamper_evt;
    logic         tamper_latched;

    logic [127:0] lfsr;
    logic [127:0] key_reg;
    logic         key_load;

    // KEY1 on the DE10-Lite is active low: 1 = released, 0 = pressed.
    assign tamper_evt = ~tamper;

    // Tamper latch: set-only, clears only on reset or power cycle.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tamper_latched <= 1'b0;
        else if (tamper_evt)
            tamper_latched <= 1'b1;
    end

    assign lockout = tamper_latched;

    // 128-bit maximal-length LFSR, taps 128/126/101/99.
    // NOT a cryptographic RNG - placeholder for a TRNG + DRBG.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 128'h0123456789ABCDEFFEDCBA9876543210;
        else
            lfsr <= {lfsr[126:0],
                     lfsr[127] ^ lfsr[125] ^ lfsr[100] ^ lfsr[98]};
    end

    // Master key register: loaded on KEYGEN, zeroized on lockout.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)        key_reg <= 128'h0;
        else if (lockout)  key_reg <= 128'h0;
        else if (key_load) key_reg <= lfsr;
    end

    uart_rx rx_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .serial_line  (uart_rxd),
        .pulse        (rx_valid),
        .byte_received(rx_byte)
    );

    uart_tx tx_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (tx_start),
        .byte_send  (tx_byte),
        .serial_line(uart_txd),
        .done       (),
        .busy       (tx_busy)
    );

    aes_key_schedule key_sched_inst (
        .key_in     (key_reg),
        .round_keys (round_keys)
    );

    aes_pipeline aes_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .lockout        (lockout),
        .round_keys     (round_keys),
        .plaintext_in   (aes_plaintext),
        .valid_in       (aes_start),
        .ciphertext_out (aes_result),
        .valid_out      (aes_valid_out)
    );

    hsm_fsm fsm_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .tamper         (tamper_latched),
        .uart_rx_valid  (rx_valid),
        .uart_rx_byte   (rx_byte),
        .aes_done       (aes_valid_out),
        .aes_result     (aes_result),
        .uart_tx_busy   (tx_busy),
        .uart_tx_start  (tx_start),
        .uart_tx_byte   (tx_byte),
        .aes_start      (aes_start),
        .aes_plaintext  (aes_plaintext),
        .key_load       (key_load)
    );

    assign led_locked = tamper_latched;

endmodule
