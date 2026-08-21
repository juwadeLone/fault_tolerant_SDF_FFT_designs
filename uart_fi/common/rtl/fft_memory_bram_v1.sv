`timescale 1ns/1ps

// Behavioral feedback memory for FI functional sim (drop-in for fft_memory_v5).
// Optional single-bit flip on the registered read port (site A).
module fft_memory_bram_v1 #(
    parameter integer WIDTH = 70,
    parameter integer DEPTH = 128,
    parameter integer ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
)(
    input  wire                   clk,
    input  wire                   rd_en,
    input  wire [ADDR_W-1:0]      rd_addr,
    output wire [WIDTH-1:0]       rd_data,
    input  wire                   wr_en,
    input  wire [ADDR_W-1:0]      wr_addr,
    input  wire [WIDTH-1:0]       wr_data,
    input  wire                   fi_inject_pulse,
    input  wire [5:0]             fi_bit_index
);
    wire [WIDTH-1:0] rd_data_clean;

    generate
    if (DEPTH == 128) begin : g_sync
        reg [WIDTH-1:0] mem [0:DEPTH-1];
        reg [WIDTH-1:0] read_register;
        always @(posedge clk) begin
            if (rd_en)
                read_register <= mem[rd_addr];
            if (wr_en)
                mem[wr_addr] <= wr_data;
        end
        assign rd_data_clean = read_register;
    end else begin : g_async
        reg [WIDTH-1:0] mem [0:DEPTH-1];
        assign rd_data_clean = mem[rd_addr];
        always @(posedge clk) begin
            if (wr_en)
                mem[wr_addr] <= wr_data;
        end
        wire _unused_rd_en = rd_en;
    end
    endgenerate

    mem_bitflip_v1 #(.WIDTH(WIDTH)) u_flip (
        .clean(rd_data_clean),
        .inject_pulse(fi_inject_pulse),
        .bit_index(fi_bit_index),
        .data_out(rd_data)
    );
endmodule
