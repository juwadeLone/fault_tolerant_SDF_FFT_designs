`timescale 1ns/1ps
// On-chip stimulus ROM. Init via $readmemh (.mem); matching .coe also provided for IP use.
module stim_rom #(
    parameter integer DEPTH     = 256,
    parameter integer ADDR_W    = 8,
    parameter integer DATA_W    = 280,
    parameter         INIT_FILE = ""
) (
    input  wire                 clk,
    input  wire [ADDR_W-1:0]    addr,
    output reg  [DATA_W-1:0]    dout
);
    (* rom_style = "block" *) reg [DATA_W-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    always @(posedge clk) begin
        dout <= mem[addr];
    end
endmodule
