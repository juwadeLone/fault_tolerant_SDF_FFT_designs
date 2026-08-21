`timescale 1ns/1ps
// ROM-fed FI shell: on-chip stimulus ROM -> DUT; UART only for FI commands.
// External ports kept small for synth/impl. Not a paper fair-kernel top.
module top_fi_rom_p2 (
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire [7:0] fi_status,
    output wire       fi_fired,
    output wire       fi_armed,
    output wire       out_valid,
    output wire       out_last
);
    localparam integer DEPTH  = 256;
    localparam integer ADDR_W = 8;
    localparam INIT_FILE = "P2_input.mem"  // stimulus image: generate/supply it yourself, see uart_fi/README.md;

    wire                in_valid, in_last;
    wire signed [34:0]  in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im;
    wire signed [34:0]  out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im;

    wire [ADDR_W-1:0]   rom_addr;
    wire [279:0]        rom_dout;

    wire        frame_valid, frame_bad;
    wire        uart_byte_ready;
    wire [7:0]  uart_rx_byte;
    wire [7:0]  opcode, site, stage_id, sel, component, bit_index, trig_mode;
    wire [15:0] trig_count;
    wire        fire_pulse;
    wire [3:0]  arm_stage_id;
    wire [2:0]  arm_sel;
    wire        arm_component, arm_site_mem;
    wire [5:0]  arm_bit;
    wire [7:0]  status_code;
    wire [7:0]  last_site;
    wire        bad_cmd;

    stim_rom #(
        .DEPTH(DEPTH), .ADDR_W(ADDR_W), .DATA_W(280), .INIT_FILE(INIT_FILE)
    ) u_rom (
        .clk(clk), .addr(rom_addr), .dout(rom_dout)
    );

    stim_feeder #(
        .DEPTH(DEPTH), .ADDR_W(ADDR_W), .BEATS_PER_FRAME(256)
    ) u_feed (
        .clk(clk), .rst(rst), .rom_dout(rom_dout), .rom_addr(rom_addr),
        .in_valid(in_valid), .in_last(in_last),
        .in0_re(in0_re), .in0_im(in0_im), .in1_re(in1_re), .in1_im(in1_im),
        .in2_re(in2_re), .in2_im(in2_im), .in3_re(in3_re), .in3_im(in3_im)
    );

    uart_rx_simple #(.CLKS_PER_BIT(16)) u_uart (
        .clk(clk), .rst(rst), .rx(uart_rx),
        .byte_ready(uart_byte_ready), .rx_byte(uart_rx_byte)
    );

    uart_cmd_decoder u_dec (
        .clk(clk), .rst(rst),
        .byte_ready(uart_byte_ready), .rx_byte(uart_rx_byte),
        .frame_valid(frame_valid), .opcode(opcode), .site(site), .stage_id(stage_id),
        .sel(sel), .component(component), .bit_index(bit_index), .trig_mode(trig_mode),
        .trig_count(trig_count), .frame_bad(frame_bad)
    );

    fi_controller u_fi (
        .clk(clk), .rst(rst),
        .frame_valid(frame_valid), .opcode(opcode), .site(site),
        .stage_id(stage_id), .sel(sel), .component(component), .bit_index(bit_index),
        .trig_mode(trig_mode), .trig_count(trig_count), .frame_bad(frame_bad),
        .armed(fi_armed), .fired(fi_fired), .last_site(last_site), .bad_cmd(bad_cmd),
        .arm_stage_id(arm_stage_id), .arm_sel(arm_sel), .arm_component(arm_component),
        .arm_bit(arm_bit), .arm_site_mem(arm_site_mem), .fire_pulse(fire_pulse),
        .status_code(status_code)
    );
    assign fi_status = status_code;

    top_p2_pfft_tmr_no_framebuf_v1 u_dut (
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
