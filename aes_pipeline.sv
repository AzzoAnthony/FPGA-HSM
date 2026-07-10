module aes_pipeline (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         lockout,
    input  logic [127:0] round_keys [0:10],
    input  logic [127:0] plaintext_in,
    input  logic         valid_in,
    output logic [127:0] ciphertext_out,
    output logic         valid_out
);

    logic [127:0] stage_data [0:5];
    logic         stage_valid [0:5];
    logic [127:0] round_out [0:5];

    logic [127:0] stage0_keyed;
    assign stage0_keyed = plaintext_in ^ round_keys[0];

    aes_round stage0_round(.state_in(stage0_keyed),   .round_key(round_keys[1]),  .is_final_round(1'b0), .state_out(round_out[0]));

    logic [127:0] stage1_mid;
    aes_round stage1_round_a(.state_in(stage_data[0]), .round_key(round_keys[2]),  .is_final_round(1'b0), .state_out(stage1_mid));
    aes_round stage1_round_b(.state_in(stage1_mid),    .round_key(round_keys[3]),  .is_final_round(1'b0), .state_out(round_out[1]));

    logic [127:0] stage2_mid;
    aes_round stage2_round_a(.state_in(stage_data[1]), .round_key(round_keys[4]),  .is_final_round(1'b0), .state_out(stage2_mid));
    aes_round stage2_round_b(.state_in(stage2_mid),    .round_key(round_keys[5]),  .is_final_round(1'b0), .state_out(round_out[2]));

    logic [127:0] stage3_mid;
    aes_round stage3_round_a(.state_in(stage_data[2]), .round_key(round_keys[6]),  .is_final_round(1'b0), .state_out(stage3_mid));
    aes_round stage3_round_b(.state_in(stage3_mid),    .round_key(round_keys[7]),  .is_final_round(1'b0), .state_out(round_out[3]));

    logic [127:0] stage4_mid;
    aes_round stage4_round_a(.state_in(stage_data[3]), .round_key(round_keys[8]),  .is_final_round(1'b0), .state_out(stage4_mid));
    aes_round stage4_round_b(.state_in(stage4_mid),    .round_key(round_keys[9]),  .is_final_round(1'b0), .state_out(round_out[4]));

    aes_round stage5_round(.state_in(stage_data[4]),   .round_key(round_keys[10]), .is_final_round(1'b1), .state_out(round_out[5]));

   always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_data[0]  <= 128'h0; stage_valid[0] <= 1'b0;
            stage_data[1]  <= 128'h0; stage_valid[1] <= 1'b0;
            stage_data[2]  <= 128'h0; stage_valid[2] <= 1'b0;
            stage_data[3]  <= 128'h0; stage_valid[3] <= 1'b0;
            stage_data[4]  <= 128'h0; stage_valid[4] <= 1'b0;
            stage_data[5]  <= 128'h0; stage_valid[5] <= 1'b0;
        end else if (lockout) begin
            stage_data[0]  <= 128'h0; stage_valid[0] <= 1'b0;
            stage_data[1]  <= 128'h0; stage_valid[1] <= 1'b0;
            stage_data[2]  <= 128'h0; stage_valid[2] <= 1'b0;
            stage_data[3]  <= 128'h0; stage_valid[3] <= 1'b0;
            stage_data[4]  <= 128'h0; stage_valid[4] <= 1'b0;
            stage_data[5]  <= 128'h0; stage_valid[5] <= 1'b0;
        end else begin
            stage_data[0]  <= round_out[0]; stage_valid[0] <= valid_in;
            stage_data[1]  <= round_out[1]; stage_valid[1] <= stage_valid[0];
            stage_data[2]  <= round_out[2]; stage_valid[2] <= stage_valid[1];
            stage_data[3]  <= round_out[3]; stage_valid[3] <= stage_valid[2];
            stage_data[4]  <= round_out[4]; stage_valid[4] <= stage_valid[3];
            stage_data[5]  <= round_out[5]; stage_valid[5] <= stage_valid[4];
        end
    end

    assign ciphertext_out = stage_data[5];
    assign valid_out      = stage_valid[5];

endmodule
