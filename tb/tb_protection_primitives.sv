`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_protection_primitives;
`TB_INIT("protection_primitives"); `TB_TIMEOUT(200000)
reg [34:0] va, vb, vc;
wire [34:0] vy;
reg [69:0] data;
wire [77:0] codeword;
reg [77:0] noisy;
wire [69:0] decoded;
wire detected, corrected;
integer i, j, k;
reg [34:0] maj;

vote35 vote(va, vb, vc, vy);
secded_encode70 encoder(data, codeword);
secded_decode70 decoder(noisy, decoded, detected, corrected);

function integer ispow2(input integer n);
    begin
        ispow2 = (n > 0) && ((n & (n - 1)) == 0);
    end
endfunction

initial begin
    tb_pass = 0;
    tb_fail = 0;
    tb_xfail = 0;
    tb_xpass = 0;
    for (i = 0; i < 200; i = i + 1) begin
        va = {$random};
        vb = va;
        vc = va;
        #1;
        `TB_CHECK_EQ(vy, va, "vote equal")
        for (j = 0; j < 3; j = j + 1) begin
            va = {$random};
            vb = va;
            vc = va;
            case (j)
                0: va = va ^ (35'd1 << ($random % 35));
                1: vb = vb ^ (35'd1 << ($random % 35));
                default: vc = vc ^ (35'd1 << ($random % 35));
            endcase
            #1;
            `TB_CHECK_EQ(vy, (vb & vc) | (va & vb) | (va & vc),
                         "vote single upset")
        end
    end
    va = {$random};
    vb = {$random};
    vc = {$random};
    #1;
    maj = (va & vb) | (va & vc) | (vb & vc);
    `TB_CHECK_EQ(vy, maj, "vote bitwise majority")
    for (i = 0; i < 100; i = i + 1) begin
        data = {$random, $random, $random};
        #1;
        noisy = codeword;
        #1;
        `TB_CHECK_EQ(decoded, data, "SECDED round trip")
        `TB_CHECK(!detected && !corrected, "SECDED clean flags")
        for (j = 0; j < 78; j = j + 1) begin
            noisy = codeword ^ (78'd1 << j);
            #1;
            `TB_CHECK_EQ(decoded, data, "SECDED single-bit correction")
            `TB_CHECK(detected && corrected, "SECDED single-bit flags")
        end
        for (j = 0; j < 10; j = j + 1) begin
            k = $random & 31;
            noisy = codeword ^ (78'd1 << j) ^ (78'd1 << (k + 32));
            #1;
            `TB_CHECK(detected && !corrected, "SECDED double-bit detect")
        end
    end
    data = 0;
    #1;
    for (i = 1; i <= 77; i = i + 1) begin
        if (!ispow2(i))
            `TB_CHECK(codeword[i - 1] === 1'b0, "zero payload parity layout")
    end
    `TB_FINISH;
end
endmodule
