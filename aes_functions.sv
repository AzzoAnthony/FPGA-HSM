package aes_functions;

    function automatic logic [7:0] xtime(logic [7:0] b);
        if (b[7])
            return (b << 1) ^ 8'h1b;
        else
            return (b << 1);
    endfunction

    function automatic logic [31:0] mix_column(logic [31:0] col_in);
        logic [7:0] a0, a1, a2, a3;
        logic [7:0] r0, r1, r2, r3;
        a0 = col_in[31:24];
        a1 = col_in[23:16];
        a2 = col_in[15:8];
        a3 = col_in[7:0];
        r0 = xtime(a0 ^ a1) ^ a1 ^ a2 ^ a3;
        r1 = xtime(a1 ^ a2) ^ a2 ^ a3 ^ a0;
        r2 = xtime(a2 ^ a3) ^ a3 ^ a0 ^ a1;
        r3 = xtime(a3 ^ a0) ^ a0 ^ a1 ^ a2;
        return {r0, r1, r2, r3};
    endfunction

    function automatic logic [127:0] shift_rows(logic [127:0] s);
        return {
            s[127:120], s[95:88],  s[63:56],  s[31:24],
            s[119:112], s[87:80],  s[55:48],  s[23:16],
            s[111:104], s[79:72],  s[47:40],  s[15:8],
            s[103:96],  s[71:64],  s[39:32],  s[7:0]
        };
    endfunction

endpackage
