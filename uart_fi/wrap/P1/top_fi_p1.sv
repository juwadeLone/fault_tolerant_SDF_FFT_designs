`timescale 1ns/1ps

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
    wire        frame_valid, frame_bad;
    wire        uart_byte_ready, tb_uart_strobe;
    wire        uart_frame_err;
    wire [7:0]  uart_rx_byte, tb_uart_byte;
    wire        dec_byte_ready;
    wire [7:0]  dec_rx_byte;
    wire [7:0]  opcode, site, stage_id, sel, component, bit_index, trig_mode;
    wire [15:0] trig_count;
    wire        tb_cmd_valid;
    wire [7:0]  tb_opcode, tb_site, tb_stage_id, tb_sel, tb_component, tb_bit_index;
    wire [7:0]  tb_trig_mode;
    wire [15:0] tb_trig_count;
    wire        tb_frame_bad;
    wire [7:0]  fi_opcode, fi_site, fi_stage_id, fi_sel, fi_component, fi_bit_index;
    wire [7:0]  fi_trig_mode;
    wire [15:0] fi_trig_count;
    wire        fi_frame_bad;
    wire        fire_pulse;
    wire        fi_frame_valid;
    wire [3:0]  arm_stage_id;
    wire [2:0]  arm_sel;
    wire        arm_component, arm_site_mem;
    wire [5:0]  arm_bit;
    wire [7:0]  status_code;
    wire [7:0]  last_site;
    wire        bad_cmd;

    uart_rx_simple #(.CLKS_PER_BIT(16)) u_uart (
        .clk(clk), .rst(rst), .rx(uart_rx), .byte_ready(uart_byte_ready), .rx_byte(uart_rx_byte),
        .frame_err(uart_frame_err)
    );

    assign dec_byte_ready = tb_uart_strobe | uart_byte_ready;
    assign dec_rx_byte = tb_uart_strobe ? tb_uart_byte : uart_rx_byte;

    uart_cmd_decoder u_dec (
        .clk(clk), .rst(rst), .byte_ready(dec_byte_ready), .rx_byte(dec_rx_byte),
        .frame_valid(frame_valid), .opcode(opcode), .site(site), .stage_id(stage_id),
        .sel(sel), .component(component), .bit_index(bit_index), .trig_mode(trig_mode),
        .trig_count(trig_count), .frame_bad(frame_bad)
    );

    fi_controller u_fi (
        .clk(clk), .rst(rst), .frame_valid(fi_frame_valid), .opcode(fi_opcode), .site(fi_site),
        .stage_id(fi_stage_id), .sel(fi_sel), .component(fi_component), .bit_index(fi_bit_index),
        .trig_mode(fi_trig_mode), .trig_count(fi_trig_count), .frame_bad(fi_frame_bad),
        .armed(fi_armed), .fired(fi_fired), .last_site(last_site), .bad_cmd(bad_cmd),
        .arm_stage_id(arm_stage_id), .arm_sel(arm_sel), .arm_component(arm_component),
        .arm_bit(arm_bit), .arm_site_mem(arm_site_mem), .fire_pulse(fire_pulse),
        .status_code(status_code)
    );
    assign fi_status = status_code;

    assign fi_frame_valid = tb_cmd_valid | frame_valid;
    assign fi_opcode = tb_cmd_valid ? tb_opcode : opcode;
    assign fi_site = tb_cmd_valid ? tb_site : site;
    assign fi_stage_id = tb_cmd_valid ? tb_stage_id : stage_id;
    assign fi_sel = tb_cmd_valid ? tb_sel : sel;
    assign fi_component = tb_cmd_valid ? tb_component : component;
    assign fi_bit_index = tb_cmd_valid ? tb_bit_index : bit_index;
    assign fi_trig_mode = tb_cmd_valid ? tb_trig_mode : trig_mode;
    assign fi_trig_count = tb_cmd_valid ? tb_trig_count : trig_count;
    assign fi_frame_bad = tb_cmd_valid ? tb_frame_bad : (frame_bad | uart_frame_err);

    initial begin
        force tb_cmd_valid = 1'b0;
        force tb_opcode = 8'h00;
        force tb_site = 8'h00;
        force tb_stage_id = 8'h00;
        force tb_sel = 8'h00;
        force tb_component = 8'h00;
        force tb_bit_index = 8'h00;
        force tb_trig_mode = 8'h00;
        force tb_trig_count = 16'h0000;
        force tb_frame_bad = 1'b0;
        force tb_uart_strobe = 1'b0;
        force tb_uart_byte = 8'h00;
    end

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
