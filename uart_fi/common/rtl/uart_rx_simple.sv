`timescale 1ns/1ps

module uart_rx_simple #(
    parameter integer CLKS_PER_BIT = 16
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg        byte_ready,
    output reg [7:0]  rx_byte,
    output reg        frame_err
);
    localparam integer IDLE   = 0;
    localparam integer START  = 1;
    localparam integer DATA   = 2;
    localparam integer STOP   = 3;
    localparam integer RESYNC = 4;

    reg [2:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
            byte_ready <= 1'b0;
            rx_byte <= 8'h00;
            frame_err <= 1'b0;
        end else begin
            byte_ready <= 1'b0;
            frame_err <= 1'b0;
            case (state)
                IDLE: begin
                    clk_cnt <= 0;
                    if (!rx) begin
                        state <= START;
                        clk_cnt <= 0;
                    end
                end
                START: begin
                    if (clk_cnt == (CLKS_PER_BIT / 2) - 1) begin
                        state <= DATA;
                        clk_cnt <= 0;
                        bit_idx <= 0;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        rx_byte[bit_idx] <= rx;
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            state <= STOP;
                            bit_idx <= 0;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (rx) begin
                            byte_ready <= 1'b1;
                            state <= IDLE;
                        end else begin
                            frame_err <= 1'b1;
                            state <= RESYNC;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                RESYNC: begin
                    if (rx)
                        state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
