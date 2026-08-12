`timescale 1ns/1ps

module ecc_stage4_v5 #(
 parameter integer DEPTH=128,
 parameter integer STAGE=1,
 parameter integer PFFT_MODE=0
)(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output reg out_valid,output reg out_last,
 output reg signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
localparam integer PHASE_W=(2*DEPTH<=2)?1:$clog2(2*DEPTH);
localparam integer ADDR_W=(DEPTH<=1)?1:$clog2(DEPTH);
localparam integer STRIDE=256/(2*DEPTH);
// Match S0: only DEPTH==128 uses sync-read. Always-sync broke bitexact.
localparam integer SYNC_READ=(DEPTH==128);
localparam integer HETEROGENEOUS_STAGE8=(PFFT_MODE!=0)&&(STAGE==8);
// SubFFT: store unrotated lower; rotate on first-half output (S0-style).
localparam integer SUBFFT_ROR=(PFFT_MODE==0);
localparam integer TRIVIAL_ONLY=(DEPTH<=2);
localparam integer USE_PIPE=SUBFFT_ROR && (TRIVIAL_ONLY==0);
// Decode→butterfly cut for all DEPTH; async RMW uses store forward.
localparam integer USE_WORK2=1;

reg[PHASE_W-1:0]phase;reg primed;reg[7:0]out_count;
wire phase_second=(phase>=DEPTH);
wire[ADDR_W-1:0]current_address=phase_second?phase-DEPTH:phase;

reg request_valid,request_second,request_primed;reg[ADDR_W-1:0]request_address;
reg signed[34:0]q0r,q0i,q1r,q1i,q2r,q2i,q3r,q3i;
wire work_valid=SYNC_READ?request_valid:in_valid;
wire work_second=SYNC_READ?request_second:phase_second;
wire work_primed=SYNC_READ?request_primed:primed;
wire[ADDR_W-1:0]work_address=SYNC_READ?request_address:current_address;
wire signed[34:0]b0r=SYNC_READ?q0r:in0_re,b0i=SYNC_READ?q0i:in0_im;
wire signed[34:0]b1r=SYNC_READ?q1r:in1_re,b1i=SYNC_READ?q1i:in1_im;
wire signed[34:0]b2r=SYNC_READ?q2r:in2_re,b2i=SYNC_READ?q2i:in2_im;
wire signed[34:0]b3r=SYNC_READ?q3r:in3_re,b3i=SYNC_READ?q3i:in3_im;

wire[77:0]mcode0,mcode1,mcode2,mcode3;
wire[69:0]mdata0,mdata1,mdata2,mdata3;wire[3:0]mem_detected,mem_corrected;
secded_decode70 dec0(mcode0,mdata0,mem_detected[0],mem_corrected[0]);
secded_decode70 dec1(mcode1,mdata1,mem_detected[1],mem_corrected[1]);
secded_decode70 dec2(mcode2,mdata2,mem_detected[2],mem_corrected[2]);
secded_decode70 dec3(mcode3,mdata3,mem_detected[3],mem_corrected[3]);
// a* assigned after store_* (forward may bypass decode)
wire signed[34:0]a0r,a0i,a1r,a1i,a2r,a2i,a3r,a3i;

// Optional capture before ECC butterfly / encode / write.
reg work2, work2_second, work2_primed;
reg [ADDR_W-1:0] work2_address;
reg signed[34:0] ca0r,ca0i,ca1r,ca1i,ca2r,ca2i,ca3r,ca3i;
reg signed[34:0] cb0r,cb0i,cb1r,cb1i,cb2r,cb2i,cb3r,cb3i;

wire do_work = USE_WORK2 ? work2 : work_valid;
wire do_second = USE_WORK2 ? work2_second : work_second;
wire do_primed = USE_WORK2 ? work2_primed : work_primed;
wire [ADDR_W-1:0] do_address = USE_WORK2 ? work2_address : work_address;
wire signed[34:0] da0r = USE_WORK2 ? ca0r : a0r, da0i = USE_WORK2 ? ca0i : a0i;
wire signed[34:0] da1r = USE_WORK2 ? ca1r : a1r, da1i = USE_WORK2 ? ca1i : a1i;
wire signed[34:0] da2r = USE_WORK2 ? ca2r : a2r, da2i = USE_WORK2 ? ca2i : a2i;
wire signed[34:0] da3r = USE_WORK2 ? ca3r : a3r, da3i = USE_WORK2 ? ca3i : a3i;
wire signed[34:0] db0r = USE_WORK2 ? cb0r : b0r, db0i = USE_WORK2 ? cb0i : b0i;
wire signed[34:0] db1r = USE_WORK2 ? cb1r : b1r, db1i = USE_WORK2 ? cb1i : b1i;
wire signed[34:0] db2r = USE_WORK2 ? cb2r : b2r, db2i = USE_WORK2 ? cb2i : b2i;
wire signed[34:0] db3r = USE_WORK2 ? cb3r : b3r, db3i = USE_WORK2 ? cb3i : b3i;

wire[9:0]sub_lower_exponent=(do_address*STRIDE)<<2;
wire[9:0]p_exponent;
pfft_phi_calc #(.STAGE(STAGE)) phi_group({out_count,2'd0},p_exponent);
wire[9:0]upper_exponent=PFFT_MODE?p_exponent:10'd0;
wire[9:0]lower_exponent=PFFT_MODE?10'd0:sub_lower_exponent;
wire signed[34:0]u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i;

// SubFFT: bypass lower CMUL into ECC (rotate later on read). PFFT already bypassed lower.
independent_butterfly_ecc_v5 #(
 .TRIVIAL_UPPER((PFFT_MODE!=0)&&(STAGE==1)),
 .BYPASS_LOWER(SUBFFT_ROR ? 1 : (PFFT_MODE!=0)),
 .SUBFFT_SINGLE_ROTATION(PFFT_MODE==0)
) protected_butterfly(
 da0r,da0i,da1r,da1i,da2r,da2i,da3r,da3i,db0r,db0i,db1r,db1i,db2r,db2i,db3r,db3i,
 upper_exponent,lower_exponent,u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i
);
wire signed[34:0]rot0r,rot0i,rot1r,rot1i,rot2r,rot2i,rot3r,rot3i;
generate
 if(PFFT_MODE!=0)begin:with_pfft_feedback_rotation
  independent_rotation_ecc_v5 #(
   .TRIVIAL_ROTATION(STAGE==1)
  ) protected_feedback_rotation(
   da0r,da0i,da1r,da1i,da2r,da2i,da3r,da3i,p_exponent,
   rot0r,rot0i,rot1r,rot1i,rot2r,rot2i,rot3r,rot3i
  );
 end else begin:without_subfft_feedback_rotation
  assign rot0r=0;assign rot0i=0;assign rot1r=0;assign rot1i=0;
  assign rot2r=0;assign rot2i=0;assign rot3r=0;assign rot3i=0;
 end
endgenerate

wire signed[34:0]raw_sum0r=da0r+db0r,raw_sum0i=da0i+db0i,raw_diff0r=da0r-db0r,raw_diff0i=da0i-db0i;
wire signed[34:0]raw_sum1r=da1r+db1r,raw_sum1i=da1i+db1i,raw_diff1r=da1r-db1r,raw_diff1i=da1i-db1i;
wire signed[34:0]raw_sum2r=da2r+db2r,raw_sum2i=da2i+db2i,raw_diff2r=da2r-db2r,raw_diff2i=da2i-db2i;
wire signed[34:0]raw_sum3r=da3r+db3r,raw_sum3i=da3i+db3i,raw_diff3r=da3r-db3r,raw_diff3i=da3i-db3i;
wire signed[34:0]raw_upper0r=raw_sum0r>>>1,raw_upper0i=raw_sum0i>>>1,raw_lower0r=raw_diff0r>>>1,raw_lower0i=raw_diff0i>>>1;
wire signed[34:0]raw_upper1r=raw_sum1r>>>1,raw_upper1i=raw_sum1i>>>1,raw_lower1r=raw_diff1r>>>1,raw_lower1i=raw_diff1i>>>1;
wire signed[34:0]raw_upper2r=raw_sum2r>>>1,raw_upper2i=raw_sum2i>>>1,raw_lower2r=raw_diff2r>>>1,raw_lower2i=raw_diff2i>>>1;
wire signed[34:0]raw_upper3r=raw_sum3r>>>1,raw_upper3i=raw_sum3i>>>1,raw_lower3r=raw_diff3r>>>1,raw_lower3i=raw_diff3i>>>1;
wire[9:0]lane_exp0,lane_exp1,lane_exp2,lane_exp3;
pfft_phi_calc #(.STAGE(STAGE)) phi0({out_count,2'd0},lane_exp0);
pfft_phi_calc #(.STAGE(STAGE)) phi1({out_count,2'd1},lane_exp1);
pfft_phi_calc #(.STAGE(STAGE)) phi2({out_count,2'd2},lane_exp2);
pfft_phi_calc #(.STAGE(STAGE)) phi3({out_count,2'd3},lane_exp3);
wire signed[34:0]hetero_upper0r,hetero_upper0i,hetero_upper1r,hetero_upper1i,hetero_upper2r,hetero_upper2i,hetero_upper3r,hetero_upper3i;
wire signed[34:0]hetero_feedback0r,hetero_feedback0i,hetero_feedback1r,hetero_feedback1i,hetero_feedback2r,hetero_feedback2i,hetero_feedback3r,hetero_feedback3i;
fft_complex_mul_q28 hm0u(raw_upper0r,raw_upper0i,lane_exp0,hetero_upper0r,hetero_upper0i);
fft_complex_mul_q28 hm1u(raw_upper1r,raw_upper1i,lane_exp1,hetero_upper1r,hetero_upper1i);
fft_complex_mul_q28 hm2u(raw_upper2r,raw_upper2i,lane_exp2,hetero_upper2r,hetero_upper2i);
fft_complex_mul_q28 hm3u(raw_upper3r,raw_upper3i,lane_exp3,hetero_upper3r,hetero_upper3i);
fft_complex_mul_q28 hm0f(da0r,da0i,lane_exp0,hetero_feedback0r,hetero_feedback0i);
fft_complex_mul_q28 hm1f(da1r,da1i,lane_exp1,hetero_feedback1r,hetero_feedback1i);
fft_complex_mul_q28 hm2f(da2r,da2i,lane_exp2,hetero_feedback2r,hetero_feedback2i);
fft_complex_mul_q28 hm3f(da3r,da3i,lane_exp3,hetero_feedback3r,hetero_feedback3i);

// Pre-pipe candidates (PFFT / hetero unchanged; SubFFT first-half uses raw memory).
wire signed[34:0]cand0r_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper0r:u0r):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback0r:rot0r):da0r);
wire signed[34:0]cand0i_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper0i:u0i):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback0i:rot0i):da0i);
wire signed[34:0]cand1r_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper1r:u1r):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback1r:rot1r):da1r);
wire signed[34:0]cand1i_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper1i:u1i):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback1i:rot1i):da1i);
wire signed[34:0]cand2r_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper2r:u2r):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback2r:rot2r):da2r);
wire signed[34:0]cand2i_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper2i:u2i):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback2i:rot2i):da2i);
wire signed[34:0]cand3r_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper3r:u3r):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback3r:rot3r):da3r);
wire signed[34:0]cand3i_pre=do_second?(HETEROGENEOUS_STAGE8?hetero_upper3i:u3i):(PFFT_MODE?(HETEROGENEOUS_STAGE8?hetero_feedback3i:rot3i):da3i);
wire candidate_valid=do_second||((!do_second)&&do_primed);
wire emit_raw=do_work&&candidate_valid;
wire raw_is_last=(out_count==8'd255);

// Store: SubFFT second-half stores unrotated ECC lower (l*); PFFT/hetero unchanged.
wire signed[34:0]store0r=do_second?(HETEROGENEOUS_STAGE8?raw_lower0r:l0r):db0r,store0i=do_second?(HETEROGENEOUS_STAGE8?raw_lower0i:l0i):db0i;
wire signed[34:0]store1r=do_second?(HETEROGENEOUS_STAGE8?raw_lower1r:l1r):db1r,store1i=do_second?(HETEROGENEOUS_STAGE8?raw_lower1i:l1i):db1i;
wire signed[34:0]store2r=do_second?(HETEROGENEOUS_STAGE8?raw_lower2r:l2r):db2r,store2i=do_second?(HETEROGENEOUS_STAGE8?raw_lower2i:l2i):db2i;
wire signed[34:0]store3r=do_second?(HETEROGENEOUS_STAGE8?raw_lower3r:l3r):db3r,store3i=do_second?(HETEROGENEOUS_STAGE8?raw_lower3i:l3i):db3i;
wire fwd=(!SYNC_READ)&&do_work&&work_valid&&(do_address==work_address);
assign a0r=fwd?store0r:mdata0[69:35]; assign a0i=fwd?store0i:mdata0[34:0];
assign a1r=fwd?store1r:mdata1[69:35]; assign a1i=fwd?store1i:mdata1[34:0];
assign a2r=fwd?store2r:mdata2[69:35]; assign a2i=fwd?store2i:mdata2[34:0];
assign a3r=fwd?store3r:mdata3[69:35]; assign a3i=fwd?store3i:mdata3[34:0];
wire[77:0]store_code0,store_code1,store_code2,store_code3;
secded_encode70 enc0({store0r,store0i},store_code0);secded_encode70 enc1({store1r,store1i},store_code1);
secded_encode70 enc2({store2r,store2i},store_code2);secded_encode70 enc3({store3r,store3i},store_code3);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem0(clk,in_valid,current_address,mcode0,do_work,do_address,store_code0);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem1(clk,in_valid,current_address,mcode1,do_work,do_address,store_code1);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem2(clk,in_valid,current_address,mcode2,do_work,do_address,store_code2);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem3(clk,in_valid,current_address,mcode3,do_work,do_address,store_code3);

// SubFFT rotate-on-read pipes / trivial rotate
wire signed[34:0]tr0r,tr0i,tr1r,tr1i,tr2r,tr2i,tr3r,tr3i;
wire mul_v0,mul_v1,mul_v2,mul_v3;
wire signed[34:0]mr0r,mr0i,mr1r,mr1i,mr2r,mr2i,mr3r,mr3i;
generate
 if(!SUBFFT_ROR) begin : g_no_ror
  assign tr0r=0;assign tr0i=0;assign tr1r=0;assign tr1i=0;assign tr2r=0;assign tr2i=0;assign tr3r=0;assign tr3i=0;
  assign mul_v0=0;assign mul_v1=0;assign mul_v2=0;assign mul_v3=0;
  assign mr0r=0;assign mr0i=0;assign mr1r=0;assign mr1i=0;assign mr2r=0;assign mr2i=0;assign mr3r=0;assign mr3i=0;
 end else if(TRIVIAL_ONLY) begin : g_triv
  fft_complex_rotate_trivial_1024 r0(da0r,da0i,lower_exponent,tr0r,tr0i);
  fft_complex_rotate_trivial_1024 r1(da1r,da1i,lower_exponent,tr1r,tr1i);
  fft_complex_rotate_trivial_1024 r2(da2r,da2i,lower_exponent,tr2r,tr2i);
  fft_complex_rotate_trivial_1024 r3(da3r,da3i,lower_exponent,tr3r,tr3i);
  assign mul_v0=0;assign mul_v1=0;assign mul_v2=0;assign mul_v3=0;
  assign mr0r=0;assign mr0i=0;assign mr1r=0;assign mr1i=0;assign mr2r=0;assign mr2i=0;assign mr3r=0;assign mr3i=0;
 end else begin : g_pipe
  assign tr0r=0;assign tr0i=0;assign tr1r=0;assign tr1i=0;assign tr2r=0;assign tr2i=0;assign tr3r=0;assign tr3i=0;
  wire mul_in=emit_raw && (!do_second);
  fft_complex_mul_q28_pipe p0(clk,rst,mul_in,da0r,da0i,lower_exponent,mul_v0,mr0r,mr0i);
  fft_complex_mul_q28_pipe p1(clk,rst,mul_in,da1r,da1i,lower_exponent,mul_v1,mr1r,mr1i);
  fft_complex_mul_q28_pipe p2(clk,rst,mul_in,da2r,da2i,lower_exponent,mul_v2,mr2r,mr2i);
  fft_complex_mul_q28_pipe p3(clk,rst,mul_in,da3r,da3i,lower_exponent,mul_v3,mr3r,mr3i);
 end
endgenerate

reg bv1,bv2,bv3,bl1,bl2,bl3,ml1,ml2,ml3;
reg signed[34:0]br0r,br0i,br1r,br1i,br2r,br2i,br3r,br3i;
reg signed[34:0]br0r2,br0i2,br1r2,br1i2,br2r2,br2i2,br3r2,br3i2;
reg signed[34:0]br0r3,br0i3,br1r3,br1i3,br2r3,br2i3,br3r3,br3i3;

wire signed[34:0]triv0r=do_second?u0r:tr0r,triv0i=do_second?u0i:tr0i;
wire signed[34:0]triv1r=do_second?u1r:tr1r,triv1i=do_second?u1i:tr1i;
wire signed[34:0]triv2r=do_second?u2r:tr2r,triv2i=do_second?u2i:tr2i;
wire signed[34:0]triv3r=do_second?u3r:tr3r,triv3i=do_second?u3i:tr3i;

always@(posedge clk)begin
 if(rst)begin phase<=0;primed<=0;out_count<=0;request_valid<=0;request_second<=0;request_primed<=0;request_address<=0;
  work2<=0;work2_second<=0;work2_primed<=0;work2_address<=0;
  q0r<=0;q0i<=0;q1r<=0;q1i<=0;q2r<=0;q2i<=0;q3r<=0;q3i<=0;out_valid<=0;out_last<=0;
  out0_re<=0;out0_im<=0;out1_re<=0;out1_im<=0;out2_re<=0;out2_im<=0;out3_re<=0;out3_im<=0;
  bv1<=0;bv2<=0;bv3<=0;bl1<=0;bl2<=0;bl3<=0;ml1<=0;ml2<=0;ml3<=0;
 end else begin
  request_valid<=SYNC_READ?in_valid:1'b0;
  if(SYNC_READ&&in_valid)begin request_second<=phase_second;request_primed<=primed;request_address<=current_address;
   q0r<=in0_re;q0i<=in0_im;q1r<=in1_re;q1i<=in1_im;q2r<=in2_re;q2i<=in2_im;q3r<=in3_re;q3i<=in3_im;end
  if(in_valid)begin if(phase==(2*DEPTH-1))begin phase<=0;primed<=1;end else phase<=phase+1'b1;end

  work2<=work_valid;
  if(work_valid) begin
    work2_second<=work_second; work2_primed<=work_primed; work2_address<=work_address;
    ca0r<=a0r;ca0i<=a0i;ca1r<=a1r;ca1i<=a1i;ca2r<=a2r;ca2i<=a2i;ca3r<=a3r;ca3i<=a3i;
    cb0r<=b0r;cb0i<=b0i;cb1r<=b1r;cb1i<=b1i;cb2r<=b2r;cb2i<=b2i;cb3r<=b3r;cb3i<=b3i;
  end

  if(emit_raw) out_count<=out_count+1'b1;

  if(!SUBFFT_ROR) begin
   out_valid<=0;out_last<=0;
   if(emit_raw)begin out_valid<=1;out_last<=raw_is_last;
    out0_re<=cand0r_pre;out0_im<=cand0i_pre;out1_re<=cand1r_pre;out1_im<=cand1i_pre;
    out2_re<=cand2r_pre;out2_im<=cand2i_pre;out3_re<=cand3r_pre;out3_im<=cand3i_pre;end
  end else if(!USE_PIPE) begin
   out_valid<=0;out_last<=0;
   if(emit_raw)begin out_valid<=1;out_last<=raw_is_last;
    out0_re<=triv0r;out0_im<=triv0i;out1_re<=triv1r;out1_im<=triv1i;
    out2_re<=triv2r;out2_im<=triv2i;out3_re<=triv3r;out3_im<=triv3i;end
  end else begin
   // 3-stage bypass for second-half upper; first-half via CMUL pipe
   bv1<=emit_raw && do_second;
   bl1<=emit_raw && do_second && raw_is_last;
   if(emit_raw && do_second) begin
    br0r<=u0r;br0i<=u0i;br1r<=u1r;br1i<=u1i;br2r<=u2r;br2i<=u2i;br3r<=u3r;br3i<=u3i;
   end
   bv2<=bv1;bl2<=bl1;
   br0r2<=br0r;br0i2<=br0i;br1r2<=br1r;br1i2<=br1i;br2r2<=br2r;br2i2<=br2i;br3r2<=br3r;br3i2<=br3i;
   bv3<=bv2;bl3<=bl2;
   br0r3<=br0r2;br0i3<=br0i2;br1r3<=br1r2;br1i3<=br1i2;br2r3<=br2r2;br2i3<=br2i2;br3r3<=br3r2;br3i3<=br3i2;
   ml1<=emit_raw && (!do_second) && raw_is_last;
   ml2<=ml1; ml3<=ml2;
   out_valid<=mul_v0 | bv3;
   out_last<=mul_v0 ? ml3 : bl3;
   out0_re<=mul_v0 ? mr0r : br0r3; out0_im<=mul_v0 ? mr0i : br0i3;
   out1_re<=mul_v0 ? mr1r : br1r3; out1_im<=mul_v0 ? mr1i : br1i3;
   out2_re<=mul_v0 ? mr2r : br2r3; out2_im<=mul_v0 ? mr2i : br2i3;
   out3_re<=mul_v0 ? mr3r : br3r3; out3_im<=mul_v0 ? mr3i : br3i3;
  end
 end
end
wire _keep=^mem_detected^mem_corrected^in_last^mul_v1^mul_v2^mul_v3;
endmodule
