`timescale 1ns/1ps
`include "common/tb_utils.svh"

module tb_stim_feeder;
    `TB_INIT("stim_feeder");
    `TB_TIMEOUT(100000)

    reg clk, rst;
    wire [3:0] rom_addr;
    reg [279:0] rom_dout;
    wire in_valid, in_last;
    wire signed [34:0] in0_re, in0_im, in1_re, in1_im;
    wire signed [34:0] in2_re, in2_im, in3_re, in3_im;
    reg [279:0] mem [0:15];
    integer i, beats;

    stim_feeder #(
        .DEPTH(16),
        .ADDR_W(4),
        .BEATS_PER_FRAME(8)
    ) dut (
        clk, rst, rom_dout, rom_addr, in_valid, in_last,
        in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im
    );

    always #1 clk = ~clk;

    always @(posedge clk) begin
        rom_dout <= mem[rom_addr];
    end

    initial begin
        clk = 0;
        rst = 1;
        rom_dout = 0;
        tb_pass = 0;
        tb_fail = 0;
        tb_xfail = 0;
        tb_xpass = 0;
        for (i = 0; i < 16; i = i + 1) begin
            mem[i] = {
                35'(i * 8 + 0), 35'(i * 8 + 1),
                35'(i * 8 + 2), 35'(i * 8 + 3),
                35'(i * 8 + 4), 35'(i * 8 + 5),
                35'(i * 8 + 6), 35'(i * 8 + 7)
            };
        end
        repeat (2) @(posedge clk);
        rst = 0;
        beats = 0;
        repeat (30) begin
            @(posedge clk);
            if (in_valid) begin
                `TB_CHECK_EQ(in0_re, beats * 8 + 0, "in0_re field order")
                `TB_CHECK_EQ(in0_im, beats * 8 + 1, "in0_im field order")
                `TB_CHECK_EQ(in1_re, beats * 8 + 2, "in1_re field order")
                `TB_CHECK_EQ(in1_im, beats * 8 + 3, "in1_im field order")
                `TB_CHECK_EQ(in2_re, beats * 8 + 4, "in2_re field order")
                `TB_CHECK_EQ(in2_im, beats * 8 + 5, "in2_im field order")
                `TB_CHECK_EQ(in3_re, beats * 8 + 6, "in3_re field order")
                `TB_CHECK_EQ(in3_im, beats * 8 + 7, "in3_im field order")
                `TB_CHECK(in_last == (beats % 8 == 7), "frame marker")
                beats = beats + 1;
            end
        end
        `TB_CHECK_EQ(beats, 16, "feeder beat count")
        `TB_CHECK(!in_valid, "feeder stops")
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;
        repeat (3) @(posedge clk);
        `TB_CHECK(in_valid, "reset restarts feeder")
        `TB_FINISH;
    end
endmodule
