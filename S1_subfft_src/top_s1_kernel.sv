`timescale 1ns/1ps

// Fair-kernel S1 (Gao path-level ECC):
//   Stage 1–8: 7 complete 256-pt SubFFT paths, Hamming (7,4,3), decode at Stage-8 boundary
//   Stage 9–10: complete-stage TMR
// No AXI/debug wrap; no terminal frame buffer (same compare口径 as S0).

(* keep_hierarchy = "yes" *)
module s1_subfft_lane8_v5 (
    input  wire clk,
    input  wire rst,
    input  wire valid,
    input  wire signed [34:0] in_re,
    input  wire signed [34:0] in_im,
    output wire out_valid,
    output wire out_last,
    output wire signed [34:0] out_re,
    output wire signed [34:0] out_im
);
    wire [8:0] v, l;
    wire signed [34:0] r [0:8];
    wire signed [34:0] i [0:8];
    assign v[0] = valid;
    assign r[0] = in_re;
    assign i[0] = in_im;
    r2sdf_lane_subfft_v5 #(.DEPTH(128), .STAGE(1)) a(clk, rst, v[0], r[0], i[0], v[1], l[1], r[1], i[1]);
    r2sdf_lane_subfft_v5 #(.DEPTH(64),  .STAGE(2)) b(clk, rst, v[1], r[1], i[1], v[2], l[2], r[2], i[2]);
    r2sdf_lane_subfft_v5 #(.DEPTH(32),  .STAGE(3)) c(clk, rst, v[2], r[2], i[2], v[3], l[3], r[3], i[3]);
    r2sdf_lane_subfft_v5 #(.DEPTH(16),  .STAGE(4)) d(clk, rst, v[3], r[3], i[3], v[4], l[4], r[4], i[4]);
    r2sdf_lane_subfft_v5 #(.DEPTH(8),   .STAGE(5)) e(clk, rst, v[4], r[4], i[4], v[5], l[5], r[5], i[5]);
    r2sdf_lane_subfft_v5 #(.DEPTH(4),   .STAGE(6)) f(clk, rst, v[5], r[5], i[5], v[6], l[6], r[6], i[6]);
    r2sdf_lane_subfft_v5 #(.DEPTH(2),   .STAGE(7)) g(clk, rst, v[6], r[6], i[6], v[7], l[7], r[7], i[7]);
    r2sdf_lane_subfft_v5 #(.DEPTH(1),   .STAGE(8)) h(clk, rst, v[7], r[7], i[7], v[8], l[8], r[8], i[8]);
    assign out_valid = v[8];
    assign out_last  = l[8];
    assign out_re    = r[8];
    assign out_im    = i[8];
endmodule


(* keep_hierarchy = "yes" *)
module s1_tmr_subfft_stage9_v5 (
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
module s1_tmr_subfft_stage10_v5 (
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


module top_s1_gao_subfft_ecc (
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
    // Gao (7,4,3) path encoding over four data lanes + three parity paths
    wire signed [34:0] a01r = in0_re + in1_re, a01i = in0_im + in1_im;
    wire signed [34:0] a02r = in0_re + in2_re, a02i = in0_im + in2_im;
    wire signed [34:0] a12r = in1_re + in2_re, a12i = in1_im + in2_im;
    wire signed [34:0] p0r = -(a01r + in3_re), p0i = -(a01i + in3_im);
    wire signed [34:0] p1r = -(a02r + in3_re), p1i = -(a02i + in3_im);
    wire signed [34:0] p3r = -(a12r + in3_re), p3i = -(a12i + in3_im);

    wire signed [34:0] pr [0:6], pi [0:6], pathr [0:6], pathi [0:6];
    wire [6:0] pv, pl;
    assign pr[0] = p0r;     assign pi[0] = p0i;
    assign pr[1] = p1r;     assign pi[1] = p1i;
    assign pr[2] = in0_re;  assign pi[2] = in0_im;
    assign pr[3] = p3r;     assign pi[3] = p3i;
    assign pr[4] = in1_re;  assign pi[4] = in1_im;
    assign pr[5] = in2_re;  assign pi[5] = in2_im;
    assign pr[6] = in3_re;  assign pi[6] = in3_im;

    genvar x;
    generate for (x = 0; x < 7; x = x + 1) begin : paths
        (* keep = "true" *)
        s1_subfft_lane8_v5 u (
            clk, rst, in_valid, pr[x], pi[x],
            pv[x], pl[x], pathr[x], pathi[x]
        );
    end endgenerate

    // Fault-free: clean reference == received path outputs (same as tcas S1 top)
    (* keep = "true" *) wire signed [34:0] received_path_r [0:6], received_path_i [0:6];
    genvar y;
    generate for (y = 0; y < 7; y = y + 1) begin : received_boundary
        assign received_path_r[y] = pathr[y];
        assign received_path_i[y] = pathi[y];
    end endgenerate

    // 125 MHz: 4-stage Gao —
    // (1) capture 7 path outs
    // (2) residues + path copy
    // (3) syndromes + path copy
    // (4) location/correct → gd*
    reg pv_d, pl_d;
    reg signed [34:0] cap_r [0:6], cap_i [0:6];
    integer ci;
    always @(posedge clk) begin
        if (rst) begin
            pv_d <= 1'b0; pl_d <= 1'b0;
            for (ci = 0; ci < 7; ci = ci + 1) begin
                cap_r[ci] <= 35'sd0; cap_i[ci] <= 35'sd0;
            end
        end else begin
            pv_d <= pv[0];
            pl_d <= pl[0];
            if (pv[0]) begin
                for (ci = 0; ci < 7; ci = ci + 1) begin
                    cap_r[ci] <= pathr[ci];
                    cap_i[ci] <= pathi[ci];
                end
            end
        end
    end

    // Stage 2: path snapshot for corrector (un-compensated: no residues).
    reg pv_d2, pl_d2;
    reg signed [34:0] cap2_r [0:6], cap2_i [0:6];
    always @(posedge clk) begin
        if (rst) begin
            pv_d2 <= 1'b0; pl_d2 <= 1'b0;
            for (ci = 0; ci < 7; ci = ci + 1) begin
                cap2_r[ci] <= 35'sd0; cap2_i[ci] <= 35'sd0;
            end
        end else begin
            pv_d2 <= pv_d;
            pl_d2 <= pl_d;
            if (pv_d) begin
                for (ci = 0; ci < 7; ci = ci + 1) begin
                    cap2_r[ci] <= cap_r[ci];
                    cap2_i[ci] <= cap_i[ci];
                end
            end
        end
    end

    // Stage 3: register syndromes (un-compensated raw syndromes).
    wire signed [38:0] s0r_c = $signed(cap2_r[0]) + $signed(cap2_r[2]) + $signed(cap2_r[4]) + $signed(cap2_r[6]);
    wire signed [38:0] s0i_c = $signed(cap2_i[0]) + $signed(cap2_i[2]) + $signed(cap2_i[4]) + $signed(cap2_i[6]);
    wire signed [38:0] s1r_c = $signed(cap2_r[1]) + $signed(cap2_r[2]) + $signed(cap2_r[5]) + $signed(cap2_r[6]);
    wire signed [38:0] s1i_c = $signed(cap2_i[1]) + $signed(cap2_i[2]) + $signed(cap2_i[5]) + $signed(cap2_i[6]);
    wire signed [38:0] s2r_c = $signed(cap2_r[3]) + $signed(cap2_r[4]) + $signed(cap2_r[5]) + $signed(cap2_r[6]);
    wire signed [38:0] s2i_c = $signed(cap2_i[3]) + $signed(cap2_i[4]) + $signed(cap2_i[5]) + $signed(cap2_i[6]);

    reg pv_d3, pl_d3;
    reg signed [34:0] cap3_r [0:6], cap3_i [0:6];
    reg signed [38:0] syn0r, syn0i, syn1r, syn1i, syn2r, syn2i;
    always @(posedge clk) begin
        if (rst) begin
            pv_d3 <= 1'b0; pl_d3 <= 1'b0;
            syn0r <= 39'sd0; syn0i <= 39'sd0; syn1r <= 39'sd0; syn1i <= 39'sd0;
            syn2r <= 39'sd0; syn2i <= 39'sd0;
            for (ci = 0; ci < 7; ci = ci + 1) begin
                cap3_r[ci] <= 35'sd0; cap3_i[ci] <= 35'sd0;
            end
        end else begin
            pv_d3 <= pv_d2;
            pl_d3 <= pl_d2;
            if (pv_d2) begin
                syn0r <= s0r_c; syn0i <= s0i_c;
                syn1r <= s1r_c; syn1i <= s1i_c;
                syn2r <= s2r_c; syn2i <= s2i_c;
                for (ci = 0; ci < 7; ci = ci + 1) begin
                    cap3_r[ci] <= cap2_r[ci];
                    cap3_i[ci] <= cap2_i[ci];
                end
            end
        end
    end

    // Un-compensated thresholded locator (tau=16, TOL=32); added 2026-08-10.
    function [38:0] abs39;
        input signed [38:0] value;
        begin
            abs39 = value[38] ? (~value + 39'sd1) : value;
        end
    endfunction

    // Stage 4: location decode + correction (same function as gao_corrector_743_v5).
    reg gv, gl;
    reg signed [34:0] gd0r, gd0i, gd1r, gd1i, gd2r, gd2i, gd3r, gd3i;
    reg signed [38:0] er, ei;
    reg [2:0] loc;
    reg found;
    always @(posedge clk) begin
        if (rst) begin
            gv <= 1'b0; gl <= 1'b0;
            gd0r <= 35'sd0; gd0i <= 35'sd0; gd1r <= 35'sd0; gd1i <= 35'sd0;
            gd2r <= 35'sd0; gd2i <= 35'sd0; gd3r <= 35'sd0; gd3i <= 35'sd0;
        end else begin
            gv <= pv_d3;
            gl <= pl_d3;
            if (pv_d3) begin
                gd0r <= cap3_r[2]; gd0i <= cap3_i[2];
                gd1r <= cap3_r[4]; gd1i <= cap3_i[4];
                gd2r <= cap3_r[5]; gd2i <= cap3_i[5];
                gd3r <= cap3_r[6]; gd3i <= cap3_i[6];
                found = 1'b0; loc = 3'd0; er = 39'sd0; ei = 39'sd0;
                if ((abs39(syn0r) > 39'sd16) || (abs39(syn0i) > 39'sd16) || (abs39(syn1r) > 39'sd16) || (abs39(syn1i) > 39'sd16) || (abs39(syn2r) > 39'sd16) || (abs39(syn2i) > 39'sd16)) begin
                    if ((abs39(syn0r) > 39'sd16 || abs39(syn0i) > 39'sd16) && (abs39(syn1r) <= 39'sd16 && abs39(syn1i) <= 39'sd16) && (abs39(syn2r) <= 39'sd16 && abs39(syn2i) <= 39'sd16)) begin
                        loc = 3'd0; found = 1'b1; er = syn0r; ei = syn0i;
                    end else if ((abs39(syn1r) > 39'sd16 || abs39(syn1i) > 39'sd16) && (abs39(syn0r) <= 39'sd16 && abs39(syn0i) <= 39'sd16) && (abs39(syn2r) <= 39'sd16 && abs39(syn2i) <= 39'sd16)) begin
                        loc = 3'd1; found = 1'b1; er = syn1r; ei = syn1i;
                    end else if ((abs39(syn0r - syn1r) <= 39'sd32) && (abs39(syn0i - syn1i) <= 39'sd32) && (abs39(syn2r) <= 39'sd16 && abs39(syn2i) <= 39'sd16)) begin
                        loc = 3'd2; found = 1'b1; er = syn0r; ei = syn0i;
                    end else if ((abs39(syn2r) > 39'sd16 || abs39(syn2i) > 39'sd16) && (abs39(syn0r) <= 39'sd16 && abs39(syn0i) <= 39'sd16) && (abs39(syn1r) <= 39'sd16 && abs39(syn1i) <= 39'sd16)) begin
                        loc = 3'd3; found = 1'b1; er = syn2r; ei = syn2i;
                    end else if ((abs39(syn0r - syn2r) <= 39'sd32) && (abs39(syn0i - syn2i) <= 39'sd32) && (abs39(syn1r) <= 39'sd16 && abs39(syn1i) <= 39'sd16)) begin
                        loc = 3'd4; found = 1'b1; er = syn0r; ei = syn0i;
                    end else if ((abs39(syn1r - syn2r) <= 39'sd32) && (abs39(syn1i - syn2i) <= 39'sd32) && (abs39(syn0r) <= 39'sd16 && abs39(syn0i) <= 39'sd16)) begin
                        loc = 3'd5; found = 1'b1; er = syn1r; ei = syn1i;
                    end else if ((abs39(syn0r - syn1r) <= 39'sd32) && (abs39(syn0i - syn1i) <= 39'sd32) && (abs39(syn0r - syn2r) <= 39'sd32) && (abs39(syn0i - syn2i) <= 39'sd32)) begin
                        loc = 3'd6; found = 1'b1; er = syn0r; ei = syn0i;
                    end
                    if (found) begin
                        case (loc)
                            3'd2: begin gd0r <= cap3_r[2] - er[34:0]; gd0i <= cap3_i[2] - ei[34:0]; end
                            3'd4: begin gd1r <= cap3_r[4] - er[34:0]; gd1i <= cap3_i[4] - ei[34:0]; end
                            3'd5: begin gd2r <= cap3_r[5] - er[34:0]; gd2i <= cap3_i[5] - ei[34:0]; end
                            3'd6: begin gd3r <= cap3_r[6] - er[34:0]; gd3i <= cap3_i[6] - ei[34:0]; end
                            default: begin end
                        endcase
                    end
                end
            end
        end
    end

    wire v9, l9;
    wire signed [34:0] s0r, s0i, s1r, s1i, s2r, s2i, s3r, s3i;
    s1_tmr_subfft_stage9_v5 s9 (
        clk, rst, gv, gl,
        gd0r, gd0i, gd1r, gd1i, gd2r, gd2i, gd3r, gd3i,
        v9, l9, s0r, s0i, s1r, s1i, s2r, s2i, s3r, s3i
    );
    s1_tmr_subfft_stage10_v5 s10 (
        clk, rst, v9, l9,
        s0r, s0i, s1r, s1i, s2r, s2i, s3r, s3i,
        out_valid, out_last,
        out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im
    );
    wire _unused = in_last;
endmodule
