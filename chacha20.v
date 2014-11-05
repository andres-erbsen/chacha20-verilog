`default_nettype none
`define ARRAY16(A) {A[0],A[1],A[2],A[3],A[4],A[5],A[6],A[7],A[8],A[9],A[10],A[11],A[12],A[13],A[14],A[15]}

module chacha20_quarter(input wire [31:0] ai, bi, ci, di,
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
                input  wire [63:0] index, // integer, not little-endian bytes
                input  wire [63:0] nonce,
                output reg done = 0,
                output wire [511:0] out);
    function automatic [31:0] LE32(input [31:0] a);
        LE32 = {a[7:0], a[15:8], a[23:16], a[31:24]};
    endfunction
    localparam CONST = 128'h657870616e642033322d62797465206b; // "expand 32-byte k".encode('hex')
    wire [511:0] init ={CONST, key, LE32(index[31:0]), LE32(index[63:32]), nonce};
    parameter ROUNDS=20;
    reg [4:0] i = ROUNDS+1; // [0, ROUNDS] => running; ROUNDS+1 => ready

    reg [31:0] x [0:15];
    wire [31:0] x_init [0:15];
    wire [31:0] x_final [0:15];
    genvar j; generate for (j = 0; j < 16; j = j + 1) begin: gen
        assign x_init [j] =      LE32(init[511 - 32*j -: 32]        );
        assign x_final[j] = LE32(LE32(init[511 - 32*j -: 32]) + x[j]);
    end endgenerate

    wire v = i[0] == 0; // even => mix columns; odd => mix diagonals
    wire [31:0] a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4;
    chacha20_quarter q1(.ai(x[0]), .bi(x[v?4:5]), .ci(x[v?8:10]), .di(x[v?12:15]),
                        .a(a1),    .b(b1),        .c(c1),         .d(d1));
    chacha20_quarter q2(.ai(x[1]), .bi(x[v?5:6]), .ci(x[v?9:11]), .di(x[v?13:12]),
                        .a(a2),    .b(b2),        .c(c2),         .d(d2));
    chacha20_quarter q3(.ai(x[2]), .bi(x[v?6:7]), .ci(x[v?10:8]), .di(x[v?14:13]),
                        .a(a3),    .b(b3),        .c(c3),         .d(d3));
    chacha20_quarter q4(.ai(x[3]), .bi(x[v?7:4]), .ci(x[v?11:9]), .di(x[v?15:14]),
                        .a(a4),    .b(b4),        .c(c4),         .d(d4));
    always @(posedge clock) begin
        if (i < ROUNDS) begin
            {x[0], x[4], x[ 8], x[12]} <= {a1, v?b1:b4, v?c1:c3, v?d1:d2};
            {x[1], x[5], x[ 9], x[13]} <= {a2, v?b2:b1, v?c2:c4, v?d2:d3};
            {x[2], x[6], x[10], x[14]} <= {a3, v?b3:b2, v?c3:c1, v?d3:d4};
            {x[3], x[7], x[11], x[15]} <= {a4, v?b4:b3, v?c4:c2, v?d4:d1};
        end
        if (start) begin
            i <= 0;
            `ARRAY16(x) <= `ARRAY16(x_init);
        end
        if (i < ROUNDS+1) i <= i + 1;
        if (i == ROUNDS) begin
            done <= 1;
            `ARRAY16(x) <= `ARRAY16(x_final);
        end
        if (done) done <= 0;
    end
    assign out = `ARRAY16(x);
endmodule
