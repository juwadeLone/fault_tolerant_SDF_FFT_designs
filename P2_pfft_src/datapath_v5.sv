`timescale 1ns/1ps

// Schema-v5 memory template. Fair-kernel policy: ALL SDF feedback memories use
// distributed RAM (LUTRAM). DEPTH==128 keeps a registered (synchronous) read so
// existing SYNC_READ lane pipelines and bitexact latency stay unchanged; smaller
// depths keep combinatorial read.
module fft_memory_v5 #(
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
    input  wire [WIDTH-1:0]       wr_data
);
generate
if (DEPTH == 128) begin : g_sync_distributed
    (* ram_style = "distributed" *) reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [WIDTH-1:0] read_register;
    always @(posedge clk) begin
        if (rd_en)
            read_register <= mem[rd_addr];
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end
    assign rd_data = read_register;
end else begin : g_async_distributed
    (* ram_style = "distributed" *) reg [WIDTH-1:0] mem [0:DEPTH-1];
    assign rd_data = mem[rd_addr];
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end
    wire _unused_rd_en = rd_en;
end
endgenerate
endmodule


module r2sdf_lane_subfft_v5 #(
    parameter integer DEPTH = 128,
    parameter integer STAGE = 1
)(
    input  wire clk,
    input  wire rst,
    input  wire in_valid,
    input  wire signed [34:0] in_re,
    input  wire signed [34:0] in_im,
    output reg  out_valid,
    output reg  out_last,
    output reg  signed [34:0] out_re,
    output reg  signed [34:0] out_im
);
// 125 MHz pilot: keep SYNC_READ=(DEPTH==128). Store unrotated lower.
// Non-trivial stages: 3-cycle CMUL on first-half output + matching 3-cycle
// upper bypass. Trivial stages: combo rotate-on-read (original latency).
localparam integer PHASE_W = (2*DEPTH <= 2) ? 1 : $clog2(2*DEPTH);
localparam integer ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
localparam integer STRIDE = 256 / (2*DEPTH);
localparam integer SYNC_READ = (DEPTH == 128);
localparam integer TRIVIAL_ONLY = (DEPTH <= 2);
localparam integer USE_PIPE = (TRIVIAL_ONLY == 0);

reg [PHASE_W-1:0] phase;
reg primed;
reg [7:0] out_count;
wire phase_second = (phase >= DEPTH);
wire [ADDR_W-1:0] current_address = phase_second ? (phase - DEPTH) : phase;

reg request_valid, request_second, request_primed;
reg [ADDR_W-1:0] request_address;
reg signed [34:0] request_re, request_im;
wire work_valid = SYNC_READ ? request_valid : in_valid;
wire work_second = SYNC_READ ? request_second : phase_second;
wire work_primed = SYNC_READ ? request_primed : primed;
wire [ADDR_W-1:0] work_address = SYNC_READ ? request_address : current_address;
wire signed [34:0] work_in_re = SYNC_READ ? request_re : in_re;
wire signed [34:0] work_in_im = SYNC_READ ? request_im : in_im;

wire [69:0] memory_read_word;
wire signed [34:0] memory_re = memory_read_word[69:35];
wire signed [34:0] memory_im = memory_read_word[34:0];
wire signed [34:0] sum_re_wrap = memory_re + work_in_re;
wire signed [34:0] sum_im_wrap = memory_im + work_in_im;
wire signed [34:0] diff_re_wrap = memory_re - work_in_re;
wire signed [34:0] diff_im_wrap = memory_im - work_in_im;
wire signed [34:0] upper_re = sum_re_wrap >>> 1;
wire signed [34:0] upper_im = sum_im_wrap >>> 1;
wire signed [34:0] lower_re = diff_re_wrap >>> 1;
wire signed [34:0] lower_im = diff_im_wrap >>> 1;
wire [9:0] twiddle_exponent = (work_address * STRIDE) << 2;
wire signed [34:0] store_re = work_second ? lower_re : work_in_re;
wire signed [34:0] store_im = work_second ? lower_im : work_in_im;
wire candidate_valid = work_second || ((!work_second) && work_primed);
wire emit_raw = work_valid && candidate_valid;
wire raw_is_last = (out_count == 8'd255);

wire signed [34:0] rot_re, rot_im;
wire mul_valid_out;
wire signed [34:0] mul_out_re, mul_out_im;

generate
if (!USE_PIPE) begin : g_triv
    fft_complex_rotate_trivial_1024 u_rot(
        .in_re(memory_re), .in_im(memory_im), .exponent(twiddle_exponent),
        .out_re(rot_re), .out_im(rot_im)
    );
    assign mul_valid_out = 1'b0;
    assign mul_out_re = 35'sd0;
    assign mul_out_im = 35'sd0;
end else begin : g_pipe
    assign rot_re = 35'sd0;
    assign rot_im = 35'sd0;
    fft_complex_mul_q28_pipe u_mul(
        .clk(clk), .rst(rst),
        .valid_in(emit_raw && (!work_second)),
        .in_re(memory_re), .in_im(memory_im), .exponent(twiddle_exponent),
        .valid_out(mul_valid_out), .out_re(mul_out_re), .out_im(mul_out_im)
    );
end
endgenerate

// Bypass mirrors mul's 3 registers: s1, s2, valid_out.
reg bv1, bv2, bv3, bl1, bl2, bl3;
reg signed [34:0] br1, br2, br3, bi1, bi2, bi3;
reg ml1, ml2, ml3;

wire signed [34:0] triv_out_re = work_second ? upper_re : rot_re;
wire signed [34:0] triv_out_im = work_second ? upper_im : rot_im;

fft_memory_v5 #(.WIDTH(70), .DEPTH(DEPTH), .ADDR_W(ADDR_W)) u_memory(
    .clk(clk), .rd_en(in_valid), .rd_addr(current_address), .rd_data(memory_read_word),
    .wr_en(work_valid), .wr_addr(work_address), .wr_data({store_re, store_im})
);

always @(posedge clk) begin
    if (rst) begin
        phase <= {PHASE_W{1'b0}};
        primed <= 1'b0;
        out_count <= 8'd0;
        request_valid <= 1'b0;
        request_second <= 1'b0;
        request_primed <= 1'b0;
        request_address <= {ADDR_W{1'b0}};
        request_re <= 35'sd0;
        request_im <= 35'sd0;
        out_valid <= 1'b0;
        out_last <= 1'b0;
        out_re <= 35'sd0;
        out_im <= 35'sd0;
        bv1 <= 1'b0; bv2 <= 1'b0; bv3 <= 1'b0;
        bl1 <= 1'b0; bl2 <= 1'b0; bl3 <= 1'b0;
        ml1 <= 1'b0; ml2 <= 1'b0; ml3 <= 1'b0;
        br1 <= 35'sd0; br2 <= 35'sd0; br3 <= 35'sd0;
        bi1 <= 35'sd0; bi2 <= 35'sd0; bi3 <= 35'sd0;
    end else begin
        request_valid <= SYNC_READ ? in_valid : 1'b0;
        if (SYNC_READ && in_valid) begin
            request_second <= phase_second;
            request_primed <= primed;
            request_address <= current_address;
            request_re <= in_re;
            request_im <= in_im;
        end
        if (in_valid) begin
            if (phase == (2*DEPTH-1)) begin
                phase <= {PHASE_W{1'b0}};
                primed <= 1'b1;
            end else begin
                phase <= phase + 1'b1;
            end
        end
        if (emit_raw)
            out_count <= out_count + 1'b1;

        if (!USE_PIPE) begin
            out_valid <= 1'b0;
            out_last <= 1'b0;
            if (emit_raw) begin
                out_valid <= 1'b1;
                out_last <= raw_is_last;
                out_re <= triv_out_re;
                out_im <= triv_out_im;
            end
        end else begin
            // Exact mirror of fft_complex_mul_q28_pipe valid pipeline.
            bv1 <= emit_raw && work_second;
            bl1 <= emit_raw && work_second && raw_is_last;
            if (emit_raw && work_second) begin
                br1 <= upper_re;
                bi1 <= upper_im;
            end
            bv2 <= bv1; bl2 <= bl1; br2 <= br1; bi2 <= bi1;
            bv3 <= bv2; bl3 <= bl2; br3 <= br2; bi3 <= bi2;

            ml1 <= emit_raw && (!work_second) && raw_is_last;
            ml2 <= ml1;
            ml3 <= ml2;

            // Same NBA visibility as reading mul_valid_out / mul_out_*.
            out_valid <= mul_valid_out | bv3;
            out_last  <= mul_valid_out ? ml3 : bl3;
            out_re    <= mul_valid_out ? mul_out_re : br3;
            out_im    <= mul_valid_out ? mul_out_im : bi3;
        end
    end
end
endmodule


module subfft_stage4_sdf_v5 #(
    parameter integer DEPTH = 128,
    parameter integer STAGE = 1
)(
    input wire clk, input wire rst, input wire in_valid, input wire in_last,
    input wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    input wire signed [34:0] in2_re, in2_im, in3_re, in3_im,
    output wire out_valid, output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im,
    output wire signed [34:0] out2_re, out2_im, out3_re, out3_im
);
wire [3:0] lane_valid, lane_last;
r2sdf_lane_subfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE)) l0(clk,rst,in_valid,in0_re,in0_im,lane_valid[0],lane_last[0],out0_re,out0_im);
r2sdf_lane_subfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE)) l1(clk,rst,in_valid,in1_re,in1_im,lane_valid[1],lane_last[1],out1_re,out1_im);
r2sdf_lane_subfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE)) l2(clk,rst,in_valid,in2_re,in2_im,lane_valid[2],lane_last[2],out2_re,out2_im);
r2sdf_lane_subfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE)) l3(clk,rst,in_valid,in3_re,in3_im,lane_valid[3],lane_last[3],out3_re,out3_im);
assign out_valid = lane_valid[0];
assign out_last = lane_last[0];
wire _unused = in_last ^ lane_last[1] ^ lane_last[2] ^ lane_last[3] ^ lane_valid[1] ^ lane_valid[2] ^ lane_valid[3];
endmodule


module r2sdf_lane_pfft_v5 #(
    parameter integer DEPTH = 128,
    parameter integer STAGE = 1,
    parameter integer LANE = 0
)(
    input wire clk, input wire rst, input wire in_valid,
    input wire signed [34:0] in_re, in_im,
    output reg out_valid, output reg out_last,
    output reg signed [34:0] out_re, out_im
);
localparam integer PHASE_W = (2*DEPTH <= 2) ? 1 : $clog2(2*DEPTH);
localparam integer ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
localparam integer SYNC_READ = (DEPTH == 128);
localparam [1:0] LANE_ID = LANE;
reg [PHASE_W-1:0] phase;
reg primed;
reg [7:0] out_count;
wire phase_second = (phase >= DEPTH);
wire [ADDR_W-1:0] current_address = phase_second ? phase - DEPTH : phase;

reg request_valid, request_second, request_primed;
reg [ADDR_W-1:0] request_address;
reg signed [34:0] request_re, request_im;
wire work_valid = SYNC_READ ? request_valid : in_valid;
wire work_second = SYNC_READ ? request_second : phase_second;
wire work_primed = SYNC_READ ? request_primed : primed;
wire [ADDR_W-1:0] work_address = SYNC_READ ? request_address : current_address;
wire signed [34:0] work_in_re = SYNC_READ ? request_re : in_re;
wire signed [34:0] work_in_im = SYNC_READ ? request_im : in_im;

wire [69:0] memory_read_word;
wire signed [34:0] memory_re = memory_read_word[69:35];
wire signed [34:0] memory_im = memory_read_word[34:0];
wire signed [34:0] sum_re_wrap = memory_re + work_in_re;
wire signed [34:0] sum_im_wrap = memory_im + work_in_im;
wire signed [34:0] diff_re_wrap = memory_re - work_in_re;
wire signed [34:0] diff_im_wrap = memory_im - work_in_im;
wire signed [34:0] upper_re = sum_re_wrap >>> 1;
wire signed [34:0] upper_im = sum_im_wrap >>> 1;
wire signed [34:0] lower_re = diff_re_wrap >>> 1;
wire signed [34:0] lower_im = diff_im_wrap >>> 1;
wire candidate_valid = work_second || ((!work_second) && work_primed);
wire signed [34:0] candidate_pre_re = work_second ? upper_re : memory_re;
wire signed [34:0] candidate_pre_im = work_second ? upper_im : memory_im;
wire signed [34:0] store_re = work_second ? lower_re : work_in_re;
wire signed [34:0] store_im = work_second ? lower_im : work_in_im;
wire [9:0] physical_index = {out_count,LANE_ID};
wire [9:0] exchanged_exponent;
wire signed [34:0] rotated_re, rotated_im;
pfft_phi_calc #(.STAGE(STAGE)) u_phi(.index(physical_index),.exponent(exchanged_exponent));
generate
    if (STAGE == 1) begin : stage1_trivial_rotation
        fft_complex_rotate_trivial_1024 u_rotation(
            .in_re(candidate_pre_re),.in_im(candidate_pre_im),.exponent(exchanged_exponent),
            .out_re(rotated_re),.out_im(rotated_im)
        );
    end else begin : nontrivial_rotation
        fft_complex_mul_q28 u_rotation(
            .in_re(candidate_pre_re),.in_im(candidate_pre_im),.exponent(exchanged_exponent),
            .out_re(rotated_re),.out_im(rotated_im)
        );
    end
endgenerate

fft_memory_v5 #(.WIDTH(70),.DEPTH(DEPTH),.ADDR_W(ADDR_W)) u_memory(
    .clk(clk),.rd_en(in_valid),.rd_addr(current_address),.rd_data(memory_read_word),
    .wr_en(work_valid),.wr_addr(work_address),.wr_data({store_re,store_im})
);

always @(posedge clk) begin
    if (rst) begin
        phase <= {PHASE_W{1'b0}}; primed <= 1'b0; out_count <= 8'd0;
        request_valid <= 1'b0; request_second <= 1'b0; request_primed <= 1'b0;
        request_address <= {ADDR_W{1'b0}}; request_re <= 35'sd0; request_im <= 35'sd0;
        out_valid <= 1'b0; out_last <= 1'b0; out_re <= 35'sd0; out_im <= 35'sd0;
    end else begin
        request_valid <= SYNC_READ ? in_valid : 1'b0;
        if (SYNC_READ && in_valid) begin
            request_second <= phase_second; request_primed <= primed;
            request_address <= current_address; request_re <= in_re; request_im <= in_im;
        end
        if (in_valid) begin
            if (phase == (2*DEPTH-1)) begin phase <= {PHASE_W{1'b0}}; primed <= 1'b1; end
            else phase <= phase + 1'b1;
        end
        out_valid <= 1'b0; out_last <= 1'b0;
        if (work_valid && candidate_valid) begin
            out_valid <= 1'b1; out_last <= (out_count == 8'd255); out_count <= out_count + 1'b1;
            out_re <= rotated_re; out_im <= rotated_im;
        end
    end
end
endmodule


module pfft_stage4_sdf_v5 #(
    parameter integer DEPTH = 128,
    parameter integer STAGE = 1
)(
    input wire clk, input wire rst, input wire in_valid, input wire in_last,
    input wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    input wire signed [34:0] in2_re, in2_im, in3_re, in3_im,
    output wire out_valid, output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im,
    output wire signed [34:0] out2_re, out2_im, out3_re, out3_im
);
wire [3:0] lane_valid, lane_last;
r2sdf_lane_pfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(0)) l0(clk,rst,in_valid,in0_re,in0_im,lane_valid[0],lane_last[0],out0_re,out0_im);
r2sdf_lane_pfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(1)) l1(clk,rst,in_valid,in1_re,in1_im,lane_valid[1],lane_last[1],out1_re,out1_im);
r2sdf_lane_pfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(2)) l2(clk,rst,in_valid,in2_re,in2_im,lane_valid[2],lane_last[2],out2_re,out2_im);
r2sdf_lane_pfft_v5 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(3)) l3(clk,rst,in_valid,in3_re,in3_im,lane_valid[3],lane_last[3],out3_re,out3_im);
assign out_valid = lane_valid[0];
assign out_last = lane_last[0];
wire _unused = in_last ^ lane_last[1] ^ lane_last[2] ^ lane_last[3] ^ lane_valid[1] ^ lane_valid[2] ^ lane_valid[3];
endmodule


// Canonical, non-exchanged P-SDF lane for the P0/P2 V3 baselines.
//
// A complete SDF butterfly has one lower-branch rotation resource.  During
// the butterfly half-cycle the lower result is rotated before it is written
// to feedback memory; during the feedback half-cycle that stored result is
// emitted directly.  The exchanged per-output pfft_phi_calc schedule is
// deliberately absent.
// 125 MHz: store unrotated lower; rotate-on-read on first-half emit.
// Non-trivial lanes: 3-cycle CMUL + matching upper bypass (same as SubFFT ROR).
(* keep_hierarchy = "yes" *) module r2sdf_lane_pfft_no_exchange_v3 #(
    parameter integer DEPTH = 128,
    parameter integer STAGE = 1,
    parameter integer LANE = 0
)(
    input wire clk, input wire rst, input wire in_valid,
    input wire signed [34:0] in_re, in_im,
    output reg out_valid, output reg out_last,
    output reg signed [34:0] out_re, out_im
);
localparam integer PHASE_W = (2*DEPTH <= 2) ? 1 : $clog2(2*DEPTH);
localparam integer ADDR_W = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
localparam integer SYNC_READ = (DEPTH == 128);
localparam integer TRIVIAL_ONLY =
    ((STAGE == 7) && (LANE == 0)) ||
    ((STAGE == 8) && ((LANE == 0) || (LANE == 2)));
// All stages 1--8 use 3-cycle ROR emit path so trivial/non-trivial lanes stay
// aligned. Attempt9 critical path was stage7 g_combo CMUL (async LUTRAM→DSP).
localparam integer USE_PIPE = 1;
localparam [9:0] LANE_INDEX = LANE;

reg [PHASE_W-1:0] phase;
reg primed;
reg [7:0] out_count;
wire phase_second = (phase >= DEPTH);
wire [ADDR_W-1:0] current_address = phase_second ? phase - DEPTH : phase;

reg request_valid, request_second, request_primed;
reg [ADDR_W-1:0] request_address;
reg signed [34:0] request_re, request_im;
wire work_valid = SYNC_READ ? request_valid : in_valid;
wire work_second = SYNC_READ ? request_second : phase_second;
wire work_primed = SYNC_READ ? request_primed : primed;
wire [ADDR_W-1:0] work_address = SYNC_READ ? request_address : current_address;
wire signed [34:0] work_in_re = SYNC_READ ? request_re : in_re;
wire signed [34:0] work_in_im = SYNC_READ ? request_im : in_im;

wire [69:0] memory_read_word;
wire signed [34:0] memory_re = memory_read_word[69:35];
wire signed [34:0] memory_im = memory_read_word[34:0];
wire signed [34:0] sum_re_wrap = memory_re + work_in_re;
wire signed [34:0] sum_im_wrap = memory_im + work_in_im;
wire signed [34:0] diff_re_wrap = memory_re - work_in_re;
wire signed [34:0] diff_im_wrap = memory_im - work_in_im;
wire signed [34:0] upper_re = sum_re_wrap >>> 1;
wire signed [34:0] upper_im = sum_im_wrap >>> 1;
wire signed [34:0] lower_re = diff_re_wrap >>> 1;
wire signed [34:0] lower_im = diff_im_wrap >>> 1;

// Canonical DIF lower exponent: ((4*a + l) * 2^(STAGE-1)) mod 1024.
// Applied on first-half read of previously stored unrotated lower.
wire [9:0] work_address_extended = {{(10-ADDR_W){1'b0}},work_address};
wire [9:0] canonical_offset = (work_address_extended << 2) + LANE_INDEX;
wire [9:0] lower_exponent = canonical_offset << (STAGE-1);

wire candidate_valid = work_second || ((!work_second) && work_primed);
wire emit_raw = work_valid && candidate_valid;
wire raw_is_last = (out_count == 8'd255);
wire signed [34:0] store_re = work_second ? lower_re : work_in_re;
wire signed [34:0] store_im = work_second ? lower_im : work_in_im;

wire signed [34:0] rot_re, rot_im;
wire mul_valid_out;
wire signed [34:0] mul_out_re, mul_out_im;

generate
if (!TRIVIAL_ONLY) begin : g_pipe
    assign rot_re = 35'sd0;
    assign rot_im = 35'sd0;
    fft_complex_mul_q28_pipe u_mul(
        .clk(clk), .rst(rst),
        .valid_in(emit_raw && (!work_second)),
        .in_re(memory_re), .in_im(memory_im), .exponent(lower_exponent),
        .valid_out(mul_valid_out), .out_re(mul_out_re), .out_im(mul_out_im)
    );
end else begin : g_triv_pipe
    // Trivial twiddle, but still 3-cycle delay to match sibling CMUL lanes.
    wire signed [34:0] triv_re, triv_im;
    fft_complex_rotate_trivial_1024 u_rot(
        .in_re(memory_re), .in_im(memory_im), .exponent(lower_exponent),
        .out_re(triv_re), .out_im(triv_im)
    );
    assign rot_re = triv_re;
    assign rot_im = triv_im;
    reg v1, v2, v3;
    reg signed [34:0] r1, i1, r2, i2, r3, i3;
    always @(posedge clk) begin
        if (rst) begin
            v1 <= 1'b0; v2 <= 1'b0; v3 <= 1'b0;
            r1 <= 35'sd0; i1 <= 35'sd0;
            r2 <= 35'sd0; i2 <= 35'sd0;
            r3 <= 35'sd0; i3 <= 35'sd0;
        end else begin
            v1 <= emit_raw && (!work_second);
            if (emit_raw && (!work_second)) begin
                r1 <= triv_re;
                i1 <= triv_im;
            end
            v2 <= v1; r2 <= r1; i2 <= i1;
            v3 <= v2; r3 <= r2; i3 <= i2;
        end
    end
    assign mul_valid_out = v3;
    assign mul_out_re = r3;
    assign mul_out_im = i3;
end
endgenerate

reg bv1, bv2, bv3, bl1, bl2, bl3;
reg signed [34:0] br1, br2, br3, bi1, bi2, bi3;
reg ml1, ml2, ml3;

wire signed [34:0] triv_out_re = work_second ? upper_re : rot_re;
wire signed [34:0] triv_out_im = work_second ? upper_im : rot_im;

fft_memory_v5 #(.WIDTH(70),.DEPTH(DEPTH),.ADDR_W(ADDR_W)) u_memory(
    .clk(clk),.rd_en(in_valid),.rd_addr(current_address),.rd_data(memory_read_word),
    .wr_en(work_valid),.wr_addr(work_address),.wr_data({store_re,store_im})
);

always @(posedge clk) begin
    if (rst) begin
        phase <= {PHASE_W{1'b0}};
        primed <= 1'b0;
        out_count <= 8'd0;
        request_valid <= 1'b0;
        request_second <= 1'b0;
        request_primed <= 1'b0;
        request_address <= {ADDR_W{1'b0}};
        request_re <= 35'sd0;
        request_im <= 35'sd0;
        out_valid <= 1'b0;
        out_last <= 1'b0;
        out_re <= 35'sd0;
        out_im <= 35'sd0;
        bv1 <= 1'b0; bv2 <= 1'b0; bv3 <= 1'b0;
        bl1 <= 1'b0; bl2 <= 1'b0; bl3 <= 1'b0;
        ml1 <= 1'b0; ml2 <= 1'b0; ml3 <= 1'b0;
        br1 <= 35'sd0; br2 <= 35'sd0; br3 <= 35'sd0;
        bi1 <= 35'sd0; bi2 <= 35'sd0; bi3 <= 35'sd0;
    end else begin
        request_valid <= SYNC_READ ? in_valid : 1'b0;
        if (SYNC_READ && in_valid) begin
            request_second <= phase_second;
            request_primed <= primed;
            request_address <= current_address;
            request_re <= in_re;
            request_im <= in_im;
        end
        if (in_valid) begin
            if (phase == (2*DEPTH-1)) begin
                phase <= {PHASE_W{1'b0}};
                primed <= 1'b1;
            end else begin
                phase <= phase + 1'b1;
            end
        end
        if (emit_raw)
            out_count <= out_count + 1'b1;

        if (!USE_PIPE) begin
            out_valid <= 1'b0;
            out_last <= 1'b0;
            if (emit_raw) begin
                out_valid <= 1'b1;
                out_last <= raw_is_last;
                out_re <= triv_out_re;
                out_im <= triv_out_im;
            end
        end else begin
            bv1 <= emit_raw && work_second;
            bl1 <= emit_raw && work_second && raw_is_last;
            if (emit_raw && work_second) begin
                br1 <= upper_re;
                bi1 <= upper_im;
            end
            bv2 <= bv1; bl2 <= bl1; br2 <= br1; bi2 <= bi1;
            bv3 <= bv2; bl3 <= bl2; br3 <= br2; bi3 <= bi2;

            ml1 <= emit_raw && (!work_second) && raw_is_last;
            ml2 <= ml1;
            ml3 <= ml2;

            out_valid <= mul_valid_out | bv3;
            out_last  <= mul_valid_out ? ml3 : bl3;
            out_re    <= mul_valid_out ? mul_out_re : br3;
            out_im    <= mul_valid_out ? mul_out_im : bi3;
        end
    end
end
endmodule


(* keep_hierarchy = "yes" *) module pfft_stage4_sdf_no_exchange_v3 #(
    parameter integer DEPTH = 128,
    parameter integer STAGE = 1
)(
    input wire clk, input wire rst, input wire in_valid, input wire in_last,
    input wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    input wire signed [34:0] in2_re, in2_im, in3_re, in3_im,
    output wire out_valid, output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im,
    output wire signed [34:0] out2_re, out2_im, out3_re, out3_im
);
wire [3:0] lane_valid, lane_last;
r2sdf_lane_pfft_no_exchange_v3 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(0)) l0(
    clk,rst,in_valid,in0_re,in0_im,lane_valid[0],lane_last[0],out0_re,out0_im
);
r2sdf_lane_pfft_no_exchange_v3 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(1)) l1(
    clk,rst,in_valid,in1_re,in1_im,lane_valid[1],lane_last[1],out1_re,out1_im
);
r2sdf_lane_pfft_no_exchange_v3 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(2)) l2(
    clk,rst,in_valid,in2_re,in2_im,lane_valid[2],lane_last[2],out2_re,out2_im
);
r2sdf_lane_pfft_no_exchange_v3 #(.DEPTH(DEPTH),.STAGE(STAGE),.LANE(3)) l3(
    clk,rst,in_valid,in3_re,in3_im,lane_valid[3],lane_last[3],out3_re,out3_im
);
assign out_valid = lane_valid[0];
assign out_last = lane_last[0];
wire _unused = in_last ^ lane_last[1] ^ lane_last[2] ^ lane_last[3]
             ^ lane_valid[1] ^ lane_valid[2] ^ lane_valid[3];
endmodule


// Canonical DIF Stage 9: butterflies (lane0,lane2) and (lane1,lane3);
// only the second lower result rotates by W_1024^256 = -j.
(* keep_hierarchy = "yes" *) module pfft_stage9_no_exchange_v3(
    input wire clk, input wire rst, input wire in_valid, input wire in_last,
    input wire signed [34:0] in0_re, in0_im, in1_re, in1_im,
    input wire signed [34:0] in2_re, in2_im, in3_re, in3_im,
    output reg out_valid, output reg out_last,
    output reg signed [34:0] out0_re, out0_im, out1_re, out1_im,
    output reg signed [34:0] out2_re, out2_im, out3_re, out3_im
);
wire signed [34:0] sum02_re = in0_re + in2_re;
wire signed [34:0] sum02_im = in0_im + in2_im;
wire signed [34:0] diff02_re = in0_re - in2_re;
wire signed [34:0] diff02_im = in0_im - in2_im;
wire signed [34:0] sum13_re = in1_re + in3_re;
wire signed [34:0] sum13_im = in1_im + in3_im;
wire signed [34:0] diff13_re = in1_re - in3_re;
wire signed [34:0] diff13_im = in1_im - in3_im;
wire signed [34:0] upper0_re = sum02_re >>> 1;
wire signed [34:0] upper0_im = sum02_im >>> 1;
wire signed [34:0] upper1_re = sum13_re >>> 1;
wire signed [34:0] upper1_im = sum13_im >>> 1;
wire signed [34:0] lower2_re = diff02_re >>> 1;
wire signed [34:0] lower2_im = diff02_im >>> 1;
wire signed [34:0] lower3_pre_re = diff13_re >>> 1;
wire signed [34:0] lower3_pre_im = diff13_im >>> 1;
wire signed [34:0] lower3_re = lower3_pre_im;
wire signed [34:0] lower3_im = -lower3_pre_re;

reg valid_pipe, last_pipe;
reg signed [34:0] q0_re,q0_im,q1_re,q1_im,q2_re,q2_im,q3_re,q3_im;
always @(posedge clk) begin
    if (rst) begin
        valid_pipe <= 1'b0;
        last_pipe <= 1'b0;
        out_valid <= 1'b0;
        out_last <= 1'b0;
        q0_re <= 35'sd0; q0_im <= 35'sd0;
        q1_re <= 35'sd0; q1_im <= 35'sd0;
        q2_re <= 35'sd0; q2_im <= 35'sd0;
        q3_re <= 35'sd0; q3_im <= 35'sd0;
        out0_re <= 35'sd0; out0_im <= 35'sd0;
        out1_re <= 35'sd0; out1_im <= 35'sd0;
        out2_re <= 35'sd0; out2_im <= 35'sd0;
        out3_re <= 35'sd0; out3_im <= 35'sd0;
    end else begin
        valid_pipe <= in_valid;
        last_pipe <= in_last;
        out_valid <= valid_pipe;
        out_last <= last_pipe;
        if (in_valid) begin
            q0_re <= upper0_re; q0_im <= upper0_im;
            q1_re <= upper1_re; q1_im <= upper1_im;
            q2_re <= lower2_re; q2_im <= lower2_im;
            q3_re <= lower3_re; q3_im <= lower3_im;
        end
        if (valid_pipe) begin
            out0_re <= q0_re; out0_im <= q0_im;
            out1_re <= q1_re; out1_im <= q1_im;
            out2_re <= q2_re; out2_im <= q2_im;
            out3_re <= q3_re; out3_im <= q3_im;
        end
    end
end
endmodule


// One 70-bit lane of the common two-frame buffer.  512 addresses encode two
// banks x 256 beats. Registered read kept; fair-kernel policy forces LUTRAM.
module pfft_frame_buffer_lane_v5(
    input wire clk,
    input wire read_enable,
    input wire [8:0] read_address,
    input wire write_enable,
    input wire [8:0] write_address,
    input wire [69:0] write_data,
    output reg [69:0] read_data
);
(* ram_style = "distributed" *) reg [69:0] memory [0:511];
always @(posedge clk) begin
    if (read_enable) read_data <= memory[read_address];
    if (write_enable) memory[write_address] <= write_data;
end
endmodule


module pfft_frame_pair_buffer_v5(
    input wire clk, input wire rst, input wire in_valid, input wire in_last,
    input wire signed [34:0] in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
    output reg out_valid, output reg out_last,
    output wire signed [34:0] out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
reg write_bank;
reg have_frame;
reg [7:0] address;
wire [8:0] write_address = {write_bank,address};
wire [8:0] read_address = {~write_bank,address};
wire [69:0] read0,read1,read2,read3;
 pfft_frame_buffer_lane_v5 lane0(clk,in_valid,read_address,in_valid,write_address,{in0_re,in0_im},read0);
 pfft_frame_buffer_lane_v5 lane1(clk,in_valid,read_address,in_valid,write_address,{in1_re,in1_im},read1);
 pfft_frame_buffer_lane_v5 lane2(clk,in_valid,read_address,in_valid,write_address,{in2_re,in2_im},read2);
 pfft_frame_buffer_lane_v5 lane3(clk,in_valid,read_address,in_valid,write_address,{in3_re,in3_im},read3);
assign out0_re=read0[69:35];assign out0_im=read0[34:0];
assign out1_re=read1[69:35];assign out1_im=read1[34:0];
assign out2_re=read2[69:35];assign out2_im=read2[34:0];
assign out3_re=read3[69:35];assign out3_im=read3[34:0];
always @(posedge clk) begin
    if (rst) begin
        write_bank <= 1'b0; have_frame <= 1'b0; address <= 8'd0;
        out_valid <= 1'b0; out_last <= 1'b0;
    end else begin
        out_valid <= in_valid && have_frame;
        out_last <= in_valid && have_frame && (address == 8'd255);
        if (in_valid) begin
            if (address == 8'd255) begin
                address <= 8'd0; write_bank <= ~write_bank; have_frame <= 1'b1;
            end else begin
                address <= address + 1'b1;
            end
        end
    end
end
wire _unused = in_last;
endmodule
