`timescale 1ns/1ps
// Shared on-chip stimulus source for the ROM-fed FI shells (`top_fi_rom_*`):
// stim_rom -> stim_feeder, producing the 4-lane kernel input stream.
module fi_stim_source #(
    parameter integer DEPTH           = 256,
    parameter integer ADDR_W          = 8,
    parameter integer DATA_W          = 280,
    parameter integer BEATS_PER_FRAME = 256,
    parameter         INIT_FILE       = ""
)(
    input  wire               clk,
    input  wire               rst,
    output wire               in_valid,
    output wire               in_last,
    output wire signed [34:0] in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im
);
    wire [ADDR_W-1:0] rom_addr;
    wire [DATA_W-1:0] rom_dout;

    stim_rom #(
        .DEPTH(DEPTH), .ADDR_W(ADDR_W), .DATA_W(DATA_W), .INIT_FILE(INIT_FILE)
    ) u_rom (
        .clk(clk), .addr(rom_addr), .dout(rom_dout)
    );

    stim_feeder #(
        .DEPTH(DEPTH), .ADDR_W(ADDR_W), .BEATS_PER_FRAME(BEATS_PER_FRAME)
    ) u_feed (
        .clk(clk), .rst(rst), .rom_dout(rom_dout), .rom_addr(rom_addr),
        .in_valid(in_valid), .in_last(in_last),
        .in0_re(in0_re), .in0_im(in0_im), .in1_re(in1_re), .in1_im(in1_im),
        .in2_re(in2_re), .in2_im(in2_im), .in3_re(in3_re), .in3_im(in3_im)
    );
endmodule
