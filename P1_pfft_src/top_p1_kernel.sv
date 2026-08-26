`timescale 1ns/1ps

// PFFT-RES-V3-001 P1 RTL.
// Attempt11: work2 decode cut + all-stage rotate/boundary pipe (Pulse_compress style).
// Attempt14: ECC stages residual|corrector split (same cut as s10 Attempt13).
// Attempt15: syndrome|apply split after residual (s1–s7 and s10).
// Attempt16: Stage-10 uncomp locate|correct split for 125 MHz OOC.

// Locator/apply half of arithmetic_corrector_643 (syndromes pre-registered).
module arithmetic_apply_from_syndrome_643_uncomp #(
    parameter integer THRESHOLD = 8
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

// Attempt16: split uncomp Stage-10 apply into locate | correct (timing).
(* keep_hierarchy = "yes" *) module complete_butterfly_locate_from_syndrome_643_uncomp #(
    parameter integer THRESHOLD = 8
)(
 input wire signed[38:0]
  sy0_ur,sy0_ui,sy1_ur,sy1_ui,
  sy0_lr,sy0_li,sy1_lr,sy1_li,
 output reg found,
 output reg[2:0] loc,
 output reg signed[38:0] eru,eiu,erl,eil
);
function [38:0] abs39;
 input signed [38:0] value;
 begin
  abs39 = value[38] ? (~value + 39'sd1) : value;
 end
endfunction
reg[38:0]th,tol;
always @* begin
 loc=0;found=0;eru=0;eiu=0;erl=0;eil=0;
 th = THRESHOLD;
 tol = THRESHOLD + THRESHOLD;
 if((abs39(sy0_ur)>th)||(abs39(sy0_ui)>th)||(abs39(sy1_ur)>th)||(abs39(sy1_ui)>th)||
    (abs39(sy0_lr)>th)||(abs39(sy0_li)>th)||(abs39(sy1_lr)>th)||(abs39(sy1_li)>th)) begin
  if((abs39(sy1_ur-sy0_ur)<=tol)&&(abs39(sy1_ui-sy0_ui)<=tol)&&(abs39(sy1_lr-sy0_lr)<=tol)&&(abs39(sy1_li-sy0_li)<=tol)) begin loc=0;found=1;end
  else if((abs39(sy1_ur+sy0_ui)<=tol)&&(abs39(sy1_ui-sy0_ur)<=tol)&&(abs39(sy1_lr+sy0_li)<=tol)&&(abs39(sy1_li-sy0_lr)<=tol)) begin loc=1;found=1;end
  else if((abs39(sy1_ur+sy0_ur)<=tol)&&(abs39(sy1_ui+sy0_ui)<=tol)&&(abs39(sy1_lr+sy0_lr)<=tol)&&(abs39(sy1_li+sy0_li)<=tol)) begin loc=2;found=1;end
  else if((abs39(sy1_ur-sy0_ui)<=tol)&&(abs39(sy1_ui+sy0_ur)<=tol)&&(abs39(sy1_lr-sy0_li)<=tol)&&(abs39(sy1_li+sy0_lr)<=tol)) begin loc=3;found=1;end
  else if((abs39(sy1_ur)<=th)&&(abs39(sy1_ui)<=th)&&(abs39(sy1_lr)<=th)&&(abs39(sy1_li)<=th)) begin loc=4;found=1;end
  else if((abs39(sy0_ur)<=th)&&(abs39(sy0_ui)<=th)&&(abs39(sy0_lr)<=th)&&(abs39(sy0_li)<=th)) begin loc=5;found=1;end
  if(found) begin
   if(loc<4) begin
    eru=-sy0_ur;eiu=-sy0_ui;erl=-sy0_lr;eil=-sy0_li;
   end else if(loc==4) begin
    eru=sy0_ur;eiu=sy0_ui;erl=sy0_lr;eil=sy0_li;
   end else begin
    eru=sy1_ur;eiu=sy1_ui;erl=sy1_lr;eil=sy1_li;
   end
  end
 end
end
endmodule

(* keep_hierarchy = "yes" *) module complete_butterfly_correct_from_location_643(
 input wire found,
 input wire[2:0] loc,
 input wire signed[38:0] eru,eiu,erl,eil,
 input wire signed[34:0]
  u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,
  l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i,
 output reg signed[34:0]
  du0r,du0i,du1r,du1i,du2r,du2i,du3r,du3i,
  dl0r,dl0i,dl1r,dl1i,dl2r,dl2i,dl3r,dl3i
);
always @* begin
 du0r=u0r;du0i=u0i;du1r=u1r;du1i=u1i;du2r=u2r;du2i=u2i;du3r=u3r;du3i=u3i;
 dl0r=l0r;dl0i=l0i;dl1r=l1r;dl1i=l1i;dl2r=l2r;dl2i=l2i;dl3r=l3r;dl3i=l3i;
 if(found) begin
  case(loc)
   0:begin
    du0r=u0r-eru[34:0];du0i=u0i-eiu[34:0];
    dl0r=l0r-erl[34:0];dl0i=l0i-eil[34:0];
   end
   1:begin
    du1r=u1r-eru[34:0];du1i=u1i-eiu[34:0];
    dl1r=l1r-erl[34:0];dl1i=l1i-eil[34:0];
   end
   2:begin
    du2r=u2r-eru[34:0];du2i=u2i-eiu[34:0];
    dl2r=l2r-erl[34:0];dl2i=l2i-eil[34:0];
   end
   3:begin
    du3r=u3r-eru[34:0];du3i=u3i-eiu[34:0];
    dl3r=l3r-erl[34:0];dl3i=l3i-eil[34:0];
   end
   default:begin end
  endcase
 end
end
endmodule

// Monolithic wrapper retained for any non-pipelined call sites.
(* keep_hierarchy = "yes" *) module complete_butterfly_apply_from_syndrome_643_uncomp #(
    parameter integer THRESHOLD = 8
)(
 input wire signed[34:0]
  u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,
  l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i,
 input wire signed[38:0]
  sy0_ur,sy0_ui,sy1_ur,sy1_ui,
  sy0_lr,sy0_li,sy1_lr,sy1_li,
 output wire signed[34:0]
  du0r,du0i,du1r,du1i,du2r,du2i,du3r,du3i,
  dl0r,dl0i,dl1r,dl1i,dl2r,dl2i,dl3r,dl3i
);
wire found; wire[2:0] loc;
wire signed[38:0] eru,eiu,erl,eil;
complete_butterfly_locate_from_syndrome_643_uncomp #(.THRESHOLD(THRESHOLD)) u_loc(
 sy0_ur,sy0_ui,sy1_ur,sy1_ui,sy0_lr,sy0_li,sy1_lr,sy1_li,
 found,loc,eru,eiu,erl,eil
);
complete_butterfly_correct_from_location_643 u_cor(
 found,loc,eru,eiu,erl,eil,
 u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,
 l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i,
 du0r,du0i,du1r,du1i,du2r,du2i,du3r,du3i,
 dl0r,dl0i,dl1r,dl1i,dl2r,dl2i,dl3r,dl3i
);
endmodule


// Locator/apply half of complete_butterfly_corrector_643.
(* keep_hierarchy = "yes" *) module complete_butterfly_apply_from_syndrome_643(
 input wire signed[34:0]
  u0r,u0i,u1r,u1i,u2r,u2i,u3r,u3i,
  l0r,l0i,l1r,l1i,l2r,l2i,l3r,l3i,
 input wire signed[38:0]
  sy0_ur,sy0_ui,sy1_ur,sy1_ui,
  sy0_lr,sy0_li,sy1_lr,sy1_li,
 output reg signed[34:0]
  du0r,du0i,du1r,du1i,du2r,du2i,du3r,du3i,
  dl0r,dl0i,dl1r,dl1i,dl2r,dl2i,dl3r,dl3i
);
reg signed[38:0]eru,eiu,erl,eil;reg[2:0]loc;reg found;
reg match0,match1,match2,match3,match4,match5;
always @* begin
 du0r=u0r;du0i=u0i;du1r=u1r;du1i=u1i;du2r=u2r;du2i=u2i;du3r=u3r;du3i=u3i;
 dl0r=l0r;dl0i=l0i;dl1r=l1r;dl1i=l1i;dl2r=l2r;dl2i=l2i;dl3r=l3r;dl3i=l3i;
 loc=0;found=0;eru=0;eiu=0;erl=0;eil=0;
 match0=(sy1_ur==sy0_ur)&&(sy1_ui==sy0_ui)&&(sy1_lr==sy0_lr)&&(sy1_li==sy0_li);
 match1=(sy1_ur==-sy0_ui)&&(sy1_ui==sy0_ur)&&(sy1_lr==-sy0_li)&&(sy1_li==sy0_lr);
 match2=(sy1_ur==-sy0_ur)&&(sy1_ui==-sy0_ui)&&(sy1_lr==-sy0_lr)&&(sy1_li==-sy0_li);
 match3=(sy1_ur==sy0_ui)&&(sy1_ui==-sy0_ur)&&(sy1_lr==sy0_li)&&(sy1_li==-sy0_lr);
 match4=(sy1_ur==0)&&(sy1_ui==0)&&(sy1_lr==0)&&(sy1_li==0);
 match5=(sy0_ur==0)&&(sy0_ui==0)&&(sy0_lr==0)&&(sy0_li==0);
 if((sy0_ur!=0)||(sy0_ui!=0)||(sy1_ur!=0)||(sy1_ui!=0)||
    (sy0_lr!=0)||(sy0_li!=0)||(sy1_lr!=0)||(sy1_li!=0)) begin
  if(match0) begin loc=0;found=1;end
  else if(match1) begin loc=1;found=1;end
  else if(match2) begin loc=2;found=1;end
  else if(match3) begin loc=3;found=1;end
  else if(match4) begin loc=4;found=1;end
  else if(match5) begin loc=5;found=1;end
  if(found) begin
   if(loc<4) begin
    eru=-sy0_ur;eiu=-sy0_ui;erl=-sy0_lr;eil=-sy0_li;
   end else if(loc==4) begin
    eru=sy0_ur;eiu=sy0_ui;erl=sy0_lr;eil=sy0_li;
   end else begin
    eru=sy1_ur;eiu=sy1_ui;erl=sy1_lr;eil=sy1_li;
   end
   case(loc)
    0:begin
     du0r=u0r-eru[34:0];du0i=u0i-eiu[34:0];
     dl0r=l0r-erl[34:0];dl0i=l0i-eil[34:0];
    end
    1:begin
     du1r=u1r-eru[34:0];du1i=u1i-eiu[34:0];
     dl1r=l1r-erl[34:0];dl1i=l1i-eil[34:0];
    end
    2:begin
     du2r=u2r-eru[34:0];du2i=u2i-eiu[34:0];
     dl2r=l2r-erl[34:0];dl2i=l2i-eil[34:0];
    end
    3:begin
     du3r=u3r-eru[34:0];du3i=u3i-eiu[34:0];
     dl3r=l3r-erl[34:0];dl3i=l3i-eil[34:0];
    end
    default:begin end
   endcase
  end
 end
end
endmodule

(* keep_hierarchy = "yes" *) module p1_ecc_stage4_v3 #(
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
localparam integer SYNC_READ=(DEPTH==128);
localparam integer TRIVIAL_ONLY=(STAGE==1);
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

// Store values declared early for async forward into decode.
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
wire[9:0]group_exponent;
pfft_phi_calc #(.STAGE(STAGE)) phi_group({out_count,2'd0},group_exponent);

wire candidate_valid=do_second||((!do_second)&&do_primed);
wire emit_raw=do_work&&candidate_valid;
wire raw_is_last=(out_count==8'd255);

wire mul_valid_bus[0:5];
wire signed[34:0]mul_r[0:5],mul_i[0:5];
wire signed[34:0]triv_r[0:5],triv_i[0:5];

genvar g;
generate for(g=0;g<6;g=g+1)begin:complete_butterflies
 wire signed[34:0]sumr=ar[g]+br[g],sumi=ai[g]+bi[g];
 wire signed[34:0]diffr=ar[g]-br[g],diffi=ai[g]-bi[g];
 assign upper_r[g]=sumr>>>1;assign upper_i[g]=sumi>>>1;
 assign lower_r[g]=diffr>>>1;assign lower_i[g]=diffi>>>1;
 assign selected_r[g]=do_second?upper_r[g]:ar[g];
 assign selected_i[g]=do_second?upper_i[g]:ai[g];
 if(TRIVIAL_ONLY)begin:triv_rot
  fft_complex_rotate_trivial_1024 rotate(
   selected_r[g],selected_i[g],group_exponent,triv_r[g],triv_i[g]);
  // 3-cycle delay matching CMUL pipe
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

// Attempt15: mul → bnd → res(+hold) → syn → apply → out.
reg bnd_v,bnd_last,res_v,res_last,syn_v,syn_last;
reg signed[34:0]bnd_r[0:5],bnd_i[0:5];
reg signed[34:0]hold_r[0:5],hold_i[0:5];
reg signed[34:0]app_r[0:3],app_i[0:3];
reg signed[38:0]sy0r,sy0i,sy1r,sy1i;

wire signed[38:0]raw0r_w=$signed(hold_r[4])-($signed(hold_r[0])+$signed(hold_r[1])+$signed(hold_r[2])+$signed(hold_r[3]));
wire signed[38:0]raw0i_w=$signed(hold_i[4])-($signed(hold_i[0])+$signed(hold_i[1])+$signed(hold_i[2])+$signed(hold_i[3]));
wire signed[38:0]raw1r_w=$signed(hold_r[5])-($signed(hold_r[0])-$signed(hold_i[1])-$signed(hold_r[2])+$signed(hold_i[3]));
wire signed[38:0]raw1i_w=$signed(hold_i[5])-($signed(hold_i[0])+$signed(hold_r[1])-$signed(hold_i[2])-$signed(hold_r[3]));
wire signed[38:0]sy0r_w=raw0r_w,sy0i_w=raw0i_w;  // un-compensated raw syndrome
wire signed[38:0]sy1r_w=raw1r_w,sy1i_w=raw1i_w;

wire signed[34:0]decoded0r,decoded0i,decoded1r,decoded1i;
wire signed[34:0]decoded2r,decoded2i,decoded3r,decoded3i;
(* keep = "true" *) arithmetic_apply_from_syndrome_643_uncomp #(.THRESHOLD(8)) u_apply(
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
  // res: snapshot symbols + residuals.
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
  // syn: register syndromes + functional symbols for apply.
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

(* keep_hierarchy = "yes" *) module p1_stage8_functional_v3(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output reg out_valid,output reg out_last,
 output reg signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im,
 output reg signed[34:0]op_a0_re,op_a0_im,op_a1_re,op_a1_im,op_a2_re,op_a2_im,op_a3_re,op_a3_im,
 output reg signed[34:0]op_b0_re,op_b0_im,op_b1_re,op_b1_im,op_b2_re,op_b2_im,op_b3_re,op_b3_im,
 output reg[9:0]op_exp0,op_exp1,op_exp2,op_exp3,
 output reg op_branch_upper
);
reg phase,primed;
reg[7:0]out_count;
wire[77:0]mcode0,mcode1,mcode2,mcode3;
wire[69:0]mdata0,mdata1,mdata2,mdata3;
wire[3:0]mem_detected,mem_corrected;
secded_decode70 dec0(mcode0,mdata0,mem_detected[0],mem_corrected[0]);
secded_decode70 dec1(mcode1,mdata1,mem_detected[1],mem_corrected[1]);
secded_decode70 dec2(mcode2,mdata2,mem_detected[2],mem_corrected[2]);
secded_decode70 dec3(mcode3,mdata3,mem_detected[3],mem_corrected[3]);
wire signed[34:0]a0r=mdata0[69:35],a0i=mdata0[34:0];
wire signed[34:0]a1r=mdata1[69:35],a1i=mdata1[34:0];
wire signed[34:0]a2r=mdata2[69:35],a2i=mdata2[34:0];
wire signed[34:0]a3r=mdata3[69:35],a3i=mdata3[34:0];

wire signed[34:0]sum0r=a0r+in0_re,sum0i=a0i+in0_im;
wire signed[34:0]sum1r=a1r+in1_re,sum1i=a1i+in1_im;
wire signed[34:0]sum2r=a2r+in2_re,sum2i=a2i+in2_im;
wire signed[34:0]sum3r=a3r+in3_re,sum3i=a3i+in3_im;
wire signed[34:0]diff0r=a0r-in0_re,diff0i=a0i-in0_im;
wire signed[34:0]diff1r=a1r-in1_re,diff1i=a1i-in1_im;
wire signed[34:0]diff2r=a2r-in2_re,diff2i=a2i-in2_im;
wire signed[34:0]diff3r=a3r-in3_re,diff3i=a3i-in3_im;
wire signed[34:0]upper0r=sum0r>>>1,upper0i=sum0i>>>1;
wire signed[34:0]upper1r=sum1r>>>1,upper1i=sum1i>>>1;
wire signed[34:0]upper2r=sum2r>>>1,upper2i=sum2i>>>1;
wire signed[34:0]upper3r=sum3r>>>1,upper3i=sum3i>>>1;
wire signed[34:0]lower0r=diff0r>>>1,lower0i=diff0i>>>1;
wire signed[34:0]lower1r=diff1r>>>1,lower1i=diff1i>>>1;
wire signed[34:0]lower2r=diff2r>>>1,lower2i=diff2i>>>1;
wire signed[34:0]lower3r=diff3r>>>1,lower3i=diff3i>>>1;

wire[9:0]exp0,exp1,exp2,exp3;
pfft_phi_calc #(.STAGE(8))phi0({out_count,2'd0},exp0);
pfft_phi_calc #(.STAGE(8))phi1({out_count,2'd1},exp1);
pfft_phi_calc #(.STAGE(8))phi2({out_count,2'd2},exp2);
pfft_phi_calc #(.STAGE(8))phi3({out_count,2'd3},exp3);
wire signed[34:0]pre0r=phase?upper0r:a0r,pre0i=phase?upper0i:a0i;
wire signed[34:0]pre1r=phase?upper1r:a1r,pre1i=phase?upper1i:a1i;
wire signed[34:0]pre2r=phase?upper2r:a2r,pre2i=phase?upper2i:a2i;
wire signed[34:0]pre3r=phase?upper3r:a3r,pre3i=phase?upper3i:a3i;
wire signed[34:0]t0r,t0i,t1r,t1i;
fft_complex_rotate_trivial_1024 rot0(pre0r,pre0i,exp0,t0r,t0i);
fft_complex_rotate_trivial_1024 rot1(pre1r,pre1i,exp1,t1r,t1i);
wire emit_raw=in_valid&&(phase||primed);
wire raw_is_last=(out_count==8'd255);
wire v2,v3;
wire signed[34:0]m2r,m2i,m3r,m3i;
fft_complex_mul_q28_pipe rot2(
 .clk(clk),.rst(rst),.valid_in(emit_raw),
 .in_re(pre2r),.in_im(pre2i),.exponent(exp2),
 .valid_out(v2),.out_re(m2r),.out_im(m2i));
fft_complex_mul_q28_pipe rot3(
 .clk(clk),.rst(rst),.valid_in(emit_raw),
 .in_re(pre3r),.in_im(pre3i),.exponent(exp3),
 .valid_out(v3),.out_re(m3r),.out_im(m3i));

wire signed[34:0]store0r=phase?lower0r:in0_re,store0i=phase?lower0i:in0_im;
wire signed[34:0]store1r=phase?lower1r:in1_re,store1i=phase?lower1i:in1_im;
wire signed[34:0]store2r=phase?lower2r:in2_re,store2i=phase?lower2i:in2_im;
wire signed[34:0]store3r=phase?lower3r:in3_re,store3i=phase?lower3i:in3_im;
wire[77:0]store_code0,store_code1,store_code2,store_code3;
secded_encode70 enc0({store0r,store0i},store_code0);
secded_encode70 enc1({store1r,store1i},store_code1);
secded_encode70 enc2({store2r,store2i},store_code2);
secded_encode70 enc3({store3r,store3i},store_code3);
fft_memory_v5 #(.WIDTH(78),.DEPTH(1),.ADDR_W(1))mem0(
 clk,in_valid,1'b0,mcode0,in_valid,1'b0,store_code0);
fft_memory_v5 #(.WIDTH(78),.DEPTH(1),.ADDR_W(1))mem1(
 clk,in_valid,1'b0,mcode1,in_valid,1'b0,store_code1);
fft_memory_v5 #(.WIDTH(78),.DEPTH(1),.ADDR_W(1))mem2(
 clk,in_valid,1'b0,mcode2,in_valid,1'b0,store_code2);
fft_memory_v5 #(.WIDTH(78),.DEPTH(1),.ADDR_W(1))mem3(
 clk,in_valid,1'b0,mcode3,in_valid,1'b0,store_code3);

reg signed[34:0]pair_a0r,pair_a0i,pair_a1r,pair_a1i,pair_a2r,pair_a2i,pair_a3r,pair_a3i;
reg signed[34:0]pair_b0r,pair_b0i,pair_b1r,pair_b1i,pair_b2r,pair_b2i,pair_b3r,pair_b3i;
reg bv1,bv2,bv3,bl1,bl2,bl3;
reg signed[34:0]c0r1,c0i1,c0r2,c0i2,c0r3,c0i3;
reg signed[34:0]c1r1,c1i1,c1r2,c1i2,c1r3,c1i3;
reg[9:0]e0_1,e1_1,e2_1,e3_1,e0_2,e1_2,e2_2,e3_2,e0_3,e1_3,e2_3,e3_3;
reg br1,br2,br3;
reg signed[34:0]oa0r1,oa0i1,oa1r1,oa1i1,oa2r1,oa2i1,oa3r1,oa3i1;
reg signed[34:0]ob0r1,ob0i1,ob1r1,ob1i1,ob2r1,ob2i1,ob3r1,ob3i1;
reg signed[34:0]oa0r2,oa0i2,oa1r2,oa1i2,oa2r2,oa2i2,oa3r2,oa3i2;
reg signed[34:0]ob0r2,ob0i2,ob1r2,ob1i2,ob2r2,ob2i2,ob3r2,ob3i2;
reg signed[34:0]oa0r3,oa0i3,oa1r3,oa1i3,oa2r3,oa2i3,oa3r3,oa3i3;
reg signed[34:0]ob0r3,ob0i3,ob1r3,ob1i3,ob2r3,ob2i3,ob3r3,ob3i3;
always@(posedge clk)begin
 if(rst)begin
  phase<=0;primed<=0;out_count<=0;out_valid<=0;out_last<=0;
  out0_re<=0;out0_im<=0;out1_re<=0;out1_im<=0;
  out2_re<=0;out2_im<=0;out3_re<=0;out3_im<=0;
  op_a0_re<=0;op_a0_im<=0;op_a1_re<=0;op_a1_im<=0;
  op_a2_re<=0;op_a2_im<=0;op_a3_re<=0;op_a3_im<=0;
  op_b0_re<=0;op_b0_im<=0;op_b1_re<=0;op_b1_im<=0;
  op_b2_re<=0;op_b2_im<=0;op_b3_re<=0;op_b3_im<=0;
  op_exp0<=0;op_exp1<=0;op_exp2<=0;op_exp3<=0;op_branch_upper<=0;
  pair_a0r<=0;pair_a0i<=0;pair_a1r<=0;pair_a1i<=0;
  pair_a2r<=0;pair_a2i<=0;pair_a3r<=0;pair_a3i<=0;
  pair_b0r<=0;pair_b0i<=0;pair_b1r<=0;pair_b1i<=0;
  pair_b2r<=0;pair_b2i<=0;pair_b3r<=0;pair_b3i<=0;
  bv1<=0;bv2<=0;bv3<=0;bl1<=0;bl2<=0;bl3<=0;br1<=0;br2<=0;br3<=0;
 end else begin
  if(in_valid)begin
   if(phase)begin
    pair_a0r<=a0r;pair_a0i<=a0i;pair_a1r<=a1r;pair_a1i<=a1i;
    pair_a2r<=a2r;pair_a2i<=a2i;pair_a3r<=a3r;pair_a3i<=a3i;
    pair_b0r<=in0_re;pair_b0i<=in0_im;pair_b1r<=in1_re;pair_b1i<=in1_im;
    pair_b2r<=in2_re;pair_b2i<=in2_im;pair_b3r<=in3_re;pair_b3i<=in3_im;
    primed<=1;
   end
   phase<=~phase;
  end
  if(emit_raw) out_count<=out_count+1'b1;

  bv1<=emit_raw; bl1<=emit_raw&&raw_is_last; br1<=phase;
  if(emit_raw)begin
   c0r1<=t0r;c0i1<=t0i;c1r1<=t1r;c1i1<=t1i;
   e0_1<=exp0;e1_1<=exp1;e2_1<=exp2;e3_1<=exp3;
   if(phase)begin
    oa0r1<=a0r;oa0i1<=a0i;oa1r1<=a1r;oa1i1<=a1i;
    oa2r1<=a2r;oa2i1<=a2i;oa3r1<=a3r;oa3i1<=a3i;
    ob0r1<=in0_re;ob0i1<=in0_im;ob1r1<=in1_re;ob1i1<=in1_im;
    ob2r1<=in2_re;ob2i1<=in2_im;ob3r1<=in3_re;ob3i1<=in3_im;
   end else begin
    oa0r1<=pair_a0r;oa0i1<=pair_a0i;oa1r1<=pair_a1r;oa1i1<=pair_a1i;
    oa2r1<=pair_a2r;oa2i1<=pair_a2i;oa3r1<=pair_a3r;oa3i1<=pair_a3i;
    ob0r1<=pair_b0r;ob0i1<=pair_b0i;ob1r1<=pair_b1r;ob1i1<=pair_b1i;
    ob2r1<=pair_b2r;ob2i1<=pair_b2i;ob3r1<=pair_b3r;ob3i1<=pair_b3i;
   end
  end
  bv2<=bv1;bl2<=bl1;br2<=br1;
  c0r2<=c0r1;c0i2<=c0i1;c1r2<=c1r1;c1i2<=c1i1;
  e0_2<=e0_1;e1_2<=e1_1;e2_2<=e2_1;e3_2<=e3_1;
  oa0r2<=oa0r1;oa0i2<=oa0i1;oa1r2<=oa1r1;oa1i2<=oa1i1;
  oa2r2<=oa2r1;oa2i2<=oa2i1;oa3r2<=oa3r1;oa3i2<=oa3i1;
  ob0r2<=ob0r1;ob0i2<=ob0i1;ob1r2<=ob1r1;ob1i2<=ob1i1;
  ob2r2<=ob2r1;ob2i2<=ob2i1;ob3r2<=ob3r1;ob3i2<=ob3i1;
  bv3<=bv2;bl3<=bl2;br3<=br2;
  c0r3<=c0r2;c0i3<=c0i2;c1r3<=c1r2;c1i3<=c1i2;
  e0_3<=e0_2;e1_3<=e1_2;e2_3<=e2_2;e3_3<=e3_2;
  oa0r3<=oa0r2;oa0i3<=oa0i2;oa1r3<=oa1r2;oa1i3<=oa1i2;
  oa2r3<=oa2r2;oa2i3<=oa2i2;oa3r3<=oa3r2;oa3i3<=oa3i2;
  ob0r3<=ob0r2;ob0i3<=ob0i2;ob1r3<=ob1r2;ob1i3<=ob1i2;
  ob2r3<=ob2r2;ob2i3<=ob2i2;ob3r3<=ob3r2;ob3i3<=ob3i2;

  out_valid<=v2; out_last<=v2?bl3:1'b0;
  if(v2)begin
   out0_re<=c0r3;out0_im<=c0i3;
   out1_re<=c1r3;out1_im<=c1i3;
   out2_re<=m2r;out2_im<=m2i;
   out3_re<=m3r;out3_im<=m3i;
   op_exp0<=e0_3;op_exp1<=e1_3;op_exp2<=e2_3;op_exp3<=e3_3;
   op_branch_upper<=br3;
   op_a0_re<=oa0r3;op_a0_im<=oa0i3;op_a1_re<=oa1r3;op_a1_im<=oa1i3;
   op_a2_re<=oa2r3;op_a2_im<=oa2i3;op_a3_re<=oa3r3;op_a3_im<=oa3i3;
   op_b0_re<=ob0r3;op_b0_im<=ob0i3;op_b1_re<=ob1r3;op_b1_im<=ob1i3;
   op_b2_re<=ob2r3;op_b2_im<=ob2i3;op_b3_re<=ob3r3;op_b3_im<=ob3i3;
  end
 end
end
wire _keep=^mem_detected^mem_corrected^in_last;
endmodule

(* keep_hierarchy = "yes" *) module p1_pfft_stage9_exchange_v3(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output reg out_valid,output reg out_last,
 output reg signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
reg[7:0]beat_count;
wire signed[34:0]s02r=in0_re+in2_re,s02i=in0_im+in2_im;
wire signed[34:0]d02r=in0_re-in2_re,d02i=in0_im-in2_im;
wire signed[34:0]s13r=in1_re+in3_re,s13i=in1_im+in3_im;
wire signed[34:0]d13r=in1_re-in3_re,d13i=in1_im-in3_im;
wire signed[34:0]b0r=s02r>>>1,b0i=s02i>>>1;
wire signed[34:0]b1r=s13r>>>1,b1i=s13i>>>1;
wire signed[34:0]b2r=d02r>>>1,b2i=d02i>>>1;
wire signed[34:0]b3r=d13r>>>1,b3i=d13i>>>1;
wire[9:0]e0,e1,e2,e3;
pfft_phi_calc #(.STAGE(9))p0({beat_count,2'd0},e0);
pfft_phi_calc #(.STAGE(9))p1({beat_count,2'd1},e1);
pfft_phi_calc #(.STAGE(9))p2({beat_count,2'd2},e2);
pfft_phi_calc #(.STAGE(9))p3({beat_count,2'd3},e3);
// Align all four lanes to 3-cycle CMUL latency (trivial lanes delayed).
wire signed[34:0]t0r,t0i,t2r,t2i;
fft_complex_rotate_trivial_1024 rot0(b0r,b0i,e0,t0r,t0i);
fft_complex_rotate_trivial_1024 rot2(b2r,b2i,e2,t2r,t2i);
wire v1,v3;
wire signed[34:0]m1r,m1i,m3r,m3i;
fft_complex_mul_q28_pipe rot1(
 .clk(clk),.rst(rst),.valid_in(in_valid),
 .in_re(b1r),.in_im(b1i),.exponent(e1),
 .valid_out(v1),.out_re(m1r),.out_im(m1i));
fft_complex_mul_q28_pipe rot3(
 .clk(clk),.rst(rst),.valid_in(in_valid),
 .in_re(b3r),.in_im(b3i),.exponent(e3),
 .valid_out(v3),.out_re(m3r),.out_im(m3i));
reg bv1,bv2,bv3,bl1,bl2,bl3;
reg signed[34:0]r0_1,i0_1,r0_2,i0_2,r0_3,i0_3;
reg signed[34:0]r2_1,i2_1,r2_2,i2_2,r2_3,i2_3;
always@(posedge clk)begin
 if(rst)begin
  beat_count<=0;out_valid<=0;out_last<=0;
  out0_re<=0;out0_im<=0;out1_re<=0;out1_im<=0;
  out2_re<=0;out2_im<=0;out3_re<=0;out3_im<=0;
  bv1<=0;bv2<=0;bv3<=0;bl1<=0;bl2<=0;bl3<=0;
  r0_1<=0;i0_1<=0;r0_2<=0;i0_2<=0;r0_3<=0;i0_3<=0;
  r2_1<=0;i2_1<=0;r2_2<=0;i2_2<=0;r2_3<=0;i2_3<=0;
 end else begin
  if(in_valid) beat_count<=beat_count+1'b1;
  bv1<=in_valid; bl1<=in_valid&&in_last;
  if(in_valid)begin r0_1<=t0r;i0_1<=t0i;r2_1<=t2r;i2_1<=t2i; end
  bv2<=bv1;bl2<=bl1;r0_2<=r0_1;i0_2<=i0_1;r2_2<=r2_1;i2_2<=i2_1;
  bv3<=bv2;bl3<=bl2;r0_3<=r0_2;i0_3<=i0_2;r2_3<=r2_2;i2_3<=i2_2;
  out_valid<=v1; out_last<=v1?bl3:1'b0;
  if(v1)begin
   out0_re<=r0_3;out0_im<=i0_3;
   out1_re<=m1r;out1_im<=m1i;
   out2_re<=r2_3;out2_im<=i2_3;
   out3_re<=m3r;out3_im<=m3i;
  end
 end
end
endmodule

(* keep_hierarchy = "yes" *) module p1_tmr_pfft_stage9_v3(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output wire out_valid,output wire out_last,
 output wire signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
wire[2:0]v,l;
wire signed[34:0]r0[0:2],i0[0:2],r1[0:2],i1[0:2],r2[0:2],i2[0:2],r3[0:2],i3[0:2];
genvar g9;
generate for(g9=0;g9<3;g9=g9+1)begin:replicas
 (* keep = "true" *)p1_pfft_stage9_exchange_v3 u(
  clk,rst,in_valid,in_last,in0_re,in0_im,in1_re,in1_im,
  in2_re,in2_im,in3_re,in3_im,v[g9],l[g9],
  r0[g9],i0[g9],r1[g9],i1[g9],r2[g9],i2[g9],r3[g9],i3[g9]);
end endgenerate
vote35 q0r(r0[0],r0[1],r0[2],out0_re);vote35 q0i(i0[0],i0[1],i0[2],out0_im);
vote35 q1r(r1[0],r1[1],r1[2],out1_re);vote35 q1i(i1[0],i1[1],i1[2],out1_im);
vote35 q2r(r2[0],r2[1],r2[2],out2_re);vote35 q2i(i2[0],i2[1],i2[2],out2_im);
vote35 q3r(r3[0],r3[1],r3[2],out3_re);vote35 q3i(i3[0],i3[1],i3[2],out3_im);
assign out_valid=(v[0]&v[1])|(v[0]&v[2])|(v[1]&v[2]);
assign out_last=(l[0]&l[1])|(l[0]&l[2])|(l[1]&l[2]);
endmodule

(* keep_hierarchy = "yes" *) module p1_tmr_pfft_stage8_v4(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output wire out_valid,output wire out_last,
 output wire signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
wire[2:0]v,l;
wire signed[34:0]r0[0:2],i0[0:2],r1[0:2],i1[0:2],r2[0:2],i2[0:2],r3[0:2],i3[0:2];
wire signed[34:0]oa0r[0:2],oa0i[0:2],oa1r[0:2],oa1i[0:2],oa2r[0:2],oa2i[0:2],oa3r[0:2],oa3i[0:2];
wire signed[34:0]ob0r[0:2],ob0i[0:2],ob1r[0:2],ob1i[0:2],ob2r[0:2],ob2i[0:2],ob3r[0:2],ob3i[0:2];
wire[9:0]oe0[0:2],oe1[0:2],oe2[0:2],oe3[0:2];
wire obranch[0:2];
genvar g8;
generate for(g8=0;g8<3;g8=g8+1)begin:replicas
 (* keep = "true" *)p1_stage8_functional_v3 u(
  clk,rst,in_valid,in_last,in0_re,in0_im,in1_re,in1_im,
  in2_re,in2_im,in3_re,in3_im,v[g8],l[g8],
  r0[g8],i0[g8],r1[g8],i1[g8],r2[g8],i2[g8],r3[g8],i3[g8],
  oa0r[g8],oa0i[g8],oa1r[g8],oa1i[g8],oa2r[g8],oa2i[g8],oa3r[g8],oa3i[g8],
  ob0r[g8],ob0i[g8],ob1r[g8],ob1i[g8],ob2r[g8],ob2i[g8],ob3r[g8],ob3i[g8],
  oe0[g8],oe1[g8],oe2[g8],oe3[g8],obranch[g8]);
end endgenerate
vote35 q0r(r0[0],r0[1],r0[2],out0_re);vote35 q0i(i0[0],i0[1],i0[2],out0_im);
vote35 q1r(r1[0],r1[1],r1[2],out1_re);vote35 q1i(i1[0],i1[1],i1[2],out1_im);
vote35 q2r(r2[0],r2[1],r2[2],out2_re);vote35 q2i(i2[0],i2[1],i2[2],out2_im);
vote35 q3r(r3[0],r3[1],r3[2],out3_re);vote35 q3i(i3[0],i3[1],i3[2],out3_im);
assign out_valid=(v[0]&v[1])|(v[0]&v[2])|(v[1]&v[2]);
assign out_last=(l[0]&l[1])|(l[0]&l[2])|(l[1]&l[2]);
endmodule

// Attempt16: residual → syndrome → locate → correct (uncomp Stage-10 timing split).
// Prior Attempt15 left sy→apply→out at WNS=-0.095 ns under uncomp tolerance match.
(* keep_hierarchy = "yes" *) module p1_stage10_time_aligned_ecc_v1(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output reg out_valid,output reg out_last,
 output reg signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
reg pair_phase;
reg signed[34:0]a0r,a0i,b0r,b0i,a1r,a1i,b1r,b1i;
reg signed[34:0]c0r,c0i,d0r,d0i,c1r,c1i,d1r,d1i;
reg go_bf,go_res,go_syn,go_loc,go_cor,pending_valid,pending_last,pair_last;
reg last_bf,last_res,last_syn,last_loc;
reg signed[34:0]pending0_re,pending0_im,pending1_re,pending1_im;
reg signed[34:0]pending2_re,pending2_im,pending3_re,pending3_im;

reg signed[34:0]qu0r,qu0i,qu1r,qu1i,qu2r,qu2i,qu3r,qu3i,qu4r,qu4i,qu5r,qu5i;
reg signed[34:0]ql0r,ql0i,ql1r,ql1i,ql2r,ql2i,ql3r,ql3i,ql4r,ql4i,ql5r,ql5i;
reg signed[34:0]au0r,au0i,au1r,au1i,au2r,au2i,au3r,au3i;
reg signed[34:0]al0r,al0i,al1r,al1i,al2r,al2i,al3r,al3i;
reg signed[34:0]hu4r,hu4i,hu5r,hu5i,hl4r,hl4i,hl5r,hl5i;
reg signed[38:0]sy0_ur,sy0_ui,sy1_ur,sy1_ui,sy0_lr,sy0_li,sy1_lr,sy1_li;
// Snapshots for locate|correct cut (avoid overwrite under overlapping pairs).
reg signed[34:0]xu0r,xu0i,xu1r,xu1i,xu2r,xu2i,xu3r,xu3i;
reg signed[34:0]xl0r,xl0i,xl1r,xl1i,xl2r,xl2i,xl3r,xl3i;
reg signed[34:0]yu0r,yu0i,yu1r,yu1i,yu2r,yu2i,yu3r,yu3i;
reg signed[34:0]yl0r,yl0i,yl1r,yl1i,yl2r,yl2i,yl3r,yl3i;
reg found_r; reg[2:0] loc_r;
reg signed[38:0]eru_r,eiu_r,erl_r,eil_r;

wire found_w; wire[2:0] loc_w;
wire signed[38:0]eru_w,eiu_w,erl_w,eil_w;
wire signed[34:0]bu0r,bu0i,bu1r,bu1i,bu2r,bu2i,bu3r,bu3i;
wire signed[34:0]bl0r,bl0i,bl1r,bl1i,bl2r,bl2i,bl3r,bl3i;
wire signed[34:0]ar[0:5],ai[0:5],brv[0:5],biv[0:5];
assign ar[0]=a0r;assign ai[0]=a0i;assign ar[1]=a1r;assign ai[1]=a1i;
assign ar[2]=c0r;assign ai[2]=c0i;assign ar[3]=c1r;assign ai[3]=c1i;
assign brv[0]=b0r;assign biv[0]=b0i;assign brv[1]=b1r;assign biv[1]=b1i;
assign brv[2]=d0r;assign biv[2]=d0i;assign brv[3]=d1r;assign biv[3]=d1i;
wire signed[34:0]a01r=a0r+a1r,a01i=a0i+a1i,a23r=c0r+c1r,a23i=c0i+c1i;
wire signed[34:0]b01r=b0r+b1r,b01i=b0i+b1i,b23r=d0r+d1r,b23i=d0i+d1i;
assign ar[4]=a01r+a23r;assign ai[4]=a01i+a23i;
assign brv[4]=b01r+b23r;assign biv[4]=b01i+b23i;
wire signed[34:0]aw1r=-a1i,aw1i=a1r,aw2r=-c0r,aw2i=-c0i,aw3r=c1i,aw3i=-c1r;
wire signed[34:0]bw1r=-b1i,bw1i=b1r,bw2r=-d0r,bw2i=-d0i,bw3r=d1i,bw3i=-d1r;
assign ar[5]=(a0r+aw1r)+(aw2r+aw3r);assign ai[5]=(a0i+aw1i)+(aw2i+aw3i);
assign brv[5]=(b0r+bw1r)+(bw2r+bw3r);assign biv[5]=(b0i+bw1i)+(bw2i+bw3i);

wire signed[34:0]raw_u_r[0:5],raw_u_i[0:5],raw_l_r[0:5],raw_l_i[0:5];
genvar g10;
generate for(g10=0;g10<6;g10=g10+1)begin:bfly
 wire signed[34:0]sumr=ar[g10]+brv[g10],sumi=ai[g10]+biv[g10];
 wire signed[34:0]diffr=ar[g10]-brv[g10],diffi=ai[g10]-biv[g10];
 assign raw_u_r[g10]=sumr>>>1;assign raw_u_i[g10]=sumi>>>1;
 assign raw_l_r[g10]=diffr>>>1;assign raw_l_i[g10]=diffi>>>1;
end endgenerate

// Syndromes from snapshotted symbols (au/al + hu/hl) after go_res.
wire signed[38:0]raw0_ur_w=$signed(hu4r)-($signed(au0r)+$signed(au1r)+$signed(au2r)+$signed(au3r));
wire signed[38:0]raw0_ui_w=$signed(hu4i)-($signed(au0i)+$signed(au1i)+$signed(au2i)+$signed(au3i));
wire signed[38:0]raw1_ur_w=$signed(hu5r)-($signed(au0r)-$signed(au1i)-$signed(au2r)+$signed(au3i));
wire signed[38:0]raw1_ui_w=$signed(hu5i)-($signed(au0i)+$signed(au1r)-$signed(au2i)-$signed(au3r));
wire signed[38:0]raw0_lr_w=$signed(hl4r)-($signed(al0r)+$signed(al1r)+$signed(al2r)+$signed(al3r));
wire signed[38:0]raw0_li_w=$signed(hl4i)-($signed(al0i)+$signed(al1i)+$signed(al2i)+$signed(al3i));
wire signed[38:0]raw1_lr_w=$signed(hl5r)-($signed(al0r)-$signed(al1i)-$signed(al2r)+$signed(al3i));
wire signed[38:0]raw1_li_w=$signed(hl5i)-($signed(al0i)+$signed(al1r)-$signed(al2i)-$signed(al3r));
wire signed[38:0]sy0_ur_w=raw0_ur_w,sy0_ui_w=raw0_ui_w;  // un-compensated raw syndrome
wire signed[38:0]sy1_ur_w=raw1_ur_w,sy1_ui_w=raw1_ui_w;
wire signed[38:0]sy0_lr_w=raw0_lr_w,sy0_li_w=raw0_li_w;
wire signed[38:0]sy1_lr_w=raw1_lr_w,sy1_li_w=raw1_li_w;

(* keep = "true" *) complete_butterfly_locate_from_syndrome_643_uncomp #(.THRESHOLD(8)) u_loc(
 sy0_ur,sy0_ui,sy1_ur,sy1_ui,sy0_lr,sy0_li,sy1_lr,sy1_li,
 found_w,loc_w,eru_w,eiu_w,erl_w,eil_w
);
(* keep = "true" *) complete_butterfly_correct_from_location_643 u_cor(
 found_r,loc_r,eru_r,eiu_r,erl_r,eil_r,
 yu0r,yu0i,yu1r,yu1i,yu2r,yu2i,yu3r,yu3i,
 yl0r,yl0i,yl1r,yl1i,yl2r,yl2i,yl3r,yl3i,
 bu0r,bu0i,bu1r,bu1i,bu2r,bu2i,bu3r,bu3i,
 bl0r,bl0i,bl1r,bl1i,bl2r,bl2i,bl3r,bl3i
);

always@(posedge clk)begin
 if(rst)begin
  pair_phase<=0;go_bf<=0;go_res<=0;go_syn<=0;go_loc<=0;go_cor<=0;
  pending_valid<=0;pending_last<=0;pair_last<=0;
  last_bf<=0;last_res<=0;last_syn<=0;last_loc<=0;
  out_valid<=0;out_last<=0;
  a0r<=0;a0i<=0;b0r<=0;b0i<=0;a1r<=0;a1i<=0;b1r<=0;b1i<=0;
  c0r<=0;c0i<=0;d0r<=0;d0i<=0;c1r<=0;c1i<=0;d1r<=0;d1i<=0;
  pending0_re<=0;pending0_im<=0;pending1_re<=0;pending1_im<=0;
  pending2_re<=0;pending2_im<=0;pending3_re<=0;pending3_im<=0;
  out0_re<=0;out0_im<=0;out1_re<=0;out1_im<=0;
  out2_re<=0;out2_im<=0;out3_re<=0;out3_im<=0;
  sy0_ur<=0;sy0_ui<=0;sy1_ur<=0;sy1_ui<=0;
  sy0_lr<=0;sy0_li<=0;sy1_lr<=0;sy1_li<=0;
  found_r<=0;loc_r<=0;eru_r<=0;eiu_r<=0;erl_r<=0;eil_r<=0;
 end else begin
  out_valid<=0;out_last<=0;
  go_bf<=0;go_res<=0;go_syn<=0;go_loc<=0;go_cor<=0;

  if(in_valid)begin
   if(!pair_phase)begin
    a0r<=in0_re;a0i<=in0_im;b0r<=in1_re;b0i<=in1_im;
    a1r<=in2_re;a1i<=in2_im;b1r<=in3_re;b1i<=in3_im;
    pair_phase<=1;
   end else begin
    c0r<=in0_re;c0i<=in0_im;d0r<=in1_re;d0i<=in1_im;
    c1r<=in2_re;c1i<=in2_im;d1r<=in3_re;d1i<=in3_im;
    pair_phase<=0;
    go_bf<=1;
    pair_last<=in_last;
   end
  end

  if(go_bf)begin
   qu0r<=raw_u_r[0];qu0i<=raw_u_i[0];qu1r<=raw_u_r[1];qu1i<=raw_u_i[1];
   qu2r<=raw_u_r[2];qu2i<=raw_u_i[2];qu3r<=raw_u_r[3];qu3i<=raw_u_i[3];
   qu4r<=raw_u_r[4];qu4i<=raw_u_i[4];qu5r<=raw_u_r[5];qu5i<=raw_u_i[5];
   ql0r<=raw_l_r[0];ql0i<=raw_l_i[0];ql1r<=raw_l_r[1];ql1i<=raw_l_i[1];
   ql2r<=raw_l_r[2];ql2i<=raw_l_i[2];ql3r<=raw_l_r[3];ql3i<=raw_l_i[3];
   ql4r<=raw_l_r[4];ql4i<=raw_l_i[4];ql5r<=raw_l_r[5];ql5i<=raw_l_i[5];
   go_res<=1;
   last_bf<=pair_last;
  end

  if(go_res)begin
   au0r<=qu0r;au0i<=qu0i;au1r<=qu1r;au1i<=qu1i;au2r<=qu2r;au2i<=qu2i;au3r<=qu3r;au3i<=qu3i;
   al0r<=ql0r;al0i<=ql0i;al1r<=ql1r;al1i<=ql1i;al2r<=ql2r;al2i<=ql2i;al3r<=ql3r;al3i<=ql3i;
   hu4r<=qu4r;hu4i<=qu4i;hu5r<=qu5r;hu5i<=qu5i;
   hl4r<=ql4r;hl4i<=ql4i;hl5r<=ql5r;hl5i<=ql5i;
   go_syn<=1;
   last_res<=last_bf;
  end

  if(go_syn)begin
   sy0_ur<=sy0_ur_w;sy0_ui<=sy0_ui_w;sy1_ur<=sy1_ur_w;sy1_ui<=sy1_ui_w;
   sy0_lr<=sy0_lr_w;sy0_li<=sy0_li_w;sy1_lr<=sy1_lr_w;sy1_li<=sy1_li_w;
   xu0r<=au0r;xu0i<=au0i;xu1r<=au1r;xu1i<=au1i;xu2r<=au2r;xu2i<=au2i;xu3r<=au3r;xu3i<=au3i;
   xl0r<=al0r;xl0i<=al0i;xl1r<=al1r;xl1i<=al1i;xl2r<=al2r;xl2i<=al2i;xl3r<=al3r;xl3i<=al3i;
   go_loc<=1;
   last_syn<=last_res;
  end

  if(go_loc)begin
   found_r<=found_w;loc_r<=loc_w;
   eru_r<=eru_w;eiu_r<=eiu_w;erl_r<=erl_w;eil_r<=eil_w;
   yu0r<=xu0r;yu0i<=xu0i;yu1r<=xu1r;yu1i<=xu1i;yu2r<=xu2r;yu2i<=xu2i;yu3r<=xu3r;yu3i<=xu3i;
   yl0r<=xl0r;yl0i<=xl0i;yl1r<=xl1r;yl1i<=xl1i;yl2r<=xl2r;yl2i<=xl2i;yl3r<=xl3r;yl3i<=xl3i;
   go_cor<=1;
   last_loc<=last_syn;
  end

  if(go_cor)begin
   out_valid<=1;out_last<=0;
   out0_re<=bu0r;out0_im<=bu0i;out1_re<=bl0r;out1_im<=bl0i;
   out2_re<=bu1r;out2_im<=bu1i;out3_re<=bl1r;out3_im<=bl1i;
   pending_valid<=1;pending_last<=last_loc;
   pending0_re<=bu2r;pending0_im<=bu2i;pending1_re<=bl2r;pending1_im<=bl2i;
   pending2_re<=bu3r;pending2_im<=bu3i;pending3_re<=bl3r;pending3_im<=bl3i;
  end else if(pending_valid)begin
   out_valid<=1;out_last<=pending_last;pending_valid<=0;
   out0_re<=pending0_re;out0_im<=pending0_im;
   out1_re<=pending1_re;out1_im<=pending1_im;
   out2_re<=pending2_re;out2_im<=pending2_im;
   out3_re<=pending3_re;out3_im<=pending3_im;
  end
 end
end
endmodule

(* keep_hierarchy = "yes" *) module p1_pfft_ecc_core_v4(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output wire out_valid,output wire out_last,
 output wire signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
wire[11:0]v,l;
wire signed[34:0]r0[0:11],i0[0:11],r1[0:11],i1[0:11],r2[0:11],i2[0:11],r3[0:11],i3[0:11];
assign v[0]=in_valid;assign l[0]=in_last;
assign r0[0]=in0_re;assign i0[0]=in0_im;assign r1[0]=in1_re;assign i1[0]=in1_im;
assign r2[0]=in2_re;assign i2[0]=in2_im;assign r3[0]=in3_re;assign i3[0]=in3_im;
p1_ecc_stage4_v3 #(.DEPTH(128),.STAGE(1))s1(clk,rst,v[0],l[0],r0[0],i0[0],r1[0],i1[0],r2[0],i2[0],r3[0],i3[0],v[1],l[1],r0[1],i0[1],r1[1],i1[1],r2[1],i2[1],r3[1],i3[1]);
p1_ecc_stage4_v3 #(.DEPTH(64),.STAGE(2))s2(clk,rst,v[1],l[1],r0[1],i0[1],r1[1],i1[1],r2[1],i2[1],r3[1],i3[1],v[2],l[2],r0[2],i0[2],r1[2],i1[2],r2[2],i2[2],r3[2],i3[2]);
p1_ecc_stage4_v3 #(.DEPTH(32),.STAGE(3))s3(clk,rst,v[2],l[2],r0[2],i0[2],r1[2],i1[2],r2[2],i2[2],r3[2],i3[2],v[3],l[3],r0[3],i0[3],r1[3],i1[3],r2[3],i2[3],r3[3],i3[3]);
p1_ecc_stage4_v3 #(.DEPTH(16),.STAGE(4))s4(clk,rst,v[3],l[3],r0[3],i0[3],r1[3],i1[3],r2[3],i2[3],r3[3],i3[3],v[4],l[4],r0[4],i0[4],r1[4],i1[4],r2[4],i2[4],r3[4],i3[4]);
p1_ecc_stage4_v3 #(.DEPTH(8),.STAGE(5))s5(clk,rst,v[4],l[4],r0[4],i0[4],r1[4],i1[4],r2[4],i2[4],r3[4],i3[4],v[5],l[5],r0[5],i0[5],r1[5],i1[5],r2[5],i2[5],r3[5],i3[5]);
p1_ecc_stage4_v3 #(.DEPTH(4),.STAGE(6))s6(clk,rst,v[5],l[5],r0[5],i0[5],r1[5],i1[5],r2[5],i2[5],r3[5],i3[5],v[6],l[6],r0[6],i0[6],r1[6],i1[6],r2[6],i2[6],r3[6],i3[6]);
p1_ecc_stage4_v3 #(.DEPTH(2),.STAGE(7))s7(clk,rst,v[6],l[6],r0[6],i0[6],r1[6],i1[6],r2[6],i2[6],r3[6],i3[6],v[7],l[7],r0[7],i0[7],r1[7],i1[7],r2[7],i2[7],r3[7],i3[7]);

p1_tmr_pfft_stage8_v4 s8(
 clk,rst,v[7],l[7],r0[7],i0[7],r1[7],i1[7],r2[7],i2[7],r3[7],i3[7],
 v[8],l[8],r0[8],i0[8],r1[8],i1[8],r2[8],i2[8],r3[8],i3[8]);
p1_tmr_pfft_stage9_v3 s9(
 clk,rst,v[8],l[8],r0[8],i0[8],r1[8],i1[8],r2[8],i2[8],r3[8],i3[8],
 v[10],l[10],r0[10],i0[10],r1[10],i1[10],r2[10],i2[10],r3[10],i3[10]);
p1_stage10_time_aligned_ecc_v1 s10(
 clk,rst,v[10],l[10],r0[10],i0[10],r1[10],i1[10],r2[10],i2[10],r3[10],i3[10],
 v[11],l[11],r0[11],i0[11],r1[11],i1[11],r2[11],i2[11],r3[11],i3[11]);
assign out_valid=v[11];assign out_last=l[11];
assign out0_re=r0[11];assign out0_im=i0[11];
assign out1_re=r1[11];assign out1_im=i1[11];
assign out2_re=r2[11];assign out2_im=i2[11];
assign out3_re=r3[11];assign out3_im=i3[11];
endmodule

module top_p1_pfft_ecc(
 input wire clk,input wire rst,input wire in_valid,input wire in_last,
 input wire signed[34:0]in0_re,in0_im,in1_re,in1_im,in2_re,in2_im,in3_re,in3_im,
 output wire out_valid,output wire out_last,
 output wire signed[34:0]out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im
);
p1_pfft_ecc_core_v4 u(
 clk,rst,in_valid,in_last,in0_re,in0_im,in1_re,in1_im,
 in2_re,in2_im,in3_re,in3_im,out_valid,out_last,
 out0_re,out0_im,out1_re,out1_im,out2_re,out2_im,out3_re,out3_im);
endmodule

