`timescale 1ns/1ps
// Walk ROM addresses (1-cycle sync ROM latency) and unpack onto DUT inputs.
module stim_feeder #(
    parameter integer DEPTH           = 256,
    parameter integer ADDR_W          = 8,
    parameter integer BEATS_PER_FRAME = 256
) (
    input  wire               clk,
    input  wire               rst,
    input  wire [279:0]       rom_dout,
    output reg  [ADDR_W-1:0]  rom_addr,
    output reg                in_valid,
    output reg                in_last,
    output wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    output wire signed [34:0] in2_re, in2_im, in3_re, in3_im
);
    localparam integer LAST_ADDR = DEPTH - 1;

    reg                  issuing;
    reg                  data_phase;
    reg [ADDR_W-1:0]     addr_q;
    reg [ADDR_W-1:0]     addr_d;  // addr associated with current rom_dout

    assign {in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im} = rom_dout;

    always @(posedge clk) begin
        if (rst) begin
            issuing    <= 1'b0;
            data_phase <= 1'b0;
            addr_q     <= {ADDR_W{1'b0}};
            addr_d     <= {ADDR_W{1'b0}};
            rom_addr   <= {ADDR_W{1'b0}};
            in_valid   <= 1'b0;
            in_last    <= 1'b0;
        end else begin
            if (!issuing) begin
                issuing  <= 1'b1;
                rom_addr <= {ADDR_W{1'b0}};
                addr_q   <= {ADDR_W{1'b0}};
                data_phase <= 1'b0;
                in_valid <= 1'b0;
                in_last  <= 1'b0;
            end else if (!data_phase) begin
                // first ROM latency cycle
                data_phase <= 1'b1;
                addr_d     <= addr_q;
                in_valid   <= 1'b1;
                in_last    <= ((addr_q % BEATS_PER_FRAME) == (BEATS_PER_FRAME - 1));
                if (addr_q != LAST_ADDR[ADDR_W-1:0]) begin
                    addr_q   <= addr_q + 1'b1;
                    rom_addr <= addr_q + 1'b1;
                end
            end else if (addr_d != LAST_ADDR[ADDR_W-1:0]) begin
                addr_d   <= addr_q;
                in_valid <= 1'b1;
                in_last  <= ((addr_q % BEATS_PER_FRAME) == (BEATS_PER_FRAME - 1));
                if (addr_q != LAST_ADDR[ADDR_W-1:0]) begin
                    addr_q   <= addr_q + 1'b1;
                    rom_addr <= addr_q + 1'b1;
                end
            end else begin
                in_valid <= 1'b0;
                in_last  <= 1'b0;
            end
        end
    end
endmodule
