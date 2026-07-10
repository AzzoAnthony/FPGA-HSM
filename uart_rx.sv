module uart_rx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       serial_line,
    output logic       pulse,
    output logic [7:0] byte_received
);

    logic [8:0] baud_counter;
    logic       baud_tick;
    logic [3:0] bit_index;
    logic [7:0] shift_reg;
    logic       middle;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter  <= 9'd0;
            baud_tick     <= 1'b0;
            middle        <= 1'b0;
            bit_index     <= 4'd0;
            shift_reg     <= 8'h00;
            pulse         <= 1'b0;
            byte_received <= 8'h00;
        end else begin
            baud_tick <= 1'b0;
            pulse     <= 1'b0;

            if (baud_counter == 9'd434) begin
                baud_counter <= 9'd0;
                baud_tick    <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1;
            end

            if (!middle && !serial_line) begin
                middle       <= 1'b1;
                baud_counter <= 9'd0;
                bit_index    <= 4'd0;
            end

            if (middle && baud_tick) begin
                if (bit_index <= 4'd7) begin
                    shift_reg <= (shift_reg >> 1) | (serial_line << 7);
                    bit_index <= bit_index + 1;
                end else begin
                    pulse         <= 1'b1;
                    byte_received <= shift_reg;
                    middle        <= 1'b0;
                end
            end
        end
    end

endmodule
