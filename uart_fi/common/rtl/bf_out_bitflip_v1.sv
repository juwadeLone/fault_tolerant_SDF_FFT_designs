`timescale 1ns/1ps

// Single-bit flip on one butterfly output component (site B).
// sel[2]=branch (0=upper,1=lower), sel[1:0]=lane; component 0=re, 1=im.
module bf_out_bitflip_v1 (
    input  wire signed [34:0] u0r, u0i, u1r, u1i, u2r, u2i, u3r, u3i,
    input  wire signed [34:0] l0r, l0i, l1r, l1i, l2r, l2i, l3r, l3i,
    input  wire                 inject_pulse,
    input  wire [2:0]           sel,
    input  wire                 component,
    input  wire [5:0]           bit_index,
    output wire signed [34:0]   o_u0r, o_u0i, o_u1r, o_u1i, o_u2r, o_u2i, o_u3r, o_u3i,
    output wire signed [34:0]   o_l0r, o_l0i, o_l1r, o_l1i, o_l2r, o_l2i, o_l3r, o_l3i
);
    wire branch = sel[2];
    wire [1:0] lane = sel[1:0];

    wire act_u0r = inject_pulse && !branch && lane == 2'd0 && !component;
    wire act_u0i = inject_pulse && !branch && lane == 2'd0 &&  component;
    wire act_u1r = inject_pulse && !branch && lane == 2'd1 && !component;
    wire act_u1i = inject_pulse && !branch && lane == 2'd1 &&  component;
    wire act_u2r = inject_pulse && !branch && lane == 2'd2 && !component;
    wire act_u2i = inject_pulse && !branch && lane == 2'd2 &&  component;
    wire act_u3r = inject_pulse && !branch && lane == 2'd3 && !component;
    wire act_u3i = inject_pulse && !branch && lane == 2'd3 &&  component;
    wire act_l0r = inject_pulse &&  branch && lane == 2'd0 && !component;
    wire act_l0i = inject_pulse &&  branch && lane == 2'd0 &&  component;
    wire act_l1r = inject_pulse &&  branch && lane == 2'd1 && !component;
    wire act_l1i = inject_pulse &&  branch && lane == 2'd1 &&  component;
    wire act_l2r = inject_pulse &&  branch && lane == 2'd2 && !component;
    wire act_l2i = inject_pulse &&  branch && lane == 2'd2 &&  component;
    wire act_l3r = inject_pulse &&  branch && lane == 2'd3 && !component;
    wire act_l3i = inject_pulse &&  branch && lane == 2'd3 &&  component;

    assign o_u0r = act_u0r ? (u0r ^ (35'sd1 << bit_index)) : u0r;
    assign o_u0i = act_u0i ? (u0i ^ (35'sd1 << bit_index)) : u0i;
    assign o_u1r = act_u1r ? (u1r ^ (35'sd1 << bit_index)) : u1r;
    assign o_u1i = act_u1i ? (u1i ^ (35'sd1 << bit_index)) : u1i;
    assign o_u2r = act_u2r ? (u2r ^ (35'sd1 << bit_index)) : u2r;
    assign o_u2i = act_u2i ? (u2i ^ (35'sd1 << bit_index)) : u2i;
    assign o_u3r = act_u3r ? (u3r ^ (35'sd1 << bit_index)) : u3r;
    assign o_u3i = act_u3i ? (u3i ^ (35'sd1 << bit_index)) : u3i;
    assign o_l0r = act_l0r ? (l0r ^ (35'sd1 << bit_index)) : l0r;
    assign o_l0i = act_l0i ? (l0i ^ (35'sd1 << bit_index)) : l0i;
    assign o_l1r = act_l1r ? (l1r ^ (35'sd1 << bit_index)) : l1r;
    assign o_l1i = act_l1i ? (l1i ^ (35'sd1 << bit_index)) : l1i;
    assign o_l2r = act_l2r ? (l2r ^ (35'sd1 << bit_index)) : l2r;
    assign o_l2i = act_l2i ? (l2i ^ (35'sd1 << bit_index)) : l2i;
    assign o_l3r = act_l3r ? (l3r ^ (35'sd1 << bit_index)) : l3r;
    assign o_l3i = act_l3i ? (l3i ^ (35'sd1 << bit_index)) : l3i;
endmodule
