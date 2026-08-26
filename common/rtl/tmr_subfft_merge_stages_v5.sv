`timescale 1ns/1ps

// Complete-stage TMR wrappers for the SubFFT merge stages (Stage 9 / Stage 10).
// Shared by S1 / S2 / S3; replicas carry DONT_TOUCH so Vivado keeps all three.

(* keep_hierarchy = "yes" *)
module tmr_subfft_stage9_v5 (
    input  wire clk, input wire rst, input wire in_valid, input wire in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
    output wire out_valid, output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im
);
    wire [2:0] v, l;
    wire signed [34:0] r0[0:2], i0[0:2], r1[0:2], i1[0:2], r2[0:2], i2[0:2], r3[0:2], i3[0:2];
    genvar g;
    generate for (g = 0; g < 3; g = g + 1) begin : rep
        (* DONT_TOUCH = "yes", keep = "true", keep_hierarchy = "yes" *)
        subfft_stage9 u (
            clk, rst, in_valid, in_last,
            in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
            v[g], l[g], r0[g], i0[g], r1[g], i1[g], r2[g], i2[g], r3[g], i3[g]
        );
    end endgenerate
    vote35 a0(r0[0], r0[1], r0[2], out0_re); vote35 b0(i0[0], i0[1], i0[2], out0_im);
    vote35 a1(r1[0], r1[1], r1[2], out1_re); vote35 b1(i1[0], i1[1], i1[2], out1_im);
    vote35 a2(r2[0], r2[1], r2[2], out2_re); vote35 b2(i2[0], i2[1], i2[2], out2_im);
    vote35 a3(r3[0], r3[1], r3[2], out3_re); vote35 b3(i3[0], i3[1], i3[2], out3_im);
    assign out_valid = (v[0] & v[1]) | (v[0] & v[2]) | (v[1] & v[2]);
    assign out_last  = (l[0] & l[1]) | (l[0] & l[2]) | (l[1] & l[2]);
endmodule


(* keep_hierarchy = "yes" *)
module tmr_subfft_stage10_v5 (
    input  wire clk, input wire rst, input wire in_valid, input wire in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
    output wire out_valid, output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im
);
    wire [2:0] v, l;
    wire signed [34:0] r0[0:2], i0[0:2], r1[0:2], i1[0:2], r2[0:2], i2[0:2], r3[0:2], i3[0:2];
    genvar g;
    generate for (g = 0; g < 3; g = g + 1) begin : rep
        (* DONT_TOUCH = "yes", keep = "true", keep_hierarchy = "yes" *)
        subfft_stage10 u (
            clk, rst, in_valid, in_last,
            in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
            v[g], l[g], r0[g], i0[g], r1[g], i1[g], r2[g], i2[g], r3[g], i3[g]
        );
    end endgenerate
    vote35 a0(r0[0], r0[1], r0[2], out0_re); vote35 b0(i0[0], i0[1], i0[2], out0_im);
    vote35 a1(r1[0], r1[1], r1[2], out1_re); vote35 b1(i1[0], i1[1], i1[2], out1_im);
    vote35 a2(r2[0], r2[1], r2[2], out2_re); vote35 b2(i2[0], i2[1], i2[2], out2_im);
    vote35 a3(r3[0], r3[1], r3[2], out3_re); vote35 b3(i3[0], i3[1], i3[2], out3_im);
    assign out_valid = (v[0] & v[1]) | (v[0] & v[2]) | (v[1] & v[2]);
    assign out_last  = (l[0] & l[1]) | (l[0] & l[2]) | (l[1] & l[2]);
endmodule
