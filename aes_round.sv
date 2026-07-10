import aes_functions::*;

module aes_round (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    input  logic         is_final_round,
    output logic [127:0] state_out
);

    logic [127:0] after_sub;
    logic [127:0] after_shift;
    logic [127:0] after_mix;

    aes_sbox sbox00(.in_byte(state_in[127:120]), .out_byte(after_sub[127:120]));
    aes_sbox sbox01(.in_byte(state_in[119:112]), .out_byte(after_sub[119:112]));
    aes_sbox sbox02(.in_byte(state_in[111:104]), .out_byte(after_sub[111:104]));
    aes_sbox sbox03(.in_byte(state_in[103:96]),  .out_byte(after_sub[103:96]));
    aes_sbox sbox04(.in_byte(state_in[95:88]),   .out_byte(after_sub[95:88]));
    aes_sbox sbox05(.in_byte(state_in[87:80]),   .out_byte(after_sub[87:80]));
    aes_sbox sbox06(.in_byte(state_in[79:72]),   .out_byte(after_sub[79:72]));
    aes_sbox sbox07(.in_byte(state_in[71:64]),   .out_byte(after_sub[71:64]));
    aes_sbox sbox08(.in_byte(state_in[63:56]),   .out_byte(after_sub[63:56]));
    aes_sbox sbox09(.in_byte(state_in[55:48]),   .out_byte(after_sub[55:48]));
    aes_sbox sbox10(.in_byte(state_in[47:40]),   .out_byte(after_sub[47:40]));
    aes_sbox sbox11(.in_byte(state_in[39:32]),   .out_byte(after_sub[39:32]));
    aes_sbox sbox12(.in_byte(state_in[31:24]),   .out_byte(after_sub[31:24]));
    aes_sbox sbox13(.in_byte(state_in[23:16]),   .out_byte(after_sub[23:16]));
    aes_sbox sbox14(.in_byte(state_in[15:8]),    .out_byte(after_sub[15:8]));
    aes_sbox sbox15(.in_byte(state_in[7:0]),     .out_byte(after_sub[7:0]));

    assign after_shift = shift_rows(after_sub);

    always_comb begin
        if (is_final_round)
            after_mix = after_shift;
        else begin
            after_mix[127:96] = mix_column(after_shift[127:96]);
            after_mix[95:64]  = mix_column(after_shift[95:64]);
            after_mix[63:32]  = mix_column(after_shift[63:32]);
            after_mix[31:0]   = mix_column(after_shift[31:0]);
        end
    end

    assign state_out = after_mix ^ round_key;

endmodule
