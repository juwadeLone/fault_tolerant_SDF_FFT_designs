`timescale 1ns/1ps
// UART FI shell for P1: streaming kernel inputs + shared UART command path.
module top_fi_p1 (
    input  wire               clk,
    input  wire               rst,
    input  wire               in_valid,
    input  wire               in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
    input  wire               uart_rx,
    output wire               out_valid,
    output wire               out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im,
    output wire [7:0]         fi_status,
    output wire               fi_fired,
    output wire               fi_armed
);
    wire       fire_pulse, arm_component, arm_site_mem;
    wire [3:0] arm_stage_id;
    wire [2:0] arm_sel;
    wire [5:0] arm_bit;

    fi_cmd_path #(.CLKS_PER_BIT(16), .TB_OVERRIDE(1'b1)) u_cmd (
        .clk(clk), .rst(rst), .uart_rx(uart_rx),
        .fi_status(fi_status), .fi_fired(fi_fired), .fi_armed(fi_armed),
        .fire_pulse(fire_pulse), .arm_stage_id(arm_stage_id), .arm_sel(arm_sel),
        .arm_component(arm_component), .arm_site_mem(arm_site_mem), .arm_bit(arm_bit)
    );

    top_p1_pfft_ecc u_dut (
        .clk(clk), .rst(rst), .in_valid(in_valid), .in_last(in_last),
        .in0_re(in0_re), .in0_im(in0_im), .in1_re(in1_re), .in1_im(in1_im),
        .in2_re(in2_re), .in2_im(in2_im), .in3_re(in3_re), .in3_im(in3_im),
        .out_valid(out_valid), .out_last(out_last),
        .out0_re(out0_re), .out0_im(out0_im), .out1_re(out1_re), .out1_im(out1_im),
        .out2_re(out2_re), .out2_im(out2_im), .out3_re(out3_re), .out3_im(out3_im),
        .fi_fire_pulse(fire_pulse), .fi_site_mem(arm_site_mem), .fi_arm_stage(arm_stage_id),
        .fi_arm_sel(arm_sel), .fi_arm_component(arm_component), .fi_arm_bit(arm_bit)
    );
endmodule
