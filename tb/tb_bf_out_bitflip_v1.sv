`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_bf_out_bitflip_v1;
`TB_INIT("bf_out_bitflip_v1");
`TB_TIMEOUT(100000)
reg signed [34:0] in [0:15]; wire signed [34:0] out [0:15];
reg pulse; reg [2:0] sel; reg component; reg [5:0] bit_index;
bf_out_bitflip_v1 d(in[0],in[1],in[2],in[3],in[4],in[5],in[6],in[7],in[8],in[9],in[10],in[11],in[12],in[13],in[14],in[15],pulse,sel,component,bit_index,
 out[0],out[1],out[2],out[3],out[4],out[5],out[6],out[7],out[8],out[9],out[10],out[11],out[12],out[13],out[14],out[15]);
integer i,k,diff,target,si,ci_i; reg signed [34:0] expected;
initial begin tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0; for(i=0;i<16;i=i+1) in[i]=$random; pulse=0; #1;
 for(i=0;i<16;i=i+1) `TB_CHECK_EQ(out[i],in[i],"clean output");
 pulse=1; for(si=0;si<8;si=si+1) for(ci_i=0;ci_i<2;ci_i=ci_i+1) begin sel=si;component=ci_i;
  for(k=0;k<5;k=k+1) begin case(k) 0:bit_index=0;1:bit_index=1;2:bit_index=17;3:bit_index=33;default:bit_index=34;endcase #1;
   target=(sel[2]?8:0)+(sel[1:0]*2)+component; diff=0; for(i=0;i<16;i=i+1) begin if(out[i]!==in[i]) diff=diff+1; if(i==target) expected=in[i]^(35'sd1<<bit_index); else expected=in[i]; `TB_CHECK_EQ(out[i],expected,"selected output and isolation"); end `TB_CHECK_EQ(diff,1,"exactly one output differs");
  end
 end
 `TB_FINISH; end
endmodule
