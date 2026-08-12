`timescale 1ns/1ps
// Hierarchy aligned to paper Fig.2 SubFFT:
//   4 × M-point pipelined FFT (M=256) + L=4 merge (stage9/10).

(* keep_hierarchy = "yes" *)
module fft_256_subfft_lane (
    input  wire clk,
    input  wire rst,
    input  wire in_valid,
    input  wire signed [34:0] in_re,
    input  wire signed [34:0] in_im,
    output wire out_valid,
    output wire out_last,
    output wire signed [34:0] out_re,
    output wire signed [34:0] out_im
);
    // Classic R2SDF 256-pt: depths 128,64,32,16,8,4,2,1
    wire [8:0] v, l;
    wire signed [34:0] r [0:8];
    wire signed [34:0] i [0:8];
    assign v[0] = in_valid;
    assign r[0] = in_re;
    assign i[0] = in_im;

    r2sdf_lane_subfft_v5 #(.DEPTH(128), .STAGE(1)) u_s1(clk, rst, v[0], r[0], i[0], v[1], l[1], r[1], i[1]);
    r2sdf_lane_subfft_v5 #(.DEPTH(64),  .STAGE(2)) u_s2(clk, rst, v[1], r[1], i[1], v[2], l[2], r[2], i[2]);
    r2sdf_lane_subfft_v5 #(.DEPTH(32),  .STAGE(3)) u_s3(clk, rst, v[2], r[2], i[2], v[3], l[3], r[3], i[3]);
    r2sdf_lane_subfft_v5 #(.DEPTH(16),  .STAGE(4)) u_s4(clk, rst, v[3], r[3], i[3], v[4], l[4], r[4], i[4]);
    r2sdf_lane_subfft_v5 #(.DEPTH(8),   .STAGE(5)) u_s5(clk, rst, v[4], r[4], i[4], v[5], l[5], r[5], i[5]);
    r2sdf_lane_subfft_v5 #(.DEPTH(4),   .STAGE(6)) u_s6(clk, rst, v[5], r[5], i[5], v[6], l[6], r[6], i[6]);
    r2sdf_lane_subfft_v5 #(.DEPTH(2),   .STAGE(7)) u_s7(clk, rst, v[6], r[6], i[6], v[7], l[7], r[7], i[7]);
    r2sdf_lane_subfft_v5 #(.DEPTH(1),   .STAGE(8)) u_s8(clk, rst, v[7], r[7], i[7], v[8], l[8], r[8], i[8]);

    assign out_valid = v[8];
    assign out_last  = l[8];
    assign out_re    = r[8];
    assign out_im    = i[8];
    wire _unused_l0 = l[1] ^ l[2] ^ l[3] ^ l[4] ^ l[5] ^ l[6] ^ l[7];
endmodule


(* keep_hierarchy = "yes" *)
module subfft_merge_l4 (
    input  wire clk,
    input  wire rst,
    input  wire in_valid,
    input  wire in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    input  wire signed [34:0] in2_re, in2_im, in3_re, in3_im,
    output wire out_valid,
    output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im,
    output wire signed [34:0] out2_re, out2_im, out3_re, out3_im
);
    // Fig.2: cross-lane twiddles + L=4 fully-parallel FFT (two pipeline stages)
    wire v9, l9;
    wire signed [34:0] r9_0, i9_0, r9_1, i9_1, r9_2, i9_2, r9_3, i9_3;
    subfft_stage9 u_s9 (
        .clk(clk), .rst(rst), .in_valid(in_valid), .in_last(in_last),
        .in0_re(in0_re), .in0_im(in0_im), .in1_re(in1_re), .in1_im(in1_im),
        .in2_re(in2_re), .in2_im(in2_im), .in3_re(in3_re), .in3_im(in3_im),
        .out_valid(v9), .out_last(l9),
        .out0_re(r9_0), .out0_im(i9_0), .out1_re(r9_1), .out1_im(i9_1),
        .out2_re(r9_2), .out2_im(i9_2), .out3_re(r9_3), .out3_im(i9_3)
    );
    subfft_stage10 u_s10 (
        .clk(clk), .rst(rst), .in_valid(v9), .in_last(l9),
        .in0_re(r9_0), .in0_im(i9_0), .in1_re(r9_1), .in1_im(i9_1),
        .in2_re(r9_2), .in2_im(i9_2), .in3_re(r9_3), .in3_im(i9_3),
        .out_valid(out_valid), .out_last(out_last),
        .out0_re(out0_re), .out0_im(out0_im), .out1_re(out1_re), .out1_im(out1_im),
        .out2_re(out2_re), .out2_im(out2_im), .out3_re(out3_re), .out3_im(out3_im)
    );
endmodule


// Same ports/behavior as before; hierarchy now matches Fig.2 packaging.
module subfft_functional_core_v5 (
    input  wire clk,
    input  wire rst,
    input  wire in_valid,
    input  wire in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    input  wire signed [34:0] in2_re, in2_im, in3_re, in3_im,
    output wire out_valid,
    output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im,
    output wire signed [34:0] out2_re, out2_im, out3_re, out3_im
);
    wire [3:0] lane_v, lane_l;
    wire signed [34:0] m0_re, m0_im, m1_re, m1_im, m2_re, m2_im, m3_re, m3_im;

    // Four M-point pipelined FFTs (M=256), one per decimated lane
    fft_256_subfft_lane u_fft256_0 (
        .clk(clk), .rst(rst), .in_valid(in_valid),
        .in_re(in0_re), .in_im(in0_im),
        .out_valid(lane_v[0]), .out_last(lane_l[0]),
        .out_re(m0_re), .out_im(m0_im)
    );
    fft_256_subfft_lane u_fft256_1 (
        .clk(clk), .rst(rst), .in_valid(in_valid),
        .in_re(in1_re), .in_im(in1_im),
        .out_valid(lane_v[1]), .out_last(lane_l[1]),
        .out_re(m1_re), .out_im(m1_im)
    );
    fft_256_subfft_lane u_fft256_2 (
        .clk(clk), .rst(rst), .in_valid(in_valid),
        .in_re(in2_re), .in_im(in2_im),
        .out_valid(lane_v[2]), .out_last(lane_l[2]),
        .out_re(m2_re), .out_im(m2_im)
    );
    fft_256_subfft_lane u_fft256_3 (
        .clk(clk), .rst(rst), .in_valid(in_valid),
        .in_re(in3_re), .in_im(in3_im),
        .out_valid(lane_v[3]), .out_last(lane_l[3]),
        .out_re(m3_re), .out_im(m3_im)
    );

    // Match prior stage4 convention: gate on lane0 valid/last (lanes stay aligned)
    wire merge_valid = lane_v[0];
    wire merge_last  = lane_l[0];
    wire _unused_lanes = ^{lane_v[3:1], lane_l[3:1], in_last};

    subfft_merge_l4 u_merge (
        .clk(clk), .rst(rst),
        .in_valid(merge_valid), .in_last(merge_last),
        .in0_re(m0_re), .in0_im(m0_im),
        .in1_re(m1_re), .in1_im(m1_im),
        .in2_re(m2_re), .in2_im(m2_im),
        .in3_re(m3_re), .in3_im(m3_im),
        .out_valid(out_valid), .out_last(out_last),
        .out0_re(out0_re), .out0_im(out0_im),
        .out1_re(out1_re), .out1_im(out1_im),
        .out2_re(out2_re), .out2_im(out2_im),
        .out3_re(out3_re), .out3_im(out3_im)
    );
endmodule


module top_s0_subfft_unprotected (
    input  wire clk,
    input  wire rst,
    input  wire in_valid,
    input  wire in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    input  wire signed [34:0] in2_re, in2_im, in3_re, in3_im,
    output wire out_valid,
    output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im,
    output wire signed [34:0] out2_re, out2_im, out3_re, out3_im
);
    subfft_functional_core_v5 u_func (
        .clk(clk), .rst(rst), .in_valid(in_valid), .in_last(in_last),
        .in0_re(in0_re), .in0_im(in0_im),
        .in1_re(in1_re), .in1_im(in1_im),
        .in2_re(in2_re), .in2_im(in2_im),
        .in3_re(in3_re), .in3_im(in3_im),
        .out_valid(out_valid), .out_last(out_last),
        .out0_re(out0_re), .out0_im(out0_im),
        .out1_re(out1_re), .out1_im(out1_im),
        .out2_re(out2_re), .out2_im(out2_im),
        .out3_re(out3_re), .out3_im(out3_im)
    );
endmodule
