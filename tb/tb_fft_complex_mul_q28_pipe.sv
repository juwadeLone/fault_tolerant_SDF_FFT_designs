`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_fft_complex_mul_q28_pipe;
`TB_INIT("fft_complex_mul_q28_pipe"); `TB_TIMEOUT(200000)
reg clk,rst,valid_in; reg signed [34:0] ir,ii; reg [9:0] exponent; wire valid_out; wire signed [34:0] orr,oi; wire signed [34:0] ref_r,ref_i; reg [2:0] pv; reg signed [34:0] pr[0:2],pi[0:2]; integer i;
fft_complex_mul_q28_pipe d(clk,rst,valid_in,ir,ii,exponent,valid_out,orr,oi);fft_complex_mul_q28 comb(ir,ii,exponent,ref_r,ref_i);
always #1 clk=~clk;
initial begin
 clk=0; rst=1; valid_in=0; ir=0; ii=0; exponent=0; pv=0;
 tb_pass=0; tb_fail=0; tb_xfail=0; tb_xpass=0;
 repeat(2) @(posedge clk);
 rst=0;
 for(i=0;i<300;i=i+1) begin
  @(negedge clk);
  valid_in=(i%5)!=0;
  ir=$random%100000000;
  ii=$random%100000000;
  exponent=$random;
  pr[0]=ref_r;
  pi[0]=ref_i;
  @(posedge clk);
  pv[0]<=valid_in;
  pv[1]<=pv[0];
  pv[2]<=pv[1];
  pr[1]<=pr[0];
  pi[1]<=pi[0];
  pr[2]<=pr[1];
  pi[2]<=pi[1];
  #0.1;
  `TB_CHECK(valid_out==pv[2],"pipe valid latency")
  if(valid_out) begin
   `TB_CHECK_EQ(orr,pr[2],"pipe re equivalence")
   `TB_CHECK_EQ(oi,pi[2],"pipe im equivalence")
  end
 end
 rst=1;
 @(posedge clk);
 #0.1;
 `TB_CHECK(!valid_out&&orr==0&&oi==0,"pipe reset clear")
 `TB_FINISH;
end
endmodule
