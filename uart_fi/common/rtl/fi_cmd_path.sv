`timescale 1ns/1ps
// Shared UART fault-injection command path: uart_rx_simple -> uart_cmd_decoder
// -> fi_controller, exposing the ARM/FIRE outputs consumed by a DUT.
//
// TB_OVERRIDE=1 adds the simulation command-injection port used by the
// streaming shells (`top_fi_*`): the tb_* nets are forced to their idle values
// here and a testbench overrides them hierarchically, e.g.
//   force <dut_inst>.u_cmd.g_tb.tb_cmd_valid = 1'b1;
// TB_OVERRIDE=0 (the ROM shells) drives fi_controller from the UART only.
module fi_cmd_path #(
    parameter integer CLKS_PER_BIT = 16,
    parameter bit     TB_OVERRIDE  = 1'b0
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       uart_rx,
    output wire [7:0] fi_status,
    output wire       fi_fired,
    output wire       fi_armed,
    output wire       fire_pulse,
    output wire [3:0] arm_stage_id,
    output wire [2:0] arm_sel,
    output wire       arm_component,
    output wire       arm_site_mem,
    output wire [5:0] arm_bit
);
    wire        frame_valid, frame_bad;
    wire        uart_byte_ready;
    wire [7:0]  uart_rx_byte;
    wire        dec_byte_ready;
    wire [7:0]  dec_rx_byte;
    wire [7:0]  opcode, site, stage_id, sel, component, bit_index, trig_mode;
    wire [15:0] trig_count;
    wire        fi_frame_valid;
    wire [7:0]  fi_opcode, fi_site, fi_stage_id, fi_sel, fi_component, fi_bit_index;
    wire [7:0]  fi_trig_mode;
    wire [15:0] fi_trig_count;
    wire        fi_frame_bad;
    wire [7:0]  status_code;
    wire [7:0]  last_site;
    wire        bad_cmd;

    uart_rx_simple #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart (
        .clk(clk), .rst(rst), .rx(uart_rx), .byte_ready(uart_byte_ready), .rx_byte(uart_rx_byte)
    );

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

    generate
    if (TB_OVERRIDE) begin : g_tb
        wire        tb_uart_strobe;
        wire [7:0]  tb_uart_byte;
        wire        tb_cmd_valid;
        wire [7:0]  tb_opcode, tb_site, tb_stage_id, tb_sel, tb_component, tb_bit_index;
        wire [7:0]  tb_trig_mode;
        wire [15:0] tb_trig_count;
        wire        tb_frame_bad;

        assign dec_byte_ready = tb_uart_strobe | uart_byte_ready;
        assign dec_rx_byte = tb_uart_strobe ? tb_uart_byte : uart_rx_byte;

        assign fi_frame_valid = tb_cmd_valid | frame_valid;
        assign fi_opcode = tb_cmd_valid ? tb_opcode : opcode;
        assign fi_site = tb_cmd_valid ? tb_site : site;
        assign fi_stage_id = tb_cmd_valid ? tb_stage_id : stage_id;
        assign fi_sel = tb_cmd_valid ? tb_sel : sel;
        assign fi_component = tb_cmd_valid ? tb_component : component;
        assign fi_bit_index = tb_cmd_valid ? tb_bit_index : bit_index;
        assign fi_trig_mode = tb_cmd_valid ? tb_trig_mode : trig_mode;
        assign fi_trig_count = tb_cmd_valid ? tb_trig_count : trig_count;
        assign fi_frame_bad = tb_cmd_valid ? tb_frame_bad : frame_bad;

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
    end else begin : g_uart_only
        assign dec_byte_ready = uart_byte_ready;
        assign dec_rx_byte = uart_rx_byte;

        assign fi_frame_valid = frame_valid;
        assign fi_opcode = opcode;
        assign fi_site = site;
        assign fi_stage_id = stage_id;
        assign fi_sel = sel;
        assign fi_component = component;
        assign fi_bit_index = bit_index;
        assign fi_trig_mode = trig_mode;
        assign fi_trig_count = trig_count;
        assign fi_frame_bad = frame_bad;
    end
    endgenerate
endmodule
