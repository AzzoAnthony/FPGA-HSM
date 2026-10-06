module hsm_top (
    input  logic clk,
    input  logic rst_n,
    input  logic uart_rxd,
    output logic uart_txd,
    input  logic tamper,
    output logic led_locked
);

    logic        rx_valid;
    logic [7:0]  rx_byte;
    logic        tx_start;
    logic [7:0]  tx_byte;
    logic        aes_start;
    logic [127:0] aes_plaintext;
    logic        aes_valid_out;
    logic [127:0] aes_result;
    logic [127:0] round_keys [0:10];
    logic        lockout;

    assign lockout = tamper;
    logic tx_busy;

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
        .done       ()
        .busy       (tx_busy)
    );

    aes_key_schedule key_sched_inst (
        .key_in     (128'hDEADBEEFCAFEBABE0123456789ABCDEF),
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
        .tamper         (tamper),
        .uart_rx_valid  (rx_valid),
        .uart_rx_byte   (rx_byte),
        .aes_done       (aes_valid_out),
        .aes_result     (aes_result),
        .uart_tx_busy   (tx_busy),
        .uart_tx_start  (tx_start),
        .uart_tx_byte   (tx_byte),
        .aes_start      (aes_start),
        .aes_plaintext  (aes_plaintext)
    );

    assign led_locked = tamper;

endmodule
