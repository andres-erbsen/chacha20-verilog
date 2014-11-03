`default_nettype none

module chacha20_quarter(input  wire [31:0] ai, bi, ci, di,
                        output reg [31:0] a, b, c, d);
    always @(*) begin a=ai; b=bi; c=ci; d=di;
        `define ROTL32(w,n) {w[31-n:0], w[31:32-n]}
        a = a + b; d = d ^ a; d = `ROTL32(d, 16);
        c = c + d; b = b ^ c; b = `ROTL32(b, 12);
        a = a + b; d = d ^ a; d = `ROTL32(d,  8);
        c = c + d; b = b ^ c; b = `ROTL32(b,  7);
        `undef ROTL32
    end
endmodule

module chacha20(input wire clock,
                input wire start,
                input  wire [255:0] key,
                input  wire [63:0] index, // little-endian!
                input  wire [63:0] nonce,
                output reg done = 0,
                output wire [511:0] out);
    //  python2: "expand 32-byte k".encode('hex')
    wire [511:0] init = {128'h657870616e642033322d62797465206b, key, index, nonce};
    function [31:0] LE32(input [31:0] a);
        LE32 = {a[7:0], a[15:8], a[23:16], a[31:24]};
    endfunction

    reg [31:0] x [0:15];
    genvar j; generate for (j = 0; j < 16; j = j + 1) begin: gen
        always @(posedge clock) begin
            if (start)       x[j] <=      LE32(init[511 - 32*j -: 32]        );
            if (i == ROUNDS) x[j] <= LE32(LE32(init[511 - 32*j -: 32]) + x[j]);
        end
    end endgenerate

    parameter ROUNDS=20;
    reg [4:0] i = ROUNDS+1; // [0, ROUNDS] => running; ROUNDS+1 => ready
    wire v = i[0] == 0; // even => mix columns; odd => mix diagonals
    wire [3:0]
        q11 = 0,  q12 = v ? 4 : 5,  q13 = v ?  8 : 10,  q14 = v ? 12 : 15,
        q21 = 1,  q22 = v ? 5 : 6,  q23 = v ?  9 : 11,  q24 = v ? 13 : 12,
        q31 = 2,  q32 = v ? 6 : 7,  q33 = v ? 10 :  8,  q34 = v ? 14 : 13,
        q41 = 3,  q42 = v ? 7 : 4,  q43 = v ? 11 :  9,  q44 = v ? 15 : 14;
    chacha20_quarter q1(.ai(x[q11]), .bi(x[q12]), .ci(x[q13]), .di(x[q14]));
    chacha20_quarter q2(.ai(x[q21]), .bi(x[q22]), .ci(x[q23]), .di(x[q24]));
    chacha20_quarter q3(.ai(x[q31]), .bi(x[q32]), .ci(x[q33]), .di(x[q34]));
    chacha20_quarter q4(.ai(x[q41]), .bi(x[q42]), .ci(x[q43]), .di(x[q44]));
    always @(posedge clock) begin
        if (i < ROUNDS) begin
            x[q11] <= q1.a; x[q12] <= q1.b; x[q13] <= q1.c; x[q14] <= q1.d;
            x[q21] <= q2.a; x[q22] <= q2.b; x[q23] <= q2.c; x[q24] <= q2.d;
            x[q31] <= q3.a; x[q32] <= q3.b; x[q33] <= q3.c; x[q34] <= q3.d;
            x[q41] <= q4.a; x[q42] <= q4.b; x[q43] <= q4.c; x[q44] <= q4.d;
        end
        if (start) i <= 0;
        if (i < ROUNDS+1) i <= i + 1;
        if (i == ROUNDS)  done <= 1;
        if (done) done <= 0;
    end
    assign out = {x[ 0], x[ 1], x[ 2], x[ 3], x[ 4], x[ 5], x[ 6], x[ 7],
                  x[ 8], x[ 9], x[10], x[11], x[12], x[13], x[14], x[15]};
endmodule
