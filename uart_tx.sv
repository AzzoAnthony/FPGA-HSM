module uart_tx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic [7:0] byte_send,
    output logic       serial_line,
    output logic       done,
    output logic       busy
);

    logic [8:0] baud_counter;
    logic       baud_tick;
    logic [3:0] bit_index;
    logic [9:0] shift_reg;
    logic       sending;

    assign busy = sending;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 9'd0;
            baud_tick    <= 1'b0;
            bit_index    <= 4'd0;
            shift_reg    <= 10'h3FF;
            serial_line  <= 1'b1;
            sending      <= 1'b0;
            done         <= 1'b0;
        end else begin
            baud_tick <= 1'b0;
            done      <= 1'b0;

            if (baud_counter == 9'd434) begin
                baud_counter <= 9'd0;
                baud_tick    <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1;
            end

            if (!sending && start) begin
                shift_reg    <= {1'b1, byte_send, 1'b0};
                sending      <= 1'b1;
                baud_counter <= 9'd0;
                bit_index    <= 4'd0;
            end

            if (sending && baud_tick) begin
                serial_line <= shift_reg[0];
                shift_reg   <= shift_reg >> 1;
                bit_index   <= bit_index + 1;

                if (bit_index == 4'd9) begin
                    sending     <= 1'b0;
                    done        <= 1'b1;
                    serial_line <= 1'b1;
                end
            end
        end
    end

endmodule
