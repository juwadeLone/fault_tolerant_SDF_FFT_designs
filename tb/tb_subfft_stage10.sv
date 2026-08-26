`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_subfft_stage10;
`TB_INIT("subfft_stage10"); `TB_TIMEOUT(100000)
reg clk,rst,valid_in,last_in; reg signed [34:0] a0,a1,a2,a3; wire valid_out,last_out; wire signed [34:0] o0,o1,o2,o3,oi0,oi1,oi2,oi3; wire signed [34:0] zero_im=0; reg exp_valid,exp_last,have_output; reg signed [34:0] exp0,exp1,exp2,exp3,cur0,cur1,cur2,cur3,last0,last1,last2,last3; integer i;
subfft_stage10 d(clk,rst,valid_in,last_in,a0,zero_im,a1,zero_im,a2,zero_im,a3,zero_im,valid_out,last_out,o0,oi0,o1,oi1,o2,oi2,o3,oi3);
always #1 clk=~clk;
initial begin
 clk=0; rst=1; valid_in=0; last_in=0; a0=0; a1=0; a2=0; a3=0; exp_valid=0; exp_last=0; have_output=0; exp0=0; exp1=0; exp2=0; exp3=0; cur0=0; cur1=0; cur2=0; cur3=0; last0=0; last1=0; last2=0; last3=0;
 tb_pass=0; tb_fail=0; tb_xfail=0; tb_xpass=0;
 repeat(2) @(posedge clk);
 rst=0;
 for(i=0;i<200;i=i+1) begin
  @(negedge clk);
  valid_in=(i%4)!=0;
  last_in=(i%17)==16;
  a0=$random%100000; a1=$random%100000; a2=$random%100000; a3=$random%100000;
  cur0=(a0+a1)>>>1; cur2=(a0-a1)>>>1;
  cur1=(a2+a3)>>>1; cur3=(a2-a3)>>>1;
  @(posedge clk);
  #0.1;
  `TB_CHECK(valid_out==exp_valid&&last_out==exp_last,"sub stage latency")
  if(valid_out) begin
   `TB_CHECK_EQ(o0,exp0,"sub stage o0")
   `TB_CHECK_EQ(o1,exp1,"sub stage o1")
   `TB_CHECK_EQ(o2,exp2,"sub stage o2")
   `TB_CHECK_EQ(o3,exp3,"sub stage o3")
   last0=o0; last1=o1; last2=o2; last3=o3; have_output=1;
  end else if(have_output) begin
   `TB_CHECK_EQ(o0,last0,"sub stage o0 holds in bubble")
   `TB_CHECK_EQ(o1,last1,"sub stage o1 holds in bubble")
   `TB_CHECK_EQ(o2,last2,"sub stage o2 holds in bubble")
   `TB_CHECK_EQ(o3,last3,"sub stage o3 holds in bubble")
  end
 exp_valid=valid_in; exp_last=last_in;
  exp0=cur0; exp1=cur1; exp2=cur2; exp3=cur3;
 end
 rst=1; valid_in=0; last_in=0;
 repeat(2) @(posedge clk);
 rst=0;
 @(negedge clk);
 valid_in=1; last_in=1; a0=10; a1=20; a2=30; a3=40;
 @(posedge clk);
 #0.1;
 `TB_CHECK(!valid_out,"sub stage first edge latency")
 @(negedge clk);
 valid_in=0; last_in=0;
 @(posedge clk);
 #0.1;
 `TB_CHECK(valid_out&&last_out,"sub stage second edge latency")
 `TB_CHECK_EQ(o0,15,"sub stage two-edge o0")
 `TB_CHECK_EQ(o1,35,"sub stage two-edge o1")
 `TB_CHECK_EQ(o2,-5,"sub stage two-edge o2")
 `TB_CHECK_EQ(o3,-5,"sub stage two-edge o3")
 @(posedge clk);
 #0.1;
 `TB_CHECK(!valid_out&&!last_out,"sub stage single-beat completion")
 a0=-1; a1=-2; a2=0; a3=0; valid_in=1; last_in=1;
 @(posedge clk);
 @(posedge clk);
 #0.1;
 `TB_CHECK(valid_out&&last_out,"sub stage arithmetic valid")
 `TB_CHECK_EQ(o0,-2,"sub stage arithmetic shift")
 `TB_FINISH;
end
endmodule
