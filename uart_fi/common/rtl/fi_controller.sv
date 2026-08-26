`timescale 1ns/1ps

module fi_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire       frame_valid,
    input  wire [7:0] opcode,
    input  wire [7:0] site,
    input  wire [7:0] stage_id,
    input  wire [7:0] sel,
    input  wire [7:0] component,
    input  wire [7:0] bit_index,
    input  wire [7:0] trig_mode,
    input  wire [15:0] trig_count,
    input  wire       frame_bad,
    output reg        armed,
    output reg        fired,
    output reg [7:0]  last_site,
    output reg        bad_cmd,
    output reg [3:0]  arm_stage_id,
    output reg [2:0]  arm_sel,
    output reg        arm_component,
    output reg [5:0]  arm_bit,
    output reg        arm_site_mem,
    output reg        fire_pulse,
    output reg [7:0]  status_code
);
    localparam OPC_NOP = 8'h00, OPC_ARM = 8'h01, OPC_FIRE = 8'h02;
    localparam OPC_STATUS = 8'h03, OPC_RESET = 8'h04;
    localparam ST_IDLE = 8'h00, ST_ARMED = 8'h01, ST_FIRED = 8'h02, ST_BAD = 8'h03;

    always @(posedge clk) begin
        if (rst) begin
            armed <= 1'b0;
            fired <= 1'b0;
            bad_cmd <= 1'b0;
            fire_pulse <= 1'b0;
            status_code <= ST_IDLE;
            last_site <= 8'h00;
        end else begin
            fire_pulse <= 1'b0;
            if (frame_bad) begin
                bad_cmd <= 1'b1;
                status_code <= ST_BAD;
            end

            if (frame_valid) begin
                case (opcode)
                    OPC_ARM: begin
                        if (site > 8'd1 || stage_id < 8'd1 || stage_id > 8'd10 || bit_index > 8'd77) begin
                            bad_cmd <= 1'b1;
                            status_code <= ST_BAD;
                        end else begin
                            armed <= 1'b1;
                            fired <= 1'b0;
                            bad_cmd <= 1'b0;
                            arm_stage_id <= stage_id[3:0];
                            arm_sel <= sel[2:0];
                            arm_component <= component[0];
                            arm_bit <= bit_index[5:0];
                            arm_site_mem <= (site == 8'd0);
                            last_site <= site;
                            status_code <= ST_ARMED;
                        end
                    end
                    OPC_FIRE: begin
                        if (armed) begin
                            fire_pulse <= 1'b1;
                            fired <= 1'b1;
                            armed <= 1'b0;
                            status_code <= ST_FIRED;
                        end else begin
                            bad_cmd <= 1'b1;
                            status_code <= ST_BAD;
                        end
                    end
                    OPC_RESET: begin
                        armed <= 1'b0;
                        fired <= 1'b0;
                        bad_cmd <= 1'b0;
                        status_code <= ST_IDLE;
                    end
                    OPC_STATUS: begin
                        status_code <= fired ? ST_FIRED : (armed ? ST_ARMED : (bad_cmd ? ST_BAD : ST_IDLE));
                    end
                    OPC_NOP: ;
                    default: begin
                        bad_cmd <= 1'b1;
                        status_code <= ST_BAD;
                    end
                endcase
            end
        end
    end

    wire _unused_trig = |trig_mode;
    wire _unused_cnt = |trig_count;
endmodule
