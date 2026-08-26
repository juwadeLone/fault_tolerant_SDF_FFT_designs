`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_pfft_phi_calc;
`TB_INIT("pfft_phi_calc"); `TB_TIMEOUT(200000)
reg [9:0] index; wire [9:0] exponent[1:9]; integer i,s,h,l,expected;
genvar g; generate for(g=1;g<=9;g=g+1)begin:p pfft_phi_calc #(.STAGE(g)) d(index,exponent[g]);end endgenerate
initial begin tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;for(i=0;i<1024;i=i+1)begin index=i;#1;for(s=1;s<=9;s=s+1)begin expected=0;for(h=1;h<10;h=h+1)for(l=0;l<h;l=l+1)if(s==(9-l)&&index[h]&&index[l])expected=expected+(1<<(9-h+l));`TB_CHECK_EQ(exponent[s],expected,"phi reference");`TB_CHECK(exponent[s]<1024,"phi range");end end index=0;#1;for(s=1;s<=9;s=s+1)`TB_CHECK_EQ(exponent[s],0,"phi zero vector");index=3;#1;`TB_CHECK_EQ(exponent[9],256,"phi hand vector index 3 stage 9");`TB_FINISH;end
endmodule
