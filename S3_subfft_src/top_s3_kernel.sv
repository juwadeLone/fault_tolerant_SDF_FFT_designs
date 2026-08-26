`timescale 1ns/1ps

// Fair-kernel S3 (paper SubFFT per-stage ECC):
//   Stage 1–8: feedback SECDED + isomorphic four-lane direct [6,4,3] (PFFT_MODE=0)
//   Stage 9–10: complete-stage TMR (separate atoms; DONT_TOUCH replicas)
// No AXI/debug wrap; no terminal frame buffer (same compare口径 as S0/S1/S2).
// Un-compensated thresholded locator/apply: raw syndrome compared against
// THRESHOLD directly; pattern match with tolerance TOL = 2*THRESHOLD.
// No residual/clean reference (physically realizable). Added 2026-08-10.
(* keep_hierarchy = "yes" *) module arithmetic_apply_from_syndrome_643_uncomp #(
    parameter integer THRESHOLD = 4
)(
 input wire signed[34:0]s0r,s0i,s1r,s1i,s2r,s2i,s3r,s3i,
 input wire signed[38:0]sy0r,sy0i,sy1r,sy1i,
 output reg signed[34:0]d0r,d0i,d1r,d1i,d2r,d2i,d3r,d3i
);
function [38:0] abs39;
 input signed [38:0] value;
 begin
  abs39 = value[38] ? (~value + 39'sd1) : value;
 end
endfunction
reg signed[38:0]er,ei;reg[2:0]loc;reg found;
reg[38:0]th,tol;
always @* begin
 d0r=s0r;d0i=s0i;d1r=s1r;d1i=s1i;d2r=s2r;d2i=s2i;d3r=s3r;d3i=s3i;loc=0;found=0;er=0;ei=0;
 th = THRESHOLD;
 tol = THRESHOLD + THRESHOLD;
 if((abs39(sy0r)>th)||(abs39(sy0i)>th)||(abs39(sy1r)>th)||(abs39(sy1i)>th)) begin
  if((abs39(sy1r-sy0r)<=tol)&&(abs39(sy1i-sy0i)<=tol)) begin loc=0;found=1;end
  else if((abs39(sy1r+sy0i)<=tol)&&(abs39(sy1i-sy0r)<=tol)) begin loc=1;found=1;end
  else if((abs39(sy1r+sy0r)<=tol)&&(abs39(sy1i+sy0i)<=tol)) begin loc=2;found=1;end
  else if((abs39(sy1r-sy0i)<=tol)&&(abs39(sy1i+sy0r)<=tol)) begin loc=3;found=1;end
  else if((abs39(sy1r)<=th)&&(abs39(sy1i)<=th)) begin loc=4;found=1;end
  else if((abs39(sy0r)<=th)&&(abs39(sy0i)<=th)) begin loc=5;found=1;end
  if(found) begin
   if(loc<4)begin er=-sy0r;ei=-sy0i;end
   case(loc)
    0:begin d0r=s0r-er[34:0];d0i=s0i-ei[34:0];end
    1:begin d1r=s1r-er[34:0];d1i=s1i-ei[34:0];end
    2:begin d2r=s2r-er[34:0];d2i=s2i-ei[34:0];end
    3:begin d3r=s3r-er[34:0];d3i=s3i-ei[34:0];end
    default:begin end
   endcase
  end
 end
end
endmodule


// S3-only per-stage ECC with P1-style bnd -> res -> syn -> apply pipeline.
// Write-back stores the raw lower butterfly result; SECDED protects memory,
// and arithmetic correction is applied on the forwarded/read path.
(* keep_hierarchy = "yes" *) module s3_ecc_stage4_v6 #(
 parameter integer DEPTH=128,
 parameter integer STAGE=1
)(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output reg out_valid,output reg out_last,
 output reg signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
localparam integer PHASE_W=(2*DEPTH<=2)?1:$clog2(2*DEPTH);
localparam integer ADDR_W=(DEPTH<=1)?1:$clog2(DEPTH);
localparam integer STRIDE=256/(2*DEPTH);
localparam integer SYNC_READ=(DEPTH==128);
localparam integer TRIVIAL_ONLY=(DEPTH<=2);
localparam integer USE_WORK2=1;

reg[PHASE_W-1:0]phase;
reg primed;
reg[7:0]out_count;
wire phase_second=(phase>=DEPTH);
wire[ADDR_W-1:0]current_address=phase_second?phase-DEPTH:phase;

reg request_valid,request_second,request_primed;
reg[ADDR_W-1:0]request_address;
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
wire[69:0]mdata0,mdata1,mdata2,mdata3;
wire[3:0]mem_detected,mem_corrected;
secded_decode70 dec0(mcode0,mdata0,mem_detected[0],mem_corrected[0]);
secded_decode70 dec1(mcode1,mdata1,mem_detected[1],mem_corrected[1]);
secded_decode70 dec2(mcode2,mdata2,mem_detected[2],mem_corrected[2]);
secded_decode70 dec3(mcode3,mdata3,mem_detected[3],mem_corrected[3]);

wire signed[34:0]store0r,store0i,store1r,store1i,store2r,store2i,store3r,store3i;
wire signed[34:0]a0r,a0i,a1r,a1i,a2r,a2i,a3r,a3i;

reg work2,work2_second,work2_primed;
reg[ADDR_W-1:0]work2_address;
reg signed[34:0]ca0r,ca0i,ca1r,ca1i,ca2r,ca2i,ca3r,ca3i;
reg signed[34:0]cb0r,cb0i,cb1r,cb1i,cb2r,cb2i,cb3r,cb3i;

wire do_work=USE_WORK2?work2:work_valid;
wire do_second=USE_WORK2?work2_second:work_second;
wire do_primed=USE_WORK2?work2_primed:work_primed;
wire[ADDR_W-1:0]do_address=USE_WORK2?work2_address:work_address;
wire signed[34:0]da0r=USE_WORK2?ca0r:a0r,da0i=USE_WORK2?ca0i:a0i;
wire signed[34:0]da1r=USE_WORK2?ca1r:a1r,da1i=USE_WORK2?ca1i:a1i;
wire signed[34:0]da2r=USE_WORK2?ca2r:a2r,da2i=USE_WORK2?ca2i:a2i;
wire signed[34:0]da3r=USE_WORK2?ca3r:a3r,da3i=USE_WORK2?ca3i:a3i;
wire signed[34:0]db0r=USE_WORK2?cb0r:b0r,db0i=USE_WORK2?cb0i:b0i;
wire signed[34:0]db1r=USE_WORK2?cb1r:b1r,db1i=USE_WORK2?cb1i:b1i;
wire signed[34:0]db2r=USE_WORK2?cb2r:b2r,db2i=USE_WORK2?cb2i:b2i;
wire signed[34:0]db3r=USE_WORK2?cb3r:b3r,db3i=USE_WORK2?cb3i:b3i;

wire signed[34:0]ar[0:5],ai[0:5],br[0:5],bi[0:5];
assign ar[0]=da0r;assign ai[0]=da0i;
assign ar[1]=da1r;assign ai[1]=da1i;
assign ar[2]=da2r;assign ai[2]=da2i;
assign ar[3]=da3r;assign ai[3]=da3i;
assign br[0]=db0r;assign bi[0]=db0i;
assign br[1]=db1r;assign bi[1]=db1i;
assign br[2]=db2r;assign bi[2]=db2i;
assign br[3]=db3r;assign bi[3]=db3i;
wire signed[34:0]a01r=ar[0]+ar[1],a01i=ai[0]+ai[1];
wire signed[34:0]a23r=ar[2]+ar[3],a23i=ai[2]+ai[3];
wire signed[34:0]b01r=br[0]+br[1],b01i=bi[0]+bi[1];
wire signed[34:0]b23r=br[2]+br[3],b23i=bi[2]+bi[3];
assign ar[4]=a01r+a23r;assign ai[4]=a01i+a23i;
assign br[4]=b01r+b23r;assign bi[4]=b01i+b23i;
assign ar[5]=(ar[0]-ai[1])+(-ar[2]+ai[3]);
assign ai[5]=(ai[0]+ar[1])+(-ai[2]-ar[3]);
assign br[5]=(br[0]-bi[1])+(-br[2]+bi[3]);
assign bi[5]=(bi[0]+br[1])+(-bi[2]-br[3]);

wire signed[34:0]upper_r[0:5],upper_i[0:5],lower_r[0:5],lower_i[0:5];
wire signed[34:0]selected_r[0:5],selected_i[0:5];
wire[9:0]lower_exponent=(do_address*STRIDE)<<2;
wire[9:0]group_exponent=do_second?10'd0:lower_exponent;

wire candidate_valid=do_second||((!do_second)&&do_primed);
wire emit_raw=do_work&&candidate_valid;
wire raw_is_last=(out_count==8'd255);

genvar g;
generate for(g=0;g<6;g=g+1)begin:complete_butterflies
 wire signed[34:0]sumr=ar[g]+br[g],sumi=ai[g]+bi[g];
 wire signed[34:0]diffr=ar[g]-br[g],diffi=ai[g]-bi[g];
 assign upper_r[g]=sumr>>>1;assign upper_i[g]=sumi>>>1;
 assign lower_r[g]=diffr>>>1;assign lower_i[g]=diffi>>>1;
 assign selected_r[g]=do_second?upper_r[g]:ar[g];
 assign selected_i[g]=do_second?upper_i[g]:ai[g];
end endgenerate

wire mul_valid_bus[0:5];
wire signed[34:0]mul_r[0:5],mul_i[0:5];
wire signed[34:0]triv_r[0:5],triv_i[0:5];
generate for(g=0;g<6;g=g+1)begin:rotators
 if(TRIVIAL_ONLY)begin:triv_rot
  fft_complex_rotate_trivial_1024 rotate(
   selected_r[g],selected_i[g],group_exponent,triv_r[g],triv_i[g]);
  reg v1,v2,v3;
  reg signed[34:0]r1,i1,r2,i2,r3,i3;
  always@(posedge clk)begin
   if(rst)begin v1<=0;v2<=0;v3<=0; end
   else begin
    v1<=emit_raw;
    if(emit_raw)begin r1<=triv_r[g];i1<=triv_i[g]; end
    v2<=v1;r2<=r1;i2<=i1;
    v3<=v2;r3<=r2;i3<=i2;
   end
  end
  assign mul_valid_bus[g]=v3;
  assign mul_r[g]=r3; assign mul_i[g]=i3;
 end else begin:pipe_rot
  assign triv_r[g]=35'sd0; assign triv_i[g]=35'sd0;
  fft_complex_mul_q28_pipe rotate(
   .clk(clk),.rst(rst),.valid_in(emit_raw),
   .in_re(selected_r[g]),.in_im(selected_i[g]),.exponent(group_exponent),
   .valid_out(mul_valid_bus[g]),.out_re(mul_r[g]),.out_im(mul_i[g]));
 end
end endgenerate

wire mul_valid_out=mul_valid_bus[0];

reg bnd_v,bnd_last,res_v,res_last,syn_v,syn_last;
reg signed[34:0]bnd_r[0:5],bnd_i[0:5];
reg signed[34:0]hold_r[0:5],hold_i[0:5];
reg signed[34:0]app_r[0:3],app_i[0:3];
reg signed[38:0]sy0r,sy0i,sy1r,sy1i;

wire signed[38:0]raw0r_w=$signed(hold_r[4])-($signed(hold_r[0])+$signed(hold_r[1])+$signed(hold_r[2])+$signed(hold_r[3]));
wire signed[38:0]raw0i_w=$signed(hold_i[4])-($signed(hold_i[0])+$signed(hold_i[1])+$signed(hold_i[2])+$signed(hold_i[3]));
wire signed[38:0]raw1r_w=$signed(hold_r[5])-($signed(hold_r[0])-$signed(hold_i[1])-$signed(hold_r[2])+$signed(hold_i[3]));
wire signed[38:0]raw1i_w=$signed(hold_i[5])-($signed(hold_i[0])+$signed(hold_r[1])-$signed(hold_i[2])-$signed(hold_r[3]));
wire signed[38:0]sy0r_w=raw0r_w,sy0i_w=raw0i_w;  // un-compensated: raw syndrome direct
wire signed[38:0]sy1r_w=raw1r_w,sy1i_w=raw1i_w;

wire signed[34:0]decoded0r,decoded0i,decoded1r,decoded1i;
wire signed[34:0]decoded2r,decoded2i,decoded3r,decoded3i;
(* keep = "true" *) arithmetic_apply_from_syndrome_643_uncomp #(.THRESHOLD(4)) u_apply(
 app_r[0],app_i[0],app_r[1],app_i[1],app_r[2],app_i[2],app_r[3],app_i[3],
 sy0r,sy0i,sy1r,sy1i,
 decoded0r,decoded0i,decoded1r,decoded1i,
 decoded2r,decoded2i,decoded3r,decoded3i
);

assign store0r=do_second?lower_r[0]:db0r;
assign store0i=do_second?lower_i[0]:db0i;
assign store1r=do_second?lower_r[1]:db1r;
assign store1i=do_second?lower_i[1]:db1i;
assign store2r=do_second?lower_r[2]:db2r;
assign store2i=do_second?lower_i[2]:db2i;
assign store3r=do_second?lower_r[3]:db3r;
assign store3i=do_second?lower_i[3]:db3i;
wire fwd=(!SYNC_READ)&&do_work&&work_valid&&(do_address==work_address);
assign a0r=fwd?store0r:mdata0[69:35]; assign a0i=fwd?store0i:mdata0[34:0];
assign a1r=fwd?store1r:mdata1[69:35]; assign a1i=fwd?store1i:mdata1[34:0];
assign a2r=fwd?store2r:mdata2[69:35]; assign a2i=fwd?store2i:mdata2[34:0];
assign a3r=fwd?store3r:mdata3[69:35]; assign a3i=fwd?store3i:mdata3[34:0];
wire[77:0]store_code0,store_code1,store_code2,store_code3;
secded_encode70 enc0({store0r,store0i},store_code0);
secded_encode70 enc1({store1r,store1i},store_code1);
secded_encode70 enc2({store2r,store2i},store_code2);
secded_encode70 enc3({store3r,store3i},store_code3);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem0(
 clk,in_valid,current_address,mcode0,do_work,do_address,store_code0);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem1(
 clk,in_valid,current_address,mcode1,do_work,do_address,store_code1);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem2(
 clk,in_valid,current_address,mcode2,do_work,do_address,store_code2);
fft_memory_v5 #(.WIDTH(78),.DEPTH(DEPTH),.ADDR_W(ADDR_W))mem3(
 clk,in_valid,current_address,mcode3,do_work,do_address,store_code3);

reg ml1,ml2,ml3,ml4;
always@(posedge clk)begin
 if(rst)begin
  phase<=0;primed<=0;out_count<=0;
  request_valid<=0;request_second<=0;request_primed<=0;request_address<=0;
  work2<=0;work2_second<=0;work2_primed<=0;work2_address<=0;
  q0r<=0;q0i<=0;q1r<=0;q1i<=0;q2r<=0;q2i<=0;q3r<=0;q3i<=0;
  out_valid<=0;out_last<=0;
  out0_re<=0;out0_im<=0;out1_re<=0;out1_im<=0;
  out2_re<=0;out2_im<=0;out3_re<=0;out3_im<=0;
  ml1<=0;ml2<=0;ml3<=0;ml4<=0;bnd_v<=0;bnd_last<=0;res_v<=0;res_last<=0;syn_v<=0;syn_last<=0;
  sy0r<=0;sy0i<=0;sy1r<=0;sy1i<=0;
 end else begin
  request_valid<=SYNC_READ?in_valid:1'b0;
  if(SYNC_READ&&in_valid)begin
   request_second<=phase_second;request_primed<=primed;
   request_address<=current_address;
   q0r<=in0_re;q0i<=in0_im;q1r<=in1_re;q1i<=in1_im;
   q2r<=in2_re;q2i<=in2_im;q3r<=in3_re;q3i<=in3_im;
  end
  if(in_valid)begin
   if(phase==(2*DEPTH-1))begin phase<=0;primed<=1;end
   else phase<=phase+1'b1;
  end
  work2<=work_valid;
  if(work_valid)begin
   work2_second<=work_second;work2_primed<=work_primed;work2_address<=work_address;
   ca0r<=a0r;ca0i<=a0i;ca1r<=a1r;ca1i<=a1i;ca2r<=a2r;ca2i<=a2i;ca3r<=a3r;ca3i<=a3i;
   cb0r<=b0r;cb0i<=b0i;cb1r<=b1r;cb1i<=b1i;cb2r<=b2r;cb2i<=b2i;cb3r<=b3r;cb3i<=b3i;
  end
  if(emit_raw) out_count<=out_count+1'b1;

  ml1<=emit_raw&&raw_is_last; ml2<=ml1; ml3<=ml2; ml4<=ml3;
  bnd_v<=mul_valid_out;
  bnd_last<=mul_valid_out?ml3:1'b0;
  if(mul_valid_out)begin
   bnd_r[0]<=mul_r[0];bnd_i[0]<=mul_i[0];
   bnd_r[1]<=mul_r[1];bnd_i[1]<=mul_i[1];
   bnd_r[2]<=mul_r[2];bnd_i[2]<=mul_i[2];
   bnd_r[3]<=mul_r[3];bnd_i[3]<=mul_i[3];
   bnd_r[4]<=mul_r[4];bnd_i[4]<=mul_i[4];
   bnd_r[5]<=mul_r[5];bnd_i[5]<=mul_i[5];
  end
  res_v<=bnd_v;
  res_last<=bnd_last;
  if(bnd_v)begin
   hold_r[0]<=bnd_r[0];hold_i[0]<=bnd_i[0];
   hold_r[1]<=bnd_r[1];hold_i[1]<=bnd_i[1];
   hold_r[2]<=bnd_r[2];hold_i[2]<=bnd_i[2];
   hold_r[3]<=bnd_r[3];hold_i[3]<=bnd_i[3];
   hold_r[4]<=bnd_r[4];hold_i[4]<=bnd_i[4];
   hold_r[5]<=bnd_r[5];hold_i[5]<=bnd_i[5];

  end
  syn_v<=res_v;
  syn_last<=res_last;
  if(res_v)begin
   sy0r<=sy0r_w;sy0i<=sy0i_w;sy1r<=sy1r_w;sy1i<=sy1i_w;
   app_r[0]<=hold_r[0];app_i[0]<=hold_i[0];
   app_r[1]<=hold_r[1];app_i[1]<=hold_i[1];
   app_r[2]<=hold_r[2];app_i[2]<=hold_i[2];
   app_r[3]<=hold_r[3];app_i[3]<=hold_i[3];
  end
  out_valid<=syn_v;
  out_last<=syn_v?syn_last:1'b0;
  if(syn_v)begin
   out0_re<=decoded0r;out0_im<=decoded0i;
   out1_re<=decoded1r;out1_im<=decoded1i;
   out2_re<=decoded2r;out2_im<=decoded2i;
   out3_re<=decoded3r;out3_im<=decoded3i;
  end
 end
end
wire _keep=^mem_detected^mem_corrected^in_last;
endmodule


(* keep_hierarchy = "yes" *)
module s3_subfft_ecc_core_v5 (
    input  wire clk, input wire rst, input wire in_valid, input wire in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
    output wire out_valid, output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im
);
    wire [10:0] v, l;
    wire signed [34:0] r0[0:10], i0[0:10], r1[0:10], i1[0:10], r2[0:10], i2[0:10], r3[0:10], i3[0:10];
    assign v[0] = in_valid; assign l[0] = in_last;
    assign r0[0] = in0_re; assign i0[0] = in0_im;
    assign r1[0] = in1_re; assign i1[0] = in1_im;
    assign r2[0] = in2_re; assign i2[0] = in2_im;
    assign r3[0] = in3_re; assign i3[0] = in3_im;

    s3_ecc_stage4_v6 #(.DEPTH(128), .STAGE(1)) s1(clk, rst, v[0], l[0], r0[0], i0[0], r1[0], i1[0], r2[0], i2[0], r3[0], i3[0], v[1], l[1], r0[1], i0[1], r1[1], i1[1], r2[1], i2[1], r3[1], i3[1]);
    s3_ecc_stage4_v6 #(.DEPTH(64),  .STAGE(2)) s2(clk, rst, v[1], l[1], r0[1], i0[1], r1[1], i1[1], r2[1], i2[1], r3[1], i3[1], v[2], l[2], r0[2], i0[2], r1[2], i1[2], r2[2], i2[2], r3[2], i3[2]);
    s3_ecc_stage4_v6 #(.DEPTH(32),  .STAGE(3)) s3(clk, rst, v[2], l[2], r0[2], i0[2], r1[2], i1[2], r2[2], i2[2], r3[2], i3[2], v[3], l[3], r0[3], i0[3], r1[3], i1[3], r2[3], i2[3], r3[3], i3[3]);
    s3_ecc_stage4_v6 #(.DEPTH(16),  .STAGE(4)) s4(clk, rst, v[3], l[3], r0[3], i0[3], r1[3], i1[3], r2[3], i2[3], r3[3], i3[3], v[4], l[4], r0[4], i0[4], r1[4], i1[4], r2[4], i2[4], r3[4], i3[4]);
    s3_ecc_stage4_v6 #(.DEPTH(8),   .STAGE(5)) s5(clk, rst, v[4], l[4], r0[4], i0[4], r1[4], i1[4], r2[4], i2[4], r3[4], i3[4], v[5], l[5], r0[5], i0[5], r1[5], i1[5], r2[5], i2[5], r3[5], i3[5]);
    s3_ecc_stage4_v6 #(.DEPTH(4),   .STAGE(6)) s6(clk, rst, v[5], l[5], r0[5], i0[5], r1[5], i1[5], r2[5], i2[5], r3[5], i3[5], v[6], l[6], r0[6], i0[6], r1[6], i1[6], r2[6], i2[6], r3[6], i3[6]);
    s3_ecc_stage4_v6 #(.DEPTH(2),   .STAGE(7)) s7(clk, rst, v[6], l[6], r0[6], i0[6], r1[6], i1[6], r2[6], i2[6], r3[6], i3[6], v[7], l[7], r0[7], i0[7], r1[7], i1[7], r2[7], i2[7], r3[7], i3[7]);
    s3_ecc_stage4_v6 #(.DEPTH(1),   .STAGE(8)) s8(clk, rst, v[7], l[7], r0[7], i0[7], r1[7], i1[7], r2[7], i2[7], r3[7], i3[7], v[8], l[8], r0[8], i0[8], r1[8], i1[8], r2[8], i2[8], r3[8], i3[8]);
    tmr_subfft_stage9_v5  s9 (clk, rst, v[8], l[8], r0[8], i0[8], r1[8], i1[8], r2[8], i2[8], r3[8], i3[8], v[9], l[9], r0[9], i0[9], r1[9], i1[9], r2[9], i2[9], r3[9], i3[9]);
    tmr_subfft_stage10_v5 s10(clk, rst, v[9], l[9], r0[9], i0[9], r1[9], i1[9], r2[9], i2[9], r3[9], i3[9], v[10], l[10], r0[10], i0[10], r1[10], i1[10], r2[10], i2[10], r3[10], i3[10]);

    assign out_valid = v[10]; assign out_last = l[10];
    assign out0_re = r0[10]; assign out0_im = i0[10];
    assign out1_re = r1[10]; assign out1_im = i1[10];
    assign out2_re = r2[10]; assign out2_im = i2[10];
    assign out3_re = r3[10]; assign out3_im = i3[10];
endmodule


module top_s3_subfft_ecc (
    input  wire clk, input wire rst, input wire in_valid, input wire in_last,
    input  wire signed [34:0] in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
    output wire out_valid, output wire out_last,
    output wire signed [34:0] out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im
);
    s3_subfft_ecc_core_v5 u (
        clk, rst, in_valid, in_last,
        in0_re, in0_im, in1_re, in1_im, in2_re, in2_im, in3_re, in3_im,
        out_valid, out_last,
        out0_re, out0_im, out1_re, out1_im, out2_re, out2_im, out3_re, out3_im
    );
endmodule
