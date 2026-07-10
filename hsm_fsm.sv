module hsm_fsm (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         tamper,
    input  logic         uart_rx_valid,
    input  logic [7:0]   uart_rx_byte,
    input  logic         aes_done,
    input  logic [127:0] aes_result,
    output logic         uart_tx_start,
    output logic [7:0]   uart_tx_byte,
    output logic         aes_start,
    output logic [127:0] aes_plaintext
);

    typedef enum logic [2:0] {
        IDLE        = 3'd0,
        RECEIVE_CMD = 3'd1,
        RECEIVE_LEN = 3'd2,
        COLLECT     = 3'd3,
        EXECUTE     = 3'd4,
        KEYGEN      = 3'd5,
        LOCKOUT     = 3'd6,
        SEND        = 3'd7
    } state_t;

    state_t current_state, next_state;

    logic [7:0]   cmd_reg;
    logic [7:0]   len_reg;
    logic [127:0] payload_reg;
    logic [3:0]   byte_count;
    logic [7:0]   send_buffer [0:16];
    logic [4:0]   send_count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else if (tamper)
            current_state <= LOCKOUT;
        else
            current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:        if (uart_rx_valid) next_state = RECEIVE_CMD;
            RECEIVE_CMD: if (uart_rx_valid) next_state = RECEIVE_LEN;
            RECEIVE_LEN: begin
                if (uart_rx_valid) begin
                    case (cmd_reg)
                        8'h01:        next_state = KEYGEN;
                        8'h04:        next_state = LOCKOUT;
                        8'h02, 8'h03: next_state = COLLECT;
                        default:      next_state = IDLE;
                    endcase
                end
            end
            COLLECT:  if (uart_rx_valid && (byte_count == len_reg - 1)) next_state = EXECUTE;
            EXECUTE:  if (aes_done) next_state = SEND;
            KEYGEN:   next_state = SEND;
            LOCKOUT:  next_state = SEND;
            SEND:     if (send_count == 0) next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_reg       <= 8'h00;
            len_reg       <= 8'h00;
            payload_reg   <= 128'h0;
            byte_count    <= 4'd0;
            aes_start     <= 1'b0;
            uart_tx_start <= 1'b0;
            uart_tx_byte  <= 8'h00;
            aes_plaintext <= 128'h0;
            send_count    <= 5'd0;
        end else begin
            aes_start     <= 1'b0;
            uart_tx_start <= 1'b0;

            case (current_state)
                IDLE: begin
                    byte_count  <= 4'd0;
                    payload_reg <= 128'h0;
                end
                RECEIVE_CMD: begin
                    if (uart_rx_valid)
                        cmd_reg <= uart_rx_byte;
                end
                RECEIVE_LEN: begin
                    if (uart_rx_valid)
                        len_reg <= uart_rx_byte;
                end
                COLLECT: begin
                    if (uart_rx_valid) begin
                        payload_reg <= (payload_reg << 8) | uart_rx_byte;
                        byte_count  <= byte_count + 1;
                    end
                end
                EXECUTE: begin
                    aes_start     <= 1'b1;
                    aes_plaintext <= payload_reg;
                    if (aes_done) begin
                        send_buffer[0]  <= 8'hAA;
                        send_buffer[1]  <= aes_result[127:120];
                        send_buffer[2]  <= aes_result[119:112];
                        send_buffer[3]  <= aes_result[111:104];
                        send_buffer[4]  <= aes_result[103:96];
                        send_buffer[5]  <= aes_result[95:88];
                        send_buffer[6]  <= aes_result[87:80];
                        send_buffer[7]  <= aes_result[79:72];
                        send_buffer[8]  <= aes_result[71:64];
                        send_buffer[9]  <= aes_result[63:56];
                        send_buffer[10] <= aes_result[55:48];
                        send_buffer[11] <= aes_result[47:40];
                        send_buffer[12] <= aes_result[39:32];
                        send_buffer[13] <= aes_result[31:24];
                        send_buffer[14] <= aes_result[23:16];
                        send_buffer[15] <= aes_result[15:8];
                        send_buffer[16] <= aes_result[7:0];
                        send_count      <= 5'd17;
                    end
                end
                KEYGEN: begin
                    send_buffer[0] <= 8'hAA;
                    send_count     <= 5'd1;
                end
                LOCKOUT: begin
                    payload_reg    <= 128'h0;
                    cmd_reg        <= 8'h00;
                    send_buffer[0] <= 8'hAA;
                    send_count     <= 5'd1;
                end
                SEND: begin
                    if (send_count > 0) begin
                        uart_tx_byte  <= send_buffer[17 - send_count];
                        uart_tx_start <= 1'b1;
                        send_count    <= send_count - 1;
                    end
                end
            endcase
        end
    end

endmodule
