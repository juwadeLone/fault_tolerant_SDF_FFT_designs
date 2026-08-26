`timescale 1ns/1ps
`include "common/tb_utils.svh"
module tb_pfft_phi_calc;
`TB_INIT("pfft_phi_calc"); `TB_TIMEOUT(200000)
reg [9:0] index; wire [9:0] exponent[1:9]; integer i,s,h,l,expected;
genvar g; generate for(g=1;g<=9;g=g+1)begin:p pfft_phi_calc #(.STAGE(g)) d(index,exponent[g]);end endgenerate
 initial begin
  tb_pass=0;tb_fail=0;tb_xfail=0;tb_xpass=0;
  for(i=0;i<1024;i=i+1)begin
   index=i;#1;
   for(s=1;s<=9;s=s+1)begin
    expected=0;
    for(h=1;h<10;h=h+1)
     for(l=0;l<h;l=l+1)
      if(s==(9-l)&&index[h]&&index[l])expected=expected+(1<<(9-h+l));
    `TB_CHECK_EQ(exponent[s],expected,"phi reference");
    `TB_CHECK(exponent[s]<1024,"phi range");
   end
  end
  index=0;#1;
  for(s=1;s<=9;s=s+1)`TB_CHECK_EQ(exponent[s],0,"phi zero vector");
  // Independent derivations: stage 9 uses bit 0 as l, stage 8 bit 1,
  // stage 7 bit 2, and stage 6 bit 3. Each term is 2**(9-h+l).
  index=10'b0000100101;#1; // bits 0,2,5: 2**7 + 2**4 = 144.
  `TB_CHECK_EQ(exponent[9],144,"phi hand vector stage 9 two/three bits");
  index=10'b0001001010;#1; // bits 1,3,6: 2**7 + 2**4 = 144.
  `TB_CHECK_EQ(exponent[8],144,"phi hand vector stage 8 two/three bits");
  index=10'b0010100100;#1; // bits 2,5,7: 2**6 + 2**4 = 80.
  `TB_CHECK_EQ(exponent[7],80,"phi hand vector stage 7 two/three bits");
  index=10'b0100011000;#1; // bits 3,4,8: 2**8 + 2**4 = 272.
  `TB_CHECK_EQ(exponent[6],272,"phi hand vector stage 6 two/three bits");
  index=3;#1;
  `TB_CHECK_EQ(exponent[9],256,"phi hand vector index 3 stage 9");
  `TB_FINISH;
 end
endmodule
