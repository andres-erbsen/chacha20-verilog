`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module chacha20_test;
    parameter N = 5;
    reg [$bits(N):0] i = 0;
    reg [255:0] keys [N:0];
    reg [63:0] nonces [N:0];
    reg [63:0] indexes [N:0];
    reg [511:0] outs [N:0];


    initial begin
        keys[0]    = 256'h0000000000000000000000000000000000000000000000000000000000000000;
        nonces[0]  = 64'h0000000000000000;
        indexes[0] = 64'h0000000000000000;
        outs[0]    = 512'h76b8e0ada0f13d90405d6ae55386bd28bdd219b8a08ded1aa836efcc8b770dc7da41597c5157488d7724e03fb8d84a376a43b8f41518a11cc387b669b2ee6586;

        keys[1]    = 256'h0000000000000000000000000000000000000000000000000000000000000001;
        nonces[1]  = 64'h0000000000000000;
        indexes[1] = 64'h0000000000000000;
        outs[1]    = 512'h4540f05a9f1fb296d7736e7b208e3c96eb4fe1834688d2604f450952ed432d41bbe2a0b6ea7566d2a5d1e7e20d42af2c53d792b1c43fea817e9ad275ae546963;

        keys[2]    = 256'h0000000000000000000000000000000000000000000000000000000000000000;
        nonces[2]  = 64'h0100000000000000;
        indexes[2] = 64'h0000000000000000;
        outs[2]    = 512'hef3fdfd6c61578fbf5cf35bd3dd33b8009631634d21e42ac33960bd138e50d32111e4caf237ee53ca8ad6426194a88545ddc497a0b466e7d6bbdb0041b2f586b;

        keys[3]    = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        nonces[3]  = 64'h0001020304050607;
        indexes[3] = 64'h0000000000000000;
        outs[3]    = 512'hf798a189f195e66982105ffb640bb7757f579da31602fc93ec01ac56f85ac3c134a4547b733b46413042c9440049176905d3be59ea1c53f15916155c2be8241a;

        keys[4]    = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        nonces[4]  = 64'h0001020304050607;
        indexes[4] = 64'h0100000000000000;
        outs[4]    = 512'h38008b9a26bc35941e2444177c8ade6689de95264986d95889fb60e84629c9bd9a5acb1cc118be563eb9b3a4a472f82e09a7e778492b562ef7130e88dfe031c7;
    end

    wire [511:0] out;
    wire done;
    reg clock = 0, start = 1;
    chacha20 chacha20(clock, start, keys[i], indexes[i], nonces[i], done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        if (done) begin
            $display("0x%x == 0x%x", out, outs[i]);
            `assert(out === outs[i])
            if (i < N-1) begin
                i <= i + 1;
                start <= 1;
            end else begin
                $finish;
            end
        end
        if (start) start <= 0;
    end

    // initial begin $monitor("i=%d x[0]=%x x[1]=%x", chacha20.i, chacha20.x[0], chacha20.x[1]); end
endmodule
