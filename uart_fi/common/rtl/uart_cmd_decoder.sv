`timescale 1ns/1ps

module uart_cmd_decoder (
    input  wire       clk,
    input  wire       rst,
    input  wire       byte_ready,
    input  wire [7:0] rx_byte,
    output reg        frame_valid,
    output reg [7:0]  opcode,
    output reg [7:0]  site,
    output reg [7:0]  stage_id,
    output reg [7:0]  sel,
    output reg [7:0]  component,
    output reg [7:0]  bit_index,
    output reg [7:0]  trig_mode,
    output reg [15:0] trig_count,
    output reg        frame_bad
);
    localparam byte PREAMBLE = 8'hA5;
    reg [3:0] idx;
    reg [7:0] frame_buf [0:10];
    reg collecting;

    function automatic [7:0] xor_checksum;
        input [7:0] bytes [0:10];
        integer i;
        begin
            xor_checksum = 8'h00;
            for (i = 1; i <= 9; i = i + 1)
                xor_checksum = xor_checksum ^ bytes[i];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            idx <= 0;
            collecting <= 1'b0;
            frame_valid <= 1'b0;
            frame_bad <= 1'b0;
        end else begin
            frame_valid <= 1'b0;
            frame_bad <= 1'b0;
            if (byte_ready) begin
                if (!collecting) begin
                    if (rx_byte == PREAMBLE) begin
                        collecting <= 1'b1;
                        idx <= 4'd1;
                        frame_buf[0] <= rx_byte;
                    end
                end else begin
                    idx <= idx + 1;
                    frame_buf[idx] <= rx_byte;
                    if (idx == 4'd10) begin
                        collecting <= 1'b0;
                        if (xor_checksum(frame_buf) == rx_byte) begin
                            opcode <= frame_buf[1];
                            site <= frame_buf[2];
                            stage_id <= frame_buf[3];
                            sel <= frame_buf[4];
                            component <= frame_buf[5];
                            bit_index <= frame_buf[6];
                            trig_mode <= frame_buf[7];
                            trig_count <= {frame_buf[9], frame_buf[8]};
                            frame_valid <= 1'b1;
                        end else
                            frame_bad <= 1'b1;
                    end
                end
            end
        end
    end
endmodule
