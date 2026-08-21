`timescale 1ns/1ps

// Single-bit flip on a memory read word (feedback cache site A).
module mem_bitflip_v1 #(
    parameter integer WIDTH = 78
)(
    input  wire [WIDTH-1:0]       clean,
    input  wire                   inject_pulse,
    input  wire [5:0]             bit_index,
    output wire [WIDTH-1:0]       data_out
);
    wire [WIDTH-1:0] mask = (WIDTH'(1) << bit_index);
    assign data_out = inject_pulse ? (clean ^ mask) : clean;
endmodule
